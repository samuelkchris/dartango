import 'dart:async';
import '../http/request.dart';
import '../middleware/authentication.dart' as auth;
import 'models_v2.dart' as models;

class DatabaseBackend extends auth.AuthenticationBackend {
  @override
  Future<auth.User?> authenticate(
      HttpRequest request, String? username, String? password) async {
    if (username == null || password == null) {
      return null;
    }

    final user = await models.User.getUserByUsername(username);
    if (user == null || !user.isActive) {
      return null;
    }

    if (!user.checkPassword(password)) {
      return null;
    }

    return DatabaseUserAdapter(user);
  }

  @override
  Future<auth.User?> getUser(dynamic userId) async {
    if (userId == null) {
      return null;
    }

    final user = await models.User.getUserById(userId);
    if (user == null) {
      return null;
    }

    return DatabaseUserAdapter(user);
  }

  @override
  FutureOr<bool> hasPermission(auth.User user, String permission,
      {dynamic obj}) async {
    if (user is DatabaseUserAdapter) {
      return await user._user.hasPermission(permission);
    }
    return false;
  }

  @override
  FutureOr<bool> hasModulePermission(auth.User user, String appLabel) async {
    if (user is DatabaseUserAdapter) {
      return await user._user.hasModulePermission(appLabel);
    }
    return false;
  }

  @override
  FutureOr<auth.User?> getAnonymousUser() {
    return auth.AnonymousUser();
  }
}

class DatabaseUserAdapter implements auth.User {
  final models.User _user;

  DatabaseUserAdapter(this._user);

  @override
  dynamic get id => _user.id;

  @override
  String get username => _user.username;

  @override
  String get email => _user.email;

  @override
  String get firstName => _user.firstName;

  @override
  String get lastName => _user.lastName;

  @override
  bool get isActive => _user.isActive;

  @override
  bool get isStaff => _user.isStaff;

  @override
  bool get isSuperuser => _user.isSuperuser;

  @override
  DateTime get dateJoined => _user.dateJoined;

  @override
  DateTime? get lastLogin => _user.lastLogin;

  @override
  Map<String, dynamic> get permissions => {};

  @override
  List<String> get groups => [];

  @override
  bool get isAuthenticated => _user.isAuthenticated;

  @override
  bool get isAnonymous => _user.isAnonymous;

  @override
  String get fullName => _user.fullName;

  @override
  String get shortName => _user.shortName;

  @override
  Future<bool> hasPermission(String permission, {dynamic obj}) async {
    return await _user.hasPermission(permission);
  }

  @override
  Future<bool> hasPermissions(List<String> permissions, {dynamic obj}) async {
    return await _user.hasPermissions(permissions);
  }

  @override
  Future<bool> hasModulePermission(String appLabel) async {
    return await _user.hasModulePermission(appLabel);
  }

  @override
  Future<void> updateLastLogin() async {
    await _user.updateLastLogin();
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'is_active': isActive,
      'is_staff': isStaff,
      'is_superuser': isSuperuser,
      'date_joined': dateJoined.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  static auth.User fromJson(Map<String, dynamic> json) {
    // This would need to be implemented to recreate from session data
    throw UnimplementedError('DatabaseUserAdapter.fromJson not implemented');
  }
}
