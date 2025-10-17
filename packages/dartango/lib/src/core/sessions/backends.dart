import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../cache/cache.dart';
import '../database/connection.dart';
import '../database/query.dart';
import '../utils/crypto.dart';
import 'exceptions.dart';

abstract class SessionBackend {
  final String sessionKey;
  final Duration? cookieAge;
  final String? cookieDomain;
  final String? cookiePath;
  final bool cookieSecure;
  final bool cookieHttpOnly;
  final String? cookieSameSite;
  
  bool _accessed = false;
  bool _modified = false;
  Map<String, dynamic> _sessionData = {};
  String? _sessionCacheKey;

  SessionBackend({
    required this.sessionKey,
    this.cookieAge,
    this.cookieDomain,
    this.cookiePath,
    this.cookieSecure = false,
    this.cookieHttpOnly = true,
    this.cookieSameSite,
  });

  Future<void> load();
  Future<void> save();
  Future<void> delete();
  Future<void> flush();
  Future<bool> exists();
  Future<String> createSessionKey();
  
  bool get accessed => _accessed;
  bool get modified => _modified;
  Map<String, dynamic> get sessionData => Map.unmodifiable(_sessionData);
  
  void markAccessed() {
    _accessed = true;
  }
  
  void markModified() {
    _modified = true;
  }
  
  T? getValue<T>(String key) {
    markAccessed();
    return _sessionData[key] as T?;
  }
  
  void setValue(String key, dynamic value) {
    markAccessed();
    markModified();
    _sessionData[key] = value;
  }
  
  void removeValue(String key) {
    markAccessed();
    markModified();
    _sessionData.remove(key);
  }
  
  bool containsKey(String key) {
    markAccessed();
    return _sessionData.containsKey(key);
  }
  
  List<String> get keys {
    markAccessed();
    return _sessionData.keys.toList();
  }
  
  void clear() {
    markAccessed();
    markModified();
    _sessionData.clear();
  }
  
  Map<String, dynamic> toMap() {
    markAccessed();
    return Map<String, dynamic>.from(_sessionData);
  }
  
  void updateFromMap(Map<String, dynamic> data) {
    markAccessed();
    markModified();
    _sessionData.clear();
    _sessionData.addAll(data);
  }
  
  String encodeSession() {
    final jsonData = jsonEncode(_sessionData);
    return base64Encode(utf8.encode(jsonData));
  }
  
  void decodeSession(String encodedData) {
    try {
      final jsonData = utf8.decode(base64Decode(encodedData));
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      _sessionData = data;
    } catch (e) {
      _sessionData = {};
    }
  }
  
  String getSessionCacheKey() {
    return _sessionCacheKey ??= 'session:$sessionKey';
  }
}

class DatabaseSessionBackend extends SessionBackend {
  final DatabaseConnection connection;
  final String tableName;
  
  DatabaseSessionBackend({
    required String sessionKey,
    required this.connection,
    this.tableName = 'dartango_sessions',
    Duration? cookieAge,
    String? cookieDomain,
    String? cookiePath,
    bool cookieSecure = false,
    bool cookieHttpOnly = true,
    String? cookieSameSite,
  }) : super(
    sessionKey: sessionKey,
    cookieAge: cookieAge,
    cookieDomain: cookieDomain,
    cookiePath: cookiePath,
    cookieSecure: cookieSecure,
    cookieHttpOnly: cookieHttpOnly,
    cookieSameSite: cookieSameSite,
  );

  @override
  Future<void> load() async {
    try {
      final builder = QueryBuilder()
          .select(['session_data', 'expire_date'])
          .from(tableName)
          .where('session_key = ?', [sessionKey]);
      
      final results = await connection.query(builder.toSql(), builder.parameters);
      
      if (results.isNotEmpty) {
        final row = results.first;
        final expireDate = DateTime.parse(row['expire_date']);
        
        if (expireDate.isAfter(DateTime.now())) {
          final sessionData = row['session_data'] as String;
          decodeSession(sessionData);
        } else {
          await delete();
        }
      }
    } catch (e) {
      _sessionData = {};
    }
  }

