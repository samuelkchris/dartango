import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../middleware/middleware.dart';
import '../utils/crypto.dart';
import 'backends.dart';
import 'session.dart';
import 'exceptions.dart';

class SessionMiddleware extends DartangoMiddleware {
  final SessionManager _sessionManager;
  final SessionConfiguration _config;
  
  SessionMiddleware(this._sessionManager, this._config);
  
  @override
  Handler call(Handler innerHandler) {
    return (Request request) async {
      Session? session;
      String? sessionKey;
      
      try {
        sessionKey = _extractSessionKey(request);
        session = await _sessionManager.createSession(sessionKey);
        
        final requestWithSession = request.change(context: {
          ...request.context,
          'session': session,
        });
        
        final response = await innerHandler(requestWithSession);
        
        if (session.modified || _config.saveEveryRequest) {
          await session.save();
        }
        
        return _addSessionCookie(response, session);
        
      } catch (e) {
        if (session != null) {
          try {
            await session.save();
          } catch (saveError) {
            print('Failed to save session: $saveError');
          }
        }
        rethrow;
      }
    };
  }
  
  String? _extractSessionKey(Request request) {
    final cookieHeader = request.headers['cookie'];
    return SessionUtils.extractSessionKeyFromCookie(cookieHeader, _config.cookieName);
  }
  
  Response _addSessionCookie(Response response, Session session) {
    if (session.sessionKey.isEmpty) {
      return response;
    }
    
    final cookieHeaders = SessionUtils.createSessionCookie(
      session.sessionKey,
      _config,
    );
    
    final existingHeaders = Map<String, String>.from(response.headers);
    existingHeaders.addAll(cookieHeaders);
    
    return response.change(headers: existingHeaders);
  }
}

class SessionRequest {
  final Request _request;
  Session? _session;
  
  SessionRequest(this._request);
  
  Session get session {
    if (_session == null) {
      throw SessionException('Session not available. Make sure SessionMiddleware is enabled.');
    }
    return _session!;
  }
  
  bool get hasSession => _session != null;
  
  void _setSession(Session session) {
    _session = session;
  }
  
  Request get request => _request;
}

extension SessionRequestExtension on Request {
  Session get session {
    final session = context['session'] as Session?;
    if (session == null) {
      throw SessionException('Session not available. Make sure SessionMiddleware is enabled.');
    }
    return session;
  }
  
  bool get hasSession => context.containsKey('session');
}

class CsrfMiddleware extends DartangoMiddleware {
  final Set<String> _safeMethods = {'GET', 'HEAD', 'OPTIONS', 'TRACE'};
  final String _csrfHeaderName;
  final String _csrfFormFieldName;
  final bool _requireHttps;
  
  CsrfMiddleware({
    String csrfHeaderName = 'X-CSRFToken',
    String csrfFormFieldName = 'csrfmiddlewaretoken',
    bool requireHttps = true,
  }) : _csrfHeaderName = csrfHeaderName,
       _csrfFormFieldName = csrfFormFieldName,
       _requireHttps = requireHttps;
  
  @override
  Handler call(Handler innerHandler) {
    return (Request request) async {
      if (_requireHttps && !_isHttps(request)) {
        return Response.forbidden('CSRF protection requires HTTPS');
      }
      
      if (!request.hasSession) {
        return Response.forbidden('CSRF protection requires sessions');
      }
      
      final session = request.session;
      final csrfToken = await session.getOrCreateCsrfToken();
      
      if (!_safeMethods.contains(request.method.toUpperCase())) {
        final providedToken = _extractCsrfToken(request);
        
        if (providedToken == null || !await session.validateCsrfToken(providedToken)) {
          return Response.forbidden('CSRF token missing or invalid');
        }
      }
      
      final requestWithCsrf = request.change(context: {
        ...request.context,
        'csrf_token': csrfToken,
      });
      
      final response = await innerHandler(requestWithCsrf);
      
      return _addCsrfHeaders(response, csrfToken);
    };
  }
  
  bool _isHttps(Request request) {
    return request.requestedUri.scheme == 'https' ||
           request.headers['x-forwarded-proto'] == 'https' ||
           request.headers['x-forwarded-ssl'] == 'on';
  }
  
