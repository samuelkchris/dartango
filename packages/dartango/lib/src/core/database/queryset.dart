import 'dart:async';
import 'dart:math' as math;

import 'connection.dart';
import 'exceptions.dart';
import 'models.dart';
import 'query.dart';

class QuerySet<T extends Model> {
  final Type _modelType;
  final String _tableName;
  final String? _database;
  final QueryBuilder _queryBuilder;
  bool _resultCache = false;
  List<T>? _cachedResults;
  
  final List<String> _selectFields = [];
  final List<String> _selectRelated = [];
  final List<String> _prefetchRelated = [];
  final Map<String, dynamic> _annotations = {};
  final Map<String, String> _extra = {};
  bool _distinct = false;
  
  QuerySet(this._modelType, this._tableName, [this._database]) 
      : _queryBuilder = QueryBuilder().from(_tableName);
  
  QuerySet._clone(QuerySet<T> other)
      : _modelType = other._modelType,
        _tableName = other._tableName,
        _database = other._database,
        _queryBuilder = other._queryBuilder.clone() {
    _selectFields.addAll(other._selectFields);
    _selectRelated.addAll(other._selectRelated);
    _prefetchRelated.addAll(other._prefetchRelated);
    _annotations.addAll(other._annotations);
    _extra.addAll(other._extra);
    _distinct = other._distinct;
  }

  // Filtering methods
  QuerySet<T> filter(Map<String, dynamic> filters) {
    final clone = _clone();
    for (final entry in filters.entries) {
      final parts = entry.key.split('__');
      final fieldName = parts[0];
      final lookup = parts.length > 1 ? parts[1] : 'exact';
      
      clone._applyFilter(fieldName, lookup, entry.value);
    }
    return clone;
  }

  QuerySet<T> exclude(Map<String, dynamic> filters) {
    final clone = _clone();
    final conditions = <String>[];
    final parameters = <dynamic>[];
    
    for (final entry in filters.entries) {
      final parts = entry.key.split('__');
      final fieldName = parts[0];
      final lookup = parts.length > 1 ? parts[1] : 'exact';
      
      final condition = clone._buildCondition(fieldName, lookup, entry.value);
      conditions.add('NOT (${condition.condition})');
      parameters.addAll(condition.parameters);
    }
    
    if (conditions.isNotEmpty) {
      clone._queryBuilder.where(conditions.join(' AND '), parameters);
    }
    
    return clone;
  }

  QuerySet<T> where(String condition, [List<dynamic>? parameters]) {
    final clone = _clone();
    clone._queryBuilder.where(condition, parameters);
    return clone;
  }

  // Ordering methods
  QuerySet<T> orderBy(List<String> fields) {
    final clone = _clone();
    clone._queryBuilder.orderByFields.clear();
    
    for (final field in fields) {
      if (field.startsWith('-')) {
        clone._queryBuilder.orderByDesc(field.substring(1));
      } else {
        clone._queryBuilder.orderBy(field);
      }
    }
    
    return clone;
  }

  QuerySet<T> reverse() {
    final clone = _clone();
    final currentOrdering = clone._queryBuilder.orderByFields.toList();
    clone._queryBuilder.orderByFields.clear();
    
    for (final order in currentOrdering) {
      if (order.endsWith(' DESC')) {
        final field = order.substring(0, order.length - 5);
        clone._queryBuilder.orderBy(field);
      } else if (order.endsWith(' ASC')) {
        final field = order.substring(0, order.length - 4);
        clone._queryBuilder.orderByDesc(field);
      }
    }
    
    return clone;
  }

  // Slicing methods
  QuerySet<T> limit(int count) {
    final clone = _clone();
    clone._queryBuilder.limit(count);
    return clone;
  }

  QuerySet<T> offset(int count) {
    final clone = _clone();
    clone._queryBuilder.offset(count);
    return clone;
  }

  QuerySet<T> slice(int start, [int? end]) {
    final clone = _clone();
    clone._queryBuilder.offset(start);
    if (end != null) {
      clone._queryBuilder.limit(end - start);
    }
    return clone;
  }

