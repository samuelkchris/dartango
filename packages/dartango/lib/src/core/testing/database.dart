import 'dart:async';

import '../database/model.dart';
import '../database/queryset.dart';
import '../database/manager.dart';

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

    if (!instance.hasField('id') || instance.getField('id') == null) {
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

class TestDatabaseQuerySet<T extends Model> extends QuerySet<T> {
  final List<T> _testData;

  TestDatabaseQuerySet(
    super.model,
    super.database, {
    List<T>? testData,
  }) : _testData = testData ?? [];

  @override
  Future<List<T>> execute() async {
    return _applyFilters(_testData);
  }

  @override
  Future<T?> first() async {
    final results = await execute();
    return results.isNotEmpty ? results.first : null;
  }

  @override
  Future<T> get([Map<String, dynamic>? filters]) async {
    if (filters != null) {
      for (final entry in filters.entries) {
        filter(entry.key, entry.value);
      }
    }

    final results = await execute();
    if (results.isEmpty) {
      throw ModelNotFoundException('$T matching query does not exist');
    }
    if (results.length > 1) {
      throw MultipleObjectsReturnedException('get() returned more than one $T');
    }
    return results.first;
  }

  @override
  Future<int> count() async {
    final results = await execute();
    return results.length;
  }

  @override
  Future<bool> exists() async {
    final count = await this.count();
    return count > 0;
  }

  List<T> _applyFilters(List<T> data) {
    var filtered = List<T>.from(data);

    for (final filter in _queryBuilder.filters) {
      filtered = filtered.where((instance) {
        return _matchesFilter(instance, filter);
      }).toList();
    }

    if (_queryBuilder.orderBy.isNotEmpty) {
      filtered.sort((a, b) {
        for (final orderField in _queryBuilder.orderBy) {
          final fieldName =
              orderField.startsWith('-') ? orderField.substring(1) : orderField;
          final descending = orderField.startsWith('-');

          final aValue = a.getField(fieldName);
          final bValue = b.getField(fieldName);

          int comparison = _compareValues(aValue, bValue);
          if (comparison != 0) {
            return descending ? -comparison : comparison;
          }
        }
        return 0;
      });
    }

    if (_queryBuilder.limitValue != null) {
      final start = _queryBuilder.offsetValue ?? 0;
      final end = start + _queryBuilder.limitValue!;
      filtered = filtered.sublist(
        start,
        end > filtered.length ? filtered.length : end,
      );
    }

    return filtered;
  }

  bool _matchesFilter(T instance, QueryFilter filter) {
    final value = instance.getField(filter.field);

    switch (filter.operation) {
      case FilterOperation.equals:
        return value == filter.value;
      case FilterOperation.notEquals:
        return value != filter.value;
      case FilterOperation.greaterThan:
        return _compareValues(value, filter.value) > 0;
      case FilterOperation.greaterThanOrEqual:
        return _compareValues(value, filter.value) >= 0;
      case FilterOperation.lessThan:
        return _compareValues(value, filter.value) < 0;
      case FilterOperation.lessThanOrEqual:
        return _compareValues(value, filter.value) <= 0;
      case FilterOperation.isIn:
        if (filter.value is List) {
          return (filter.value as List).contains(value);
        }
        return false;
      case FilterOperation.isNull:
        return value == null;
      case FilterOperation.isNotNull:
        return value != null;
      case FilterOperation.contains:
        if (value is String && filter.value is String) {
          return value.contains(filter.value);
        }
        return false;
      case FilterOperation.startsWith:
        if (value is String && filter.value is String) {
          return value.startsWith(filter.value);
        }
        return false;
      case FilterOperation.endsWith:
        if (value is String && filter.value is String) {
          return value.endsWith(filter.value);
        }
        return false;
      case FilterOperation.regex:
        if (value is String && filter.value is String) {
          final regex = RegExp(filter.value);
          return regex.hasMatch(value);
        }
        return false;
    }
  }

  int _compareValues(dynamic a, dynamic b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;

    if (a is Comparable && b is Comparable) {
      return Comparable.compare(a, b);
    }

    return a.toString().compareTo(b.toString());
  }
}

class TestModelManager<T extends Model> extends ModelManager<T> {
  TestModelManager(super.model, super.database);

  @override
  QuerySet<T> get all {
    final fixtures = TestDatabaseMixin.getFixtures<T>();
    return TestDatabaseQuerySet<T>(model, database, testData: fixtures);
  }

  @override
  QuerySet<T> filter(String field, dynamic value) {
    return all.filter(field, value);
  }

  @override
  QuerySet<T> exclude(String field, dynamic value) {
    return all.exclude(field, value);
  }

  @override
  Future<T?> find(dynamic id) async {
    final fixtures = TestDatabaseMixin.getFixtures<T>();
    try {
      return fixtures.firstWhere((instance) => instance.getField('id') == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<T> create(Map<String, dynamic> data) async {
    final instance = model.fromMap(data);
    final counter = TestDatabaseMixin._counters[T] ?? 0;
    TestDatabaseMixin._counters[T] = counter + 1;

    if (!instance.hasField('id') || instance.getField('id') == null) {
      instance.setField('id', counter + 1);
    }

    TestDatabaseMixin._fixtures.putIfAbsent(T, () => []).add(instance);
    return instance;
  }

  @override
  Future<T> updateOrCreate(
    Map<String, dynamic> defaults,
    Map<String, dynamic> conditions,
  ) async {
    final fixtures = TestDatabaseMixin.getFixtures<T>();

    for (final instance in fixtures) {
      bool matches = true;
      for (final entry in conditions.entries) {
        if (instance.getField(entry.key) != entry.value) {
          matches = false;
          break;
        }
      }

      if (matches) {
        for (final entry in defaults.entries) {
          instance.setField(entry.key, entry.value);
        }
        return instance;
      }
    }

    final data = Map<String, dynamic>.from(conditions);
    data.addAll(defaults);
    return await create(data);
  }

  @override
  Future<int> deleteWhere(Map<String, dynamic> conditions) async {
    final fixtures = TestDatabaseMixin._fixtures[T] ?? [];
    int deleted = 0;

    fixtures.removeWhere((instance) {
      bool matches = true;
      for (final entry in conditions.entries) {
        if (instance.getField(entry.key) != entry.value) {
          matches = false;
          break;
        }
      }
      if (matches) deleted++;
      return matches;
    });

    return deleted;
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
