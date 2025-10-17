import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

import '../../../lib/src/core/sessions/backends.dart';
import '../../../lib/src/core/sessions/exceptions.dart';
import '../../../lib/src/core/cache/cache.dart';
import '../../../lib/src/core/database/connection.dart';
import '../../../lib/src/core/database/query.dart';

void main() {
  group('SessionBackend', () {
    late TestSessionBackend backend;
    
    setUp(() {
      backend = TestSessionBackend(sessionKey: 'test-key');
    });
    
    test('getValue and setValue work correctly', () {
      expect(backend.getValue<String>('key1'), isNull);
      
      backend.setValue('key1', 'value1');
      expect(backend.getValue<String>('key1'), equals('value1'));
      expect(backend.modified, isTrue);
      expect(backend.accessed, isTrue);
    });
    
    test('removeValue works correctly', () {
      backend.setValue('key1', 'value1');
      backend.removeValue('key1');
      
      expect(backend.getValue<String>('key1'), isNull);
      expect(backend.modified, isTrue);
    });
    
    test('containsKey works correctly', () {
      expect(backend.containsKey('key1'), isFalse);
      
      backend.setValue('key1', 'value1');
      expect(backend.containsKey('key1'), isTrue);
    });
    
    test('clear works correctly', () {
      backend.setValue('key1', 'value1');
      backend.setValue('key2', 'value2');
      
      backend.clear();
      
      expect(backend.containsKey('key1'), isFalse);
      expect(backend.containsKey('key2'), isFalse);
      expect(backend.modified, isTrue);
    });
    
    test('session encoding and decoding', () {
      backend.setValue('string', 'test');
      backend.setValue('number', 42);
      backend.setValue('boolean', true);
      backend.setValue('list', [1, 2, 3]);
      backend.setValue('map', {'nested': 'value'});
      
      final encoded = backend.encodeSession();
      expect(encoded, isA<String>());
      
      final newBackend = TestSessionBackend(sessionKey: 'test-key-2');
      newBackend.decodeSession(encoded);
      
      expect(newBackend.getValue<String>('string'), equals('test'));
      expect(newBackend.getValue<int>('number'), equals(42));
      expect(newBackend.getValue<bool>('boolean'), equals(true));
      expect(newBackend.getValue<List>('list'), equals([1, 2, 3]));
      expect(newBackend.getValue<Map>('map'), equals({'nested': 'value'}));
    });
    
    test('toMap and updateFromMap work correctly', () {
      backend.setValue('key1', 'value1');
      backend.setValue('key2', 42);
      
      final map = backend.toMap();
      expect(map, equals({'key1': 'value1', 'key2': 42}));
      
      final newBackend = TestSessionBackend(sessionKey: 'test-key-2');
      newBackend.updateFromMap({'key3': 'value3', 'key4': false});
      
      expect(newBackend.getValue<String>('key3'), equals('value3'));
      expect(newBackend.getValue<bool>('key4'), equals(false));
    });
  });
  
  group('DatabaseSessionBackend', () {
    late MockDatabaseConnection connection;
    late DatabaseSessionBackend backend;
    
    setUp(() {
      connection = MockDatabaseConnection();
      backend = DatabaseSessionBackend(
        sessionKey: 'db-test-key',
        connection: connection,
        tableName: 'test_sessions',
        cookieAge: const Duration(hours: 1),
      );
    });
    
    test('load session from database', () async {
      connection.queryResults = [
        {
          'session_data': base64Encode(utf8.encode(jsonEncode({'key1': 'value1'}))),
          'expire_date': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        }
      ];
      
      await backend.load();
      
      expect(backend.getValue<String>('key1'), equals('value1'));
      expect(connection.lastSql, contains('SELECT'));
      expect(connection.lastSql, contains('test_sessions'));
    });
    
    test('load handles expired sessions', () async {
      connection.queryResults = [
        {
          'session_data': base64Encode(utf8.encode(jsonEncode({'key1': 'value1'}))),
          'expire_date': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        }
      ];
      
      await backend.load();
      
      expect(backend.getValue<String>('key1'), isNull);
      expect(connection.lastSql, contains('DELETE'));
    });
    
    test('save creates new session', () async {
      connection.queryResults = [{'count': 0}];
      
      backend.setValue('key1', 'value1');
      await backend.save();
      
      expect(connection.executeCalls.length, equals(2));
      expect(connection.executeCalls[0], contains('SELECT'));
      expect(connection.executeCalls[1], contains('INSERT'));
    });
    
    test('save updates existing session', () async {
      connection.queryResults = [{'count': 1}];
      
      backend.setValue('key1', 'value1');
      await backend.save();
      
      expect(connection.executeCalls.length, equals(2));
      expect(connection.executeCalls[0], contains('SELECT'));
      expect(connection.executeCalls[1], contains('UPDATE'));
    });
    
    test('delete removes session', () async {
      await backend.delete();
      
      expect(connection.lastSql, contains('DELETE'));
      expect(connection.lastSql, contains('db-test-key'));
    });
    
    test('exists checks session existence', () async {
      connection.queryResults = [{'count': 1}];
      
      final exists = await backend.exists();
      
      expect(exists, isTrue);
      expect(connection.lastSql, contains('COUNT'));
    });
  });
  
  group('CacheSessionBackend', () {
    late MockCacheBackend cache;
    late CacheSessionBackend backend;
    
    setUp(() {
      cache = MockCacheBackend();
      backend = CacheSessionBackend(
        sessionKey: 'cache-test-key',
        cache: cache,
        keyPrefix: 'test-session',
        cookieAge: const Duration(hours: 1),
      );
    });
    
    test('load session from cache', () async {
      final sessionData = {'key1': 'value1', 'key2': 42};
      cache.data['test-session:cache-test-key'] = base64Encode(utf8.encode(jsonEncode(sessionData)));
      
      await backend.load();
      
      expect(backend.getValue<String>('key1'), equals('value1'));
      expect(backend.getValue<int>('key2'), equals(42));
    });
    
    test('save session to cache', () async {
      backend.setValue('key1', 'value1');
      await backend.save();
      
      final cacheKey = 'test-session:cache-test-key';
      expect(cache.data.containsKey(cacheKey), isTrue);
      
      final stored = jsonDecode(utf8.decode(base64Decode(cache.data[cacheKey]!)));
      expect(stored['key1'], equals('value1'));
    });
    
    test('delete removes session from cache', () async {
      cache.data['test-session:cache-test-key'] = 'test-data';
      
      await backend.delete();
      
      expect(cache.data.containsKey('test-session:cache-test-key'), isFalse);
    });
    
    test('exists checks cache for session', () async {
      cache.data['test-session:cache-test-key'] = 'test-data';
      
      final exists = await backend.exists();
      
      expect(exists, isTrue);
    });
  });
  
  group('FileSessionBackend', () {
    late Directory tempDir;
    late FileSessionBackend backend;
    
    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('session_test_');
      backend = FileSessionBackend(
        sessionKey: 'file-test-key',
        storageDirectory: tempDir.path,
        filePrefix: 'test_session',
        cookieAge: const Duration(hours: 1),
      );
    });
    
    tearDown(() async {
      await tempDir.delete(recursive: true);
    });
    
    test('save and load session file', () async {
      backend.setValue('key1', 'value1');
      backend.setValue('key2', 42);
      
      await backend.save();
      
      final newBackend = FileSessionBackend(
        sessionKey: 'file-test-key',
        storageDirectory: tempDir.path,
        filePrefix: 'test_session',
        cookieAge: const Duration(hours: 1),
      );
      
      await newBackend.load();
      
      expect(newBackend.getValue<String>('key1'), equals('value1'));
      expect(newBackend.getValue<int>('key2'), equals(42));
    });
    
    test('load handles non-existent file', () async {
      await backend.load();
      
      expect(backend.getValue<String>('key1'), isNull);
    });
    
    test('delete removes session file', () async {
      backend.setValue('key1', 'value1');
      await backend.save();
      
      final sessionFile = File('${tempDir.path}/test_session_file-test-key.session');
      expect(await sessionFile.exists(), isTrue);
      
      await backend.delete();
      
      expect(await sessionFile.exists(), isFalse);
    });
    
    test('exists checks file existence and validity', () async {
      backend.setValue('key1', 'value1');
      await backend.save();
      
      final exists = await backend.exists();
      expect(exists, isTrue);
      
      final expiredBackend = FileSessionBackend(
        sessionKey: 'file-test-key',
        storageDirectory: tempDir.path,
        filePrefix: 'test_session',
        cookieAge: const Duration(milliseconds: 1),
      );
      
      await Future.delayed(const Duration(milliseconds: 2));
      
      final expiredExists = await expiredBackend.exists();
      expect(expiredExists, isFalse);
    });
    
    test('clearExpiredSessions removes old files', () async {
      backend.setValue('key1', 'value1');
      await backend.save();
      
      final sessionFile = File('${tempDir.path}/test_session_file-test-key.session');
      expect(await sessionFile.exists(), isTrue);
      
      final expiredBackend = FileSessionBackend(
        sessionKey: 'file-test-key',
        storageDirectory: tempDir.path,
        filePrefix: 'test_session',
        cookieAge: const Duration(milliseconds: 1),
      );
      
      await Future.delayed(const Duration(milliseconds: 2));
      await expiredBackend.clearExpiredSessions();
      
      expect(await sessionFile.exists(), isFalse);
    });
  });
  
  group('SignedCookieSessionBackend', () {
    late SignedCookieSessionBackend backend;
    
    setUp(() {
      backend = SignedCookieSessionBackend(
        sessionKey: 'signed-test-key',
        secretKey: 'test-secret-key-12345',
        saltValue: 'test-salt',
        cookieAge: const Duration(hours: 1),
      );
    });
    
    test('load session from signed value', () async {
      final sessionData = {'key1': 'value1'};
      final encoded = base64Encode(utf8.encode(jsonEncode(sessionData)));
      
      backend = SignedCookieSessionBackend(
        sessionKey: encoded,
        secretKey: 'test-secret-key-12345',
        saltValue: 'test-salt',
      );
      
      await backend.load();
      
      expect(backend.getValue<String>('key1'), equals('value1'));
    });
    
    test('createSessionKey returns signed value', () async {
      final sessionKey = await backend.createSessionKey();
      
      expect(sessionKey, isA<String>());
      expect(sessionKey, contains('.'));
    });
  });
  
  group('SessionConfiguration', () {
    test('default configuration', () {
      const config = SessionConfiguration();
      
      expect(config.engine, equals('database'));
      expect(config.cookieAge, equals(Duration(days: 14)));
      expect(config.cookieName, equals('sessionid'));
      expect(config.cookieHttpOnly, isTrue);
      expect(config.cookieSecure, isFalse);
    });
    
    test('copyWith creates modified configuration', () {
      const config = SessionConfiguration();
      final modified = config.copyWith(
        engine: 'cache',
        cookieSecure: true,
        cookieName: 'custom-session',
      );
      
      expect(modified.engine, equals('cache'));
      expect(modified.cookieSecure, isTrue);
      expect(modified.cookieName, equals('custom-session'));
      expect(modified.cookieAge, equals(config.cookieAge));
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
  }
  
  @override
  Future<void> flush() async {
    clear();
  }
  
  @override
  Future<bool> exists() async {
    return sessionData.isNotEmpty;
  }
  
  @override
  Future<String> createSessionKey() async {
    return 'test-key-${DateTime.now().millisecondsSinceEpoch}';
  }
}

class MockDatabaseConnection implements DatabaseConnection {
  String lastSql = '';
  List<dynamic> lastParameters = [];
  List<String> executeCalls = [];
  List<Map<String, dynamic>> queryResults = [];
  
  @override
  Future<QueryResult> execute(String sql, [List<dynamic>? parameters]) async {
    lastSql = sql;
    lastParameters = parameters ?? [];
    executeCalls.add(sql);
    
    return QueryResult(
      affectedRows: 1,
      insertId: 1,
      columns: [],
      rows: [],
    );
  }
  
  @override
  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic>? parameters]) async {
    lastSql = sql;
    lastParameters = parameters ?? [];
    return queryResults;
  }
  
  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseConnection) callback) async {
    return await callback(this);
  }
  
  @override
  Future<void> close() async {}
  
  @override
  bool get isOpen => true;
  
  @override
  String get databaseName => 'test';
  
  @override
  DatabaseBackend get backend => DatabaseBackend.sqlite;
  
  @override
  Future<void> ping() async {}
  
  @override
  Future<Map<String, dynamic>> getServerInfo() async => {};
  
  @override
  Future<List<String>> getTableNames() async => [];
  
  @override
  Future<List<Map<String, dynamic>>> getTableSchema(String tableName) async => [];
  
  @override
  Future<List<Map<String, dynamic>>> getIndexes(String tableName) async => [];
  
  @override
  Future<void> beginTransaction() async {}
  
  @override
  Future<void> commitTransaction() async {}
  
  @override
  Future<void> rollbackTransaction() async {}
  
  @override
  Future<void> setSavepoint(String name) async {}
  
  @override
  Future<void> releaseSavepoint(String name) async {}
  
  @override
  Future<void> rollbackToSavepoint(String name) async {}
}

