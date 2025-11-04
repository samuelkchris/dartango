import 'package:test/test.dart';
import 'package:shelf/shelf.dart' as shelf;

import '../../../lib/src/core/middleware/rate_limit.dart';
import '../../../lib/src/core/http/request.dart';
import '../../../lib/src/core/http/response.dart';
import '../../../lib/src/core/cache/cache.dart';

HttpRequest _createRequest(String method, String path, {Map<String, String>? headers}) {
  final uri = Uri.parse('http://localhost$path');
  final shelfHeaders = headers ?? {};
  final shelfRequest = shelf.Request(method, uri, headers: shelfHeaders);
  return HttpRequest(shelfRequest);
}

void main() {
  group('RateLimitInfo', () {
    test('should calculate remaining requests correctly', () {
      final info = RateLimitInfo(
        currentCount: 5,
        maxRequests: 10,
        resetTime: DateTime.now().add(const Duration(minutes: 1)),
        window: const Duration(minutes: 1),
      );

      expect(info.remaining, equals(5));
      expect(info.isLimitExceeded, isFalse);
    });

    test('should detect when limit is exceeded', () {
      final info = RateLimitInfo(
        currentCount: 10,
        maxRequests: 10,
        resetTime: DateTime.now().add(const Duration(minutes: 1)),
        window: const Duration(minutes: 1),
      );

      expect(info.remaining, equals(0));
      expect(info.isLimitExceeded, isTrue);
    });

    test('should calculate retry after seconds', () {
      final resetTime = DateTime.now().add(const Duration(seconds: 30));
      final info = RateLimitInfo(
        currentCount: 10,
        maxRequests: 10,
        resetTime: resetTime,
        window: const Duration(minutes: 1),
      );

      expect(info.retryAfterSeconds, greaterThan(0));
      expect(info.retryAfterSeconds, lessThanOrEqualTo(60));
    });
  });

  group('TokenBucketRateLimiter', () {
    late TokenBucketRateLimiter limiter;
    late RateLimitConfig config;

    setUp(() {
      limiter = TokenBucketRateLimiter();
      config = const RateLimitConfig(
        maxRequests: 10,
        window: Duration(seconds: 10),
        strategy: RateLimitStrategy.tokenBucket,
      );
    });

    tearDown(() async {
      await limiter.clear();
    });

    test('should allow requests under the limit', () async {
      final key = 'test:key';

      for (var i = 0; i < 10; i++) {
        final info = await limiter.checkLimit(key, config);
        expect(info.isLimitExceeded, isFalse);
        await limiter.recordRequest(key, config);
      }
    });

    test('should block requests over the limit', () async {
      final key = 'test:key';

      for (var i = 0; i < 10; i++) {
        await limiter.recordRequest(key, config);
      }

      final info = await limiter.checkLimit(key, config);
      expect(info.isLimitExceeded, isTrue);
    });

    test('should reset key correctly', () async {
      final key = 'test:key';

      for (var i = 0; i < 10; i++) {
        await limiter.recordRequest(key, config);
      }

      await limiter.reset(key);

      final info = await limiter.checkLimit(key, config);
      expect(info.isLimitExceeded, isFalse);
    });

    test('should track multiple keys independently', () async {
      final key1 = 'test:key1';
      final key2 = 'test:key2';

      for (var i = 0; i < 10; i++) {
        await limiter.recordRequest(key1, config);
      }

      final info1 = await limiter.checkLimit(key1, config);
      final info2 = await limiter.checkLimit(key2, config);

      expect(info1.isLimitExceeded, isTrue);
      expect(info2.isLimitExceeded, isFalse);
    });
  });

  group('SlidingWindowRateLimiter', () {
    late SlidingWindowRateLimiter limiter;
    late RateLimitConfig config;

    setUp(() {
      limiter = SlidingWindowRateLimiter();
      config = const RateLimitConfig(
        maxRequests: 5,
        window: Duration(seconds: 2),
        strategy: RateLimitStrategy.slidingWindow,
      );
    });

    tearDown(() async {
      await limiter.clear();
    });

    test('should allow requests under the limit', () async {
      final key = 'test:key';

      for (var i = 0; i < 5; i++) {
        final info = await limiter.checkLimit(key, config);
        expect(info.isLimitExceeded, isFalse);
        await limiter.recordRequest(key, config);
      }
    });

    test('should block requests over the limit', () async {
      final key = 'test:key';

      for (var i = 0; i < 5; i++) {
        await limiter.recordRequest(key, config);
      }

      final info = await limiter.checkLimit(key, config);
      expect(info.isLimitExceeded, isTrue);
    });

    test('should allow requests after window expires', () async {
      final key = 'test:key';

      for (var i = 0; i < 5; i++) {
        await limiter.recordRequest(key, config);
      }

      await Future.delayed(const Duration(seconds: 3));

      final info = await limiter.checkLimit(key, config);
      expect(info.isLimitExceeded, isFalse);
    });
  });

  group('FixedWindowRateLimiter', () {
    late FixedWindowRateLimiter limiter;
    late RateLimitConfig config;

    setUp(() {
      limiter = FixedWindowRateLimiter();
      config = const RateLimitConfig(
        maxRequests: 10,
        window: Duration(seconds: 5),
        strategy: RateLimitStrategy.fixedWindow,
      );
    });

    tearDown(() async {
      await limiter.clear();
    });

    test('should allow requests under the limit', () async {
      final key = 'test:key';

      for (var i = 0; i < 10; i++) {
        final info = await limiter.checkLimit(key, config);
        expect(info.isLimitExceeded, isFalse);
        await limiter.recordRequest(key, config);
      }
    });

    test('should block requests over the limit', () async {
      final key = 'test:key';

      for (var i = 0; i < 10; i++) {
        await limiter.recordRequest(key, config);
      }

      final info = await limiter.checkLimit(key, config);
      expect(info.isLimitExceeded, isTrue);
    });
  });

  group('RateLimitMiddleware', () {
    late RateLimitMiddleware middleware;
    late RateLimitConfig config;

    Future<HttpResponse> _handler(HttpRequest request) async {
      return HttpResponse.ok('Success');
    }

    setUp(() {
      config = const RateLimitConfig(
        maxRequests: 5,
        window: Duration(minutes: 1),
        strategy: RateLimitStrategy.slidingWindow,
      );
      middleware = RateLimitMiddleware(config: config);
    });

    test('should allow requests under the limit', () async {
      final request = _createRequest('GET', '/test');

      for (var i = 0; i < 5; i++) {
        final response = await middleware.processRequest(request);
        expect(response, isNull);
      }
    });

    test('should block requests over the limit', () async {
      final request = _createRequest('GET', '/test');

      for (var i = 0; i < 5; i++) {
        await middleware.processRequest(request);
      }

      final response = await middleware.processRequest(request);
      expect(response, isNotNull);
      expect(response!.statusCode, equals(429));
    });

    test('should include rate limit headers in response', () async {
      final request = _createRequest('GET', '/test');

      await middleware.processRequest(request);
      final response = await middleware.processResponse(request, HttpResponse.ok('Test'));

      expect(response.headers.containsKey('x-ratelimit-limit'), isTrue);
      expect(response.headers.containsKey('x-ratelimit-remaining'), isTrue);
      expect(response.headers.containsKey('x-ratelimit-reset'), isTrue);
    });

    test('should include retry-after header when limit exceeded', () async {
      final request = _createRequest('GET', '/test');

      for (var i = 0; i < 5; i++) {
        await middleware.processRequest(request);
      }

      final response = await middleware.processRequest(request);
      expect(response!.headers.containsKey('retry-after'), isTrue);
    });

    test('should use per-IP scope by default', () async {
      final request1 = _createRequest('GET', '/test', headers: {'x-forwarded-for': '192.168.1.1'});
      final request2 = _createRequest('GET', '/test', headers: {'x-forwarded-for': '192.168.1.2'});

      for (var i = 0; i < 5; i++) {
        await middleware.processRequest(request1);
      }

      final response1 = await middleware.processRequest(request1);
      final response2 = await middleware.processRequest(request2);

      expect(response1, isNotNull);
      expect(response1!.statusCode, equals(429));
      expect(response2, isNull);
    });

    test('should respect method filter', () async {
      final config = const RateLimitConfig(
        maxRequests: 5,
        window: Duration(minutes: 1),
        methods: ['POST'],
      );
      final middleware = RateLimitMiddleware(config: config);

      final getRequest = _createRequest('GET', '/test');
      final postRequest = _createRequest('POST', '/test');

      for (var i = 0; i < 10; i++) {
        final response = await middleware.processRequest(getRequest);
        expect(response, isNull);
      }

      for (var i = 0; i < 5; i++) {
        await middleware.processRequest(postRequest);
      }

      final response = await middleware.processRequest(postRequest);
      expect(response, isNotNull);
      expect(response!.statusCode, equals(429));
    });

    test('should respect path filter', () async {
      final config = const RateLimitConfig(
        maxRequests: 5,
        window: Duration(minutes: 1),
        paths: [r'^/api/.*'],
      );
      final middleware = RateLimitMiddleware(config: config);

      final apiRequest = _createRequest('GET', '/api/users');
      final otherRequest = _createRequest('GET', '/static/file.css');

      for (var i = 0; i < 10; i++) {
        final response = await middleware.processRequest(otherRequest);
        expect(response, isNull);
      }

      for (var i = 0; i < 5; i++) {
        await middleware.processRequest(apiRequest);
      }

      final response = await middleware.processRequest(apiRequest);
      expect(response, isNotNull);
      expect(response!.statusCode, equals(429));
    });

    test('should respect exclude paths', () async {
      final config = const RateLimitConfig(
        maxRequests: 5,
        window: Duration(minutes: 1),
        excludePaths: [r'^/health$', r'^/status$'],
      );
      final middleware = RateLimitMiddleware(config: config);

      final healthRequest = _createRequest('GET', '/health');
      final apiRequest = _createRequest('GET', '/api/users');

      for (var i = 0; i < 10; i++) {
        final response = await middleware.processRequest(healthRequest);
        expect(response, isNull);
      }

      for (var i = 0; i < 5; i++) {
        await middleware.processRequest(apiRequest);
      }

      final response = await middleware.processRequest(apiRequest);
      expect(response, isNotNull);
      expect(response!.statusCode, equals(429));
    });

    test('should use custom key extractor', () async {
      final config = RateLimitConfig(
        maxRequests: 5,
        window: const Duration(minutes: 1),
        scope: RateLimitScope.custom,
        keyExtractor: (request) => 'custom:key',
      );
      final middleware = RateLimitMiddleware(config: config);

      final request1 = _createRequest('GET', '/test');
      final request2 = _createRequest('GET', '/other');

      for (var i = 0; i < 5; i++) {
        await middleware.processRequest(request1);
      }

      final response = await middleware.processRequest(request2);
      expect(response, isNotNull);
      expect(response!.statusCode, equals(429));
    });

    test('should use custom error builder', () async {
      final config = RateLimitConfig(
        maxRequests: 5,
        window: const Duration(minutes: 1),
        errorBuilder: (request, info) {
          return HttpResponse.forbidden('Custom error message');
        },
      );
      final middleware = RateLimitMiddleware(config: config);

      final request = _createRequest('GET', '/test');

      for (var i = 0; i < 5; i++) {
        await middleware.processRequest(request);
      }

      final response = await middleware.processRequest(request);
      expect(response, isNotNull);
      expect(response!.statusCode, equals(403));
    });

    test('should not include headers when disabled', () async {
      final config = const RateLimitConfig(
        maxRequests: 5,
        window: Duration(minutes: 1),
        includeHeaders: false,
      );
      final middleware = RateLimitMiddleware(config: config);

      final request = _createRequest('GET', '/test');

      await middleware.processRequest(request);
      final response = await middleware.processResponse(request, HttpResponse.ok('Test'));

      expect(response.headers.containsKey('x-ratelimit-limit'), isFalse);
      expect(response.headers.containsKey('x-ratelimit-remaining'), isFalse);
      expect(response.headers.containsKey('x-ratelimit-reset'), isFalse);
    });
  });

  group('RateLimitPresets', () {
    test('should create strict preset', () {
      final config = RateLimitPresets.strict();
      expect(config.maxRequests, equals(10));
      expect(config.window, equals(const Duration(minutes: 1)));
      expect(config.strategy, equals(RateLimitStrategy.slidingWindow));
    });

    test('should create moderate preset', () {
      final config = RateLimitPresets.moderate();
      expect(config.maxRequests, equals(100));
      expect(config.window, equals(const Duration(minutes: 1)));
    });

    test('should create relaxed preset', () {
      final config = RateLimitPresets.relaxed();
      expect(config.maxRequests, equals(1000));
      expect(config.window, equals(const Duration(minutes: 1)));
      expect(config.strategy, equals(RateLimitStrategy.tokenBucket));
    });

    test('should create API preset', () {
      final config = RateLimitPresets.api();
      expect(config.maxRequests, equals(1000));
      expect(config.window, equals(const Duration(hours: 1)));
      expect(config.scope, equals(RateLimitScope.perUser));
    });

    test('should create authentication preset', () {
      final config = RateLimitPresets.authentication();
      expect(config.maxRequests, equals(5));
      expect(config.window, equals(const Duration(minutes: 15)));
      expect(config.strategy, equals(RateLimitStrategy.fixedWindow));
      expect(config.scope, equals(RateLimitScope.perIp));
    });

    test('should create custom preset', () {
      final config = RateLimitPresets.custom(
        maxRequests: 50,
        window: const Duration(minutes: 5),
        strategy: RateLimitStrategy.tokenBucket,
        scope: RateLimitScope.perEndpoint,
      );

      expect(config.maxRequests, equals(50));
      expect(config.window, equals(const Duration(minutes: 5)));
      expect(config.strategy, equals(RateLimitStrategy.tokenBucket));
      expect(config.scope, equals(RateLimitScope.perEndpoint));
    });
  });

  group('Rate Limit Strategies', () {
    test('should use correct strategy from config', () {
      final tokenBucketConfig = const RateLimitConfig(
        maxRequests: 10,
        window: Duration(minutes: 1),
        strategy: RateLimitStrategy.tokenBucket,
      );

      final slidingWindowConfig = const RateLimitConfig(
        maxRequests: 10,
        window: Duration(minutes: 1),
        strategy: RateLimitStrategy.slidingWindow,
      );

      final fixedWindowConfig = const RateLimitConfig(
        maxRequests: 10,
        window: Duration(minutes: 1),
        strategy: RateLimitStrategy.fixedWindow,
      );

      final middleware1 = RateLimitMiddleware(config: tokenBucketConfig);
      final middleware2 = RateLimitMiddleware(config: slidingWindowConfig);
      final middleware3 = RateLimitMiddleware(config: fixedWindowConfig);

      expect(middleware1.limiter, isA<TokenBucketRateLimiter>());
      expect(middleware2.limiter, isA<SlidingWindowRateLimiter>());
      expect(middleware3.limiter, isA<FixedWindowRateLimiter>());
    });
  });

  group('Rate Limit Scopes', () {
    test('should use per-IP scope', () async {
      final config = const RateLimitConfig(
        maxRequests: 5,
        window: Duration(minutes: 1),
        scope: RateLimitScope.perIp,
      );
      final middleware = RateLimitMiddleware(config: config);

      final request = _createRequest('GET', '/test', headers: {'x-forwarded-for': '192.168.1.1'});

      for (var i = 0; i < 5; i++) {
        await middleware.processRequest(request);
      }

      final response = await middleware.processRequest(request);
      expect(response, isNotNull);
      expect(response!.statusCode, equals(429));
    });

    test('should use per-endpoint scope', () async {
      final config = const RateLimitConfig(
        maxRequests: 5,
        window: Duration(minutes: 1),
        scope: RateLimitScope.perEndpoint,
      );
      final middleware = RateLimitMiddleware(config: config);

      final request1 = _createRequest('GET', '/api/users');
      final request2 = _createRequest('GET', '/api/posts');

      for (var i = 0; i < 5; i++) {
        await middleware.processRequest(request1);
      }

      final response1 = await middleware.processRequest(request1);
      final response2 = await middleware.processRequest(request2);

      expect(response1, isNotNull);
      expect(response1!.statusCode, equals(429));
      expect(response2, isNull);
    });

    test('should use global scope', () async {
      final config = const RateLimitConfig(
        maxRequests: 5,
        window: Duration(minutes: 1),
        scope: RateLimitScope.global,
      );
      final middleware = RateLimitMiddleware(config: config);

      final request1 = _createRequest('GET', '/api/users', headers: {'x-forwarded-for': '192.168.1.1'});
      final request2 = _createRequest('POST', '/api/posts', headers: {'x-forwarded-for': '192.168.1.2'});

      for (var i = 0; i < 3; i++) {
        await middleware.processRequest(request1);
      }

      for (var i = 0; i < 2; i++) {
        await middleware.processRequest(request2);
      }

      final response = await middleware.processRequest(request1);
      expect(response, isNotNull);
      expect(response!.statusCode, equals(429));
    });
  });
}