  @override
  Future<void> save() async {
    if (!modified) return;
    
    final expireDate = DateTime.now().add(
      cookieAge ?? const Duration(days: 14)
    );
    
    final sessionData = encodeSession();
    
    final existsBuilder = QueryBuilder()
        .select(['COUNT(*) as count'])
        .from(tableName)
        .where('session_key = ?', [sessionKey]);
    
    final existsResult = await connection.query(existsBuilder.toSql(), existsBuilder.parameters);
    final exists = existsResult.first['count'] > 0;
    
    if (exists) {
      final updateBuilder = UpdateQueryBuilder(tableName)
          .set({
            'session_data': sessionData,
            'expire_date': expireDate.toIso8601String(),
          })
          .where('session_key = ?', [sessionKey]);
      
      await connection.execute(updateBuilder.toSql(), updateBuilder.parameters);
    } else {
      final insertBuilder = InsertQueryBuilder(tableName)
          .values({
            'session_key': sessionKey,
            'session_data': sessionData,
            'expire_date': expireDate.toIso8601String(),
          });
      
      await connection.execute(insertBuilder.toSql(), insertBuilder.parameters);
    }
  }

  @override
  Future<void> delete() async {
    final builder = DeleteQueryBuilder(tableName)
        .where('session_key = ?', [sessionKey]);
    
    await connection.execute(builder.toSql(), builder.parameters);
    _sessionData.clear();
  }

  @override
  Future<void> flush() async {
    await delete();
    await createSessionKey();
  }

  @override
  Future<bool> exists() async {
    final builder = QueryBuilder()
        .select(['COUNT(*) as count'])
        .from(tableName)
        .where('session_key = ? AND expire_date > ?', 
               [sessionKey, DateTime.now().toIso8601String()]);
    
    final results = await connection.query(builder.toSql(), builder.parameters);
    return results.first['count'] > 0;
  }

  @override
  Future<String> createSessionKey() {
    return Future.value(CryptoUtils.generateSecureToken(32));
  }
  
  Future<void> createTable() async {
    final sql = '''
      CREATE TABLE IF NOT EXISTS $tableName (
        session_key VARCHAR(40) PRIMARY KEY,
        session_data TEXT NOT NULL,
        expire_date DATETIME NOT NULL
      )
    ''';
    
    await connection.execute(sql, []);
    
    final indexSql = '''
      CREATE INDEX IF NOT EXISTS ${tableName}_expire_date_idx 
      ON $tableName (expire_date)
    ''';
    
    await connection.execute(indexSql, []);
  }
  
  Future<void> clearExpiredSessions() async {
    final builder = DeleteQueryBuilder(tableName)
        .where('expire_date < ?', [DateTime.now().toIso8601String()]);
    
    await connection.execute(builder.toSql(), builder.parameters);
  }
}

class CacheSessionBackend extends SessionBackend {
  final CacheBackend cache;
  final String keyPrefix;
  
  CacheSessionBackend({
    required String sessionKey,
    required this.cache,
    this.keyPrefix = 'session',
    Duration? cookieAge,
    String? cookieDomain,
    String? cookiePath,
    bool cookieSecure = false,
    bool cookieHttpOnly = true,
    String? cookieSameSite,
  }) : super(
    sessionKey: sessionKey,
    cookieAge: cookieAge,
    cookieDomain: cookieDomain,
    cookiePath: cookiePath,
    cookieSecure: cookieSecure,
    cookieHttpOnly: cookieHttpOnly,
    cookieSameSite: cookieSameSite,
  );

  @override
  Future<void> load() async {
    try {
      final cacheKey = '$keyPrefix:$sessionKey';
      final sessionData = await cache.get(cacheKey);
      
      if (sessionData != null) {
        decodeSession(sessionData);
      }
    } catch (e) {
      _sessionData = {};
    }
  }

  @override
  Future<void> save() async {
    if (!modified) return;
    
    final cacheKey = '$keyPrefix:$sessionKey';
    final sessionData = encodeSession();
    final timeout = cookieAge ?? const Duration(days: 14);
    
    await cache.set(cacheKey, sessionData, timeout);
  }

  @override
  Future<void> delete() async {
    final cacheKey = '$keyPrefix:$sessionKey';
    await cache.delete(cacheKey);
    _sessionData.clear();
  }

  @override
  Future<void> flush() async {
    await delete();
    await createSessionKey();
  }

  @override
  Future<bool> exists() async {
    final cacheKey = '$keyPrefix:$sessionKey';
    return await cache.exists(cacheKey);
  }

  @override
  Future<String> createSessionKey() {
    return Future.value(CryptoUtils.generateSecureToken(32));
  }
}

class FileSessionBackend extends SessionBackend {
  final String storageDirectory;
  final String filePrefix;
  
