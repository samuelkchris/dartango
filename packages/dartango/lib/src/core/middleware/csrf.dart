import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';

import '../http/request.dart';
import '../http/response.dart';
import 'base.dart';
import 'session.dart';

class CsrfViewMiddleware extends BaseMiddleware {
  static const String csrfTokenName = 'csrfmiddlewaretoken';
  static const String csrfHeaderName = 'X-CSRFToken';
  static const String csrfCookieName = 'csrftoken';
  static const String csrfFailureView = 'csrf_failure';

  final String cookieName;
  final String? cookieDomain;
  final String cookiePath;
  final bool cookieSecure;
  final bool cookieHttpOnly;
  final SameSite? cookieSameSite;
  final Duration? cookieAge;
  final String secretKey;
  final String salt;
  final List<String> trustedOrigins;
  final String failureView;
  final bool useSSL;
  final bool exemptUrls;
  final List<String> exemptUrlPatterns;
  final List<String> exemptViews;
  final String reasonForFailure;

  CsrfViewMiddleware({
    String? cookieName,
    this.cookieDomain,
    String? cookiePath,
    bool? cookieSecure,
    bool? cookieHttpOnly,
    SameSite? cookieSameSite,
    Duration? cookieAge,
    String? secretKey,
    String? salt,
    List<String>? trustedOrigins,
    String? failureView,
    bool? useSSL,
    bool? exemptUrls,
    List<String>? exemptUrlPatterns,
    List<String>? exemptViews,
    String? reasonForFailure,
  })  : cookieName = cookieName ?? csrfCookieName,
        cookiePath = cookiePath ?? '/',
        cookieSecure = cookieSecure ?? false,
        cookieHttpOnly = cookieHttpOnly ?? false,
        cookieSameSite = cookieSameSite ?? SameSite.lax,
        cookieAge = cookieAge ?? const Duration(seconds: 31449600),
        secretKey = secretKey ?? 'default-secret-key',
        salt = salt ?? 'django.middleware.csrf.CsrfViewMiddleware',
        trustedOrigins = trustedOrigins ?? [],
        failureView = failureView ?? csrfFailureView,
        useSSL = useSSL ?? false,
        exemptUrls = exemptUrls ?? false,
        exemptUrlPatterns = exemptUrlPatterns ?? [],
        exemptViews = exemptViews ?? [],
        reasonForFailure = reasonForFailure ?? 'CSRF verification failed. Request aborted.';


  @override
  FutureOr<HttpResponse?> processView(
    HttpRequest request,
    Function viewFunc,
    List<dynamic> viewArgs,
    Map<String, dynamic> viewKwargs,
  ) async {
    if (_isExempt(request, viewFunc)) {
      return null;
    }

    if (_requiresCSRFProtection(request)) {
      final csrfToken = _getCsrfToken(request);
      if (csrfToken == null) {
        return _rejectRequest(request, 'CSRF cookie not set');
      }

      final providedToken = await _getProvidedToken(request);
      if (providedToken == null) {
        return _rejectRequest(request, 'CSRF token missing');
      }

      if (!_constantTimeCompare(csrfToken, providedToken)) {
        return _rejectRequest(request, 'CSRF token incorrect');
      }

      if (!_originMatches(request)) {
        return _rejectRequest(request, 'Origin verification failed');
      }

      if (!_refererMatches(request)) {
        return _rejectRequest(request, 'Referer verification failed');
      }
    }

    return null;
  }

  @override
  FutureOr<HttpResponse> processResponse(
    HttpRequest request,
    HttpResponse response,
  ) {
    if (_shouldSetCookie(request, response)) {
      final token = _getOrCreateCsrfToken(request);
      response = _setCsrfCookie(response, token);
    }

    return response;
  }

  bool _isExempt(HttpRequest request, Function viewFunc) {
    final path = request.uri.path;
    
    for (final pattern in exemptUrlPatterns) {
      if (RegExp(pattern).hasMatch(path)) {
        return true;
      }
    }

    return false;
  }

