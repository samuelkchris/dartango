import 'dart:collection';
import 'dart:math';

import 'resolver.dart';

abstract class RouteCache {
  ResolverMatch? get(String key);

  void put(String key, ResolverMatch value);

  void clear();

  int get size;

  bool get isEmpty;

  bool get isNotEmpty;
}

class LRURouteCache implements RouteCache {
  final int maxSize;
  final LinkedHashMap<String, ResolverMatch> _cache;

  LRURouteCache({this.maxSize = 1000})
      : _cache = LinkedHashMap<String, ResolverMatch>();

  @override
  ResolverMatch? get(String key) {
    if (!_cache.containsKey(key)) return null;

    final value = _cache.remove(key)!;
    _cache[key] = value;
    return value;
  }

  @override
  void put(String key, ResolverMatch value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
    }

    _cache[key] = value;
  }

  @override
  void clear() {
    _cache.clear();
  }

  @override
  int get size => _cache.length;

  @override
  bool get isEmpty => _cache.isEmpty;

  @override
  bool get isNotEmpty => _cache.isNotEmpty;
}

class TTLRouteCache implements RouteCache {
  final int maxSize;
  final Duration ttl;
  final Map<String, ResolverMatch> _cache;
  final Map<String, DateTime> _timestamps;

  TTLRouteCache({
    this.maxSize = 1000,
    this.ttl = const Duration(minutes: 5),
  })  : _cache = {},
        _timestamps = {};

  @override
  ResolverMatch? get(String key) {
    _cleanupExpired();

    if (!_cache.containsKey(key)) return null;

    final timestamp = _timestamps[key]!;
    if (DateTime.now().difference(timestamp) > ttl) {
      _cache.remove(key);
      _timestamps.remove(key);
      return null;
    }

    return _cache[key];
  }

  @override
  void put(String key, ResolverMatch value) {
    _cleanupExpired();

    if (_cache.length >= maxSize && !_cache.containsKey(key)) {
      final oldestKey = _timestamps.keys
          .reduce((a, b) => _timestamps[a]!.isBefore(_timestamps[b]!) ? a : b);
      _cache.remove(oldestKey);
      _timestamps.remove(oldestKey);
    }

    _cache[key] = value;
    _timestamps[key] = DateTime.now();
  }

  @override
  void clear() {
    _cache.clear();
    _timestamps.clear();
  }

  @override
  int get size => _cache.length;

  @override
  bool get isEmpty => _cache.isEmpty;

  @override
  bool get isNotEmpty => _cache.isNotEmpty;

  void _cleanupExpired() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _timestamps.entries) {
      if (now.difference(entry.value) > ttl) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cache.remove(key);
      _timestamps.remove(key);
    }
  }
}

class FIFORouteCache implements RouteCache {
  final int maxSize;
  final Map<String, ResolverMatch> _cache;
  final Queue<String> _order;

  FIFORouteCache({this.maxSize = 1000})
      : _cache = {},
        _order = Queue<String>();

  @override
  ResolverMatch? get(String key) {
    return _cache[key];
  }

  @override
  void put(String key, ResolverMatch value) {
    if (_cache.containsKey(key)) {
      _cache[key] = value;
      return;
    }

    if (_cache.length >= maxSize) {
      final oldestKey = _order.removeFirst();
      _cache.remove(oldestKey);
    }

    _cache[key] = value;
    _order.add(key);
  }

  @override
  void clear() {
    _cache.clear();
    _order.clear();
  }

  @override
  int get size => _cache.length;

  @override
  bool get isEmpty => _cache.isEmpty;

  @override
  bool get isNotEmpty => _cache.isNotEmpty;
}

class RandomRouteCache implements RouteCache {
  final int maxSize;
  final Map<String, ResolverMatch> _cache;
  final Random _random;

  RandomRouteCache({this.maxSize = 1000})
      : _cache = {},
        _random = Random();

  @override
  ResolverMatch? get(String key) {
    return _cache[key];
  }

  @override
  void put(String key, ResolverMatch value) {
    if (_cache.containsKey(key)) {
      _cache[key] = value;
      return;
    }

    if (_cache.length >= maxSize) {
      final keys = _cache.keys.toList();
      final randomKey = keys[_random.nextInt(keys.length)];
      _cache.remove(randomKey);
    }

    _cache[key] = value;
  }

