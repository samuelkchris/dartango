import 'dart:async';
import 'dart:convert';
import 'dart:math';

abstract class Cache {
  Future<T?> get<T>(String key);
  Future<void> set<T>(String key, T value, {Duration? timeout});
  Future<void> delete(String key);
  Future<void> clear();
  Future<bool> exists(String key);
  Future<int> size();
  Future<List<String>> keys();
  Future<Map<String, T>> getMany<T>(List<String> keys);
  Future<void> setMany<T>(Map<String, T> values, {Duration? timeout});
  Future<void> deleteMany(List<String> keys);
  Future<T?> getOrSet<T>(String key, Future<T> Function() factory, {Duration? timeout});
  Future<void> touch(String key, {Duration? timeout});
  Future<int> increment(String key, {int delta = 1});
  Future<int> decrement(String key, {int delta = 1});
  Future<void> expire(String key, Duration timeout);
  Future<Duration?> ttl(String key);
}

abstract class CacheBackend implements Cache {
  String makeKey(String key) => key;
  
  T? deserialize<T>(String data) {
    try {
      final decoded = json.decode(data);
      return decoded as T?;
    } catch (e) {
      return null;
    }
  }
  
  String serialize<T>(T value) {
    return json.encode(value);
  }
}

class CacheEntry<T> {
  final T value;
  final DateTime expiry;
  
  CacheEntry(this.value, this.expiry);
  
  bool get isExpired => DateTime.now().isAfter(expiry);
}

class InMemoryCache extends CacheBackend {
  final Map<String, CacheEntry> _cache = {};
  final Duration _defaultTimeout;
  
  InMemoryCache({Duration? defaultTimeout}) 
    : _defaultTimeout = defaultTimeout ?? const Duration(minutes: 5);
  
  @override
  Future<T?> get<T>(String key) async {
    final entry = _cache[makeKey(key)];
    if (entry == null || entry.isExpired) {
      if (entry != null) {
        _cache.remove(makeKey(key));
      }
      return null;
    }
    return entry.value as T?;
  }
  
  @override
  Future<void> set<T>(String key, T value, {Duration? timeout}) async {
    final expiry = DateTime.now().add(timeout ?? _defaultTimeout);
    _cache[makeKey(key)] = CacheEntry(value, expiry);
  }
  
  @override
  Future<void> delete(String key) async {
    _cache.remove(makeKey(key));
  }
  
  @override
  Future<void> clear() async {
    _cache.clear();
  }
  
  @override
  Future<bool> exists(String key) async {
    return await get(key) != null;
  }
  
  @override
  Future<int> size() async {
    _cleanupExpired();
    return _cache.length;
  }
  
  @override
  Future<List<String>> keys() async {
    _cleanupExpired();
    return _cache.keys.toList();
  }
  
  @override
  Future<Map<String, T>> getMany<T>(List<String> keys) async {
    final result = <String, T>{};
    for (final key in keys) {
      final value = await get<T>(key);
      if (value != null) {
        result[key] = value;
      }
    }
    return result;
  }
  
  @override
  Future<void> setMany<T>(Map<String, T> values, {Duration? timeout}) async {
    for (final entry in values.entries) {
      await set(entry.key, entry.value, timeout: timeout);
    }
  }
  
  @override
  Future<void> deleteMany(List<String> keys) async {
    for (final key in keys) {
      await delete(key);
    }
  }
  
  @override
  Future<T?> getOrSet<T>(String key, Future<T> Function() factory, {Duration? timeout}) async {
    final existing = await get<T>(key);
    if (existing != null) {
      return existing;
    }
    
    final value = await factory();
    await set(key, value, timeout: timeout);
    return value;
  }
  
  @override
  Future<void> touch(String key, {Duration? timeout}) async {
    final value = await get(key);
    if (value != null) {
      await set(key, value, timeout: timeout);
    }
  }
  
  @override
  Future<int> increment(String key, {int delta = 1}) async {
    final current = await get<int>(key) ?? 0;
    final newValue = current + delta;
    await set(key, newValue);
    return newValue;
  }
  
  @override
  Future<int> decrement(String key, {int delta = 1}) async {
    return await increment(key, delta: -delta);
  }
  
  @override
  Future<void> expire(String key, Duration timeout) async {
    final value = await get(key);
    if (value != null) {
      await set(key, value, timeout: timeout);
    }
  }
  
  @override
  Future<Duration?> ttl(String key) async {
    final entry = _cache[makeKey(key)];
    if (entry == null || entry.isExpired) {
      return null;
    }
    return entry.expiry.difference(DateTime.now());
  }
  
