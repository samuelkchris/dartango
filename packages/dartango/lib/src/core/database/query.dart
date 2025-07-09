
class QueryResult {
  final int? affectedRows;
  final int? insertId;
  final List<String> columns;
  final List<Map<String, dynamic>> rows;

  QueryResult({
    this.affectedRows,
    this.insertId,
    required this.columns,
    required this.rows,
  });

  bool get isEmpty => rows.isEmpty;
  bool get isNotEmpty => rows.isNotEmpty;
  int get length => rows.length;
  
  Map<String, dynamic>? get first => rows.isNotEmpty ? rows.first : null;
  Map<String, dynamic>? get last => rows.isNotEmpty ? rows.last : null;
  
  List<Map<String, dynamic>> take(int count) => rows.take(count).toList();
  List<Map<String, dynamic>> skip(int count) => rows.skip(count).toList();
  
  QueryResult where(bool Function(Map<String, dynamic>) test) {
    return QueryResult(
      affectedRows: affectedRows,
      insertId: insertId,
      columns: columns,
      rows: rows.where(test).toList(),
    );
  }
  
  QueryResult map<T>(T Function(Map<String, dynamic>) mapper) {
    return QueryResult(
      affectedRows: affectedRows,
      insertId: insertId,
      columns: columns,
      rows: rows.map((row) => mapper(row) as Map<String, dynamic>).toList(),
    );
  }

  @override
  String toString() {
    return 'QueryResult(affectedRows: $affectedRows, insertId: $insertId, rows: ${rows.length})';
  }
}

class QueryBuilder {
  final List<String> _select = [];
  final List<String> _from = [];
  final List<String> _joins = [];
  final List<String> _where = [];
  final List<String> _groupBy = [];
  final List<String> _having = [];
  final List<String> _orderBy = [];
  int? _limit;
  int? _offset;
  final List<dynamic> _parameters = [];
  String? _rawSql;
  
  set rawSql(String? sql) => _rawSql = sql;

  // Public getters for accessing private fields
  List<String> get selectFields => _select;
  List<String> get fromTables => _from;
  List<String> get joins => _joins;
  List<String> get whereConditions => _where;
  List<String> get groupByFields => _groupBy;
  List<String> get havingConditions => _having;
  List<String> get orderByFields => _orderBy;
  int? get limitValue => _limit;
  int? get offsetValue => _offset;
  
  // Setters for limit and offset
  set limitValue(int? value) => _limit = value;
  set offsetValue(int? value) => _offset = value;

  QueryBuilder();

  QueryBuilder select(List<String> columns) {
    _select.addAll(columns);
    return this;
  }

  QueryBuilder from(String table) {
    _from.add(table);
    return this;
  }

  QueryBuilder join(String table, String condition, {String type = 'INNER'}) {
    _joins.add('$type JOIN $table ON $condition');
    return this;
  }

  QueryBuilder leftJoin(String table, String condition) {
    return join(table, condition, type: 'LEFT');
  }

  QueryBuilder rightJoin(String table, String condition) {
    return join(table, condition, type: 'RIGHT');
  }

  QueryBuilder innerJoin(String table, String condition) {
    return join(table, condition, type: 'INNER');
  }

  QueryBuilder where(String condition, [List<dynamic>? parameters]) {
    _where.add(condition);
    if (parameters != null) {
      _parameters.addAll(parameters);
    }
    return this;
  }

  QueryBuilder whereIn(String column, List<dynamic> values) {
    if (values.isEmpty) return this;
    
    final placeholders = List.filled(values.length, '?').join(', ');
    _where.add('$column IN ($placeholders)');
    _parameters.addAll(values);
    return this;
  }

  QueryBuilder whereNotIn(String column, List<dynamic> values) {
    if (values.isEmpty) return this;
    
    final placeholders = List.filled(values.length, '?').join(', ');
    _where.add('$column NOT IN ($placeholders)');
    _parameters.addAll(values);
    return this;
  }

  QueryBuilder whereBetween(String column, dynamic start, dynamic end) {
    _where.add('$column BETWEEN ? AND ?');
    _parameters.addAll([start, end]);
    return this;
  }

  QueryBuilder whereNotBetween(String column, dynamic start, dynamic end) {
    _where.add('$column NOT BETWEEN ? AND ?');
    _parameters.addAll([start, end]);
    return this;
  }

  QueryBuilder whereNull(String column) {
    _where.add('$column IS NULL');
    return this;
  }

  QueryBuilder whereNotNull(String column) {
    _where.add('$column IS NOT NULL');
    return this;
  }

