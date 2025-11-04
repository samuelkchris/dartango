import 'dart:async';
import 'dart:collection';

import '../http/request.dart';
import '../http/response.dart';
import '../cache/cache.dart';
import 'base.dart';

/// Rate limiting strategy
enum RateLimitStrategy {
  /// Token bucket algorithm - allows bursts
  tokenBucket,

  /// Sliding window algorithm - more precise
  slidingWindow,

  /// Fixed window algorithm - simple and fast
  fixedWindow,
}

/// Rate limit scope
enum RateLimitScope {
  /// Per IP address
  perIp,

  /// Per authenticated user
  perUser,

  /// Per endpoint
  perEndpoint,

  /// Global rate limit
  global,

  /// Custom key extraction
  custom,
}

/// Rate limit configuration
class RateLimitConfig {
  /// Maximum number of requests allowed
  final int maxRequests;

  /// Time window for the rate limit
  final Duration window;

  /// Strategy to use for rate limiting
  final RateLimitStrategy strategy;

  /// Scope of the rate limit
  final RateLimitScope scope;

  /// Custom key extractor function
  final String Function(HttpRequest request)? keyExtractor;

  /// HTTP methods to apply rate limiting (null means all methods)
  final List<String>? methods;

  /// Paths to apply rate limiting (regex patterns)
  final List<String>? paths;

  /// Paths to exclude from rate limiting (regex patterns)
  final List<String>? excludePaths;

  /// Custom error message
  final String? errorMessage;

  /// Custom error response builder
  final HttpResponse Function(HttpRequest request, RateLimitInfo info)?
      errorBuilder;

  /// Whether to include rate limit headers in response
  final bool includeHeaders;

  const RateLimitConfig({
    required this.maxRequests,
    required this.window,
    this.strategy = RateLimitStrategy.slidingWindow,
    this.scope = RateLimitScope.perIp,
    this.keyExtractor,
    this.methods,
    this.paths,
    this.excludePaths,
    this.errorMessage,
    this.errorBuilder,
    this.includeHeaders = true,
  });
}

/// Rate limit information
class RateLimitInfo {
  /// Current request count
  final int currentCount;

  /// Maximum allowed requests
  final int maxRequests;

  /// Remaining requests
  final int remaining;

  /// Time when the rate limit resets
  final DateTime resetTime;

  /// Time window duration
  final Duration window;

  RateLimitInfo({
    required this.currentCount,
    required this.maxRequests,
    required this.resetTime,
    required this.window,
  }) : remaining = maxRequests - currentCount;

  bool get isLimitExceeded => currentCount >= maxRequests;

  int get retryAfterSeconds =>
      resetTime.difference(DateTime.now()).inSeconds.clamp(0, window.inSeconds);
}

/// Rate limiter interface
abstract class RateLimiter {
  Future<RateLimitInfo> checkLimit(String key, RateLimitConfig config);
  Future<void> recordRequest(String key, RateLimitConfig config);
  Future<void> reset(String key);
  Future<void> clear();
}

/// In-memory rate limiter using token bucket algorithm
class TokenBucketRateLimiter implements RateLimiter {
  final Cache cache;
  final Map<String, _TokenBucket> _buckets = {};

  TokenBucketRateLimiter({Cache? cache}) : cache = cache ?? InMemoryCache();

  @override
  Future<RateLimitInfo> checkLimit(String key, RateLimitConfig config) async {
    final bucket = _getBucket(key, config);
    final now = DateTime.now();

    bucket.refill(now);

    final resetTime = DateTime.fromMillisecondsSinceEpoch(
      bucket.lastRefill.millisecondsSinceEpoch + config.window.inMilliseconds,
    );

    return RateLimitInfo(
      currentCount: config.maxRequests - bucket.tokens,
      maxRequests: config.maxRequests,
      resetTime: resetTime,
      window: config.window,
    );
  }

  @override
  Future<void> recordRequest(String key, RateLimitConfig config) async {
    final bucket = _getBucket(key, config);
    bucket.consume();
  }

  @override
  Future<void> reset(String key) async {
    _buckets.remove(key);
    await cache.delete(key);
  }

  @override
  Future<void> clear() async {
    _buckets.clear();
    await cache.clear();
  }

  _TokenBucket _getBucket(String key, RateLimitConfig config) {
    return _buckets.putIfAbsent(
      key,
      () => _TokenBucket(
        capacity: config.maxRequests,
        refillRate: config.maxRequests / config.window.inSeconds,
      ),
    );
  }
}

/// Token bucket implementation
class _TokenBucket {
  final int capacity;
  final double refillRate;
  int tokens;
  DateTime lastRefill;

  _TokenBucket({
    required this.capacity,
    required this.refillRate,
  })  : tokens = capacity,
        lastRefill = DateTime.now();

  void refill(DateTime now) {
    final elapsed = now.difference(lastRefill).inSeconds;
    if (elapsed > 0) {
      final tokensToAdd = (elapsed * refillRate).floor();
      tokens = (tokens + tokensToAdd).clamp(0, capacity);
      lastRefill = now;
    }
  }

