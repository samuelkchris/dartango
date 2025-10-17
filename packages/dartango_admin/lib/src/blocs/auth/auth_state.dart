part of 'auth_bloc.dart';

/// Authentication states
@freezed
class AuthState with _$AuthState {
  /// Initial state
  const factory AuthState.initial() = AuthInitial;

  /// Loading state
  const factory AuthState.loading() = AuthLoading;

  /// Authenticated state
  const factory AuthState.authenticated({
    required UserProfile user,
    required String token,
  }) = AuthAuthenticated;

  /// Unauthenticated state
  const factory AuthState.unauthenticated() = AuthUnauthenticated;

  /// Error state
  const factory AuthState.error({
    required String message,
    String? code,
  }) = AuthError;
}

/// Extension methods for AuthState
extension AuthStateX on AuthState {
  bool get isLoading => this is AuthLoading;

  bool get isAuthenticated => this is AuthAuthenticated;

  bool get isUnauthenticated => this is AuthUnauthenticated;

  bool get hasError => this is AuthError;

  UserProfile? get user => maybeWhen(
        authenticated: (user, token) => user,
        orElse: () => null,
      );

  String? get token => maybeWhen(
        authenticated: (user, token) => token,
        orElse: () => null,
      );

  String? get errorMessage => maybeWhen(
        error: (message, code) => message,
        orElse: () => null,
      );
}
