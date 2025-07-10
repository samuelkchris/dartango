import 'dart:async';
import 'package:test/test.dart';
import 'package:dartango/src/core/database/connection.dart';
import 'package:dartango/src/core/database/models.dart';
import 'package:dartango/src/core/database/fields.dart';
import 'package:dartango/src/core/database/queryset.dart';
import 'package:dartango/src/core/database/exceptions.dart';

// Test model class
class TestUser extends Model {
  TestUser() : super(tableName: 'test_users');
  
  @override
  Map<String, Field> get fields => {
    'id': AutoField(primaryKey: true),
    'name': CharField(maxLength: 100),
    'email': EmailField(),
    'age': IntegerField(null: true),
    'is_active': BooleanField(defaultValue: true),
  };
  
  static TestUser fromMap(Map<String, dynamic> data) {
    final user = TestUser();
    user.fromMapInternal(data);
    return user;
  }
  
  String get name => getField('name');
  set name(String value) => setField('name', value);
  
  String get email => getField('email');
  set email(String value) => setField('email', value);
  
  int? get age => getField('age');
  set age(int? value) => setField('age', value);
  
  bool get isActive => getField('is_active');
  set isActive(bool value) => setField('is_active', value);
}

void main() {
  late DatabaseConnection connection;
  
  setUpAll(() async {
    // Set up test database
    final config = DatabaseConfig(
      database: ':memory:',
      backend: DatabaseBackend.sqlite,
    );
    DatabaseRouter.registerDatabase('test', config);
    connection = await DatabaseRouter.getConnection('test');
    
    // Create test table
    await connection.execute('''
      CREATE TABLE test_users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE,
        age INTEGER,
        is_active BOOLEAN DEFAULT 1
      )
    ''');
    
    // Insert test data
    await connection.execute(
      'INSERT INTO test_users (name, email, age, is_active) VALUES (?, ?, ?, ?)',
      ['Alice Johnson', 'alice@example.com', 25, true]
    );
    await connection.execute(
      'INSERT INTO test_users (name, email, age, is_active) VALUES (?, ?, ?, ?)',
      ['Bob Smith', 'bob@example.com', 30, true]
    );
    await connection.execute(
      'INSERT INTO test_users (name, email, age, is_active) VALUES (?, ?, ?, ?)',
      ['Charlie Brown', 'charlie@example.com', 35, false]
    );
    await connection.execute(
      'INSERT INTO test_users (name, email, age, is_active) VALUES (?, ?, ?, ?)',
      ['Diana Prince', 'diana@example.com', 28, true]
    );
  });
  
  tearDownAll(() async {
    await DatabaseRouter.closeAll();
  });

  group('QuerySet Basic Operations', () {
    test('should retrieve all records', () async {
      final queryset = QuerySet<TestUser>(TestUser, 'test_users', 'test');
      final users = await queryset.all();
      
      expect(users.length, equals(4));
      expect(users[0].name, equals('Alice Johnson'));
      expect(users[1].name, equals('Bob Smith'));
    });
    
    test('should get first record', () async {
      final queryset = QuerySet<TestUser>(TestUser, 'test_users', 'test');
      final user = await queryset.first();
      
      expect(user, isNotNull);
      expect(user!.name, equals('Alice Johnson'));
    });
    
    test('should get last record', () async {
      final queryset = QuerySet<TestUser>(TestUser, 'test_users', 'test')
          .orderBy(['id']);
      final user = await queryset.last();
      
      expect(user, isNotNull);
      expect(user!.name, equals('Diana Prince'));
    });
    
    test('should count records', () async {
      final queryset = QuerySet<TestUser>(TestUser, 'test_users', 'test');
      final count = await queryset.count();
      
      expect(count, equals(4));
    });
    
    test('should check if records exist', () async {
      final queryset = QuerySet<TestUser>(TestUser, 'test_users', 'test');
      final exists = await queryset.exists();
      
      expect(exists, isTrue);
      
      final emptyQueryset = queryset.filter({'name': 'Nonexistent'});
      final notExists = await emptyQueryset.exists();
      
      expect(notExists, isFalse);
    });
  });

  group('QuerySet Filtering', () {
    test('should filter by exact match', () async {
      final queryset = QuerySet<TestUser>(TestUser, 'test_users', 'test');
      final users = await queryset.filter({'name': 'Alice Johnson'}).all();
      
      expect(users.length, equals(1));
      expect(users[0].name, equals('Alice Johnson'));
      expect(users[0].email, equals('alice@example.com'));
    });
    
    test('should filter by multiple conditions', () async {
      final queryset = QuerySet<TestUser>(TestUser, 'test_users', 'test');
      final users = await queryset.filter({
        'is_active': true,
        'age__gte': 30,
      }).all();
      
      expect(users.length, equals(1));
      expect(users[0].name, equals('Bob Smith'));
    });
    
    test('should filter with lookup types', () async {
      final queryset = QuerySet<TestUser>(TestUser, 'test_users', 'test');
      
      // Test contains lookup
      final containsUsers = await queryset.filter({'name__contains': 'Johnson'}).all();
      expect(containsUsers.length, equals(1));
      expect(containsUsers[0].name, equals('Alice Johnson'));
      
      // Test startswith lookup
      final startsWithUsers = await queryset.filter({'name__startswith': 'Bob'}).all();
      expect(startsWithUsers.length, equals(1));
      expect(startsWithUsers[0].name, equals('Bob Smith'));
      
      // Test greater than lookup
      final gtUsers = await queryset.filter({'age__gt': 30}).all();
      expect(gtUsers.length, equals(1));
      expect(gtUsers[0].name, equals('Charlie Brown'));
      
      // Test less than or equal lookup
      final lteUsers = await queryset.filter({'age__lte': 28}).all();
      expect(lteUsers.length, equals(2));
    });
    
    test('should exclude records', () async {
      final queryset = QuerySet<TestUser>(TestUser, 'test_users', 'test');
      final users = await queryset.exclude({'is_active': false}).all();
      
      expect(users.length, equals(3));
      expect(users.any((u) => u.name == 'Charlie Brown'), isFalse);
    });
    
    test('should filter with raw WHERE clause', () async {
      final queryset = QuerySet<TestUser>(TestUser, 'test_users', 'test');
      final users = await queryset.where('age BETWEEN ? AND ?', [25, 30]).all();
      
      expect(users.length, equals(3));
    });
  });

  group('QuerySet Ordering', () {
    test('should order by single field ascending', () async {
      final queryset = QuerySet<TestUser>(TestUser, 'test_users', 'test');
      final users = await queryset.orderBy(['age']).all();
      
      expect(users[0].age, equals(25));
      expect(users[1].age, equals(28));
      expect(users[2].age, equals(30));
      expect(users[3].age, equals(35));
    });
    
    test('should order by single field descending', () async {
      final queryset = QuerySet<TestUser>(TestUser, 'test_users', 'test');
      final users = await queryset.orderBy(['-age']).all();
      
      expect(users[0].age, equals(35));
      expect(users[1].age, equals(30));
      expect(users[2].age, equals(28));
      expect(users[3].age, equals(25));
    });
    
    test('should order by multiple fields', () async {
      final queryset = QuerySet<TestUser>(TestUser, 'test_users', 'test');
      final users = await queryset.orderBy(['is_active', '-age']).all();
      
      // First inactive users (Charlie), then active users by age desc
      expect(users[0].name, equals('Charlie Brown')); // inactive
      expect(users[1].age, equals(30)); // Bob - active, age 30
      expect(users[2].age, equals(28)); // Diana - active, age 28
      expect(users[3].age, equals(25)); // Alice - active, age 25
    });
    
    test('should reverse ordering', () async {
      final queryset = QuerySet<TestUser>(TestUser, 'test_users', 'test');
      final orderedUsers = await queryset.orderBy(['age']).all();
      final reversedUsers = await queryset.orderBy(['age']).reverse().all();
      
      expect(orderedUsers[0].age, equals(reversedUsers[3].age));
      expect(orderedUsers[3].age, equals(reversedUsers[0].age));
    });
  });

  group('QuerySet Slicing', () {
    test('should limit results', () async {
      final queryset = QuerySet<TestUser>(TestUser, 'test_users', 'test');
      final users = await queryset.limit(2).all();
      
      expect(users.length, equals(2));
    });
    
    test('should offset results', () async {
      final queryset = QuerySet<TestUser>(TestUser, 'test_users', 'test');
      final allUsers = await queryset.orderBy(['id']).all();
      final offsetUsers = await queryset.orderBy(['id']).offset(2).all();
      
      expect(offsetUsers.length, equals(2));
      expect(offsetUsers[0].name, equals(allUsers[2].name));
    });
    
    test('should combine limit and offset', () async {
      final queryset = QuerySet<TestUser>(TestUser, 'test_users', 'test');
      final users = await queryset.orderBy(['id']).offset(1).limit(2).all();
      
      expect(users.length, equals(2));
      expect(users[0].name, equals('Bob Smith'));
      expect(users[1].name, equals('Charlie Brown'));
    });
  });

  group('QuerySet Get Operations', () {
    test('should get single record', () async {
      final queryset = QuerySet<TestUser>(TestUser, 'test_users', 'test');
      final user = await queryset.get({'email': 'alice@example.com'});
      
      expect(user.name, equals('Alice Johnson'));
      expect(user.email, equals('alice@example.com'));
    });
    
    test('should throw DoesNotExistException for missing record', () async {
      final queryset = QuerySet<TestUser>(TestUser, 'test_users', 'test');
      
      expect(
        () => queryset.get({'email': 'nonexistent@example.com'}),
        throwsA(isA<DoesNotExistException>())
      );
    });
    
    test('should throw MultipleObjectsReturnedException for multiple records', () async {
      final queryset = QuerySet<TestUser>(TestUser, 'test_users', 'test');
      
      expect(
        () => queryset.get({'is_active': true}),
        throwsA(isA<MultipleObjectsReturnedException>())
      );
    });
    
    test('should return null for getOrNull with missing record', () async {
      final queryset = QuerySet<TestUser>(TestUser, 'test_users', 'test');
      final user = await queryset.getOrNull({'email': 'nonexistent@example.com'});
      
      expect(user, isNull);
    });
  });

  group('QuerySet Modification Operations', () {
    test('should update records', () async {
      final queryset = QuerySet<TestUser>(TestUser, 'test_users', 'test');
      final affectedRows = await queryset
          .filter({'name': 'Alice Johnson'})
          .update({'age': 26});
      
      expect(affectedRows, equals(1));
      
      // Verify update
      final user = await queryset.get({'name': 'Alice Johnson'});
      expect(user.age, equals(26));
    });
    
    test('should delete records', () async {
      // First, add a test record to delete
      await connection.execute(
        'INSERT INTO test_users (name, email, age) VALUES (?, ?, ?)',
        ['Test Delete', 'delete@example.com', 99]
      );
      
      final queryset = QuerySet<TestUser>(TestUser, 'test_users', 'test');
      final initialCount = await queryset.count();
      
      final deletedRows = await queryset
          .filter({'email': 'delete@example.com'})
          .delete();
      
      expect(deletedRows, equals(1));
      
      final finalCount = await queryset.count();
      expect(finalCount, equals(initialCount - 1));
    });
  });

  group('QuerySet Chaining', () {
    test('should chain multiple operations', () async {
      final queryset = QuerySet<TestUser>(TestUser, 'test_users', 'test');
      final users = await queryset
          .filter({'is_active': true})
          .exclude({'age__lt': 28})
          .orderBy(['-age'])
          .limit(2)
          .all();
      
      expect(users.length, equals(2));
      expect(users[0].age, equals(30)); // Bob
      expect(users[1].age, equals(28)); // Diana
    });
    
    test('should create independent clones', () async {
      final baseQueryset = QuerySet<TestUser>(TestUser, 'test_users', 'test');
      final filtered1 = baseQueryset.filter({'is_active': true});
      final filtered2 = baseQueryset.filter({'age__gte': 30});
      
      final count1 = await filtered1.count();
      final count2 = await filtered2.count();
      final baseCount = await baseQueryset.count();
      
      expect(count1, equals(3)); // Active users
      expect(count2, equals(2)); // Users >= 30
      expect(baseCount, equals(4)); // All users
    });
  });

  group('QuerySet Distinct Operations', () {
    test('should apply distinct to query', () async {
      // Insert duplicate data for testing
      await connection.execute(
        'INSERT INTO test_users (name, email, age) VALUES (?, ?, ?)',
        ['Alice Johnson', 'alice2@example.com', 25]
      );
      
      final queryset = QuerySet<TestUser>(TestUser, 'test_users', 'test');
      final distinctUsers = await queryset
          .distinct()
          .values(['age'])
          .orderBy(['age'])
          .all();
      
      final ages = distinctUsers.map((u) => u.age).toSet();
      expect(ages.length, greaterThanOrEqualTo(4));
    });
  });
}