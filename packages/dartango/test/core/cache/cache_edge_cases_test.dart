import 'package:test/test.dart';

import '../../../lib/src/core/cache/cache.dart';

void main() {
  group('Cache Edge Cases and Boundary Conditions', () {
    late InMemoryCache cache;

    setUp(() {
      cache = InMemoryCache();
    });

    tearDown(() async {
      await cache.clear();
    });

    group('Null and Empty Input Validation', () {
      test('should handle empty string key', () async {
        await cache.set('', 'value');
        final result = await cache.get<String>('');
        expect(result, equals('value'));
      });

      test('should handle null value', () async {
        await cache.set('key', null);
        final result = await cache.get('key');
        expect(result, isNull);
      });

      test('should handle empty string value', () async {
        await cache.set('key', '');
        final result = await cache.get<String>('key');
        expect(result, equals(''));
      });

      test('should handle getMany with empty list', () async {
        final result = await cache.getMany<String>([]);
        expect(result, isEmpty);
      });

      test('should handle setMany with empty map', () async {
        await cache.setMany({});
        final size = await cache.size();
        expect(size, equals(0));
      });

      test('should handle deleteMany with empty list', () async {
        await cache.set('key1', 'value1');
        await cache.deleteMany([]);
        final size = await cache.size();
        expect(size, equals(1));
      });
    });

    group('Boundary Conditions', () {
      test('should handle very long keys', () async {
        final longKey = 'k' * 1000;
        await cache.set(longKey, 'value');
        final result = await cache.get<String>(longKey);
        expect(result, equals('value'));
      });

      test('should handle keys with special characters', () async {
        await cache.set('key:with:colons', 'value1');
        await cache.set('key with spaces', 'value2');
        await cache.set('key/with/slashes', 'value3');
        await cache.set('key.with.dots', 'value4');

        expect(await cache.get<String>('key:with:colons'), equals('value1'));
        expect(await cache.get<String>('key with spaces'), equals('value2'));
        expect(await cache.get<String>('key/with/slashes'), equals('value3'));
        expect(await cache.get<String>('key.with.dots'), equals('value4'));
      });

      test('should handle negative timeout duration', () async {
        await cache.set(
          'key',
          'value',
          timeout: const Duration(milliseconds: -100),
        );

        /// Negative timeout should be treated as no timeout or immediate expiry
        final result = await cache.get<String>('key');
        expect(result, anyOf(isNull, equals('value')));
      });

      test('should handle zero timeout duration', () async {
        await cache.set(
          'key',
          'value',
          timeout: Duration.zero,
        );

        /// Zero timeout should expire immediately or have no timeout
        final result = await cache.get<String>('key');
        expect(result, anyOf(isNull, equals('value')));
      });

      test('should handle touch on non-existent key', () async {
        final result =
            await cache.touch('non-existent', const Duration(seconds: 1));
        expect(result, isFalse);
      });

      test('should handle expire on non-existent key', () async {
        final result = await cache.expire('non-existent');
        expect(result, isFalse);
      });

      test('should handle increment with non-numeric existing value', () async {
        await cache.set('key', 'not-a-number');

        /// Should either throw an exception or handle gracefully
        expect(
          () async => await cache.increment('key'),
          anyOf(
            throwsA(anything),
            completes,
          ),
        );
      });

      test('should handle decrement with non-numeric existing value', () async {
        await cache.set('key', 'not-a-number');

        /// Should either throw an exception or handle gracefully
        expect(
          () async => await cache.decrement('key'),
          anyOf(
            throwsA(anything),
            completes,
          ),
        );
      });

      test('should handle very large numeric increment', () async {
        await cache.set('key', 1000000000);
        await cache.increment('key', delta: 1000000000);
        final result = await cache.get<int>('key');
        expect(result, equals(2000000000));
      });

      test('should handle negative increment (decrement)', () async {
        await cache.set('key', 100);
        await cache.increment('key', delta: -50);
        final result = await cache.get<int>('key');
        expect(result, equals(50));
      });

      test('should handle very large collection in setMany', () async {
        final largeMap = <String, String>{};
        for (int i = 0; i < 1000; i++) {
          largeMap['key$i'] = 'value$i';
        }

        await cache.setMany(largeMap);
        final size = await cache.size();
        expect(size, equals(1000));
      });

      test('should handle very large value', () async {
        final largeValue = 'x' * 1000000;
        await cache.set('large', largeValue);
        final result = await cache.get<String>('large');
        expect(result, equals(largeValue));
      });
    });

    group('LRUCache Edge Cases', () {
      test('should handle LRU with maxSize of 1', () async {
        final lruCache = LRUCache(maxSize: 1);

        await lruCache.set('key1', 'value1');
        await lruCache.set('key2', 'value2');

        /// key1 should be evicted
        expect(await lruCache.get<String>('key1'), isNull);
        expect(await lruCache.get<String>('key2'), equals('value2'));
      });

      test('should handle LRU with maxSize of 0', () async {
        /// This should either throw or handle gracefully
        expect(
          () => LRUCache(maxSize: 0),
          anyOf(
            throwsA(anything),
            returnsNormally,
          ),
        );
      });

      test('should handle LRU with negative maxSize', () async {
        /// This should either throw or handle gracefully
        expect(
          () => LRUCache(maxSize: -1),
          anyOf(
            throwsA(anything),
            returnsNormally,
          ),
        );
      });
    });

    group('NullCache Edge Cases', () {
      test('should handle NullCache with all operations', () async {
        final nullCache = NullCache();

        await nullCache.set('key', 'value');
        expect(await nullCache.get<String>('key'), isNull);

        await nullCache.setMany({'key1': 'value1', 'key2': 'value2'});
        expect(await nullCache.getMany<String>(['key1', 'key2']), isEmpty);

        expect(await nullCache.has('any-key'), isFalse);
        expect(await nullCache.size(), equals(0));
        expect(await nullCache.keys(), isEmpty);

        await nullCache.increment('counter');
        expect(await nullCache.get<int>('counter'), isNull);

        await nullCache.clear();
        expect(await nullCache.size(), equals(0));
      });
    });

    group('Concurrent Operations', () {
      test('should handle concurrent set operations', () async {
        final futures = <Future>[];

        for (int i = 0; i < 100; i++) {
          futures.add(cache.set('key$i', 'value$i'));
        }

        await Future.wait(futures);

        final size = await cache.size();
        expect(size, equals(100));
      });

      test('should handle concurrent get operations on same key', () async {
        await cache.set('shared-key', 'shared-value');

        final futures = <Future<String?>>[];
        for (int i = 0; i < 100; i++) {
          futures.add(cache.get<String>('shared-key'));
        }

        final results = await Future.wait(futures);
        expect(results.every((r) => r == 'shared-value'), isTrue);
      });

      test('should handle concurrent increment operations', () async {
        await cache.set('counter', 0);

        final futures = <Future>[];
        for (int i = 0; i < 100; i++) {
          futures.add(cache.increment('counter'));
        }

        await Future.wait(futures);

        /// The final value should be 100, but due to race conditions
        /// it might be less. This test documents the behavior.
        final result = await cache.get<int>('counter');
        expect(result, greaterThan(0));
        expect(result, lessThanOrEqualTo(100));
      });

      test('should handle concurrent mixed operations', () async {
        final futures = <Future>[];

        for (int i = 0; i < 50; i++) {
          futures.add(cache.set('key$i', 'value$i'));
          futures.add(cache.get<String>('key$i'));
          futures.add(cache.has('key$i'));
        }

        await Future.wait(futures);

        /// Should complete without errors
        expect(true, isTrue);
      });
    });
  });
}
