import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../database/connection.dart';
import '../signals/signals.dart';

// User model that works directly with the database
// without depending on the ORM field reflection system
class User {
  final String? _database;

  Map<String, dynamic> _data = {};
  Map<String, dynamic> _originalData = {};
  bool _hasChanged = false;
  Set<String> _changedFields = {};

  User({String? database}) : _database = database;

  User.fromMap(Map<String, dynamic> data, {String? database})
      : _database = database {
    _loadFromMap(data);
  }

  String? get database => _database;
  String get tableName => 'auth_users';

  void _loadFromMap(Map<String, dynamic> data) {
    _data = <String, dynamic>{};
    _originalData = <String, dynamic>{};

    // Convert database values to proper Dart types
    for (final entry in data.entries) {
      final value = _convertValueFromDatabase(entry.key, entry.value);
      _data[entry.key] = value;
      _originalData[entry.key] = value;
    }

    _changedFields.clear();
    _hasChanged = false;
  }

  T? _getField<T>(String fieldName) {
    return _data[fieldName] as T?;
  }

  void _setField<T>(String fieldName, T? value) {
    if (_data[fieldName] != value) {
      _data[fieldName] = value;
      _changedFields.add(fieldName);
      _hasChanged = true;
    }
  }

  // Database type conversion methods
  dynamic _convertValueForDatabase(dynamic value) {
    if (value is DateTime) {
      return value.toIso8601String();
    }
    return value;
  }

  dynamic _convertValueFromDatabase(String fieldName, dynamic value) {
    if (value == null) return null;

    // Convert based on field name patterns
    if (fieldName.contains('date') || fieldName.contains('login')) {
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
    }

    // Convert boolean fields
    if (fieldName.startsWith('is_')) {
      if (value is int) {
        return value == 1;
      }
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1';
      }
    }

