import 'package:test/test.dart';
import 'package:dartango/src/core/database/connection.dart';
import 'package:dartango/src/core/database/models.dart';
import 'package:dartango/src/core/database/queryset.dart';
import 'package:dartango/src/core/database/query.dart';

// Simple test model
class DebugUser extends Model {
  DebugUser();

  DebugUser.fromMap(Map<String, dynamic> data) : super.fromMap(data);

  @override
  ModelMeta get meta => const ModelMeta(tableName: 'debug_users');

  String get name => getField('name') ?? '';
  set name(String value) => setField('name', value);
}

void main() {
  test('Debug QuerySet step by step', () async {
    print('Step 1: Setting up database...');

    // Set up database
    final config = DatabaseConfig(
      database: 'debug_test.db',
      backend: DatabaseBackend.sqlite,
      minConnections: 1,
      maxConnections: 5,
    );
    DatabaseRouter.registerDatabase('test', config);
    final connection = await DatabaseRouter.getConnection('test');

    try {
      print('Step 2: Creating table...');

      // Create table
      await connection.execute('''
        CREATE TABLE IF NOT EXISTS debug_users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL
        )
      ''');

      print('Step 3: Inserting test data...');

      // Insert test data
      await connection
          .execute('INSERT INTO debug_users (name) VALUES (?)', ['Test User']);

      print('Step 4: Testing direct query...');

      // Query data directly
      final results = await connection.query('SELECT * FROM debug_users');
      print('Direct query results: $results');

      print('Step 5: Testing model creation...');

      // Try to create model instance directly
      final user = DebugUser.fromMap(results.first);
      print('User name: ${user.name}');

      print('Step 6: Testing QueryBuilder...');

      // Test QueryBuilder directly
      final queryBuilder = QueryBuilder().from('debug_users').select(['*']);
      print('Generated SQL: ${queryBuilder.toSql()}');
      print('Parameters: ${queryBuilder.parameters}');

      final builderResults =
          await connection.query(queryBuilder.toSql(), queryBuilder.parameters);
      print('QueryBuilder results: $builderResults');

      print('Step 7: Testing QuerySet creation...');

      // Test QuerySet creation (but don't execute yet)
      final queryset =
          QuerySet<DebugUser>(DebugUser, 'debug_users', 'test', (data) {
        print('Model factory called with data: $data');
        final user = DebugUser.fromMap(data);
        print('Model factory created user: ${user.name}');
        return user;
      });

      print('QuerySet created successfully');
      print('QuerySet SQL: ${queryset.toSql()}');
      print('QuerySet parameters: ${queryset.parameters}');

      print('Step 8: Attempting QuerySet.all()...');

      // Let's try to manually replicate what QuerySet.all() does
      print('Getting database connection...');
      final connection2 = await DatabaseRouter.getConnection('test');
      print('Got connection');

      try {
        print('Executing query...');
        final results2 =
            await connection2.query(queryset.toSql(), queryset.parameters);
        print('Query executed, results: $results2');

        print('Creating models...');
        final models = results2.map((data) => DebugUser.fromMap(data)).toList();
        print('Models created: ${models.length}');

        for (final model in models) {
          print('Model: ${model.name}');
        }
      } finally {
        print('Releasing connection...');
        await DatabaseRouter.releaseConnection(connection2, 'test');
        print('Connection released');
      }

      print('Now trying QuerySet.all()...');

      // This is where it might hang
      final querysetResults = await queryset.all();
      print('QuerySet results: ${querysetResults.length} items');

      for (final result in querysetResults) {
        print('User: ${result.name}');
      }

      expect(querysetResults.length, equals(1));
      expect(querysetResults.first.name, equals('Test User'));
    } catch (e, stackTrace) {
      print('Error occurred: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    } finally {
      await DatabaseRouter.releaseConnection(connection, 'test');
      await DatabaseRouter.closeAll();
    }
  });
}