  @override
  void clear() {
    _cache.clear();
  }

  @override
  int get size => _cache.length;

  @override
  bool get isEmpty => _cache.isEmpty;

  @override
  bool get isNotEmpty => _cache.isNotEmpty;
}

class NoOpRouteCache implements RouteCache {
  @override
  ResolverMatch? get(String key) => null;

  @override
  void put(String key, ResolverMatch value) {}

  @override
  void clear() {}

  @override
  int get size => 0;

  @override
  bool get isEmpty => true;

  @override
  bool get isNotEmpty => false;
}

class CachedURLResolver extends URLResolver {
  final RouteCache _cache;

  CachedURLResolver({
    required List<URLPattern> urlPatterns,
    String? appName,
    String? namespace,
    RouteCache? cache,
  })  : _cache = cache ?? LRURouteCache(),
        super(
          urlPatterns: urlPatterns,
          appName: appName,
          namespace: namespace,
          enableCaching: false,
        );

  @override
  ResolverMatch? resolve(String path) {
    final cached = _cache.get(path);
    if (cached != null) {
      return cached;
    }

    final match = super.resolve(path);
    if (match != null) {
      _cache.put(path, match);
    }

    return match;
  }

  @override
  void clearCache() {
    _cache.clear();
    super.clearCache();
  }

  RouteCache get cache => _cache;
}

class ReverseCacheEntry {
  final String viewName;
  final Map<String, String>? kwargs;
  final List<String>? args;
  final String result;

  const ReverseCacheEntry({
    required this.viewName,
    this.kwargs,
    this.args,
    required this.result,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ReverseCacheEntry) return false;

    return viewName == other.viewName &&
        _mapEquals(kwargs, other.kwargs) &&
        _listEquals(args, other.args);
  }

  @override
  int get hashCode {
    return Object.hash(
      viewName,
      kwargs?.entries
              .map((e) => Object.hash(e.key, e.value))
              .fold<int>(0, (a, b) => a ^ b) ??
          0,
      args?.fold<int>(0, (a, b) => a.hashCode ^ b.hashCode) ?? 0,
    );
  }

  bool _mapEquals(Map<String, String>? a, Map<String, String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }

    return true;
  }

  bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }
}

class CachedURLConfiguration extends URLConfiguration {
  final RouteCache _resolveCache;
  final Map<ReverseCacheEntry, String> _reverseCache;
  final int _reverseCacheMaxSize;

  CachedURLConfiguration(
    List<URLPattern> urlPatterns, {
    String? appName,
    String? namespace,
    RouteCache? resolveCache,
    int reverseCacheMaxSize = 1000,
  })  : _resolveCache = resolveCache ?? LRURouteCache(),
        _reverseCache = {},
        _reverseCacheMaxSize = reverseCacheMaxSize,
        super(urlPatterns, appName: appName, namespace: namespace);

  @override
  ResolverMatch? resolve(String path) {
    final cached = _resolveCache.get(path);
    if (cached != null) {
      return cached;
    }

    final match = super.resolve(path);
    if (match != null) {
      _resolveCache.put(path, match);
    }

    return match;
  }

  @override
  String? reverse(String viewName,
      {Map<String, String>? kwargs, List<String>? args}) {
    final cacheKey = ReverseCacheEntry(
      viewName: viewName,
      kwargs: kwargs,
      args: args,
      result: '',
    );

    if (_reverseCache.containsKey(cacheKey)) {
      return _reverseCache[cacheKey];
    }

    final result = super.reverse(viewName, kwargs: kwargs, args: args);
    if (result != null) {
      if (_reverseCache.length >= _reverseCacheMaxSize) {
        final firstKey = _reverseCache.keys.first;
        _reverseCache.remove(firstKey);
      }

      _reverseCache[ReverseCacheEntry(
        viewName: viewName,
        kwargs: kwargs,
        args: args,
        result: result,
      )] = result;
    }

    return result;
  }

  @override
  void clearCache() {
    _resolveCache.clear();
    _reverseCache.clear();
    super.clearCache();
  }

  RouteCache get resolveCache => _resolveCache;

  int get reverseCacheSize => _reverseCache.length;
}
