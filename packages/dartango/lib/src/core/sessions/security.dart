import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../http/request.dart';
import '../http/response.dart';
import '../middleware/base.dart';
import '../utils/crypto.dart';
import 'session.dart' as session_mod;
import 'exceptions.dart';

class SessionSecuritySettings {
  final Duration sessionTimeout;
  final Duration maxIdleTime;
  final bool enableSessionRotation;
  final bool requireHttps;
  final bool enableIpBinding;
  final bool enableUserAgentBinding;
  final int maxSessionsPerUser;
  final bool enableConcurrentSessionControl;
  final Duration csrfTokenExpiry;
  final bool enableSecurityHeaders;
  final int maxFailedAttempts;
  final Duration lockoutDuration;
  final bool enableSessionFingerprinting;
  final Set<String> allowedOrigins;
  final Set<String> allowedUserAgents;
  final bool logSecurityEvents;
  
  const SessionSecuritySettings({
    this.sessionTimeout = const Duration(hours: 2),
    this.maxIdleTime = const Duration(minutes: 30),
    this.enableSessionRotation = true,
    this.requireHttps = true,
    this.enableIpBinding = false,
    this.enableUserAgentBinding = false,
    this.maxSessionsPerUser = 5,
    this.enableConcurrentSessionControl = false,
    this.csrfTokenExpiry = const Duration(hours: 1),
    this.enableSecurityHeaders = true,
    this.maxFailedAttempts = 5,
    this.lockoutDuration = const Duration(minutes: 15),
    this.enableSessionFingerprinting = true,
    this.allowedOrigins = const {},
    this.allowedUserAgents = const {},
    this.logSecurityEvents = true,
  });
  
  SessionSecuritySettings copyWith({
    Duration? sessionTimeout,
    Duration? maxIdleTime,
    bool? enableSessionRotation,
    bool? requireHttps,
    bool? enableIpBinding,
    bool? enableUserAgentBinding,
    int? maxSessionsPerUser,
    bool? enableConcurrentSessionControl,
    Duration? csrfTokenExpiry,
    bool? enableSecurityHeaders,
    int? maxFailedAttempts,
    Duration? lockoutDuration,
    bool? enableSessionFingerprinting,
    Set<String>? allowedOrigins,
    Set<String>? allowedUserAgents,
    bool? logSecurityEvents,
  }) {
    return SessionSecuritySettings(
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      maxIdleTime: maxIdleTime ?? this.maxIdleTime,
      enableSessionRotation: enableSessionRotation ?? this.enableSessionRotation,
      requireHttps: requireHttps ?? this.requireHttps,
      enableIpBinding: enableIpBinding ?? this.enableIpBinding,
      enableUserAgentBinding: enableUserAgentBinding ?? this.enableUserAgentBinding,
      maxSessionsPerUser: maxSessionsPerUser ?? this.maxSessionsPerUser,
      enableConcurrentSessionControl: enableConcurrentSessionControl ?? this.enableConcurrentSessionControl,
      csrfTokenExpiry: csrfTokenExpiry ?? this.csrfTokenExpiry,
      enableSecurityHeaders: enableSecurityHeaders ?? this.enableSecurityHeaders,
      maxFailedAttempts: maxFailedAttempts ?? this.maxFailedAttempts,
      lockoutDuration: lockoutDuration ?? this.lockoutDuration,
      enableSessionFingerprinting: enableSessionFingerprinting ?? this.enableSessionFingerprinting,
      allowedOrigins: allowedOrigins ?? this.allowedOrigins,
      allowedUserAgents: allowedUserAgents ?? this.allowedUserAgents,
      logSecurityEvents: logSecurityEvents ?? this.logSecurityEvents,
    );
  }
}

class SessionSecurityMiddleware extends BaseMiddleware {
  final SessionSecuritySettings settings;
  final Map<String, int> _failedAttempts = {};
  final Map<String, DateTime> _lockoutTimes = {};
  final Map<String, Set<String>> _userSessions = {};
  
  SessionSecurityMiddleware({required this.settings});
  
