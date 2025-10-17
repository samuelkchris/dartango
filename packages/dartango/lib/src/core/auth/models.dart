import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../database/models.dart';
import '../database/fields.dart';
import '../database/queryset.dart';

class User extends Model {
  String? _database;

  // Field definitions for the ORM
  final AutoField idField = AutoField(columnName: 'id');
  final CharField usernameField = CharField(maxLength: 150, unique: true, columnName: 'username');
  final EmailField emailField = EmailField(columnName: 'email');
  final CharField firstNameField = CharField(maxLength: 150, blank: true, columnName: 'first_name');
  final CharField lastNameField = CharField(maxLength: 150, blank: true, columnName: 'last_name');
  final BooleanField isActiveField = BooleanField(defaultValue: true, columnName: 'is_active');
  final BooleanField isStaffField = BooleanField(defaultValue: false, columnName: 'is_staff');
  final BooleanField isSuperuserField = BooleanField(defaultValue: false, columnName: 'is_superuser');
  final DateTimeField dateJoinedField = DateTimeField(autoNowAdd: true, columnName: 'date_joined');
  final DateTimeField lastLoginField = DateTimeField(allowNull: true, columnName: 'last_login');
  final CharField passwordField = CharField(maxLength: 128, columnName: 'password');

  User({String? database}) : _database = database;

  User.fromMap(Map<String, dynamic> data, {String? database})
      : _database = database,
        super.fromMap(data);

  @override
  ModelMeta get meta => const ModelMeta(tableName: 'auth_users');

  @override
  String? get database => _database;

  int get id => getField('id') ?? 0;
  set id(int value) => setField('id', value);

  String get username => getField('username') ?? '';
  set username(String value) => setField('username', value);

  String get email => getField('email') ?? '';
  set email(String value) => setField('email', value);

  String get firstName => getField('first_name') ?? '';
  set firstName(String value) => setField('first_name', value);

  String get lastName => getField('last_name') ?? '';
  set lastName(String value) => setField('last_name', value);

  bool get isActive => getField('is_active') ?? false;
  set isActive(bool value) => setField('is_active', value);

  bool get isStaff => getField('is_staff') ?? false;
  set isStaff(bool value) => setField('is_staff', value);

  bool get isSuperuser => getField('is_superuser') ?? false;
  set isSuperuser(bool value) => setField('is_superuser', value);

  DateTime get dateJoined => getField('date_joined') ?? DateTime.now();
  set dateJoined(DateTime value) => setField('date_joined', value);

  DateTime? get lastLogin => getField('last_login');
  set lastLogin(DateTime? value) => setField('last_login', value);

  String get password => getField('password') ?? '';
  set password(String value) => setField('password', value);

  // Django User API compatibility
  bool get isAuthenticated => id != 0;
  bool get isAnonymous => !isAuthenticated;
  String get fullName => '$firstName $lastName'.trim();
  String get shortName => firstName.isNotEmpty ? firstName : username;

  // Static methods for Django-style user operations
  static Future<User?> getUserById(int id, {String? database}) async {
    final users = QuerySet<User>(User, 'auth_users', database,
        (data) => User.fromMap(data, database: database));
    return await users.getOrNull({'id': id});
  }

  static Future<User?> getUserByUsername(String username,
      {String? database}) async {
    final users = QuerySet<User>(User, 'auth_users', database,
        (data) => User.fromMap(data, database: database));
    return await users.getOrNull({'username': username});
  }

  static Future<User?> getUserByEmail(String email, {String? database}) async {
    final users = QuerySet<User>(User, 'auth_users', database,
        (data) => User.fromMap(data, database: database));
    return await users.getOrNull({'email': email});
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
      if (groupPermissions.any((p) => p.codename == permission)) return true;
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
    final userPermissions = QuerySet<UserPermission>(UserPermission,
        'auth_user_permissions', null, (data) => UserPermission.fromMap(data));
    final permissions = await userPermissions.filter({'user_id': id}).all();

    final permissionIds = permissions.map((up) => up.permissionId).toList();
    if (permissionIds.isEmpty) return [];

    final allPermissions = QuerySet<Permission>(Permission, 'auth_permissions',
        null, (data) => Permission.fromMap(data));
    final permissionObjects =
        await allPermissions.filter({'id__in': permissionIds}).all();

    return permissionObjects
        .map((p) => '${p.contentType}.${p.codename}')
        .toList();
  }

  Future<List<Group>> getGroups() async {
    final userGroups = QuerySet<UserGroup>(
        UserGroup, 'auth_user_groups', null, (data) => UserGroup.fromMap(data));
    final userGroupLinks = await userGroups.filter({'user_id': id}).all();

    final groupIds = userGroupLinks.map((ug) => ug.groupId).toList();
    if (groupIds.isEmpty) return [];

    final groups = QuerySet<Group>(
        Group, 'auth_groups', null, (data) => Group.fromMap(data));
    return await groups.filter({'id__in': groupIds}).all();
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
}

class Group extends Model {
  Group();

  Group.fromMap(Map<String, dynamic> data) : super.fromMap(data);

