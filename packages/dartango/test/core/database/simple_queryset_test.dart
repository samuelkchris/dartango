import 'package:test/test.dart';
import 'package:dartango/src/core/database/connection.dart';
import 'package:dartango/src/core/database/models.dart';

// Simple test model
class SimpleUser extends Model {
  SimpleUser();

  SimpleUser.fromMap(Map<String, dynamic> data) : super.fromMap(data);

  @override
  ModelMeta get meta => const ModelMeta(tableName: 'simple_users');

  String get name => getField('name') ?? '';
  set name(String value) => setField('name', value);
}

void main() {
  test('Simple QuerySet test', () async {
    // Set up database
    final config = DatabaseConfig(
      database: 'simple_test.db',
      backend: DatabaseBackend.sqlite,
      minConnections: 1,
      maxConnections: 1,
    );
    DatabaseRouter.registerDatabase('test', config);
    final connection = await DatabaseRouter.getConnection('test');

    try {
      // Create table
      await connection.execute('''
        CREATE TABLE IF NOT EXISTS simple_users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL
        )
      ''');

      // Insert test data
      await connection
          .execute('INSERT INTO simple_users (name) VALUES (?)', ['Test User']);

      // Query data directly
      final results = await connection.query('SELECT * FROM simple_users');
      print('Direct query results: $results');

      // Try to create model instance directly
      final user = SimpleUser.fromMap(results.first);
      print('User name: ${user.name}');

      expect(user.name, equals('Test User'));
    } finally {
      await DatabaseRouter.releaseConnection(connection, 'test');
      await DatabaseRouter.closeAll();
    }
  });
}
