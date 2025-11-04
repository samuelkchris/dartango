import 'package:test/test.dart';
import 'package:shelf/shelf.dart' as shelf;

import '../../../lib/src/core/middleware/base.dart';
import '../../../lib/src/core/http/request.dart';
import '../../../lib/src/core/http/response.dart';

class TestMiddleware extends BaseMiddleware {
  final String name;
  final bool shouldBlock;
  final List<String> calls = [];

  TestMiddleware({required this.name, this.shouldBlock = false});

  @override
  Future<HttpResponse?> processRequest(HttpRequest request) async {
    calls.add('processRequest');
    if (shouldBlock) {
      return HttpResponse.ok('blocked by $name');
    }
    return null;
  }

  @override
  Future<HttpResponse> processResponse(
    HttpRequest request,
    HttpResponse response,
  ) async {
    calls.add('processResponse');
    return response.setHeader('X-Processed-By', name);
  }

  @override
  Future<HttpResponse?> processView(
    HttpRequest request,
    Function viewFunc,
    List<dynamic> viewArgs,
    Map<String, dynamic> viewKwargs,
  ) async {
    calls.add('processView');
    return null;
  }

  @override
  Future<HttpResponse?> processException(
    HttpRequest request,
    Exception exception,
  ) async {
    calls.add('processException');
    if (name == 'error-handler') {
      return HttpResponse.internalServerError('handled by $name');
    }
    return null;
  }

  @override
  Future<HttpResponse> processTemplateResponse(
    HttpRequest request,
    HttpResponse response,
  ) async {
    calls.add('processTemplateResponse');
    return response.setHeader('X-Template-Processed', name);
  }
}

class AsyncTestMiddleware extends AsyncMiddleware {
  final String name;
  final List<String> calls = [];

  AsyncTestMiddleware({required this.name});

  @override
  Future<HttpResponse?> processRequest(HttpRequest request) async {
    calls.add('processRequest');
    await Future.delayed(const Duration(milliseconds: 10));
    return null;
  }

  @override
  Future<HttpResponse> processResponse(
    HttpRequest request,
    HttpResponse response,
  ) async {
    calls.add('processResponse');
    await Future.delayed(const Duration(milliseconds: 10));
    return response.setHeader('X-Async-$name', 'processed');
  }
}

HttpRequest _createRequest(String method, String path,
    {Map<String, String>? headers}) {
  final uri = Uri.parse('http://localhost$path');
  final shelfHeaders = headers ?? {};
  final shelfRequest = shelf.Request(method, uri, headers: shelfHeaders);
  return HttpRequest(shelfRequest);
}

