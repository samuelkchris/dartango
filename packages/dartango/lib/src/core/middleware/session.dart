import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:crypto/crypto.dart';

import '../http/request.dart';
import '../http/response.dart';
import 'base.dart';

abstract class SessionStore {
  FutureOr<Map<String, dynamic>?> load(String sessionKey);
  FutureOr<void> save(String sessionKey, Map<String, dynamic> data, Duration expiry);
  FutureOr<void> delete(String sessionKey);
  FutureOr<bool> exists(String sessionKey);
  FutureOr<String> createSessionKey();
}

class Session {
  String sessionKey;
  final Map<String, dynamic> _data;
  final SessionStore _store;
  bool _modified = false;
  bool _accessed = false;

  Session({
    required this.sessionKey,
    required SessionStore store,
    Map<String, dynamic>? data,
  })  : _store = store,
        _data = data ?? {};

  dynamic operator [](String key) {
    _accessed = true;
    return _data[key];
  }

  void operator []=(String key, dynamic value) {
    _accessed = true;
    _modified = true;
    _data[key] = value;
  }

  bool containsKey(String key) {
    _accessed = true;
    return _data.containsKey(key);
  }

  dynamic remove(String key) {
    _accessed = true;
    _modified = true;
    return _data.remove(key);
  }

  void clear() {
    _accessed = true;
    _modified = true;
    _data.clear();
  }

  Map<String, dynamic> get data => Map.unmodifiable(_data);

  bool get isEmpty => _data.isEmpty;
  bool get isNotEmpty => _data.isNotEmpty;
  int get length => _data.length;
  bool get modified => _modified;
  bool get accessed => _accessed;

  void setExpiry(String key, dynamic value, Duration duration) {
    final expiryTime = DateTime.now().add(duration).millisecondsSinceEpoch;
    this['${key}__expiry'] = expiryTime;
    this[key] = value;
  }

  dynamic getWithExpiry(String key) {
    final expiryKey = '${key}__expiry';
    if (containsKey(expiryKey)) {
      final expiryTime = this[expiryKey] as int;
      if (DateTime.now().millisecondsSinceEpoch > expiryTime) {
        remove(key);
        remove(expiryKey);
        return null;
      }
    }
    return this[key];
  }

  void flash(String key, dynamic value) {
    this['_flash_$key'] = value;
  }

  dynamic getFlash(String key) {
    final flashKey = '_flash_$key';
    final value = this[flashKey];
    if (value != null) {
      remove(flashKey);
    }
    return value;
  }

  Future<void> save() async {
    if (_modified) {
      await _store.save(sessionKey, _data, _getSessionExpiry());
      _modified = false;
    }
  }

  Future<void> delete() async {
    await _store.delete(sessionKey);
    clear();
  }

  Future<void> regenerateKey() async {
    final oldKey = sessionKey;
    final newKey = await _store.createSessionKey();
    
    await _store.save(newKey, _data, _getSessionExpiry());
    await _store.delete(oldKey);
    
    sessionKey = newKey;
    _modified = true;
  }

  Duration _getSessionExpiry() {
    return const Duration(seconds: 1209600); // 2 weeks
  }
}

class SessionMiddleware extends BaseMiddleware {
  final SessionStore sessionStore;
  final String cookieName;
  final String? cookieDomain;
  final bool cookieSecure;
  final bool cookieHttpOnly;
  final SameSite? cookieSameSite;
  final Duration cookieAge;
  final String cookiePath;
  final bool saveEveryRequest;

  SessionMiddleware({
    required this.sessionStore,
    String? cookieName,
    this.cookieDomain,
    bool? cookieSecure,
    bool? cookieHttpOnly,
    SameSite? cookieSameSite,
    Duration? cookieAge,
    String? cookiePath,
    bool? saveEveryRequest,
  })  : cookieName = cookieName ?? 'sessionid',
        cookieSecure = cookieSecure ?? false,
        cookieHttpOnly = cookieHttpOnly ?? true,
        cookieSameSite = cookieSameSite ?? SameSite.lax,
        cookieAge = cookieAge ?? const Duration(seconds: 1209600),
        cookiePath = cookiePath ?? '/',
        saveEveryRequest = saveEveryRequest ?? false;


