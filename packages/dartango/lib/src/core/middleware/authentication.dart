import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import '../http/request.dart';
import '../http/response.dart';
import 'base.dart';
import 'session.dart';

class UserStore {
  static final UserStore _instance = UserStore._internal();
  static UserStore get instance => _instance;
  
  UserStore._internal();
  
  final Map<dynamic, DatabaseUser> _userCache = {};
  final Map<String, DatabaseUser> _usernameCache = {};
  
  Future<DatabaseUser?> getUserById(dynamic id) async {
    if (_userCache.containsKey(id)) {
      return _userCache[id];
    }
    
    final userData = await _fetchUserFromDatabase('id', id);
    if (userData != null) {
      final user = DatabaseUser.fromMap(userData);
      _userCache[id] = user;
      _usernameCache[user.username] = user;
      return user;
    }
    
    return null;
  }
  
  Future<DatabaseUser?> getUserByUsername(String username) async {
    if (_usernameCache.containsKey(username)) {
      return _usernameCache[username];
    }
    
    final userData = await _fetchUserFromDatabase('username', username);
    if (userData != null) {
      final user = DatabaseUser.fromMap(userData);
      _userCache[user.id] = user;
      _usernameCache[username] = user;
      return user;
    }
    
    return null;
  }
  
  Future<DatabaseUser> createUser({
    required String username,
    required String email,
    required String password,
    required bool isActive,
    required bool isStaff,
    required bool isSuperuser,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch;
    final user = DatabaseUser(
      id: id,
      username: username,
      email: email,
      firstName: '',
      lastName: '',
      isActive: isActive,
      isStaff: isStaff,
      isSuperuser: isSuperuser,
      dateJoined: DateTime.now(),
      lastLogin: null,
      permissions: {},
      groups: [],
    );
    
    await _saveUserToDatabase(user);
    _userCache[id] = user;
    _usernameCache[username] = user;
    
    return user;
  }
  
  Future<Map<String, dynamic>?> _fetchUserFromDatabase(String field, dynamic value) async {
    await Future.delayed(Duration(milliseconds: 1));
    return {
      'id': 1,
      'username': 'admin',
      'email': 'admin@example.com',
      'first_name': 'Admin',
      'last_name': 'User',
      'is_active': true,
      'is_staff': true,
      'is_superuser': true,
      'date_joined': DateTime.now(),
      'last_login': DateTime.now(),
      'password': 'pbkdf2_sha256\$260000\$abcdefghijklmnop\$hash_here',
    };
  }
  
  Future<void> _saveUserToDatabase(DatabaseUser user) async {
    await Future.delayed(Duration(milliseconds: 1));
  }
}

class DatabaseUser implements User {
  @override
  final dynamic id;
  
  @override
  final String username;
  
  @override
  final String email;
  
  @override
  final String firstName;
  
  @override
  final String lastName;
  
  @override
  final bool isActive;
  
  @override
  final bool isStaff;
  
  @override
  final bool isSuperuser;
  
  @override
  final DateTime dateJoined;
  
  @override
  final DateTime? lastLogin;
  
  @override
  final Map<String, dynamic> permissions;
  
  @override
  final List<String> groups;
  
  const DatabaseUser({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.isActive,
    required this.isStaff,
    required this.isSuperuser,
    required this.dateJoined,
    this.lastLogin,
    required this.permissions,
    required this.groups,
  });
  
  @override
  bool get isAuthenticated => id != null;
  
  @override
  bool get isAnonymous => !isAuthenticated;
  
  @override
  String get fullName => '$firstName $lastName'.trim();
  
  @override
  String get shortName => firstName.isNotEmpty ? firstName : username;
  
  @override
  Future<bool> hasPermission(String permission, {dynamic obj}) async {
    if (isSuperuser) {
      return true;
    }
    
    if (permissions.containsKey(permission)) {
      return permissions[permission] == true;
    }
    
    for (final group in groups) {
      final groupPermissions = await _getGroupPermissions(group);
      if (groupPermissions.containsKey(permission)) {
        return groupPermissions[permission] == true;
      }
    }
    
    return false;
  }
  
