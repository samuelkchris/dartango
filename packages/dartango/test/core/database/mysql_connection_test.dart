import 'dart:async';
import 'dart:io';
import 'package:test/test.dart';
import 'package:dartango/src/core/database/connection.dart';
import 'package:dartango/src/core/database/exceptions.dart';

const String _mysqlHost = 'localhost';
const int _mysqlPort = 3306;
const String _mysqlUser = 'root';
const String _mysqlPassword = '';
const String _mysqlDatabase = 'dartango_test';

bool _isMySQLAvailable = false;

Future<bool> _checkMySQLAvailability() async {
  try {
    final config = DatabaseConfig(
      host: _mysqlHost,
      port: _mysqlPort,
      database: 'mysql',
      username: _mysqlUser,
      password: _mysqlPassword,
      backend: DatabaseBackend.mysql,
    );

    final connection = MySQLConnection(config);
    await connection.ping();
    await connection.close();
    return true;
  } catch (e) {
    return false;
  }
}

void main() async {
  _isMySQLAvailable = await _checkMySQLAvailability();

  if (!_isMySQLAvailable) {
    print('\nMySQL not available - skipping MySQL tests');
    print('To run MySQL tests, ensure MySQL is running on localhost:3306');
    print('with user: $_mysqlUser, password: $_mysqlPassword\n');
  }

  group('MySQLConnection', () {
    late MySQLConnection connection;
    late DatabaseConfig config;

    setUp(() async {
      if (!_isMySQLAvailable) return;

      config = DatabaseConfig(
        host: _mysqlHost,
        port: _mysqlPort,
        database: _mysqlDatabase,
        username: _mysqlUser,
        password: _mysqlPassword,
        backend: DatabaseBackend.mysql,
      );

      final adminConnection = MySQLConnection(DatabaseConfig(
        host: _mysqlHost,
        port: _mysqlPort,
        database: 'mysql',
        username: _mysqlUser,
        password: _mysqlPassword,
        backend: DatabaseBackend.mysql,
      ));

      try {
        await adminConnection.execute('CREATE DATABASE IF NOT EXISTS $_mysqlDatabase');
      } catch (e) {
      } finally {
        await adminConnection.close();
      }

      connection = MySQLConnection(config);
    });

    tearDown(() async {
      if (!_isMySQLAvailable) return;

      if (connection.isOpen) {
        try {
          final tables = await connection.getTableNames();
          for (final table in tables) {
            await connection.execute('DROP TABLE IF EXISTS $table');
          }
        } catch (e) {
        }
      }

      await connection.close();
    });

    test('should connect to MySQL database',
        skip: !_isMySQLAvailable ? 'MySQL not available' : null, () async {
      expect(connection.isOpen, isFalse);

      await connection.execute('SELECT 1');

      expect(connection.isOpen, isTrue);
      expect(connection.backend, equals(DatabaseBackend.mysql));
      expect(connection.databaseName, equals(_mysqlDatabase));
    });

    test('should execute CREATE TABLE and INSERT operations',
        skip: !_isMySQLAvailable ? 'MySQL not available' : null, () async {
      await connection.execute('''
        CREATE TABLE users (
          id INT AUTO_INCREMENT PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          email VARCHAR(255) UNIQUE,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
      ''');

      final result = await connection.execute(
          'INSERT INTO users (name, email) VALUES (?, ?)',
          ['John Doe', 'john@example.com']);

      expect(result.affectedRows, equals(1));
      expect(result.insertId, isNotNull);
      expect(result.insertId, greaterThan(0));
    });

    test('should execute SELECT queries with proper column mapping',
        skip: !_isMySQLAvailable ? 'MySQL not available' : null, () async {
      await connection.execute('''
        CREATE TABLE users (
          id INT AUTO_INCREMENT PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          age INT,
          email VARCHAR(255),
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
      ''');

      await connection.execute(
          'INSERT INTO users (name, age, email) VALUES (?, ?, ?)',
          ['Alice Smith', 25, 'alice@example.com']);
      await connection.execute(
          'INSERT INTO users (name, age, email) VALUES (?, ?, ?)',
          ['Bob Johnson', 30, 'bob@example.com']);
      await connection.execute(
          'INSERT INTO users (name, age, email) VALUES (?, ?, ?)',
          ['Charlie Brown', 35, 'charlie@example.com']);

      final result = await connection.execute('SELECT id, name, age, email FROM users ORDER BY id');

      expect(result.rows.length, equals(3));
      expect(result.columns, containsAll(['id', 'name', 'age', 'email']));

      expect(result.rows[0]['name'], equals('Alice Smith'));
      expect(result.rows[0]['age'], equals(25));
      expect(result.rows[0]['email'], equals('alice@example.com'));

      expect(result.rows[1]['name'], equals('Bob Johnson'));
      expect(result.rows[1]['age'], equals(30));

      expect(result.rows[2]['name'], equals('Charlie Brown'));
      expect(result.rows[2]['age'], equals(35));
    });

    test('should support UPDATE and DELETE operations',
        skip: !_isMySQLAvailable ? 'MySQL not available' : null, () async {
      await connection.execute('''
        CREATE TABLE products (
          id INT AUTO_INCREMENT PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          price DECIMAL(10,2)
        ) ENGINE=InnoDB
      ''');

      await connection.execute(
          'INSERT INTO products (name, price) VALUES (?, ?)', ['Widget', 19.99]);
      await connection.execute(
          'INSERT INTO products (name, price) VALUES (?, ?)', ['Gadget', 29.99]);

      final updateResult = await connection
          .execute('UPDATE products SET price = ? WHERE name = ?', [24.99, 'Widget']);
      expect(updateResult.affectedRows, equals(1));

      final selectResult = await connection
          .execute('SELECT price FROM products WHERE name = ?', ['Widget']);
      expect(selectResult.rows[0]['price'], equals(24.99));

      final deleteResult =
          await connection.execute('DELETE FROM products WHERE name = ?', ['Gadget']);
      expect(deleteResult.affectedRows, equals(1));

      final countResult = await connection.execute('SELECT COUNT(*) as cnt FROM products');
      expect(countResult.rows[0]['cnt'], equals(1));
    });

    test('should support transactions with commit',
        skip: !_isMySQLAvailable ? 'MySQL not available' : null, () async {
      await connection.execute('''
        CREATE TABLE accounts (
          id INT AUTO_INCREMENT PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          balance DECIMAL(10,2)
        ) ENGINE=InnoDB
      ''');

      await connection.execute(
          'INSERT INTO accounts (name, balance) VALUES (?, ?)', ['Account A', 100.00]);
      await connection.execute(
          'INSERT INTO accounts (name, balance) VALUES (?, ?)', ['Account B', 50.00]);

      await connection.transaction((txn) async {
        await txn.execute(
            'UPDATE accounts SET balance = balance - ? WHERE id = ?', [25.00, 1]);
        await txn.execute(
            'UPDATE accounts SET balance = balance + ? WHERE id = ?', [25.00, 2]);
      });

      final result = await connection.execute('SELECT balance FROM accounts ORDER BY id');
      expect(result.rows[0]['balance'], equals(75.00));
      expect(result.rows[1]['balance'], equals(75.00));
    });

    test('should rollback transaction on error',
        skip: !_isMySQLAvailable ? 'MySQL not available' : null, () async {
      await connection.execute('''
        CREATE TABLE test_rollback (
          id INT AUTO_INCREMENT PRIMARY KEY,
          value INT UNIQUE
        ) ENGINE=InnoDB
      ''');

      await connection.execute('INSERT INTO test_rollback (value) VALUES (?)', [1]);

      try {
        await connection.transaction((txn) async {
          await txn.execute('INSERT INTO test_rollback (value) VALUES (?)', [2]);
          await txn.execute('INSERT INTO test_rollback (value) VALUES (?)', [1]);
        });
        fail('Should have thrown exception');
      } catch (e) {
        expect(e, isA<DatabaseException>());
      }

      final result = await connection.execute('SELECT COUNT(*) as cnt FROM test_rollback');
      expect(result.rows[0]['cnt'], equals(1));
    });

    test('should handle nested transactions with savepoints',
        skip: !_isMySQLAvailable ? 'MySQL not available' : null, () async {
      await connection.execute('''
        CREATE TABLE test_savepoints (
          id INT AUTO_INCREMENT PRIMARY KEY,
          value VARCHAR(10)
        ) ENGINE=InnoDB
      ''');

      await connection.beginTransaction();

      await connection.execute('INSERT INTO test_savepoints (value) VALUES (?)', ['A']);

      await connection.setSavepoint('sp1');
      await connection.execute('INSERT INTO test_savepoints (value) VALUES (?)', ['B']);

      await connection.setSavepoint('sp2');
      await connection.execute('INSERT INTO test_savepoints (value) VALUES (?)', ['C']);

      await connection.rollbackToSavepoint('sp2');
      await connection.releaseSavepoint('sp1');

      await connection.commitTransaction();

      final result = await connection.execute('SELECT value FROM test_savepoints ORDER BY id');
      expect(result.rows.length, equals(2));
      expect(result.rows[0]['value'], equals('A'));
      expect(result.rows[1]['value'], equals('B'));
    });

    test('should handle multiple savepoints correctly',
        skip: !_isMySQLAvailable ? 'MySQL not available' : null, () async {
      await connection.execute('''
        CREATE TABLE test_multi_sp (
          id INT AUTO_INCREMENT PRIMARY KEY,
          value VARCHAR(10)
        ) ENGINE=InnoDB
      ''');

      await connection.beginTransaction();

      await connection.execute('INSERT INTO test_multi_sp (value) VALUES (?)', ['X']);
      await connection.setSavepoint('sp_x');

      await connection.execute('INSERT INTO test_multi_sp (value) VALUES (?)', ['Y']);
      await connection.setSavepoint('sp_y');

      await connection.execute('INSERT INTO test_multi_sp (value) VALUES (?)', ['Z']);

      await connection.rollbackToSavepoint('sp_x');
      await connection.commitTransaction();

      final result = await connection.execute('SELECT value FROM test_multi_sp ORDER BY id');
      expect(result.rows.length, equals(1));
      expect(result.rows[0]['value'], equals('X'));
    });

    test('should ping successfully',
        skip: !_isMySQLAvailable ? 'MySQL not available' : null, () async {
      await expectLater(connection.ping(), completes);
      expect(connection.isOpen, isTrue);
    });

    test('should get server info',
        skip: !_isMySQLAvailable ? 'MySQL not available' : null, () async {
      final info = await connection.getServerInfo();

      expect(info, isNotNull);
      expect(info['version'], isNotNull);
      expect(info['version'], contains('MySQL'));
      expect(info['protocol_version'], isNotNull);
    });

    test('should list table names',
        skip: !_isMySQLAvailable ? 'MySQL not available' : null, () async {
      await connection.execute('''
        CREATE TABLE test_table1 (id INT PRIMARY KEY) ENGINE=InnoDB
      ''');
      await connection.execute('''
        CREATE TABLE test_table2 (id INT PRIMARY KEY) ENGINE=InnoDB
      ''');
      await connection.execute('''
        CREATE TABLE test_table3 (id INT PRIMARY KEY) ENGINE=InnoDB
      ''');

      final tables = await connection.getTableNames();

      expect(tables, containsAll(['test_table1', 'test_table2', 'test_table3']));
    });

    test('should get table schema with complete information',
        skip: !_isMySQLAvailable ? 'MySQL not available' : null, () async {
      await connection.execute('''
        CREATE TABLE test_schema (
          id INT AUTO_INCREMENT PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          age INT DEFAULT 0,
          email VARCHAR(255) UNIQUE,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB
      ''');

      final schema = await connection.getTableSchema('test_schema');

      expect(schema.length, greaterThanOrEqualTo(5));

      final idColumn = schema.firstWhere((col) => col['column_name'] == 'id');
      expect(idColumn['data_type'], contains('int'));
      expect(idColumn['column_key'], equals('PRI'));
      expect(idColumn['extra'], contains('auto_increment'));

      final nameColumn = schema.firstWhere((col) => col['column_name'] == 'name');
      expect(nameColumn['data_type'], contains('varchar'));
      expect(nameColumn['is_nullable'], equals('NO'));

      final emailColumn = schema.firstWhere((col) => col['column_name'] == 'email');
      expect(emailColumn['column_key'], equals('UNI'));
    });

    test('should get indexes for table',
        skip: !_isMySQLAvailable ? 'MySQL not available' : null, () async {
      await connection.execute('''
        CREATE TABLE test_indexes (
          id INT AUTO_INCREMENT PRIMARY KEY,
          email VARCHAR(255),
          username VARCHAR(255),
          INDEX idx_email (email),
          UNIQUE INDEX idx_username (username)
        ) ENGINE=InnoDB
      ''');

      final indexes = await connection.getIndexes('test_indexes');

      expect(indexes.length, greaterThanOrEqualTo(3));

      expect(indexes.any((idx) => idx['key_name'] == 'PRIMARY'), isTrue);
      expect(indexes.any((idx) => idx['key_name'] == 'idx_email'), isTrue);
      expect(indexes.any((idx) => idx['key_name'] == 'idx_username'), isTrue);

      final uniqueIndex = indexes.firstWhere((idx) => idx['key_name'] == 'idx_username');
      expect(uniqueIndex['non_unique'], equals(0));
    });

    test('should handle NULL values correctly',
        skip: !_isMySQLAvailable ? 'MySQL not available' : null, () async {
      await connection.execute('''
        CREATE TABLE test_nulls (
          id INT AUTO_INCREMENT PRIMARY KEY,
          value VARCHAR(255)
        ) ENGINE=InnoDB
      ''');

      await connection.execute('INSERT INTO test_nulls (value) VALUES (?)', [null]);
      await connection.execute('INSERT INTO test_nulls (value) VALUES (?)', ['not null']);

      final result = await connection.execute('SELECT id, value FROM test_nulls ORDER BY id');

      expect(result.rows[0]['value'], isNull);
      expect(result.rows[1]['value'], equals('not null'));
    });

    test('should handle various data types correctly',
        skip: !_isMySQLAvailable ? 'MySQL not available' : null, () async {
      await connection.execute('''
        CREATE TABLE test_types (
          id INT AUTO_INCREMENT PRIMARY KEY,
          int_val INT,
          bigint_val BIGINT,
          decimal_val DECIMAL(10,2),
          float_val FLOAT,
          double_val DOUBLE,
          text_val TEXT,
          varchar_val VARCHAR(255),
          bool_val BOOLEAN,
          date_val DATE,
          datetime_val DATETIME,
          timestamp_val TIMESTAMP
        ) ENGINE=InnoDB
      ''');

      await connection.execute('''
        INSERT INTO test_types
        (int_val, bigint_val, decimal_val, float_val, double_val, text_val, varchar_val, bool_val, date_val, datetime_val, timestamp_val)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        42,
        9223372036854775807,
        123.45,
        3.14,
        2.71828,
        'This is a long text field',
        'Short string',
        true,
        '2024-01-15',
        '2024-01-15 14:30:00',
        '2024-01-15 14:30:00'
      ]);

      final result = await connection.execute('SELECT * FROM test_types');

      expect(result.rows.length, equals(1));
      final row = result.rows[0];

      expect(row['int_val'], equals(42));
      expect(row['decimal_val'], equals(123.45));
      expect(row['text_val'], equals('This is a long text field'));
      expect(row['varchar_val'], equals('Short string'));
      expect(row['bool_val'], isIn([1, true]));
    });

    test('should handle connection auto-reconnect on failure',
        skip: !_isMySQLAvailable ? 'MySQL not available' : null, () async {
      final reconnectConfig = config.copyWith(autoReconnect: true);
      final reconnectConn = MySQLConnection(reconnectConfig);

      await reconnectConn.execute('SELECT 1');
      expect(reconnectConn.isOpen, isTrue);

      await reconnectConn.close();
      expect(reconnectConn.isOpen, isFalse);

      await reconnectConn.execute('SELECT 1');
      expect(reconnectConn.isOpen, isTrue);

      await reconnectConn.close();
    });

    test('should handle query timeout',
        skip: !_isMySQLAvailable ? 'MySQL not available' : null, () async {
      final timeoutConfig = config.copyWith(
        queryTimeout: Duration(milliseconds: 100),
      );
      final timeoutConn = MySQLConnection(timeoutConfig);

      try {
        await timeoutConn.execute('SELECT SLEEP(10)');
        fail('Should have timed out');
      } catch (e) {
        expect(e, isA<TimeoutException>());
      } finally {
        await timeoutConn.close();
      }
    });

    test('should handle parameterized queries safely',
        skip: !_isMySQLAvailable ? 'MySQL not available' : null, () async {
      await connection.execute('''
        CREATE TABLE test_params (
          id INT AUTO_INCREMENT PRIMARY KEY,
          data VARCHAR(255)
        ) ENGINE=InnoDB
      ''');

      final maliciousInput = "'; DROP TABLE test_params; --";

      await connection.execute(
        'INSERT INTO test_params (data) VALUES (?)',
        [maliciousInput]
      );

      final result = await connection.execute('SELECT data FROM test_params');
      expect(result.rows.length, equals(1));
      expect(result.rows[0]['data'], equals(maliciousInput));

      final tables = await connection.getTableNames();
      expect(tables, contains('test_params'));
    });

    test('should handle large result sets efficiently',
        skip: !_isMySQLAvailable ? 'MySQL not available' : null, () async {
      await connection.execute('''
        CREATE TABLE test_large (
          id INT AUTO_INCREMENT PRIMARY KEY,
          value VARCHAR(255)
        ) ENGINE=InnoDB
      ''');

      for (int i = 0; i < 1000; i++) {
        await connection.execute(
          'INSERT INTO test_large (value) VALUES (?)',
          ['Value $i']
        );
      }

      final result = await connection.execute('SELECT COUNT(*) as cnt FROM test_large');
      expect(result.rows[0]['cnt'], equals(1000));

      final allRows = await connection.execute('SELECT * FROM test_large');
      expect(allRows.rows.length, equals(1000));
    });
  });

  group('MySQL ConnectionPool', () {
    late ConnectionPool pool;

    setUp(() {
      if (!_isMySQLAvailable) return;

      final config = DatabaseConfig(
        host: _mysqlHost,
        port: _mysqlPort,
        database: _mysqlDatabase,
        username: _mysqlUser,
        password: _mysqlPassword,
        backend: DatabaseBackend.mysql,
        minConnections: 2,
        maxConnections: 5,
      );

      pool = ConnectionPool(config);
    });

    tearDown(() async {
      if (!_isMySQLAvailable) return;
      await pool.close();
    });

    test('should initialize with minimum MySQL connections',
        skip: !_isMySQLAvailable ? 'MySQL not available' : null, () async {
      await Future.delayed(Duration(milliseconds: 500));

      expect(pool.availableConnections, equals(2));
      expect(pool.usedConnections, equals(0));
      expect(pool.totalConnections, equals(2));
    });

    test('should acquire and release MySQL connections',
        skip: !_isMySQLAvailable ? 'MySQL not available' : null, () async {
      await Future.delayed(Duration(milliseconds: 500));

      final conn1 = await pool.acquire();
      expect(pool.usedConnections, equals(1));

      final conn2 = await pool.acquire();
      expect(pool.usedConnections, equals(2));

      await pool.release(conn1);
      expect(pool.usedConnections, equals(1));

      await pool.release(conn2);
      expect(pool.usedConnections, equals(0));
    });

    test('should create new MySQL connections up to max limit',
        skip: !_isMySQLAvailable ? 'MySQL not available' : null, () async {
      await Future.delayed(Duration(milliseconds: 500));

      final connections = <DatabaseConnection>[];

      for (int i = 0; i < 5; i++) {
        connections.add(await pool.acquire());
      }

      expect(pool.usedConnections, equals(5));

      for (final conn in connections) {
        await pool.release(conn);
      }

      expect(pool.usedConnections, equals(0));
    });
  });
}