  @override
  FutureOr<HttpResponse?> processRequest(HttpRequest request) async {
    if (settings.requireHttps && !_isSecureConnection(request)) {
      return HttpResponse.forbidden('HTTPS required for session security');
    }
    
    final clientIp = _getClientIp(request);
    
    if (_isLockedOut(clientIp)) {
      _logSecurityEvent('IP_LOCKOUT', request, 'IP $clientIp is locked out');
      return HttpResponse.tooManyRequests('Too many failed attempts. Try again later.');
    }
    
    final session = request.middlewareState['session'] as session_mod.Session?;
    if (session != null) {
      final securityCheck = await _validateSessionSecurity(request, session);
      if (securityCheck != null) {
        await session.delete();
        return securityCheck;
      }
      
      await _updateSessionActivity(session, request);
    }
    
    return null;
  }
  
  @override
  FutureOr<HttpResponse> processResponse(HttpRequest request, HttpResponse response) async {
    if (settings.enableSecurityHeaders) {
      response = _addSecurityHeaders(response);
    }
    
    final session = request.middlewareState['session'] as session_mod.Session?;
    if (session != null && settings.enableSessionRotation) {
      await _rotateSessionIfNeeded(session, request);
    }
    
    return response;
  }
  
  bool _isSecureConnection(HttpRequest request) {
    return request.uri.scheme == 'https' ||
           request.headers['x-forwarded-proto']?.contains('https') == true ||
           request.headers['x-forwarded-ssl'] == 'on';
  }
  
  String _getClientIp(HttpRequest request) {
    return request.headers['x-forwarded-for']?.split(',').first.trim() ??
           request.headers['x-real-ip'] ??
           request.connectionInfo?.remoteAddress.address ??
           'unknown';
  }
  
  bool _isLockedOut(String clientIp) {
    final lockoutTime = _lockoutTimes[clientIp];
    if (lockoutTime != null) {
      if (DateTime.now().isBefore(lockoutTime)) {
        return true;
      } else {
        _lockoutTimes.remove(clientIp);
        _failedAttempts.remove(clientIp);
      }
    }
    return false;
  }
  
  Future<HttpResponse?> _validateSessionSecurity(HttpRequest request, session_mod.Session session) async {
    final sessionFingerprint = session['_security_fingerprint'] as String?;
    
    if (settings.enableSessionFingerprinting) {
      final currentFingerprint = _generateSessionFingerprint(request);
      
      if (sessionFingerprint == null) {
        session['_security_fingerprint'] = currentFingerprint;
        session['_creation_time'] = DateTime.now().millisecondsSinceEpoch;
        session['_last_activity'] = DateTime.now().millisecondsSinceEpoch;
      } else if (sessionFingerprint != currentFingerprint) {
        _logSecurityEvent('FINGERPRINT_MISMATCH', request, 'Session fingerprint mismatch');
        return HttpResponse.forbidden('Session security violation');
      }
    }
    
    final lastActivity = session['_last_activity'] as int?;
    if (lastActivity != null) {
      final idleTime = DateTime.now().millisecondsSinceEpoch - lastActivity;
      if (idleTime > settings.maxIdleTime.inMilliseconds) {
        _logSecurityEvent('SESSION_TIMEOUT', request, 'Session idle timeout');
        return HttpResponse.forbidden('Session expired due to inactivity');
      }
    }
    
    final creationTime = session['_creation_time'] as int?;
    if (creationTime != null) {
      final sessionAge = DateTime.now().millisecondsSinceEpoch - creationTime;
      if (sessionAge > settings.sessionTimeout.inMilliseconds) {
        _logSecurityEvent('SESSION_EXPIRED', request, 'Session exceeded maximum lifetime');
        return HttpResponse.forbidden('Session expired');
      }
    }
    
    if (settings.enableConcurrentSessionControl) {
      final userId = session['_user_id'] as String?;
      if (userId != null) {
        final userSessions = _userSessions[userId] ??= <String>{};
        userSessions.add(session.sessionKey);
        
        if (userSessions.length > settings.maxSessionsPerUser) {
          userSessions.remove(session.sessionKey);
          _logSecurityEvent('MAX_SESSIONS_EXCEEDED', request, 'User $userId exceeded max sessions');
          return HttpResponse.forbidden('Maximum number of concurrent sessions exceeded');
        }
      }
    }
    
    return null;
  }
  