  // Field selection methods
  QuerySet<T> only(List<String> fields) {
    final clone = _clone();
    clone._selectFields.clear();
    clone._selectFields.addAll(fields);
    clone._queryBuilder.select(fields);
    return clone;
  }

  QuerySet<T> defer(List<String> fields) {
    final clone = _clone();
    final allFields = Model.getFieldNames(_modelType);
    final selectedFields = allFields.where((field) => !fields.contains(field)).toList();
    
    clone._selectFields.clear();
    clone._selectFields.addAll(selectedFields);
    clone._queryBuilder.select(selectedFields);
    return clone;
  }

  QuerySet<T> values(List<String> fields) {
    final clone = _clone();
    clone._selectFields.clear();
    clone._selectFields.addAll(fields);
    clone._queryBuilder.select(fields);
    return clone;
  }

  QuerySet<T> valuesList(List<String> fields, {bool flat = false}) {
    final clone = _clone();
    clone._selectFields.clear();
    clone._selectFields.addAll(fields);
    clone._queryBuilder.select(fields);
    return clone;
  }

  // Distinct methods
  QuerySet<T> distinct([List<String>? fields]) {
    final clone = _clone();
    clone._distinct = true;
    
    if (fields != null && fields.isNotEmpty) {
      // PostgreSQL supports DISTINCT ON
      final distinctFields = fields.join(', ');
      clone._queryBuilder.selectFields.clear();
      clone._queryBuilder.selectFields.add('DISTINCT ON ($distinctFields) *');
    } else {
      clone._queryBuilder.selectFields.clear();
      clone._queryBuilder.selectFields.add('DISTINCT *');
    }
    
    return clone;
  }

  // Relationship methods
  QuerySet<T> selectRelated(List<String> fields) {
    final clone = _clone();
    clone._selectRelated.addAll(fields);
    
    for (final field in fields) {
      // In a real implementation, this would add JOIN clauses
      clone._queryBuilder.leftJoin('${field}_table', '${_tableName}.${field}_id = ${field}_table.id');
    }
    
    return clone;
  }

  QuerySet<T> prefetchRelated(List<String> fields) {
    final clone = _clone();
    clone._prefetchRelated.addAll(fields);
    return clone;
  }

  // Aggregation methods
  QuerySet<T> annotate(Map<String, dynamic> annotations) {
    final clone = _clone();
    clone._annotations.addAll(annotations);
    
    for (final entry in annotations.entries) {
      // In a real implementation, this would handle aggregation functions
      clone._queryBuilder.select(['${entry.value} as ${entry.key}']);
    }
    
    return clone;
  }