  @override
  Future<bool> hasPermissions(List<String> permissions, {dynamic obj}) async {
    for (final permission in permissions) {
      if (!await hasPermission(permission, obj: obj)) {
        return false;
      }
    }
    return true;
  }
  
  @override
  Future<bool> hasModulePermission(String appLabel) async {
    if (isSuperuser) {
      return true;
    }
    
    final modulePermissions = permissions.keys.where((perm) => perm.startsWith('$appLabel.'));
    return modulePermissions.isNotEmpty;
  }
  
  @override
  Future<void> updateLastLogin() async {
    await UserStore.instance._saveUserToDatabase(copyWith(lastLogin: DateTime.now()));
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
      'permissions': permissions,
      'groups': groups,
    };
  }
  
  static DatabaseUser fromMap(Map<String, dynamic> map) {
    return DatabaseUser(
      id: map['id'],
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      isActive: map['is_active'] ?? false,
      isStaff: map['is_staff'] ?? false,
      isSuperuser: map['is_superuser'] ?? false,
      dateJoined: map['date_joined'] is DateTime 
          ? map['date_joined'] 
          : DateTime.parse(map['date_joined'] ?? DateTime.now().toIso8601String()),
      lastLogin: map['last_login'] != null 
          ? (map['last_login'] is DateTime 
              ? map['last_login'] 
              : DateTime.parse(map['last_login']))
          : null,
      permissions: Map<String, dynamic>.from(map['permissions'] ?? {}),
      groups: List<String>.from(map['groups'] ?? []),
    );
  }
  
  static DatabaseUser fromRow(Map<String, dynamic> row) => fromMap(row);
  
  DatabaseUser copyWith({
    dynamic id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    bool? isActive,
    bool? isStaff,
    bool? isSuperuser,
    DateTime? dateJoined,
    DateTime? lastLogin,
    Map<String, dynamic>? permissions,
    List<String>? groups,
  }) {
    return DatabaseUser(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      isActive: isActive ?? this.isActive,
      isStaff: isStaff ?? this.isStaff,
      isSuperuser: isSuperuser ?? this.isSuperuser,
      dateJoined: dateJoined ?? this.dateJoined,
      lastLogin: lastLogin ?? this.lastLogin,
      permissions: permissions ?? this.permissions,
      groups: groups ?? this.groups,
    );
  }
  
  Future<Map<String, dynamic>> _getGroupPermissions(String group) async {
    return {};
  }
}

class TokenStore {
  static final TokenStore _instance = TokenStore._internal();
  static TokenStore get instance => _instance;
  
  TokenStore._internal();
  
  final Map<String, AuthToken> _tokens = {};
  
  Future<String> createToken(dynamic userId) async {
    final token = _generateToken();
    final authToken = AuthToken(
      token: token,
      userId: userId,
      created: DateTime.now(),
      lastUsed: DateTime.now(),
    );
    
    _tokens[token] = authToken;
    return token;
  }
  
  Future<dynamic> validateToken(String token) async {
    final authToken = _tokens[token];
    if (authToken == null) {
      return null;
    }
    
    if (authToken.isExpired) {
      _tokens.remove(token);
      return null;
    }
    
    authToken.updateLastUsed();
    return authToken.userId;
  }
  
  Future<void> revokeToken(String token) async {
    _tokens.remove(token);
  }
  
  String _generateToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}

class AuthToken {
  final String token;
  final dynamic userId;
  final DateTime created;
  DateTime lastUsed;
  
  AuthToken({
    required this.token,
    required this.userId,
    required this.created,
    required this.lastUsed,
  });
  
  bool get isExpired {
    final now = DateTime.now();
    return now.difference(created).inDays > 30;
  }
  
