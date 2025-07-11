import 'dart:async';
import 'package:test/test.dart';

import '../lib/src/core/auth/models_v2.dart' as auth;
import '../lib/src/core/database/connection.dart';
import '../lib/src/core/signals/signals.dart';

void main() {
  group('Signals ORM Integration Tests', () {
    late DatabaseConfig config;
    late SignalTestHelper helper;

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

      // Initialize signals
      initializeSignals();
    });

    setUp(() {
      helper = SignalTestHelper();
    });

    tearDown(() async {
      // Clear all signal connections
      DjangoSignals.preSave.disconnect();
      DjangoSignals.postSave.disconnect();
      DjangoSignals.preDelete.disconnect();
      DjangoSignals.postDelete.disconnect();

      // Clean up any test data
      try {
        final connection = await DatabaseRouter.getConnection();
        await connection.execute('DELETE FROM auth_users');
        await connection.execute('DELETE FROM auth_groups');
        await DatabaseRouter.releaseConnection(connection);
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('should send pre_save and post_save signals when creating user',
        () async {
      var preSaveReceived = false;
      var postSaveReceived = false;
      auth.User? preSaveInstance;
      auth.User? postSaveInstance;
      bool? preSaveCreated;
      bool? postSaveCreated;

      // Connect signal receivers
      DjangoSignals.preSave.connect(
        receiver: (sender, {kwargs}) async {
          preSaveReceived = true;
          preSaveInstance = kwargs?['instance'] as auth.User?;
          preSaveCreated = kwargs?['created'] as bool?;
        },
      );

      DjangoSignals.postSave.connect(
        receiver: (sender, {kwargs}) async {
          postSaveReceived = true;
          postSaveInstance = kwargs?['instance'] as auth.User?;
          postSaveCreated = kwargs?['created'] as bool?;
        },
      );

      // Create user
      final user = await auth.User.createUser(
        username: 'testuser',
        email: 'test@example.com',
        password: 'password123',
      );

      // Verify signals were sent
      expect(preSaveReceived, isTrue);
      expect(postSaveReceived, isTrue);
      expect(preSaveInstance, equals(user));
      expect(postSaveInstance, equals(user));
      expect(preSaveCreated, isTrue);
      expect(postSaveCreated, isTrue);
    });

    test('should send pre_save and post_save signals when updating user',
        () async {
      var preSaveReceived = false;
      var postSaveReceived = false;
      auth.User? preSaveInstance;
      auth.User? postSaveInstance;
      bool? preSaveCreated;
      bool? postSaveCreated;

      // Create user first
      final user = await auth.User.createUser(
        username: 'testuser',
        email: 'test@example.com',
        password: 'password123',
      );

      // Connect signal receivers
      DjangoSignals.preSave.connect(
        receiver: (sender, {kwargs}) async {
          preSaveReceived = true;
          preSaveInstance = kwargs?['instance'] as auth.User?;
          preSaveCreated = kwargs?['created'] as bool?;
        },
      );

      DjangoSignals.postSave.connect(
        receiver: (sender, {kwargs}) async {
          postSaveReceived = true;
          postSaveInstance = kwargs?['instance'] as auth.User?;
          postSaveCreated = kwargs?['created'] as bool?;
        },
      );

      // Update user
      user.firstName = 'Updated';
      await user.save();

      // Verify signals were sent
      expect(preSaveReceived, isTrue);
      expect(postSaveReceived, isTrue);
      expect(preSaveInstance, equals(user));
      expect(postSaveInstance, equals(user));
      expect(preSaveCreated, isFalse);
      expect(postSaveCreated, isFalse);
    });

    test('should send pre_delete and post_delete signals when deleting user',
        () async {
      var preDeleteReceived = false;
      var postDeleteReceived = false;
      auth.User? preDeleteInstance;
      auth.User? postDeleteInstance;

      // Create user first
      final user = await auth.User.createUser(
        username: 'testuser',
        email: 'test@example.com',
        password: 'password123',
      );

      // Connect signal receivers
      DjangoSignals.preDelete.connect(
        receiver: (sender, {kwargs}) async {
          preDeleteReceived = true;
          preDeleteInstance = kwargs?['instance'] as auth.User?;
        },
      );

      DjangoSignals.postDelete.connect(
        receiver: (sender, {kwargs}) async {
          postDeleteReceived = true;
          postDeleteInstance = kwargs?['instance'] as auth.User?;
        },
      );

      // Delete user
      await user.delete();

      // Verify signals were sent
      expect(preDeleteReceived, isTrue);
      expect(postDeleteReceived, isTrue);
      expect(preDeleteInstance, equals(user));
      expect(postDeleteInstance, equals(user));
    });

    test('should send signals for group operations', () async {
      var preSaveReceived = false;
      var postSaveReceived = false;
      var preDeleteReceived = false;
      var postDeleteReceived = false;

      // Connect signal receivers
      DjangoSignals.preSave.connect(
        receiver: (sender, {kwargs}) async {
          preSaveReceived = true;
        },
      );

      DjangoSignals.postSave.connect(
        receiver: (sender, {kwargs}) async {
          postSaveReceived = true;
        },
      );

      DjangoSignals.preDelete.connect(
        receiver: (sender, {kwargs}) async {
          preDeleteReceived = true;
        },
      );

      DjangoSignals.postDelete.connect(
        receiver: (sender, {kwargs}) async {
          postDeleteReceived = true;
        },
      );

      // Create group
      final group = await auth.Group.createGroup('testgroup');

      // Verify save signals were sent
      expect(preSaveReceived, isTrue);
      expect(postSaveReceived, isTrue);

      // Reset flags
      preSaveReceived = false;
      postSaveReceived = false;

      // Update group
      group.name = 'Updated Group';
      await group.save();

      // Verify update signals were sent
      expect(preSaveReceived, isTrue);
      expect(postSaveReceived, isTrue);

      // Delete group
      await group.delete();

      // Verify delete signals were sent
      expect(preDeleteReceived, isTrue);
      expect(postDeleteReceived, isTrue);
    });

    test('should handle signal receiver exceptions gracefully', () async {
      var normalReceiverCalled = false;

      // Connect receivers - one that throws, one that doesn't
      DjangoSignals.preSave.connect(
        receiver: (sender, {kwargs}) async {
          throw Exception('Signal receiver error');
        },
        dispatchUid: 'faulty_receiver',
      );

      DjangoSignals.preSave.connect(
        receiver: (sender, {kwargs}) async {
          normalReceiverCalled = true;
        },
        dispatchUid: 'normal_receiver',
      );

      // Create user - this should not fail even though one receiver throws
      final user = await auth.User.createUser(
        username: 'testuser',
        email: 'test@example.com',
        password: 'password123',
      );

      // Verify user was created successfully
      expect(user.id, greaterThan(0));
      expect(normalReceiverCalled, isTrue);
    });

    test('should support signal filtering by sender type', () async {
      var userSignalReceived = false;
      var groupSignalReceived = false;

      // Connect receiver only for User signals
      DjangoSignals.preSave.connect(
        receiver: (sender, {kwargs}) async {
          userSignalReceived = true;
        },
        sender: auth.User,
      );

      // Connect receiver only for Group signals
      DjangoSignals.preSave.connect(
        receiver: (sender, {kwargs}) async {
          groupSignalReceived = true;
        },
        sender: auth.Group,
      );

      // Create user
      await auth.User.createUser(
        username: 'testuser',
        email: 'test@example.com',
        password: 'password123',
      );

      // Verify only user signal was received
      expect(userSignalReceived, isTrue);
      expect(groupSignalReceived, isFalse);

      // Reset flags
      userSignalReceived = false;
      groupSignalReceived = false;

      // Create group
      await auth.Group.createGroup('testgroup');

      // Verify only group signal was received
      expect(userSignalReceived, isFalse);
      expect(groupSignalReceived, isTrue);
    });
  });
}

// Helper function to create database tables
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