  bool _requiresCSRFProtection(HttpRequest request) {
    final method = request.method.toUpperCase();
    return ['POST', 'PUT', 'PATCH', 'DELETE'].contains(method);
  }

  String? _getCsrfToken(HttpRequest request) {
    final session = request.context['session'] as Session?;
    if (session != null) {
      return session['_csrf_token'] as String?;
    }

    return request.cookies[cookieName]?.value;
  }

  Future<String?> _getProvidedToken(HttpRequest request) async {
    final headerToken = request.headers[csrfHeaderName.toLowerCase()];
    if (headerToken != null) {
      return headerToken;
    }

    final formData = await request.parsedBody;
    return formData[csrfTokenName] as String?;
  }

  bool _constantTimeCompare(String a, String b) {
    if (a.length != b.length) {
      return false;
    }

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }

    return result == 0;
  }

  bool _originMatches(HttpRequest request) {
    final origin = request.headers['origin'];
    if (origin == null) {
      return true;
    }

    final requestHost = request.host;
    final requestScheme = request.scheme;
    final expectedOrigin = '$requestScheme://$requestHost';

    if (origin == expectedOrigin) {
      return true;
    }

    for (final trustedOrigin in trustedOrigins) {
      if (origin == trustedOrigin) {
        return true;
      }

      if (trustedOrigin.startsWith('*.')) {
        final domain = trustedOrigin.substring(2);
        final originUri = Uri.parse(origin);
        if (originUri.host == domain || originUri.host.endsWith('.$domain')) {
          return true;
        }
      }
    }

    return false;
  }

  bool _refererMatches(HttpRequest request) {
    final referer = request.headers['referer'];
    if (referer == null) {
      return false;
    }

    final refererUri = Uri.tryParse(referer);
    if (refererUri == null) {
      return false;
    }

    final requestHost = request.host;
    final requestScheme = request.scheme;

    if (refererUri.host == requestHost && refererUri.scheme == requestScheme) {
      return true;
    }

    for (final trustedOrigin in trustedOrigins) {
      final trustedUri = Uri.tryParse(trustedOrigin);
      if (trustedUri != null && 
          refererUri.host == trustedUri.host && 
          refererUri.scheme == trustedUri.scheme) {
        return true;
      }
    }

    return false;
  }

  bool _shouldSetCookie(HttpRequest request, HttpResponse response) {
    final existingToken = _getCsrfToken(request);
    return existingToken == null || response.headers.containsKey('set-cookie');
  }

  String _getOrCreateCsrfToken(HttpRequest request) {
    final existingToken = _getCsrfToken(request);
    if (existingToken != null) {
      return existingToken;
    }

    final token = _generateCsrfToken();
    
    final session = request.context['session'] as Session?;
    if (session != null) {
      session['_csrf_token'] = token;
    }

    return token;
  }

  String _generateCsrfToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  HttpResponse _setCsrfCookie(HttpResponse response, String token) {
    final expires = cookieAge != null ? DateTime.now().add(cookieAge!) : null;
    
    return response.setCookie(
      cookieName,
      token,
      expires: expires,
      path: cookiePath,
      domain: cookieDomain,
      secure: cookieSecure,
      httpOnly: cookieHttpOnly,
      sameSite: cookieSameSite,
    );
  }

  HttpResponse _rejectRequest(HttpRequest request, String reason) {
    return HttpResponse(
      reasonForFailure,
      statusCode: 403,
      headers: {'Content-Type': 'text/plain'},
    );
  }
}

class CsrfToken {
  final String token;
  final DateTime created;
  final String? sessionKey;

  CsrfToken({
    required this.token,
    required this.created,
    this.sessionKey,
  });

