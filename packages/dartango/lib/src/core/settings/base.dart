import 'dart:convert';
import 'dart:io';

abstract class BaseSettings {
  T getSetting<T>(String key, [T? defaultValue]);
  void setSetting<T>(String key, T value);
  bool hasSetting(String key);
  void reload();
  Map<String, dynamic> toMap();
  String toJson();
  void fromJson(String json);
}

class Settings extends BaseSettings {
  final Map<String, dynamic> _settings = {};
  final Map<String, dynamic> _defaults = {};
  final Map<String, String> _environment = {};

  Settings([Map<String, dynamic>? settings]) {
    if (settings != null) {
      _settings.addAll(settings);
    }
    _loadEnvironment();
    _setDefaults();
  }

  void _loadEnvironment() {
    _environment.addAll(Platform.environment);
  }

  void _setDefaults() {
    _defaults.addAll(<String, dynamic>{
      'DEBUG': false,
      'SECRET_KEY': '',
      'ALLOWED_HOSTS': ['*'],
      'TIME_ZONE': 'UTC',
      'LANGUAGE_CODE': 'en-us',
      'USE_I18N': true,
      'USE_L10N': true,
      'USE_TZ': true,
      'INSTALLED_APPS': [
        'dartango.contrib.admin',
        'dartango.contrib.auth',
        'dartango.contrib.contenttypes',
        'dartango.contrib.sessions',
        'dartango.contrib.messages',
        'dartango.contrib.staticfiles',
      ],
      'MIDDLEWARE': [
        'dartango.middleware.security.SecurityMiddleware',
        'dartango.contrib.sessions.middleware.SessionMiddleware',
        'dartango.middleware.common.CommonMiddleware',
        'dartango.middleware.csrf.CsrfViewMiddleware',
        'dartango.contrib.auth.middleware.AuthenticationMiddleware',
        'dartango.contrib.messages.middleware.MessageMiddleware',
        'dartango.middleware.clickjacking.XFrameOptionsMiddleware',
      ],
      'ROOT_URLCONF': '',
      'WSGI_APPLICATION': '',
      'ASGI_APPLICATION': '',
      'DATABASES': {
        'default': {
          'ENGINE': 'dartango.db.backends.sqlite3',
          'NAME': ':memory:',
        }
      },
      'MEDIA_URL': '/media/',
      'MEDIA_ROOT': '',
      'STATIC_URL': '/static/',
      'STATIC_ROOT': '',
      'STATICFILES_DIRS': [],
      'STATICFILES_FINDERS': [
        'dartango.contrib.staticfiles.finders.FileSystemFinder',
        'dartango.contrib.staticfiles.finders.AppDirectoriesFinder',
      ],
      'TEMPLATES': [
        {
          'BACKEND': 'dartango.template.backends.dartango.DartangoTemplates',
          'DIRS': [],
          'APP_DIRS': true,
          'OPTIONS': {
            'context_processors': [
              'dartango.template.context_processors.debug',
              'dartango.template.context_processors.request',
              'dartango.contrib.auth.context_processors.auth',
              'dartango.contrib.messages.context_processors.messages',
            ],
          },
        },
      ],
      'DEFAULT_FROM_EMAIL': 'webmaster@localhost',
      'SERVER_EMAIL': 'root@localhost',
      'EMAIL_HOST': 'localhost',
      'EMAIL_PORT': 25,
      'EMAIL_HOST_USER': '',
      'EMAIL_HOST_PASSWORD': '',
      'EMAIL_USE_TLS': false,
      'EMAIL_USE_SSL': false,
      'EMAIL_TIMEOUT': 60,
      'EMAIL_SSL_KEYFILE': '',
      'EMAIL_SSL_CERTFILE': '',
      'SESSION_COOKIE_NAME': 'sessionid',
      'SESSION_COOKIE_AGE': 1209600, // 2 weeks
      'SESSION_COOKIE_DOMAIN': '',
      'SESSION_COOKIE_PATH': '/',
      'SESSION_COOKIE_SECURE': false,
      'SESSION_COOKIE_HTTPONLY': true,
      'SESSION_COOKIE_SAMESITE': 'Lax',
      'SESSION_SAVE_EVERY_REQUEST': false,
      'SESSION_EXPIRE_AT_BROWSER_CLOSE': false,
      'SESSION_ENGINE': 'dartango.contrib.sessions.backends.db',
      'SESSION_FILE_STORAGE_PATH': '',
      'CSRF_COOKIE_NAME': 'csrftoken',
      'CSRF_COOKIE_AGE': 31449600, // 1 year
      'CSRF_COOKIE_DOMAIN': '',
      'CSRF_COOKIE_PATH': '/',
      'CSRF_COOKIE_SECURE': false,
      'CSRF_COOKIE_HTTPONLY': false,
      'CSRF_COOKIE_SAMESITE': 'Lax',
      'CSRF_HEADER_NAME': 'HTTP_X_CSRFTOKEN',
      'CSRF_TRUSTED_ORIGINS': [],
      'CACHES': {
        'default': {
          'BACKEND': 'dartango.core.cache.backends.locmem.LocMemCache',
        }
      },
      'LOGGING': {
        'version': 1,
        'disable_existing_loggers': false,
        'formatters': {
          'verbose': {
            'format':
                '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
          },
          'simple': {
            'format': '{levelname} {message}',
            'style': '{',
          },
        },
        'handlers': {
          'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'simple',
          },
        },
        'root': {
          'handlers': ['console'],
          'level': 'INFO',
        },
      },
      'AUTH_USER_MODEL': 'auth.User',
      'AUTHENTICATION_BACKENDS': [
        'dartango.contrib.auth.backends.ModelBackend',
      ],
      'LOGIN_URL': '/accounts/login/',
      'LOGIN_REDIRECT_URL': '/accounts/profile/',
      'LOGOUT_REDIRECT_URL': '',
      'USE_ETAGS': false,
      'PREPEND_WWW': false,
      'APPEND_SLASH': true,
      'FORCE_SCRIPT_NAME': false,
      'DISALLOWED_USER_AGENTS': [],
      'DATA_UPLOAD_MAX_MEMORY_SIZE': 2621440, // 2.5MB
      'DATA_UPLOAD_MAX_NUMBER_FIELDS': 1000,
      'FILE_UPLOAD_MAX_MEMORY_SIZE': 2621440, // 2.5MB
      'FILE_UPLOAD_HANDLERS': [
        'dartango.core.files.uploadhandler.MemoryFileUploadHandler',
        'dartango.core.files.uploadhandler.TemporaryFileUploadHandler',
      ],
      'FILE_UPLOAD_TEMP_DIR': '',
      'FILE_UPLOAD_PERMISSIONS': 420, // 0o644
      'FILE_UPLOAD_DIRECTORY_PERMISSIONS': 493, // 0o755
      'SECURE_PROXY_HEADERS': [],
      'SECURE_REDIRECT_EXEMPT': [],
      'SECURE_SSL_REDIRECT': false,
      'SECURE_SSL_HOST': '',
      'SECURE_HSTS_SECONDS': 0,
      'SECURE_HSTS_INCLUDE_SUBDOMAINS': false,
      'SECURE_HSTS_PRELOAD': false,
      'SECURE_CONTENT_TYPE_NOSNIFF': true,
      'SECURE_BROWSER_XSS_FILTER': true,
      'SECURE_REFERRER_POLICY': 'same-origin',
      'TEST_RUNNER': 'dartango.test.runner.DartangoTestSuiteRunner',
      'TEST_DATABASE': '',
      'TEST_APPS': [],
      'SERVER_NAME': 'localhost',
      'SERVER_PORT': 8000,
      'SERVER_HOST': '127.0.0.1',
      'SERVER_RELOAD': false,
      'SERVER_WORKERS': 1,
      'SERVER_MAX_REQUESTS': 0,
      'SERVER_MAX_REQUESTS_JITTER': 0,
      'SERVER_TIMEOUT': 30,
      'SERVER_KEEP_ALIVE': 2,
      'SERVER_MAX_CONNECTIONS_PER_CHILD': 0,
      'LOG_LEVEL': 'INFO',
    });
  }

  @override
  T getSetting<T>(String key, [T? defaultValue]) {
    if (_settings.containsKey(key)) {
      return _settings[key] as T;
    }

    final envKey = key.toUpperCase();
    if (_environment.containsKey(envKey)) {
      return _parseEnvironmentValue<T>(_environment[envKey]!, defaultValue);
    }

    if (_defaults.containsKey(key)) {
      return _defaults[key] as T;
    }

    if (defaultValue != null) {
      return defaultValue;
    }

    throw Exception('Setting $key not found and no default value provided');
  }

  T _parseEnvironmentValue<T>(String value, T? defaultValue) {
    try {
      switch (T) {
        case bool:
          return (value.toLowerCase() == 'true' || value == '1') as T;
        case int:
          return int.parse(value) as T;
        case double:
          return double.parse(value) as T;
        case String:
          return value as T;
        case const (List<String>):
          return value
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList() as T;
        default:
          if (value.startsWith('{') || value.startsWith('[')) {
            return json.decode(value) as T;
          }
          return value as T;
      }
    } catch (e) {
      print('Failed to parse environment value $value for type $T: $e');
      return defaultValue ?? value as T;
    }
  }

  @override
  void setSetting<T>(String key, T value) {
    _settings[key] = value;
  }

  @override
  bool hasSetting(String key) {
    return _settings.containsKey(key) ||
        _environment.containsKey(key.toUpperCase()) ||
        _defaults.containsKey(key);
  }

  @override
  void reload() {
    _loadEnvironment();
  }

  @override
  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
    result.addAll(_defaults);
    result.addAll(_settings);

    for (final entry in _environment.entries) {
      final key = entry.key.toLowerCase();
      if (_defaults.containsKey(key) || _settings.containsKey(key)) {
        result[key] = entry.value;
      }
    }

    return result;
  }

  @override
  String toJson() {
    return json.encode(toMap());
  }

  @override
  void fromJson(String jsonString) {
    final data = json.decode(jsonString) as Map<String, dynamic>;
    _settings.addAll(data);
  }

  void fromMap(Map<String, dynamic> data) {
    _settings.addAll(data);
  }

  void clear() {
    _settings.clear();
  }

  void remove(String key) {
    _settings.remove(key);
  }

  List<String> get keys =>
      [..._defaults.keys, ..._settings.keys].toSet().toList();

  bool get debug => getSetting<bool>('DEBUG', false);
  set debug(bool value) => setSetting('DEBUG', value);

  String get secretKey => getSetting<String>('SECRET_KEY', '');
  set secretKey(String value) => setSetting('SECRET_KEY', value);

  List<String> get allowedHosts =>
      getSetting<List<String>>('ALLOWED_HOSTS', ['*']);
  set allowedHosts(List<String> value) => setSetting('ALLOWED_HOSTS', value);

  String get timeZone => getSetting<String>('TIME_ZONE', 'UTC');
  set timeZone(String value) => setSetting('TIME_ZONE', value);

  String get languageCode => getSetting<String>('LANGUAGE_CODE', 'en-us');
  set languageCode(String value) => setSetting('LANGUAGE_CODE', value);

  bool get useI18n => getSetting<bool>('USE_I18N', true);
  set useI18n(bool value) => setSetting('USE_I18N', value);

  bool get useL10n => getSetting<bool>('USE_L10N', true);
  set useL10n(bool value) => setSetting('USE_L10N', value);

  bool get useTz => getSetting<bool>('USE_TZ', true);
  set useTz(bool value) => setSetting('USE_TZ', value);

  List<String> get installedApps =>
      getSetting<List<String>>('INSTALLED_APPS', []);
  set installedApps(List<String> value) => setSetting('INSTALLED_APPS', value);

  List<String> get middleware => getSetting<List<String>>('MIDDLEWARE', []);
  set middleware(List<String> value) => setSetting('MIDDLEWARE', value);

  String get rootUrlConf => getSetting<String>('ROOT_URLCONF', '');
  set rootUrlConf(String value) => setSetting('ROOT_URLCONF', value);

  String get wsgiApplication => getSetting<String>('WSGI_APPLICATION', '');
  set wsgiApplication(String value) => setSetting('WSGI_APPLICATION', value);

  String get asgiApplication => getSetting<String>('ASGI_APPLICATION', '');
  set asgiApplication(String value) => setSetting('ASGI_APPLICATION', value);

  Map<String, dynamic> get databases =>
      getSetting<Map<String, dynamic>>('DATABASES', {});
  set databases(Map<String, dynamic> value) => setSetting('DATABASES', value);

  String get mediaUrl => getSetting<String>('MEDIA_URL', '/media/');
  set mediaUrl(String value) => setSetting('MEDIA_URL', value);

  String get mediaRoot => getSetting<String>('MEDIA_ROOT', '');
  set mediaRoot(String value) => setSetting('MEDIA_ROOT', value);

  String get staticUrl => getSetting<String>('STATIC_URL', '/static/');
  set staticUrl(String value) => setSetting('STATIC_URL', value);

  String get staticRoot => getSetting<String>('STATIC_ROOT', '');
  set staticRoot(String value) => setSetting('STATIC_ROOT', value);

  List<String> get staticFilesDirs =>
      getSetting<List<String>>('STATICFILES_DIRS', []);
  set staticFilesDirs(List<String> value) =>
      setSetting('STATICFILES_DIRS', value);

  List<Map<String, dynamic>> get templates =>
      getSetting<List<Map<String, dynamic>>>('TEMPLATES', []);
  set templates(List<Map<String, dynamic>> value) =>
      setSetting('TEMPLATES', value);

  String get defaultFromEmail =>
      getSetting<String>('DEFAULT_FROM_EMAIL', 'webmaster@localhost');
  set defaultFromEmail(String value) => setSetting('DEFAULT_FROM_EMAIL', value);

  String get serverEmail =>
      getSetting<String>('SERVER_EMAIL', 'root@localhost');
  set serverEmail(String value) => setSetting('SERVER_EMAIL', value);

  String get emailHost => getSetting<String>('EMAIL_HOST', 'localhost');
  set emailHost(String value) => setSetting('EMAIL_HOST', value);

  int get emailPort => getSetting<int>('EMAIL_PORT', 25);
  set emailPort(int value) => setSetting('EMAIL_PORT', value);

  String get emailHostUser => getSetting<String>('EMAIL_HOST_USER', '');
  set emailHostUser(String value) => setSetting('EMAIL_HOST_USER', value);

  String get emailHostPassword => getSetting<String>('EMAIL_HOST_PASSWORD', '');
  set emailHostPassword(String value) =>
      setSetting('EMAIL_HOST_PASSWORD', value);

  bool get emailUseTls => getSetting<bool>('EMAIL_USE_TLS', false);
  set emailUseTls(bool value) => setSetting('EMAIL_USE_TLS', value);

  bool get emailUseSsl => getSetting<bool>('EMAIL_USE_SSL', false);
  set emailUseSsl(bool value) => setSetting('EMAIL_USE_SSL', value);

  int get emailTimeout => getSetting<int>('EMAIL_TIMEOUT', 60);
  set emailTimeout(int value) => setSetting('EMAIL_TIMEOUT', value);

  String get serverName => getSetting<String>('SERVER_NAME', 'localhost');
  set serverName(String value) => setSetting('SERVER_NAME', value);

  int get serverPort => getSetting<int>('SERVER_PORT', 8000);
  set serverPort(int value) => setSetting('SERVER_PORT', value);

  String get serverHost => getSetting<String>('SERVER_HOST', '127.0.0.1');
  set serverHost(String value) => setSetting('SERVER_HOST', value);

  bool get serverReload => getSetting<bool>('SERVER_RELOAD', false);
  set serverReload(bool value) => setSetting('SERVER_RELOAD', value);

  @override
  String toString() => 'Settings(${_settings.length} settings)';
}
