import 'package:test/test.dart';

import '../../../lib/src/core/sessions/session.dart';
import '../../../lib/src/core/sessions/backends.dart';
import '../../../lib/src/core/sessions/exceptions.dart';

void main() {
  group('Session', () {
    late TestSessionBackend backend;
    late SessionConfiguration config;
    late Session session;
    
    setUp(() {
      backend = TestSessionBackend(sessionKey: 'test-session-key');
      config = const SessionConfiguration();
      session = Session(backend, config);
    });
    
    test('get and set values', () async {
      await session.set('key1', 'value1');
      final value = await session.get<String>('key1');
      
      expect(value, equals('value1'));
      expect(session.modified, isTrue);
      expect(session.accessed, isTrue);
    });
    
    test('remove values', () async {
      await session.set('key1', 'value1');
      await session.remove('key1');
      
      final value = await session.get<String>('key1');
      expect(value, isNull);
    });
    
    test('containsKey works correctly', () async {
      expect(await session.containsKey('key1'), isFalse);
      
      await session.set('key1', 'value1');
      expect(await session.containsKey('key1'), isTrue);
    });
    
    test('keys returns all session keys', () async {
      await session.set('key1', 'value1');
      await session.set('key2', 'value2');
      
      final keys = await session.keys;
      expect(keys, containsAll(['key1', 'key2']));
    });
    
    test('clear removes all data', () async {
      await session.set('key1', 'value1');
      await session.set('key2', 'value2');
      
      await session.clear();
      
      expect(await session.containsKey('key1'), isFalse);
      expect(await session.containsKey('key2'), isFalse);
    });
    
    test('toMap returns session data', () async {
      await session.set('key1', 'value1');
      await session.set('key2', 42);
      
      final map = await session.toMap();
      expect(map, equals({'key1': 'value1', 'key2': 42}));
    });
    
    test('updateFromMap sets session data', () async {
      await session.updateFromMap({'key1': 'value1', 'key2': 42});
      
      expect(await session.get<String>('key1'), equals('value1'));
      expect(await session.get<int>('key2'), equals(42));
    });
    
    test('flush clears and recreates session', () async {
      await session.set('key1', 'value1');
      final oldKey = session.sessionKey;
      
      await session.flush();
      
      expect(await session.containsKey('key1'), isFalse);
      expect(session.sessionKey, isNot(equals(oldKey)));
    });
    
    test('CSRF token generation and validation', () async {
      final token1 = await session.getOrCreateCsrfToken();
      final token2 = await session.getOrCreateCsrfToken();
      
      expect(token1, equals(token2));
      expect(token1, isA<String>());
      expect(token1.length, greaterThan(16));
      
      expect(await session.validateCsrfToken(token1), isTrue);
      expect(await session.validateCsrfToken('invalid-token'), isFalse);
    });
    
    test('session expiry', () async {
      await session.setExpiry(DateTime.now().add(const Duration(hours: 1)));
      expect(await session.isExpired(), isFalse);
      
      await session.setExpiry(DateTime.now().subtract(const Duration(hours: 1)));
      expect(await session.isExpired(), isTrue);
    });
    
    test('touch marks session as modified', () async {
      expect(session.modified, isFalse);
      
      await session.touch();
      expect(session.modified, isTrue);
    });
    
    test('cycleKey regenerates session key', () async {
      await session.set('key1', 'value1');
      final oldKey = session.sessionKey;
      
      await session.cycleKey();
      
      expect(session.sessionKey, isNot(equals(oldKey)));
      expect(await session.get<String>('key1'), equals('value1'));
    });
    
    test('test cookie functionality', () async {
      await session.setTestCookie();
      expect(await session.testCookieWorked(), isTrue);
      
      await session.deleteTestCookie();
      expect(await session.testCookieWorked(), isFalse);
    });
  });
  
  group('SessionManager', () {
    late SessionConfiguration config;
    late SessionManager manager;
    
    setUp(() {
      config = const SessionConfiguration(engine: 'file');
      manager = SessionManager(config);
    });
    
    test('creates session with provided key', () async {
      final session = await manager.createSession('test-key');
      
      expect(session.sessionKey, equals('test-key'));
      expect(session.config.engine, equals('file'));
    });
    
    test('creates session with generated key', () async {
      final session = await manager.createSession(null);
      
      expect(session.sessionKey, isA<String>());
      expect(session.sessionKey.isNotEmpty, isTrue);
    });
    
    test('supports different backends', () async {
      final cacheManager = SessionManager(const SessionConfiguration(engine: 'cache'));
      final cacheSession = await cacheManager.createSession('cache-key');
      expect(cacheSession.sessionKey, equals('cache-key'));
      
      final fileManager = SessionManager(const SessionConfiguration(engine: 'file'));
      final fileSession = await fileManager.createSession('file-key');
      expect(fileSession.sessionKey, equals('file-key'));
      
      final signedManager = SessionManager(const SessionConfiguration(
        engine: 'signed_cookies',
        engineOptions: {'secret_key': 'test-secret-key-12345'},
      ));
      final signedSession = await signedManager.createSession('signed-key');
      expect(signedSession.sessionKey, equals('signed-key'));
    });
    
    test('throws error for unknown backend', () async {
      final invalidManager = SessionManager(const SessionConfiguration(engine: 'invalid'));
      
      expect(
        () => invalidManager.createSession('test-key'),
        throwsA(isA<SessionBackendError>()),
      );
    });
  });
  
  group('SessionData', () {
    late SessionData data;
    
    setUp(() {
      data = SessionData();
    });
    
    test('get and set values', () {
      expect(data.get<String>('key1'), isNull);
      
      data.set('key1', 'value1');
      expect(data.get<String>('key1'), equals('value1'));
      expect(data.modified, isTrue);
    });
    
    test('remove values', () {
      data.set('key1', 'value1');
      data.remove('key1');
      
      expect(data.get<String>('key1'), isNull);
      expect(data.modified, isTrue);
    });
    
    test('containsKey works correctly', () {
      expect(data.containsKey('key1'), isFalse);
      
      data.set('key1', 'value1');
      expect(data.containsKey('key1'), isTrue);
    });
    
    test('keys returns all data keys', () {
      data.set('key1', 'value1');
      data.set('key2', 'value2');
      
      final keys = data.keys;
      expect(keys, containsAll(['key1', 'key2']));
    });
    
    test('clear removes all data', () {
      data.set('key1', 'value1');
      data.set('key2', 'value2');
      
      data.clear();
      
      expect(data.containsKey('key1'), isFalse);
      expect(data.containsKey('key2'), isFalse);
      expect(data.modified, isTrue);
    });
    
    test('toMap returns data copy', () {
      data.set('key1', 'value1');
      data.set('key2', 42);
      
      final map = data.toMap();
      expect(map, equals({'key1': 'value1', 'key2': 42}));
      
      map['key3'] = 'value3';
      expect(data.containsKey('key3'), isFalse);
    });
    
    test('updateFromMap replaces data', () {
      data.set('key1', 'value1');
      data.updateFromMap({'key2': 'value2', 'key3': 42});
      
      expect(data.containsKey('key1'), isFalse);
      expect(data.get<String>('key2'), equals('value2'));
      expect(data.get<int>('key3'), equals(42));
      expect(data.modified, isTrue);
    });
    
    test('markClean resets modified flag', () {
      data.set('key1', 'value1');
      expect(data.modified, isTrue);
      
      data.markClean();
      expect(data.modified, isFalse);
    });
    
    test('markModified sets modified flag', () {
      expect(data.modified, isFalse);
      
      data.markModified();
      expect(data.modified, isTrue);
    });
    
    test('serialize and deserialize', () {
      data.set('string', 'value');
      data.set('number', 42);
      data.set('boolean', true);
      data.set('list', [1, 2, 3]);
      data.set('map', {'nested': 'value'});
      
      final serialized = data.serialize();
      expect(serialized, isA<String>());
      
      final newData = SessionData();
      newData.deserialize(serialized);
      
      expect(newData.get<String>('string'), equals('value'));
      expect(newData.get<int>('number'), equals(42));
      expect(newData.get<bool>('boolean'), equals(true));
      expect(newData.get<List>('list'), equals([1, 2, 3]));
      expect(newData.get<Map>('map'), equals({'nested': 'value'}));
    });
    
    test('deserialize handles invalid data', () {
      final data = SessionData();
      
      expect(
        () => data.deserialize('invalid-json'),
        throwsA(isA<SessionSerializationError>()),
      );
    });
    
    test('tracks accessed keys', () {
      data.set('key1', 'value1');
      data.get<String>('key1');
      data.containsKey('key2');
      
      final accessedKeys = data.accessedKeys;
      expect(accessedKeys, contains('key1'));
      expect(accessedKeys, contains('key2'));
    });
  });
  
  group('SessionUtils', () {
    test('generateSessionKey creates valid keys', () {
      final key1 = SessionUtils.generateSessionKey();
      final key2 = SessionUtils.generateSessionKey(16);
      
      expect(key1, isA<String>());
      expect(key1.length, equals(32));
      expect(key2.length, equals(16));
      expect(key1, isNot(equals(key2)));
    });
    
    test('isValidSessionKey validates keys', () {
      expect(SessionUtils.isValidSessionKey('valid-key-123'), isTrue);
      expect(SessionUtils.isValidSessionKey('VALID123'), isTrue);
      expect(SessionUtils.isValidSessionKey(''), isFalse);
      expect(SessionUtils.isValidSessionKey('short'), isFalse);
      expect(SessionUtils.isValidSessionKey('invalid-chars!@#'), isFalse);
    });
    
    test('calculateExpiryDate adds duration', () {
      final duration = const Duration(hours: 2);
      final expiry = SessionUtils.calculateExpiryDate(duration);
      final expected = DateTime.now().add(duration);
      
      expect(expiry.difference(expected).abs(), lessThan(const Duration(seconds: 1)));
    });
    
    test('createSessionCookie generates cookie headers', () {
      const config = SessionConfiguration(
        cookieName: 'sessionid',
        cookiePath: '/test',
        cookieSecure: true,
        cookieHttpOnly: true,
        cookieSameSite: 'Strict',
        cookieAge: Duration(hours: 1),
      );
      
      final headers = SessionUtils.createSessionCookie('test-key', config);
      final cookieValue = headers['Set-Cookie']!;
      
      expect(cookieValue, contains('sessionid=test-key'));
      expect(cookieValue, contains('Path=/test'));
      expect(cookieValue, contains('Secure'));
      expect(cookieValue, contains('HttpOnly'));
      expect(cookieValue, contains('SameSite=Strict'));
      expect(cookieValue, contains('Max-Age=3600'));
    });
    
    test('deleteSessionCookie generates deletion headers', () {
      const config = SessionConfiguration(
        cookieName: 'sessionid',
        cookiePath: '/test',
      );
      
      final headers = SessionUtils.deleteSessionCookie(config);
      final cookieValue = headers['Set-Cookie']!;
      
      expect(cookieValue, contains('sessionid=;'));
      expect(cookieValue, contains('Path=/test'));
      expect(cookieValue, contains('Expires=Thu, 01 Jan 1970 00:00:00 GMT'));
      expect(cookieValue, contains('Max-Age=0'));
    });
    
    test('extractSessionKeyFromCookie parses cookies', () {
      final cookieHeader = 'sessionid=test-key; other=value';
      final sessionKey = SessionUtils.extractSessionKeyFromCookie(cookieHeader, 'sessionid');
      
      expect(sessionKey, equals('test-key'));
    });
    
    test('extractSessionKeyFromCookie handles missing cookie', () {
      final sessionKey = SessionUtils.extractSessionKeyFromCookie(null, 'sessionid');
      expect(sessionKey, isNull);
      
      final emptyKey = SessionUtils.extractSessionKeyFromCookie('other=value', 'sessionid');
      expect(emptyKey, isNull);
    });
  });
}

class TestSessionBackend extends SessionBackend {
  TestSessionBackend({required String sessionKey})
      : super(sessionKey: sessionKey);
  
  @override
  Future<void> load() async {
  }
  
  @override
  Future<void> save() async {
  }
  
  @override
  Future<void> delete() async {
    clear();
  }
  
  @override
  Future<void> flush() async {
    clear();
    final newKey = await createSessionKey();
    _sessionData.clear();
  }
  
  @override
  Future<bool> exists() async {
    return sessionData.isNotEmpty;
  }
  
  @override
  Future<String> createSessionKey() async {
    return 'new-key-${DateTime.now().millisecondsSinceEpoch}';
  }
}