  bool isExpired(Duration maxAge) {
    return DateTime.now().difference(created) > maxAge;
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'created': created.millisecondsSinceEpoch,
      'session_key': sessionKey,
    };
  }

  static CsrfToken fromJson(Map<String, dynamic> json) {
    return CsrfToken(
      token: json['token'] as String,
      created: DateTime.fromMillisecondsSinceEpoch(json['created'] as int),
      sessionKey: json['session_key'] as String?,
    );
  }
}

class CsrfTokenStorage {
  final Map<String, CsrfToken> _tokens = {};
  final Duration _maxAge;

  CsrfTokenStorage({Duration? maxAge}) 
      : _maxAge = maxAge ?? const Duration(hours: 24);

  void store(String key, CsrfToken token) {
    _cleanupExpired();
    _tokens[key] = token;
  }

  CsrfToken? get(String key) {
    _cleanupExpired();
    return _tokens[key];
  }

  void remove(String key) {
    _tokens.remove(key);
  }

  void _cleanupExpired() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _tokens.entries) {
      if (now.difference(entry.value.created) > _maxAge) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _tokens.remove(key);
    }
  }
}

class CsrfProtectionError implements Exception {
  final String message;
  final String? reason;

  CsrfProtectionError(this.message, {this.reason});

  @override
  String toString() => 'CsrfProtectionError: $message';
}

class CsrfTokenMissingError extends CsrfProtectionError {
  CsrfTokenMissingError() : super('CSRF token missing');
}

class CsrfTokenInvalidError extends CsrfProtectionError {
  CsrfTokenInvalidError() : super('CSRF token invalid');
}

class CsrfOriginMismatchError extends CsrfProtectionError {
  CsrfOriginMismatchError() : super('CSRF origin mismatch');
}

class CsrfRefererMismatchError extends CsrfProtectionError {
  CsrfRefererMismatchError() : super('CSRF referer mismatch');
}

mixin CsrfExempt {
  bool get csrfExempt => true;
}

class CsrfExemptMiddleware extends BaseMiddleware {
  final List<String> exemptPaths;
  final List<String> exemptMethods;

  CsrfExemptMiddleware({
    List<String>? exemptPaths,
    List<String>? exemptMethods,
  })  : exemptPaths = exemptPaths ?? [],
        exemptMethods = exemptMethods ?? ['GET', 'HEAD', 'OPTIONS', 'TRACE'];

  @override
  FutureOr<HttpResponse?> processView(
    HttpRequest request,
    Function viewFunc,
    List<dynamic> viewArgs,
    Map<String, dynamic> viewKwargs,
  ) {
    if (_isExempt(request)) {
      request.context['csrf_exempt'] = true;
    }
    return null;
  }

  bool _isExempt(HttpRequest request) {
    final method = request.method.toUpperCase();
    if (exemptMethods.contains(method)) {
      return true;
    }

    final path = request.uri.path;
    for (final pattern in exemptPaths) {
      if (RegExp(pattern).hasMatch(path)) {
        return true;
      }
    }

    return false;
  }
}

String generateCsrfToken() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}

String getCsrfToken(HttpRequest request) {
  final session = request.context['session'] as Session?;
  if (session != null) {
    final token = session['_csrf_token'] as String?;
    if (token != null) {
      return token;
    }
  }

  final cookieToken = request.cookies[CsrfViewMiddleware.csrfCookieName]?.value;
  if (cookieToken != null) {
    return cookieToken;
  }

  final newToken = generateCsrfToken();
  if (session != null) {
    session['_csrf_token'] = newToken;
  }

  return newToken;
}

bool verifyCsrfToken(HttpRequest request, String token) {
  final expectedToken = getCsrfToken(request);
  return _constantTimeCompare(token, expectedToken);
}

bool _constantTimeCompare(String a, String b) {
  if (a.length != b.length) {
    return false;
  }

  int result = 0;
  for (int i = 0; i < a.length; i++) {
    result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }

  return result == 0;
}