    return value;
  }

  // Field accessors
  int get id => _getField<int>('id') ?? 0;
  set id(int value) => _setField('id', value);

  String get username => _getField<String>('username') ?? '';
  set username(String value) => _setField('username', value);

  String get email => _getField<String>('email') ?? '';
  set email(String value) => _setField('email', value);

  String get firstName => _getField<String>('first_name') ?? '';
  set firstName(String value) => _setField('first_name', value);

  String get lastName => _getField<String>('last_name') ?? '';
  set lastName(String value) => _setField('last_name', value);

  bool get isActive => _getField<bool>('is_active') ?? false;
  set isActive(bool value) => _setField('is_active', value);

  bool get isStaff => _getField<bool>('is_staff') ?? false;
  set isStaff(bool value) => _setField('is_staff', value);

  bool get isSuperuser => _getField<bool>('is_superuser') ?? false;
  set isSuperuser(bool value) => _setField('is_superuser', value);

  DateTime get dateJoined =>
      _getField<DateTime>('date_joined') ?? DateTime.now();
  set dateJoined(DateTime value) => _setField('date_joined', value);

  DateTime? get lastLogin => _getField<DateTime>('last_login');
  set lastLogin(DateTime? value) => _setField('last_login', value);

  String get password => _getField<String>('password') ?? '';
  set password(String value) => _setField('password', value);

  // Django User API compatibility
  bool get isAuthenticated => id != 0;
  bool get isAnonymous => !isAuthenticated;
  String get fullName => '$firstName $lastName'.trim();
  String get shortName => firstName.isNotEmpty ? firstName : username;
  bool get isNew => id == 0;
  bool get hasChanged => _hasChanged;
  Set<String> get changedFields => Set.unmodifiable(_changedFields);

  // Database operations
  Future<void> save(
      {bool forceInsert = false,
      bool forceUpdate = false,
      List<String>? updateFields}) async {
    if (forceInsert && forceUpdate) {
      throw Exception('Cannot force both insert and update');
    }

    final isCreating = isNew && !forceUpdate;

    // Send pre_save signal
    await DjangoSignals.preSave.send(
      sender: this,
      kwargs: {
        'instance': this,
        'created': isCreating,
        'update_fields': updateFields,
      },
    );

    if (isNew && !forceUpdate) {
      await _insert();
    } else if (!isNew && !forceInsert) {
      await _update(updateFields: updateFields);
    } else if (forceInsert) {
      await _insert();
    } else if (forceUpdate) {
      await _update(updateFields: updateFields);
    }

    _hasChanged = false;
    _changedFields.clear();

    // Send post_save signal
    await DjangoSignals.postSave.send(
      sender: this,
      kwargs: {
        'instance': this,
        'created': isCreating,
        'update_fields': updateFields,
      },
    );
  }

  Future<void> _insert() async {
    final connection = await DatabaseRouter.getConnection(_database);
    try {
      final fields = _data.keys.where((key) => key != 'id').toList();
      final values = fields
          .map((field) => _convertValueForDatabase(_data[field]))
          .toList();
      final placeholders = List.filled(fields.length, '?').join(', ');

      final sql = '''
        INSERT INTO $tableName (${fields.join(', ')}) 
        VALUES ($placeholders)
      ''';

      final result = await connection.execute(sql, values);
      if (result.insertId != null) {
        id = result.insertId!;
      }
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  Future<void> _update({List<String>? updateFields}) async {
    final connection = await DatabaseRouter.getConnection(_database);
    try {
      final fieldsToUpdate = updateFields ?? _changedFields.toList();
      if (fieldsToUpdate.isEmpty) return;

      final setClauses = fieldsToUpdate.map((field) => '$field = ?').join(', ');
      final values = fieldsToUpdate
          .map((field) => _convertValueForDatabase(_data[field]))
          .toList();
      values.add(id); // Add ID for WHERE clause

      final sql = '''
        UPDATE $tableName 
        SET $setClauses 
        WHERE id = ?
      ''';

      await connection.execute(sql, values);
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  Future<void> delete() async {
    if (isNew) {
      throw Exception('Cannot delete unsaved user instance');
    }

    // Send pre_delete signal
    await DjangoSignals.preDelete.send(
      sender: this,
      kwargs: {
        'instance': this,
      },
    );

    final connection = await DatabaseRouter.getConnection(_database);
    try {
      await connection.execute('DELETE FROM $tableName WHERE id = ?', [id]);
      _data.clear();
      _hasChanged = false;
      _changedFields.clear();
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }

    // Send post_delete signal
    await DjangoSignals.postDelete.send(
      sender: this,
      kwargs: {
        'instance': this,
      },
    );
  }

  Future<void> refresh() async {
    if (isNew) {
      throw Exception('Cannot refresh unsaved user instance');
    }

    final connection = await DatabaseRouter.getConnection(_database);
    try {
      final result =
          await connection.query('SELECT * FROM $tableName WHERE id = ?', [id]);
      if (result.isEmpty) {
        throw Exception('User instance no longer exists in database');
      }
      _loadFromMap(result.first);
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  // Static methods for Django-style user operations
  static Future<User?> getUserById(int id, {String? database}) async {
    final connection = await DatabaseRouter.getConnection(database);
    try {
      final result =
          await connection.query('SELECT * FROM auth_users WHERE id = ?', [id]);
      if (result.isEmpty) return null;
      return User.fromMap(result.first, database: database);
    } finally {
      await DatabaseRouter.releaseConnection(connection, database);
    }
  }

  static Future<User?> getUserByUsername(String username,
      {String? database}) async {
    final connection = await DatabaseRouter.getConnection(database);
    try {
      final result = await connection
          .query('SELECT * FROM auth_users WHERE username = ?', [username]);
      if (result.isEmpty) return null;
      return User.fromMap(result.first, database: database);
    } finally {
      await DatabaseRouter.releaseConnection(connection, database);
    }
  }

  static Future<User?> getUserByEmail(String email, {String? database}) async {
    final connection = await DatabaseRouter.getConnection(database);
    try {
      final result = await connection
          .query('SELECT * FROM auth_users WHERE email = ?', [email]);
      if (result.isEmpty) return null;
      return User.fromMap(result.first, database: database);
    } finally {
      await DatabaseRouter.releaseConnection(connection, database);
    }
  }

  static Future<User> createUser({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    bool isActive = true,
    bool isStaff = false,
    bool isSuperuser = false,
    String? database,
  }) async {
    final user = User(database: database)
      ..username = username
      ..email = email
      ..password = _hashPassword(password)
      ..firstName = firstName ?? ''
      ..lastName = lastName ?? ''
      ..isActive = isActive
      ..isStaff = isStaff
      ..isSuperuser = isSuperuser
      ..dateJoined = DateTime.now();

    await user.save();
    return user;
  }

  static Future<User> createSuperuser({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? database,
  }) async {
    return await createUser(
      username: username,
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      isActive: true,
      isStaff: true,
      isSuperuser: true,
      database: database,
    );
  }

  // Password operations
  void setPassword(String password) {
    this.password = _hashPassword(password);
  }

  bool checkPassword(String password) {
    return _verifyPassword(password, this.password);
  }

  static String _hashPassword(String password) {
    // Django-style PBKDF2 password hashing
    final salt = _generateSalt();
    const iterations = 260000;
    final hash = _pbkdf2(password, salt, iterations);
    return 'pbkdf2_sha256\$${iterations}\$${salt}\$${hash}';
  }

  static bool _verifyPassword(String password, String hashedPassword) {
    if (!hashedPassword.startsWith('pbkdf2_sha256\$')) {
      return false;
    }

    final parts = hashedPassword.split('\$');
    if (parts.length != 4) return false;

    final iterations = int.parse(parts[1]);
    final salt = parts[2];
    final expectedHash = parts[3];

    final actualHash = _pbkdf2(password, salt, iterations);
    return _constantTimeCompare(actualHash, expectedHash);
  }

  static String _generateSalt() {
    final bytes = List<int>.generate(
        16, (i) => DateTime.now().millisecondsSinceEpoch % 256);
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static String _pbkdf2(String password, String salt, int iterations) {
    final passwordBytes = utf8.encode(password);
    final saltBytes = utf8.encode(salt);

    final hmac = Hmac(sha256, passwordBytes);
    var result = hmac.convert(saltBytes).bytes;

    for (int i = 1; i < iterations; i++) {
      result = hmac.convert(result).bytes;
    }

    return base64Url.encode(result).replaceAll('=', '');
  }

  static bool _constantTimeCompare(String a, String b) {
    if (a.length != b.length) return false;

    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  // Permission checking
  Future<bool> hasPermission(String permission) async {
    if (isSuperuser) return true;

    // Check user permissions
    final userPermissions = await getUserPermissions();
    if (userPermissions.contains(permission)) return true;

    // Check group permissions
    final groups = await getGroups();
    for (final group in groups) {
      final groupPermissions = await group.getPermissions();
      if (groupPermissions.any(
          (p) => '${p.contentType}.${p.codename}' == permission)) return true;
    }

    return false;
  }

  Future<bool> hasPermissions(List<String> permissions) async {
    for (final permission in permissions) {
      if (!await hasPermission(permission)) return false;
    }
    return true;
  }

  Future<bool> hasModulePermission(String appLabel) async {
    if (isSuperuser) return true;

    final allPermissions = await getAllPermissions();
    return allPermissions.any((p) => p.startsWith('$appLabel.'));
  }

  Future<List<String>> getUserPermissions() async {
    final connection = await DatabaseRouter.getConnection(_database);
    try {
      final result = await connection.query('''
        SELECT p.content_type, p.codename 
        FROM auth_permissions p
        JOIN auth_user_permissions up ON p.id = up.permission_id
        WHERE up.user_id = ?
      ''', [id]);

      return result
          .map((row) => '${row['content_type']}.${row['codename']}')
          .toList();
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  Future<List<Group>> getGroups() async {
    final connection = await DatabaseRouter.getConnection(_database);
    try {
      final result = await connection.query('''
        SELECT g.* 
        FROM auth_groups g
        JOIN auth_user_groups ug ON g.id = ug.group_id
        WHERE ug.user_id = ?
      ''', [id]);

      return result
          .map((row) => Group.fromMap(row, database: _database))
          .toList();
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  Future<List<String>> getAllPermissions() async {
    final userPermissions = await getUserPermissions();
    final groups = await getGroups();

    final allPermissions = <String>{...userPermissions};
    for (final group in groups) {
      final groupPermissions = await group.getPermissions();
      allPermissions.addAll(
          groupPermissions.map((p) => '${p.contentType}.${p.codename}'));
    }

    return allPermissions.toList();
  }

  Future<void> updateLastLogin() async {
    lastLogin = DateTime.now();
    await save(updateFields: ['last_login']);
  }

  Map<String, dynamic> toJson() {
    return Map<String, dynamic>.from(_data);
  }
}

// Production-ready Group model
class Group {
  final String? _database;

  Map<String, dynamic> _data = {};
  bool _hasChanged = false;
  Set<String> _changedFields = {};

  Group({String? database}) : _database = database;

  Group.fromMap(Map<String, dynamic> data, {String? database})
      : _database = database {
    _data = Map<String, dynamic>.from(data);
  }

  String? get database => _database;
  String get tableName => 'auth_groups';

  int get id => _data['id'] ?? 0;
  set id(int value) {
    if (_data['id'] != value) {
      _data['id'] = value;
      _changedFields.add('id');
      _hasChanged = true;
    }
  }

  String get name => _data['name'] ?? '';
  set name(String value) {
    if (_data['name'] != value) {
      _data['name'] = value;
      _changedFields.add('name');
      _hasChanged = true;
    }
  }

  bool get isNew => id == 0;

  Future<void> save() async {
    final isCreating = isNew;

    // Send pre_save signal
    await DjangoSignals.preSave.send(
      sender: this,
      kwargs: {
        'instance': this,
        'created': isCreating,
      },
    );

    if (isNew) {
      await _insert();
    } else {
      await _update();
    }
    _hasChanged = false;
    _changedFields.clear();

    // Send post_save signal
    await DjangoSignals.postSave.send(
      sender: this,
      kwargs: {
        'instance': this,
        'created': isCreating,
      },
    );
  }

  Future<void> _insert() async {
    final connection = await DatabaseRouter.getConnection(_database);
    try {
      final result = await connection
          .execute('INSERT INTO $tableName (name) VALUES (?)', [name]);
      if (result.insertId != null) {
        id = result.insertId!;
      }
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  Future<void> _update() async {
    if (!_hasChanged) return;

    final connection = await DatabaseRouter.getConnection(_database);
    try {
      await connection
          .execute('UPDATE $tableName SET name = ? WHERE id = ?', [name, id]);
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  Future<void> delete() async {
    if (isNew) {
      throw Exception('Cannot delete unsaved group instance');
    }

    // Send pre_delete signal
    await DjangoSignals.preDelete.send(
      sender: this,
      kwargs: {
        'instance': this,
      },
    );

    final connection = await DatabaseRouter.getConnection(_database);
    try {
      await connection.execute('DELETE FROM $tableName WHERE id = ?', [id]);
      _data.clear();
      _hasChanged = false;
      _changedFields.clear();
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }

    // Send post_delete signal
    await DjangoSignals.postDelete.send(
      sender: this,
      kwargs: {
        'instance': this,
      },
    );
  }

  static Future<Group?> getGroupByName(String name, {String? database}) async {
    final connection = await DatabaseRouter.getConnection(database);
    try {
      final result = await connection
          .query('SELECT * FROM auth_groups WHERE name = ?', [name]);
      if (result.isEmpty) return null;
      return Group.fromMap(result.first, database: database);
    } finally {
      await DatabaseRouter.releaseConnection(connection, database);
    }
  }

  static Future<Group> createGroup(String name, {String? database}) async {
    final group = Group(database: database)..name = name;
    await group.save();
    return group;
  }

  Future<List<Permission>> getPermissions() async {
    final connection = await DatabaseRouter.getConnection(_database);
    try {
      final result = await connection.query('''
        SELECT p.* 
        FROM auth_permissions p
        JOIN auth_group_permissions gp ON p.id = gp.permission_id
        WHERE gp.group_id = ?
      ''', [id]);

      return result
          .map((row) => Permission.fromMap(row, database: _database))
          .toList();
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  Future<void> addPermission(Permission permission) async {
    final connection = await DatabaseRouter.getConnection(_database);
    try {
      await connection.execute(
          'INSERT OR IGNORE INTO auth_group_permissions (group_id, permission_id) VALUES (?, ?)',
          [id, permission.id]);
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  Future<void> removePermission(Permission permission) async {
    final connection = await DatabaseRouter.getConnection(_database);
    try {
      await connection.execute(
          'DELETE FROM auth_group_permissions WHERE group_id = ? AND permission_id = ?',
          [id, permission.id]);
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }
}

// Production-ready Permission model
class Permission {
  final String? _database;

  Map<String, dynamic> _data = {};
  bool _hasChanged = false;

  Permission({String? database}) : _database = database;

  Permission.fromMap(Map<String, dynamic> data, {String? database})
      : _database = database {
    _data = Map<String, dynamic>.from(data);
  }

  String? get database => _database;
  String get tableName => 'auth_permissions';

  int get id => _data['id'] ?? 0;
  set id(int value) {
    if (_data['id'] != value) {
      _data['id'] = value;
      _hasChanged = true;
    }
  }

  String get name => _data['name'] ?? '';
  set name(String value) {
    if (_data['name'] != value) {
      _data['name'] = value;
      _hasChanged = true;
    }
  }

  String get codename => _data['codename'] ?? '';
  set codename(String value) {
    if (_data['codename'] != value) {
      _data['codename'] = value;
      _hasChanged = true;
    }
  }

  String get contentType => _data['content_type'] ?? '';
  set contentType(String value) {
    if (_data['content_type'] != value) {
      _data['content_type'] = value;
      _hasChanged = true;
    }
  }

  bool get isNew => id == 0;
  String get fullName => '$contentType.$codename';

  Future<void> save() async {
    if (isNew) {
      await _insert();
    } else {
      await _update();
    }
    _hasChanged = false;
  }

  Future<void> _insert() async {
    final connection = await DatabaseRouter.getConnection(_database);
    try {
      final result = await connection.execute(
          'INSERT INTO $tableName (name, codename, content_type) VALUES (?, ?, ?)',
          [name, codename, contentType]);
      if (result.insertId != null) {
        id = result.insertId!;
      }
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  Future<void> _update() async {
    if (!_hasChanged) return;

    final connection = await DatabaseRouter.getConnection(_database);
    try {
      await connection.execute(
          'UPDATE $tableName SET name = ?, codename = ?, content_type = ? WHERE id = ?',
          [name, codename, contentType, id]);
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  static Future<Permission?> getPermission(String contentType, String codename,
      {String? database}) async {
    final connection = await DatabaseRouter.getConnection(database);
    try {
      final result = await connection.query(
          'SELECT * FROM auth_permissions WHERE content_type = ? AND codename = ?',
          [contentType, codename]);
      if (result.isEmpty) return null;
      return Permission.fromMap(result.first, database: database);
    } finally {
      await DatabaseRouter.releaseConnection(connection, database);
    }
  }

  static Future<Permission> createPermission({
    required String name,
    required String codename,
    required String contentType,
    String? database,
  }) async {
    final permission = Permission(database: database)
      ..name = name
      ..codename = codename
      ..contentType = contentType;
    await permission.save();
    return permission;
  }
}
