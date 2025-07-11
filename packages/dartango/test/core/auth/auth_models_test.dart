import 'dart:io';
import 'package:test/test.dart';
import 'package:dartango/src/core/database/connection.dart';
import 'package:dartango/src/core/auth/models.dart';
import 'package:dartango/src/core/auth/migrations.dart';

void main() {
  late DatabaseConnection connection;

  setUpAll(() async {
    // Set up test database
    final config = DatabaseConfig(
      database: 'test_auth.db',
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
    await DatabaseRouter.closeAll();
    // Clean up test database file
    try {
      final file = File('test_auth.db');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  });

  group('User Model Tests', () {
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
        database: 'test',
        username: 'admin',
        email: 'admin@example.com',
        password: 'adminpass123',
      );

      expect(user.username, equals('admin'));
      expect(user.isActive, isTrue);
      expect(user.isStaff, isTrue);
      expect(user.isSuperuser, isTrue);
    });

    test('should find user by username', () async {
      await User.createUser(
        database: 'test',
        username: 'findme',
        email: 'findme@example.com',
        password: 'password123',
      );

      final user = await User.getUserByUsername('findme', database: 'test');
      expect(user, isNotNull);
      expect(user!.username, equals('findme'));
      expect(user.email, equals('findme@example.com'));
    });

    test('should find user by email', () async {
      await User.createUser(
        database: 'test',
        username: 'emailuser',
        email: 'email@example.com',
        password: 'password123',
      );

      final user =
          await User.getUserByEmail('email@example.com', database: 'test');
      expect(user, isNotNull);
      expect(user!.username, equals('emailuser'));
      expect(user.email, equals('email@example.com'));
    });

    test('should hash and verify password', () async {
      final user = await User.createUser(
        database: 'test',
        username: 'passworduser',
        email: 'pwd@example.com',
        password: 'mypassword123',
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
        database: 'test',
        username: 'loginuser',
        email: 'login@example.com',
        password: 'password123',
      );

      expect(user.lastLogin, isNull);

      await user.updateLastLogin();
      expect(user.lastLogin, isNotNull);
      expect(user.lastLogin!.difference(DateTime.now()).inSeconds, lessThan(5));
    });
  });

  group('Group Model Tests', () {
    test('should create and save group', () async {
      final group = await Group.createGroup('Test Group');

      expect(group.id, greaterThan(0));
      expect(group.name, equals('Test Group'));
    });

    test('should find group by name', () async {
      await Group.createGroup('Findable Group');

      final group = await Group.getGroupByName('Findable Group');
      expect(group, isNotNull);
      expect(group!.name, equals('Findable Group'));
    });
  });

  group('Permission Model Tests', () {
    test('should create permission', () async {
      final permission = await Permission.createPermission(
        name: 'Can test something',
        codename: 'test_something',
        contentType: 'testapp',
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
      );

      final permission =
          await Permission.getPermission('testapp', 'find_permission');
      expect(permission, isNotNull);
      expect(permission!.name, equals('Can find permission'));
    });
  });

  group('Permission System Tests', () {
    test('should check superuser permissions', () async {
      final superuser = await User.createSuperuser(
        database: 'test',
        username: 'super',
        email: 'super@example.com',
        password: 'password123',
      );

      expect(await superuser.hasPermission('any.permission'), isTrue);
      expect(await superuser.hasModulePermission('any_app'), isTrue);
    });

    test('should manage user permissions', () async {
      final user = await User.createUser(
        database: 'test',
        username: 'permuser',
        email: 'perm@example.com',
        password: 'password123',
      );

      final permission = await Permission.createPermission(
        name: 'Can test permission',
        codename: 'test_permission',
        contentType: 'testapp',
      );

      // User should not have permission initially
      expect(await user.hasPermission('testapp.test_permission'), isFalse);

      // Add permission to user
      final userPermission = UserPermission()
        ..userId = user.id
        ..permissionId = permission.id;
      await userPermission.save();

      // User should now have permission
      expect(await user.hasPermission('testapp.test_permission'), isTrue);
    });

    test('should manage group permissions', () async {
      final user = await User.createUser(
        database: 'test',
        username: 'groupuser',
        email: 'group@example.com',
        password: 'password123',
      );

      final group = await Group.createGroup('Test Permission Group');

      final permission = await Permission.createPermission(
        name: 'Can test group permission',
        codename: 'test_group_permission',
        contentType: 'testapp',
      );

      // Add permission to group
      await group.addPermission(permission);

      // Add user to group
      final userGroup = UserGroup()
        ..userId = user.id
        ..groupId = group.id;
      await userGroup.save();

      // User should have permission through group
      expect(await user.hasPermission('testapp.test_group_permission'), isTrue);

      // Test group methods
      final groupPermissions = await group.getPermissions();
      expect(groupPermissions.length, equals(1));
      expect(groupPermissions.first.codename, equals('test_group_permission'));

      final groupUsers = await group.getUsers();
      expect(groupUsers.length, equals(1));
      expect(groupUsers.first.username, equals('groupuser'));

      // Remove permission from group
      await group.removePermission(permission);
      expect(
          await user.hasPermission('testapp.test_group_permission'), isFalse);
    });

    test('should get all user permissions', () async {
      final user = await User.createUser(
        database: 'test',
        username: 'allperms',
        email: 'allperms@example.com',
        password: 'password123',
      );

      // Create permissions
      final perm1 = await Permission.createPermission(
        name: 'Permission 1',
        codename: 'perm1',
        contentType: 'app1',
      );

      final perm2 = await Permission.createPermission(
        name: 'Permission 2',
        codename: 'perm2',
        contentType: 'app2',
      );

      // Add direct permission
      final userPerm = UserPermission()
        ..userId = user.id
        ..permissionId = perm1.id;
      await userPerm.save();

      // Add group permission
      final group = await Group.createGroup('Permission Group');
      await group.addPermission(perm2);

      final userGroup = UserGroup()
        ..userId = user.id
        ..groupId = group.id;
      await userGroup.save();

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
  });
}
