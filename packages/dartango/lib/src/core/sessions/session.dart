import 'dart:async';
import 'dart:convert';

import 'backends.dart';
import 'exceptions.dart';
import '../utils/crypto.dart';
import '../database/connection.dart';
import '../cache/cache.dart';

class Session {
  final SessionBackend _backend;
  final SessionConfiguration _config;
  bool _loaded = false;
  
  Session(this._backend, this._config);
  
  Future<void> _ensureLoaded() async {
    if (!_loaded) {
      await _backend.load();
      _loaded = true;
    }
  }
  
  Future<T?> get<T>(String key) async {
    await _ensureLoaded();
    return _backend.getValue<T>(key);
  }
  
  Future<void> set(String key, dynamic value) async {
    await _ensureLoaded();
    _backend.setValue(key, value);
  }
  
  Future<void> remove(String key) async {
    await _ensureLoaded();
    _backend.removeValue(key);
  }
  
  Future<bool> containsKey(String key) async {
    await _ensureLoaded();
    return _backend.containsKey(key);
  }
  
  Future<List<String>> get keys async {
    await _ensureLoaded();
    return _backend.keys;
  }
  
  Future<void> clear() async {
    await _ensureLoaded();
    _backend.clear();
  }
  
  Future<void> flush() async {
    await _backend.flush();
    _loaded = false;
  }
  
  Future<void> delete() async {
    await _backend.delete();
    _loaded = false;
  }
  
  Future<void> save() async {
    if (_loaded) {
      await _backend.save();
    }
  }
  
  Future<bool> exists() async {
    return await _backend.exists();
  }
  
  Future<Map<String, dynamic>> toMap() async {
    await _ensureLoaded();
    return _backend.toMap();
  }
  
  Future<void> updateFromMap(Map<String, dynamic> data) async {
    await _ensureLoaded();
    _backend.updateFromMap(data);
  }
  
  String get sessionKey => _backend.sessionKey;
  bool get accessed => _backend.accessed;
  bool get modified => _backend.modified;
  SessionConfiguration get config => _config;
  
  Future<void> setTestCookie() async {
    await set('_test_cookie', 'test_cookie_value');
  }
  
  Future<bool> testCookieWorked() async {
    final value = await get<String>('_test_cookie');
    if (value == 'test_cookie_value') {
      await remove('_test_cookie');
      return true;
    }
    return false;
  }
  
  Future<void> deleteTestCookie() async {
    await remove('_test_cookie');
  }
  
  Future<void> cycleKey() async {
    final oldData = await toMap();
    await delete();
    final newKey = await _backend.createSessionKey();
    await updateFromMap(oldData);
    await save();
  }
  
  Future<String> getOrCreateCsrfToken() async {
    const key = '_csrf_token';
    String? token = await get<String>(key);
    
    if (token == null) {
      token = CryptoUtils.generateSecureToken(32);
      await set(key, token);
    }
    
    return token;
  }
  
  Future<bool> validateCsrfToken(String token) async {
    final sessionToken = await get<String>('_csrf_token');
    return sessionToken != null && sessionToken == token;
  }
  
  Future<void> setExpiry(DateTime expiry) async {
    await set('_session_expiry', expiry.toIso8601String());
  }
  
  Future<DateTime?> getExpiry() async {
    final expiryStr = await get<String>('_session_expiry');
    if (expiryStr != null) {
      return DateTime.parse(expiryStr);
    }
    return null;
  }
  
  Future<bool> isExpired() async {
    final expiry = await getExpiry();
    if (expiry != null) {
      return DateTime.now().isAfter(expiry);
    }
    return false;
  }
  
  Future<void> touch() async {
    await _ensureLoaded();
    _backend.markModified();
  }

  dynamic operator [](String key) {
    if (!_loaded) {
      throw SessionException('Session not loaded. Call get() or ensure session is loaded first.');
    }
    return _backend.getValue(key);
  }

  void operator []=(String key, dynamic value) {
    if (!_loaded) {
      throw SessionException('Session not loaded. Call set() or ensure session is loaded first.');
    }
    _backend.setValue(key, value);
  }

  Future<void> regenerateKey() async {
    await cycleKey();
  }
}

class SessionManager {
  final SessionConfiguration _config;
  
  SessionManager(this._config);
  
  Future<Session> createSession(String? sessionKey) async {
    final key = sessionKey ?? _generateSessionKey();
    final backend = await _createBackend(key);
    return Session(backend, _config);
  }
  
