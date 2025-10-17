import 'dart:async';
import 'dart:math';

import 'package:shelf/shelf.dart';

import 'backends.dart' show SessionConfiguration;
import 'session.dart' show Session, SessionManager, SessionUtils;
import 'exceptions.dart';

class SessionMiddleware {
  final SessionManager _sessionManager;
  final SessionConfiguration _config;
  
  SessionMiddleware(this._sessionManager, this._config);

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

class CsrfMiddleware {
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

class SessionSecurityMiddleware {
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

class SessionCleanupMiddleware {
  final Duration _cleanupInterval;
  final double _cleanupProbability;
  DateTime _lastCleanup = DateTime.now();

  SessionCleanupMiddleware({
    Duration cleanupInterval = const Duration(hours: 1),
    double cleanupProbability = 0.01,
  }) : _cleanupInterval = cleanupInterval,
       _cleanupProbability = cleanupProbability;

  Handler call(Handler innerHandler) {
    return (Request request) async {
      _maybeCleanupSessions();
      return await innerHandler(request);
    };
  }
  
  void _maybeCleanupSessions() {
    final now = DateTime.now();
    final shouldCleanup = now.difference(_lastCleanup) >= _cleanupInterval;
    final randomCleanup = Random.secure().nextDouble() < _cleanupProbability;

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

class SessionMiddlewareBuilder {
  SessionConfiguration config;

  SessionMiddlewareBuilder({SessionConfiguration? config})
      : config = config ?? SessionConfiguration();

  Handler build(Handler innerHandler) {
    final sessionManager = SessionManager(config);

    Handler handler = innerHandler;

    // Add cleanup middleware
    handler = SessionCleanupMiddleware().call(handler);

    // Add security middleware
    handler = SessionSecurityMiddleware().call(handler);

    // Add CSRF middleware
    handler = CsrfMiddleware().call(handler);

    // Add session middleware (must be last)
    handler = SessionMiddleware(sessionManager, config).call(handler);

    return handler;
  }
}