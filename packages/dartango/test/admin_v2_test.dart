import 'dart:convert';
import 'package:test/test.dart';
import 'package:shelf/shelf.dart' as shelf;

import '../lib/src/core/admin/admin_v2.dart';
import '../lib/src/core/auth/models.dart' as auth;
import '../lib/src/core/database/connection.dart';
import '../lib/src/core/http/request.dart';

void main() {
  group('Admin V2 Backend Tests', () {
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

      // Register models using BaseAdmin interface - skip for now due to type mismatch
      // adminSite.register<auth.User>('User', userAdmin);
      // adminSite.register<auth.Group>('Group', groupAdmin);

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

    group('ModelAdmin V2 Tests', () {
      test('should get queryset with search', () async {
        final users = await userAdmin.getQueryset(search: 'test');
        expect(users, isNotEmpty);
        expect(users.first.username, equals('testuser'));
      });

      test('should get object by ID', () async {
        final user = await userAdmin.getObject(testUser!.id);
        expect(user, isNotNull);
        expect(user!.username, equals('testuser'));
      });

      test('should create and delete objects', () async {
        final userData = {
          'username': 'tempuser',
          'email': 'temp@example.com',
          'password': 'password123',
        };

        final user = await userAdmin.createObject(userData);
        expect(user.username, equals('tempuser'));

        await userAdmin.deleteObject(user);
        final deletedUser = await userAdmin.getObject(user.id);
        expect(deletedUser, isNull);
      });
    });

    group('Group Admin V2 Tests', () {
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

    group('Permission Tests V2', () {
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
    });

    test('should setup admin registry', () async {
      // Register models for testing
      adminSite.register('User', userAdmin as BaseAdmin);
      adminSite.register('Group', groupAdmin as BaseAdmin);
      
      expect(adminSite.isRegistered('User'), isTrue);
      expect(adminSite.isRegistered('Group'), isTrue);
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