  bool consume() {
    if (tokens > 0) {
      tokens--;
      return true;
    }
    return false;
  }
}

/// Sliding window rate limiter
class SlidingWindowRateLimiter implements RateLimiter {
  final Cache cache;
  final Map<String, Queue<DateTime>> _windows = {};

  SlidingWindowRateLimiter({Cache? cache}) : cache = cache ?? InMemoryCache();

  @override
  Future<RateLimitInfo> checkLimit(String key, RateLimitConfig config) async {
    final window = _getWindow(key);
    final now = DateTime.now();
    final cutoff = now.subtract(config.window);

    _cleanExpired(window, cutoff);

    final resetTime = window.isNotEmpty
        ? window.first.add(config.window)
        : now.add(config.window);

    return RateLimitInfo(
      currentCount: window.length,
      maxRequests: config.maxRequests,
      resetTime: resetTime,
      window: config.window,
    );
  }

  @override
  Future<void> recordRequest(String key, RateLimitConfig config) async {
    final window = _getWindow(key);
    final now = DateTime.now();
    final cutoff = now.subtract(config.window);

    _cleanExpired(window, cutoff);
    window.add(now);
  }

  @override
  Future<void> reset(String key) async {
    _windows.remove(key);
    await cache.delete(key);
  }

  @override
  Future<void> clear() async {
    _windows.clear();
    await cache.clear();
  }

  Queue<DateTime> _getWindow(String key) {
    return _windows.putIfAbsent(key, () => Queue<DateTime>());
  }

  void _cleanExpired(Queue<DateTime> window, DateTime cutoff) {
    while (window.isNotEmpty && window.first.isBefore(cutoff)) {
      window.removeFirst();
    }
  }
}

/// Fixed window rate limiter
class FixedWindowRateLimiter implements RateLimiter {
  final Cache cache;

  FixedWindowRateLimiter({Cache? cache}) : cache = cache ?? InMemoryCache();

  @override
  Future<RateLimitInfo> checkLimit(String key, RateLimitConfig config) async {
    final windowKey = _getWindowKey(key, config.window);
    final count = await cache.get<int>(windowKey) ?? 0;
    final resetTime = _getResetTime(config.window);

    return RateLimitInfo(
      currentCount: count,
      maxRequests: config.maxRequests,
      resetTime: resetTime,
      window: config.window,
    );
  }

  @override
  Future<void> recordRequest(String key, RateLimitConfig config) async {
    final windowKey = _getWindowKey(key, config.window);
    await cache.increment(windowKey);

    final ttl = _getTimeUntilReset(config.window);
    await cache.touch(windowKey, ttl);
  }

  @override
  Future<void> reset(String key) async {
    await cache.delete(key);
  }

  @override
  Future<void> clear() async {
    await cache.clear();
  }

  String _getWindowKey(String key, Duration window) {
    final now = DateTime.now();
    final windowStart =
        (now.millisecondsSinceEpoch ~/ window.inMilliseconds) *
            window.inMilliseconds;
    return '$key:$windowStart';
  }

  DateTime _getResetTime(Duration window) {
    final now = DateTime.now();
    final windowStart =
        (now.millisecondsSinceEpoch ~/ window.inMilliseconds) *
            window.inMilliseconds;
    return DateTime.fromMillisecondsSinceEpoch(
        windowStart + window.inMilliseconds);
  }

  Duration _getTimeUntilReset(Duration window) {
    final resetTime = _getResetTime(window);
    return resetTime.difference(DateTime.now());
  }
}

/// Rate limiting middleware
class RateLimitMiddleware extends BaseMiddleware {
  final RateLimitConfig config;
  final RateLimiter limiter;

  RateLimitMiddleware({
    required this.config,
    RateLimiter? limiter,
  }) : limiter = limiter ?? _createDefaultLimiter(config);

  static RateLimiter _createDefaultLimiter(RateLimitConfig config) {
    switch (config.strategy) {
      case RateLimitStrategy.tokenBucket:
        return TokenBucketRateLimiter();
      case RateLimitStrategy.slidingWindow:
        return SlidingWindowRateLimiter();
      case RateLimitStrategy.fixedWindow:
        return FixedWindowRateLimiter();
    }
  }

  @override
  Future<HttpResponse?> processRequest(HttpRequest request) async {
    if (!_shouldApplyRateLimit(request)) {
      return null;
    }

    final key = _extractKey(request);
    final info = await limiter.checkLimit(key, config);

    if (info.isLimitExceeded) {
      return _buildErrorResponse(request, info);
    }

    await limiter.recordRequest(key, config);

    request.middlewareState['rate_limit_info'] = info;
    return null;
  }

