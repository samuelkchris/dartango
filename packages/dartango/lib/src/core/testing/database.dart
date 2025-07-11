import 'dart:async';

import '../database/models.dart';

class TestDatabaseMixin {
  static final Map<Type, List<Model>> _fixtures = {};
  static final Map<Type, int> _counters = {};

  static void loadFixtures<T extends Model>(List<T> fixtures) {
    _fixtures[T] = fixtures.cast<Model>();
  }

  static void clearFixtures<T extends Model>() {
    _fixtures.remove(T);
  }

  static void clearAllFixtures() {
    _fixtures.clear();
    _counters.clear();
  }

  static List<T> getFixtures<T extends Model>() {
    return (_fixtures[T] ?? []).cast<T>();
  }

  static T createFixture<T extends Model>(
    T Function() factory,
    Map<String, dynamic> overrides,
  ) {
    final instance = factory();

    for (final entry in overrides.entries) {
      instance.setField(entry.key, entry.value);
    }

    final counter = _counters[T] ?? 0;
    _counters[T] = counter + 1;

    if (!Model.hasField(T, 'id') || instance.getField('id') == null) {
      instance.setField('id', counter + 1);
    }

    _fixtures.putIfAbsent(T, () => []).add(instance);

    return instance;
  }

  static Future<T> saveFixture<T extends Model>(T instance) async {
    await instance.save();
    return instance;
  }

  static Future<void> deleteFixture<T extends Model>(T instance) async {
    await instance.delete();
    _fixtures[T]?.remove(instance);
  }
}

class TestTransactionContext {
  final Map<Type, List<Model>> _originalFixtures = {};
  final Map<Type, int> _originalCounters = {};
  bool _isActive = false;

  void begin() {
    if (_isActive) {
      throw StateError('Transaction already active');
    }

    for (final entry in TestDatabaseMixin._fixtures.entries) {
      _originalFixtures[entry.key] = List.from(entry.value);
    }

    for (final entry in TestDatabaseMixin._counters.entries) {
      _originalCounters[entry.key] = entry.value;
    }

    _isActive = true;
  }

  void commit() {
    if (!_isActive) {
      throw StateError('No active transaction');
    }

    _originalFixtures.clear();
    _originalCounters.clear();
    _isActive = false;
  }

  void rollback() {
    if (!_isActive) {
      throw StateError('No active transaction');
    }

    TestDatabaseMixin._fixtures.clear();
    TestDatabaseMixin._counters.clear();

    for (final entry in _originalFixtures.entries) {
      TestDatabaseMixin._fixtures[entry.key] = List.from(entry.value);
    }

    for (final entry in _originalCounters.entries) {
      TestDatabaseMixin._counters[entry.key] = entry.value;
    }

    _originalFixtures.clear();
    _originalCounters.clear();
    _isActive = false;
  }

  bool get isActive => _isActive;
}

Future<T> runInTestTransaction<T>(Future<T> Function() operation) async {
  final transaction = TestTransactionContext();
  transaction.begin();

  try {
    final result = await operation();
    transaction.commit();
    return result;
  } catch (e) {
    transaction.rollback();
    rethrow;
  }
}

class ModelNotFoundException implements Exception {
  final String message;
  const ModelNotFoundException(this.message);

  @override
  String toString() => 'ModelNotFoundException: $message';
}

class MultipleObjectsReturnedException implements Exception {
  final String message;
  const MultipleObjectsReturnedException(this.message);

  @override
  String toString() => 'MultipleObjectsReturnedException: $message';
}