  String _generateSessionFingerprint(HttpRequest request) {
    final components = <String>[];
    
    if (settings.enableIpBinding) {
      components.add(_getClientIp(request));
    }
    
    if (settings.enableUserAgentBinding) {
      final userAgent = request.headers['user-agent'] ?? '';
      components.add(userAgent);
    }
    
    components.add(request.headers['accept-language'] ?? '');
    components.add(request.headers['accept-encoding'] ?? '');
    
    final fingerprint = components.join('|');
    return SecureKeyGenerator.secureHash(fingerprint);
  }
  
  Future<void> _updateSessionActivity(session_mod.Session session, HttpRequest request) async {
    session['_last_activity'] = DateTime.now().millisecondsSinceEpoch;
    session['_request_count'] = (session['_request_count'] as int? ?? 0) + 1;
  }
  
  Future<void> _rotateSessionIfNeeded(session_mod.Session session, HttpRequest request) async {
    final lastRotation = session['_last_rotation'] as int?;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (lastRotation == null || (now - lastRotation) > const Duration(hours: 1).inMilliseconds) {
      await session.regenerateKey();
      session['_last_rotation'] = now;
      _logSecurityEvent('SESSION_ROTATED', request, 'Session key rotated');
    }
  }
  
  HttpResponse _addSecurityHeaders(HttpResponse response) {
    final headers = Map<String, String>.from(response.headers);
    
    headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains';
    headers['X-Frame-Options'] = 'DENY';
    headers['X-Content-Type-Options'] = 'nosniff';
    headers['X-XSS-Protection'] = '1; mode=block';
    headers['Referrer-Policy'] = 'strict-origin-when-cross-origin';
    headers['Permissions-Policy'] = 'geolocation=(), microphone=(), camera=()';
    headers['Content-Security-Policy'] = "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'";
    
    return response.change(headers: headers);
  }
  
  void recordFailedAttempt(String clientIp) {
    final attempts = _failedAttempts[clientIp] ?? 0;
    _failedAttempts[clientIp] = attempts + 1;
    
    if (_failedAttempts[clientIp]! >= settings.maxFailedAttempts) {
      _lockoutTimes[clientIp] = DateTime.now().add(settings.lockoutDuration);
      _logSecurityEvent('IP_LOCKED', null, 'IP $clientIp locked out after ${settings.maxFailedAttempts} failed attempts');
    }
  }
  
  void resetFailedAttempts(String clientIp) {
    _failedAttempts.remove(clientIp);
    _lockoutTimes.remove(clientIp);
  }
  
  void _logSecurityEvent(String eventType, HttpRequest? request, String description) {
    if (!settings.logSecurityEvents) return;
    
    final timestamp = DateTime.now().toIso8601String();
    final clientIp = request != null ? _getClientIp(request) : 'unknown';
    final userAgent = request?.headers['user-agent'] ?? 'unknown';
    
    print('[$timestamp] SECURITY_EVENT: $eventType - $description (IP: $clientIp, UA: $userAgent)');
  }
}

class CsrfSecurityMiddleware extends BaseMiddleware {
  final SessionSecuritySettings settings;
  final Set<String> _safeMethods = {'GET', 'HEAD', 'OPTIONS', 'TRACE'};
  
  CsrfSecurityMiddleware({required this.settings});
  