  Future<SessionBackend> _createBackend(String sessionKey) async {
    switch (_config.engine) {
      case 'database':
        final connection = await DatabaseRouter.getConnection();
        return DatabaseSessionBackend(
          sessionKey: sessionKey,
          connection: connection,
          tableName: _config.engineOptions['table_name'] ?? 'dartango_sessions',
          cookieAge: _config.cookieAge,
          cookieDomain: _config.cookieDomain,
          cookiePath: _config.cookiePath,
          cookieSecure: _config.cookieSecure,
          cookieHttpOnly: _config.cookieHttpOnly,
          cookieSameSite: _config.cookieSameSite,
        );
      
      case 'cache':
        final cache = InMemoryCache();
        return CacheSessionBackend(
          sessionKey: sessionKey,
          cache: cache,
          keyPrefix: _config.engineOptions['key_prefix'] ?? 'session',
          cookieAge: _config.cookieAge,
          cookieDomain: _config.cookieDomain,
          cookiePath: _config.cookiePath,
          cookieSecure: _config.cookieSecure,
          cookieHttpOnly: _config.cookieHttpOnly,
          cookieSameSite: _config.cookieSameSite,
        );
      
      case 'file':
        return FileSessionBackend(
          sessionKey: sessionKey,
          storageDirectory: _config.engineOptions['storage_directory'] ?? '/tmp/dartango_sessions',
          filePrefix: _config.engineOptions['file_prefix'] ?? 'session',
          cookieAge: _config.cookieAge,
          cookieDomain: _config.cookieDomain,
          cookiePath: _config.cookiePath,
          cookieSecure: _config.cookieSecure,
          cookieHttpOnly: _config.cookieHttpOnly,
          cookieSameSite: _config.cookieSameSite,
        );
      
      case 'signed_cookies':
        return SignedCookieSessionBackend(
          sessionKey: sessionKey,
          secretKey: _config.engineOptions['secret_key'] ?? _getSecretKey(),
          saltValue: _config.engineOptions['salt'],
          cookieAge: _config.cookieAge,
          cookieDomain: _config.cookieDomain,
          cookiePath: _config.cookiePath,
          cookieSecure: _config.cookieSecure,
          cookieHttpOnly: _config.cookieHttpOnly,
          cookieSameSite: _config.cookieSameSite,
        );
      
      default:
        throw SessionBackendError('Unknown session backend: ${_config.engine}');
    }
  }
  
  String _generateSessionKey() {
    return CryptoUtils.generateSecureToken(32);
  }
  
  String _getSecretKey() {
    return SecureKeyGenerator.generateDjangoSecretKey();
  }
}

class SessionData {
  final Map<String, dynamic> _data = {};
  final Set<String> _accessed = {};
  bool _modified = false;
  
  T? get<T>(String key) {
    _accessed.add(key);
    return _data[key] as T?;
  }
  
  void set(String key, dynamic value) {
    _accessed.add(key);
    
    if (_data[key] != value) {
      _data[key] = value;
      _modified = true;
    }
  }
  
  void remove(String key) {
    _accessed.add(key);
    
    if (_data.containsKey(key)) {
      _data.remove(key);
      _modified = true;
    }
  }
  
  bool containsKey(String key) {
    _accessed.add(key);
    return _data.containsKey(key);
  }
  
  List<String> get keys {
    _accessed.addAll(_data.keys);
    return _data.keys.toList();
  }
  
  void clear() {
    _accessed.addAll(_data.keys);
    if (_data.isNotEmpty) {
      _data.clear();
      _modified = true;
    }
  }
  
  Map<String, dynamic> toMap() {
    _accessed.addAll(_data.keys);
    return Map<String, dynamic>.from(_data);
  }
  
  void updateFromMap(Map<String, dynamic> data) {
    _accessed.addAll(data.keys);
    _data.clear();
    _data.addAll(data);
    _modified = true;
  }
  
  bool get modified => _modified;
  Set<String> get accessedKeys => Set.unmodifiable(_accessed);
  
  void markClean() {
    _modified = false;
  }
  
  void markModified() {
    _modified = true;
  }
  
  String serialize() {
    return jsonEncode(_data);
  }
  
  void deserialize(String data) {
    try {
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      _data.clear();
      _data.addAll(decoded);
      _modified = false;
    } catch (e) {
      throw SessionSerializationError('Failed to deserialize session data: $e');
    }
  }
}

class SessionUtils {
  static String generateSessionKey([int length = 32]) {
    return CryptoUtils.generateSecureToken(length);
  }
  
  static bool isValidSessionKey(String key) {
    return key.isNotEmpty && key.length >= 16 && RegExp(r'^[a-zA-Z0-9]+$').hasMatch(key);
  }
  
  static DateTime calculateExpiryDate(Duration cookieAge) {
    return DateTime.now().add(cookieAge);
  }
  
  static Map<String, String> createSessionCookie(
    String sessionKey,
    SessionConfiguration config,
  ) {
    final attributes = <String>[];
    
    if (config.cookieDomain != null) {
      attributes.add('Domain=${config.cookieDomain}');
    }
    
    attributes.add('Path=${config.cookiePath}');
    
    if (config.cookieSecure) {
      attributes.add('Secure');
    }
    
    if (config.cookieHttpOnly) {
      attributes.add('HttpOnly');
    }
    
    if (config.cookieSameSite != null) {
      attributes.add('SameSite=${config.cookieSameSite}');
    }
    
    if (!config.expireAtBrowserClose) {
      final expiry = DateTime.now().add(config.cookieAge);
      attributes.add('Expires=${expiry.toUtc().toIso8601String()}');
      attributes.add('Max-Age=${config.cookieAge.inSeconds}');
    }
    
    final cookieValue = '${config.cookieName}=$sessionKey; ${attributes.join('; ')}';
    
    return {'Set-Cookie': cookieValue};
  }
  
  static Map<String, String> deleteSessionCookie(SessionConfiguration config) {
    final attributes = <String>[];
    
    if (config.cookieDomain != null) {
      attributes.add('Domain=${config.cookieDomain}');
    }
    
    attributes.add('Path=${config.cookiePath}');
    attributes.add('Expires=Thu, 01 Jan 1970 00:00:00 GMT');
    attributes.add('Max-Age=0');
    
    final cookieValue = '${config.cookieName}=; ${attributes.join('; ')}';
    
    return {'Set-Cookie': cookieValue};
  }
  
  static String? extractSessionKeyFromCookie(String? cookieHeader, String cookieName) {
    if (cookieHeader == null) return null;
    
    final cookies = cookieHeader.split(';');
    for (final cookie in cookies) {
      final parts = cookie.trim().split('=');
      if (parts.length == 2 && parts[0] == cookieName) {
        return parts[1];
      }
    }
    
    return null;
  }
}