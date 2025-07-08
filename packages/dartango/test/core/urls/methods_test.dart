import 'package:test/test.dart';
import 'package:dartango/src/core/urls/methods.dart';
import 'package:dartango/src/core/urls/resolver.dart';
import 'package:dartango/src/core/http/request.dart';
import 'package:dartango/src/core/http/response.dart';
import 'package:shelf/shelf.dart' as shelf;

void main() {
  group('MethodBasedView', () {
    test('should create view with GET method', () {
      final view = MethodBasedView(
        get: (request, kwargs) => HttpResponse.ok('GET response'),
      );
      
      expect(view.allowedMethods, contains('GET'));
      expect(view.allowedMethods.length, equals(1));
    });

    test('should create view with multiple methods', () {
      final view = MethodBasedView(
        get: (request, kwargs) => HttpResponse.ok('GET response'),
        post: (request, kwargs) => HttpResponse.ok('POST response'),
        put: (request, kwargs) => HttpResponse.ok('PUT response'),
      );
      
      expect(view.allowedMethods, containsAll(['GET', 'POST', 'PUT']));
      expect(view.allowedMethods.length, equals(3));
    });

    test('should dispatch to correct method', () async {
      final view = MethodBasedView(
        get: (request, kwargs) => HttpResponse.ok('GET response'),
        post: (request, kwargs) => HttpResponse.ok('POST response'),
      );
      
      final getRequest = HttpRequest(shelf.Request('GET', Uri.parse('http://example.com/')));
      final postRequest = HttpRequest(shelf.Request('POST', Uri.parse('http://example.com/')));
      
      final getResponse = await view.dispatch(getRequest, {});
      final postResponse = await view.dispatch(postRequest, {});
      
      expect(getResponse.body, equals('GET response'));
      expect(postResponse.body, equals('POST response'));
    });

    test('should throw HttpMethodNotAllowed for unsupported method', () {
      final view = MethodBasedView(
        get: (request, kwargs) => HttpResponse.ok('GET response'),
      );
      
      final deleteRequest = HttpRequest(shelf.Request('DELETE', Uri.parse('http://example.com/')));
      
      expect(
        () => view.dispatch(deleteRequest, {}),
        throwsA(isA<HttpMethodNotAllowed>()),
      );
    });

    test('should add method dynamically', () {
      final view = MethodBasedView(
        get: (request, kwargs) => HttpResponse.ok('GET response'),
      );
      
      expect(view.allowedMethods, equals(['GET']));
      
      view.addMethod('POST', (request, kwargs) => HttpResponse.ok('POST response'));
      
      expect(view.allowedMethods, containsAll(['GET', 'POST']));
    });

    test('should remove method dynamically', () {
      final view = MethodBasedView(
        get: (request, kwargs) => HttpResponse.ok('GET response'),
        post: (request, kwargs) => HttpResponse.ok('POST response'),
      );
      
      expect(view.allowedMethods, containsAll(['GET', 'POST']));
      
      view.removeMethod('POST');
      
      expect(view.allowedMethods, equals(['GET']));
      expect(view.allowedMethods, isNot(contains('POST')));
    });

    test('should throw when no methods provided', () {
      expect(
        () => MethodBasedView(),
        throwsArgumentError,
      );
    });
  });

  group('MethodRoute', () {
    test('should create route with method-based view', () {
      final view = MethodBasedView(
        get: (request, kwargs) => HttpResponse.ok('GET response'),
      );
      
      final route = MethodRoute(
        pattern: '/test/',
        view: view,
        name: 'test',
      );
      
      expect(route.pattern, equals('/test/'));
      expect(route.name, equals('test'));
      expect(route.allowedMethods, equals(['GET']));
    });

    test('should resolve path and dispatch to view', () {
      final view = MethodBasedView(
        get: (request, kwargs) => HttpResponse.ok('GET response'),
      );
      
      final route = MethodRoute(
        pattern: '/test/',
        view: view,
      );
      
      final match = route.resolve('/test/');
      expect(match, isNotNull);
      expect(match!.kwargs, isEmpty);
    });

    test('should resolve path with parameters', () {
      final view = MethodBasedView(
        get: (request, kwargs) => HttpResponse.ok('GET response'),
      );
      
      final route = MethodRoute(
        pattern: '/test/<int:id>/',
        view: view,
      );
      
      final match = route.resolve('/test/123/');
      expect(match, isNotNull);
      expect(match!.kwargs['id'], equals('123'));
    });

    test('should reverse URL', () {
      final view = MethodBasedView(
        get: (request, kwargs) => HttpResponse.ok('GET response'),
      );
      
      final route = MethodRoute(
        pattern: '/test/<int:id>/',
        view: view,
        name: 'test-detail',
      );
      
      final url = route.reverse('test-detail', kwargs: {'id': '123'});
      expect(url, equals('/test/123/'));
    });
  });

  group('HTTP Method Helpers', () {
    test('get helper should create Route with GET method', () {
      final route = get('/test/', (request, kwargs) => HttpResponse.ok('GET'));
      
      expect(route, isA<Route>());
      expect(route.allowedMethods, containsAll(['GET', 'HEAD']));
    });

    test('post helper should create Route with POST method', () {
      final route = post('/test/', (request, kwargs) => HttpResponse.ok('POST'));
      
      expect(route, isA<Route>());
      expect(route.allowedMethods, equals(['POST']));
    });

    test('put helper should create Route with PUT method', () {
      final route = put('/test/', (request, kwargs) => HttpResponse.ok('PUT'));
      
      expect(route, isA<Route>());
      expect(route.allowedMethods, equals(['PUT']));
    });

    test('patch helper should create Route with PATCH method', () {
      final route = patch('/test/', (request, kwargs) => HttpResponse.ok('PATCH'));
      
      expect(route, isA<Route>());
      expect(route.allowedMethods, equals(['PATCH']));
    });

    test('delete helper should create Route with DELETE method', () {
      final route = delete('/test/', (request, kwargs) => HttpResponse.ok('DELETE'));
      
      expect(route, isA<Route>());
      expect(route.allowedMethods, equals(['DELETE']));
    });

    test('head helper should create Route with HEAD method', () {
      final route = head('/test/', (request, kwargs) => HttpResponse.ok('HEAD'));
      
      expect(route, isA<Route>());
      expect(route.allowedMethods, equals(['HEAD']));
    });

    test('options helper should create Route with OPTIONS method', () {
      final route = options('/test/', (request, kwargs) => HttpResponse.ok('OPTIONS'));
      
      expect(route, isA<Route>());
      expect(route.allowedMethods, equals(['OPTIONS']));
    });

    test('trace helper should create Route with TRACE method', () {
      final route = trace('/test/', (request, kwargs) => HttpResponse.ok('TRACE'));
      
      expect(route, isA<Route>());
      expect(route.allowedMethods, equals(['TRACE']));
    });
  });

  group('methodPath helper', () {
    test('should create MethodRoute', () {
      final view = MethodBasedView(
        get: (request, kwargs) => HttpResponse.ok('GET'),
      );
      
      final route = methodPath('/test/', view, name: 'test');
      
      expect(route, isA<MethodRoute>());
      expect(route.pattern, equals('/test/'));
      expect(route.name, equals('test'));
    });
  });

  group('HttpMethodNotAllowed', () {
    test('should create exception with message and allowed methods', () {
      final exception = HttpMethodNotAllowed(
        'Method not allowed',
        allowedMethods: ['GET', 'POST'],
      );
      
      expect(exception.message, equals('Method not allowed'));
      expect(exception.allowedMethods, equals(['GET', 'POST']));
      expect(exception.statusCode, equals(405));
    });

    test('should convert to HTTP response', () {
      final exception = HttpMethodNotAllowed(
        'Method not allowed',
        allowedMethods: ['GET', 'POST'],
      );
      
      final response = exception.toResponse();
      expect(response.statusCode, equals(405));
      expect(response.body, equals('Method not allowed'));
      expect(response.headers['Allow'], equals('GET, POST'));
    });
  });
}