import 'dart:async';
import 'package:test/test.dart';
import 'package:dartango/src/core/database/connection.dart';
import 'package:dartango/src/core/database/exceptions.dart';

void main() {
  group('DatabaseConfig', () {
    test('should create default PostgreSQL config', () {
      final config = DatabaseConfig(database: 'test_db');
      
      expect(config.host, equals('localhost'));
      expect(config.port, equals(5432));
      expect(config.database, equals('test_db'));
      expect(config.backend, equals(DatabaseBackend.postgresql));
      expect(config.maxConnections, equals(10));
    });
    
    test('should create custom config', () {
      final config = DatabaseConfig(
        host: 'db.example.com',
        port: 3306,
        database: 'myapp',
        username: 'dbuser',
        password: 'secret',
        backend: DatabaseBackend.mysql,
        maxConnections: 20,
      );
      
      expect(config.host, equals('db.example.com'));
      expect(config.port, equals(3306));
      expect(config.database, equals('myapp'));
      expect(config.username, equals('dbuser'));
      expect(config.password, equals('secret'));
      expect(config.backend, equals(DatabaseBackend.mysql));
      expect(config.maxConnections, equals(20));
    });
    
    test('should support copyWith', () {
      final config = DatabaseConfig(database: 'test_db');
      final newConfig = config.copyWith(
        host: 'newhost',
        port: 9999,
      );
      
      expect(newConfig.host, equals('newhost'));
      expect(newConfig.port, equals(9999));
      expect(newConfig.database, equals('test_db')); // unchanged
      expect(newConfig.backend, equals(DatabaseBackend.postgresql)); // unchanged
    });
  });

  group('DatabaseRouter', () {
    tearDown(() async {
      await DatabaseRouter.closeAll();
    });
    
    test('should register and retrieve database configuration', () {
      final config = DatabaseConfig(database: 'test_db');
      DatabaseRouter.registerDatabase('test', config);
      
      final retrievedConfig = DatabaseRouter.getConfig('test');
      expect(retrievedConfig, isNotNull);
      expect(retrievedConfig!.database, equals('test_db'));
    });
    
    test('should set and use default database', () {
      final config = DatabaseConfig(database: 'default_db');
      DatabaseRouter.registerDatabase('default', config);
      DatabaseRouter.setDefaultDatabase('default');
      
      final retrievedConfig = DatabaseRouter.getConfig();
      expect(retrievedConfig!.database, equals('default_db'));
    });
    
    test('should throw exception for unconfigured database', () {
      expect(() => DatabaseRouter.getPool('nonexistent'), 
             throwsA(isA<DatabaseException>()));
    });
    
    test('should list database names', () {
      final config1 = DatabaseConfig(database: 'db1');
      final config2 = DatabaseConfig(database: 'db2');
      
      DatabaseRouter.registerDatabase('test1', config1);
      DatabaseRouter.registerDatabase('test2', config2);
      
      final names = DatabaseRouter.getDatabaseNames();
      expect(names, containsAll(['test1', 'test2']));
    });
  });

  group('SQLiteConnection', () {
    late SQLiteConnection connection;
    
    setUp(() {
      final config = DatabaseConfig(
        database: ':memory:',
        backend: DatabaseBackend.sqlite,
      );
      connection = SQLiteConnection(config);
    });
    
    tearDown(() async {
      await connection.close();
    });
    
    test('should connect to SQLite database', () async {
      expect(connection.isOpen, isFalse);
      
      // Execute a query to trigger connection
      await connection.execute('SELECT 1');
      
      expect(connection.isOpen, isTrue);
      expect(connection.backend, equals(DatabaseBackend.sqlite));
    });
    
    test('should execute CREATE TABLE and INSERT operations', () async {
      // Create table
      await connection.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT UNIQUE
        )
      ''');
      
      // Insert data
      final result = await connection.execute(
        'INSERT INTO users (name, email) VALUES (?, ?)',
        ['John Doe', 'john@example.com']
      );
      
      expect(result.affectedRows, equals(1));
      expect(result.insertId, equals(1));
    });
    
    test('should execute SELECT queries', () async {
      // Create and populate table
      await connection.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          age INTEGER
        )
      ''');
      
      await connection.execute(
        'INSERT INTO users (name, age) VALUES (?, ?)',
        ['Alice', 25]
      );
      await connection.execute(
        'INSERT INTO users (name, age) VALUES (?, ?)',
        ['Bob', 30]
      );
      
      // Query data
      final result = await connection.execute('SELECT * FROM users ORDER BY id');
      
      expect(result.rows.length, equals(2));
      expect(result.columns, equals(['id', 'name', 'age']));
      expect(result.rows[0]['name'], equals('Alice'));
      expect(result.rows[1]['name'], equals('Bob'));
    });
    
    test('should support transactions', () async {
      await connection.execute('''
        CREATE TABLE accounts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          balance REAL
        )
      ''');
      
      await connection.execute(
        'INSERT INTO accounts (name, balance) VALUES (?, ?)',
        ['Account A', 100.0]
      );
      await connection.execute(
        'INSERT INTO accounts (name, balance) VALUES (?, ?)',
        ['Account B', 50.0]
      );
      
      // Test transaction
      await connection.transaction((txn) async {
        await txn.execute(
          'UPDATE accounts SET balance = balance - ? WHERE id = ?',
          [25.0, 1]
        );
        await txn.execute(
          'UPDATE accounts SET balance = balance + ? WHERE id = ?',
          [25.0, 2]
        );
      });
      
      // Verify changes
      final result = await connection.execute('SELECT balance FROM accounts ORDER BY id');
      expect(result.rows[0]['balance'], equals(75.0));
      expect(result.rows[1]['balance'], equals(75.0));
    });
    
    test('should rollback transaction on error', () async {
      await connection.execute('''
        CREATE TABLE test_table (
          id INTEGER PRIMARY KEY,
          value INTEGER UNIQUE
        )
      ''');
      
      await connection.execute('INSERT INTO test_table (value) VALUES (?)', [1]);
      
      try {
        await connection.transaction((txn) async {
          await txn.execute('INSERT INTO test_table (value) VALUES (?)', [2]);
          // This should fail due to unique constraint
          await txn.execute('INSERT INTO test_table (value) VALUES (?)', [1]);
        });
      } catch (e) {
        // Transaction should be rolled back
      }
      
      // Only the original record should exist
      final result = await connection.execute('SELECT COUNT(*) as count FROM test_table');
      expect(result.rows[0]['count'], equals(1));
    });
    
    test('should handle savepoints', () async {
      await connection.execute('''
        CREATE TABLE test_savepoints (
          id INTEGER PRIMARY KEY,
          value TEXT
        )
      ''');
      
      await connection.beginTransaction();
      await connection.execute('INSERT INTO test_savepoints (value) VALUES (?)', ['A']);
      
      await connection.setSavepoint('sp1');
      await connection.execute('INSERT INTO test_savepoints (value) VALUES (?)', ['B']);
      
      await connection.rollbackToSavepoint('sp1');
      await connection.commitTransaction();
      
      final result = await connection.execute('SELECT * FROM test_savepoints');
      expect(result.rows.length, equals(1));
      expect(result.rows[0]['value'], equals('A'));
    });
    
    test('should get server info', () async {
      final info = await connection.getServerInfo();
      expect(info['version'], startsWith('SQLite'));
    });
    
    test('should list table names', () async {
      await connection.execute('CREATE TABLE test_table1 (id INTEGER)');
      await connection.execute('CREATE TABLE test_table2 (id INTEGER)');
      
      final tables = await connection.getTableNames();
      expect(tables, containsAll(['test_table1', 'test_table2']));
    });
    
    test('should get table schema', () async {
      await connection.execute('''
        CREATE TABLE test_schema (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          age INTEGER
        )
      ''');
      
      final schema = await connection.getTableSchema('test_schema');
      expect(schema.length, equals(3));
      
      final idColumn = schema.firstWhere((col) => col['name'] == 'id');
      expect(idColumn['type'], equals('INTEGER'));
      expect(idColumn['pk'], equals(1));
      
      final nameColumn = schema.firstWhere((col) => col['name'] == 'name');
      expect(nameColumn['type'], equals('TEXT'));
      expect(nameColumn['notnull'], equals(1));
    });
  });

  group('ConnectionPool', () {
    late ConnectionPool pool;
    
    setUp(() {
      final config = DatabaseConfig(
        database: ':memory:',
        backend: DatabaseBackend.sqlite,
        minConnections: 2,
        maxConnections: 5,
      );
      pool = ConnectionPool(config);
    });
    
    tearDown(() async {
      await pool.close();
    });
    
    test('should initialize with minimum connections', () async {
      // Wait for initialization
      await Future.delayed(Duration(milliseconds: 100));
      
      expect(pool.availableConnections, equals(2));
      expect(pool.usedConnections, equals(0));
      expect(pool.totalConnections, equals(2));
    });
    
    test('should acquire and release connections', () async {
      // Wait for pool initialization
      await Future.delayed(Duration(milliseconds: 200));
      
      final conn1 = await pool.acquire();
      expect(pool.usedConnections, equals(1));
      
      final conn2 = await pool.acquire();
      expect(pool.usedConnections, equals(2));
      
      await pool.release(conn1);
      expect(pool.usedConnections, equals(1));
      
      await pool.release(conn2);
      expect(pool.usedConnections, equals(0));
    });
    
    test('should create new connections up to max limit', () async {
      await Future.delayed(Duration(milliseconds: 200));
      
      final connections = <DatabaseConnection>[];
      
      // Acquire 5 connections (max)
      for (int i = 0; i < 5; i++) {
        connections.add(await pool.acquire());
      }
      
      expect(pool.usedConnections, equals(5));
      
      // Release all connections
      for (final conn in connections) {
        await pool.release(conn);
      }
      
      expect(pool.usedConnections, equals(0));
    });
  });
}