  void _cleanupExpired() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _cache.entries) {
      if (entry.value.expiry.isBefore(now)) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }
}

class LRUCache extends CacheBackend {
  final int _maxSize;
  final Duration _defaultTimeout;
  final Map<String, CacheEntry> _cache = {};
  final Map<String, int> _accessOrder = {};
  int _currentTime = 0;
  
  LRUCache({int maxSize = 1000, Duration? defaultTimeout}) 
    : _maxSize = maxSize,
      _defaultTimeout = defaultTimeout ?? const Duration(minutes: 5);
  
  @override
  Future<T?> get<T>(String key) async {
    final entry = _cache[makeKey(key)];
    if (entry == null || entry.isExpired) {
      if (entry != null) {
        _cache.remove(makeKey(key));
        _accessOrder.remove(makeKey(key));
      }
      return null;
    }
    
    _accessOrder[makeKey(key)] = ++_currentTime;
    return entry.value as T?;
  }
  
  @override
  Future<void> set<T>(String key, T value, {Duration? timeout}) async {
    final k = makeKey(key);
    final expiry = DateTime.now().add(timeout ?? _defaultTimeout);
    
    if (_cache.containsKey(k)) {
      _cache[k] = CacheEntry(value, expiry);
      _accessOrder[k] = ++_currentTime;
    } else {
      if (_cache.length >= _maxSize) {
        _evictLRU();
      }
      
      _cache[k] = CacheEntry(value, expiry);
      _accessOrder[k] = ++_currentTime;
    }
  }
  
  @override
  Future<void> delete(String key) async {
    final k = makeKey(key);
    _cache.remove(k);
    _accessOrder.remove(k);
  }
  
  @override
  Future<void> clear() async {
    _cache.clear();
    _accessOrder.clear();
    _currentTime = 0;
  }
  
  @override
  Future<bool> exists(String key) async {
    return await get(key) != null;
  }
  
  @override
  Future<int> size() async {
    _cleanupExpired();
    return _cache.length;
  }
  
  @override
  Future<List<String>> keys() async {
    _cleanupExpired();
    return _cache.keys.toList();
  }
  
  @override
  Future<Map<String, T>> getMany<T>(List<String> keys) async {
    final result = <String, T>{};
    for (final key in keys) {
      final value = await get<T>(key);
      if (value != null) {
        result[key] = value;
      }
    }
    return result;
  }
  
  @override
  Future<void> setMany<T>(Map<String, T> values, {Duration? timeout}) async {
    for (final entry in values.entries) {
      await set(entry.key, entry.value, timeout: timeout);
    }
  }
  
  @override
  Future<void> deleteMany(List<String> keys) async {
    for (final key in keys) {
      await delete(key);
    }
  }
  
  @override
  Future<T?> getOrSet<T>(String key, Future<T> Function() factory, {Duration? timeout}) async {
    final existing = await get<T>(key);
    if (existing != null) {
      return existing;
    }
    
    final value = await factory();
    await set(key, value, timeout: timeout);
    return value;
  }
  
  @override
  Future<void> touch(String key, {Duration? timeout}) async {
    final value = await get(key);
    if (value != null) {
      await set(key, value, timeout: timeout);
    }
  }
  
  @override
  Future<int> increment(String key, {int delta = 1}) async {
    final current = await get<int>(key) ?? 0;
    final newValue = current + delta;
    await set(key, newValue);
    return newValue;
  }
  
  @override
  Future<int> decrement(String key, {int delta = 1}) async {
    return await increment(key, delta: -delta);
  }
  
  @override
  Future<void> expire(String key, Duration timeout) async {
    final value = await get(key);
    if (value != null) {
      await set(key, value, timeout: timeout);
    }
  }
  
  @override
  Future<Duration?> ttl(String key) async {
    final entry = _cache[makeKey(key)];
    if (entry == null || entry.isExpired) {
      return null;
    }
    return entry.expiry.difference(DateTime.now());
  }
  
  void _evictLRU() {
    if (_accessOrder.isEmpty) return;
    
    final lruKey = _accessOrder.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;
    
    _cache.remove(lruKey);
    _accessOrder.remove(lruKey);
  }
  
  void _cleanupExpired() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _cache.entries) {
      if (entry.value.expiry.isBefore(now)) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _cache.remove(key);
      _accessOrder.remove(key);
    }
  }
}

class NullCache extends CacheBackend {
  @override
  Future<T?> get<T>(String key) async => null;
  
