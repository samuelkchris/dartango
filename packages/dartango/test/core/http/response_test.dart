import 'dart:convert';
import 'package:test/test.dart';
import 'package:dartango/src/core/http/response.dart';

void main() {
  group('HttpResponse', () {
    test('should create basic response', () {
      final response = HttpResponse('Hello, World!');

      expect(response.statusCode, equals(200));
      expect(response.body, equals('Hello, World!'));
      expect(response.encoding, equals(utf8));
      expect(response.streaming, isFalse);
      expect(response.headers, isEmpty);
    });

    test('should create response with custom status and headers', () {
      final response = HttpResponse(
        'Not Found',
        statusCode: 404,
        headers: {'Content-Type': 'text/plain'},
      );

      expect(response.statusCode, equals(404));
      expect(response.body, equals('Not Found'));
      expect(response.headers['Content-Type'], equals('text/plain'));
    });

    test('should create OK response', () {
      final response = HttpResponse.ok('Success');

      expect(response.statusCode, equals(200));
      expect(response.body, equals('Success'));
    });

    test('should create created response', () {
      final response = HttpResponse.created('Resource created');

      expect(response.statusCode, equals(201));
      expect(response.body, equals('Resource created'));
    });

    test('should create no content response', () {
      final response = HttpResponse.noContent();

      expect(response.statusCode, equals(204));
      expect(response.body, isNull);
    });

    test('should create bad request response', () {
      final response = HttpResponse.badRequest('Invalid input');

      expect(response.statusCode, equals(400));
      expect(response.body, equals('Invalid input'));
    });

    test('should create unauthorized response', () {
      final response = HttpResponse.unauthorized('Access denied');

      expect(response.statusCode, equals(401));
      expect(response.body, equals('Access denied'));
    });

    test('should create forbidden response', () {
      final response = HttpResponse.forbidden('Forbidden');

      expect(response.statusCode, equals(403));
      expect(response.body, equals('Forbidden'));
    });

    test('should create not found response', () {
      final response = HttpResponse.notFound('Page not found');

      expect(response.statusCode, equals(404));
      expect(response.body, equals('Page not found'));
    });

    test('should create method not allowed response', () {
      final response = HttpResponse.methodNotAllowed(
        'Method not allowed',
        allowedMethods: ['GET', 'POST'],
      );

      expect(response.statusCode, equals(405));
      expect(response.body, equals('Method not allowed'));
      expect(response.headers['Allow'], equals('GET, POST'));
    });

    test('should create internal server error response', () {
      final response = HttpResponse.internalServerError('Server error');

      expect(response.statusCode, equals(500));
      expect(response.body, equals('Server error'));
    });

    test('should create JSON response', () {
      final data = {'name': 'John', 'age': 30};
      final response = HttpResponse.json(data);

      expect(response.statusCode, equals(200));
      expect(response.body, equals(json.encode(data)));
      expect(response.headers['Content-Type'],
          equals('application/json; charset=utf-8'));
    });

    test('should create JSON response with custom encoder', () {
      final data = {'name': 'John', 'age': 30};
      final response = HttpResponse.json(data, indent: true);

      expect(response.statusCode, equals(200));
      expect(response.body, equals(JsonEncoder.withIndent('  ').convert(data)));
      expect(response.headers['Content-Type'],
          equals('application/json; charset=utf-8'));
    });

    test('should create HTML response', () {
      final html = '<h1>Hello, World!</h1>';
      final response = HttpResponse.html(html);

      expect(response.statusCode, equals(200));
      expect(response.body, equals(html));
      expect(
          response.headers['Content-Type'], equals('text/html; charset=utf-8'));
    });

    test('should create text response', () {
      final text = 'Hello, World!';
      final response = HttpResponse.text(text);

      expect(response.statusCode, equals(200));
      expect(response.body, equals(text));
      expect(response.headers['Content-Type'],
          equals('text/plain; charset=utf-8'));
    });

    test('should create XML response', () {
      final xml = '<root><item>value</item></root>';
      final response = HttpResponse.xml(xml);

      expect(response.statusCode, equals(200));
      expect(response.body, equals(xml));
      expect(response.headers['Content-Type'],
          equals('application/xml; charset=utf-8'));
    });

    test('should create redirect response', () {
      final response = HttpResponse.redirect('/new-location');

      expect(response.statusCode, equals(302));
      expect(response.headers['Location'], equals('/new-location'));
    });

    test('should create permanent redirect response', () {
      final response = HttpResponse.permanentRedirect('/new-location');

      expect(response.statusCode, equals(301));
      expect(response.headers['Location'], equals('/new-location'));
    });

    test('should create custom redirect response', () {
      final response = HttpResponse.redirect('/new-location', statusCode: 303);

      expect(response.statusCode, equals(303));
      expect(response.headers['Location'], equals('/new-location'));
    });

    test('should set header', () {
      final response =
          HttpResponse('test').setHeader('X-Custom-Header', 'custom-value');

      expect(response.headers['X-Custom-Header'], equals('custom-value'));
    });

    test('should set multiple headers', () {
      final response = HttpResponse('test').setHeaders({
        'X-Custom-Header': 'custom-value',
        'X-Another-Header': 'another-value',
      });

      expect(response.headers['X-Custom-Header'], equals('custom-value'));
      expect(response.headers['X-Another-Header'], equals('another-value'));
    });

    test('should remove header', () {
      final response =
          HttpResponse('test', headers: {'X-Custom-Header': 'value'})
              .removeHeader('X-Custom-Header');

      expect(response.headers.containsKey('X-Custom-Header'), isFalse);
    });

    test('should set cookie', () {
      final response = HttpResponse('test')
          .setCookie('session', 'abc123', path: '/', httpOnly: true);

      expect(response.headers['Set-Cookie'], contains('session=abc123'));
      expect(response.headers['Set-Cookie'], contains('Path=/'));
      expect(response.headers['Set-Cookie'], contains('HttpOnly'));
    });

    test('should delete cookie', () {
      final response = HttpResponse('test').deleteCookie('session', path: '/');

      expect(response.headers['Set-Cookie'], contains('session='));
      expect(response.headers['Set-Cookie'], contains('Path=/'));
      expect(response.headers['Set-Cookie'], contains('Max-Age=0'));
    });

    test('should set cache headers', () {
      final response =
          HttpResponse('test').cache(maxAge: Duration(hours: 1), private: true);

      expect(response.headers['Cache-Control'], contains('max-age=3600'));
      expect(response.headers['Cache-Control'], contains('private'));
    });

    test('should set ETag header', () {
      final response = HttpResponse('test').etag('abc123');

      expect(response.headers['ETag'], equals('"abc123"'));
    });

    test('should set Last-Modified header', () {
      final dateTime = DateTime.utc(2023, 1, 1, 12, 0, 0);
      final response = HttpResponse('test').lastModified(dateTime);

      expect(response.headers['Last-Modified'], isNotNull);
    });

    test('should set Vary header', () {
      final response = HttpResponse('test').vary(['Accept', 'Accept-Language']);

      expect(response.headers['Vary'], equals('Accept, Accept-Language'));
    });

    test('should set CORS headers', () {
      final response = HttpResponse('test').cors(
        allowOrigins: ['https://example.com'],
        allowMethods: ['GET', 'POST'],
        allowCredentials: true,
      );

      expect(response.headers['Access-Control-Allow-Origin'],
          equals('https://example.com'));
      expect(response.headers['Access-Control-Allow-Methods'],
          equals('GET, POST'));
      expect(
          response.headers['Access-Control-Allow-Credentials'], equals('true'));
    });

    test('should convert to map', () {
      final response = HttpResponse('test', statusCode: 200);
      final map = response.toMap();

      expect(map['status_code'], equals(200));
      expect(map['body'], equals('test'));
      expect(map['encoding'], equals('utf-8'));
      expect(map['streaming'], isFalse);
    });

    test('should provide string representation', () {
      final response = HttpResponse('test', statusCode: 200);

      expect(response.toString(), equals('HttpResponse(200, 0 headers)'));
    });

    test('should convert to shelf response', () {
      final response = HttpResponse('test', statusCode: 200);
      final shelfResponse = response.toShelfResponse();

      expect(shelfResponse.statusCode, equals(200));
    });
  });

  group('JsonResponse', () {
    test('should create JSON response', () {
      final data = {'name': 'John', 'age': 30};
      final response = JsonResponse(data);

      expect(response.statusCode, equals(200));
      expect(response.body, equals(json.encode(data)));
      expect(response.headers['Content-Type'],
          equals('application/json; charset=utf-8'));
    });

    test('should create JSON response with custom status', () {
      final data = {'error': 'Not found'};
      final response = JsonResponse(data, statusCode: 404);

      expect(response.statusCode, equals(404));
      expect(response.body, equals(json.encode(data)));
    });
  });

  group('TemplateResponse', () {
    test('should create template response', () {
      final context = {'name': 'John', 'age': 30};
      final response = TemplateResponse('user.html', context);

      expect(response.statusCode, equals(200));
      expect(response.templateName, equals('user.html'));
      expect(response.context, equals(context));
      expect(
          response.headers['Content-Type'], equals('text/html; charset=utf-8'));
    });

    test('should create template response with custom status', () {
      final context = {'error': 'Not found'};
      final response = TemplateResponse('error.html', context, statusCode: 404);

      expect(response.statusCode, equals(404));
      expect(response.templateName, equals('error.html'));
      expect(response.context, equals(context));
    });

    test('should provide string representation', () {
      final context = {'name': 'John'};
      final response = TemplateResponse('user.html', context);

      expect(response.toString(), equals('TemplateResponse(user.html, 200)'));
    });
  });

  group('StreamingHttpResponse', () {
    test('should create streaming response', () {
      final response = StreamingHttpResponse();

      expect(response.statusCode, equals(200));
      expect(response.streaming, isTrue);
      expect(response.headers['Content-Type'], equals('text/plain'));
    });

    test('should write data to stream', () {
      final response = StreamingHttpResponse();

      response.write('Hello, ');
      response.write('World!');

      expect(response.statusCode, equals(200));
    });

    test('should write bytes to stream', () {
      final response = StreamingHttpResponse();

      response.writeBytes(utf8.encode('Hello, World!'));

      expect(response.statusCode, equals(200));
    });
  });
}