  void updateLastUsed() {
    lastUsed = DateTime.now();
  }
}

abstract class AuthenticationBackend {
  FutureOr<User?> authenticate(HttpRequest request, String? username, String? password);
  FutureOr<User?> getUser(dynamic userId);
  FutureOr<bool> hasPermission(User user, String permission, {dynamic obj});
  FutureOr<bool> hasModulePermission(User user, String appLabel);
  FutureOr<User?> getAnonymousUser();
}

abstract class User {
  dynamic get id;
  String get username;
  String get email;
  String get firstName;
  String get lastName;
  bool get isActive;
  bool get isStaff;
  bool get isSuperuser;
  DateTime get dateJoined;
  DateTime? get lastLogin;
  Map<String, dynamic> get permissions;
  List<String> get groups;
  
  bool get isAuthenticated => id != null;
  bool get isAnonymous => !isAuthenticated;
  
  String get fullName => '$firstName $lastName'.trim();
  String get shortName => firstName.isNotEmpty ? firstName : username;
  
  FutureOr<bool> hasPermission(String permission, {dynamic obj});
  FutureOr<bool> hasPermissions(List<String> permissions, {dynamic obj});
  FutureOr<bool> hasModulePermission(String appLabel);
  FutureOr<void> updateLastLogin();
  
  Map<String, dynamic> toJson();
  static User fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('fromJson must be implemented by concrete User class');
  }
}

class AnonymousUser implements User {
  @override
  dynamic get id => null;
  
  @override
  String get username => '';
  
  @override
  String get email => '';
  
  @override
  String get firstName => '';
  
  @override
  String get lastName => '';
  
  @override
  bool get isActive => false;
  
  @override
  bool get isStaff => false;
  
  @override
  bool get isSuperuser => false;
  
  @override
  DateTime get dateJoined => DateTime.now();
  
  @override
  DateTime? get lastLogin => null;
  
  @override
  Map<String, dynamic> get permissions => {};
  
  @override
  List<String> get groups => [];
  
  @override
  bool get isAuthenticated => false;
  
  @override
  bool get isAnonymous => true;
  
  @override
  String get fullName => '';
  
  @override
  String get shortName => '';
  
  @override
  FutureOr<bool> hasPermission(String permission, {dynamic obj}) => false;
  
  @override
  FutureOr<bool> hasPermissions(List<String> permissions, {dynamic obj}) => false;
  
  @override
  FutureOr<bool> hasModulePermission(String appLabel) => false;
  
  @override
  FutureOr<void> updateLastLogin() {}
  
  @override
  Map<String, dynamic> toJson() => {'id': null, 'username': '', 'is_anonymous': true};
  
  static User fromJson(Map<String, dynamic> json) => AnonymousUser();
}

class AuthenticationMiddleware extends BaseMiddleware {
  final List<AuthenticationBackend> backends;
  final String userSessionKey;
  final String backendSessionKey;
  final String hashSessionKey;
  final bool requiresAuthentication;
  final String? loginUrl;
  final String? logoutUrl;
  final List<String> exemptPaths;
  final Duration? sessionTimeout;
  final bool rotateSessionOnLogin;

  AuthenticationMiddleware({
    List<AuthenticationBackend>? backends,
    String? userSessionKey,
    String? backendSessionKey,
    String? hashSessionKey,
    bool? requiresAuthentication,
    this.loginUrl,
    this.logoutUrl,
    List<String>? exemptPaths,
    this.sessionTimeout,
    bool? rotateSessionOnLogin,
  })  : backends = backends ?? _getDefaultBackends(),
        userSessionKey = userSessionKey ?? '_auth_user_id',
        backendSessionKey = backendSessionKey ?? '_auth_user_backend',
        hashSessionKey = hashSessionKey ?? '_auth_user_hash',
        requiresAuthentication = requiresAuthentication ?? false,
        exemptPaths = exemptPaths ?? [],
        rotateSessionOnLogin = rotateSessionOnLogin ?? true;

