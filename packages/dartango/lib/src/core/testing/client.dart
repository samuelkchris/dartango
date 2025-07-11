import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;

import '../http/request.dart';
import '../http/response.dart';
import '../middleware/base.dart';
import '../middleware/session.dart';
import '../sessions/sessions.dart';
import '../urls/resolver.dart';

class TestClient {
  final URLConfiguration urlConfig;
  final List<BaseMiddleware> middleware;
  final Map<String, String> _defaultHeaders;
  final CookieJar _cookies;
  Session? _session;

  TestClient({
    required this.urlConfig,
    this.middleware = const [],
    Map<String, String>? defaultHeaders,
  })  : _defaultHeaders = defaultHeaders ?? {},
        _cookies = CookieJar();

  Future<TestResponse> get(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    bool follow = false,
  }) async {
    return await _makeRequest(
      'GET',
      path,
      queryParams: queryParams,
      headers: headers,
      follow: follow,
    );
  }

  Future<TestResponse> post(
    String path, {
    dynamic data,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    String? contentType,
    bool follow = false,
  }) async {
    return await _makeRequest(
      'POST',
      path,
      data: data,
      queryParams: queryParams,
      headers: headers,
      contentType: contentType,
      follow: follow,
    );
  }

  Future<TestResponse> put(
    String path, {
    dynamic data,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    String? contentType,
    bool follow = false,
  }) async {
    return await _makeRequest(
      'PUT',
      path,
      data: data,
      queryParams: queryParams,
      headers: headers,
      contentType: contentType,
      follow: follow,
    );
  }

  Future<TestResponse> patch(
    String path, {
    dynamic data,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    String? contentType,
    bool follow = false,
  }) async {
    return await _makeRequest(
      'PATCH',
      path,
      data: data,
      queryParams: queryParams,
      headers: headers,
      contentType: contentType,
      follow: follow,
    );
  }

  Future<TestResponse> delete(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    bool follow = false,
  }) async {
    return await _makeRequest(
      'DELETE',
      path,
      queryParams: queryParams,
      headers: headers,
      follow: follow,
    );
  }

  Future<TestResponse> head(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    bool follow = false,
  }) async {
    return await _makeRequest(
      'HEAD',
      path,
      queryParams: queryParams,
      headers: headers,
      follow: follow,
    );
  }

  Future<TestResponse> options(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    bool follow = false,
  }) async {
    return await _makeRequest(
      'OPTIONS',
      path,
      queryParams: queryParams,
      headers: headers,
      follow: follow,
    );
  }

  Future<TestResponse> _makeRequest(
    String method,
    String path, {
    dynamic data,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    String? contentType,
    bool follow = false,
  }) async {
    final uri = _buildUri(path, queryParams);
    final requestHeaders = _buildHeaders(headers, contentType);
    final body = _prepareBody(data, contentType);

    final request = TestHttpRequest(
      method: method,
      uri: uri,
      headers: requestHeaders,
      body: body,
      cookies: _cookies,
      session: _session,
    );

    await _applyCookiesToRequest(request);

    HttpResponse response = await _processRequest(request);

    _extractCookiesFromResponse(response);
    _updateSession(request);

    final testResponse = TestResponse(response, request);

    if (follow && testResponse.isRedirect) {
      final location = response.headers['location'];
      if (location != null) {
        return await get(location, follow: true);
      }
    }

    return testResponse;
  }

  Uri _buildUri(String path, Map<String, String>? queryParams) {
    var uri = Uri.parse(path);

    if (queryParams != null && queryParams.isNotEmpty) {
      final existingParams = Map<String, String>.from(uri.queryParameters);
      existingParams.addAll(queryParams);
      uri = uri.replace(queryParameters: existingParams);
    }

    return uri;
  }

  Map<String, String> _buildHeaders(
    Map<String, String>? headers,
    String? contentType,
  ) {
    final requestHeaders = Map<String, String>.from(_defaultHeaders);

    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    if (contentType != null) {
      requestHeaders['content-type'] = contentType;
    }

    return requestHeaders;
  }

  String _prepareBody(dynamic data, String? contentType) {
    if (data == null) return '';

    if (data is String) {
      return data;
    }

    if (data is Map) {
      final ct = contentType ?? 'application/json';
      if (ct.contains('json')) {
        return json.encode(data);
      } else if (ct.contains('form-urlencoded')) {
        return data.entries
            .map((e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
      }
    }

    return data.toString();
  }

  Future<void> _applyCookiesToRequest(TestHttpRequest request) async {
    final cookies = _cookies.getCookies(request.uri);
    if (cookies.isNotEmpty) {
      final cookieHeader =
          cookies.map((c) => '${c.name}=${c.value}').join('; ');
      request.headers['cookie'] = cookieHeader;
    }
  }

  Future<HttpResponse> _processRequest(TestHttpRequest request) async {
    HttpResponse response;

    try {
      final match = urlConfig.resolve(request.path);
      if (match == null) {
        response = HttpResponse(
          'Not Found',
          statusCode: 404,
          headers: {'content-type': 'text/plain'},
        );
      } else {
        response = await _executeView(request, match);
      }
    } catch (e) {
      response = HttpResponse(
        'Internal Server Error: $e',
        statusCode: 500,
        headers: {'content-type': 'text/plain'},
      );
    }

    for (final mw in middleware) {
      response = await mw.processResponse(request, response);
    }

    return response;
  }

  Future<HttpResponse> _executeView(
      TestHttpRequest request, ResolverMatch match) async {
    for (final mw in middleware) {
      final earlyResponse = await mw.processRequest(request);
      if (earlyResponse != null) {
        return earlyResponse;
      }
    }

    final viewFunction = match.func;
    return await viewFunction(request, match.kwargs);
  }

  void _extractCookiesFromResponse(HttpResponse response) {
    final setCookieHeaders = response.headers.entries
        .where((entry) => entry.key.toLowerCase() == 'set-cookie')
        .map((entry) => entry.value)
        .toList();

    for (final cookieHeader in setCookieHeaders) {
      final cookie = Cookie.fromSetCookieValue(cookieHeader);
      _cookies.add(cookie);
    }
  }

  void _updateSession(TestHttpRequest request) {
    if (request.hasSession) {
      _session = request.session;
    }
  }

  void login(
      {required String username,
      String? password,
      Map<String, dynamic>? userDetails}) {
    _session ??=
        Session(sessionKey: 'test-session', store: InMemorySessionStore());
    _session!['_auth_user_id'] = username;
    _session!['_auth_user_backend'] = 'test_backend';

    if (userDetails != null) {
      for (final entry in userDetails.entries) {
        _session![entry.key] = entry.value;
      }
    }
  }

  void logout() {
    _session?.clear();
    _session = null;
  }

  void addCookie(
    String name,
    String value, {
    String? domain,
    String? path,
    DateTime? expires,
    bool? secure,
    bool? httpOnly,
  }) {
    final cookie = Cookie(name, value);
    if (domain != null) cookie.domain = domain;
    if (path != null) cookie.path = path;
    if (expires != null) cookie.expires = expires;
    if (secure != null) cookie.secure = secure;
    if (httpOnly != null) cookie.httpOnly = httpOnly;

    _cookies.add(cookie);
  }

  void clearCookies() {
    _cookies.clear();
  }

  Map<String, String> get cookies {
    final result = <String, String>{};
    for (final cookie in _cookies.cookies) {
      result[cookie.name] = cookie.value;
    }
    return result;
  }

  Session? get session => _session;
}

class TestHttpRequest extends HttpRequest {
  final String _bodyString;
  final CookieJar _cookieJar;
  Session? session;

  TestHttpRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    required String body,
    required CookieJar cookies,
    this.session,
  })  : _bodyString = body,
        _cookieJar = cookies,
        super(_createShelfRequest(method, uri, headers, body));

  static shelf.Request _createShelfRequest(
      String method, Uri uri, Map<String, String> headers, String body) {
    return shelf.Request(method, uri, headers: headers, body: body);
  }

  @override
  Future<String> get body async => _bodyString;

  @override
  Map<String, Cookie> get cookies {
    final result = <String, Cookie>{};
    for (final cookie in _cookieJar.getCookies(uri)) {
      result[cookie.name] = cookie;
    }
    return result;
  }

  bool get hasSession => session != null;
}