  QueryBuilder whereLike(String column, String pattern) {
    _where.add('$column LIKE ?');
    _parameters.add(pattern);
    return this;
  }

  QueryBuilder whereNotLike(String column, String pattern) {
    _where.add('$column NOT LIKE ?');
    _parameters.add(pattern);
    return this;
  }

  QueryBuilder whereExists(String subquery) {
    _where.add('EXISTS ($subquery)');
    return this;
  }

  QueryBuilder whereNotExists(String subquery) {
    _where.add('NOT EXISTS ($subquery)');
    return this;
  }

  QueryBuilder groupBy(List<String> columns) {
    _groupBy.addAll(columns);
    return this;
  }

  QueryBuilder having(String condition, [List<dynamic>? parameters]) {
    _having.add(condition);
    if (parameters != null) {
      _parameters.addAll(parameters);
    }
    return this;
  }

  QueryBuilder orderBy(String column, {bool ascending = true}) {
    _orderBy.add('$column ${ascending ? 'ASC' : 'DESC'}');
    return this;
  }

  QueryBuilder orderByDesc(String column) {
    return orderBy(column, ascending: false);
  }

  QueryBuilder limit(int count) {
    _limit = count;
    return this;
  }

  QueryBuilder offset(int count) {
    _offset = count;
    return this;
  }

  String toSql() {
    if (_rawSql != null) {
      return _rawSql!;
    }
    
    final buffer = StringBuffer();
    
    if (_select.isNotEmpty) {
      buffer.write('SELECT ${_select.join(', ')}');
    } else {
      buffer.write('SELECT *');
    }
    
    if (_from.isNotEmpty) {
      buffer.write(' FROM ${_from.join(', ')}');
    }
    
    if (_joins.isNotEmpty) {
      buffer.write(' ${_joins.join(' ')}');
    }
    
    if (_where.isNotEmpty) {
      buffer.write(' WHERE ${_where.join(' AND ')}');
    }
    
    if (_groupBy.isNotEmpty) {
      buffer.write(' GROUP BY ${_groupBy.join(', ')}');
    }
    
    if (_having.isNotEmpty) {
      buffer.write(' HAVING ${_having.join(' AND ')}');
    }
    
    if (_orderBy.isNotEmpty) {
      buffer.write(' ORDER BY ${_orderBy.join(', ')}');
    }
    
    if (_limit != null) {
      buffer.write(' LIMIT $_limit');
    }
    
    if (_offset != null) {
      buffer.write(' OFFSET $_offset');
    }
    
    return buffer.toString();
  }

  List<dynamic> get parameters => List.unmodifiable(_parameters);
  
  List<dynamic> get mutableParameters => _parameters;

  QueryBuilder clone() {
    final clone = QueryBuilder();
    clone._select.addAll(_select);
    clone._from.addAll(_from);
    clone._joins.addAll(_joins);
    clone._where.addAll(_where);
    clone._groupBy.addAll(_groupBy);
    clone._having.addAll(_having);
    clone._orderBy.addAll(_orderBy);
    clone._limit = _limit;
    clone._offset = _offset;
    clone._rawSql = _rawSql;
    clone._parameters.addAll(_parameters);
    return clone;
  }

  @override
  String toString() => toSql();
}

class InsertQueryBuilder {
  final String _table;
  final Map<String, dynamic> _values = {};
  final List<Map<String, dynamic>> _bulkValues = [];
  bool _ignore = false;
  String? _onConflict;

  InsertQueryBuilder(this._table);

  InsertQueryBuilder values(Map<String, dynamic> values) {
    _values.addAll(values);
    return this;
  }

  InsertQueryBuilder bulkValues(List<Map<String, dynamic>> values) {
    _bulkValues.addAll(values);
    return this;
  }

  InsertQueryBuilder ignore() {
    _ignore = true;
    return this;
  }

  InsertQueryBuilder onConflict(String action) {
    _onConflict = action;
    return this;
  }

  String toSql() {
    final buffer = StringBuffer();
    
    if (_ignore) {
      buffer.write('INSERT IGNORE INTO $_table');
    } else {
      buffer.write('INSERT INTO $_table');
    }
    
    if (_bulkValues.isNotEmpty) {
      final columns = _bulkValues.first.keys.toList();
      buffer.write(' (${columns.join(', ')})');
      
      final placeholders = List.filled(columns.length, '?').join(', ');
      final valuesList = List.filled(_bulkValues.length, '($placeholders)').join(', ');
      buffer.write(' VALUES $valuesList');
    } else if (_values.isNotEmpty) {
      final columns = _values.keys.toList();
      buffer.write(' (${columns.join(', ')})');
      
      final placeholders = List.filled(columns.length, '?').join(', ');
      buffer.write(' VALUES ($placeholders)');
    }
    
    if (_onConflict != null) {
      buffer.write(' $_onConflict');
    }
    
    return buffer.toString();
  }