  static List<AuthenticationBackend> _getDefaultBackends() {
    return [ModelBackend()];
  }

  @override
  FutureOr<HttpResponse?> processRequest(HttpRequest request) async {
    final user = await _getUser(request);
    request.middlewareState['user'] = user;

    if (requiresAuthentication && 
        user.isAnonymous && 
        !_isExemptPath(request.uri.path)) {
      return _redirectToLogin(request);
    }

    return null;
  }

  Future<User> _getUser(HttpRequest request) async {
    final session = request.middlewareState['session'] as Session?;
    if (session == null) {
      return AnonymousUser();
    }

    final userId = session[userSessionKey];
    if (userId == null) {
      return AnonymousUser();
    }

    final backendPath = session[backendSessionKey] as String?;
    if (backendPath == null) {
      return AnonymousUser();
    }

    final backend = _getBackend(backendPath);
    if (backend == null) {
      return AnonymousUser();
    }

    final user = await backend.getUser(userId);
    if (user == null) {
      return AnonymousUser();
    }

    final sessionHash = session[hashSessionKey] as String?;
    if (sessionHash != null) {
      final currentHash = _getUserHash(user);
      if (sessionHash != currentHash) {
        _flushSession(session);
        return AnonymousUser();
      }
    }

    if (sessionTimeout != null) {
      final lastActivity = session['_auth_last_activity'] as int?;
      if (lastActivity != null) {
        final lastActivityTime = DateTime.fromMillisecondsSinceEpoch(lastActivity);
        if (DateTime.now().difference(lastActivityTime) > sessionTimeout!) {
          _flushSession(session);
          return AnonymousUser();
        }
      }
      session['_auth_last_activity'] = DateTime.now().millisecondsSinceEpoch;
    }

    return user;
  }

  AuthenticationBackend? _getBackend(String backendPath) {
    for (final backend in backends) {
      if (backend.runtimeType.toString() == backendPath) {
        return backend;
      }
    }
    return null;
  }

  String _getUserHash(User user) {
    final userJson = jsonEncode(user.toJson());
    final bytes = utf8.encode(userJson);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _flushSession(dynamic session) {
    session.remove(userSessionKey);
    session.remove(backendSessionKey);
    session.remove(hashSessionKey);
    session.remove('_auth_last_activity');
  }

  bool _isExemptPath(String path) {
    for (final pattern in exemptPaths) {
      if (RegExp(pattern).hasMatch(path)) {
        return true;
      }
    }
    return false;
  }

  HttpResponse _redirectToLogin(HttpRequest request) {
    final loginUrlPath = loginUrl ?? '/login/';
    final nextUrl = request.uri.toString();
    final redirectUrl = '$loginUrlPath?next=${Uri.encodeComponent(nextUrl)}';
    return HttpResponse.redirect(redirectUrl);
  }
}

class ModelBackend extends AuthenticationBackend {
  @override
  Future<User?> authenticate(HttpRequest request, String? username, String? password) async {
    if (username == null || password == null) {
      return null;
    }
    
    final userStore = UserStore.instance;
    final user = await userStore.getUserByUsername(username);
    
    if (user == null || !user.isActive) {
      return null;
    }
    
    final userData = await userStore._fetchUserFromDatabase('username', username);
    if (userData == null) {
      return null;
    }
    
    final storedPassword = userData['password'] as String;
    
    if (!_verifyPassword(password, storedPassword)) {
      return null;
    }
    
    return user;
  }

  @override
  Future<User?> getUser(dynamic userId) async {
    if (userId == null) {
      return null;
    }
    
    final userStore = UserStore.instance;
    return await userStore.getUserById(userId);
  }
  
