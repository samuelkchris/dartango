import 'dart:convert';
import 'package:test/test.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:dartango/src/core/http/request.dart';
import 'package:dartango/src/core/exceptions/http.dart';

void main() {
  group('HttpRequest', () {
    test('should parse basic GET request', () {
      final shelfRequest = shelf.Request(
          'GET', Uri.parse('http://localhost:8000/test?param=value'));
      final request = HttpRequest(shelfRequest);

      expect(request.method, equals('GET'));
      expect(request.path, equals('/test'));
      expect(request.queryString, equals('param=value'));
      expect(request.scheme, equals('http'));
      expect(request.host, equals('localhost'));
      expect(request.port, equals(8000));
      expect(request.isSecure, isFalse);
      expect(request.isGet, isTrue);
      expect(request.isPost, isFalse);
    });

    test('should parse HTTPS request', () {
      final shelfRequest =
          shelf.Request('GET', Uri.parse('https://example.com/secure'));
      final request = HttpRequest(shelfRequest);

      expect(request.scheme, equals('https'));
      expect(request.isSecure, isTrue);
    });

    test('should parse query parameters', () {
      final shelfRequest = shelf.Request(
          'GET',
          Uri.parse(
              'http://localhost/test?name=John&age=30&tags=dart&tags=web'));
      final request = HttpRequest(shelfRequest);

      expect(request.getQueryParam('name'), equals('John'));
      expect(request.getQueryParam('age'), equals('30'));
      expect(request.getQueryParams('tags'), equals(['dart', 'web']));
      expect(request.getQueryParam('nonexistent'), isNull);
      expect(request.getQueryParams('nonexistent'), isEmpty);
    });

    test('should parse headers', () {
      final shelfRequest = shelf.Request(
        'GET',
        Uri.parse('http://localhost/test'),
        headers: {
          'content-type': 'application/json',
          'user-agent': 'Test Agent',
          'x-custom-header': 'custom-value',
        },
      );
      final request = HttpRequest(shelfRequest);

      expect(request.contentType, equals('application/json'));
      expect(request.userAgent, equals('Test Agent'));
      expect(request.getHeader('x-custom-header'), equals('custom-value'));
      expect(request.hasHeader('content-type'), isTrue);
      expect(request.hasHeader('nonexistent'), isFalse);
    });

    test('should detect AJAX requests', () {
      final shelfRequest = shelf.Request(
        'GET',
        Uri.parse('http://localhost/test'),
        headers: {'x-requested-with': 'XMLHttpRequest'},
      );
      final request = HttpRequest(shelfRequest);

      expect(request.isAjax, isTrue);
    });

    test('should parse forwarded headers', () {
      final shelfRequest = shelf.Request(
        'GET',
        Uri.parse('http://localhost/test'),
        headers: {
          'x-forwarded-for': '192.168.1.1, 10.0.0.1',
          'x-forwarded-host': 'example.com',
          'x-forwarded-proto': 'https',
          'x-real-ip': '192.168.1.1',
        },
      );
      final request = HttpRequest(shelfRequest);

      expect(request.remoteAddr, equals('192.168.1.1'));
      expect(request.serverName, equals('example.com'));
      expect(request.xForwardedFor, equals('192.168.1.1, 10.0.0.1'));
      expect(request.xForwardedHost, equals('example.com'));
      expect(request.xForwardedProto, equals('https'));
      expect(request.xRealIp, equals('192.168.1.1'));
    });

    test('should parse cookies', () {
      final shelfRequest = shelf.Request(
        'GET',
        Uri.parse('http://localhost/test'),
        headers: {'cookie': 'session=abc123; theme=dark; lang=en'},
      );
      final request = HttpRequest(shelfRequest);

      expect(request.getCookie('session'), equals('abc123'));
      expect(request.getCookie('theme'), equals('dark'));
      expect(request.getCookie('lang'), equals('en'));
      expect(request.getCookie('nonexistent'), isNull);
    });

    test('should parse JSON body', () async {
      final jsonData = {'name': 'John', 'age': 30};
      final body = json.encode(jsonData);
      final shelfRequest = shelf.Request(
        'POST',
        Uri.parse('http://localhost/test'),
        headers: {'content-type': 'application/json'},
        body: body,
      );
      final request = HttpRequest(shelfRequest);

      final parsedBody = await request.parsedBody;
      expect(parsedBody, equals(jsonData));
    });

    test('should parse form data', () async {
      final formData = 'name=John&age=30&city=New%20York';
      final shelfRequest = shelf.Request(
        'POST',
        Uri.parse('http://localhost/test'),
        headers: {'content-type': 'application/x-www-form-urlencoded'},
        body: formData,
      );
      final request = HttpRequest(shelfRequest);

      final parsedBody = await request.parsedBody;
      expect(parsedBody['name'], equals('John'));
      expect(parsedBody['age'], equals('30'));
      expect(parsedBody['city'], equals('New York'));
    });

    test('should handle empty body', () async {
      final shelfRequest = shelf.Request(
        'POST',
        Uri.parse('http://localhost/test'),
        body: '',
      );
      final request = HttpRequest(shelfRequest);

      final parsedBody = await request.parsedBody;
      expect(parsedBody, isEmpty);
    });

    test('should handle raw body', () async {
      const rawData = 'This is raw text data';
      final shelfRequest = shelf.Request(
        'POST',
        Uri.parse('http://localhost/test'),
        headers: {'content-type': 'text/plain'},
        body: rawData,
      );
      final request = HttpRequest(shelfRequest);

      final parsedBody = await request.parsedBody;
      expect(parsedBody['_raw'], equals(rawData));
    });

    test('should throw exception for invalid JSON', () async {
      const invalidJson = '{"name": "John", "age":}';
      final shelfRequest = shelf.Request(
        'POST',
        Uri.parse('http://localhost/test'),
        headers: {'content-type': 'application/json'},
        body: invalidJson,
      );
      final request = HttpRequest(shelfRequest);

      expect(() => request.parsedBody, throwsA(isA<BadRequestException>()));
    });

    test('should support copyWith', () {
      final shelfRequest =
          shelf.Request('GET', Uri.parse('http://localhost/test'));
      final request = HttpRequest(shelfRequest);

      final copy = request.copyWith(
        method: 'POST',
        uri: Uri.parse('http://localhost/other'),
        headers: {'content-type': 'application/json'},
        meta: {'custom': 'value'},
      );

      expect(copy.method, equals('POST'));
      expect(copy.path, equals('/other'));
      expect(copy.getHeader('content-type'), equals('application/json'));
      expect(copy.meta['custom'], equals('value'));
    });

    test('should provide request information as map', () {
      final shelfRequest = shelf.Request(
        'GET',
        Uri.parse('http://localhost:8000/test?param=value'),
        headers: {
          'content-type': 'application/json',
          'user-agent': 'Test Agent',
        },
      );
      final request = HttpRequest(shelfRequest);

      final requestMap = request.toMap();
      expect(requestMap['method'], equals('GET'));
      expect(requestMap['path'], equals('/test'));
      expect(requestMap['query_string'], equals('param=value'));
      expect(requestMap['is_secure'], isFalse);
      expect(requestMap['content_type'], equals('application/json'));
      expect(requestMap['user_agent'], equals('Test Agent'));
    });

    test('should provide string representation', () {
      final shelfRequest =
          shelf.Request('GET', Uri.parse('http://localhost/test'));
      final request = HttpRequest(shelfRequest);

      expect(request.toString(), equals('GET /test'));
    });

    test('should handle HTTP methods correctly', () {
      final methods = [
        'GET',
        'POST',
        'PUT',
        'DELETE',
        'PATCH',
        'HEAD',
        'OPTIONS',
        'TRACE'
      ];

      for (final method in methods) {
        final shelfRequest =
            shelf.Request(method, Uri.parse('http://localhost/test'));
        final request = HttpRequest(shelfRequest);

        expect(request.method, equals(method));
        expect(request.isGet, equals(method == 'GET'));
        expect(request.isPost, equals(method == 'POST'));
        expect(request.isPut, equals(method == 'PUT'));
        expect(request.isDelete, equals(method == 'DELETE'));
        expect(request.isPatch, equals(method == 'PATCH'));
        expect(request.isHead, equals(method == 'HEAD'));
        expect(request.isOptions, equals(method == 'OPTIONS'));
        expect(request.isTrace, equals(method == 'TRACE'));
      }
    });
  });

  group('HttpFile', () {
    test('should create HttpFile with correct properties', () {
      final content = utf8.encode('test content');
      final file = HttpFile(
        name: 'test.txt',
        contentType: 'text/plain',
        content: content,
      );

      expect(file.name, equals('test.txt'));
      expect(file.contentType, equals('text/plain'));
      expect(file.content, equals(content));
      expect(file.size, equals(content.length));
      expect(file.extension, equals('txt'));
      expect(file.contentAsString, equals('test content'));
    });

    test('should provide string representation', () {
      final content = utf8.encode('test content');
      final file = HttpFile(
        name: 'test.txt',
        contentType: 'text/plain',
        content: content,
      );

      expect(file.toString(),
          equals('HttpFile(test.txt, text/plain, ${content.length}bytes)'));
    });
  });
}