  List<dynamic> get parameters {
    if (_bulkValues.isNotEmpty) {
      final result = <dynamic>[];
      for (final values in _bulkValues) {
        result.addAll(values.values);
      }
      return result;
    }
    return _values.values.toList();
  }

  @override
  String toString() => toSql();
}

class UpdateQueryBuilder {
  final String _table;
  final Map<String, dynamic> _values = {};
  final List<String> _where = [];
  final List<dynamic> _parameters = [];

  UpdateQueryBuilder(this._table);

  UpdateQueryBuilder set(Map<String, dynamic> values) {
    _values.addAll(values);
    return this;
  }

  UpdateQueryBuilder where(String condition, [List<dynamic>? parameters]) {
    _where.add(condition);
    if (parameters != null) {
      _parameters.addAll(parameters);
    }
    return this;
  }

  String toSql() {
    final buffer = StringBuffer();
    buffer.write('UPDATE $_table SET ');
    
    final assignments = _values.keys.map((key) => '$key = ?').join(', ');
    buffer.write(assignments);
    
    if (_where.isNotEmpty) {
      buffer.write(' WHERE ${_where.join(' AND ')}');
    }
    
    return buffer.toString();
  }

  List<dynamic> get parameters {
    final result = <dynamic>[];
    result.addAll(_values.values);
    result.addAll(_parameters);
    return result;
  }

  @override
  String toString() => toSql();
}

class DeleteQueryBuilder {
  final String _table;
  final List<String> _where = [];
  final List<dynamic> _parameters = [];

  DeleteQueryBuilder(this._table);

  DeleteQueryBuilder where(String condition, [List<dynamic>? parameters]) {
    _where.add(condition);
    if (parameters != null) {
      _parameters.addAll(parameters);
    }
    return this;
  }

  String toSql() {
    final buffer = StringBuffer();
    buffer.write('DELETE FROM $_table');
    
    if (_where.isNotEmpty) {
      buffer.write(' WHERE ${_where.join(' AND ')}');
    }
    
    return buffer.toString();
  }

  List<dynamic> get parameters => List.unmodifiable(_parameters);

  @override
  String toString() => toSql();
}

class RawQuery {
  final String sql;
  final List<dynamic> parameters;

  RawQuery(this.sql, [this.parameters = const []]);

  @override
  String toString() => sql;
}

class SubQuery {
  final QueryBuilder query;
  final String alias;

  SubQuery(this.query, this.alias);

  String toSql() => '(${query.toSql()}) AS $alias';
  List<dynamic> get parameters => query.parameters;

  @override
  String toString() => toSql();
}

class Union {
  final List<QueryBuilder> queries;
  final bool all;

  Union(this.queries, {this.all = false});

  String toSql() {
    final unionType = all ? 'UNION ALL' : 'UNION';
    return queries.map((q) => q.toSql()).join(' $unionType ');
  }

  List<dynamic> get parameters {
    final result = <dynamic>[];
    for (final query in queries) {
      result.addAll(query.parameters);
    }
    return result;
  }

  @override
  String toString() => toSql();
}

class CTE {
  final String name;
  final QueryBuilder query;
  final bool recursive;

  CTE(this.name, this.query, {this.recursive = false});

  String toSql() => '$name AS (${query.toSql()})';
  List<dynamic> get parameters => query.parameters;

  @override
  String toString() => toSql();
}

class WindowFunction {
  final String function;
  final List<String> partitionBy;
  final List<String> orderBy;
  final String? frame;

  WindowFunction(this.function, {
    this.partitionBy = const [],
    this.orderBy = const [],
    this.frame,
  });

  String toSql() {
    final buffer = StringBuffer();
    buffer.write('$function OVER (');
    
    if (partitionBy.isNotEmpty) {
      buffer.write('PARTITION BY ${partitionBy.join(', ')}');
    }
    
    if (orderBy.isNotEmpty) {
      if (partitionBy.isNotEmpty) buffer.write(' ');
      buffer.write('ORDER BY ${orderBy.join(', ')}');
    }
    
    if (frame != null) {
      if (partitionBy.isNotEmpty || orderBy.isNotEmpty) buffer.write(' ');
      buffer.write(frame);
    }
    
    buffer.write(')');
    return buffer.toString();
  }

  @override
  String toString() => toSql();
}