  bool _verifyPassword(String password, String hashedPassword) {
    if (hashedPassword.startsWith('pbkdf2_sha256\$')) {
      return _verifyPbkdf2(password, hashedPassword);
    } else if (hashedPassword.startsWith('bcrypt\$')) {
      return _verifyBcrypt(password, hashedPassword);
    } else if (hashedPassword.startsWith('argon2\$')) {
      return _verifyArgon2(password, hashedPassword);
    }
    return password == hashedPassword;
  }
  
  bool _verifyPbkdf2(String password, String hashedPassword) {
    final parts = hashedPassword.split('\$');
    if (parts.length != 4) return false;
    
    final iterations = int.parse(parts[1]);
    final salt = base64.decode(parts[2]);
    final expectedHash = base64.decode(parts[3]);
    
    final passwordBytes = utf8.encode(password);
    final hmacSha256 = Hmac(sha256, passwordBytes);
    
    var result = Uint8List.fromList(salt);
    for (var i = 0; i < iterations; i++) {
      result = Uint8List.fromList(hmacSha256.convert(result).bytes);
    }
    
    return _constantTimeCompare(result, expectedHash);
  }
  
  bool _verifyBcrypt(String password, String hashedPassword) {
    final parts = hashedPassword.split('\$');
    if (parts.length != 4) return false;
    
    final cost = int.parse(parts[2]);
    final saltAndHash = parts[3];
    
    final salt = saltAndHash.substring(0, 22);
    final hash = saltAndHash.substring(22);
    
    final passwordBytes = utf8.encode(password);
    final saltBytes = base64.decode(salt);
    
    var result = Uint8List.fromList(passwordBytes);
    for (var i = 0; i < (1 << cost); i++) {
      final hmac = Hmac(sha256, saltBytes);
      result = Uint8List.fromList(hmac.convert(result).bytes);
    }
    
    return base64.encode(result) == hash;
  }
  
  bool _verifyArgon2(String password, String hashedPassword) {
    final parts = hashedPassword.split('\$');
    if (parts.length != 6) return false;
    
    final iterations = int.parse(parts[4].split('=')[1]);
    
    final passwordBytes = utf8.encode(password);
    final salt = base64.decode(parts[4]);
    
    var result = Uint8List.fromList(passwordBytes);
    for (var i = 0; i < iterations; i++) {
      final hmac = Hmac(sha256, salt);
      result = Uint8List.fromList(hmac.convert(result).bytes);
    }
    
    return base64.encode(result) == parts[5];
  }
  
  bool _constantTimeCompare(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  @override
  FutureOr<bool> hasPermission(User user, String permission, {dynamic obj}) {
    if (user.isSuperuser) {
      return true;
    }
    
    return user.permissions.containsKey(permission);
  }

  @override
  FutureOr<bool> hasModulePermission(User user, String appLabel) {
    if (user.isSuperuser) {
      return true;
    }
    
    return user.permissions.keys.any((perm) => perm.startsWith('$appLabel.'));
  }

  @override
  FutureOr<User?> getAnonymousUser() {
    return AnonymousUser();
  }
}

class RemoteUserBackend extends AuthenticationBackend {
  final String headerName;
  final bool createUnknownUser;
  final bool cleanUsername;

  RemoteUserBackend({
    String? headerName,
    bool? createUnknownUser,
    bool? cleanUsername,
  })  : headerName = headerName ?? 'REMOTE_USER',
        createUnknownUser = createUnknownUser ?? true,
        cleanUsername = cleanUsername ?? true;

  @override
  Future<User?> authenticate(HttpRequest request, String? username, String? password) async {
    final remoteUser = request.headers[headerName.toLowerCase()];
    if (remoteUser == null || remoteUser.isEmpty) {
      return null;
    }

    final cleanedUsername = cleanUsername ? _cleanUsername(remoteUser) : remoteUser;
    
    final userStore = UserStore.instance;
    final existingUser = await userStore.getUserByUsername(cleanedUsername);
    
    if (existingUser != null) {
      return existingUser;
    }
    
    if (!createUnknownUser) {
      return null;
    }
    
    return await userStore.createUser(
      username: cleanedUsername,
      email: '$cleanedUsername@remote.user',
      password: 'unusable',
      isActive: true,
      isStaff: false,
      isSuperuser: false,
    );
  }

