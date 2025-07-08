import 'dart:io';
import 'package:logging/logging.dart';
import 'base.dart';

class GlobalSettings {
  static BaseSettings? _instance;
  static final Map<String, dynamic> _cache = {};
  static final Logger _logger = Logger('GlobalSettings');

  static BaseSettings get instance {
    if (_instance == null) {
      throw Exception('Settings not configured. Call GlobalSettings.configure() first.');
    }
    return _instance!;
  }

  static void configure(BaseSettings settings) {
    _instance = settings;
    _cache.clear();
    _logger.info('Settings configured successfully');
  }

  static bool get isConfigured => _instance != null;

  static T getSetting<T>(String key, [T? defaultValue]) {
    if (!isConfigured) {
      throw Exception('Settings not configured. Call GlobalSettings.configure() first.');
    }

    if (_cache.containsKey(key)) {
      return _cache[key] as T;
    }

    final value = _instance!.getSetting<T>(key, defaultValue);
    _cache[key] = value;
    return value;
  }

  static void setSetting<T>(String key, T value) {
    if (!isConfigured) {
      throw Exception('Settings not configured. Call GlobalSettings.configure() first.');
    }

    _instance!.setSetting(key, value);
    _cache[key] = value;
  }

  static bool hasSetting(String key) {
    if (!isConfigured) return false;
    return _instance!.hasSetting(key);
  }

  static void clearCache() {
    _cache.clear();
  }

  static void reload() {
    if (!isConfigured) return;
    _instance!.reload();
    _cache.clear();
  }

  static String get debug => getSetting('DEBUG', 'false').toString().toLowerCase();
  static bool get isDebug => debug == 'true';

  static String get secretKey => getSetting('SECRET_KEY', '');
  static bool get hasSecretKey => secretKey.isNotEmpty;

  static List<String> get allowedHosts => getSetting('ALLOWED_HOSTS', <String>['*']);
  static bool get hasAllowedHosts => allowedHosts.isNotEmpty && !allowedHosts.contains('*');

  static String get timeZone => getSetting('TIME_ZONE', 'UTC');
  static String get languageCode => getSetting('LANGUAGE_CODE', 'en-us');
  static bool get useI18n => getSetting('USE_I18N', true);
  static bool get useL10n => getSetting('USE_L10N', true);
  static bool get useTz => getSetting('USE_TZ', true);

  static List<String> get installedApps => getSetting('INSTALLED_APPS', <String>[]);
  static List<String> get middleware => getSetting('MIDDLEWARE', <String>[]);

  static String get rootUrlConf => getSetting('ROOT_URLCONF', '');
  static String get wsgiApplication => getSetting('WSGI_APPLICATION', '');
  static String get asgiApplication => getSetting('ASGI_APPLICATION', '');

  static Map<String, dynamic> get databases => getSetting('DATABASES', <String, dynamic>{});
  static Map<String, dynamic> get defaultDatabase => databases['default'] ?? {};

  static String get mediaUrl => getSetting('MEDIA_URL', '/media/');
  static String get mediaRoot => getSetting('MEDIA_ROOT', '');
  static String get staticUrl => getSetting('STATIC_URL', '/static/');
  static String get staticRoot => getSetting('STATIC_ROOT', '');
  static List<String> get staticFilesDirs => getSetting('STATICFILES_DIRS', <String>[]);
  static List<String> get staticFilesFinders => getSetting('STATICFILES_FINDERS', <String>[]);

  static List<Map<String, dynamic>> get templates => getSetting('TEMPLATES', <Map<String, dynamic>>[]);
  static Map<String, dynamic> get defaultTemplate => templates.isNotEmpty ? templates.first : {};

  static String get defaultFromEmail => getSetting('DEFAULT_FROM_EMAIL', 'webmaster@localhost');
  static String get serverEmail => getSetting('SERVER_EMAIL', 'root@localhost');
  static String get emailHost => getSetting('EMAIL_HOST', 'localhost');
  static int get emailPort => getSetting('EMAIL_PORT', 25);
  static String get emailHostUser => getSetting('EMAIL_HOST_USER', '');
  static String get emailHostPassword => getSetting('EMAIL_HOST_PASSWORD', '');
  static bool get emailUseTls => getSetting('EMAIL_USE_TLS', false);
  static bool get emailUseSsl => getSetting('EMAIL_USE_SSL', false);
  static int get emailTimeout => getSetting('EMAIL_TIMEOUT', 60);
  static String get emailSslKeyfile => getSetting('EMAIL_SSL_KEYFILE', '');
  static String get emailSslCertfile => getSetting('EMAIL_SSL_CERTFILE', '');