  String? _extractCsrfToken(Request request) {
    final headerToken = request.headers[_csrfHeaderName.toLowerCase()];
    if (headerToken != null) {
      return headerToken;
    }
    
    if (request.method.toUpperCase() == 'POST') {
      return _extractFormCsrfToken(request);
    }
    
    return null;
  }
  
  String? _extractFormCsrfToken(Request request) {
    final contentType = request.headers['content-type'];
    if (contentType == null || !contentType.contains('application/x-www-form-urlencoded')) {
      return null;
    }
    
    return null;
  }
  
  Response _addCsrfHeaders(Response response, String csrfToken) {
    final headers = Map<String, String>.from(response.headers);
    headers['X-CSRF-Token'] = csrfToken;
    
    return response.change(headers: headers);
  }
}

extension CsrfRequestExtension on Request {
  String get csrfToken {
    final token = context['csrf_token'] as String?;
    if (token == null) {
      throw SessionException('CSRF token not available. Make sure CsrfMiddleware is enabled.');
    }
    return token;
  }
  
  bool get hasCsrfToken => context.containsKey('csrf_token');
}

class SessionSecurityMiddleware extends DartangoMiddleware {
  final Duration _sessionTimeout;
  final bool _renewOnActivity;
  final bool _rotateOnLogin;
  final int _maxSessionsPerUser;
  
  SessionSecurityMiddleware({
    Duration sessionTimeout = const Duration(hours: 2),
    bool renewOnActivity = true,
    bool rotateOnLogin = true,
    int maxSessionsPerUser = 5,
  }) : _sessionTimeout = sessionTimeout,
       _renewOnActivity = renewOnActivity,
       _rotateOnLogin = rotateOnLogin,
       _maxSessionsPerUser = maxSessionsPerUser;
  
  @override
  Handler call(Handler innerHandler) {
    return (Request request) async {
      if (!request.hasSession) {
        return await innerHandler(request);
      }
      
      final session = request.session;
      
      if (await session.isExpired()) {
        await session.flush();
        return Response.forbidden('Session expired');
      }
      
      if (_renewOnActivity) {
        await session.touch();
      }
      
      final response = await innerHandler(request);
      
      return _addSecurityHeaders(response);
    };
  }
  
  Response _addSecurityHeaders(Response response) {
    final headers = Map<String, String>.from(response.headers);
    
    headers['X-Frame-Options'] = 'DENY';
    headers['X-Content-Type-Options'] = 'nosniff';
    headers['X-XSS-Protection'] = '1; mode=block';
    headers['Referrer-Policy'] = 'strict-origin-when-cross-origin';
    headers['Content-Security-Policy'] = "default-src 'self'";
    
    return response.change(headers: headers);
  }
}

class SessionCleanupMiddleware extends DartangoMiddleware {
  final Duration _cleanupInterval;
  final double _cleanupProbability;
  DateTime _lastCleanup = DateTime.now();
  
  SessionCleanupMiddleware({
    Duration cleanupInterval = const Duration(hours: 1),
    double cleanupProbability = 0.01,
  }) : _cleanupInterval = cleanupInterval,
       _cleanupProbability = cleanupProbability;
  
  @override
  Handler call(Handler innerHandler) {
    return (Request request) async {
      _maybeCleanupSessions();
      return await innerHandler(request);
    };
  }
  
  void _maybeCleanupSessions() {
    final now = DateTime.now();
    final shouldCleanup = now.difference(_lastCleanup) >= _cleanupInterval;
    final randomCleanup = CryptoUtils.generateRandomDouble() < _cleanupProbability;
    
    if (shouldCleanup || randomCleanup) {
      _performCleanup();
      _lastCleanup = now;
    }
  }
  
  Future<void> _performCleanup() async {
    try {
      print('Performing session cleanup...');
    } catch (e) {
      print('Session cleanup failed: $e');
    }
  }
}

class SessionConfiguration {
  final String engine;
  final Duration cookieAge;
  final String? cookieDomain;
  final String cookiePath;
  final bool cookieSecure;
  final bool cookieHttpOnly;
  final String? cookieSameSite;
  final String cookieName;
  final bool saveEveryRequest;
  final bool expireAtBrowserClose;
  final Map<String, dynamic> engineOptions;
  final bool csrfProtectionEnabled;
  final bool sessionSecurityEnabled;
  final bool sessionCleanupEnabled;
  
