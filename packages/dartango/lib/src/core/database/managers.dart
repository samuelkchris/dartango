import 'dart:async';

import 'connection.dart';
import 'models.dart';
import 'queryset.dart';

abstract class BaseManager<T extends Model> {
  final Model _model;
  final String _tableName;
  final String? _database;
  
  BaseManager(this._model) 
      : _tableName = _model.tableName,
        _database = _model.database;

  Type get modelType => T;
  String get tableName => _tableName;
  String? get database => _database;

  QuerySet<T> getQuerySet() {
    return QuerySet<T>(T, _tableName, _database);
  }

  // Filtering methods
  QuerySet<T> all() => getQuerySet();
  QuerySet<T> filter(Map<String, dynamic> filters) => getQuerySet().filter(filters);
  QuerySet<T> exclude(Map<String, dynamic> filters) => getQuerySet().exclude(filters);
  QuerySet<T> where(String condition, [List<dynamic>? parameters]) => getQuerySet().where(condition, parameters);

  // Ordering methods
  QuerySet<T> orderBy(List<String> fields) => getQuerySet().orderBy(fields);
  QuerySet<T> reverse() => getQuerySet().reverse();

  // Slicing methods
  QuerySet<T> limit(int count) => getQuerySet().limit(count);
  QuerySet<T> offset(int count) => getQuerySet().offset(count);
  QuerySet<T> slice(int start, [int? end]) => getQuerySet().slice(start, end);

  // Field selection methods
  QuerySet<T> only(List<String> fields) => getQuerySet().only(fields);
  QuerySet<T> defer(List<String> fields) => getQuerySet().defer(fields);
  QuerySet<T> selectValues(List<String> fields) => getQuerySet().only(fields);
  QuerySet<T> selectValuesList(List<String> fields, {bool flat = false}) => getQuerySet().only(fields);

  // Distinct methods
  QuerySet<T> distinct([List<String>? fields]) => getQuerySet().distinct(fields);

  // Relationship methods
  QuerySet<T> selectRelated(List<String> fields) => getQuerySet().selectRelated(fields);
  QuerySet<T> prefetchRelated(List<String> fields) => getQuerySet().prefetchRelated(fields);

  // Aggregation methods
  QuerySet<T> annotate(Map<String, dynamic> annotations) => getQuerySet().annotate(annotations);
  Future<Map<String, dynamic>> aggregate(Map<String, String> aggregations) => getQuerySet().aggregate(aggregations);

  // Execution methods
  Future<T?> first() => getQuerySet().first();
  Future<T?> last() => getQuerySet().last();
  Future<T> get(Map<String, dynamic> filters) => getQuerySet().get(filters);
  Future<T?> getOrNull(Map<String, dynamic> filters) => getQuerySet().getOrNull(filters);
  Future<T> getOrCreate(Map<String, dynamic> filters, {Map<String, dynamic>? defaults}) => getQuerySet().getOrCreate(filters, defaults: defaults);
  Future<MapEntry<T, bool>> updateOrCreate(Map<String, dynamic> filters, {Map<String, dynamic>? defaults}) => getQuerySet().updateOrCreate(filters, defaults: defaults);

  // Existence methods
  Future<bool> exists() => getQuerySet().exists();

  // Counting methods
  Future<int> count() => getQuerySet().count();

  // Modification methods
  Future<int> update(Map<String, dynamic> values) => getQuerySet().update(values);
  Future<int> delete() => getQuerySet().delete();

  // Bulk operations
  Future<List<T>> bulkCreate(List<Map<String, dynamic>> dataList, {int batchSize = 1000}) => getQuerySet().bulkCreate(dataList, batchSize: batchSize);
  Future<int> bulkUpdate(List<Map<String, dynamic>> dataList, List<String> updateFields, {int batchSize = 1000}) => getQuerySet().bulkUpdate(dataList, updateFields, batchSize: batchSize);

