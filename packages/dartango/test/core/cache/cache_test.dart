import 'package:test/test.dart';
import '../../../lib/src/core/cache/cache.dart';

void main() {
  group('InMemoryCache', () {
    late InMemoryCache cache;

    setUp(() {
      cache = InMemoryCache(defaultTimeout: const Duration(seconds: 2));
    });

    tearDown(() async {
      await cache.clear();
    });

    test('should set and get values', () async {
      await cache.set('key1', 'value1');
      final value = await cache.get<String>('key1');

      expect(value, equals('value1'));
    });

    test('should handle different data types', () async {
      await cache.set('string', 'text');
      await cache.set('int', 42);
      await cache.set('double', 3.14);
      await cache.set('bool', true);
      await cache.set('list', [1, 2, 3]);
      await cache.set('map', {'key': 'value'});

      expect(await cache.get<String>('string'), equals('text'));
      expect(await cache.get<int>('int'), equals(42));
      expect(await cache.get<double>('double'), equals(3.14));
      expect(await cache.get<bool>('bool'), isTrue);
      expect(await cache.get<List>('list'), equals([1, 2, 3]));
      expect(await cache.get<Map>('map'), equals({'key': 'value'}));
    });

    test('should return null for non-existent keys', () async {
      final value = await cache.get<String>('nonexistent');
      expect(value, isNull);
    });

    test('should delete values', () async {
      await cache.set('key1', 'value1');
      expect(await cache.get<String>('key1'), equals('value1'));

      await cache.delete('key1');
      expect(await cache.get<String>('key1'), isNull);
    });

    test('should clear all values', () async {
      await cache.set('key1', 'value1');
      await cache.set('key2', 'value2');
      await cache.set('key3', 'value3');

      await cache.clear();

      expect(await cache.size(), equals(0));
      expect(await cache.get<String>('key1'), isNull);
      expect(await cache.get<String>('key2'), isNull);
    });

    test('should check if key exists', () async {
      expect(await cache.exists('key1'), isFalse);

      await cache.set('key1', 'value1');
      expect(await cache.exists('key1'), isTrue);

      await cache.delete('key1');
      expect(await cache.exists('key1'), isFalse);
    });

    test('should return cache size', () async {
      expect(await cache.size(), equals(0));

      await cache.set('key1', 'value1');
      expect(await cache.size(), equals(1));

      await cache.set('key2', 'value2');
      await cache.set('key3', 'value3');
      expect(await cache.size(), equals(3));

      await cache.delete('key2');
      expect(await cache.size(), equals(2));
    });

    test('should return all keys', () async {
      await cache.set('key1', 'value1');
      await cache.set('key2', 'value2');
      await cache.set('key3', 'value3');

      final keys = await cache.keys();
      expect(keys, hasLength(3));
      expect(keys, containsAll(['key1', 'key2', 'key3']));
    });

    test('should get many values at once', () async {
      await cache.set('key1', 'value1');
      await cache.set('key2', 'value2');
      await cache.set('key3', 'value3');

      final values = await cache.getMany<String>(['key1', 'key2', 'nonexistent']);

      expect(values, hasLength(2));
      expect(values['key1'], equals('value1'));
      expect(values['key2'], equals('value2'));
      expect(values.containsKey('nonexistent'), isFalse);
    });

    test('should set many values at once', () async {
      await cache.setMany({
        'key1': 'value1',
        'key2': 'value2',
        'key3': 'value3',
      });

      expect(await cache.get<String>('key1'), equals('value1'));
      expect(await cache.get<String>('key2'), equals('value2'));
      expect(await cache.get<String>('key3'), equals('value3'));
    });

    test('should delete many values at once', () async {
      await cache.set('key1', 'value1');
      await cache.set('key2', 'value2');
      await cache.set('key3', 'value3');

      await cache.deleteMany(['key1', 'key3']);

      expect(await cache.get<String>('key1'), isNull);
      expect(await cache.get<String>('key2'), equals('value2'));
      expect(await cache.get<String>('key3'), isNull);
    });

    test('should handle getOrSet with existing value', () async {
      await cache.set('key1', 'existing');

      var factoryCalled = false;
      final value = await cache.getOrSet<String>(
        'key1',
        () async {
          factoryCalled = true;
          return 'new';
        },
      );

      expect(value, equals('existing'));
      expect(factoryCalled, isFalse);
    });

    test('should handle getOrSet with non-existent value', () async {
      var factoryCalled = false;
      final value = await cache.getOrSet<String>(
        'key1',
        () async {
          factoryCalled = true;
          return 'new';
        },
      );

      expect(value, equals('new'));
      expect(factoryCalled, isTrue);
      expect(await cache.get<String>('key1'), equals('new'));
    });

    test('should touch to update expiry', () async {
      await cache.set('key1', 'value1', timeout: const Duration(seconds: 1));

      await Future.delayed(const Duration(milliseconds: 500));
      await cache.touch('key1', timeout: const Duration(seconds: 2));
      await Future.delayed(const Duration(milliseconds: 600));

      expect(await cache.get<String>('key1'), equals('value1'));
    });

    test('should increment numeric values', () async {
      expect(await cache.increment('counter'), equals(1));
      expect(await cache.increment('counter'), equals(2));
      expect(await cache.increment('counter', delta: 5), equals(7));
    });

    test('should decrement numeric values', () async {
      await cache.set('counter', 10);

      expect(await cache.decrement('counter'), equals(9));
      expect(await cache.decrement('counter'), equals(8));
      expect(await cache.decrement('counter', delta: 3), equals(5));
    });

    test('should handle expiration correctly', () async {
      await cache.set('key1', 'value1', timeout: const Duration(milliseconds: 500));

      expect(await cache.get<String>('key1'), equals('value1'));

      await Future.delayed(const Duration(milliseconds: 600));
      expect(await cache.get<String>('key1'), isNull);
    });

    test('should update expiry with expire method', () async {
      await cache.set('key1', 'value1', timeout: const Duration(milliseconds: 500));
      await cache.expire('key1', const Duration(seconds: 2));

      await Future.delayed(const Duration(milliseconds: 600));
      expect(await cache.get<String>('key1'), equals('value1'));
    });

    test('should return time to live', () async {
      await cache.set('key1', 'value1', timeout: const Duration(seconds: 2));

      final ttl = await cache.ttl('key1');
      expect(ttl, isNotNull);
      expect(ttl!.inSeconds, greaterThanOrEqualTo(1));
      expect(ttl.inSeconds, lessThanOrEqualTo(2));
    });

    test('should return null ttl for expired keys', () async {
      await cache.set('key1', 'value1', timeout: const Duration(milliseconds: 100));
      await Future.delayed(const Duration(milliseconds: 150));

      final ttl = await cache.ttl('key1');
      expect(ttl, isNull);
    });

    test('should return null ttl for non-existent keys', () async {
      final ttl = await cache.ttl('nonexistent');
      expect(ttl, isNull);
    });

    test('should clean up expired entries on size call', () async {
      await cache.set('key1', 'value1', timeout: const Duration(milliseconds: 100));
      await cache.set('key2', 'value2', timeout: const Duration(seconds: 10));

      expect(await cache.size(), equals(2));

      await Future.delayed(const Duration(milliseconds: 150));
      expect(await cache.size(), equals(1));
    });

    test('should clean up expired entries on keys call', () async {
      await cache.set('key1', 'value1', timeout: const Duration(milliseconds: 100));
      await cache.set('key2', 'value2', timeout: const Duration(seconds: 10));

      await Future.delayed(const Duration(milliseconds: 150));

      final keys = await cache.keys();
      expect(keys, hasLength(1));
      expect(keys, contains('key2'));
    });
  });

  group('LRUCache', () {
    late LRUCache cache;

    setUp(() {
      cache = LRUCache(maxSize: 3, defaultTimeout: const Duration(seconds: 10));
    });

    tearDown(() async {
      await cache.clear();
    });

    test('should set and get values', () async {
      await cache.set('key1', 'value1');
      final value = await cache.get<String>('key1');

      expect(value, equals('value1'));
    });

    test('should evict least recently used item when max size reached', () async {
      await cache.set('key1', 'value1');
      await cache.set('key2', 'value2');
      await cache.set('key3', 'value3');

      expect(await cache.size(), equals(3));

      await cache.set('key4', 'value4');

      expect(await cache.size(), equals(3));
      expect(await cache.get<String>('key1'), isNull);
      expect(await cache.get<String>('key2'), equals('value2'));
      expect(await cache.get<String>('key3'), equals('value3'));
      expect(await cache.get<String>('key4'), equals('value4'));
    });

    test('should update access order on get', () async {
      await cache.set('key1', 'value1');
      await cache.set('key2', 'value2');
      await cache.set('key3', 'value3');

      await cache.get('key1');

      await cache.set('key4', 'value4');

      expect(await cache.get<String>('key1'), equals('value1'));
      expect(await cache.get<String>('key2'), isNull);
    });

    test('should update access order on set for existing key', () async {
      await cache.set('key1', 'value1');
      await cache.set('key2', 'value2');
      await cache.set('key3', 'value3');

      await cache.set('key1', 'updated1');

      await cache.set('key4', 'value4');

      expect(await cache.get<String>('key1'), equals('updated1'));
      expect(await cache.get<String>('key2'), isNull);
    });

    test('should handle all standard cache operations', () async {
      await cache.set('key1', 'value1');

      expect(await cache.exists('key1'), isTrue);
      expect(await cache.size(), equals(1));
      expect(await cache.keys(), contains('key1'));

      await cache.delete('key1');
      expect(await cache.get<String>('key1'), isNull);
    });

    test('should handle expiration', () async {
      await cache.set('key1', 'value1', timeout: const Duration(milliseconds: 200));

      expect(await cache.get<String>('key1'), equals('value1'));

      await Future.delayed(const Duration(milliseconds: 250));
      expect(await cache.get<String>('key1'), isNull);
    });

    test('should handle getMany and setMany', () async {
      await cache.setMany({
        'key1': 'value1',
        'key2': 'value2',
      });

      final values = await cache.getMany<String>(['key1', 'key2']);
      expect(values['key1'], equals('value1'));
      expect(values['key2'], equals('value2'));
    });

    test('should handle increment and decrement', () async {
      expect(await cache.increment('counter'), equals(1));
      expect(await cache.increment('counter', delta: 5), equals(6));
      expect(await cache.decrement('counter', delta: 2), equals(4));
    });
  });

  group('NullCache', () {
    late NullCache cache;

    setUp(() {
      cache = NullCache();
    });

    test('should always return null for get', () async {
      await cache.set('key1', 'value1');
      expect(await cache.get<String>('key1'), isNull);
    });

    test('should always return false for exists', () async {
      await cache.set('key1', 'value1');
      expect(await cache.exists('key1'), isFalse);
    });

    test('should always return 0 for size', () async {
      await cache.set('key1', 'value1');
      await cache.set('key2', 'value2');
      expect(await cache.size(), equals(0));
    });

    test('should always return empty list for keys', () async {
      await cache.set('key1', 'value1');
      expect(await cache.keys(), isEmpty);
    });

    test('should always return empty map for getMany', () async {
      await cache.set('key1', 'value1');
      final values = await cache.getMany<String>(['key1']);
      expect(values, isEmpty);
    });

    test('should always call factory in getOrSet', () async {
      var factoryCalled = false;
      await cache.set('key1', 'existing');

      final value = await cache.getOrSet<String>(
        'key1',
        () async {
          factoryCalled = true;
          return 'new';
        },
      );

      expect(value, equals('new'));
      expect(factoryCalled, isTrue);
    });

    test('should handle increment starting from delta', () async {
      expect(await cache.increment('counter'), equals(1));
      expect(await cache.increment('counter', delta: 5), equals(5));
    });

    test('should handle decrement returning negative delta', () async {
      expect(await cache.decrement('counter'), equals(-1));
      expect(await cache.decrement('counter', delta: 5), equals(-5));
    });
  });

  group('CacheStatistics', () {
    late CacheStatistics stats;

    setUp(() {
      stats = CacheStatistics();
    });

    test('should track hits and misses', () {
      stats.recordHit();
      stats.recordHit();
      stats.recordMiss();

      expect(stats.hits, equals(2));
      expect(stats.misses, equals(1));
      expect(stats.hitRate, closeTo(0.666, 0.001));
      expect(stats.missRate, closeTo(0.333, 0.001));
    });

    test('should track sets and deletes', () {
      stats.recordSet();
      stats.recordSet();
      stats.recordSet();
      stats.recordDelete();

      expect(stats.sets, equals(3));
      expect(stats.deletes, equals(1));
    });

    test('should track evictions', () {
      stats.recordEviction();
      stats.recordEviction();

      expect(stats.evictions, equals(2));
    });

    test('should handle zero hits and misses', () {
      expect(stats.hitRate, equals(0.0));
      expect(stats.missRate, equals(1.0));
    });

    test('should reset all statistics', () {
      stats.recordHit();
      stats.recordMiss();
      stats.recordSet();
      stats.recordDelete();
      stats.recordEviction();

      stats.reset();

      expect(stats.hits, equals(0));
      expect(stats.misses, equals(0));
      expect(stats.sets, equals(0));
      expect(stats.deletes, equals(0));
      expect(stats.evictions, equals(0));
    });

    test('should convert to map', () {
      stats.recordHit();
      stats.recordHit();
      stats.recordMiss();
      stats.recordSet();

      final map = stats.toMap();

      expect(map['hits'], equals(2));
      expect(map['misses'], equals(1));
      expect(map['sets'], equals(1));
      expect(map['deletes'], equals(0));
      expect(map['evictions'], equals(0));
      expect(map['hit_rate'], closeTo(0.666, 0.001));
      expect(map['miss_rate'], closeTo(0.333, 0.001));
    });
  });

  group('StatisticsCache', () {
    late InMemoryCache backend;
    late StatisticsCache cache;

    setUp(() {
      backend = InMemoryCache();
      cache = StatisticsCache(backend);
    });

    tearDown(() async {
      await cache.clear();
    });

    test('should track cache hits', () async {
      await cache.set('key1', 'value1');
      await cache.get<String>('key1');
      await cache.get<String>('key1');

      expect(cache.statistics.hits, equals(2));
      expect(cache.statistics.misses, equals(0));
    });

    test('should track cache misses', () async {
      await cache.get<String>('nonexistent1');
      await cache.get<String>('nonexistent2');

      expect(cache.statistics.hits, equals(0));
      expect(cache.statistics.misses, equals(2));
    });

    test('should track sets', () async {
      await cache.set('key1', 'value1');
      await cache.set('key2', 'value2');

      expect(cache.statistics.sets, equals(2));
    });

    test('should track deletes', () async {
      await cache.set('key1', 'value1');
      await cache.delete('key1');
      await cache.delete('key2');

      expect(cache.statistics.deletes, equals(2));
    });

    test('should track setMany operations', () async {
      await cache.setMany({
        'key1': 'value1',
        'key2': 'value2',
        'key3': 'value3',
      });

      expect(cache.statistics.sets, equals(3));
    });

    test('should track deleteMany operations', () async {
      await cache.deleteMany(['key1', 'key2']);

      expect(cache.statistics.deletes, equals(2));
    });

    test('should delegate all operations to backend', () async {
      await cache.set('key1', 'value1');
      expect(await cache.get<String>('key1'), equals('value1'));

      expect(await cache.exists('key1'), isTrue);
      expect(await cache.size(), equals(1));

      final keys = await cache.keys();
      expect(keys, contains('key1'));

      await cache.delete('key1');
      expect(await cache.get<String>('key1'), isNull);
    });

    test('should handle all cache operations', () async {
      await cache.setMany({'key1': 'value1', 'key2': 'value2'});

      final values = await cache.getMany<String>(['key1', 'key2']);
      expect(values, hasLength(2));

      await cache.touch('key1');
      expect(await cache.increment('counter'), equals(1));
      expect(await cache.decrement('counter'), equals(0));

      await cache.expire('key1', const Duration(seconds: 10));
      final ttl = await cache.ttl('key1');
      expect(ttl, isNotNull);

      final value = await cache.getOrSet('key3', () async => 'value3');
      expect(value, equals('value3'));
    });
  });

  group('CacheBackend serialization', () {
    late InMemoryCache cache;

    setUp(() {
      cache = InMemoryCache();
    });

    test('should serialize and deserialize strings', () {
      final serialized = cache.serialize('hello');
      final deserialized = cache.deserialize<String>(serialized);
      expect(deserialized, equals('hello'));
    });

    test('should serialize and deserialize numbers', () {
      final serialized = cache.serialize(42);
      final deserialized = cache.deserialize<int>(serialized);
      expect(deserialized, equals(42));
    });

    test('should serialize and deserialize maps', () {
      final data = {'key': 'value', 'nested': {'inner': 'data'}};
      final serialized = cache.serialize(data);
      final deserialized = cache.deserialize<Map<String, dynamic>>(serialized);
      expect(deserialized, equals(data));
    });

    test('should serialize and deserialize lists', () {
      final data = [1, 2, 3, 'four', {'five': 5}];
      final serialized = cache.serialize(data);
      final deserialized = cache.deserialize<List>(serialized);
      expect(deserialized, equals(data));
    });

    test('should handle deserialization errors', () {
      final deserialized = cache.deserialize<String>('invalid-json{');
      expect(deserialized, isNull);
    });
  });

  group('CacheEntry', () {
    test('should create cache entry with expiry', () {
      final expiry = DateTime.now().add(const Duration(seconds: 10));
      final entry = CacheEntry('value', expiry);

      expect(entry.value, equals('value'));
      expect(entry.expiry, equals(expiry));
      expect(entry.isExpired, isFalse);
    });

    test('should detect expired entries', () {
      final expiry = DateTime.now().subtract(const Duration(seconds: 1));
      final entry = CacheEntry('value', expiry);

      expect(entry.isExpired, isTrue);
    });

    test('should detect not expired entries', () async {
      final expiry = DateTime.now().add(const Duration(seconds: 1));
      final entry = CacheEntry('value', expiry);

      expect(entry.isExpired, isFalse);

      await Future.delayed(const Duration(milliseconds: 1100));
      expect(entry.isExpired, isTrue);
    });
  });
}