  @override
  Future<HttpResponse> processResponse(
    HttpRequest request,
    HttpResponse response,
  ) async {
    if (!config.includeHeaders) {
      return response;
    }

    final info = request.middlewareState['rate_limit_info'] as RateLimitInfo?;
    if (info == null) {
      return response;
    }

    return response
        .setHeader('X-RateLimit-Limit', info.maxRequests.toString())
        .setHeader('X-RateLimit-Remaining', info.remaining.toString())
        .setHeader(
          'X-RateLimit-Reset',
          (info.resetTime.millisecondsSinceEpoch ~/ 1000).toString(),
        );
  }

  bool _shouldApplyRateLimit(HttpRequest request) {
    if (config.excludePaths != null) {
      for (final pattern in config.excludePaths!) {
        if (RegExp(pattern).hasMatch(request.path)) {
          return false;
        }
      }
    }

    if (config.methods != null && !config.methods!.contains(request.method)) {
      return false;
    }

    if (config.paths != null) {
      bool matches = false;
      for (final pattern in config.paths!) {
        if (RegExp(pattern).hasMatch(request.path)) {
          matches = true;
          break;
        }
      }
      if (!matches) {
        return false;
      }
    }

    return true;
  }

  String _extractKey(HttpRequest request) {
    switch (config.scope) {
      case RateLimitScope.perIp:
        return 'ratelimit:ip:${_getClientIp(request)}';
      case RateLimitScope.perUser:
        final user = request.middlewareState['user'];
        if (user == null) {
          return 'ratelimit:anonymous:${_getClientIp(request)}';
        }
        final userId = (user as dynamic).id ?? 'unknown';
        return 'ratelimit:user:$userId';
      case RateLimitScope.perEndpoint:
        return 'ratelimit:endpoint:${request.method}:${request.path}';
      case RateLimitScope.global:
        return 'ratelimit:global';
      case RateLimitScope.custom:
        if (config.keyExtractor != null) {
          return config.keyExtractor!(request);
        }
        return 'ratelimit:custom:${_getClientIp(request)}';
    }
  }

  String _getClientIp(HttpRequest request) {
    final forwardedFor = request.headers['x-forwarded-for'];
    if (forwardedFor != null) {
      return forwardedFor.split(',').first.trim();
    }

    final realIp = request.headers['x-real-ip'];
    if (realIp != null) {
      return realIp;
    }

    return request.uri.host;
  }

  HttpResponse _buildErrorResponse(HttpRequest request, RateLimitInfo info) {
    if (config.errorBuilder != null) {
      return config.errorBuilder!(request, info);
    }

    final message = config.errorMessage ??
        'Rate limit exceeded. Try again in ${info.retryAfterSeconds} seconds.';

    return HttpResponse.tooManyRequests(message)
        .setHeader('Retry-After', info.retryAfterSeconds.toString())
        .setHeader('X-RateLimit-Limit', info.maxRequests.toString())
        .setHeader('X-RateLimit-Remaining', '0')
        .setHeader(
          'X-RateLimit-Reset',
          (info.resetTime.millisecondsSinceEpoch ~/ 1000).toString(),
        );
  }
}

/// Convenience factory methods for common rate limiting scenarios
class RateLimitPresets {
  /// Strict rate limit: 10 requests per minute
  static RateLimitConfig strict() {
    return const RateLimitConfig(
      maxRequests: 10,
      window: Duration(minutes: 1),
      strategy: RateLimitStrategy.slidingWindow,
    );
  }

  /// Moderate rate limit: 100 requests per minute
  static RateLimitConfig moderate() {
    return const RateLimitConfig(
      maxRequests: 100,
      window: Duration(minutes: 1),
      strategy: RateLimitStrategy.slidingWindow,
    );
  }

  /// Relaxed rate limit: 1000 requests per minute
  static RateLimitConfig relaxed() {
    return const RateLimitConfig(
      maxRequests: 1000,
      window: Duration(minutes: 1),
      strategy: RateLimitStrategy.tokenBucket,
    );
  }

  /// API rate limit: 1000 requests per hour
  static RateLimitConfig api() {
    return const RateLimitConfig(
      maxRequests: 1000,
      window: Duration(hours: 1),
      strategy: RateLimitStrategy.slidingWindow,
      scope: RateLimitScope.perUser,
    );
  }

  /// Authentication rate limit: 5 attempts per 15 minutes
  static RateLimitConfig authentication() {
    return const RateLimitConfig(
      maxRequests: 5,
      window: Duration(minutes: 15),
      strategy: RateLimitStrategy.fixedWindow,
      scope: RateLimitScope.perIp,
    );
  }

  /// Custom rate limit
  static RateLimitConfig custom({
    required int maxRequests,
    required Duration window,
    RateLimitStrategy strategy = RateLimitStrategy.slidingWindow,
    RateLimitScope scope = RateLimitScope.perIp,
    String Function(HttpRequest request)? keyExtractor,
    List<String>? methods,
    List<String>? paths,
    List<String>? excludePaths,
  }) {
    return RateLimitConfig(
      maxRequests: maxRequests,
      window: window,
      strategy: strategy,
      scope: scope,
      keyExtractor: keyExtractor,
      methods: methods,
      paths: paths,
      excludePaths: excludePaths,
    );
  }
}