  @override
  ModelMeta get meta => const ModelMeta(tableName: 'auth_groups');

  int get id => getField('id') ?? 0;
  set id(int value) => setField('id', value);

  String get name => getField('name') ?? '';
  set name(String value) => setField('name', value);

  static Future<Group?> getGroupByName(String name) async {
    final groups = QuerySet<Group>(
        Group, 'auth_groups', null, (data) => Group.fromMap(data));
    return await groups.getOrNull({'name': name});
  }

  static Future<Group> createGroup(String name) async {
    final group = Group()..name = name;
    await group.save();
    return group;
  }

  Future<List<Permission>> getPermissions() async {
    final groupPermissions = QuerySet<GroupPermission>(
        GroupPermission,
        'auth_group_permissions',
        null,
        (data) => GroupPermission.fromMap(data));
    final groupPermissionLinks =
        await groupPermissions.filter({'group_id': id}).all();

    final permissionIds =
        groupPermissionLinks.map((gp) => gp.permissionId).toList();
    if (permissionIds.isEmpty) return [];

    final permissions = QuerySet<Permission>(Permission, 'auth_permissions',
        null, (data) => Permission.fromMap(data));
    return await permissions.filter({'id__in': permissionIds}).all();
  }

  Future<void> addPermission(Permission permission) async {
    final groupPermission = GroupPermission()
      ..groupId = id
      ..permissionId = permission.id;
    await groupPermission.save();
  }

  Future<void> removePermission(Permission permission) async {
    final groupPermissions = QuerySet<GroupPermission>(
        GroupPermission,
        'auth_group_permissions',
        null,
        (data) => GroupPermission.fromMap(data));
    await groupPermissions
        .filter({'group_id': id, 'permission_id': permission.id}).delete();
  }

  Future<List<User>> getUsers() async {
    final userGroups = QuerySet<UserGroup>(
        UserGroup, 'auth_user_groups', null, (data) => UserGroup.fromMap(data));
    final userGroupLinks = await userGroups.filter({'group_id': id}).all();

    final userIds = userGroupLinks.map((ug) => ug.userId).toList();
    if (userIds.isEmpty) return [];

    final users =
        QuerySet<User>(User, 'auth_users', null, (data) => User.fromMap(data));
    return await users.filter({'id__in': userIds}).all();
  }
}

class Permission extends Model {
  Permission();

  Permission.fromMap(Map<String, dynamic> data) : super.fromMap(data);

  @override
  ModelMeta get meta => const ModelMeta(tableName: 'auth_permissions');

  int get id => getField('id') ?? 0;
  set id(int value) => setField('id', value);

  String get name => getField('name') ?? '';
  set name(String value) => setField('name', value);

  String get codename => getField('codename') ?? '';
  set codename(String value) => setField('codename', value);

  String get contentType => getField('content_type') ?? '';
  set contentType(String value) => setField('content_type', value);

  static Future<Permission?> getPermission(
      String contentType, String codename) async {
    final permissions = QuerySet<Permission>(Permission, 'auth_permissions',
        null, (data) => Permission.fromMap(data));
    return await permissions.getOrNull({
      'content_type': contentType,
      'codename': codename,
    });
  }

  static Future<Permission> createPermission({
    required String name,
    required String codename,
    required String contentType,
  }) async {
    final permission = Permission()
      ..name = name
      ..codename = codename
      ..contentType = contentType;
    await permission.save();
    return permission;
  }

  String get fullName => '$contentType.$codename';
}

// Junction table models
class UserGroup extends Model {
  UserGroup();

  UserGroup.fromMap(Map<String, dynamic> data) : super.fromMap(data);

  @override
  ModelMeta get meta => const ModelMeta(tableName: 'auth_user_groups');

  int get id => getField('id') ?? 0;
  set id(int value) => setField('id', value);

  int get userId => getField('user_id') ?? 0;
  set userId(int value) => setField('user_id', value);

  int get groupId => getField('group_id') ?? 0;
  set groupId(int value) => setField('group_id', value);
}

class UserPermission extends Model {
  UserPermission();

  UserPermission.fromMap(Map<String, dynamic> data) : super.fromMap(data);

  @override
  ModelMeta get meta => const ModelMeta(tableName: 'auth_user_permissions');

  int get id => getField('id') ?? 0;
  set id(int value) => setField('id', value);

  int get userId => getField('user_id') ?? 0;
  set userId(int value) => setField('user_id', value);

  int get permissionId => getField('permission_id') ?? 0;
  set permissionId(int value) => setField('permission_id', value);
}

class GroupPermission extends Model {
  GroupPermission();

  GroupPermission.fromMap(Map<String, dynamic> data) : super.fromMap(data);

  @override
  ModelMeta get meta => const ModelMeta(tableName: 'auth_group_permissions');

  int get id => getField('id') ?? 0;
  set id(int value) => setField('id', value);

  int get groupId => getField('group_id') ?? 0;
  set groupId(int value) => setField('group_id', value);

  int get permissionId => getField('permission_id') ?? 0;
  set permissionId(int value) => setField('permission_id', value);
}
