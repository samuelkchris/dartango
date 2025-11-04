import 'package:test/test.dart';
import 'package:shelf/shelf.dart' as shelf;

import '../../lib/src/core/http/request.dart';
import '../../lib/src/core/http/response.dart';
import '../../lib/src/core/middleware/base.dart';
import '../../lib/src/core/views/base.dart';
import '../../lib/src/core/forms/forms.dart';
import '../../lib/src/core/forms/fields.dart';
import '../../lib/src/core/cache/cache.dart';
import '../../lib/src/core/sessions/session.dart';
import '../../lib/src/core/sessions/backends.dart';
import '../../lib/src/core/exceptions/http.dart';

class AuthenticationMiddleware extends BaseMiddleware {
  @override
  Future<HttpResponse?> processRequest(HttpRequest request) async {
    final authHeader = request.headers['authorization'];

    if (authHeader == null) {
      return null;
    }

    if (authHeader.startsWith('Bearer ')) {
      final token = authHeader.substring(7);
      request.middlewareState['user'] = {'id': token, 'authenticated': true};
    }

    return null;
  }

  @override
  Future<HttpResponse> processResponse(
    HttpRequest request,
    HttpResponse response,
  ) async {
    return response.setHeader('X-Processed-By', 'AuthMiddleware');
  }
}

class LoggingMiddleware extends BaseMiddleware {
  final List<String> logs = [];

  @override
  Future<HttpResponse?> processRequest(HttpRequest request) async {
    logs.add('Request: ${request.method} ${request.path}');
    return null;
  }

  @override
  Future<HttpResponse> processResponse(
    HttpRequest request,
    HttpResponse response,
  ) async {
    logs.add('Response: ${response.statusCode}');
    return response;
  }
}

class CachingMiddleware extends BaseMiddleware {
  final Cache cache;

  CachingMiddleware(this.cache);

  @override
  Future<HttpResponse?> processRequest(HttpRequest request) async {
    if (request.method != 'GET') {
      return null;
    }

    final cacheKey = 'response:${request.path}';
    final cached = await cache.get<Map<String, dynamic>>(cacheKey);

    if (cached != null) {
      return HttpResponse(
        cached['body'],
        statusCode: cached['statusCode'],
        headers: Map<String, String>.from(cached['headers']),
      ).setHeader('X-Cache', 'HIT');
    }

    return null;
  }

  @override
  Future<HttpResponse> processResponse(
    HttpRequest request,
    HttpResponse response,
  ) async {
    if (request.method == 'GET' && response.statusCode == 200) {
      final cacheKey = 'response:${request.path}';
      await cache.set(
        cacheKey,
        {
          'body': response.body,
          'statusCode': response.statusCode,
          'headers': response.headers,
        },
        timeout: const Duration(minutes: 5),
      );
    }

    return response.setHeader('X-Cache', 'MISS');
  }
}

class ProfileView extends View {
  @override
  Future<HttpResponse> get(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    final userId = kwargs['id'];
    final user = request.middlewareState['user'];

    if (user == null) {
      return HttpResponse.unauthorized('Authentication required');
    }

    return HttpResponse.json({
      'user_id': userId,
      'profile': {
        'name': 'User $userId',
        'email': 'user$userId@example.com',
      },
      'authenticated_as': user['id'],
    });
  }

  @override
  Future<HttpResponse> post(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    final userId = kwargs['id'];

    return HttpResponse.json({
      'message': 'Profile updated',
      'user_id': userId,
    });
  }
}

class ContactForm extends Form {
  final CharField name = CharField(
    name: 'name',
    label: 'Name',
    maxLength: 100,
  );

  final EmailField email = EmailField(
    name: 'email',
    label: 'Email',
  );

  final CharField message = CharField(
    name: 'message',
    label: 'Message',
    maxLength: 1000,
  );

  ContactForm({
    super.data,
    super.initial,
  });
}