  @override
  FutureOr<HttpResponse?> processRequest(HttpRequest request) async {
    if (settings.requireHttps && !_isSecureConnection(request)) {
      return HttpResponse.forbidden('HTTPS required for CSRF protection');
    }
    
    final session = request.middlewareState['session'] as session_mod.Session?;
    if (session == null) {
      return HttpResponse.forbidden('Session required for CSRF protection');
    }
    
    final csrfToken = _getOrCreateCsrfToken(session);
    request.middlewareState['csrf_token'] = csrfToken;
    
    if (!_safeMethods.contains(request.method.toUpperCase())) {
      final providedToken = _extractCsrfToken(request);
      
      if (providedToken == null) {
        _logSecurityEvent('CSRF_TOKEN_MISSING', request);
        return HttpResponse.forbidden('CSRF token missing');
      }
      
      if (!_validateCsrfToken(session, providedToken)) {
        _logSecurityEvent('CSRF_TOKEN_INVALID', request);
        return HttpResponse.forbidden('CSRF token invalid');
      }
      
      if (_isCsrfTokenExpired(session)) {
        _logSecurityEvent('CSRF_TOKEN_EXPIRED', request);
        return HttpResponse.forbidden('CSRF token expired');
      }
    }
    
    return null;
  }
  
  @override
  FutureOr<HttpResponse> processResponse(HttpRequest request, HttpResponse response) async {
    final csrfToken = request.middlewareState['csrf_token'] as String?;
    if (csrfToken != null) {
      final headers = Map<String, String>.from(response.headers);
      headers['X-CSRFToken'] = csrfToken;
      response = response.change(headers: headers);
    }
    
    return response;
  }
  
  bool _isSecureConnection(HttpRequest request) {
    return request.uri.scheme == 'https' ||
           request.headers['x-forwarded-proto']?.contains('https') == true ||
           request.headers['x-forwarded-ssl'] == 'on';
  }
  
  String _getOrCreateCsrfToken(session_mod.Session session) {
    String? token = session['_csrf_token'];
    
    if (token == null || _isCsrfTokenExpired(session)) {
      token = CryptoUtils.createCsrfToken();
      session['_csrf_token'] = token;
      session['_csrf_token_created'] = DateTime.now().millisecondsSinceEpoch;
    }
    
    return token;
  }
  
  String? _extractCsrfToken(HttpRequest request) {
    final headerToken = request.headers['x-csrftoken'] ?? 
                       request.headers['x-csrf-token'];
    
    if (headerToken != null) {
      return headerToken;
    }
    
    return null;
  }
  
  bool _validateCsrfToken(session_mod.Session session, String providedToken) {
    final sessionToken = session['_csrf_token'] as String?;
    if (sessionToken == null) return false;
    
    return CryptoUtils.constantTimeEquals(sessionToken, providedToken);
  }
  
  bool _isCsrfTokenExpired(session_mod.Session session) {
    final created = session['_csrf_token_created'] as int?;
    if (created == null) return true;
    
    final age = DateTime.now().millisecondsSinceEpoch - created;
    return age > settings.csrfTokenExpiry.inMilliseconds;
  }
  
  void _logSecurityEvent(String eventType, HttpRequest request) {
    if (!settings.logSecurityEvents) return;
    
    final timestamp = DateTime.now().toIso8601String();
    final clientIp = request.headers['x-forwarded-for']?.split(',').first.trim() ??
                     request.headers['x-real-ip'] ??
                     request.connectionInfo?.remoteAddress.address ??
                     'unknown';
    
    print('[$timestamp] CSRF_EVENT: $eventType (IP: $clientIp, Path: ${request.uri.path})');
  }
}

class SessionAnomalyDetector {
  final Map<String, SessionBehaviorProfile> _profiles = {};
  final SessionSecuritySettings settings;
  
  SessionAnomalyDetector({required this.settings});
  
  Future<bool> detectAnomaly(HttpRequest request, session_mod.Session session) async {
    final sessionKey = session.sessionKey;
    final profile = _profiles[sessionKey] ??= SessionBehaviorProfile();
    
    final currentBehavior = _extractBehaviorMetrics(request);
    final isAnomalous = profile.isAnomalous(currentBehavior);
    
    profile.update(currentBehavior);
    
    if (isAnomalous && settings.logSecurityEvents) {
      _logAnomaly(request, currentBehavior);
    }
    
    return isAnomalous;
  }
  