  static String get sessionCookieName => getSetting('SESSION_COOKIE_NAME', 'sessionid');
  static String get sessionCookieAge => getSetting('SESSION_COOKIE_AGE', '1209600'); // 2 weeks
  static String get sessionCookieDomain => getSetting('SESSION_COOKIE_DOMAIN', '');
  static String get sessionCookiePath => getSetting('SESSION_COOKIE_PATH', '/');
  static bool get sessionCookieSecure => getSetting('SESSION_COOKIE_SECURE', false);
  static bool get sessionCookieHttponly => getSetting('SESSION_COOKIE_HTTPONLY', true);
  static String get sessionCookieSamesite => getSetting('SESSION_COOKIE_SAMESITE', 'Lax');
  static bool get sessionSaveEveryRequest => getSetting('SESSION_SAVE_EVERY_REQUEST', false);
  static bool get sessionExpireAtBrowserClose => getSetting('SESSION_EXPIRE_AT_BROWSER_CLOSE', false);
  static String get sessionEngine => getSetting('SESSION_ENGINE', 'django.contrib.sessions.backends.db');
  static String get sessionFileStoragePath => getSetting('SESSION_FILE_STORAGE_PATH', '');

  static String get csrfCookieName => getSetting('CSRF_COOKIE_NAME', 'csrftoken');
  static String get csrfCookieAge => getSetting('CSRF_COOKIE_AGE', '31449600'); // 1 year
  static String get csrfCookieDomain => getSetting('CSRF_COOKIE_DOMAIN', '');
  static String get csrfCookiePath => getSetting('CSRF_COOKIE_PATH', '/');
  static bool get csrfCookieSecure => getSetting('CSRF_COOKIE_SECURE', false);
  static bool get csrfCookieHttponly => getSetting('CSRF_COOKIE_HTTPONLY', false);
  static String get csrfCookieSamesite => getSetting('CSRF_COOKIE_SAMESITE', 'Lax');
  static String get csrfHeaderName => getSetting('CSRF_HEADER_NAME', 'HTTP_X_CSRFTOKEN');
  static List<String> get csrfTrustedOrigins => getSetting('CSRF_TRUSTED_ORIGINS', <String>[]);

  static Map<String, dynamic> get caches => getSetting('CACHES', <String, dynamic>{});
  static Map<String, dynamic> get defaultCache => caches['default'] ?? {};

  static Map<String, dynamic> get logging => getSetting('LOGGING', <String, dynamic>{});
  static Level get logLevel => _parseLogLevel(getSetting('LOG_LEVEL', 'INFO'));

  static Level _parseLogLevel(String level) {
    switch (level.toUpperCase()) {
      case 'ALL':
        return Level.ALL;
      case 'FINEST':
        return Level.FINEST;
      case 'FINER':
        return Level.FINER;
      case 'FINE':
        return Level.FINE;
      case 'CONFIG':
        return Level.CONFIG;
      case 'INFO':
        return Level.INFO;
      case 'WARNING':
        return Level.WARNING;
      case 'SEVERE':
        return Level.SEVERE;
      case 'SHOUT':
        return Level.SHOUT;
      case 'OFF':
        return Level.OFF;
      default:
        return Level.INFO;
    }
  }

  static String get authUserModel => getSetting('AUTH_USER_MODEL', 'auth.User');
  static List<String> get authenticationBackends => getSetting('AUTHENTICATION_BACKENDS', <String>[]);
  static String get loginUrl => getSetting('LOGIN_URL', '/accounts/login/');
  static String get loginRedirectUrl => getSetting('LOGIN_REDIRECT_URL', '/accounts/profile/');
  static String get logoutRedirectUrl => getSetting('LOGOUT_REDIRECT_URL', '');

  static bool get useEtags => getSetting('USE_ETAGS', false);
  static bool get prependWww => getSetting('PREPEND_WWW', false);
  static bool get appendSlash => getSetting('APPEND_SLASH', true);
  static bool get forceScriptName => getSetting('FORCE_SCRIPT_NAME', false);
  static bool get disallowedUserAgents => getSetting('DISALLOWED_USER_AGENTS', false);