class ContactView extends View {
  @override
  Future<HttpResponse> get(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    final form = ContactForm();

    return HttpResponse.json({
      'form': form.toJson(),
    });
  }

  @override
  Future<HttpResponse> post(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    final data = request.middlewareState['parsed_body'] as Map<String, dynamic>?;

    final form = ContactForm(data: data?.map((k, v) => MapEntry(k, v.toString())));

    if (await form.isValidAsync()) {
      return HttpResponse.json({
        'success': true,
        'message': 'Form submitted successfully',
        'data': form.cleanedData,
      });
    } else {
      return HttpResponse.json(
        {
          'success': false,
          'errors': form.errors,
        },
        statusCode: 400,
      );
    }
  }
}

HttpRequest _createRequest(
  String method,
  String path, {
  Map<String, String>? headers,
  String? body,
}) {
  final uri = Uri.parse('http://localhost$path');
  final shelfHeaders = headers ?? {};
  final shelfRequest = shelf.Request(
    method,
    uri,
    headers: shelfHeaders,
    body: body ?? '',
  );
  return HttpRequest(shelfRequest);
}

void main() {
  group('Request/Response Flow Integration', () {
    test('should process request through middleware chain', () async {
      final loggingMiddleware = LoggingMiddleware();
      final authMiddleware = AuthenticationMiddleware();

      final chain = MiddlewareChain([loggingMiddleware, authMiddleware]);

      final request = _createRequest(
        'GET',
        '/test',
        headers: {'authorization': 'Bearer user123'},
      );

      final response = await chain.process(
        request,
        (req) async => HttpResponse.ok('Handler response'),
      );

      expect(response.statusCode, equals(200));
      expect(response.headers['X-Processed-By'], equals('AuthMiddleware'));
      expect(loggingMiddleware.logs, hasLength(2));
      expect(loggingMiddleware.logs[0], contains('Request: GET /test'));
      expect(loggingMiddleware.logs[1], contains('Response: 200'));
      expect(request.middlewareState['user'], isNotNull);
    });

    test('should handle view with authentication', () async {
      final authMiddleware = AuthenticationMiddleware();
      final chain = MiddlewareChain([authMiddleware]);

      final request = _createRequest(
        'GET',
        '/profile/123',
        headers: {'authorization': 'Bearer user456'},
      );

      final view = ProfileView();

      final response = await chain.process(
        request,
        (req) => view.dispatch(req, {'id': '123'}),
      );

      expect(response.statusCode, equals(200));
      expect(response.headers['content-type'], contains('application/json'));

      final jsonBody = response.body;
      expect(jsonBody, contains('user_id'));
      expect(jsonBody, contains('authenticated_as'));
    });

    test('should reject unauthenticated request', () async {
      final authMiddleware = AuthenticationMiddleware();
      final chain = MiddlewareChain([authMiddleware]);

      final request = _createRequest('GET', '/profile/123');

      final view = ProfileView();

      final response = await chain.process(
        request,
        (req) => view.dispatch(req, {'id': '123'}),
      );

      expect(response.statusCode, equals(401));
      expect(response.body, contains('Authentication required'));
    });

    test('should cache GET responses', () async {
      final cache = InMemoryCache();
      final cachingMiddleware = CachingMiddleware(cache);
      final chain = MiddlewareChain([cachingMiddleware]);

      final request1 = _createRequest('GET', '/data');

      final response1 = await chain.process(
        request1,
        (req) async => HttpResponse.ok('Fresh data'),
      );

      expect(response1.headers['X-Cache'], equals('MISS'));
      expect(response1.body, equals('Fresh data'));

      final request2 = _createRequest('GET', '/data');

      final response2 = await chain.process(
        request2,
        (req) async => HttpResponse.ok('Should not be called'),
      );

      expect(response2.headers['X-Cache'], equals('HIT'));
      expect(response2.body, equals('Fresh data'));
    });

    test('should not cache POST requests', () async {
      final cache = InMemoryCache();
      final cachingMiddleware = CachingMiddleware(cache);
      final chain = MiddlewareChain([cachingMiddleware]);

      final request1 = _createRequest('POST', '/data', body: '{"test": true}');

      final response1 = await chain.process(
        request1,
        (req) async => HttpResponse.ok('Created'),
      );

      expect(response1.headers.containsKey('X-Cache'), isFalse);

      final request2 = _createRequest('POST', '/data', body: '{"test": true}');

      final response2 = await chain.process(
        request2,
        (req) async => HttpResponse.ok('Created again'),
      );

      expect(response2.body, equals('Created again'));
    });

    test('should handle form submission with validation', () async {
      final request = _createRequest('POST', '/contact');
      request.middlewareState['parsed_body'] = {
        'name': 'John Doe',
        'email': 'john@example.com',
        'message': 'Hello World',
      };

      final view = ContactView();
      final response = await view.dispatch(request);

      expect(response.statusCode, equals(200));
      expect(response.body, contains('success'));
      expect(response.body, contains('true'));
    });

    test('should reject invalid form submission', () async {
      final request = _createRequest('POST', '/contact');
      request.middlewareState['parsed_body'] = {
        'name': '',
        'email': 'invalid-email',
        'message': '',
      };

      final view = ContactView();
      final response = await view.dispatch(request);

      expect(response.statusCode, equals(400));
      expect(response.body, contains('success'));
      expect(response.body, contains('false'));
      expect(response.body, contains('errors'));
    });

    test('should handle multiple middleware with state passing', () async {
      final middleware1 = FunctionalMiddleware((request, getResponse) async {
        request.middlewareState['step1'] = 'completed';
        return null;
      });

      final middleware2 = FunctionalMiddleware((request, getResponse) async {
        request.middlewareState['step2'] = 'completed';
        expect(request.middlewareState['step1'], equals('completed'));
        return null;
      });

      final chain = MiddlewareChain([middleware1, middleware2]);

      final request = _createRequest('GET', '/test');

      await chain.process(
        request,
        (req) async {
          expect(req.middlewareState['step1'], equals('completed'));
          expect(req.middlewareState['step2'], equals('completed'));
          return HttpResponse.ok('Success');
        },
      );
    });

    test('should handle error in middleware chain', () async {
      final errorMiddleware = FunctionalMiddleware((request, getResponse) async {
        return null;
      });

      final errorHandlingMiddleware = FunctionalMiddleware((request, getResponse) async {
        return null;
      });

      final chain = MiddlewareChain([errorMiddleware, errorHandlingMiddleware]);

      final request = _createRequest('GET', '/test');

      final response = await chain.process(
        request,
        (req) async => throw Exception('Handler error'),
      );

      expect(response, isNotNull);
    });

    test('should handle view method not allowed', () async {
      final view = ProfileView();
      final request = _createRequest('DELETE', '/profile/123');

      expect(
        () => view.dispatch(request, {'id': '123'}),
        throwsA(isA<MethodNotAllowedException>()),
      );
    });

    test('should support OPTIONS request', () async {
      final view = ProfileView();
      final request = _createRequest('OPTIONS', '/profile/123');

      final response = await view.dispatch(request, {'id': '123'});

      expect(response.statusCode, equals(200));
      expect(response.headers['Allow'], isNotNull);
      expect(response.headers['Allow'], contains('GET'));
      expect(response.headers['Allow'], contains('POST'));
    });

    test('should handle HEAD request', () async {
      final authMiddleware = AuthenticationMiddleware();
      final chain = MiddlewareChain([authMiddleware]);

      final request = _createRequest(
        'HEAD',
        '/profile/123',
        headers: {'authorization': 'Bearer user789'},
      );

      final view = ProfileView();

      final response = await chain.process(
        request,
        (req) => view.dispatch(req, {'id': '123'}),
      );

      expect(response.statusCode, equals(200));
      expect(response.body, isEmpty);
    });
  });

  group('Complex Integration Scenarios', () {
    test('should handle multi-layered middleware with caching and auth', () async {
      final cache = InMemoryCache();
      final authMiddleware = AuthenticationMiddleware();
      final cachingMiddleware = CachingMiddleware(cache);
      final loggingMiddleware = LoggingMiddleware();

      final chain = MiddlewareChain([
        loggingMiddleware,
        authMiddleware,
        cachingMiddleware,
      ]);

      final request1 = _createRequest(
        'GET',
        '/api/data',
        headers: {'authorization': 'Bearer user123'},
      );

      final response1 = await chain.process(
        request1,
        (req) async => HttpResponse.json({'data': 'value'}),
      );

      expect(response1.statusCode, equals(200));
      expect(response1.headers['X-Cache'], equals('MISS'));
      expect(response1.headers['X-Processed-By'], equals('AuthMiddleware'));

      final request2 = _createRequest(
        'GET',
        '/api/data',
        headers: {'authorization': 'Bearer user456'},
      );

      final response2 = await chain.process(
        request2,
        (req) async => HttpResponse.json({'data': 'should not be called'}),
      );

      expect(response2.statusCode, equals(200));
      expect(response2.headers['X-Cache'], equals('HIT'));

      expect(loggingMiddleware.logs, hasLength(4));
    });

    test('should handle form validation with middleware', () async {
      final loggingMiddleware = LoggingMiddleware();
      final chain = MiddlewareChain([loggingMiddleware]);

      final request = _createRequest('POST', '/contact');
      request.middlewareState['parsed_body'] = {
        'name': 'Jane Smith',
        'email': 'jane@example.com',
        'message': 'Test message',
      };

      final view = ContactView();

      final response = await chain.process(
        request,
        (req) => view.dispatch(req),
      );

      expect(response.statusCode, equals(200));
      expect(response.body, contains('success'));

      expect(loggingMiddleware.logs, hasLength(2));
      expect(loggingMiddleware.logs[0], contains('POST /contact'));
      expect(loggingMiddleware.logs[1], contains('200'));
    });

    test('should handle session with middleware', () async {
      final config = SessionConfiguration(
        engine: 'file',
        engineOptions: {'session_dir': '/tmp/sessions'},
      );

      final manager = SessionManager(config);
      final session = await manager.createSession('test-session-id');

      final request = _createRequest('GET', '/test');
      request.middlewareState['session'] = session;

      await session.set('user_id', '123');
      await session.set('visited', true);

      final value = await session.get<String>('user_id');
      expect(value, equals('123'));

      final visited = await session.get<bool>('visited');
      expect(visited, isTrue);
    });

    test('should handle concurrent requests', () async {
      final cache = InMemoryCache();
      final cachingMiddleware = CachingMiddleware(cache);
      final chain = MiddlewareChain([cachingMiddleware]);

      final futures = <Future<HttpResponse>>[];

      for (int i = 0; i < 10; i++) {
        final request = _createRequest('GET', '/data/$i');
        final future = chain.process(
          request,
          (req) async => HttpResponse.ok('Data $i'),
        );
        futures.add(future);
      }

      final responses = await Future.wait(futures);

      expect(responses, hasLength(10));
      expect(responses.every((r) => r.statusCode == 200), isTrue);
    });
  });

  group('Error Handling Integration', () {
    test('should handle middleware exception gracefully', () async {
      final failingMiddleware = FunctionalMiddleware((request, getResponse) async {
        throw Exception('Middleware failure');
      });

      final chain = MiddlewareChain([failingMiddleware]);

      final request = _createRequest('GET', '/test');

      expect(
        () => chain.process(request, (req) async => HttpResponse.ok('OK')),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle view exception', () async {
      final view = ProfileView();
      final request = _createRequest('GET', '/profile/invalid');

      expect(
        () => view.dispatch(request, {'id': 'invalid'}),
        completes,
      );
    });
  });
}