  const SessionConfiguration({
    this.engine = 'database',
    this.cookieAge = const Duration(days: 14),
    this.cookieDomain,
    this.cookiePath = '/',
    this.cookieSecure = false,
    this.cookieHttpOnly = true,
    this.cookieSameSite,
    this.cookieName = 'sessionid',
    this.saveEveryRequest = false,
    this.expireAtBrowserClose = false,
    this.engineOptions = const {},
    this.csrfProtectionEnabled = true,
    this.sessionSecurityEnabled = true,
    this.sessionCleanupEnabled = true,
  });
  
  SessionConfiguration copyWith({
    String? engine,
    Duration? cookieAge,
    String? cookieDomain,
    String? cookiePath,
    bool? cookieSecure,
    bool? cookieHttpOnly,
    String? cookieSameSite,
    String? cookieName,
    bool? saveEveryRequest,
    bool? expireAtBrowserClose,
    Map<String, dynamic>? engineOptions,
    bool? csrfProtectionEnabled,
    bool? sessionSecurityEnabled,
    bool? sessionCleanupEnabled,
  }) {
    return SessionConfiguration(
      engine: engine ?? this.engine,
      cookieAge: cookieAge ?? this.cookieAge,
      cookieDomain: cookieDomain ?? this.cookieDomain,
      cookiePath: cookiePath ?? this.cookiePath,
      cookieSecure: cookieSecure ?? this.cookieSecure,
      cookieHttpOnly: cookieHttpOnly ?? this.cookieHttpOnly,
      cookieSameSite: cookieSameSite ?? this.cookieSameSite,
      cookieName: cookieName ?? this.cookieName,
      saveEveryRequest: saveEveryRequest ?? this.saveEveryRequest,
      expireAtBrowserClose: expireAtBrowserClose ?? this.expireAtBrowserClose,
      engineOptions: engineOptions ?? this.engineOptions,
      csrfProtectionEnabled: csrfProtectionEnabled ?? this.csrfProtectionEnabled,
      sessionSecurityEnabled: sessionSecurityEnabled ?? this.sessionSecurityEnabled,
      sessionCleanupEnabled: sessionCleanupEnabled ?? this.sessionCleanupEnabled,
    );
  }
}

class SessionMiddlewareBuilder {
  SessionConfiguration _config = const SessionConfiguration();
  
  SessionMiddlewareBuilder withConfiguration(SessionConfiguration config) {
    _config = config;
    return this;
  }
  
  SessionMiddlewareBuilder withEngine(String engine) {
    _config = _config.copyWith(engine: engine);
    return this;
  }
  
  SessionMiddlewareBuilder withCookieAge(Duration age) {
    _config = _config.copyWith(cookieAge: age);
    return this;
  }
  
  SessionMiddlewareBuilder withCookieName(String name) {
    _config = _config.copyWith(cookieName: name);
    return this;
  }
  
  SessionMiddlewareBuilder withCookieSecure(bool secure) {
    _config = _config.copyWith(cookieSecure: secure);
    return this;
  }
  
  SessionMiddlewareBuilder withCsrfProtection(bool enabled) {
    _config = _config.copyWith(csrfProtectionEnabled: enabled);
    return this;
  }
  
  SessionMiddlewareBuilder withEngineOptions(Map<String, dynamic> options) {
    _config = _config.copyWith(engineOptions: options);
    return this;
  }
  
  Handler build(Handler innerHandler) {
    final sessionManager = SessionManager(_config);
    
    Handler handler = innerHandler;
    
    if (_config.sessionCleanupEnabled) {
      handler = SessionCleanupMiddleware().call(handler);
    }
    
    if (_config.sessionSecurityEnabled) {
      handler = SessionSecurityMiddleware().call(handler);
    }
    
    if (_config.csrfProtectionEnabled) {
      handler = CsrfMiddleware().call(handler);
    }
    
    handler = SessionMiddleware(sessionManager, _config).call(handler);
    
    return handler;
  }
}