  static int get dataUploadMaxMemorySize => getSetting('DATA_UPLOAD_MAX_MEMORY_SIZE', 2621440); // 2.5MB
  static int get dataUploadMaxNumberFields => getSetting('DATA_UPLOAD_MAX_NUMBER_FIELDS', 1000);
  static int get fileUploadMaxMemorySize => getSetting('FILE_UPLOAD_MAX_MEMORY_SIZE', 2621440); // 2.5MB
  static List<String> get fileUploadHandlers => getSetting('FILE_UPLOAD_HANDLERS', <String>[]);
  static String get fileUploadTempDir => getSetting('FILE_UPLOAD_TEMP_DIR', Directory.systemTemp.path);
  static int get fileUploadPermissions => getSetting('FILE_UPLOAD_PERMISSIONS', 420); // 0o644
  static int get fileUploadDirectoryPermissions => getSetting('FILE_UPLOAD_DIRECTORY_PERMISSIONS', 493); // 0o755

  static List<String> get secureProxyHeaders => getSetting('SECURE_PROXY_HEADERS', <String>[]);
  static bool get secureRedirectExempt => getSetting('SECURE_REDIRECT_EXEMPT', false);
  static bool get secureSslRedirect => getSetting('SECURE_SSL_REDIRECT', false);
  static String get secureSslHost => getSetting('SECURE_SSL_HOST', '');
  static int get secureHstsSeconds => getSetting('SECURE_HSTS_SECONDS', 0);
  static bool get secureHstsIncludeSubdomains => getSetting('SECURE_HSTS_INCLUDE_SUBDOMAINS', false);
  static bool get secureHstsPreload => getSetting('SECURE_HSTS_PRELOAD', false);
  static bool get secureContentTypeNosniff => getSetting('SECURE_CONTENT_TYPE_NOSNIFF', true);
  static bool get secureBrowserXssFilter => getSetting('SECURE_BROWSER_XSS_FILTER', true);
  static String get secureReferrerPolicy => getSetting('SECURE_REFERRER_POLICY', 'same-origin');

  static bool get testRunner => getSetting('TEST_RUNNER', false);
  static String get testDatabase => getSetting('TEST_DATABASE', '');
  static List<String> get testApps => getSetting('TEST_APPS', <String>[]);

  static String get serverName => getSetting('SERVER_NAME', 'localhost');
  static int get serverPort => getSetting('SERVER_PORT', 8000);
  static String get serverHost => getSetting('SERVER_HOST', '127.0.0.1');
  static bool get serverReload => getSetting('SERVER_RELOAD', false);
  static int get serverWorkers => getSetting('SERVER_WORKERS', 1);
  static int get serverMaxRequests => getSetting('SERVER_MAX_REQUESTS', 0);
  static int get serverMaxRequestsJitter => getSetting('SERVER_MAX_REQUESTS_JITTER', 0);
  static int get serverTimeout => getSetting('SERVER_TIMEOUT', 30);
  static int get serverKeepAlive => getSetting('SERVER_KEEP_ALIVE', 2);
  static int get serverMaxConnectionsPerChild => getSetting('SERVER_MAX_CONNECTIONS_PER_CHILD', 0);

  static void validate() {
    if (!isConfigured) {
      throw Exception('Settings not configured. Call GlobalSettings.configure() first.');
    }

    if (!hasSecretKey) {
      throw Exception('SECRET_KEY setting must be set');
    }

    if (isDebug && hasAllowedHosts) {
      _logger.warning('DEBUG is True but ALLOWED_HOSTS is not set to allow all hosts');
    }

    if (databases.isEmpty) {
      throw Exception('DATABASES setting must be configured');
    }

    if (installedApps.isEmpty) {
      _logger.warning('INSTALLED_APPS is empty');
    }

    if (middleware.isEmpty) {
      _logger.warning('MIDDLEWARE is empty');
    }
  }

  static Map<String, dynamic> toMap() {
    if (!isConfigured) return {};
    return _instance!.toMap();
  }

  static String toJson() {
    if (!isConfigured) return '{}';
    return _instance!.toJson();
  }

  static void fromJson(String json) {
    if (!isConfigured) {
      throw Exception('Settings not configured. Call GlobalSettings.configure() first.');
    }
    _instance!.fromJson(json);
    _cache.clear();
  }

  static void reset() {
    _instance = null;
    _cache.clear();
  }
}