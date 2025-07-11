import 'dart:io';
import 'package:test/test.dart';
import 'package:dartango/src/core/database/connection.dart';
import 'package:dartango/src/core/auth/models_v2.dart';
import 'package:dartango/src/core/auth/migrations.dart';

void main() {
  late DatabaseConnection connection;

  setUpAll(() async {
    // Set up test database
    final config = DatabaseConfig(
      database: 'test_auth_v2.db',
      backend: DatabaseBackend.sqlite,
      minConnections: 1,
      maxConnections: 5,
    );
    DatabaseRouter.registerDatabase('test', config);
    connection = await DatabaseRouter.getConnection('test');

    // Run auth migrations
    await AuthMigrations.runMigrations(database: 'test');
  });

  tearDown(() async {
    // Clean up test data between tests
    try {
      await connection.execute('DELETE FROM auth_user_permissions');
      await connection.execute('DELETE FROM auth_group_permissions');
      await connection.execute('DELETE FROM auth_user_groups');
      await connection.execute('DELETE FROM auth_users');
      await connection.execute('DELETE FROM auth_groups');
      await connection
          .execute('DELETE FROM auth_permissions WHERE content_type != "auth"');
    } catch (e) {
      // Ignore cleanup errors
    }
  });

  tearDownAll(() async {
    await DatabaseRouter.releaseConnection(connection, 'test');
    await DatabaseRouter.closeAll();
    // Clean up test database file
    try {
      final file = File('test_auth_v2.db');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  });

  group('User Model V2 Tests', () {
    test('should create and save user', () async {
      final user = await User.createUser(
        username: 'testuser',
        email: 'test@example.com',
        password: 'testpass123',
        firstName: 'Test',
        lastName: 'User',
        database: 'test',
      );

      expect(user.id, greaterThan(0));
      expect(user.username, equals('testuser'));
      expect(user.email, equals('test@example.com'));
      expect(user.firstName, equals('Test'));
      expect(user.lastName, equals('User'));
      expect(user.isActive, isTrue);
      expect(user.isStaff, isFalse);
      expect(user.isSuperuser, isFalse);
      expect(user.isAuthenticated, isTrue);
      expect(user.isAnonymous, isFalse);
      expect(user.fullName, equals('Test User'));
      expect(user.shortName, equals('Test'));
    });

    test('should create superuser', () async {
      final user = await User.createSuperuser(
        username: 'admin',
        email: 'admin@example.com',
        password: 'adminpass123',
        database: 'test',
      );

      expect(user.username, equals('admin'));
      expect(user.isActive, isTrue);
      expect(user.isStaff, isTrue);
      expect(user.isSuperuser, isTrue);
    });

    test('should find user by username', () async {
      await User.createUser(
        username: 'findme',
        email: 'findme@example.com',
        password: 'password123',
        database: 'test',
      );

      final user = await User.getUserByUsername('findme', database: 'test');
      expect(user, isNotNull);
      expect(user!.username, equals('findme'));
      expect(user.email, equals('findme@example.com'));
    });

    test('should find user by email', () async {
      await User.createUser(
        username: 'emailuser',
        email: 'email@example.com',
        password: 'password123',
        database: 'test',
      );

      final user =
          await User.getUserByEmail('email@example.com', database: 'test');
      expect(user, isNotNull);
      expect(user!.username, equals('emailuser'));
      expect(user.email, equals('email@example.com'));
    });

    test('should find user by id', () async {
      final createdUser = await User.createUser(
        username: 'iduser',
        email: 'id@example.com',
        password: 'password123',
        database: 'test',
      );

      final user = await User.getUserById(createdUser.id, database: 'test');
      expect(user, isNotNull);
      expect(user!.id, equals(createdUser.id));
      expect(user.username, equals('iduser'));
    });

    test('should hash and verify password', () async {
      final user = await User.createUser(
        username: 'passworduser',
        email: 'pwd@example.com',
        password: 'mypassword123',
        database: 'test',
      );

      expect(user.checkPassword('mypassword123'), isTrue);
      expect(user.checkPassword('wrongpassword'), isFalse);

      // Test password change
      user.setPassword('newpassword456');
      await user.save();

      expect(user.checkPassword('newpassword456'), isTrue);
      expect(user.checkPassword('mypassword123'), isFalse);
    });

    test('should update last login', () async {
      final user = await User.createUser(
        username: 'loginuser',
        email: 'login@example.com',
        password: 'password123',
        database: 'test',
      );

      expect(user.lastLogin, isNull);

      await user.updateLastLogin();
      expect(user.lastLogin, isNotNull);
      expect(user.lastLogin!.difference(DateTime.now()).inSeconds.abs(),
          lessThan(5));
    });

    test('should update user fields', () async {
      final user = await User.createUser(
        username: 'updateuser',
        email: 'update@example.com',
        password: 'password123',
        database: 'test',
      );

      user.firstName = 'Updated';
      user.lastName = 'Name';
      user.email = 'updated@example.com';
      await user.save();

      // Verify changes were saved
      final reloadedUser = await User.getUserById(user.id, database: 'test');
      expect(reloadedUser!.firstName, equals('Updated'));
      expect(reloadedUser.lastName, equals('Name'));
      expect(reloadedUser.email, equals('updated@example.com'));
    });

    test('should delete user', () async {
      final user = await User.createUser(
        username: 'deleteuser',
        email: 'delete@example.com',
        password: 'password123',
        database: 'test',
      );

      final userId = user.id;
      await user.delete();

      // Verify user was deleted
      final deletedUser = await User.getUserById(userId, database: 'test');
      expect(deletedUser, isNull);
    });

    test('should refresh user data', () async {
      final user = await User.createUser(
        username: 'refreshuser',
        email: 'refresh@example.com',
        password: 'password123',
        database: 'test',
      );

      // Modify user directly in database
      await connection.execute(
          'UPDATE auth_users SET first_name = ? WHERE id = ?',
          ['DirectlyModified', user.id]);

      // User object still has old data
      expect(user.firstName, equals(''));

      // Refresh should load new data
      await user.refresh();
      expect(user.firstName, equals('DirectlyModified'));
    });

    test('should track field changes', () async {
      final user = await User.createUser(
        username: 'trackuser',
        email: 'track@example.com',
        password: 'password123',
        database: 'test',
      );

      expect(user.hasChanged, isFalse);
      expect(user.changedFields.isEmpty, isTrue);

      user.firstName = 'Changed';
      user.lastName = 'Also';

      expect(user.hasChanged, isTrue);
      expect(user.changedFields.contains('first_name'), isTrue);
      expect(user.changedFields.contains('last_name'), isTrue);

      await user.save();

      expect(user.hasChanged, isFalse);
      expect(user.changedFields.isEmpty, isTrue);
    });
  });

  group('Group Model V2 Tests', () {
    test('should create and save group', () async {
      final group = await Group.createGroup('Test Group', database: 'test');

      expect(group.id, greaterThan(0));
      expect(group.name, equals('Test Group'));
    });

    test('should find group by name', () async {
      await Group.createGroup('Findable Group', database: 'test');

      final group =
          await Group.getGroupByName('Findable Group', database: 'test');
      expect(group, isNotNull);
      expect(group!.name, equals('Findable Group'));
    });

    test('should manage group permissions', () async {
      final group =
          await Group.createGroup('Permission Group', database: 'test');
      final permission = await Permission.createPermission(
        name: 'Test Permission',
        codename: 'test_perm',
        contentType: 'testapp',
        database: 'test',
      );

      // Add permission to group
      await group.addPermission(permission);

      // Verify permission was added
      final permissions = await group.getPermissions();
      expect(permissions.length, equals(1));
      expect(permissions.first.codename, equals('test_perm'));

      // Remove permission from group
      await group.removePermission(permission);

      // Verify permission was removed
      final permissionsAfterRemoval = await group.getPermissions();
      expect(permissionsAfterRemoval.length, equals(0));
    });
  });

  group('Permission Model V2 Tests', () {
    test('should create permission', () async {
      final permission = await Permission.createPermission(
        name: 'Can test something',
        codename: 'test_something',
        contentType: 'testapp',
        database: 'test',
      );

      expect(permission.id, greaterThan(0));
      expect(permission.name, equals('Can test something'));
      expect(permission.codename, equals('test_something'));
      expect(permission.contentType, equals('testapp'));
      expect(permission.fullName, equals('testapp.test_something'));
    });

    test('should find permission by content type and codename', () async {
      await Permission.createPermission(
        name: 'Can find permission',
        codename: 'find_permission',
        contentType: 'testapp',
        database: 'test',
      );

      final permission = await Permission.getPermission(
          'testapp', 'find_permission',
          database: 'test');
      expect(permission, isNotNull);
      expect(permission!.name, equals('Can find permission'));
    });
  });

  group('Permission System V2 Tests', () {
    test('should check superuser permissions', () async {
      final superuser = await User.createSuperuser(
        username: 'super',
        email: 'super@example.com',
        password: 'password123',
        database: 'test',
      );

      expect(await superuser.hasPermission('any.permission'), isTrue);
      expect(await superuser.hasModulePermission('any_app'), isTrue);
    });

    test('should manage user permissions through direct assignment', () async {
      final user = await User.createUser(
        username: 'permuser',
        email: 'perm@example.com',
        password: 'password123',
        database: 'test',
      );

      // User should not have permission initially
      expect(await user.hasPermission('testapp.test_permission'), isFalse);

      // Create permission and add to user manually via database
      final permission = await Permission.createPermission(
        name: 'Test Permission',
        codename: 'test_permission',
        contentType: 'testapp',
        database: 'test',
      );

      await connection.execute(
          'INSERT INTO auth_user_permissions (user_id, permission_id) VALUES (?, ?)',
          [user.id, permission.id]);

      // User should now have permission
      expect(await user.hasPermission('testapp.test_permission'), isTrue);
    });

    test('should manage user permissions through groups', () async {
      final user = await User.createUser(
        username: 'groupuser',
        email: 'group@example.com',
        password: 'password123',
        database: 'test',
      );

      final group =
          await Group.createGroup('Test Permission Group', database: 'test');

      final permission = await Permission.createPermission(
        name: 'Can test group permission',
        codename: 'test_group_permission',
        contentType: 'testapp',
        database: 'test',
      );

      // Add permission to group
      await group.addPermission(permission);

      // Add user to group manually via database
      await connection.execute(
          'INSERT INTO auth_user_groups (user_id, group_id) VALUES (?, ?)',
          [user.id, group.id]);

      // User should have permission through group
      expect(await user.hasPermission('testapp.test_group_permission'), isTrue);

      // Test group methods
      final groupPermissions = await group.getPermissions();
      expect(groupPermissions.length, equals(1));
      expect(groupPermissions.first.codename, equals('test_group_permission'));

      // Remove permission from group
      await group.removePermission(permission);
      expect(
          await user.hasPermission('testapp.test_group_permission'), isFalse);
    });

    test('should get all user permissions from direct and group assignments',
        () async {
      final user = await User.createUser(
        username: 'allperms',
        email: 'allperms@example.com',
        password: 'password123',
        database: 'test',
      );

      // Create permissions
      final perm1 = await Permission.createPermission(
        name: 'Permission 1',
        codename: 'perm1',
        contentType: 'app1',
        database: 'test',
      );

      final perm2 = await Permission.createPermission(
        name: 'Permission 2',
        codename: 'perm2',
        contentType: 'app2',
        database: 'test',
      );

      // Add direct permission
      await connection.execute(
          'INSERT INTO auth_user_permissions (user_id, permission_id) VALUES (?, ?)',
          [user.id, perm1.id]);

      // Add group permission
      final group =
          await Group.createGroup('Permission Group', database: 'test');
      await group.addPermission(perm2);

      await connection.execute(
          'INSERT INTO auth_user_groups (user_id, group_id) VALUES (?, ?)',
          [user.id, group.id]);

      // Check all permissions
      final allPermissions = await user.getAllPermissions();
      expect(allPermissions.length, equals(2));
      expect(allPermissions.contains('app1.perm1'), isTrue);
      expect(allPermissions.contains('app2.perm2'), isTrue);

      // Check module permissions
      expect(await user.hasModulePermission('app1'), isTrue);
      expect(await user.hasModulePermission('app2'), isTrue);
      expect(await user.hasModulePermission('app3'), isFalse);
    });

    test('should handle has permissions for multiple permissions', () async {
      final user = await User.createUser(
        username: 'multiperms',
        email: 'multiperms@example.com',
        password: 'password123',
        database: 'test',
      );

      final perm1 = await Permission.createPermission(
        name: 'Permission 1',
        codename: 'perm1',
        contentType: 'app1',
        database: 'test',
      );

      final perm2 = await Permission.createPermission(
        name: 'Permission 2',
        codename: 'perm2',
        contentType: 'app1',
        database: 'test',
      );

      // Add both permissions
      await connection.execute(
          'INSERT INTO auth_user_permissions (user_id, permission_id) VALUES (?, ?)',
          [user.id, perm1.id]);
      await connection.execute(
          'INSERT INTO auth_user_permissions (user_id, permission_id) VALUES (?, ?)',
          [user.id, perm2.id]);

      // Should have both permissions
      expect(await user.hasPermissions(['app1.perm1', 'app1.perm2']), isTrue);

      // Should fail if missing one permission
      expect(await user.hasPermissions(['app1.perm1', 'app1.nonexistent']),
          isFalse);
    });
  });

  group('User Model V2 JSON Tests', () {
    test('should serialize to JSON', () async {
      final user = await User.createUser(
        username: 'jsonuser',
        email: 'json@example.com',
        password: 'password123',
        firstName: 'JSON',
        lastName: 'User',
        database: 'test',
      );

      final json = user.toJson();
      expect(json['username'], equals('jsonuser'));
      expect(json['email'], equals('json@example.com'));
      expect(json['first_name'], equals('JSON'));
      expect(json['last_name'], equals('User'));
      expect(json['is_active'], isTrue);
      expect(json['is_staff'], isFalse);
      expect(json['is_superuser'], isFalse);
    });
  });
}
