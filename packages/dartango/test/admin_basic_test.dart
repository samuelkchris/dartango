import 'dart:convert';

import 'package:test/test.dart';
import 'package:shelf/shelf.dart' as shelf;

import '../lib/src/core/admin/admin_v2.dart';
import '../lib/src/core/auth/models_v2.dart' as auth;
import '../lib/src/core/database/connection.dart';
import '../lib/src/core/http/request.dart';

void main() {
  group('Admin Basic Tests', () {
    late DatabaseConfig config;
    late AdminSite adminSite;
    late UserAdmin userAdmin;
    late GroupAdmin groupAdmin;

    setUpAll(() async {
      // Use in-memory SQLite for testing
      config = DatabaseConfig(
        backend: DatabaseBackend.sqlite,
        database: ':memory:',
        maxConnections: 5,
        connectionTimeout: Duration(seconds: 30),
      );

      // Register database configuration
      DatabaseRouter.registerDatabase('default', config);

      // Create database tables
      await _createTables();

      // Setup admin site
      adminSite = AdminSite();
      userAdmin = UserAdmin(adminSite: adminSite);
      groupAdmin = GroupAdmin(adminSite: adminSite);

      // Register models
      adminSite.register<auth.User>('user', userAdmin);
      adminSite.register<auth.Group>('group', groupAdmin);
    });

    tearDownAll(() async {
      // Close database connections
      try {
        final connection = await DatabaseRouter.getConnection();
        await DatabaseRouter.releaseConnection(connection);
      } catch (e) {
        // Ignore errors during cleanup
      }
    });

    test('should create admin site', () async {
      expect(adminSite, isNotNull);
      expect(adminSite.name, equals('admin'));
      expect(adminSite.adminUrl, equals('/admin/'));
    });

    test('should register model admins', () async {
      expect(adminSite.isRegistered('user'), isTrue);
      expect(adminSite.isRegistered('group'), isTrue);

      final modelAdmin = adminSite.getModelAdmin('user');
      expect(modelAdmin, isNotNull);
      expect(modelAdmin, isA<UserAdmin>());
    });

    test('should create user admin', () async {
      expect(userAdmin, isNotNull);
      expect(userAdmin.modelName, equals('user'));
      expect(userAdmin.listDisplay, contains('username'));
      expect(userAdmin.listDisplay, contains('email'));
      expect(userAdmin.searchFields, contains('username'));
      expect(userAdmin.searchFields, contains('email'));
    });

    test('should create group admin', () async {
      expect(groupAdmin, isNotNull);
      expect(groupAdmin.modelName, equals('group'));
      expect(groupAdmin.listDisplay, contains('name'));
      expect(groupAdmin.searchFields, contains('name'));
    });

    test('should create user and test CRUD operations', () async {
      // Create user
      final userData = {
        'username': 'testuser',
        'email': 'test@example.com',
        'password': 'password123',
        'first_name': 'Test',
        'last_name': 'User',
        'is_active': true,
        'is_staff': false,
        'is_superuser': false,
      };

      final newUser = await userAdmin.createObject(userData);
      expect(newUser.username, equals('testuser'));
      expect(newUser.email, equals('test@example.com'));

      // Get user
      final fetchedUser = await userAdmin.getObject(newUser.id);
      expect(fetchedUser, isNotNull);
      expect(fetchedUser!.username, equals('testuser'));

      // Update user
      final updateData = {
        'username': 'testuser',
        'email': 'test@example.com',
        'first_name': 'Updated',
        'last_name': 'Name',
        'is_active': true,
        'is_staff': true,
        'is_superuser': false,
      };

      final updatedUser = await userAdmin.updateObject(fetchedUser, updateData);
      expect(updatedUser.firstName, equals('Updated'));
      expect(updatedUser.lastName, equals('Name'));
      expect(updatedUser.isStaff, isTrue);

      // Test queryset
      final users = await userAdmin.getQueryset();
      expect(users, isNotEmpty);
      expect(users.any((u) => u.username == 'testuser'), isTrue);

      // Delete user
      await userAdmin.deleteObject(updatedUser);

      final deletedUser = await userAdmin.getObject(newUser.id);
      expect(deletedUser, isNull);
    });

    test('should create group and test CRUD operations', () async {
      // Create group
      final groupData = {
        'name': 'Test Group',
      };

      final newGroup = await groupAdmin.createObject(groupData);
      expect(newGroup.name, equals('Test Group'));

      // Get group
      final fetchedGroup = await groupAdmin.getObject(newGroup.id);
      expect(fetchedGroup, isNotNull);
      expect(fetchedGroup!.name, equals('Test Group'));

      // Update group
      final updateData = {
        'name': 'Updated Group',
      };

      final updatedGroup =
          await groupAdmin.updateObject(fetchedGroup, updateData);
      expect(updatedGroup.name, equals('Updated Group'));

      // Test queryset
      final groups = await groupAdmin.getQueryset();
      expect(groups, isNotEmpty);
      expect(groups.any((g) => g.name == 'Updated Group'), isTrue);

      // Delete group
      await groupAdmin.deleteObject(updatedGroup);

      final deletedGroup = await groupAdmin.getObject(newGroup.id);
      expect(deletedGroup, isNull);
    });

    test('should handle admin forms', () async {
      // Test user form
      final userForm = userAdmin.getForm();
      expect(userForm, isNotNull);
      expect(userForm.fields.containsKey('username'), isTrue);
      expect(userForm.fields.containsKey('email'), isTrue);
      expect(userForm.fields.containsKey('password'), isTrue);
      expect(userForm.fields.containsKey('first_name'), isTrue);
      expect(userForm.fields.containsKey('last_name'), isTrue);
      expect(userForm.fields.containsKey('is_active'), isTrue);
      expect(userForm.fields.containsKey('is_staff'), isTrue);
      expect(userForm.fields.containsKey('is_superuser'), isTrue);

      // Test group form
      final groupForm = groupAdmin.getForm();
      expect(groupForm, isNotNull);
      expect(groupForm.fields.containsKey('name'), isTrue);
    });

    test('should handle admin views without user', () async {
      final request = _createMockRequest('GET', '/admin/admin/user/');

      final response = await userAdmin.changelistView(request);
      expect(response.statusCode, equals(403));
    });

    test('should handle admin site login view', () async {
      final request = _createMockRequest('GET', '/admin/login/');

      final response = await adminSite.loginView(request);
      expect(response.statusCode, equals(200));

      final responseData = json.decode(response.body as String);
      expect(responseData['title'], equals('Log in'));
      expect(responseData['site_header'], equals('Dartango Administration'));
    });

    test('should handle admin site index without user', () async {
      final request = _createMockRequest('GET', '/admin/');

      final response = await adminSite.indexView(request);
      expect(response.statusCode, equals(302));
      expect(response.headers['Location'], equals('/admin/login/'));
    });

    test('should handle admin site logout', () async {
      final request = _createMockRequest('POST', '/admin/logout/');

      final response = await adminSite.logoutView(request);
      expect(response.statusCode, equals(200));

      final responseData = json.decode(response.body as String);
      expect(responseData['success'], isTrue);
      expect(responseData['redirect'], equals('/admin/login/'));
    });

    test('should handle search functionality', () async {
      // Create test user
      final testUser = await auth.User.createUser(
        username: 'searchuser',
        email: 'search@example.com',
        password: 'password123',
        firstName: 'Search',
        lastName: 'User',
      );

      // Search for user
      final users = await userAdmin.getQueryset(search: 'search');
      expect(users, isNotEmpty);
      expect(users.any((u) => u.username == 'searchuser'), isTrue);

      // Clean up
      await userAdmin.deleteObject(testUser);
    });

    test('should handle filtering', () async {
      // Create test users
      final staffUser = await auth.User.createUser(
        username: 'staffuser',
        email: 'staff@example.com',
        password: 'password123',
        isStaff: true,
      );

      final regularUser = await auth.User.createUser(
        username: 'regularuser',
        email: 'regular@example.com',
        password: 'password123',
        isStaff: false,
      );

      // Filter staff users
      final staffUsers = await userAdmin.getQueryset(filters: {'is_staff': 1});
      expect(staffUsers, isNotEmpty);
      expect(staffUsers.any((u) => u.username == 'staffuser'), isTrue);
      expect(staffUsers.any((u) => u.username == 'regularuser'), isFalse);

      // Clean up
      await userAdmin.deleteObject(staffUser);
      await userAdmin.deleteObject(regularUser);
    });

    test('should handle pagination', () async {
      // Create multiple test users
      final users = <auth.User>[];
      for (int i = 0; i < 5; i++) {
        final user = await auth.User.createUser(
          username: 'user$i',
          email: 'user$i@example.com',
          password: 'password123',
        );
        users.add(user);
      }

      // Test pagination
      final firstPage = await userAdmin.getQueryset(limit: 2, offset: 0);
      expect(firstPage, hasLength(2));

      final secondPage = await userAdmin.getQueryset(limit: 2, offset: 2);
      expect(secondPage, hasLength(2));

      // Clean up
      for (final user in users) {
        await userAdmin.deleteObject(user);
      }
    });

    test('should handle ordering', () async {
      // Create test users
      final userA = await auth.User.createUser(
        username: 'auser',
        email: 'a@example.com',
        password: 'password123',
      );

      final userZ = await auth.User.createUser(
        username: 'zuser',
        email: 'z@example.com',
        password: 'password123',
      );

      // Test ascending order
      final ascending = await userAdmin.getQueryset(ordering: 'username ASC');
      expect(ascending.first.username, equals('auser'));

      // Test descending order
      final descending = await userAdmin.getQueryset(ordering: 'username DESC');
      expect(descending.first.username, equals('zuser'));

      // Clean up
      await userAdmin.deleteObject(userA);
      await userAdmin.deleteObject(userZ);
    });

    test('should handle setup default admin', () async {
      final testSite = AdminSite();

      // Test the setup function
      testSite.register<auth.User>('user', UserAdmin(adminSite: testSite));
      testSite.register<auth.Group>('group', GroupAdmin(adminSite: testSite));

      expect(testSite.isRegistered('user'), isTrue);
      expect(testSite.isRegistered('group'), isTrue);

      final userAdminInstance = testSite.getModelAdmin('user');
      expect(userAdminInstance, isNotNull);
      expect(userAdminInstance, isA<UserAdmin>());

      final groupAdminInstance = testSite.getModelAdmin('group');
      expect(groupAdminInstance, isNotNull);
      expect(groupAdminInstance, isA<GroupAdmin>());
    });
  });
}

