import 'dart:async';

import 'exceptions.dart';
import 'query.dart';

abstract class DatabaseConnection {
  Future<QueryResult> execute(String sql, [List<dynamic>? parameters]);
  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic>? parameters]);
  Future<T> transaction<T>(Future<T> Function(DatabaseConnection) callback);
  Future<void> close();
  
  bool get isOpen;
  String get databaseName;
  DatabaseBackend get backend;
  
  Future<void> ping();
  Future<Map<String, dynamic>> getServerInfo();
  Future<List<String>> getTableNames();
  Future<List<Map<String, dynamic>>> getTableSchema(String tableName);
  Future<List<Map<String, dynamic>>> getIndexes(String tableName);
  Future<void> beginTransaction();
  Future<void> commitTransaction();
  Future<void> rollbackTransaction();
  Future<void> setSavepoint(String name);
  Future<void> releaseSavepoint(String name);
  Future<void> rollbackToSavepoint(String name);
}

enum DatabaseBackend {
  postgresql,
  mysql,
  sqlite,
}

class DatabaseConfig {
  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final DatabaseBackend backend;
  final Map<String, dynamic> options;
  final Duration connectionTimeout;
  final Duration queryTimeout;
  final int maxConnections;
  final int minConnections;
  final Duration maxIdleTime;
  final bool enableSsl;
  final String? sslCertPath;
  final String? charset;
  final String? timezone;
  final bool autoReconnect;
  final int maxRetries;
  final Duration retryDelay;

  const DatabaseConfig({
    this.host = 'localhost',
    this.port = 5432,
    required this.database,
    this.username = '',
    this.password = '',
    this.backend = DatabaseBackend.postgresql,
    this.options = const {},
    this.connectionTimeout = const Duration(seconds: 30),
    this.queryTimeout = const Duration(seconds: 30),
    this.maxConnections = 10,
    this.minConnections = 1,
    this.maxIdleTime = const Duration(minutes: 10),
    this.enableSsl = false,
    this.sslCertPath,
    this.charset = 'utf8',
    this.timezone,
    this.autoReconnect = true,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
  });

  DatabaseConfig copyWith({
    String? host,
    int? port,
    String? database,
    String? username,
    String? password,
    DatabaseBackend? backend,
    Map<String, dynamic>? options,
    Duration? connectionTimeout,
    Duration? queryTimeout,
    int? maxConnections,
    int? minConnections,
    Duration? maxIdleTime,
    bool? enableSsl,
    String? sslCertPath,
    String? charset,
    String? timezone,
    bool? autoReconnect,
    int? maxRetries,
    Duration? retryDelay,
  }) {
    return DatabaseConfig(
      host: host ?? this.host,
      port: port ?? this.port,
      database: database ?? this.database,
      username: username ?? this.username,
      password: password ?? this.password,
      backend: backend ?? this.backend,
      options: options ?? this.options,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      queryTimeout: queryTimeout ?? this.queryTimeout,
      maxConnections: maxConnections ?? this.maxConnections,
      minConnections: minConnections ?? this.minConnections,
      maxIdleTime: maxIdleTime ?? this.maxIdleTime,
      enableSsl: enableSsl ?? this.enableSsl,
      sslCertPath: sslCertPath ?? this.sslCertPath,
      charset: charset ?? this.charset,
      timezone: timezone ?? this.timezone,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      maxRetries: maxRetries ?? this.maxRetries,
      retryDelay: retryDelay ?? this.retryDelay,
    );
  }
}

class ConnectionPool {
  final DatabaseConfig config;
  final List<_PooledConnection> _availableConnections = [];
  final List<_PooledConnection> _usedConnections = [];
  final Completer<void>? _initCompleter;
  bool _isInitialized = false;
  bool _isShuttingDown = false;
  Timer? _cleanupTimer;