  @override
  Future<User?> getUser(dynamic userId) async {
    final userStore = UserStore.instance;
    return await userStore.getUserById(userId);
  }

  @override
  FutureOr<bool> hasPermission(User user, String permission, {dynamic obj}) {
    return user.permissions.containsKey(permission);
  }

  @override
  FutureOr<bool> hasModulePermission(User user, String appLabel) {
    return user.permissions.keys.any((perm) => perm.startsWith('$appLabel.'));
  }

  @override
  FutureOr<User?> getAnonymousUser() {
    return AnonymousUser();
  }

  String _cleanUsername(String username) {
    return username.replaceAll(RegExp(r'[^\w.@+-]'), '');
  }
}

class TokenAuthenticationBackend extends AuthenticationBackend {
  final String tokenHeaderName;
  final String tokenPrefix;
  final Duration? tokenExpiry;
  final bool requiresActiveUser;

  TokenAuthenticationBackend({
    String? tokenHeaderName,
    String? tokenPrefix,
    this.tokenExpiry,
    bool? requiresActiveUser,
  })  : tokenHeaderName = tokenHeaderName ?? 'Authorization',
        tokenPrefix = tokenPrefix ?? 'Token ',
        requiresActiveUser = requiresActiveUser ?? true;

  @override
  Future<User?> authenticate(HttpRequest request, String? username, String? password) async {
    final authHeader = request.headers[tokenHeaderName.toLowerCase()];
    if (authHeader == null || !authHeader.startsWith(tokenPrefix)) {
      return null;
    }

    final token = authHeader.substring(tokenPrefix.length);
    return await _getUserFromToken(token);
  }

  @override
  Future<User?> getUser(dynamic userId) async {
    final userStore = UserStore.instance;
    return await userStore.getUserById(userId);
  }

  @override
  FutureOr<bool> hasPermission(User user, String permission, {dynamic obj}) async {
    return await user.hasPermission(permission, obj: obj);
  }

  @override
  FutureOr<bool> hasModulePermission(User user, String appLabel) async {
    return await user.hasModulePermission(appLabel);
  }

  @override
  FutureOr<User?> getAnonymousUser() {
    return AnonymousUser();
  }

  Future<User?> _getUserFromToken(String token) async {
    final tokenStore = TokenStore.instance;
    final userId = await tokenStore.validateToken(token);
    
    if (userId == null) {
      return null;
    }
    
    final userStore = UserStore.instance;
    final user = await userStore.getUserById(userId);
    
    if (user == null || !user.isActive) {
      return null;
    }
    
    if (requiresActiveUser && !user.isActive) {
      return null;
    }
    
    return user;
  }
}

class SessionAuthenticationBackend extends AuthenticationBackend {
  final String sessionKeyName;
  final bool enforceCSRF;

  SessionAuthenticationBackend({
    String? sessionKeyName,
    bool? enforceCSRF,
  })  : sessionKeyName = sessionKeyName ?? 'sessionid',
        enforceCSRF = enforceCSRF ?? true;

  @override
  Future<User?> authenticate(HttpRequest request, String? username, String? password) async {
    final session = request.middlewareState['session'] as Session?;
    if (session == null) {
      return null;
    }

    final userId = session['_auth_user_id'];
    if (userId == null) {
      return null;
    }

    return await getUser(userId);
  }

  @override
  Future<User?> getUser(dynamic userId) async {
    final userStore = UserStore.instance;
    return await userStore.getUserById(userId);
  }

  @override
  FutureOr<bool> hasPermission(User user, String permission, {dynamic obj}) {
    return user.permissions.containsKey(permission);
  }

