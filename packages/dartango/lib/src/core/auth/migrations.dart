import '../database/connection.dart';

class AuthMigrations {
  static Future<void> createAuthTables({String? database}) async {
    final connection = await DatabaseRouter.getConnection(database);

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
          date_joined TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
          last_login TIMESTAMP NULL,
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
          content_type VARCHAR(100) NOT NULL,
          UNIQUE(content_type, codename)
        )
      ''');

      // Create auth_user_groups table (many-to-many: User <-> Group)
      await connection.execute('''
        CREATE TABLE IF NOT EXISTS auth_user_groups (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          group_id INTEGER NOT NULL,
          FOREIGN KEY (user_id) REFERENCES auth_users (id) ON DELETE CASCADE,
          FOREIGN KEY (group_id) REFERENCES auth_groups (id) ON DELETE CASCADE,
          UNIQUE(user_id, group_id)
        )
      ''');

      // Create auth_user_permissions table (many-to-many: User <-> Permission)
      await connection.execute('''
        CREATE TABLE IF NOT EXISTS auth_user_permissions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          permission_id INTEGER NOT NULL,
          FOREIGN KEY (user_id) REFERENCES auth_users (id) ON DELETE CASCADE,
          FOREIGN KEY (permission_id) REFERENCES auth_permissions (id) ON DELETE CASCADE,
          UNIQUE(user_id, permission_id)
        )
      ''');

      // Create auth_group_permissions table (many-to-many: Group <-> Permission)
      await connection.execute('''
        CREATE TABLE IF NOT EXISTS auth_group_permissions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          group_id INTEGER NOT NULL,
          permission_id INTEGER NOT NULL,
          FOREIGN KEY (group_id) REFERENCES auth_groups (id) ON DELETE CASCADE,
          FOREIGN KEY (permission_id) REFERENCES auth_permissions (id) ON DELETE CASCADE,
          UNIQUE(group_id, permission_id)
        )
      ''');

      // Create indexes for better performance
      await connection.execute(
          'CREATE INDEX IF NOT EXISTS idx_auth_users_username ON auth_users(username)');
      await connection.execute(
          'CREATE INDEX IF NOT EXISTS idx_auth_users_email ON auth_users(email)');
      await connection.execute(
          'CREATE INDEX IF NOT EXISTS idx_auth_users_active ON auth_users(is_active)');
      await connection.execute(
          'CREATE INDEX IF NOT EXISTS idx_auth_user_groups_user ON auth_user_groups(user_id)');
      await connection.execute(
          'CREATE INDEX IF NOT EXISTS idx_auth_user_groups_group ON auth_user_groups(group_id)');
      await connection.execute(
          'CREATE INDEX IF NOT EXISTS idx_auth_user_permissions_user ON auth_user_permissions(user_id)');
      await connection.execute(
          'CREATE INDEX IF NOT EXISTS idx_auth_user_permissions_permission ON auth_user_permissions(permission_id)');
      await connection.execute(
          'CREATE INDEX IF NOT EXISTS idx_auth_group_permissions_group ON auth_group_permissions(group_id)');
      await connection.execute(
          'CREATE INDEX IF NOT EXISTS idx_auth_group_permissions_permission ON auth_group_permissions(permission_id)');
    } finally {
      await DatabaseRouter.releaseConnection(connection, database);
    }
  }

  static Future<void> createDefaultPermissions({String? database}) async {
    final connection = await DatabaseRouter.getConnection(database);

    try {
      // Create default auth permissions
      final defaultPermissions = [
        {
          'name': 'Can add user',
          'codename': 'add_user',
          'content_type': 'auth'
        },
        {
          'name': 'Can change user',
          'codename': 'change_user',
          'content_type': 'auth'
        },
        {
          'name': 'Can delete user',
          'codename': 'delete_user',
          'content_type': 'auth'
        },
        {
          'name': 'Can view user',
          'codename': 'view_user',
          'content_type': 'auth'
        },
        {
          'name': 'Can add group',
          'codename': 'add_group',
          'content_type': 'auth'
        },
        {
          'name': 'Can change group',
          'codename': 'change_group',
          'content_type': 'auth'
        },
        {
          'name': 'Can delete group',
          'codename': 'delete_group',
          'content_type': 'auth'
        },
        {
          'name': 'Can view group',
          'codename': 'view_group',
          'content_type': 'auth'
        },
        {
          'name': 'Can add permission',
          'codename': 'add_permission',
          'content_type': 'auth'
        },
        {
          'name': 'Can change permission',
          'codename': 'change_permission',
          'content_type': 'auth'
        },
        {
          'name': 'Can delete permission',
          'codename': 'delete_permission',
          'content_type': 'auth'
        },
        {
          'name': 'Can view permission',
          'codename': 'view_permission',
          'content_type': 'auth'
        },
      ];

      for (final perm in defaultPermissions) {
        await connection.execute('''
          INSERT OR IGNORE INTO auth_permissions (name, codename, content_type) 
          VALUES (?, ?, ?)
        ''', [perm['name'], perm['codename'], perm['content_type']]);
      }
    } finally {
      await DatabaseRouter.releaseConnection(connection, database);
    }
  }

  static Future<void> runMigrations({String? database}) async {
    await createAuthTables(database: database);
    await createDefaultPermissions(database: database);
  }
}