  ConnectionPool(this.config) : _initCompleter = Completer<void>() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      for (int i = 0; i < config.minConnections; i++) {
        final connection = await _createConnection();
        _availableConnections.add(connection);
      }
      _isInitialized = true;
      _initCompleter?.complete();
      _startCleanupTimer();
    } catch (e) {
      _initCompleter?.completeError(e);
    }
  }

  Future<_PooledConnection> _createConnection() async {
    final connection = await _createDatabaseConnection();
    return _PooledConnection(connection, DateTime.now());
  }

  Future<DatabaseConnection> _createDatabaseConnection() async {
    switch (config.backend) {
      case DatabaseBackend.postgresql:
        return PostgreSQLConnection(config);
      case DatabaseBackend.mysql:
        return MySQLConnection(config);
      case DatabaseBackend.sqlite:
        return SQLiteConnection(config);
    }
  }

  Future<DatabaseConnection> acquire() async {
    if (!_isInitialized) {
      await _initCompleter?.future;
    }

    if (_isShuttingDown) {
      throw DatabaseException('Connection pool is shutting down');
    }

    if (_availableConnections.isNotEmpty) {
      final pooledConnection = _availableConnections.removeAt(0);
      _usedConnections.add(pooledConnection);
      
      if (!pooledConnection.connection.isOpen) {
        await pooledConnection.connection.close();
        _usedConnections.remove(pooledConnection);
        return acquire();
      }
      
      return pooledConnection.connection;
    }

    if (_usedConnections.length < config.maxConnections) {
      final pooledConnection = await _createConnection();
      _usedConnections.add(pooledConnection);
      return pooledConnection.connection;
    }

    await Future.delayed(const Duration(milliseconds: 100));
    return acquire();
  }

  Future<void> release(DatabaseConnection connection) async {
    final pooledConnection = _usedConnections.firstWhere(
      (pc) => pc.connection == connection,
      orElse: () => throw DatabaseException('Connection not found in pool'),
    );

    _usedConnections.remove(pooledConnection);
    
    if (connection.isOpen && !_isShuttingDown) {
      pooledConnection.lastUsed = DateTime.now();
      _availableConnections.add(pooledConnection);
    } else {
      await connection.close();
    }
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _cleanupIdleConnections();
    });
  }

  void _cleanupIdleConnections() {
    final now = DateTime.now();
    final toRemove = <_PooledConnection>[];

    for (final connection in _availableConnections) {
      if (now.difference(connection.lastUsed) > config.maxIdleTime) {
        toRemove.add(connection);
      }
    }

    for (final connection in toRemove) {
      _availableConnections.remove(connection);
      connection.connection.close();
    }

    while (_availableConnections.length < config.minConnections) {
      _createConnection().then((connection) {
        if (!_isShuttingDown) {
          _availableConnections.add(connection);
        }
      }).catchError((error) {
        // Log error but don't crash
      });
    }
  }

  Future<void> close() async {
    _isShuttingDown = true;
    _cleanupTimer?.cancel();

    final allConnections = [..._availableConnections, ..._usedConnections];
    await Future.wait(allConnections.map((pc) => pc.connection.close()));

    _availableConnections.clear();
    _usedConnections.clear();
  }

  int get availableConnections => _availableConnections.length;
  int get usedConnections => _usedConnections.length;
  int get totalConnections => _availableConnections.length + _usedConnections.length;
}

class _PooledConnection {
  final DatabaseConnection connection;
  DateTime lastUsed;

  _PooledConnection(this.connection, this.lastUsed);
}

class PostgreSQLConnection implements DatabaseConnection {
  final DatabaseConfig config;
  bool _isOpen = false;
  bool _inTransaction = false;

  PostgreSQLConnection(this.config);

  Future<void> _connect() async {
    await Future.delayed(Duration(milliseconds: 100));
    _isOpen = true;
  }