  Future<Map<String, dynamic>> aggregate(Map<String, String> aggregations) async {
    final clone = _clone();
    final selectFields = <String>[];
    
    for (final entry in aggregations.entries) {
      selectFields.add('${entry.value} as ${entry.key}');
    }
    
    clone._queryBuilder.select(selectFields);
    
    final connection = await DatabaseRouter.getConnection(_database);
    try {
      final result = await connection.query(clone._queryBuilder.toSql(), clone._queryBuilder.parameters);
      return result.isNotEmpty ? result.first : {};
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  // Grouping methods
  QuerySet<T> groupBy(List<String> fields) {
    final clone = _clone();
    clone._queryBuilder.groupBy(fields);
    return clone;
  }

  QuerySet<T> having(String condition, [List<dynamic>? parameters]) {
    final clone = _clone();
    clone._queryBuilder.having(condition, parameters);
    return clone;
  }

  // Extra methods
  QuerySet<T> extra({
    List<String>? select,
    String? where,
    List<dynamic>? params,
    List<String>? tables,
    List<String>? orderBy,
  }) {
    final clone = _clone();
    
    if (select != null) {
      for (final field in select) {
        clone._queryBuilder.select([field]);
      }
    }
    
    if (where != null) {
      clone._queryBuilder.where(where, params);
    }
    
    if (tables != null) {
      for (final table in tables) {
        clone._queryBuilder.from(table);
      }
    }
    
    if (orderBy != null) {
      for (final field in orderBy) {
        clone._queryBuilder.orderBy(field);
      }
    }
    
    return clone;
  }

  // Raw SQL methods
  QuerySet<T> raw(String sql, [List<dynamic>? parameters]) {
    final clone = _clone();
    // In a real implementation, this would handle raw SQL
    return clone;
  }

  // Union methods
  QuerySet<T> union(QuerySet<T> other, {bool all = false}) {
    final clone = _clone();
    Union([clone._queryBuilder, other._queryBuilder], all: all);
    return clone;
  }

  QuerySet<T> intersection(QuerySet<T> other) {
    final clone = _clone();
    // In a real implementation, this would handle intersection
    return clone;
  }

  QuerySet<T> difference(QuerySet<T> other) {
    final clone = _clone();
    // In a real implementation, this would handle difference
    return clone;
  }

  // Execution methods
  Future<List<T>> all() async {
    if (_cachedResults != null && _resultCache) {
      return _cachedResults!;
    }
    
    final connection = await DatabaseRouter.getConnection(_database);
    try {
      final results = await connection.query(_queryBuilder.toSql(), _queryBuilder.parameters);
      final models = results.map((data) => _createModelFromData(data)).toList();
      
      if (_resultCache) {
        _cachedResults = models;
      }
      
      // Handle prefetch_related
      if (_prefetchRelated.isNotEmpty) {
        await _handlePrefetchRelated(models);
      }
      
      return models;
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  Future<T?> first() async {
    final clone = _clone();
    clone._queryBuilder.limit(1);
    
    final results = await clone.all();
    return results.isNotEmpty ? results.first : null;
  }

  Future<T?> last() async {
    final clone = _clone();
    clone._queryBuilder.limit(1);
    
    // Reverse the ordering
    final currentOrdering = clone._queryBuilder.orderByFields.toList();
    clone._queryBuilder.orderByFields.clear();
    
    for (final order in currentOrdering) {
      if (order.endsWith(' DESC')) {
        final field = order.substring(0, order.length - 5);
        clone._queryBuilder.orderBy(field);
      } else if (order.endsWith(' ASC')) {
        final field = order.substring(0, order.length - 4);
        clone._queryBuilder.orderByDesc(field);
      }
    }
    
    final results = await clone.all();
    return results.isNotEmpty ? results.first : null;
  }

  Future<T> get(Map<String, dynamic> filters) async {
    final clone = filter(filters);
    final results = await clone.all();
    
    if (results.isEmpty) {
      throw DoesNotExistException('${_modelType.toString()} matching query does not exist');
    }
    
    if (results.length > 1) {
      throw MultipleObjectsReturnedException('${_modelType.toString()} query returned multiple objects');
    }
    
    return results.first;
  }

  Future<T?> getOrNull(Map<String, dynamic> filters) async {
    try {
      return await get(filters);
    } on DoesNotExistException {
      return null;
    }
  }

  Future<T> getOrCreate(Map<String, dynamic> filters, {Map<String, dynamic>? defaults}) async {
    try {
      return await get(filters);
    } on DoesNotExistException {
      final createData = Map<String, dynamic>.from(filters);
      if (defaults != null) {
        createData.addAll(defaults);
      }
      
      final model = _createModelFromData(createData);
      await model.save();
      return model;
    }
  }

  Future<MapEntry<T, bool>> updateOrCreate(Map<String, dynamic> filters, {Map<String, dynamic>? defaults}) async {
    try {
      final existing = await get(filters);
      if (defaults != null) {
        for (final entry in defaults.entries) {
          existing.setField(entry.key, entry.value);
        }
        await existing.save();
      }
      return MapEntry(existing, false);
    } on DoesNotExistException {
      final createData = Map<String, dynamic>.from(filters);
      if (defaults != null) {
        createData.addAll(defaults);
      }
      
      final model = _createModelFromData(createData);
      await model.save();
      return MapEntry(model, true);
    }
  }

  // Existence methods
  Future<bool> exists() async {
    final clone = _clone();
    clone._queryBuilder.select(['1']);
    clone._queryBuilder.limit(1);
    
    final connection = await DatabaseRouter.getConnection(_database);
    try {
      final result = await connection.query(clone._queryBuilder.toSql(), clone._queryBuilder.parameters);
      return result.isNotEmpty;
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  // Counting methods
  Future<int> count() async {
    final clone = _clone();
    clone._queryBuilder.select(['COUNT(*) as count']);
    clone._queryBuilder.limitValue = null;
    clone._queryBuilder.offsetValue = null;
    
    final connection = await DatabaseRouter.getConnection(_database);
    try {
      final result = await connection.query(clone._queryBuilder.toSql(), clone._queryBuilder.parameters);
      return result.first['count'] as int;
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  // Modification methods
  Future<int> update(Map<String, dynamic> values) async {
    final connection = await DatabaseRouter.getConnection(_database);
    try {
      final updateBuilder = UpdateQueryBuilder(_tableName).set(values);
      
      // Copy where conditions from the query builder
      for (final condition in _queryBuilder.whereConditions) {
        updateBuilder.where(condition);
      }
      
      final result = await connection.execute(updateBuilder.toSql(), updateBuilder.parameters);
      return result.affectedRows ?? 0;
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  Future<int> delete() async {
    final connection = await DatabaseRouter.getConnection(_database);
    try {
      final deleteBuilder = DeleteQueryBuilder(_tableName);
      
      // Copy where conditions from the query builder
      for (final condition in _queryBuilder.whereConditions) {
        deleteBuilder.where(condition);
      }
      
      final result = await connection.execute(deleteBuilder.toSql(), deleteBuilder.parameters);
      return result.affectedRows ?? 0;
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  // Bulk operations
  Future<List<T>> bulkCreate(List<Map<String, dynamic>> dataList, {int batchSize = 1000}) async {
    final connection = await DatabaseRouter.getConnection(_database);
    try {
      final batches = <List<Map<String, dynamic>>>[];
      for (int i = 0; i < dataList.length; i += batchSize) {
        final end = (i + batchSize < dataList.length) ? i + batchSize : dataList.length;
        batches.add(dataList.sublist(i, end));
      }
      
      final results = <T>[];
      for (final batch in batches) {
        final builder = InsertQueryBuilder(_tableName).bulkValues(batch);
        await connection.execute(builder.toSql(), builder.parameters);
        
        for (final data in batch) {
          results.add(_createModelFromData(data));
        }
      }
      
      return results;
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  Future<int> bulkUpdate(List<Map<String, dynamic>> dataList, List<String> updateFields, {int batchSize = 1000}) async {
    int updated = 0;
    
    final batches = <List<Map<String, dynamic>>>[];
    for (int i = 0; i < dataList.length; i += batchSize) {
      final end = (i + batchSize < dataList.length) ? i + batchSize : dataList.length;
      batches.add(dataList.sublist(i, end));
    }
    
    final connection = await DatabaseRouter.getConnection(_database);
    try {
      for (final batch in batches) {
        for (final data in batch) {
          final updateData = <String, dynamic>{};
          for (final field in updateFields) {
            if (data.containsKey(field)) {
              updateData[field] = data[field];
            }
          }
          
          final pkField = Model.getPrimaryKeyField(_modelType);
          final pkValue = data[pkField];
          
          if (pkValue != null) {
            final builder = UpdateQueryBuilder(_tableName)
                .set(updateData)
                .where('$pkField = ?', [pkValue]);
            
            final result = await connection.execute(builder.toSql(), builder.parameters);
            updated += result.affectedRows ?? 0;
          }
        }
      }
      
      return updated;
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  // Utility methods
  Future<List<dynamic>> getValuesList(List<String> fields, {bool flat = false}) async {
    final clone = _clone();
    clone._queryBuilder.select(fields);
    
    final connection = await DatabaseRouter.getConnection(_database);
    try {
      final results = await connection.query(clone._queryBuilder.toSql(), clone._queryBuilder.parameters);
      
      if (flat && fields.length == 1) {
        return results.map((row) => row[fields.first]).toList();
      }
      
      return results.map((row) => fields.map((field) => row[field]).toList()).toList();
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  Future<List<Map<String, dynamic>>> getValues(List<String> fields) async {
    final clone = _clone();
    clone._queryBuilder.select(fields);
    
    final connection = await DatabaseRouter.getConnection(_database);
    try {
      final results = await connection.query(clone._queryBuilder.toSql(), clone._queryBuilder.parameters);
      return results.map((row) {
        final result = <String, dynamic>{};
        for (final field in fields) {
          result[field] = row[field];
        }
        return result;
      }).toList();
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  // Iterator support
  Stream<T> stream() async* {
    final results = await all();
    for (final result in results) {
      yield result;
    }
  }

  // Caching methods
  QuerySet<T> cache() {
    final clone = _clone();
    clone._resultCache = true;
    return clone;
  }

  void clearCache() {
    _cachedResults = null;
  }

  // Private helper methods
  QuerySet<T> _clone() {
    return QuerySet<T>._clone(this);
  }

  T _createModelFromData(Map<String, dynamic> data) {
    final modelClass = _modelType as dynamic;
    return modelClass.fromMap(data) as T;
  }

  void _applyFilter(String fieldName, String lookup, dynamic value) {
    final condition = _buildCondition(fieldName, lookup, value);
    _queryBuilder.where(condition.condition, condition.parameters);
  }

  FilterCondition _buildCondition(String fieldName, String lookup, dynamic value) {
    switch (lookup) {
      case 'exact':
        return FilterCondition('$fieldName = ?', [value]);
      case 'iexact':
        return FilterCondition('LOWER($fieldName) = LOWER(?)', [value]);
      case 'contains':
        return FilterCondition('$fieldName LIKE ?', ['%$value%']);
      case 'icontains':
        return FilterCondition('LOWER($fieldName) LIKE LOWER(?)', ['%$value%']);
      case 'startswith':
        return FilterCondition('$fieldName LIKE ?', ['$value%']);
      case 'istartswith':
        return FilterCondition('LOWER($fieldName) LIKE LOWER(?)', ['$value%']);
      case 'endswith':
        return FilterCondition('$fieldName LIKE ?', ['%$value']);
      case 'iendswith':
        return FilterCondition('LOWER($fieldName) LIKE LOWER(?)', ['%$value']);
      case 'in':
        if (value is List) {
          final placeholders = List.filled(value.length, '?').join(', ');
          return FilterCondition('$fieldName IN ($placeholders)', value);
        }
        throw QuerySetException('Value for "in" lookup must be a list');
      case 'gt':
        return FilterCondition('$fieldName > ?', [value]);
      case 'gte':
        return FilterCondition('$fieldName >= ?', [value]);
      case 'lt':
        return FilterCondition('$fieldName < ?', [value]);
      case 'lte':
        return FilterCondition('$fieldName <= ?', [value]);
      case 'isnull':
        if (value == true) {
          return FilterCondition('$fieldName IS NULL', []);
        } else {
          return FilterCondition('$fieldName IS NOT NULL', []);
        }
      case 'regex':
        return FilterCondition('$fieldName ~ ?', [value]);
      case 'iregex':
        return FilterCondition('$fieldName ~* ?', [value]);
      case 'range':
        if (value is List && value.length == 2) {
          return FilterCondition('$fieldName BETWEEN ? AND ?', value);
        }
        throw QuerySetException('Value for "range" lookup must be a list of 2 elements');
      case 'year':
        return FilterCondition('EXTRACT(YEAR FROM $fieldName) = ?', [value]);
      case 'month':
        return FilterCondition('EXTRACT(MONTH FROM $fieldName) = ?', [value]);
      case 'day':
        return FilterCondition('EXTRACT(DAY FROM $fieldName) = ?', [value]);
      case 'week':
        return FilterCondition('EXTRACT(WEEK FROM $fieldName) = ?', [value]);
      case 'week_day':
        return FilterCondition('EXTRACT(DOW FROM $fieldName) = ?', [value]);
      case 'quarter':
        return FilterCondition('EXTRACT(QUARTER FROM $fieldName) = ?', [value]);
      case 'hour':
        return FilterCondition('EXTRACT(HOUR FROM $fieldName) = ?', [value]);
      case 'minute':
        return FilterCondition('EXTRACT(MINUTE FROM $fieldName) = ?', [value]);
      case 'second':
        return FilterCondition('EXTRACT(SECOND FROM $fieldName) = ?', [value]);
      default:
        throw QuerySetException('Unknown lookup: $lookup');
    }
  }

  Future<void> _handlePrefetchRelated(List<T> models) async {
    for (final relatedField in _prefetchRelated) {
      await _prefetchField(models, relatedField);
    }
  }
  
  Future<void> _prefetchField(List<T> models, String fieldName) async {
    final modelIds = models.map((model) => model.pk).where((id) => id != null).toList();
    if (modelIds.isEmpty) return;
    
    final connection = await DatabaseRouter.getConnection(_database);
    try {
      final relatedTableName = '${fieldName}s';
      final foreignKey = '${_tableName.substring(0, _tableName.length - 1)}_id';
      
      final query = QueryBuilder()
          .select(['*'])
          .from(relatedTableName)
          .whereIn(foreignKey, modelIds);
      
      final relatedResults = await connection.query(query.toSql(), query.parameters);
      
      final relatedObjectsMap = <dynamic, List<Map<String, dynamic>>>{};
      for (final row in relatedResults) {
        final foreignKeyValue = row[foreignKey];
        relatedObjectsMap.putIfAbsent(foreignKeyValue, () => []).add(row);
      }
      
      for (final model in models) {
        final relatedObjects = relatedObjectsMap[model.pk] ?? [];
        model.setField('_${fieldName}_cache', relatedObjects);
      }
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  // SQL generation
  String toSql() {
    return _queryBuilder.toSql();
  }

  List<dynamic> get parameters {
    return _queryBuilder.parameters;
  }

  // String representation
  @override
  String toString() {
    return 'QuerySet<${_modelType.toString()}>(${_queryBuilder.toSql()})';
  }
}

class FilterCondition {
  final String condition;
  final List<dynamic> parameters;

  FilterCondition(this.condition, this.parameters);
}

// QuerySet extensions for specific operations
extension QuerySetExtensions<T extends Model> on QuerySet<T> {
  // Random operations
  Future<T?> randomOrNull() async {
    final count = await this.count();
    if (count == 0) return null;
    
    final randomOffset = math.Random().nextInt(count);
    return await offset(randomOffset).first();
  }

  Future<T> random() async {
    final result = await randomOrNull();
    if (result == null) {
      throw DoesNotExistException('No objects in QuerySet');
    }
    return result;
  }

  // Pagination
  Future<QuerySetPage<T>> paginate(int page, int perPage) async {
    final offset = (page - 1) * perPage;
    final items = await this.offset(offset).limit(perPage).all();
    final totalCount = await count();
    
    return QuerySetPage<T>(
      items: items,
      page: page,
      perPage: perPage,
      totalCount: totalCount,
      totalPages: (totalCount / perPage).ceil(),
    );
  }

  // Chunked iteration
  Stream<List<T>> chunk(int chunkSize) async* {
    int offset = 0;
    while (true) {
      final chunk = await this.offset(offset).limit(chunkSize).all();
      if (chunk.isEmpty) break;
      
      yield chunk;
      offset += chunkSize;
      
      if (chunk.length < chunkSize) break;
    }
  }

  // Batch operations
  Future<void> batchUpdate(Map<String, dynamic> updates, {int batchSize = 1000}) async {
    await update(updates);
  }

  Future<void> batchDelete({int batchSize = 1000}) async {
    await delete();
  }
}

class QuerySetPage<T extends Model> {
  final List<T> items;
  final int page;
  final int perPage;
  final int totalCount;
  final int totalPages;

  QuerySetPage({
    required this.items,
    required this.page,
    required this.perPage,
    required this.totalCount,
    required this.totalPages,
  });

  bool get hasNext => page < totalPages;
  bool get hasPrevious => page > 1;
  int? get nextPage => hasNext ? page + 1 : null;
  int? get previousPage => hasPrevious ? page - 1 : null;
  
  int get startIndex => (page - 1) * perPage + 1;
  int get endIndex => math.min(page * perPage, totalCount);
  
  @override
  String toString() {
    return 'QuerySetPage<${T.toString()}>(page: $page, items: ${items.length}, total: $totalCount)';
  }
}