  // Raw SQL methods
  Future<List<T>> raw(String sql, [List<dynamic>? parameters]) async {
    final connection = await DatabaseRouter.getConnection(_database);
    try {
      final results = await connection.query(sql, parameters);
      return results.map((data) => _createModelFromData(data)).toList();
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  // Utility methods
  Future<List<dynamic>> getValuesList(List<String> fields, {bool flat = false}) => getQuerySet().valuesList(fields, flat: flat);
  Future<List<Map<String, dynamic>>> getValues(List<String> fields) => getQuerySet().values(fields);

  // Private helper methods
  T _createModelFromData(Map<String, dynamic> data) {
    // In a real implementation, this would use reflection to create the model
    return (T as dynamic).fromMap(data) as T;
  }

  // Model creation methods
  Future<T> create(Map<String, dynamic> data) async {
    final model = _createModelFromData(data);
    await model.save();
    return model;
  }

  T build(Map<String, dynamic> data) {
    return _createModelFromData(data);
  }

  // Transaction methods
  Future<R> transaction<R>(Future<R> Function() callback) async {
    final connection = await DatabaseRouter.getConnection(_database);
    try {
      return await connection.transaction<R>((conn) async {
        return await callback();
      });
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  // Custom query methods (to be overridden in subclasses)
  QuerySet<T> getQuerySetForUser(dynamic user) {
    // Override in subclasses to provide user-specific filtering
    return getQuerySet();
  }

  QuerySet<T> getQuerySetForSite(dynamic site) {
    // Override in subclasses to provide site-specific filtering
    return getQuerySet();
  }

  // Introspection methods
  Future<List<String>> getTableNames() async {
    final connection = await DatabaseRouter.getConnection(_database);
    try {
      return await connection.getTableNames();
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  Future<List<Map<String, dynamic>>> getTableSchema() async {
    final connection = await DatabaseRouter.getConnection(_database);
    try {
      return await connection.getTableSchema(_tableName);
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  Future<List<Map<String, dynamic>>> getIndexes() async {
    final connection = await DatabaseRouter.getConnection(_database);
    try {
      return await connection.getIndexes(_tableName);
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  // Iterator support
  Stream<T> stream() => getQuerySet().stream();
}

class Manager<T extends Model> extends BaseManager<T> {
  Manager(Model model) : super(model);
}

// Custom managers for specific use cases
class PublishedManager<T extends Model> extends BaseManager<T> {
  PublishedManager(Model model) : super(model);

  @override
  QuerySet<T> getQuerySet() {
    return super.getQuerySet().filter({'published': true});
  }
}

class ActiveManager<T extends Model> extends BaseManager<T> {
  ActiveManager(Model model) : super(model);

  @override
  QuerySet<T> getQuerySet() {
    return super.getQuerySet().filter({'active': true});
  }
}

class SoftDeleteManager<T extends Model> extends BaseManager<T> {
  SoftDeleteManager(Model model) : super(model);

  @override
  QuerySet<T> getQuerySet() {
    return super.getQuerySet().filter({'deleted_at__isnull': true});
  }

  QuerySet<T> withDeleted() {
    return super.getQuerySet();
  }

  QuerySet<T> onlyDeleted() {
    return super.getQuerySet().filter({'deleted_at__isnull': false});
  }

  Future<int> restore() async {
    return await getQuerySet().update({'deleted_at': null});
  }

  Future<int> forceDelete() async {
    return await withDeleted().delete();
  }
}

class TimestampedManager<T extends Model> extends BaseManager<T> {
  TimestampedManager(Model model) : super(model);

  QuerySet<T> recent({int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return getQuerySet().filter({'created_at__gte': cutoff});
  }

  QuerySet<T> olderthan({int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return getQuerySet().filter({'created_at__lt': cutoff});
  }

  QuerySet<T> today() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return getQuerySet().filter({
      'created_at__gte': startOfDay,
      'created_at__lt': endOfDay,
    });
  }

  QuerySet<T> thisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    
    return getQuerySet().filter({
      'created_at__gte': startOfWeek,
      'created_at__lt': endOfWeek,
    });
  }

  QuerySet<T> thisMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    
    return getQuerySet().filter({
      'created_at__gte': startOfMonth,
      'created_at__lt': endOfMonth,
    });
  }

  QuerySet<T> thisYear() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year + 1, 1, 1);
    
    return getQuerySet().filter({
      'created_at__gte': startOfYear,
      'created_at__lt': endOfYear,
    });
  }
}

class HierarchicalManager<T extends Model> extends BaseManager<T> {
  HierarchicalManager(Model model) : super(model);

  QuerySet<T> roots() {
    return getQuerySet().filter({'parent__isnull': true});
  }

  QuerySet<T> leaves() {
    // In a real implementation, this would use subqueries
    return getQuerySet();
  }

  QuerySet<T> ancestors(dynamic nodeId) {
    // In a real implementation, this would traverse the hierarchy
    return getQuerySet();
  }

  QuerySet<T> descendants(dynamic nodeId) {
    // In a real implementation, this would traverse the hierarchy
    return getQuerySet();
  }

  QuerySet<T> siblings(dynamic nodeId) {
    return getQuerySet().filter({'parent': nodeId});
  }

  QuerySet<T> children(dynamic nodeId) {
    return getQuerySet().filter({'parent': nodeId});
  }
}

class GeoManager<T extends Model> extends BaseManager<T> {
  GeoManager(Model model) : super(model);

  QuerySet<T> withinDistance(double latitude, double longitude, double distanceKm) {
    // In a real implementation, this would use PostGIS or similar
    return getQuerySet();
  }

  QuerySet<T> withinBounds(double northLat, double southLat, double eastLng, double westLng) {
    return getQuerySet().filter({
      'latitude__gte': southLat,
      'latitude__lte': northLat,
      'longitude__gte': westLng,
      'longitude__lte': eastLng,
    });
  }

  QuerySet<T> orderByDistance(double latitude, double longitude) {
    // In a real implementation, this would calculate distance
    return getQuerySet();
  }
}

class TaggedManager<T extends Model> extends BaseManager<T> {
  TaggedManager(Model model) : super(model);

  QuerySet<T> withTag(String tag) {
    return getQuerySet().filter({'tags__name': tag});
  }

  QuerySet<T> withTags(List<String> tags) {
    return getQuerySet().filter({'tags__name__in': tags});
  }

  QuerySet<T> withAllTags(List<String> tags) {
    QuerySet<T> qs = getQuerySet();
    for (final tag in tags) {
      qs = qs.filter({'tags__name': tag});
    }
    return qs;
  }

  QuerySet<T> withoutTag(String tag) {
    return getQuerySet().exclude({'tags__name': tag});
  }

  QuerySet<T> withoutTags(List<String> tags) {
    return getQuerySet().exclude({'tags__name__in': tags});
  }
}

class VersionedManager<T extends Model> extends BaseManager<T> {
  VersionedManager(Model model) : super(model);

  QuerySet<T> currentVersion() {
    return getQuerySet().filter({'is_current': true});
  }

  QuerySet<T> allVersions() {
    return getQuerySet();
  }

  QuerySet<T> versionHistory(dynamic objectId) {
    return getQuerySet().filter({'object_id': objectId}).orderBy(['-version']);
  }

  Future<T?> getVersion(dynamic objectId, int version) async {
    return await getQuerySet().getOrNull({'object_id': objectId, 'version': version});
  }

  Future<T?> getLatestVersion(dynamic objectId) async {
    return await getQuerySet().filter({'object_id': objectId}).orderBy(['-version']).first();
  }
}

class CachedManager<T extends Model> extends BaseManager<T> {
  final Duration _cacheTimeout;
  final Map<String, CacheEntry<List<T>>> _cache = {};

  CachedManager(Model model, {Duration cacheTimeout = const Duration(minutes: 5)})
      : _cacheTimeout = cacheTimeout,
        super(model);

  @override
  QuerySet<T> getQuerySet() {
    return super.getQuerySet().cache();
  }

  Future<List<T>> getCached(String cacheKey, Future<List<T>> Function() fetchFn) async {
    final entry = _cache[cacheKey];
    if (entry != null && !entry.isExpired) {
      return entry.value;
    }

    final result = await fetchFn();
    _cache[cacheKey] = CacheEntry(result, DateTime.now().add(_cacheTimeout));
    return result;
  }

  void clearCache([String? cacheKey]) {
    if (cacheKey != null) {
      _cache.remove(cacheKey);
    } else {
      _cache.clear();
    }
  }

  void cleanupExpiredCache() {
    _cache.removeWhere((key, entry) => entry.isExpired);
  }
}

class CacheEntry<T> {
  final T value;
  final DateTime expiresAt;

  CacheEntry(this.value, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

// Manager registry for tracking custom managers
class ManagerRegistry {
  static final Map<Type, List<BaseManager>> _managers = {};

  static void register<T extends Model>(Type modelType, BaseManager<T> manager) {
    _managers.putIfAbsent(modelType, () => []).add(manager);
  }

  static List<BaseManager> getManagers(Type modelType) {
    return _managers[modelType] ?? [];
  }

  static BaseManager<T>? getManager<T extends Model>(Type modelType, String name) {
    final managers = getManagers(modelType);
    for (final manager in managers) {
      if (manager.runtimeType.toString().toLowerCase().contains(name.toLowerCase())) {
        return manager as BaseManager<T>;
      }
    }
    return null;
  }

  static void clear() {
    _managers.clear();
  }
}

// Manager mixins for common functionality
mixin TimestampMixin<T extends Model> on BaseManager<T> {
  QuerySet<T> recent({int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return getQuerySet().filter({'created_at__gte': cutoff});
  }

  QuerySet<T> today() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return getQuerySet().filter({
      'created_at__gte': startOfDay,
      'created_at__lt': endOfDay,
    });
  }
}

mixin SoftDeleteMixin<T extends Model> on BaseManager<T> {
  QuerySet<T> withDeleted() {
    return super.getQuerySet();
  }

  QuerySet<T> onlyDeleted() {
    return super.getQuerySet().filter({'deleted_at__isnull': false});
  }

  Future<int> restore() async {
    return await getQuerySet().update({'deleted_at': null});
  }
}

mixin PublishedMixin<T extends Model> on BaseManager<T> {
  QuerySet<T> published() {
    return getQuerySet().filter({'published': true});
  }

  QuerySet<T> unpublished() {
    return getQuerySet().filter({'published': false});
  }

  QuerySet<T> draft() {
    return getQuerySet().filter({'status': 'draft'});
  }
}

mixin ActiveMixin<T extends Model> on BaseManager<T> {
  QuerySet<T> active() {
    return getQuerySet().filter({'active': true});
  }

  QuerySet<T> inactive() {
    return getQuerySet().filter({'active': false});
  }
}

// Custom manager builder
class ManagerBuilder<T extends Model> {
  final Model _model;
  final List<QuerySet<T> Function(QuerySet<T>)> _filters = [];
  final List<String> _defaultOrdering = [];
  
  ManagerBuilder(this._model);

  ManagerBuilder<T> filter(Map<String, dynamic> filters) {
    _filters.add((qs) => qs.filter(filters));
    return this;
  }

  ManagerBuilder<T> exclude(Map<String, dynamic> filters) {
    _filters.add((qs) => qs.exclude(filters));
    return this;
  }

  ManagerBuilder<T> orderBy(List<String> fields) {
    _defaultOrdering.addAll(fields);
    return this;
  }

  BaseManager<T> build() {
    return _CustomManager<T>(_model, _filters, _defaultOrdering);
  }
}

class _CustomManager<T extends Model> extends BaseManager<T> {
  final List<QuerySet<T> Function(QuerySet<T>)> _filters;
  final List<String> _defaultOrdering;

  _CustomManager(Model model, this._filters, this._defaultOrdering) : super(model);

  @override
  QuerySet<T> getQuerySet() {
    QuerySet<T> qs = super.getQuerySet();
    
    for (final filter in _filters) {
      qs = filter(qs);
    }
    
    if (_defaultOrdering.isNotEmpty) {
      qs = qs.orderBy(_defaultOrdering);
    }
    
    return qs;
  }
}