  FileSessionBackend({
    required String sessionKey,
    required this.storageDirectory,
    this.filePrefix = 'session',
    Duration? cookieAge,
    String? cookieDomain,
    String? cookiePath,
    bool cookieSecure = false,
    bool cookieHttpOnly = true,
    String? cookieSameSite,
  }) : super(
    sessionKey: sessionKey,
    cookieAge: cookieAge,
    cookieDomain: cookieDomain,
    cookiePath: cookiePath,
    cookieSecure: cookieSecure,
    cookieHttpOnly: cookieHttpOnly,
    cookieSameSite: cookieSameSite,
  );

  @override
  Future<void> load() async {
    try {
      final sessionFile = await _getSessionFile();
      
      if (await sessionFile.exists()) {
        final stat = await sessionFile.stat();
        final expireDate = stat.modified.add(
          cookieAge ?? const Duration(days: 14)
        );
        
        if (expireDate.isAfter(DateTime.now())) {
          final sessionData = await sessionFile.readAsString();
          decodeSession(sessionData);
        } else {
          await sessionFile.delete();
        }
      }
    } catch (e) {
      _sessionData = {};
    }
  }

  @override
  Future<void> save() async {
    if (!modified) return;
    
    final sessionFile = await _getSessionFile();
    final sessionData = encodeSession();
    
    await sessionFile.create(recursive: true);
    await sessionFile.writeAsString(sessionData);
  }

  @override
  Future<void> delete() async {
    final sessionFile = await _getSessionFile();
    
    if (await sessionFile.exists()) {
      await sessionFile.delete();
    }
    
    _sessionData.clear();
  }

  @override
  Future<void> flush() async {
    await delete();
    await createSessionKey();
  }

  @override
  Future<bool> exists() async {
    final sessionFile = await _getSessionFile();
    
    if (await sessionFile.exists()) {
      final stat = await sessionFile.stat();
      final expireDate = stat.modified.add(
        cookieAge ?? const Duration(days: 14)
      );
      return expireDate.isAfter(DateTime.now());
    }
    
    return false;
  }

  @override
  Future<String> createSessionKey() {
    return Future.value(CryptoUtils.generateSecureToken(32));
  }
  
  Future<File> _getSessionFile() async {
    final dir = Directory(storageDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    final fileName = '${filePrefix}_$sessionKey.session';
    return File('${dir.path}/$fileName');
  }
  
  Future<void> clearExpiredSessions() async {
    final dir = Directory(storageDirectory);
    
    if (await dir.exists()) {
      final files = await dir.list().toList();
      final now = DateTime.now();
      
      for (final file in files) {
        if (file is File && file.path.endsWith('.session')) {
          final stat = await file.stat();
          final expireDate = stat.modified.add(
            cookieAge ?? const Duration(days: 14)
          );
          
          if (expireDate.isBefore(now)) {
            await file.delete();
          }
        }
      }
    }
  }
}

class SignedCookieSessionBackend extends SessionBackend {
  final String secretKey;
  final String? saltValue;
  
  SignedCookieSessionBackend({
    required String sessionKey,
    required this.secretKey,
    this.saltValue,
    Duration? cookieAge,
    String? cookieDomain,
    String? cookiePath,
    bool cookieSecure = false,
    bool cookieHttpOnly = true,
    String? cookieSameSite,
  }) : super(
    sessionKey: sessionKey,
    cookieAge: cookieAge,
    cookieDomain: cookieDomain,
    cookiePath: cookiePath,
    cookieSecure: cookieSecure,
    cookieHttpOnly: cookieHttpOnly,
    cookieSameSite: cookieSameSite,
  );

  @override
  Future<void> load() async {
    try {
      if (sessionKey.isNotEmpty) {
        final unsignedData = CryptoUtils.unsignValue(sessionKey, secretKey, saltValue);
        if (unsignedData != null) {
          decodeSession(unsignedData);
        }
      }
    } catch (e) {
      _sessionData = {};
    }
  }

  @override
  Future<void> save() async {
    if (!modified) return;
  }

  @override
  Future<void> delete() async {
    _sessionData.clear();
  }

  @override
  Future<void> flush() async {
    await delete();
    await createSessionKey();
  }

  @override
  Future<bool> exists() async {
    return sessionKey.isNotEmpty;
  }

  @override
  Future<String> createSessionKey() {
    final sessionData = encodeSession();
    return Future.value(CryptoUtils.signValue(sessionData, secretKey, saltValue));
  }
}

class SessionStore {
  static final Map<String, SessionBackend> _backends = {};
  
  static void registerBackend(String name, SessionBackend backend) {
    _backends[name] = backend;
  }
  
  static SessionBackend? getBackend(String name) {
    return _backends[name];
  }
  
  static void clearBackends() {
    _backends.clear();
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
    );
  }
}