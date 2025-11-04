import 'package:test/test.dart';
import 'package:shelf/shelf.dart' as shelf;

import '../../../lib/src/core/views/base.dart';
import '../../../lib/src/core/http/request.dart';
import '../../../lib/src/core/http/response.dart';
import '../../../lib/src/core/exceptions/http.dart';

class TestView extends View {
  final List<String> methodsCalled = [];

  @override
  Future<HttpResponse> get(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    methodsCalled.add('get');
    return HttpResponse.ok('GET response');
  }

  @override
  Future<HttpResponse> post(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    methodsCalled.add('post');
    return HttpResponse.ok('POST response');
  }

  @override
  Future<HttpResponse> put(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    methodsCalled.add('put');
    return HttpResponse.ok('PUT response');
  }

  @override
  Future<HttpResponse> patch(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    methodsCalled.add('patch');
    return HttpResponse.ok('PATCH response');
  }

  @override
  Future<HttpResponse> delete(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    methodsCalled.add('delete');
    return HttpResponse.ok('DELETE response');
  }
}

class GetOnlyView extends View {
  @override
  Future<HttpResponse> get(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    return HttpResponse.ok('GET only');
  }
}

class TestRedirectView extends RedirectView {
  TestRedirectView({
    super.url,
    super.patternName,
    super.permanent,
    super.queryStringParams,
  });
}

class TestLoginRequiredView extends View with LoginRequiredMixin {
  @override
  Future<HttpResponse> get(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    return HttpResponse.ok('Protected content');
  }
}

class TestPermissionRequiredView extends View with PermissionRequiredMixin {
  @override
  List<String> get requiredPermissions => ['can_edit', 'can_delete'];

  @override
  Future<HttpResponse> get(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    return HttpResponse.ok('Protected content');
  }
}

class TestUserPassesTestView extends View with UserPassesTestMixin {
  bool Function(HttpRequest)? testFunc;

  @override
  Future<bool> testFunction(HttpRequest request) async {
    if (testFunc != null) {
      return testFunc!(request);
    }
    return true;
  }

  @override
  Future<HttpResponse> get(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    return HttpResponse.ok('Content');
  }
}

class MockUser {
  final bool isAuthenticated;
  final Set<String> permissions;

  MockUser({this.isAuthenticated = true, this.permissions = const {}});

  Future<bool> hasPermission(String permission) async {
    return permissions.contains(permission);
  }
}

HttpRequest _createRequest(String method, String path,
    {Map<String, String>? headers, MockUser? user}) {
  final uri = Uri.parse('http://localhost$path');
  final shelfHeaders = headers ?? {};
  final shelfRequest = shelf.Request(method, uri, headers: shelfHeaders);
  final request = HttpRequest(shelfRequest);

  if (user != null) {
    request.middlewareState['user'] = user;
  }

  return request;
}