class TestResponse {
  final HttpResponse _response;
  final TestHttpRequest _request;

  TestResponse(this._response, this._request);

  int get statusCode => _response.statusCode;
  String get body => _response.body?.toString() ?? '';
  Map<String, String> get headers => _response.headers;
  TestHttpRequest get request => _request;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get isRedirect => statusCode >= 300 && statusCode < 400;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isServerError => statusCode >= 500;

  Map<String, dynamic>? get json {
    final contentType = headers['content-type'] ?? '';
    if (contentType.contains('json')) {
      try {
        return jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  List<dynamic>? get jsonList {
    final contentType = headers['content-type'] ?? '';
    if (contentType.contains('json')) {
      try {
        return jsonDecode(body) as List<dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  void assertStatusCode(int expectedStatusCode) {
    if (statusCode != expectedStatusCode) {
      throw AssertionError(
          'Expected status code $expectedStatusCode, got $statusCode');
    }
  }

  void assertContains(String text, {bool caseSensitive = true}) {
    final bodyToCheck = caseSensitive ? body : body.toLowerCase();
    final textToCheck = caseSensitive ? text : text.toLowerCase();

    if (!bodyToCheck.contains(textToCheck)) {
      throw AssertionError('Response body does not contain "$text"');
    }
  }

  void assertNotContains(String text, {bool caseSensitive = true}) {
    final bodyToCheck = caseSensitive ? body : body.toLowerCase();
    final textToCheck = caseSensitive ? text : text.toLowerCase();

    if (bodyToCheck.contains(textToCheck)) {
      throw AssertionError('Response body contains "$text" but should not');
    }
  }

  void assertRedirects(String expectedUrl) {
    if (!isRedirect) {
      throw AssertionError('Response is not a redirect (status: $statusCode)');
    }

    final location = headers['location'];
    if (location != expectedUrl) {
      throw AssertionError(
          'Expected redirect to "$expectedUrl", got "$location"');
    }
  }

  void assertHeaderExists(String headerName) {
    final lowerHeaderName = headerName.toLowerCase();
    final exists =
        headers.keys.any((key) => key.toLowerCase() == lowerHeaderName);

    if (!exists) {
      throw AssertionError('Header "$headerName" not found in response');
    }
  }

  void assertHeaderEquals(String headerName, String expectedValue) {
    assertHeaderExists(headerName);

    final lowerHeaderName = headerName.toLowerCase();
    final actualValue = headers.entries
        .where((entry) => entry.key.toLowerCase() == lowerHeaderName)
        .first
        .value;

    if (actualValue != expectedValue) {
      throw AssertionError(
          'Header "$headerName" expected "$expectedValue", got "$actualValue"');
    }
  }

  void assertJsonEquals(Map<String, dynamic> expectedJson) {
    final actualJson = json;
    if (actualJson == null) {
      throw AssertionError('Response is not valid JSON');
    }

    if (!_deepEquals(actualJson, expectedJson)) {
      throw AssertionError('JSON does not match expected value');
    }
  }

  bool _deepEquals(dynamic a, dynamic b) {
    if (a.runtimeType != b.runtimeType) return false;

    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
      }
      return true;
    }

    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }

    return a == b;
  }
}

class CookieJar {
  final List<Cookie> _cookies = [];

  void add(Cookie cookie) {
    _cookies.removeWhere((c) =>
        c.name == cookie.name &&
        c.domain == cookie.domain &&
        c.path == cookie.path);
    _cookies.add(cookie);
  }

  List<Cookie> getCookies(Uri uri) {
    return _cookies.where((cookie) {
      if (cookie.domain != null && !_domainMatches(uri.host, cookie.domain!)) {
        return false;
      }

      if (cookie.path != null && !uri.path.startsWith(cookie.path!)) {
        return false;
      }

      if (cookie.expires != null && DateTime.now().isAfter(cookie.expires!)) {
        return false;
      }

      return true;
    }).toList();
  }

  bool _domainMatches(String host, String domain) {
    if (domain.startsWith('.')) {
      return host.endsWith(domain.substring(1)) || host == domain.substring(1);
    }
    return host == domain;
  }

  void clear() {
    _cookies.clear();
  }

  List<Cookie> get cookies => List.unmodifiable(_cookies);
}
