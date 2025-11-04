/// Mock user for testing authentication and authorization
class MockUser {
  final String id;
  final String username;
  final String email;
  final bool isAuthenticated;
  final Set<String> permissions;
  final bool Function(String)? hasPermissionOverride;

  MockUser({
    this.id = 'test-user-id',
    this.username = 'testuser',
    this.email = 'test@example.com',
    this.isAuthenticated = true,
    this.permissions = const {},
    this.hasPermissionOverride,
  });

  Future<bool> hasPermission(String permission) async {
    if (hasPermissionOverride != null) {
      return hasPermissionOverride!(permission);
    }
    return permissions.contains(permission);
  }

  Future<bool> hasAnyPermission(List<String> perms) async {
    return perms.any((p) => permissions.contains(p));
  }

  Future<bool> hasAllPermissions(List<String> perms) async {
    return perms.every((p) => permissions.contains(p));
  }
}