void main() {
  group('View Base Class', () {
    late TestView view;

    setUp(() {
      view = TestView();
    });

    test('should dispatch GET request', () async {
      final request = _createRequest('GET', '/test');
      final response = await view.dispatch(request);

      expect(view.methodsCalled, contains('get'));
      expect(response.statusCode, equals(200));
      expect(response.body, equals('GET response'));
    });

    test('should dispatch POST request', () async {
      final request = _createRequest('POST', '/test');
      final response = await view.dispatch(request);

      expect(view.methodsCalled, contains('post'));
      expect(response.body, equals('POST response'));
    });

    test('should dispatch PUT request', () async {
      final request = _createRequest('PUT', '/test');
      final response = await view.dispatch(request);

      expect(view.methodsCalled, contains('put'));
      expect(response.body, equals('PUT response'));
    });

    test('should dispatch PATCH request', () async {
      final request = _createRequest('PATCH', '/test');
      final response = await view.dispatch(request);

      expect(view.methodsCalled, contains('patch'));
      expect(response.body, equals('PATCH response'));
    });

    test('should dispatch DELETE request', () async {
      final request = _createRequest('DELETE', '/test');
      final response = await view.dispatch(request);

      expect(view.methodsCalled, contains('delete'));
      expect(response.body, equals('DELETE response'));
    });

    test('should handle HEAD request', () async {
      final request = _createRequest('HEAD', '/test');
      final response = await view.dispatch(request);

      expect(response.statusCode, equals(200));
      expect(response.body, equals(''));
    });

    test('should handle OPTIONS request', () async {
      final request = _createRequest('OPTIONS', '/test');
      final response = await view.dispatch(request);

      expect(response.headers['Allow'], isNotNull);
      expect(response.headers['Allow'], contains('GET'));
      expect(response.headers['Allow'], contains('POST'));
      expect(response.headers['Content-Length'], equals('0'));
    });

    test('should handle TRACE request', () async {
      final request = _createRequest('TRACE', '/test');
      final response = await view.dispatch(request);

      expect(response.headers['Content-Type'], equals('message/http'));
      expect(response.body, isNotEmpty);
    });

    test('should throw MethodNotAllowedException for unsupported methods',
        () async {
      final view = GetOnlyView();
      final request = _createRequest('POST', '/test');

      expect(
        () => view.dispatch(request),
        throwsA(isA<MethodNotAllowedException>()),
      );
    });

    test('should return list of allowed methods', () {
      final allowedMethods = view.getAllowedMethods();

      expect(allowedMethods, contains('GET'));
      expect(allowedMethods, contains('POST'));
      expect(allowedMethods, contains('PUT'));
      expect(allowedMethods, contains('PATCH'));
      expect(allowedMethods, contains('DELETE'));
    });

    test('should handle kwargs in dispatch', () async {
      final request = _createRequest('GET', '/test');
      final kwargs = {'id': '123', 'slug': 'test-slug'};

      final response = await view.dispatch(request, kwargs);

      expect(response, isNotNull);
    });
  });

  group('RedirectView', () {
    test('should redirect to static URL', () async {
      final view = TestRedirectView(url: '/target');
      final request = _createRequest('GET', '/redirect');

      final response = await view.dispatch(request);

      expect(response.statusCode, equals(302));
      expect(response.headers['Location'], equals('/target'));
    });

    test('should create permanent redirect', () async {
      final view = TestRedirectView(url: '/target', permanent: true);
      final request = _createRequest('GET', '/redirect');

      final response = await view.dispatch(request);

      expect(response.statusCode, equals(301));
      expect(response.headers['Location'], equals('/target'));
    });

    test('should interpolate URL parameters', () async {
      final view = TestRedirectView(url: '/user/{id}/profile');
      final request = _createRequest('GET', '/redirect');
      final kwargs = {'id': '42'};

      final response = await view.dispatch(request, kwargs);

      expect(response.headers['Location'], equals('/user/42/profile'));
    });

    test('should add query string parameters', () async {
      final view = TestRedirectView(
        url: '/search',
        queryStringParams: {'q': 'test', 'page': '2'},
      );
      final request = _createRequest('GET', '/redirect');

      final response = await view.dispatch(request);

      final location = response.headers['Location']!;
      expect(location, contains('/search?'));
      expect(location, contains('q=test'));
      expect(location, contains('page=2'));
    });

    test('should append to existing query string', () async {
      final view = TestRedirectView(
        url: '/search?existing=value',
        queryStringParams: {'new': 'param'},
      );
      final request = _createRequest('GET', '/redirect');

      final response = await view.dispatch(request);

      final location = response.headers['Location']!;
      expect(location, contains('existing=value'));
      expect(location, contains('new=param'));
    });

    test('should throw GoneException when URL is null', () async {
      final view = TestRedirectView();
      final request = _createRequest('GET', '/redirect');

      expect(
        () => view.dispatch(request),
        throwsA(isA<GoneException>()),
      );
    });

    test('should handle all HTTP methods', () async {
      final view = TestRedirectView(url: '/target');

      for (final method in ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD']) {
        final request = _createRequest(method, '/redirect');
        final response = await view.dispatch(request);

        expect(response.statusCode, anyOf(301, 302));
        expect(response.headers['Location'], equals('/target'));
      }
    });
  });

  group('FunctionBasedView', () {
    test('should execute view function', () async {
      var called = false;
      final view = FunctionBasedView((request, [kwargs]) async {
        called = true;
        return HttpResponse.ok('Function response');
      });

      final request = _createRequest('GET', '/test');
      final response = await view.dispatch(request);

      expect(called, isTrue);
      expect(response.body, equals('Function response'));
    });

    test('should pass request and kwargs to function', () async {
      String? capturedPath;
      Map<String, dynamic>? capturedKwargs;

      final view = FunctionBasedView((request, [kwargs]) async {
        capturedPath = request.path;
        capturedKwargs = kwargs;
        return HttpResponse.ok('OK');
      });

      final request = _createRequest('GET', '/test');
      final kwargs = {'id': '123'};

      await view.dispatch(request, kwargs);

      expect(capturedPath, equals('/test'));
      expect(capturedKwargs, equals(kwargs));
    });

    test('should handle async operations', () async {
      final view = FunctionBasedView((request, [kwargs]) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return HttpResponse.ok('Delayed response');
      });

      final request = _createRequest('GET', '/test');
      final response = await view.dispatch(request);

      expect(response.body, equals('Delayed response'));
    });
  });

  group('LoginRequiredMixin', () {
    test('should allow access for authenticated user', () async {
      final view = TestLoginRequiredView();
      final user = MockUser(isAuthenticated: true);
      final request = _createRequest('GET', '/protected', user: user);

      final response = await view.dispatch(request);

      expect(response.statusCode, equals(200));
      expect(response.body, equals('Protected content'));
    });

    test('should redirect unauthenticated user to login', () async {
      final view = TestLoginRequiredView();
      final request = _createRequest('GET', '/protected');

      final response = await view.dispatch(request);

      expect(response.statusCode, equals(302));
      expect(response.headers['Location'], contains('/login/'));
      expect(response.headers['Location'], contains('next='));
    });

    test('should preserve next URL in redirect', () async {
      final view = TestLoginRequiredView();
      final request = _createRequest('GET', '/protected/page');

      final response = await view.dispatch(request);

      final location = response.headers['Location']!;
      expect(location, contains('/protected/page'));
    });

    test('should handle user with isAuthenticated false', () async {
      final view = TestLoginRequiredView();
      final user = MockUser(isAuthenticated: false);
      final request = _createRequest('GET', '/protected', user: user);

      final response = await view.dispatch(request);

      expect(response.statusCode, equals(302));
    });
  });

  group('PermissionRequiredMixin', () {
    test('should allow access for user with all permissions', () async {
      final view = TestPermissionRequiredView();
      final user = MockUser(
        isAuthenticated: true,
        permissions: {'can_edit', 'can_delete'},
      );
      final request = _createRequest('GET', '/admin', user: user);

      final response = await view.dispatch(request);

      expect(response.statusCode, equals(200));
      expect(response.body, equals('Protected content'));
    });

    test('should deny access for user without permissions', () async {
      final view = TestPermissionRequiredView();
      final user = MockUser(isAuthenticated: true, permissions: {});
      final request = _createRequest('GET', '/admin', user: user);

      final response = await view.dispatch(request);

      expect(response.statusCode, equals(302));
      expect(response.headers['Location'], contains('/login/'));
    });

    test('should deny access for user with partial permissions', () async {
      final view = TestPermissionRequiredView();
      final user = MockUser(
        isAuthenticated: true,
        permissions: {'can_edit'},
      );
      final request = _createRequest('GET', '/admin', user: user);

      final response = await view.dispatch(request);

      expect(response.statusCode, equals(302));
    });

    test('should deny access for unauthenticated user', () async {
      final view = TestPermissionRequiredView();
      final request = _createRequest('GET', '/admin');

      final response = await view.dispatch(request);

      expect(response.statusCode, equals(302));
    });
  });

  group('UserPassesTestMixin', () {
    test('should allow access when test passes', () async {
      final view = TestUserPassesTestView();
      view.testFunc = (request) => true;

      final request = _createRequest('GET', '/test');
      final response = await view.dispatch(request);

      expect(response.statusCode, equals(200));
      expect(response.body, equals('Content'));
    });

    test('should deny access when test fails', () async {
      final view = TestUserPassesTestView();
      view.testFunc = (request) => false;

      final request = _createRequest('GET', '/test');
      final response = await view.dispatch(request);

      expect(response.statusCode, equals(302));
      expect(response.headers['Location'], contains('/login/'));
    });

    test('should use custom test function', () async {
      final view = TestUserPassesTestView();
      HttpRequest? capturedRequest;
      view.testFunc = (request) {
        capturedRequest = request;
        return request.path == '/allowed';
      };

      final allowedRequest = _createRequest('GET', '/allowed');
      final allowedResponse = await view.dispatch(allowedRequest);
      expect(allowedResponse.statusCode, equals(200));
      expect(capturedRequest, equals(allowedRequest));

      final deniedRequest = _createRequest('GET', '/denied');
      final deniedResponse = await view.dispatch(deniedRequest);
      expect(deniedResponse.statusCode, equals(302));
    });

    test('should handle async test function', () async {
      final view = TestUserPassesTestView();
      view.testFunc = (request) => true;

      final request = _createRequest('GET', '/test');
      final response = await view.dispatch(request);

      expect(response, isNotNull);
    });
  });

  group('ViewException', () {
    test('should create exception with message', () {
      final exception = ViewException('Test error message');

      expect(exception.toString(), contains('Test error message'));
      expect(exception.toString(), contains('ViewException'));
    });

    test('should be throwable', () {
      expect(
        () => throw ViewException('Error'),
        throwsA(isA<ViewException>()),
      );
    });
  });

  group('View Method Handlers', () {
    test('should return proper HTTP method names', () {
      final view = TestView();

      expect(view.httpMethodNames, contains('get'));
      expect(view.httpMethodNames, contains('post'));
      expect(view.httpMethodNames, contains('put'));
      expect(view.httpMethodNames, contains('patch'));
      expect(view.httpMethodNames, contains('delete'));
      expect(view.httpMethodNames, contains('head'));
      expect(view.httpMethodNames, contains('options'));
      expect(view.httpMethodNames, contains('trace'));
    });

    test('should get correct handler for method', () {
      final view = TestView();

      expect(view.getHandler('get'), isNotNull);
      expect(view.getHandler('post'), isNotNull);
      expect(view.getHandler('put'), isNotNull);
      expect(view.getHandler('patch'), isNotNull);
      expect(view.getHandler('delete'), isNotNull);
    });

    test('should return null for unsupported method', () {
      final view = TestView();

      expect(view.getHandler('invalid'), isNull);
    });
  });

  group('Complex View Scenarios', () {
    test('should handle view with multiple mixins', () async {
      final view = _ComplexView();
      final user = MockUser(
        isAuthenticated: true,
        permissions: {'required_permission'},
      );
      final request = _createRequest('GET', '/complex', user: user);

      final response = await view.dispatch(request);

      expect(response.statusCode, equals(200));
    });

    test('should chain mixin checks correctly', () async {
      final view = _ComplexView();
      final user = MockUser(isAuthenticated: true, permissions: {});
      final request = _createRequest('GET', '/complex', user: user);

      final response = await view.dispatch(request);

      expect(response.statusCode, equals(302));
    });

    test('should handle errors during dispatch', () async {
      final view = _ErrorView();
      final request = _createRequest('GET', '/error');

      expect(
        () => view.dispatch(request),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('HttpRequest Extension', () {
    test('should get user from middleware state', () {
      final user = MockUser();
      final request = _createRequest('GET', '/test', user: user);

      expect(request.user, equals(user));
    });

    test('should return null when no user in state', () {
      final request = _createRequest('GET', '/test');

      expect(request.user, isNull);
    });
  });
}

class _ComplexView extends View
    with LoginRequiredMixin, PermissionRequiredMixin {
  @override
  List<String> get requiredPermissions => ['required_permission'];

  @override
  Future<HttpResponse> get(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    return HttpResponse.ok('Complex view content');
  }
}

class _ErrorView extends View {
  @override
  Future<HttpResponse> get(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    throw Exception('Intentional error');
  }
}
