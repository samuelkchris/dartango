import 'package:test/test.dart';

import '../../../lib/src/core/sessions/security.dart';
import '../../../lib/src/core/http/request.dart';
import '../../../lib/src/core/http/response.dart';
import '../../../lib/src/core/middleware/session.dart' as session_middleware;

void main() {
  group('SessionSecuritySettings', () {
    test('default settings', () {
      const settings = SessionSecuritySettings();
      
      expect(settings.sessionTimeout, equals(Duration(hours: 2)));
      expect(settings.maxIdleTime, equals(Duration(minutes: 30)));
      expect(settings.enableSessionRotation, isTrue);
      expect(settings.requireHttps, isTrue);
      expect(settings.enableIpBinding, isFalse);
      expect(settings.enableUserAgentBinding, isFalse);
      expect(settings.maxSessionsPerUser, equals(5));
      expect(settings.enableConcurrentSessionControl, isFalse);
      expect(settings.csrfTokenExpiry, equals(Duration(hours: 1)));
      expect(settings.enableSecurityHeaders, isTrue);
      expect(settings.maxFailedAttempts, equals(5));
      expect(settings.lockoutDuration, equals(Duration(minutes: 15)));
      expect(settings.enableSessionFingerprinting, isTrue);
      expect(settings.logSecurityEvents, isTrue);
    });
    
    test('copyWith creates modified settings', () {
      const settings = SessionSecuritySettings();
      final modified = settings.copyWith(
        sessionTimeout: const Duration(hours: 4),
        requireHttps: false,
        enableIpBinding: true,
        maxSessionsPerUser: 10,
      );
      
      expect(modified.sessionTimeout, equals(Duration(hours: 4)));
      expect(modified.requireHttps, isFalse);
      expect(modified.enableIpBinding, isTrue);
      expect(modified.maxSessionsPerUser, equals(10));
      expect(modified.maxIdleTime, equals(settings.maxIdleTime));
    });
  });
  
  group('SessionSecurityMiddleware', () {
    late SessionSecurityMiddleware middleware;
    late SessionSecuritySettings settings;
    
    setUp(() {
      settings = const SessionSecuritySettings(
        requireHttps: false,
        enableSessionFingerprinting: true,
        maxIdleTime: Duration(minutes: 5),
        sessionTimeout: Duration(hours: 1),
      );
      middleware = SessionSecurityMiddleware(settings: settings);
    });
    
    test('allows secure connections when HTTPS required', () async {
      final httpsSettings = settings.copyWith(requireHttps: true);
      final httpsMiddleware = SessionSecurityMiddleware(settings: httpsSettings);
      
      final secureRequest = MockHttpRequest(
        uri: Uri.parse('https://example.com/test'),
        headers: {},
      );
      
      final response = await httpsMiddleware.processRequest(secureRequest);
      expect(response, isNull);
    });
    
    test('blocks insecure connections when HTTPS required', () async {
      final httpsSettings = settings.copyWith(requireHttps: true);
      final httpsMiddleware = SessionSecurityMiddleware(settings: httpsSettings);
      
      final insecureRequest = MockHttpRequest(
        uri: Uri.parse('http://example.com/test'),
        headers: {},
      );
      
      final response = await httpsMiddleware.processRequest(insecureRequest);
      expect(response, isNotNull);
      expect(response!.statusCode, equals(403));
    });
    
    test('detects X-Forwarded-Proto header for HTTPS', () async {
      final httpsSettings = settings.copyWith(requireHttps: true);
      final httpsMiddleware = SessionSecurityMiddleware(settings: httpsSettings);
      
      final request = MockHttpRequest(
        uri: Uri.parse('http://example.com/test'),
        headers: {'x-forwarded-proto': 'https'},
      );
      
      final response = await httpsMiddleware.processRequest(request);
      expect(response, isNull);
    });
    
    test('adds security headers in response', () async {
      final request = MockHttpRequest(
        uri: Uri.parse('http://example.com/test'),
        headers: {},
      );
      
      final originalResponse = HttpResponse.ok('test');
      final response = await middleware.processResponse(request, originalResponse);
      
      expect(response.headers['X-Frame-Options'], equals('DENY'));
      expect(response.headers['X-Content-Type-Options'], equals('nosniff'));
      expect(response.headers['X-XSS-Protection'], equals('1; mode=block'));
      expect(response.headers['Referrer-Policy'], equals('strict-origin-when-cross-origin'));
      expect(response.headers['Content-Security-Policy'], contains("default-src 'self'"));
    });
    
    test('validates session fingerprint', () async {
      final session = session_middleware.Session(
        sessionKey: 'test-key',
        store: MockSessionStore(),
      );
      
      final request = MockHttpRequest(
        uri: Uri.parse('http://example.com/test'),
        headers: {
          'user-agent': 'Test Browser 1.0',
          'accept-language': 'en-US,en;q=0.9',
          'accept-encoding': 'gzip, deflate',
        },
      );
      request.middlewareState['session'] = session;
      
      final response = await middleware.processRequest(request);
      expect(response, isNull);
      expect(session['_security_fingerprint'], isNotNull);
    });
    
    test('detects fingerprint mismatch', () async {
      final session = session_middleware.Session(
        sessionKey: 'test-key',
        store: MockSessionStore(),
      );
      session['_security_fingerprint'] = 'old-fingerprint';
      session['_creation_time'] = DateTime.now().millisecondsSinceEpoch;
      session['_last_activity'] = DateTime.now().millisecondsSinceEpoch;
      
      final request = MockHttpRequest(
        uri: Uri.parse('http://example.com/test'),
        headers: {
          'user-agent': 'Different Browser 2.0',
          'accept-language': 'fr-FR,fr;q=0.9',
          'accept-encoding': 'br, gzip',
        },
      );
      request.middlewareState['session'] = session;
      
      final response = await middleware.processRequest(request);
      expect(response, isNotNull);
      expect(response!.statusCode, equals(403));
    });
    
    test('detects session timeout', () async {
      final session = session_middleware.Session(
        sessionKey: 'test-key',
        store: MockSessionStore(),
      );
      session['_creation_time'] = DateTime.now().subtract(const Duration(hours: 2)).millisecondsSinceEpoch;
      session['_last_activity'] = DateTime.now().millisecondsSinceEpoch;
      
      final request = MockHttpRequest(
        uri: Uri.parse('http://example.com/test'),
        headers: {},
      );
      request.middlewareState['session'] = session;
      
      final response = await middleware.processRequest(request);
      expect(response, isNotNull);
      expect(response!.statusCode, equals(403));
    });
    
    test('detects idle timeout', () async {
      final session = session_middleware.Session(
        sessionKey: 'test-key',
        store: MockSessionStore(),
      );
      session['_creation_time'] = DateTime.now().millisecondsSinceEpoch;
      session['_last_activity'] = DateTime.now().subtract(const Duration(minutes: 10)).millisecondsSinceEpoch;
      
      final request = MockHttpRequest(
        uri: Uri.parse('http://example.com/test'),
        headers: {},
      );
      request.middlewareState['session'] = session;
      
      final response = await middleware.processRequest(request);
      expect(response, isNotNull);
      expect(response!.statusCode, equals(403));
    });
    
    test('records and enforces failed attempts', () async {
      const clientIp = '192.168.1.100';
      
      for (int i = 0; i < 5; i++) {
        middleware.recordFailedAttempt(clientIp);
      }
      
      final request = MockHttpRequest(
        uri: Uri.parse('http://example.com/test'),
        headers: {'x-forwarded-for': clientIp},
      );
      
      final response = await middleware.processRequest(request);
      expect(response, isNotNull);
      expect(response!.statusCode, equals(429));
    });
    
    test('resets failed attempts on success', () async {
      const clientIp = '192.168.1.100';
      
      middleware.recordFailedAttempt(clientIp);
      middleware.recordFailedAttempt(clientIp);
      middleware.resetFailedAttempts(clientIp);
      
      final request = MockHttpRequest(
        uri: Uri.parse('http://example.com/test'),
        headers: {'x-forwarded-for': clientIp},
      );
      
      final response = await middleware.processRequest(request);
      expect(response, isNull);
    });
  });
  
  group('CsrfSecurityMiddleware', () {
    late CsrfSecurityMiddleware middleware;
    late SessionSecuritySettings settings;
    
    setUp(() {
      settings = const SessionSecuritySettings(requireHttps: false);
      middleware = CsrfSecurityMiddleware(settings: settings);
    });
    
    test('allows safe methods without CSRF token', () async {
      final session = session_middleware.Session(
        sessionKey: 'test-key',
        store: MockSessionStore(),
      );
      
      final request = MockHttpRequest(
        uri: Uri.parse('http://example.com/test'),
        method: 'GET',
        headers: {},
      );
      request.middlewareState['session'] = session;
      
      final response = await middleware.processRequest(request);
      expect(response, isNull);
    });
    
    test('requires CSRF token for unsafe methods', () async {
      final session = session_middleware.Session(
        sessionKey: 'test-key',
        store: MockSessionStore(),
      );
      
      final request = MockHttpRequest(
        uri: Uri.parse('http://example.com/test'),
        method: 'POST',
        headers: {},
      );
      request.middlewareState['session'] = session;
      
      final response = await middleware.processRequest(request);
      expect(response, isNotNull);
      expect(response!.statusCode, equals(403));
    });
    
    test('validates CSRF token from header', () async {
      final session = session_middleware.Session(
        sessionKey: 'test-key',
        store: MockSessionStore(),
      );
      session['_csrf_token'] = 'valid-token';
      session['_csrf_token_created'] = DateTime.now().millisecondsSinceEpoch;
      
      final request = MockHttpRequest(
        uri: Uri.parse('http://example.com/test'),
        method: 'POST',
        headers: {'x-csrftoken': 'valid-token'},
      );
      request.middlewareState['session'] = session;
      
      final response = await middleware.processRequest(request);
      expect(response, isNull);
    });
    
    test('rejects invalid CSRF token', () async {
      final session = session_middleware.Session(
        sessionKey: 'test-key',
        store: MockSessionStore(),
      );
      session['_csrf_token'] = 'valid-token';
      session['_csrf_token_created'] = DateTime.now().millisecondsSinceEpoch;
      
      final request = MockHttpRequest(
        uri: Uri.parse('http://example.com/test'),
        method: 'POST',
        headers: {'x-csrftoken': 'invalid-token'},
      );
      request.middlewareState['session'] = session;
      
      final response = await middleware.processRequest(request);
      expect(response, isNotNull);
      expect(response!.statusCode, equals(403));
    });
    
    test('rejects expired CSRF token', () async {
      final session = session_middleware.Session(
        sessionKey: 'test-key',
        store: MockSessionStore(),
      );
      session['_csrf_token'] = 'valid-token';
      session['_csrf_token_created'] = DateTime.now().subtract(const Duration(hours: 2)).millisecondsSinceEpoch;
      
      final request = MockHttpRequest(
        uri: Uri.parse('http://example.com/test'),
        method: 'POST',
        headers: {'x-csrftoken': 'valid-token'},
      );
      request.middlewareState['session'] = session;
      
      final response = await middleware.processRequest(request);
      expect(response, isNotNull);
      expect(response!.statusCode, equals(403));
    });
    
    test('adds CSRF token to response headers', () async {
      final session = session_middleware.Session(
        sessionKey: 'test-key',
        store: MockSessionStore(),
      );
      
      final request = MockHttpRequest(
        uri: Uri.parse('http://example.com/test'),
        method: 'GET',
        headers: {},
      );
      request.middlewareState['session'] = session;
      
      await middleware.processRequest(request);
      
      final originalResponse = HttpResponse.ok('test');
      final response = await middleware.processResponse(request, originalResponse);
      
      expect(response.headers['X-CSRFToken'], isNotNull);
      expect(response.headers['X-CSRFToken'], isA<String>());
    });
  });
  
  group('SessionAnomalyDetector', () {
    late SessionAnomalyDetector detector;
    late SessionSecuritySettings settings;
    
    setUp(() {
      settings = const SessionSecuritySettings();
      detector = SessionAnomalyDetector(settings: settings);
    });
    
    test('does not detect anomaly for first request', () async {
      final session = session_middleware.Session(
        sessionKey: 'test-key',
        store: MockSessionStore(),
      );
      
      final request = MockHttpRequest(
        uri: Uri.parse('http://example.com/test'),
        headers: {'user-agent': 'Test Browser 1.0'},
      );
      
      final isAnomalous = await detector.detectAnomaly(request, session);
      expect(isAnomalous, isFalse);
    });
    
    test('detects IP address changes', () async {
      final session = session_middleware.Session(
        sessionKey: 'test-key',
        store: MockSessionStore(),
      );
      
      final ips = ['192.168.1.1', '192.168.1.2', '192.168.1.3', '192.168.1.4'];
      for (final ip in ips) {
        final request = MockHttpRequest(
          uri: Uri.parse('http://example.com/test'),
          headers: {'x-forwarded-for': ip, 'user-agent': 'Test Browser 1.0'},
        );
        await detector.detectAnomaly(request, session);
      }
      
      final anomalousRequest = MockHttpRequest(
        uri: Uri.parse('http://example.com/test'),
        headers: {'x-forwarded-for': '192.168.1.5', 'user-agent': 'Test Browser 1.0'},
      );
      
      final isAnomalous = await detector.detectAnomaly(anomalousRequest, session);
      expect(isAnomalous, isTrue);
    });
    
    test('detects user agent changes', () async {
      final session = session_middleware.Session(
        sessionKey: 'test-key',
        store: MockSessionStore(),
      );
      
      final userAgents = ['Browser A', 'Browser B'];
      for (final ua in userAgents) {
        final request = MockHttpRequest(
          uri: Uri.parse('http://example.com/test'),
          headers: {'user-agent': ua},
        );
        await detector.detectAnomaly(request, session);
      }
      
      final anomalousRequest = MockHttpRequest(
        uri: Uri.parse('http://example.com/test'),
        headers: {'user-agent': 'Browser C'},
      );
      
      final isAnomalous = await detector.detectAnomaly(anomalousRequest, session);
      expect(isAnomalous, isTrue);
    });
  });
  
  group('SessionBehaviorProfile', () {
    late SessionBehaviorProfile profile;
    
    setUp(() {
      profile = SessionBehaviorProfile();
    });
    
    test('creates behavior metrics', () {
      final metrics = SessionBehaviorMetrics(
        timestamp: DateTime.now(),
        userAgent: 'Test Browser 1.0',
        ipAddress: '192.168.1.1',
        requestPath: '/test',
        requestMethod: 'GET',
        referrer: 'https://example.com',
      );
      
      expect(metrics.userAgent, equals('Test Browser 1.0'));
      expect(metrics.ipAddress, equals('192.168.1.1'));
      expect(metrics.requestPath, equals('/test'));
      expect(metrics.requestMethod, equals('GET'));
      expect(metrics.referrer, equals('https://example.com'));
    });
    
    test('updates behavior history', () {
      final metrics1 = SessionBehaviorMetrics(
        timestamp: DateTime.now(),
        userAgent: 'Browser 1',
        ipAddress: '192.168.1.1',
        requestPath: '/test1',
        requestMethod: 'GET',
        referrer: '',
      );
      
      final metrics2 = SessionBehaviorMetrics(
        timestamp: DateTime.now(),
        userAgent: 'Browser 1',
        ipAddress: '192.168.1.1',
        requestPath: '/test2',
        requestMethod: 'POST',
        referrer: '',
      );
      
      profile.update(metrics1);
      profile.update(metrics2);
      
      expect(profile.isAnomalous(metrics1), isFalse);
    });
  });
  
  group('SessionSecurityManager', () {
    late SessionSecurityManager manager;
    late SessionSecuritySettings settings;
    
    setUp(() {
      settings = const SessionSecuritySettings(
        enableSessionFingerprinting: true,
        enableIpBinding: true,
      );
      manager = SessionSecurityManager(settings: settings);
    });
    
    test('validates session security', () async {
      final session = session_middleware.Session(
        sessionKey: 'test-key',
        store: MockSessionStore(),
      );
      
      final request = MockHttpRequest(
        uri: Uri.parse('http://example.com/test'),
        headers: {
          'user-agent': 'Test Browser 1.0',
          'x-forwarded-for': '192.168.1.1',
          'accept-language': 'en-US',
          'accept-encoding': 'gzip',
        },
      );
      
      final isValid = await manager.validateSessionSecurity(request, session);
      expect(isValid, isTrue);
      expect(session['_security_fingerprint'], isNotNull);
    });
    
    test('detects fingerprint mismatch', () async {
      final session = session_middleware.Session(
        sessionKey: 'test-key',
        store: MockSessionStore(),
      );
      session['_security_fingerprint'] = 'old-fingerprint';
      
      final request = MockHttpRequest(
        uri: Uri.parse('http://example.com/test'),
        headers: {
          'user-agent': 'Different Browser',
          'x-forwarded-for': '192.168.1.2',
          'accept-language': 'fr-FR',
          'accept-encoding': 'br',
        },
      );
      
      final isValid = await manager.validateSessionSecurity(request, session);
      expect(isValid, isFalse);
    });
    
    test('rotates session key', () {
      final session = session_middleware.Session(
        sessionKey: 'old-key',
        store: MockSessionStore(),
      );
      final oldKey = session.sessionKey;
      
      manager.rotateSession(session);
      
      expect(session.sessionKey, isNot(equals(oldKey)));
      expect(session['_last_rotation'], isNotNull);
    });
  });
}

class MockHttpRequest implements HttpRequest {
  @override
  final Uri uri;
  
  @override
  final String method;
  
  @override
  final Map<String, String> headers;
  
  @override
  final Map<String, dynamic> middlewareState = {};
  
  MockHttpRequest({
    required this.uri,
    this.method = 'GET',
    required this.headers,
  });
  
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockSessionStore implements session_middleware.SessionStore {
  final Map<String, Map<String, dynamic>> _sessions = {};
  
  @override
  Future<Map<String, dynamic>?> load(String sessionKey) async {
    return _sessions[sessionKey];
  }
  
  @override
  Future<void> save(String sessionKey, Map<String, dynamic> data, Duration expiry) async {
    _sessions[sessionKey] = Map.from(data);
  }
  
  @override
  Future<void> delete(String sessionKey) async {
    _sessions.remove(sessionKey);
  }
  
  @override
  Future<bool> exists(String sessionKey) async {
    return _sessions.containsKey(sessionKey);
  }
  
  @override
  Future<String> createSessionKey() async {
    return 'new-key-${DateTime.now().millisecondsSinceEpoch}';
  }
}