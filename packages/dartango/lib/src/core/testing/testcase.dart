import 'dart:async';

import '../middleware/base.dart';
import '../urls/resolver.dart';
import 'client.dart';
import 'database.dart';

abstract class TestCase {
  late TestClient client;
  TestTransactionContext? _transaction;

  void setUp() {
    client = createClient();
    TestDatabaseMixin.clearAllFixtures();
  }

  void tearDown() {
    if (_transaction?.isActive == true) {
      _transaction!.rollback();
    }
    TestDatabaseMixin.clearAllFixtures();
  }

  TestClient createClient() {
    return TestClient(
      urlConfig: getUrlConfiguration(),
      middleware: getMiddleware(),
      defaultHeaders: getDefaultHeaders(),
    );
  }

  URLConfiguration getUrlConfiguration();

  List<BaseMiddleware> getMiddleware() => [];

  Map<String, String> getDefaultHeaders() => {};

  Future<void> runInTransaction(Future<void> Function() operation) async {
    _transaction = TestTransactionContext();
    _transaction!.begin();

    try {
      await operation();
      _transaction!.commit();
    } catch (e) {
      _transaction!.rollback();
      rethrow;
    } finally {
      _transaction = null;
    }
  }

  void assertResponse(TestResponse response, int expectedStatusCode) {
    response.assertStatusCode(expectedStatusCode);
  }

  void assertResponseContains(TestResponse response, String text) {
    response.assertContains(text);
  }

  void assertResponseNotContains(TestResponse response, String text) {
    response.assertNotContains(text);
  }

  void assertRedirects(TestResponse response, String expectedUrl) {
    response.assertRedirects(expectedUrl);
  }

  void assertHeaderExists(TestResponse response, String headerName) {
    response.assertHeaderExists(headerName);
  }

  void assertHeaderEquals(
      TestResponse response, String headerName, String expectedValue) {
    response.assertHeaderEquals(headerName, expectedValue);
  }

  void assertJsonResponse(
      TestResponse response, Map<String, dynamic> expectedJson) {
    response.assertJsonEquals(expectedJson);
  }
}

abstract class TransactionTestCase extends TestCase {
  @override
  void setUp() {
    super.setUp();
    _transaction = TestTransactionContext();
    _transaction!.begin();
  }

  @override
  void tearDown() {
    if (_transaction?.isActive == true) {
      _transaction!.rollback();
    }
    super.tearDown();
  }
}

class SimpleTestCase extends TestCase {
  final URLConfiguration _urlConfig;
  final List<BaseMiddleware> _middleware;
  final Map<String, String> _defaultHeaders;

  SimpleTestCase({
    required URLConfiguration urlConfig,
    List<BaseMiddleware>? middleware,
    Map<String, String>? defaultHeaders,
  })  : _urlConfig = urlConfig,
        _middleware = middleware ?? [],
        _defaultHeaders = defaultHeaders ?? {};

  @override
  URLConfiguration getUrlConfiguration() => _urlConfig;

  @override
  List<BaseMiddleware> getMiddleware() => _middleware;

  @override
  Map<String, String> getDefaultHeaders() => _defaultHeaders;
}

mixin LiveServerTestMixin on TestCase {
  static int _portCounter = 8000;
  late final int serverPort;
  late final String serverUrl;

  @override
  void setUp() {
    super.setUp();
    serverPort = _portCounter++;
    serverUrl = 'http://localhost:$serverPort';
  }

  @override
  TestClient createClient() {
    return TestClient(
      urlConfig: getUrlConfiguration(),
      middleware: getMiddleware(),
      defaultHeaders: {
        'host': 'localhost:$serverPort',
        ...getDefaultHeaders(),
      },
    );
  }
}

mixin StaticFilesMixin on TestCase {
  String get staticFilesDirectory => 'test/static';
  String get staticUrl => '/static/';

  String getStaticUrl(String filename) {
    return '$staticUrl$filename';
  }

  Future<TestResponse> getStaticFile(String filename) async {
    return await client.get(getStaticUrl(filename));
  }
}

