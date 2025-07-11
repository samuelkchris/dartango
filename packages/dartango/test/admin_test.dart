import 'dart:convert';
import 'package:test/test.dart';
import 'package:shelf/shelf.dart' as shelf;

import '../lib/src/core/admin/admin.dart';
import '../lib/src/core/auth/models.dart' as auth;
import '../lib/src/core/database/connection.dart';
import '../lib/src/core/http/request.dart';

void main() {
  group('Admin Backend Tests', () {
    late DatabaseConfig config;
    late AdminSite adminSite;
    late UserAdmin userAdmin;
    late GroupAdmin groupAdmin;
    auth.User? testUser;
    auth.User? staffUser;
    auth.Group? testGroup;

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
      adminSite.register<auth.User>(auth.User, userAdmin);
      adminSite.register<auth.Group>(auth.Group, groupAdmin);

      // Create test data
      testGroup = await auth.Group.createGroup('Test Group');

      testUser = await auth.User.createUser(
        username: 'testuser',
        email: 'test@example.com',
        password: 'password123',
        firstName: 'Test',
        lastName: 'User',
      );

      staffUser = await auth.User.createUser(
        username: 'staffuser',
        email: 'staff@example.com',
        password: 'password123',
        firstName: 'Staff',
        lastName: 'User',
        isStaff: true,
      );
    });

    tearDownAll(() async {
      // Cleanup database connections
      try {
        final connection = await DatabaseRouter.getConnection();
        await DatabaseRouter.releaseConnection(connection);
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    group('ModelAdmin Tests', () {
      test('should get queryset with search', () async {
        final users = await userAdmin.getQueryset(search: 'test');
        expect(users, isNotEmpty);
        expect(users.first.username, equals('testuser'));
      });

      test('should get queryset with filters', () async {
        final users = await userAdmin.getQueryset(filters: {'is_staff': true});
        expect(users, isNotEmpty);
        expect(users.first.isStaff, isTrue);
      });

      test('should get object by ID', () async {
        final user = await userAdmin.getObject(testUser!.id);
        expect(user, isNotNull);
        expect(user!.username, equals('testuser'));
      });

      test('should create object', () async {
        final userData = {
          'username': 'newuser',
          'email': 'new@example.com',
          'password': 'password123',
          'first_name': 'New',
          'last_name': 'User',
        };

        final user = await userAdmin.createObject(userData);
        expect(user.username, equals('newuser'));
        expect(user.email, equals('new@example.com'));
      });

      test('should update object', () async {
        final updateData = {
          'first_name': 'Updated',
          'last_name': 'Name',
        };

        final updatedUser =
            await userAdmin.updateObject(testUser!, updateData);
        expect(updatedUser.firstName, equals('Updated'));
        expect(updatedUser.lastName, equals('Name'));
      });

      test('should delete object', () async {
        // Create a user to delete
        final userToDelete = await auth.User.createUser(
          username: 'todelete',
          email: 'delete@example.com',
          password: 'password123',
        );

        await userAdmin.deleteObject(userToDelete);

        // Verify user is deleted
        final deletedUser = await userAdmin.getObject(userToDelete.id);
        expect(deletedUser, isNull);
      });
    });

    group('Permission Tests', () {
      test('should grant permissions for staff user', () async {
        final request = _createMockRequest('GET', '/admin/', user: staffUser);

        final hasAdd = await userAdmin.hasAddPermissionCheck(request);
        final hasChange = await userAdmin.hasChangePermissionCheck(request);
        final hasDelete = await userAdmin.hasDeletePermissionCheck(request);
        final hasView = await userAdmin.hasViewPermissionCheck(request);

        expect(hasAdd, isTrue);
        expect(hasChange, isTrue);
        expect(hasDelete, isTrue);
        expect(hasView, isTrue);
      });

      test('should deny permissions for non-staff user', () async {
        final request = _createMockRequest('GET', '/admin/', user: testUser);

        final hasAdd = await userAdmin.hasAddPermissionCheck(request);
        final hasChange = await userAdmin.hasChangePermissionCheck(request);
        final hasDelete = await userAdmin.hasDeletePermissionCheck(request);
        final hasView = await userAdmin.hasViewPermissionCheck(request);

        expect(hasAdd, isFalse);
        expect(hasChange, isFalse);
        expect(hasDelete, isFalse);
        expect(hasView, isFalse);
      });

      test('should allow all permissions for superuser', () async {
        final superUser = await auth.User.createSuperuser(
          username: 'superuser',
          email: 'super@example.com',
          password: 'password123',
        );

        final request = _createMockRequest('GET', '/admin/', user: superUser);

        final hasAdd = await userAdmin.hasAddPermissionCheck(request);
        final hasChange = await userAdmin.hasChangePermissionCheck(request);
        final hasDelete = await userAdmin.hasDeletePermissionCheck(request);
        final hasView = await userAdmin.hasViewPermissionCheck(request);

        expect(hasAdd, isTrue);
        expect(hasChange, isTrue);
        expect(hasDelete, isTrue);
        expect(hasView, isTrue);
      });
    });

    group('View Tests', () {
      test('should handle changelist view', () async {
        final request =
            _createMockRequest('GET', '/admin/admin/user/', user: staffUser);

        final response = await userAdmin.changelistView(request);
        expect(response.statusCode, equals(200));

        final responseData = jsonDecode(response.body as String) as Map<String, dynamic>;
        expect(responseData['objects'], isList);
        expect((responseData['objects'] as List).length, greaterThan(0));
      });

      test('should handle add view', () async {
        final request =
            _createMockRequest('GET', '/admin/admin/user/add/', user: staffUser);

        final response = await userAdmin.addView(request);
        expect(response.statusCode, equals(200));

        final responseData = jsonDecode(response.body as String) as Map<String, dynamic>;
        expect(responseData['form_fields'], isMap);
      });

      test('should handle change view', () async {
        final request = _createMockRequest(
            'GET', '/admin/admin/user/${testUser!.id}/change/', user: staffUser);

        final response = await userAdmin.changeView(request, testUser!.id);
        expect(response.statusCode, equals(200));

        final responseData = jsonDecode(response.body as String) as Map<String, dynamic>;
        expect(responseData['object'], isMap);
        final objectData = responseData['object'] as Map<String, dynamic>;
        expect(objectData['username'], equals(testUser!.username));
      });

      test('should handle delete view', () async {
        final userToDelete = await auth.User.createUser(
          username: 'willdelete',
          email: 'willdelete@example.com',
          password: 'password123',
        );

        final request = _createMockRequest(
            'GET', '/admin/admin/user/${userToDelete.id}/delete/', user: staffUser);

        final response = await userAdmin.deleteView(request, userToDelete.id);
        expect(response.statusCode, equals(200));

        final responseData = jsonDecode(response.body as String) as Map<String, dynamic>;
        expect(responseData['object'], isMap);
        final objectData = responseData['object'] as Map<String, dynamic>;
        expect(objectData['username'], equals(userToDelete.username));
      });
    });

    group('Group Admin Tests', () {
      test('should get group queryset', () async {
        final groups = await groupAdmin.getQueryset();
        expect(groups, isNotEmpty);
        expect(groups.first.name, equals('Test Group'));
      });

      test('should get group by ID', () async {
        final group = await groupAdmin.getObject(testGroup!.id);
        expect(group, isNotNull);
        expect(group!.name, equals('Test Group'));
      });
    });

    test('should setup default admin', () async {
      setupDefaultAdmin();
      expect(adminSite.isRegistered(auth.User), isTrue);
      expect(adminSite.isRegistered(auth.Group), isTrue);
    });
  });
}

Future<void> _createTables() async {
  final connection = await DatabaseRouter.getConnection();
  try {
    // Create auth_users table
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS auth_users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username VARCHAR(150) UNIQUE NOT NULL,
        email VARCHAR(254) NOT NULL,
        first_name VARCHAR(150) NOT NULL DEFAULT '',
        last_name VARCHAR(150) NOT NULL DEFAULT '',
        is_active BOOLEAN NOT NULL DEFAULT 1,
        is_staff BOOLEAN NOT NULL DEFAULT 0,
        is_superuser BOOLEAN NOT NULL DEFAULT 0,
        date_joined DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        last_login DATETIME,
        password VARCHAR(128) NOT NULL
      )
    ''');

    // Create auth_groups table
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS auth_groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(150) UNIQUE NOT NULL
      )
    ''');

    // Create auth_permissions table
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS auth_permissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(255) NOT NULL,
        codename VARCHAR(100) NOT NULL,
        content_type VARCHAR(100) NOT NULL
      )
    ''');

    // Create auth_user_groups table
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

    // Create auth_user_permissions table
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

    // Create auth_group_permissions table
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
  final uri = Uri.parse(path);
  final headers = <String, String>{
    'content-type': 'application/json',
  };

  final shelfRequest = shelf.Request(method, uri,
      headers: headers, body: data != null ? jsonEncode(data) : '');
  final request = HttpRequest(shelfRequest);

  if (user != null) {
    request.middlewareState['user'] = user;
  }

  return request;
}