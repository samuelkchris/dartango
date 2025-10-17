import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/admin_models.dart';
import '../../repositories/admin_repository.dart';

part 'auth_event.dart';

part 'auth_state.dart';

part 'auth_bloc.freezed.dart';

/// Authentication BLoC for admin interface
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AdminRepository _repository;
  final SharedPreferences _prefs;

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_profile';

  AuthBloc({
    required AdminRepository repository,
    required SharedPreferences prefs,
  })  : _repository = repository,
        _prefs = prefs,
        super(const AuthState.initial()) {
    on<AuthEvent>(
      (event, emit) async {
        await event.when(
          checkAuthStatus: () => _onCheckAuthStatus(emit),
          login: (request) => _onLogin(request, emit),
          logout: () => _onLogout(emit),
          refreshToken: () => _onRefreshToken(emit),
          updateUser: (user) => _onUpdateUser(user, emit),
        );
      },
    );
  }

  Future<void> _onCheckAuthStatus(Emitter<AuthState> emit) async {
    emit(const AuthState.loading());

    try {
      final token = _prefs.getString(_tokenKey);
      final userJson = _prefs.getString(_userKey);

      if (token != null && userJson != null) {
        // Verify token is still valid
        final user = await _repository.getCurrentUser();
        emit(AuthState.authenticated(user: user, token: token));
      } else {
        emit(const AuthState.unauthenticated());
      }
    } catch (e) {
      // Token might be expired, try to refresh
      await _tryRefreshToken(emit);
    }
  }

  Future<void> _onLogin(LoginRequest request, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());

    try {
      final response = await _repository.login(request);

      // Store tokens and user data
      await _storeAuthData(response);

      emit(AuthState.authenticated(
        user: response.user,
        token: response.token,
      ));
    } catch (e) {
      emit(AuthState.error(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onLogout(Emitter<AuthState> emit) async {
    try {
      await _repository.logout();
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      await _clearAuthData();
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onRefreshToken(Emitter<AuthState> emit) async {
    await _tryRefreshToken(emit);
  }

  Future<void> _onUpdateUser(UserProfile user, Emitter<AuthState> emit) async {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      await _storeUserData(user);
      emit(currentState.copyWith(user: user));
    }
  }

  Future<void> _tryRefreshToken(Emitter<AuthState> emit) async {
    try {
      final refreshToken = _prefs.getString(_refreshTokenKey);
      if (refreshToken == null) {
        emit(const AuthState.unauthenticated());
        return;
      }

      final response = await _repository.refreshToken(refreshToken);
      await _storeAuthData(response);

      emit(AuthState.authenticated(
        user: response.user,
        token: response.token,
      ));
    } catch (e) {
      await _clearAuthData();
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _storeAuthData(AuthResponse response) async {
    await Future.wait([
      _prefs.setString(_tokenKey, response.token),
      _prefs.setString(_refreshTokenKey, response.refreshToken),
      _storeUserData(response.user),
    ]);
  }

  Future<void> _storeUserData(UserProfile user) async {
    // In a real app, you'd use a more secure method to store user data
    final userJson = user.toJson().toString();
    await _prefs.setString(_userKey, userJson);
  }

  Future<void> _clearAuthData() async {
    await Future.wait([
      _prefs.remove(_tokenKey),
      _prefs.remove(_refreshTokenKey),
      _prefs.remove(_userKey),
    ]);
  }

  String _getErrorMessage(dynamic error) {
    if (error is AdminApiError) {
      return error.message;
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Get current auth token
  String? get currentToken => _prefs.getString(_tokenKey);

  /// Check if user is authenticated
  bool get isAuthenticated => state is AuthAuthenticated;

  /// Get current user
  UserProfile? get currentUser {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      return currentState.user;
    }
    return null;
  }
}