mixin MailTestMixin on TestCase {
  final List<TestEmail> _sentEmails = [];

  @override
  void setUp() {
    super.setUp();
    _sentEmails.clear();
  }

  List<TestEmail> get outbox => List.unmodifiable(_sentEmails);

  void sendTestEmail(TestEmail email) {
    _sentEmails.add(email);
  }

  void assertEmailSent({String? to, String? subject, String? body}) {
    final matches = _sentEmails.where((email) {
      if (to != null && !email.to.contains(to)) return false;
      if (subject != null && email.subject != subject) return false;
      if (body != null && !email.body.contains(body)) return false;
      return true;
    }).toList();

    if (matches.isEmpty) {
      throw AssertionError('No email found matching criteria');
    }
  }

  void assertEmailNotSent({String? to, String? subject, String? body}) {
    final matches = _sentEmails.where((email) {
      if (to != null && !email.to.contains(to)) return false;
      if (subject != null && email.subject != subject) return false;
      if (body != null && !email.body.contains(body)) return false;
      return true;
    }).toList();

    if (matches.isNotEmpty) {
      throw AssertionError(
          'Found ${matches.length} emails matching criteria, expected 0');
    }
  }

  void assertEmailCount(int expectedCount) {
    if (_sentEmails.length != expectedCount) {
      throw AssertionError(
          'Expected $expectedCount emails, got ${_sentEmails.length}');
    }
  }
}

class TestEmail {
  final String subject;
  final String body;
  final String from;
  final List<String> to;
  final List<String> cc;
  final List<String> bcc;
  final Map<String, String> headers;

  const TestEmail({
    required this.subject,
    required this.body,
    required this.from,
    required this.to,
    this.cc = const [],
    this.bcc = const [],
    this.headers = const {},
  });
}

mixin CacheTestMixin on TestCase {
  Map<String, dynamic> get cacheData => TestCacheBackend._data;

  void clearCache() {
    TestCacheBackend._data.clear();
  }

  void assertCacheContains(String key) {
    if (!cacheData.containsKey(key)) {
      throw AssertionError('Cache does not contain key "$key"');
    }
  }

  void assertCacheNotContains(String key) {
    if (cacheData.containsKey(key)) {
      throw AssertionError('Cache contains key "$key" but should not');
    }
  }

  void assertCacheValue(String key, dynamic expectedValue) {
    assertCacheContains(key);
    final actualValue = cacheData[key];
    if (actualValue != expectedValue) {
      throw AssertionError(
          'Cache key "$key" expected "$expectedValue", got "$actualValue"');
    }
  }
}

class TestCacheBackend {
  static final Map<String, dynamic> _data = {};

  static dynamic get(String key) => _data[key];
  static void set(String key, dynamic value) => _data[key] = value;
  static void delete(String key) => _data.remove(key);
  static void clear() => _data.clear();
  static bool contains(String key) => _data.containsKey(key);
  static int get size => _data.length;
  static List<String> get keys => _data.keys.toList();
}

mixin OverrideSettingsMixin on TestCase {
  final Map<String, dynamic> _originalSettings = {};
  final Map<String, dynamic> _overrides = {};

  void overrideSetting(String key, dynamic value) {
    if (!_originalSettings.containsKey(key)) {
      _originalSettings[key] = getCurrentSettingValue(key);
    }
    _overrides[key] = value;
    applySettingOverride(key, value);
  }

  @override
  void tearDown() {
    for (final entry in _originalSettings.entries) {
      applySettingOverride(entry.key, entry.value);
    }
    _originalSettings.clear();
    _overrides.clear();
    super.tearDown();
  }

  dynamic getCurrentSettingValue(String key) {
    return null;
  }

  void applySettingOverride(String key, dynamic value) {}
}

class AssertionError extends Error {
  final String message;
  AssertionError(this.message);

  @override
  String toString() => 'AssertionError: $message';
}
