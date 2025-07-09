import '../middleware/session.dart';
import '../http/request.dart';
import 'file_store.dart';

export '../middleware/session.dart';
export 'file_store.dart';

class SessionConfiguration {
  final String engine;
  final String sessionCookieName;
  final Duration sessionCookieAge;
  final String? sessionCookieDomain;
  final bool sessionCookieSecure;
  final bool sessionCookieHttpOnly;
  final SessionSameSite sessionCookieSameSite;
  final String sessionCookiePath;
  final bool sessionSaveEveryRequest;
  final bool sessionExpireAtBrowserClose;
  final String sessionFileStorePath;
  final String sessionDatabaseTable;
  final String sessionRedisPrefix;
  final bool sessionUseCachedStore;
  final Duration sessionCacheTimeout;

  const SessionConfiguration({
    this.engine = 'memory',
    this.sessionCookieName = 'sessionid',
    this.sessionCookieAge = const Duration(seconds: 1209600), // 2 weeks
    this.sessionCookieDomain,
    this.sessionCookieSecure = false,
    this.sessionCookieHttpOnly = true,
    this.sessionCookieSameSite = SessionSameSite.lax,
    this.sessionCookiePath = '/',
    this.sessionSaveEveryRequest = false,
    this.sessionExpireAtBrowserClose = false,
    this.sessionFileStorePath = '/tmp/django_sessions',
    this.sessionDatabaseTable = 'sessions',
    this.sessionRedisPrefix = 'session:',
    this.sessionUseCachedStore = false,
    this.sessionCacheTimeout = const Duration(minutes: 5),
  });

  SessionStore createSessionStore() {
    SessionStore store;

    switch (engine) {
      case 'file':
        store = FileSessionStore(sessionPath: sessionFileStorePath);
        break;
      case 'database':
        store = DatabaseSessionStore(tableName: sessionDatabaseTable);
        break;
      case 'redis':
        store = RedisSessionStore(keyPrefix: sessionRedisPrefix);
        break;
      case 'signed_cookies':
        store = SignedCookieSessionStore(
          secretKey: 'your-secret-key-here',
        );
        break;
      case 'memory':
      default:
        store = InMemorySessionStore();
        break;
    }

    if (sessionUseCachedStore && engine != 'memory') {
      store = CachedSessionStore(
        backingStore: store,
        cacheTimeout: sessionCacheTimeout,
      );
    }

    return store;
  }

  SessionMiddleware createSessionMiddleware() {
    return SessionMiddleware(
      sessionStore: createSessionStore(),
      cookieName: sessionCookieName,
      cookieDomain: sessionCookieDomain,
      cookieSecure: sessionCookieSecure,
      cookieHttpOnly: sessionCookieHttpOnly,
      cookieSameSite: sessionCookieSameSite,
      cookieAge: sessionCookieAge,
      cookiePath: sessionCookiePath,
      saveEveryRequest: sessionSaveEveryRequest,
    );
  }
}

extension HttpRequestSessionExtension on HttpRequest {
  Session get session => middlewareState['session'] as Session;

  dynamic get messages => middlewareState['messages'];

  bool get hasSession => middlewareState.containsKey('session');

  bool get hasMessages => middlewareState.containsKey('messages');
}

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();

  factory SessionManager() => _instance;

  SessionManager._internal();

  SessionStore? _store;
  SessionMiddleware? _middleware;

  void configure(SessionConfiguration config) {
    _store = config.createSessionStore();
    _middleware = config.createSessionMiddleware();
  }

  SessionStore get store {
    if (_store == null) {
      throw StateError(
          'SessionManager not configured. Call configure() first.');
    }
    return _store!;
  }

  SessionMiddleware get middleware {
    if (_middleware == null) {
      throw StateError(
          'SessionManager not configured. Call configure() first.');
    }
    return _middleware!;
  }

  Future<void> cleanupExpiredSessions() async {
    final store = _store;
    if (store is FileSessionStore) {
      await store.cleanup();
    } else if (store is DatabaseSessionStore) {
      await store.cleanup();
    } else if (store is CachedSessionStore) {
      store.clearCache();
    }
  }

  Future<Session> createSession() async {
    final sessionKey = await store.createSessionKey();
    return Session(sessionKey: sessionKey, store: store);
  }

  Future<Session?> loadSession(String sessionKey) async {
    final data = await store.load(sessionKey);
    if (data != null) {
      return Session(sessionKey: sessionKey, store: store, data: data);
    }
    return null;
  }

  Future<void> deleteSession(String sessionKey) async {
    await store.delete(sessionKey);
  }

  Future<bool> sessionExists(String sessionKey) async {
    return await store.exists(sessionKey);
  }
}

class SessionTestUtils {
  static Future<Session> createTestSession({
    Map<String, dynamic>? data,
    SessionStore? store,
  }) async {
    final sessionStore = store ?? InMemorySessionStore();
    final sessionKey = await sessionStore.createSessionKey();

    final session = Session(
      sessionKey: sessionKey,
      store: sessionStore,
      data: data,
    );

    if (data != null) {
      await session.save();
    }

    return session;
  }

  static SessionMiddleware createTestSessionMiddleware({
    SessionStore? store,
    String? cookieName,
  }) {
    return SessionMiddleware(
      sessionStore: store ?? InMemorySessionStore(),
      cookieName: cookieName ?? 'test_sessionid',
      cookieSecure: false,
      cookieHttpOnly: false,
    );
  }
}