  @override
  Future<void> set<T>(String key, T value, {Duration? timeout}) async {}
  
  @override
  Future<void> delete(String key) async {}
  
  @override
  Future<void> clear() async {}
  
  @override
  Future<bool> exists(String key) async => false;
  
  @override
  Future<int> size() async => 0;
  
  @override
  Future<List<String>> keys() async => [];
  
  @override
  Future<Map<String, T>> getMany<T>(List<String> keys) async => {};
  
  @override
  Future<void> setMany<T>(Map<String, T> values, {Duration? timeout}) async {}
  
  @override
  Future<void> deleteMany(List<String> keys) async {}
  
  @override
  Future<T?> getOrSet<T>(String key, Future<T> Function() factory, {Duration? timeout}) async {
    return await factory();
  }
  
  @override
  Future<void> touch(String key, {Duration? timeout}) async {}
  
  @override
  Future<int> increment(String key, {int delta = 1}) async => delta;
  
  @override
  Future<int> decrement(String key, {int delta = 1}) async => -delta;
  
  @override
  Future<void> expire(String key, Duration timeout) async {}
  
  @override
  Future<Duration?> ttl(String key) async => null;
}

class CacheStatistics {
  int hits = 0;
  int misses = 0;
  int sets = 0;
  int deletes = 0;
  int evictions = 0;
  
  double get hitRate => (hits + misses) > 0 ? hits / (hits + misses) : 0.0;
  double get missRate => 1.0 - hitRate;
  
  void recordHit() => hits++;
  void recordMiss() => misses++;
  void recordSet() => sets++;
  void recordDelete() => deletes++;
  void recordEviction() => evictions++;
  
  void reset() {
    hits = 0;
    misses = 0;
    sets = 0;
    deletes = 0;
    evictions = 0;
  }
  
  Map<String, dynamic> toMap() {
    return {
      'hits': hits,
      'misses': misses,
      'sets': sets,
      'deletes': deletes,
      'evictions': evictions,
      'hit_rate': hitRate,
      'miss_rate': missRate,
    };
  }
}

class StatisticsCache extends CacheBackend {
  final Cache _backend;
  final CacheStatistics _stats = CacheStatistics();
  
  StatisticsCache(this._backend);
  
  CacheStatistics get statistics => _stats;
  
  @override
  Future<T?> get<T>(String key) async {
    final value = await _backend.get<T>(key);
    if (value != null) {
      _stats.recordHit();
    } else {
      _stats.recordMiss();
    }
    return value;
  }
  
  @override
  Future<void> set<T>(String key, T value, {Duration? timeout}) async {
    await _backend.set(key, value, timeout: timeout);
    _stats.recordSet();
  }
  
  @override
  Future<void> delete(String key) async {
    await _backend.delete(key);
    _stats.recordDelete();
  }
  
  @override
  Future<void> clear() async {
    await _backend.clear();
  }
  
  @override
  Future<bool> exists(String key) async {
    return await _backend.exists(key);
  }
  
  @override
  Future<int> size() async {
    return await _backend.size();
  }
  
  @override
  Future<List<String>> keys() async {
    return await _backend.keys();
  }
  
  @override
  Future<Map<String, T>> getMany<T>(List<String> keys) async {
    return await _backend.getMany<T>(keys);
  }
  
  @override
  Future<void> setMany<T>(Map<String, T> values, {Duration? timeout}) async {
    await _backend.setMany(values, timeout: timeout);
    _stats.sets += values.length;
  }
  
  @override
  Future<void> deleteMany(List<String> keys) async {
    await _backend.deleteMany(keys);
    _stats.deletes += keys.length;
  }
  
  @override
  Future<T?> getOrSet<T>(String key, Future<T> Function() factory, {Duration? timeout}) async {
    return await _backend.getOrSet(key, factory, timeout: timeout);
  }
  
  @override
  Future<void> touch(String key, {Duration? timeout}) async {
    await _backend.touch(key, timeout: timeout);
  }
  
  @override
  Future<int> increment(String key, {int delta = 1}) async {
    return await _backend.increment(key, delta: delta);
  }
  
  @override
  Future<int> decrement(String key, {int delta = 1}) async {
    return await _backend.decrement(key, delta: delta);
  }
  
  @override
  Future<void> expire(String key, Duration timeout) async {
    await _backend.expire(key, timeout);
  }
  
  @override
  Future<Duration?> ttl(String key) async {
    return await _backend.ttl(key);
  }
}