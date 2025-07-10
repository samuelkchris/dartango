import 'dart:async';

import 'package:postgres/postgres.dart';
import 'package:sqlite3/sqlite3.dart';

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
  Connection? _connection;
  bool _inTransaction = false;

  PostgreSQLConnection(this.config);

  Future<void> _connect() async {
    try {
      final endpoint = Endpoint(
        host: config.host,
        port: config.port,
        database: config.database,
        username: config.username,
        password: config.password,
      );
      
      final settings = ConnectionSettings(
        sslMode: config.enableSsl ? SslMode.require : SslMode.disable,
        connectTimeout: config.connectionTimeout,
        queryTimeout: config.queryTimeout,
        timeZone: config.timezone,
        applicationName: 'Dartango',
      );
      
      _connection = await Connection.open(endpoint, settings: settings);
    } catch (e) {
      throw DatabaseException('Failed to connect to PostgreSQL: $e');
    }
  }

  @override
  Future<QueryResult> execute(String sql, [List<dynamic>? parameters]) async {
    if (!isOpen) await _connect();
    
    try {
      final result = await _connection!.execute(
        sql,
        parameters: parameters ?? const [],
      );
      
      final rows = <Map<String, dynamic>>[];
      final columns = <String>[];
      
      if (result.isNotEmpty) {
        // Get column names from first row
        for (int i = 0; i < result.first.length; i++) {
          columns.add('column_$i'); // We'll use generic names for now
        }
        
        for (final row in result) {
          final rowMap = <String, dynamic>{};
          for (int i = 0; i < row.length; i++) {
            rowMap[columns[i]] = row[i];
          }
          rows.add(rowMap);
        }
      }
      
      return QueryResult(
        affectedRows: result.affectedRows,
        insertId: null,
        columns: columns,
        rows: rows,
      );
    } catch (e) {
      if (config.autoReconnect && !isOpen) {
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
    if (!isOpen) await _connect();
    await _connection!.execute('BEGIN');
    _inTransaction = true;
  }

  @override
  Future<void> commitTransaction() async {
    if (_inTransaction) {
      await _connection!.execute('COMMIT');
      _inTransaction = false;
    }
  }

  @override
  Future<void> rollbackTransaction() async {
    if (_inTransaction) {
      await _connection!.execute('ROLLBACK');
      _inTransaction = false;
    }
  }

  @override
  Future<void> setSavepoint(String name) async {
    if (!isOpen) await _connect();
    await _connection!.execute('SAVEPOINT $name');
  }

  @override
  Future<void> releaseSavepoint(String name) async {
    if (!isOpen) await _connect();
    await _connection!.execute('RELEASE SAVEPOINT $name');
  }

  @override
  Future<void> rollbackToSavepoint(String name) async {
    if (!isOpen) await _connect();
    await _connection!.execute('ROLLBACK TO SAVEPOINT $name');
  }

  @override
  Future<void> ping() async {
    if (!isOpen) await _connect();
    await _connection!.execute('SELECT 1');
  }

  @override
  Future<Map<String, dynamic>> getServerInfo() async {
    if (!isOpen) await _connect();
    final result = await _connection!.execute('SELECT version()');
    return {'version': result.first[0] as String};
  }

  @override
  Future<List<String>> getTableNames() async {
    if (!isOpen) await _connect();
    final result = await _connection!.execute(
      "SELECT tablename FROM pg_tables WHERE schemaname = 'public'"
    );
    return result.map((row) => row[0] as String).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getTableSchema(String tableName) async {
    if (!isOpen) await _connect();
    final result = await _connection!.execute(
      '''
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_name = @tableName
      ORDER BY ordinal_position
      ''',
      parameters: {'tableName': tableName},
    );
    
    return result.map((row) => {
      'column_name': row[0],
      'data_type': row[1],
      'is_nullable': row[2],
      'column_default': row[3],
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getIndexes(String tableName) async {
    if (!isOpen) await _connect();
    final result = await _connection!.execute(
      '''
      SELECT indexname, indexdef
      FROM pg_indexes
      WHERE tablename = @tableName
      ''',
      parameters: {'tableName': tableName},
    );
    
    return result.map((row) => {
      'indexname': row[0],
      'indexdef': row[1],
    }).toList();
  }

  @override
  Future<void> close() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
      _inTransaction = false;
    }
  }

  Future<void> _reconnect() async {
    await close();
    await _connect();
  }

  @override
  bool get isOpen => _connection != null;

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
    // MySQL implementation would go here
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
  Database? _database;
  bool _inTransaction = false;

  SQLiteConnection(this.config);

  Future<void> _connect() async {
    try {
      _database = sqlite3.open(config.database);
    } catch (e) {
      throw DatabaseException('Failed to connect to SQLite: $e');
    }
  }

  @override
  Future<QueryResult> execute(String sql, [List<dynamic>? parameters]) async {
    if (!isOpen) await _connect();
    
    try {
      final stmt = _database!.prepare(sql);
      
      int affectedRows = 0;
      int? insertId;
      final rows = <Map<String, dynamic>>[];
      final columns = <String>[];
      
      if (sql.trim().toUpperCase().startsWith('SELECT')) {
        final result = stmt.select(parameters ?? []);
        columns.addAll(result.columnNames);
        for (final row in result) {
          final rowMap = <String, dynamic>{};
          for (int i = 0; i < columns.length; i++) {
            rowMap[columns[i]] = row[i];
          }
          rows.add(rowMap);
        }
      } else {
        stmt.execute(parameters ?? []);
        affectedRows = _database!.updatedRows;
        if (sql.trim().toUpperCase().startsWith('INSERT')) {
          insertId = _database!.lastInsertRowId;
        }
      }
      
      stmt.dispose();
      
      return QueryResult(
        affectedRows: affectedRows,
        insertId: insertId,
        columns: columns,
        rows: rows,
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
    if (!isOpen) await _connect();
    _database!.execute('BEGIN');
    _inTransaction = true;
  }

  @override
  Future<void> commitTransaction() async {
    if (_inTransaction) {
      _database!.execute('COMMIT');
      _inTransaction = false;
    }
  }

  @override
  Future<void> rollbackTransaction() async {
    if (_inTransaction) {
      _database!.execute('ROLLBACK');
      _inTransaction = false;
    }
  }

  @override
  Future<void> setSavepoint(String name) async {
    if (!isOpen) await _connect();
    _database!.execute('SAVEPOINT $name');
  }

  @override
  Future<void> releaseSavepoint(String name) async {
    if (!isOpen) await _connect();
    _database!.execute('RELEASE SAVEPOINT $name');
  }

  @override
  Future<void> rollbackToSavepoint(String name) async {
    if (!isOpen) await _connect();
    _database!.execute('ROLLBACK TO SAVEPOINT $name');
  }

  @override
  Future<void> ping() async {
    if (!isOpen) await _connect();
    _database!.execute('SELECT 1');
  }

  @override
  Future<Map<String, dynamic>> getServerInfo() async {
    if (!isOpen) await _connect();
    final result = _database!.select('SELECT sqlite_version()');
    return {'version': 'SQLite ${result.first[0] as String}'};
  }

  @override
  Future<List<String>> getTableNames() async {
    if (!isOpen) await _connect();
    final result = _database!.select("SELECT name FROM sqlite_master WHERE type='table'");
    return result.map((row) => row[0] as String).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getTableSchema(String tableName) async {
    if (!isOpen) await _connect();
    final result = _database!.select('PRAGMA table_info($tableName)');
    
    return result.map((row) => {
      'cid': row[0],
      'name': row[1],
      'type': row[2],
      'notnull': row[3],
      'dflt_value': row[4],
      'pk': row[5],
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getIndexes(String tableName) async {
    if (!isOpen) await _connect();
    final result = _database!.select('PRAGMA index_list($tableName)');
    
    return result.map((row) => {
      'seq': row[0],
      'name': row[1],
      'unique': row[2],
      'origin': row[3],
      'partial': row[4],
    }).toList();
  }

  @override
  Future<void> close() async {
    if (_database != null) {
      _database!.dispose();
      _database = null;
      _inTransaction = false;
    }
  }

  @override
  bool get isOpen => _database != null;

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