  SessionBehaviorMetrics _extractBehaviorMetrics(HttpRequest request) {
    return SessionBehaviorMetrics(
      timestamp: DateTime.now(),
      userAgent: request.headers['user-agent'] ?? '',
      ipAddress: request.headers['x-forwarded-for']?.split(',').first.trim() ??
                 request.headers['x-real-ip'] ??
                 'unknown',
      requestPath: request.uri.path,
      requestMethod: request.method,
      referrer: request.headers['referer'] ?? '',
    );
  }
  
  void _logAnomaly(HttpRequest request, SessionBehaviorMetrics behavior) {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] ANOMALY_DETECTED: ${behavior.toString()}');
  }
}

class SessionBehaviorProfile {
  final List<SessionBehaviorMetrics> _history = [];
  static const int maxHistorySize = 100;
  
  bool isAnomalous(SessionBehaviorMetrics current) {
    if (_history.isEmpty) return false;
    
    final recentBehavior = _history.take(10).toList();
    
    final ipChanges = recentBehavior.map((b) => b.ipAddress).toSet().length;
    if (ipChanges > 3) return true;
    
    final userAgentChanges = recentBehavior.map((b) => b.userAgent).toSet().length;
    if (userAgentChanges > 2) return true;
    
    final timeDiffs = <int>[];
    for (int i = 1; i < recentBehavior.length; i++) {
      final diff = recentBehavior[i].timestamp.difference(recentBehavior[i-1].timestamp).inMilliseconds;
      timeDiffs.add(diff);
    }
    
    if (timeDiffs.isNotEmpty) {
      final avgTimeDiff = timeDiffs.reduce((a, b) => a + b) / timeDiffs.length;
      final currentDiff = current.timestamp.difference(_history.last.timestamp).inMilliseconds;
      
      if (currentDiff < avgTimeDiff * 0.1) return true;
    }
    
    return false;
  }
  
  void update(SessionBehaviorMetrics metrics) {
    _history.insert(0, metrics);
    if (_history.length > maxHistorySize) {
      _history.removeLast();
    }
  }
}

class SessionBehaviorMetrics {
  final DateTime timestamp;
  final String userAgent;
  final String ipAddress;
  final String requestPath;
  final String requestMethod;
  final String referrer;
  
  SessionBehaviorMetrics({
    required this.timestamp,
    required this.userAgent,
    required this.ipAddress,
    required this.requestPath,
    required this.requestMethod,
    required this.referrer,
  });
  
  @override
  String toString() {
    return 'SessionBehaviorMetrics(timestamp: $timestamp, ip: $ipAddress, path: $requestPath, method: $requestMethod)';
  }
}

class SessionSecurityManager {
  final SessionSecuritySettings settings;
  final SessionAnomalyDetector _anomalyDetector;
  
  SessionSecurityManager({required this.settings})
      : _anomalyDetector = SessionAnomalyDetector(settings: settings);
  
  Future<bool> validateSessionSecurity(HttpRequest request, session_mod.Session session) async {
    if (settings.enableSessionFingerprinting) {
      final fingerprint = _generateFingerprint(request);
      final storedFingerprint = session['_security_fingerprint'] as String?;
      
      if (storedFingerprint == null) {
        session['_security_fingerprint'] = fingerprint;
      } else if (storedFingerprint != fingerprint) {
        return false;
      }
    }
    
    final isAnomalous = await _anomalyDetector.detectAnomaly(request, session);
    return !isAnomalous;
  }
  
  String _generateFingerprint(HttpRequest request) {
    final components = [
      request.headers['user-agent'] ?? '',
      request.headers['accept-language'] ?? '',
      request.headers['accept-encoding'] ?? '',
    ];
    
    if (settings.enableIpBinding) {
      final ip = request.headers['x-forwarded-for']?.split(',').first.trim() ??
                 request.headers['x-real-ip'] ??
                 'unknown';
      components.add(ip);
    }
    
    return SecureKeyGenerator.secureHash(components.join('|'));
  }
  
  void rotateSession(session_mod.Session session) {
    session.regenerateKey();
    session['_last_rotation'] = DateTime.now().millisecondsSinceEpoch;
  }
}