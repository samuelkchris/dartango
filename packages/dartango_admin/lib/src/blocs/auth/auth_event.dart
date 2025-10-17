part of 'auth_bloc.dart';

/// Authentication events
@freezed
class AuthEvent with _$AuthEvent {
  /// Check current authentication status
  const factory AuthEvent.checkAuthStatus() = AuthCheckAuthStatus;
  
  /// Login with credentials
  const factory AuthEvent.login(LoginRequest request) = AuthLogin;
  
  /// Logout current user
  const factory AuthEvent.logout() = AuthLogout;
  
  /// Refresh authentication token
  const factory AuthEvent.refreshToken() = AuthRefreshToken;
  
  /// Update user profile
  const factory AuthEvent.updateUser(UserProfile user) = AuthUpdateUser;
}