  @override
  FutureOr<HttpResponse?> processRequest(HttpRequest request) async {
    final sessionKey = request.cookies[cookieName]?.value;
    
    if (sessionKey != null) {
      final sessionData = await sessionStore.load(sessionKey);
      if (sessionData != null) {
        request.middlewareState['session'] = Session(
          sessionKey: sessionKey,
          store: sessionStore,
          data: sessionData,
        );
        return null;
      }
    }
    
    final newSessionKey = await sessionStore.createSessionKey();
    request.middlewareState['session'] = Session(
      sessionKey: newSessionKey,
      store: sessionStore,
    );
    
    return null;
  }

  @override
  FutureOr<HttpResponse> processResponse(
    HttpRequest request,
    HttpResponse response,
  ) async {
    final session = request.middlewareState['session'] as Session?;
    if (session == null) {
      return response;
    }

    final shouldSave = session.modified || (saveEveryRequest && session.accessed);
    
    if (shouldSave) {
      await session.save();
      
      if (session.isEmpty) {
        response = response.deleteCookie(
          cookieName,
          path: cookiePath,
          domain: cookieDomain,
        );
      } else {
        final expires = DateTime.now().add(cookieAge);
        response = response.setCookie(
          cookieName,
          session.sessionKey,
          expires: expires,
          path: cookiePath,
          domain: cookieDomain,
          secure: cookieSecure,
          httpOnly: cookieHttpOnly,
          sameSite: cookieSameSite,
        );
      }
    }

    return response;
  }
}

class InMemorySessionStore extends SessionStore {
  final Map<String, Map<String, dynamic>> _sessions = {};
  final Map<String, DateTime> _expiries = {};
  final Random _random = Random.secure();

  @override
  FutureOr<Map<String, dynamic>?> load(String sessionKey) {
    _cleanupExpired();
    return _sessions[sessionKey];
  }

  @override
  FutureOr<void> save(String sessionKey, Map<String, dynamic> data, Duration expiry) {
    _sessions[sessionKey] = Map.from(data);
    _expiries[sessionKey] = DateTime.now().add(expiry);
  }

  @override
  FutureOr<void> delete(String sessionKey) {
    _sessions.remove(sessionKey);
    _expiries.remove(sessionKey);
  }

  @override
  FutureOr<bool> exists(String sessionKey) {
    _cleanupExpired();
    return _sessions.containsKey(sessionKey);
  }

  @override
  FutureOr<String> createSessionKey() {
    String key;
    do {
      key = _generateKey();
    } while (_sessions.containsKey(key));
    return key;
  }

  String _generateKey() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  void _cleanupExpired() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _expiries.entries) {
      if (entry.value.isBefore(now)) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _sessions.remove(key);
      _expiries.remove(key);
    }
  }
}

class SignedCookieSessionStore extends SessionStore {
  final String secretKey;
  final String salt;

  SignedCookieSessionStore({
    required this.secretKey,
    this.salt = 'django.contrib.sessions.backends.signed_cookies',
  });

  @override
  FutureOr<Map<String, dynamic>?> load(String sessionKey) {
    try {
      final decoded = _unsign(sessionKey);
      if (decoded != null) {
        return json.decode(decoded) as Map<String, dynamic>;
      }
    } catch (e) {
      // Invalid session data
    }
    return null;
  }

  @override
  FutureOr<void> save(String sessionKey, Map<String, dynamic> data, Duration expiry) {
    // In signed cookie sessions, data is stored in the cookie itself
    // This is handled by the session middleware
  }