class MockCacheBackend implements CacheBackend {
  Map<String, String> data = {};
  
  @override
  Future<T?> get<T>(String key) async {
    final value = data[makeKey(key)];
    return value != null ? deserialize<T>(value) : null;
  }
  
  @override
  Future<void> set<T>(String key, T value, {Duration? timeout}) async {
    data[makeKey(key)] = serialize(value);
  }
  
  @override
  Future<void> delete(String key) async {
    data.remove(makeKey(key));
  }
  
  @override
  Future<void> clear() async {
    data.clear();
  }
  
  @override
  Future<bool> exists(String key) async {
    return data.containsKey(makeKey(key));
  }
  
  @override
  Future<int> size() async {
    return data.length;
  }
  
  @override
  Future<List<String>> keys() async {
    return data.keys.toList();
  }
  
  @override
  Future<Map<String, T>> getMany<T>(List<String> keys) async {
    final result = <String, T>{};
    for (final key in keys) {
      final value = await get<T>(key);
      if (value != null) {
        result[key] = value;
      }
    }
    return result;
  }
  
  @override
  Future<void> setMany<T>(Map<String, T> values, {Duration? timeout}) async {
    for (final entry in values.entries) {
      await set(entry.key, entry.value, timeout: timeout);
    }
  }
  
  @override
  Future<void> deleteMany(List<String> keys) async {
    for (final key in keys) {
      await delete(key);
    }
  }
  
  @override
  Future<T?> getOrSet<T>(String key, Future<T> Function() factory, {Duration? timeout}) async {
    final existing = await get<T>(key);
    if (existing != null) {
      return existing;
    }
    
    final value = await factory();
    await set(key, value, timeout: timeout);
    return value;
  }
  
  @override
  Future<void> touch(String key, {Duration? timeout}) async {}
  
  @override
  Future<int> increment(String key, {int delta = 1}) async {
    final current = await get<int>(key) ?? 0;
    final newValue = current + delta;
    await set(key, newValue);
    return newValue;
  }
  
  @override
  Future<int> decrement(String key, {int delta = 1}) async {
    return await increment(key, delta: -delta);
  }
  
  @override
  Future<void> expire(String key, Duration timeout) async {}
  
  @override
  Future<Duration?> ttl(String key) async => null;
  
  @override
  String makeKey(String key) => key;
  
  @override
  T? deserialize<T>(String data) {
    try {
      return data as T;
    } catch (e) {
      return null;
    }
  }
  
  @override
  String serialize<T>(T value) {
    return value.toString();
  }
}