  @override
  Future<QueryResult> execute(String sql, [List<dynamic>? parameters]) async {
    if (!_isOpen) await _connect();
    
    try {
      await Future.delayed(Duration(milliseconds: 10));
      return QueryResult(
        affectedRows: 1,
        insertId: null,
        columns: ['id', 'name'],
        rows: [{'id': 1, 'name': 'test'}],
      );
    } catch (e) {
      if (config.autoReconnect && !_isOpen) {
        await _reconnect();
        return execute(sql, parameters);
      }
      throw DatabaseException('Query execution failed: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic>? parameters]) async {
    final result = await execute(sql, parameters);
    return result.rows;
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseConnection) callback) async {
    if (_inTransaction) {
      return await callback(this);
    }

    await beginTransaction();
    try {
      final result = await callback(this);
      await commitTransaction();
      return result;
    } catch (e) {
      await rollbackTransaction();
      rethrow;
    }
  }

  @override
  Future<void> beginTransaction() async {
    if (!_isOpen) await _connect();
    _inTransaction = true;
  }

  @override
  Future<void> commitTransaction() async {
    if (_inTransaction) {
      _inTransaction = false;
    }
  }

  @override
  Future<void> rollbackTransaction() async {
    if (_inTransaction) {
      _inTransaction = false;
    }
  }

  @override
  Future<void> setSavepoint(String name) async {
    await Future.delayed(Duration(milliseconds: 1));
  }

  @override
  Future<void> releaseSavepoint(String name) async {
    await Future.delayed(Duration(milliseconds: 1));
  }

  @override
  Future<void> rollbackToSavepoint(String name) async {
    await Future.delayed(Duration(milliseconds: 1));
  }

  @override
  Future<void> ping() async {
    await Future.delayed(Duration(milliseconds: 1));
  }

  @override
  Future<Map<String, dynamic>> getServerInfo() async {
    return {'version': 'PostgreSQL 13.0'};
  }

  @override
  Future<List<String>> getTableNames() async {
    return ['users', 'posts', 'comments'];
  }

  @override
  Future<List<Map<String, dynamic>>> getTableSchema(String tableName) async {
    return [
      {'column_name': 'id', 'data_type': 'integer', 'is_nullable': 'NO', 'column_default': 'nextval(\'seq\')'},
      {'column_name': 'name', 'data_type': 'character varying', 'is_nullable': 'YES', 'column_default': null},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getIndexes(String tableName) async {
    return [
      {'indexname': '${tableName}_pkey', 'indexdef': 'CREATE UNIQUE INDEX ${tableName}_pkey ON $tableName USING btree (id)'},
    ];
  }

  @override
  Future<void> close() async {
    if (_isOpen) {
      _isOpen = false;
    }
  }

  Future<void> _reconnect() async {
    await close();
    await _connect();
  }

  @override
  bool get isOpen => _isOpen;

  @override
  String get databaseName => config.database;

  @override
  DatabaseBackend get backend => DatabaseBackend.postgresql;
}

class MySQLConnection implements DatabaseConnection {
  final DatabaseConfig config;
  bool _isOpen = false;
  bool _inTransaction = false;

  MySQLConnection(this.config);

  Future<void> _connect() async {
    await Future.delayed(Duration(milliseconds: 100));
    _isOpen = true;
  }

  @override
  Future<QueryResult> execute(String sql, [List<dynamic>? parameters]) async {
    if (!_isOpen) await _connect();
    
    try {
      await Future.delayed(Duration(milliseconds: 10));
      return QueryResult(
        affectedRows: 1,
        insertId: 1,
        columns: ['id', 'name'],
        rows: [{'id': 1, 'name': 'test'}],
      );
    } catch (e) {
      if (config.autoReconnect && !_isOpen) {
        await _reconnect();
        return execute(sql, parameters);
      }
      throw DatabaseException('Query execution failed: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic>? parameters]) async {
    final result = await execute(sql, parameters);
    return result.rows;
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseConnection) callback) async {
    if (_inTransaction) {
      return await callback(this);
    }

    await beginTransaction();
    try {
      final result = await callback(this);
      await commitTransaction();
      return result;
    } catch (e) {
      await rollbackTransaction();
      rethrow;
    }
  }

  @override
  Future<void> beginTransaction() async {
    if (!_isOpen) await _connect();
    _inTransaction = true;
  }

  @override
  Future<void> commitTransaction() async {
    if (_inTransaction) {
      _inTransaction = false;
    }
  }

  @override
  Future<void> rollbackTransaction() async {
    if (_inTransaction) {
      _inTransaction = false;
    }
  }

  @override
  Future<void> setSavepoint(String name) async {
    await Future.delayed(Duration(milliseconds: 1));
  }

  @override
  Future<void> releaseSavepoint(String name) async {
    await Future.delayed(Duration(milliseconds: 1));
  }

  @override
  Future<void> rollbackToSavepoint(String name) async {
    await Future.delayed(Duration(milliseconds: 1));
  }

  @override
  Future<void> ping() async {
    await Future.delayed(Duration(milliseconds: 1));
  }

  @override
  Future<Map<String, dynamic>> getServerInfo() async {
    return {'version': 'MySQL 8.0'};
  }

  @override
  Future<List<String>> getTableNames() async {
    return ['users', 'posts', 'comments'];
  }

  @override
  Future<List<Map<String, dynamic>>> getTableSchema(String tableName) async {
    return [
      {'Field': 'id', 'Type': 'int(11)', 'Null': 'NO', 'Key': 'PRI', 'Default': null, 'Extra': 'auto_increment'},
      {'Field': 'name', 'Type': 'varchar(255)', 'Null': 'YES', 'Key': '', 'Default': null, 'Extra': ''},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getIndexes(String tableName) async {
    return [
      {'Table': tableName, 'Non_unique': 0, 'Key_name': 'PRIMARY', 'Seq_in_index': 1, 'Column_name': 'id'},
    ];
  }

  @override
  Future<void> close() async {
    if (_isOpen) {
      _isOpen = false;
    }
  }

  Future<void> _reconnect() async {
    await close();
    await _connect();
  }

  @override
  bool get isOpen => _isOpen;

  @override
  String get databaseName => config.database;

  @override
  DatabaseBackend get backend => DatabaseBackend.mysql;
}

class SQLiteConnection implements DatabaseConnection {
  final DatabaseConfig config;
  bool _isOpen = false;
  bool _inTransaction = false;

  SQLiteConnection(this.config);

  Future<void> _connect() async {
    await Future.delayed(Duration(milliseconds: 50));
    _isOpen = true;
  }

  @override
  Future<QueryResult> execute(String sql, [List<dynamic>? parameters]) async {
    if (!_isOpen) await _connect();
    
    try {
      await Future.delayed(Duration(milliseconds: 5));
      return QueryResult(
        affectedRows: 1,
        insertId: 1,
        columns: ['id', 'name'],
        rows: [{'id': 1, 'name': 'test'}],
      );
    } catch (e) {
      throw DatabaseException('Query execution failed: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic>? parameters]) async {
    final result = await execute(sql, parameters);
    return result.rows;
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseConnection) callback) async {
    if (_inTransaction) {
      return await callback(this);
    }

    await beginTransaction();
    try {
      final result = await callback(this);
      await commitTransaction();
      return result;
    } catch (e) {
      await rollbackTransaction();
      rethrow;
    }
  }

  @override
  Future<void> beginTransaction() async {
    if (!_isOpen) await _connect();
    _inTransaction = true;
  }

  @override
  Future<void> commitTransaction() async {
    if (_inTransaction) {
      _inTransaction = false;
    }
  }

  @override
  Future<void> rollbackTransaction() async {
    if (_inTransaction) {
      _inTransaction = false;
    }
  }

  @override
  Future<void> setSavepoint(String name) async {
    await Future.delayed(Duration(milliseconds: 1));
  }

  @override
  Future<void> releaseSavepoint(String name) async {
    await Future.delayed(Duration(milliseconds: 1));
  }

  @override
  Future<void> rollbackToSavepoint(String name) async {
    await Future.delayed(Duration(milliseconds: 1));
  }

  @override
  Future<void> ping() async {
    await Future.delayed(Duration(milliseconds: 1));
  }

  @override
  Future<Map<String, dynamic>> getServerInfo() async {
    return {'version': 'SQLite 3.35.0'};
  }

  @override
  Future<List<String>> getTableNames() async {
    return ['users', 'posts', 'comments'];
  }

  @override
  Future<List<Map<String, dynamic>>> getTableSchema(String tableName) async {
    return [
      {'cid': 0, 'name': 'id', 'type': 'INTEGER', 'notnull': 1, 'dflt_value': null, 'pk': 1},
      {'cid': 1, 'name': 'name', 'type': 'TEXT', 'notnull': 0, 'dflt_value': null, 'pk': 0},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getIndexes(String tableName) async {
    return [
      {'seq': 0, 'name': 'sqlite_autoindex_${tableName}_1', 'unique': 1, 'origin': 'pk', 'partial': 0},
    ];
  }

  @override
  Future<void> close() async {
    if (_isOpen) {
      _isOpen = false;
    }
  }

  @override
  bool get isOpen => _isOpen;

  @override
  String get databaseName => config.database;

  @override
  DatabaseBackend get backend => DatabaseBackend.sqlite;
}

class DatabaseRouter {
  static final Map<String, ConnectionPool> _pools = {};
  static final Map<String, DatabaseConfig> _configs = {};
  static String _defaultDatabase = 'default';

  static void registerDatabase(String name, DatabaseConfig config) {
    _configs[name] = config;
    _pools[name] = ConnectionPool(config);
  }

  static void setDefaultDatabase(String name) {
    _defaultDatabase = name;
  }

  static ConnectionPool getPool([String? database]) {
    final dbName = database ?? _defaultDatabase;
    final pool = _pools[dbName];
    if (pool == null) {
      throw DatabaseException('Database $dbName not configured');
    }
    return pool;
  }

  static Future<DatabaseConnection> getConnection([String? database]) async {
    final pool = getPool(database);
    return await pool.acquire();
  }

  static Future<void> releaseConnection(DatabaseConnection connection, [String? database]) async {
    final pool = getPool(database);
    await pool.release(connection);
  }

  static Future<void> closeAll() async {
    await Future.wait(_pools.values.map((pool) => pool.close()));
    _pools.clear();
    _configs.clear();
  }

  static DatabaseConfig? getConfig([String? database]) {
    final dbName = database ?? _defaultDatabase;
    return _configs[dbName];
  }

  static List<String> getDatabaseNames() {
    return _configs.keys.toList();
  }
}