// Helper functions
Future<void> _createTables() async {
  final connection = await DatabaseRouter.getConnection();
  try {
    // Create auth_users table
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS auth_users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL,
        first_name TEXT,
        last_name TEXT,
        password TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        is_staff INTEGER DEFAULT 0,
        is_superuser INTEGER DEFAULT 0,
        date_joined TEXT NOT NULL,
        last_login TEXT
      )
    ''');

    // Create auth_groups table
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS auth_groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // Create auth_permissions table
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS auth_permissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        content_type TEXT NOT NULL,
        codename TEXT NOT NULL,
        UNIQUE(content_type, codename)
      )
    ''');

    // Create junction tables
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS auth_user_groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        group_id INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES auth_users (id),
        FOREIGN KEY (group_id) REFERENCES auth_groups (id),
        UNIQUE(user_id, group_id)
      )
    ''');

    await connection.execute('''
      CREATE TABLE IF NOT EXISTS auth_user_permissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        permission_id INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES auth_users (id),
        FOREIGN KEY (permission_id) REFERENCES auth_permissions (id),
        UNIQUE(user_id, permission_id)
      )
    ''');

    await connection.execute('''
      CREATE TABLE IF NOT EXISTS auth_group_permissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        permission_id INTEGER NOT NULL,
        FOREIGN KEY (group_id) REFERENCES auth_groups (id),
        FOREIGN KEY (permission_id) REFERENCES auth_permissions (id),
        UNIQUE(group_id, permission_id)
      )
    ''');
  } finally {
    await DatabaseRouter.releaseConnection(connection);
  }
}

HttpRequest _createMockRequest(String method, String path,
    {auth.User? user, Map<String, dynamic>? data}) {
  final uri = Uri.parse('http://localhost$path');
  final headers = <String, String>{
    'content-type': 'application/json',
  };

  final shelfRequest = shelf.Request(method, uri,
      headers: headers, body: data != null ? json.encode(data) : '');
  final request = HttpRequest(shelfRequest);

  if (user != null) {
    request.middlewareState['user'] = user;
  }

  return request;
}