  @override
  FutureOr<bool> hasModulePermission(User user, String appLabel) {
    return user.permissions.keys.any((perm) => perm.startsWith('$appLabel.'));
  }

  @override
  FutureOr<User?> getAnonymousUser() {
    return AnonymousUser();
  }
}

class AuthenticationError implements Exception {
  final String message;
  final String? code;

  AuthenticationError(this.message, {this.code});

  @override
  String toString() => 'AuthenticationError: $message';
}

class AuthenticationRequired extends AuthenticationError {
  AuthenticationRequired({String? message})
      : super(message ?? 'Authentication credentials were not provided.', code: 'not_authenticated');
}

class InvalidCredentials extends AuthenticationError {
  InvalidCredentials({String? message})
      : super(message ?? 'Invalid authentication credentials.', code: 'invalid_credentials');
}

class UserInactive extends AuthenticationError {
  UserInactive({String? message})
      : super(message ?? 'User account is inactive.', code: 'user_inactive');
}

class TokenExpired extends AuthenticationError {
  TokenExpired({String? message})
      : super(message ?? 'Authentication token has expired.', code: 'token_expired');
}

Future<User?> authenticate(HttpRequest request, String? username, String? password) async {
  final middleware = AuthenticationMiddleware();
  
  for (final backend in middleware.backends) {
    try {
      final user = await backend.authenticate(request, username, password);
      if (user != null) {
        return user;
      }
    } catch (e) {
      continue;
    }
  }
  
  return null;
}

Future<void> login(HttpRequest request, User user) async {
  final session = request.middlewareState['session'] as Session?;
  if (session == null) {
    throw AuthenticationError('No session available for login');
  }

  final middleware = AuthenticationMiddleware();
  
  if (middleware.rotateSessionOnLogin) {
    await session.regenerateKey();
  }

  session[middleware.userSessionKey] = user.id;
  session[middleware.backendSessionKey] = user.runtimeType.toString();
  
  final userHash = _getUserHash(user);
  session[middleware.hashSessionKey] = userHash;
  
  session['_auth_last_activity'] = DateTime.now().millisecondsSinceEpoch;
  
  await user.updateLastLogin();
}

Future<void> logout(HttpRequest request) async {
  final session = request.middlewareState['session'] as Session?;
  if (session == null) {
    return;
  }

  final middleware = AuthenticationMiddleware();
  
  session.remove(middleware.userSessionKey);
  session.remove(middleware.backendSessionKey);
  session.remove(middleware.hashSessionKey);
  session.remove('_auth_last_activity');
  
  await session.regenerateKey();
  
  request.middlewareState['user'] = AnonymousUser();
}

String _getUserHash(User user) {
  final userJson = jsonEncode(user.toJson());
  final bytes = utf8.encode(userJson);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

mixin RequiresAuthentication {
  bool get requiresAuthentication => true;
}

mixin RequiresStaff {
  bool get requiresStaff => true;
}

mixin RequiresSuperuser {
  bool get requiresSuperuser => true;
}

mixin RequiresPermissions {
  List<String> get requiredPermissions => [];
}

class PermissionDenied implements Exception {
  final String message;
  final String? permission;

  PermissionDenied(this.message, {this.permission});

  @override
  String toString() => 'PermissionDenied: $message';
}

class LoginRequired extends PermissionDenied {
  LoginRequired({String? message})
      : super(message ?? 'Login required to access this resource.');
}

class StaffRequired extends PermissionDenied {
  StaffRequired({String? message})
      : super(message ?? 'Staff privileges required to access this resource.');
}

class SuperuserRequired extends PermissionDenied {
  SuperuserRequired({String? message})
      : super(message ?? 'Superuser privileges required to access this resource.');
}

class PermissionRequiredError extends PermissionDenied {
  PermissionRequiredError(String permission, {String? message})
      : super(message ?? 'Permission $permission required to access this resource.',
            permission: permission);
}