  @override
  FutureOr<void> delete(String sessionKey) {
    // Nothing to do for signed cookie sessions
  }

  @override
  Future<bool> exists(String sessionKey) async {
    final data = await load(sessionKey);
    return data != null;
  }

  @override
  FutureOr<String> createSessionKey() {
    // For signed cookies, we return an empty session that will be signed later
    return _sign(json.encode({}));
  }

  String _sign(String value) {
    final key = _deriveKey();
    final signature = _hmac(key, value);
    return '$value:$signature';
  }

  String? _unsign(String signedValue) {
    final parts = signedValue.split(':');
    if (parts.length != 2) {
      return null;
    }
    
    final value = parts[0];
    final signature = parts[1];
    
    final key = _deriveKey();
    final expectedSignature = _hmac(key, value);
    
    if (signature == expectedSignature) {
      return value;
    }
    
    return null;
  }

  String _deriveKey() {
    final keyBytes = utf8.encode(secretKey);
    final saltBytes = utf8.encode(salt);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(saltBytes);
    return base64.encode(digest.bytes);
  }

  String _hmac(String key, String value) {
    final keyBytes = utf8.encode(key);
    final valueBytes = utf8.encode(value);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(valueBytes);
    return base64.encode(digest.bytes);
  }
}

class MessageMiddleware extends BaseMiddleware {
  static const String messageKey = '_messages';

  @override
  FutureOr<HttpResponse?> processRequest(HttpRequest request) {
    final session = request.middlewareState['session'] as Session?;
    if (session != null) {
      final messages = session.getFlash(messageKey) as List<Map<String, dynamic>>? ?? [];
      request.middlewareState['messages'] = Messages(messages);
    } else {
      request.middlewareState['messages'] = Messages([]);
    }
    return null;
  }

  @override
  FutureOr<HttpResponse> processResponse(
    HttpRequest request,
    HttpResponse response,
  ) {
    final messages = request.middlewareState['messages'] as Messages?;
    final session = request.middlewareState['session'] as Session?;
    
    if (messages != null && session != null && messages.hasUnconsumed) {
      final unconsumed = messages.unconsumed;
      if (unconsumed.isNotEmpty) {
        session.flash(messageKey, unconsumed);
      }
    }
    
    return response;
  }
}

class Messages {
  final List<Map<String, dynamic>> _messages;
  final Set<int> _consumed = {};

  Messages(this._messages);

  void add(String message, {String level = 'info', Map<String, dynamic>? extra}) {
    _messages.add({
      'message': message,
      'level': level,
      'extra': extra ?? {},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void debug(String message, {Map<String, dynamic>? extra}) {
    add(message, level: 'debug', extra: extra);
  }

  void info(String message, {Map<String, dynamic>? extra}) {
    add(message, level: 'info', extra: extra);
  }

  void success(String message, {Map<String, dynamic>? extra}) {
    add(message, level: 'success', extra: extra);
  }

  void warning(String message, {Map<String, dynamic>? extra}) {
    add(message, level: 'warning', extra: extra);
  }

  void error(String message, {Map<String, dynamic>? extra}) {
    add(message, level: 'error', extra: extra);
  }

  List<Map<String, dynamic>> get all {
    for (int i = 0; i < _messages.length; i++) {
      _consumed.add(i);
    }
    return List.unmodifiable(_messages);
  }

  List<Map<String, dynamic>> get unconsumed {
    final result = <Map<String, dynamic>>[];
    for (int i = 0; i < _messages.length; i++) {
      if (!_consumed.contains(i)) {
        result.add(_messages[i]);
      }
    }
    return result;
  }

  bool get hasUnconsumed => unconsumed.isNotEmpty;

  void markConsumed(int index) {
    _consumed.add(index);
  }

  void markAllConsumed() {
    for (int i = 0; i < _messages.length; i++) {
      _consumed.add(i);
    }
  }
}