void main() {
  group('BaseMiddleware', () {
    test('should have default implementations that return null or pass through',
        () async {
      final middleware = TestMiddleware(name: 'test');
      final request = _createRequest('GET', '/');

      final requestResponse = await middleware.processRequest(request);
      expect(requestResponse, isNull);

      final response = HttpResponse.ok('test');
      final processedResponse =
          await middleware.processResponse(request, response);
      expect(processedResponse, isNotNull);
    });

    test('should track method calls', () async {
      final middleware = TestMiddleware(name: 'test');
      final request = _createRequest('GET', '/');

      await middleware.processRequest(request);
      await middleware.processResponse(request, HttpResponse.ok(''));
      await middleware.processView(request, () {}, [], {});

      expect(middleware.calls, hasLength(3));
      expect(middleware.calls, contains('processRequest'));
      expect(middleware.calls, contains('processResponse'));
      expect(middleware.calls, contains('processView'));
    });
  });

  group('FunctionalMiddleware', () {
    test('should create middleware from function', () async {
      var called = false;
      final middleware = FunctionalMiddleware((request, getResponse) async {
        called = true;
        return HttpResponse.ok('from function');
      });

      final request = _createRequest('GET', '/');
      final response = await middleware.processRequest(request);

      expect(called, isTrue);
      expect(response, isNotNull);
      expect(response!.statusCode, equals(200));
    });

    test('should pass request to function', () async {
      String? capturedPath;
      final middleware = FunctionalMiddleware((request, getResponse) async {
        capturedPath = request.path;
        return null;
      });

      final request = _createRequest('GET', '/test/path');
      await middleware.processRequest(request);

      expect(capturedPath, equals('/test/path'));
    });
  });

  group('MiddlewareChain', () {
    test('should process request through all middlewares', () async {
      final middleware1 = TestMiddleware(name: 'first');
      final middleware2 = TestMiddleware(name: 'second');
      final middleware3 = TestMiddleware(name: 'third');

      final chain = MiddlewareChain([middleware1, middleware2, middleware3]);
      final request = _createRequest('GET', '/');

      await chain.process(request, (req) async => HttpResponse.ok('handler'));

      expect(middleware1.calls, contains('processRequest'));
      expect(middleware2.calls, contains('processRequest'));
      expect(middleware3.calls, contains('processRequest'));
    });

    test('should call processResponse in reverse order', () async {
      final middleware1 = TestMiddleware(name: 'first');
      final middleware2 = TestMiddleware(name: 'second');
      final chain = MiddlewareChain([middleware1, middleware2]);

      final request = _createRequest('GET', '/');
      final response =
          await chain.process(request, (req) async => HttpResponse.ok('test'));

      expect(middleware1.calls, contains('processResponse'));
      expect(middleware2.calls, contains('processResponse'));

      final processedBy = response.headers['X-Processed-By'];
      expect(processedBy, equals('first'));
    });

    test('should stop processing if middleware returns response', () async {
      final middleware1 = TestMiddleware(name: 'first');
      final middleware2 = TestMiddleware(name: 'blocker', shouldBlock: true);
      final middleware3 = TestMiddleware(name: 'third');

      final chain = MiddlewareChain([middleware1, middleware2, middleware3]);
      final request = _createRequest('GET', '/');

      final response = await chain.process(
          request, (req) async => HttpResponse.ok('should not reach'));

      expect(middleware1.calls, contains('processRequest'));
      expect(middleware2.calls, contains('processRequest'));
      expect(middleware3.calls, isEmpty);

      expect(response.body, contains('blocked by blocker'));
    });

    test('should handle exceptions through processException', () async {
      final errorHandler = TestMiddleware(name: 'error-handler');
      final chain = MiddlewareChain([errorHandler]);

      final request = _createRequest('GET', '/');
      final response = await chain.process(request, (req) async {
        throw Exception('test error');
      });

      expect(errorHandler.calls, contains('processException'));
      expect(response.statusCode, equals(500));
      expect(response.body, contains('handled by error-handler'));
    });

    test('should rethrow if no middleware handles exception', () async {
      final middleware = TestMiddleware(name: 'no-handler');
      final chain = MiddlewareChain([middleware]);

      final request = _createRequest('GET', '/');

      expect(
        () => chain.process(request, (req) async {
          throw Exception('unhandled error');
        }),
        throwsA(isA<Exception>()),
      );
    });

    test('should process view through middlewares', () async {
      final middleware1 = TestMiddleware(name: 'first');
      final middleware2 = TestMiddleware(name: 'second');
      final chain = MiddlewareChain([middleware1, middleware2]);

      final request = _createRequest('GET', '/');
      var viewExecuted = false;

      await chain.processView(
        request,
        () {},
        [],
        {},
        () async {
          viewExecuted = true;
          return HttpResponse.ok('view result');
        },
      );

      expect(middleware1.calls, contains('processView'));
      expect(middleware2.calls, contains('processView'));
      expect(viewExecuted, isTrue);
    });

    test('should handle template responses', () async {
      final middleware = TestMiddleware(name: 'template-processor');
      final chain = MiddlewareChain([middleware]);

      final request = _createRequest('GET', '/');
      final templateResponse = HttpResponse.ok('template')
          .setHeader('X-Template-Response', 'true');

      final response = await chain.process(
        request,
        (req) async => templateResponse,
      );

      expect(middleware.calls, contains('processTemplateResponse'));
      expect(response.headers['X-Template-Processed'], equals('template-processor'));
    });
  });

  group('AsyncMiddleware', () {
    test('should handle async processRequest', () async {
      final middleware = AsyncTestMiddleware(name: 'async');
      final request = _createRequest('GET', '/');

      final response = await middleware.processRequest(request);

      expect(middleware.calls, contains('processRequest'));
      expect(response, isNull);
    });

    test('should handle async processResponse', () async {
      final middleware = AsyncTestMiddleware(name: 'async');
      final request = _createRequest('GET', '/');

      final response = await middleware.processResponse(
        request,
        HttpResponse.ok('test'),
      );

      expect(middleware.calls, contains('processResponse'));
      expect(response.headers['X-Async-async'], equals('processed'));
    });

    test('should work in middleware chain', () async {
      final asyncMiddleware = AsyncTestMiddleware(name: 'async');
      final chain = MiddlewareChain([asyncMiddleware]);

      final request = _createRequest('GET', '/');
      final response =
          await chain.process(request, (req) async => HttpResponse.ok('test'));

      expect(asyncMiddleware.calls, hasLength(2));
      expect(response.headers.containsKey('X-Async-async'), isTrue);
    });
  });

  group('ConditionalMiddleware', () {
    test('should apply middleware when condition is true', () async {
      final innerMiddleware = TestMiddleware(name: 'inner', shouldBlock: true);
      final conditional = ConditionalMiddleware(
        middleware: innerMiddleware,
        condition: (request) => request.path == '/admin',
      );

      final request = _createRequest('GET', '/admin');
      final response = await conditional.processRequest(request);

      expect(response, isNotNull);
      expect(response!.body, contains('blocked by inner'));
    });

    test('should skip middleware when condition is false', () async {
      final innerMiddleware = TestMiddleware(name: 'inner', shouldBlock: true);
      final conditional = ConditionalMiddleware(
        middleware: innerMiddleware,
        condition: (request) => request.path == '/admin',
      );

      final request = _createRequest('GET', '/public');
      final response = await conditional.processRequest(request);

      expect(response, isNull);
      expect(innerMiddleware.calls, isEmpty);
    });

    test('should conditionally process response', () async {
      final innerMiddleware = TestMiddleware(name: 'inner');
      final conditional = ConditionalMiddleware(
        middleware: innerMiddleware,
        condition: (request) => request.path == '/api',
      );

      final request = _createRequest('GET', '/api');
      final response = await conditional.processResponse(
        request,
        HttpResponse.ok('test'),
      );

      expect(response.headers['X-Processed-By'], equals('inner'));
    });

    test('should skip processResponse when condition is false', () async {
      final innerMiddleware = TestMiddleware(name: 'inner');
      final conditional = ConditionalMiddleware(
        middleware: innerMiddleware,
        condition: (request) => request.path == '/api',
      );

      final request = _createRequest('GET', '/other');
      final originalResponse = HttpResponse.ok('test');
      final response = await conditional.processResponse(
        request,
        originalResponse,
      );

      expect(response.headers.containsKey('X-Processed-By'), isFalse);
    });

    test('should conditionally process view', () async {
      final innerMiddleware = TestMiddleware(name: 'inner');
      final conditional = ConditionalMiddleware(
        middleware: innerMiddleware,
        condition: (request) => request.method == 'POST',
      );

      final postRequest = _createRequest('POST', '/');
      await conditional.processView(postRequest, () {}, [], {});

      expect(innerMiddleware.calls, contains('processView'));

      innerMiddleware.calls.clear();

      final getRequest = _createRequest('GET', '/');
      await conditional.processView(getRequest, () {}, [], {});

      expect(innerMiddleware.calls, isEmpty);
    });

    test('should conditionally process exception', () async {
      final innerMiddleware = TestMiddleware(name: 'error-handler');
      final conditional = ConditionalMiddleware(
        middleware: innerMiddleware,
        condition: (request) => request.headers.containsKey('X-Handle-Errors'),
      );

      final request = _createRequest('GET', '/',
          headers: {'X-Handle-Errors': 'true'});
      final response = await conditional.processException(
        request,
        Exception('test error'),
      );

      expect(response, isNotNull);
      expect(innerMiddleware.calls, contains('processException'));
    });
  });

  group('MiddlewareStack', () {
    test('should add middlewares', () {
      final stack = MiddlewareStack();
      final middleware1 = TestMiddleware(name: 'first');
      final middleware2 = TestMiddleware(name: 'second');

      stack.add(middleware1);
      stack.add(middleware2);

      expect(stack.length, equals(2));
      expect(stack.isNotEmpty, isTrue);
    });

    test('should insert middleware at specific position', () {
      final stack = MiddlewareStack();
      final middleware1 = TestMiddleware(name: 'first');
      final middleware2 = TestMiddleware(name: 'second');
      final middleware3 = TestMiddleware(name: 'inserted');

      stack.add(middleware1);
      stack.add(middleware2);
      stack.insert(1, middleware3);

      expect(stack.length, equals(3));
      expect(stack.middlewares[1], equals(middleware3));
    });

    test('should remove middleware', () {
      final stack = MiddlewareStack();
      final middleware1 = TestMiddleware(name: 'first');
      final middleware2 = TestMiddleware(name: 'second');

      stack.add(middleware1);
      stack.add(middleware2);

      stack.remove(middleware1);

      expect(stack.length, equals(1));
      expect(stack.middlewares[0], equals(middleware2));
    });

    test('should clear all middlewares', () {
      final stack = MiddlewareStack();
      stack.add(TestMiddleware(name: 'first'));
      stack.add(TestMiddleware(name: 'second'));

      stack.clear();

      expect(stack.isEmpty, isTrue);
      expect(stack.length, equals(0));
    });

    test('should return unmodifiable list of middlewares', () {
      final stack = MiddlewareStack();
      stack.add(TestMiddleware(name: 'first'));

      final middlewares = stack.middlewares;

      expect(() => middlewares.add(TestMiddleware(name: 'second')),
          throwsUnsupportedError);
    });

    test('should convert to middleware chain', () {
      final stack = MiddlewareStack();
      final middleware1 = TestMiddleware(name: 'first');
      final middleware2 = TestMiddleware(name: 'second');

      stack.add(middleware1);
      stack.add(middleware2);

      final chain = stack.toChain();

      expect(chain, isA<MiddlewareChain>());
    });
  });

  group('MiddlewareMixin', () {
    test('should provide middleware list', () {
      final implementation = _TestMiddlewareMixin();

      expect(implementation.middleware, isNotNull);
      expect(implementation.middleware, isList);
    });

    test('should create middleware chain', () {
      final implementation = _TestMiddlewareMixin();

      final chain = implementation.createMiddlewareChain();

      expect(chain, isA<MiddlewareChain>());
    });
  });

  group('Middleware Exceptions', () {
    test('should create MiddlewareException', () {
      final exception = MiddlewareException('test error');

      expect(exception.toString(), contains('test error'));
    });

    test('should create MiddlewareNotCallable', () {
      final exception = MiddlewareNotCallable('TestMiddleware');

      expect(exception.toString(), contains('TestMiddleware'));
      expect(exception.toString(), contains('not callable'));
    });

    test('should create MiddlewareOrderingError', () {
      final exception = MiddlewareOrderingError('wrong order');

      expect(exception.toString(), contains('wrong order'));
    });
  });

  group('Complex Middleware Scenarios', () {
    test('should handle multiple blocking middlewares', () async {
      final middleware1 = TestMiddleware(name: 'first', shouldBlock: true);
      final middleware2 = TestMiddleware(name: 'second', shouldBlock: true);

      final chain = MiddlewareChain([middleware1, middleware2]);
      final request = _createRequest('GET', '/');

      final response =
          await chain.process(request, (req) async => HttpResponse.ok('handler'));

      expect(response.body, contains('blocked by first'));
      expect(middleware2.calls, isEmpty);
    });

    test('should handle mixed sync and async middlewares', () async {
      final syncMiddleware = TestMiddleware(name: 'sync');
      final asyncMiddleware = AsyncTestMiddleware(name: 'async');

      final chain = MiddlewareChain([syncMiddleware, asyncMiddleware]);
      final request = _createRequest('GET', '/');

      final response =
          await chain.process(request, (req) async => HttpResponse.ok('test'));

      expect(syncMiddleware.calls, isNotEmpty);
      expect(asyncMiddleware.calls, isNotEmpty);
      expect(response, isNotNull);
    });

    test('should handle nested conditional middlewares', () async {
      final innerMiddleware = TestMiddleware(name: 'inner', shouldBlock: true);

      final innerConditional = ConditionalMiddleware(
        middleware: innerMiddleware,
        condition: (request) => request.method == 'POST',
      );

      final outerConditional = ConditionalMiddleware(
        middleware: innerConditional,
        condition: (request) => request.path.startsWith('/api'),
      );

      final matchingRequest = _createRequest('POST', '/api/users');
      final response1 = await outerConditional.processRequest(matchingRequest);
      expect(response1, isNotNull);

      final nonMatchingRequest = _createRequest('GET', '/api/users');
      final response2 =
          await outerConditional.processRequest(nonMatchingRequest);
      expect(response2, isNull);
    });

    test('should maintain request state across middlewares', () async {
      final middleware1 = FunctionalMiddleware((request, getResponse) async {
        request.middlewareState['user'] = 'john';
        return null;
      });

      final middleware2 = FunctionalMiddleware((request, getResponse) async {
        final user = request.middlewareState['user'];
        expect(user, equals('john'));
        return null;
      });

      final chain = MiddlewareChain([middleware1, middleware2]);
      final request = _createRequest('GET', '/');

      await chain.process(request, (req) async {
        expect(req.middlewareState['user'], equals('john'));
        return HttpResponse.ok('ok');
      });
    });

    test('should handle exception in processResponse', () async {
      final faultyMiddleware = FunctionalMiddleware((request, getResponse) async {
        return null;
      });

      final chain = MiddlewareChain([faultyMiddleware]);
      final request = _createRequest('GET', '/');

      expect(
        () => chain.process(request, (req) async {
          throw Exception('handler error');
        }),
        throwsA(isA<Exception>()),
      );
    });
  });
}

class _TestMiddlewareMixin with MiddlewareMixin {
  @override
  List<BaseMiddleware> get middleware => [
        TestMiddleware(name: 'test1'),
        TestMiddleware(name: 'test2'),
      ];
}
