import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  User _user = User.empty;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  AuthProvider({required AuthService authService}) : _authService = authService;

  User get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _user.isAuthenticated;
  bool get canAccessAdmin => _user.canAccessAdmin;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    try {
      final savedUser = await _authService.getCurrentUser();
      if (savedUser != null) {
        _user = savedUser;
        await _authService.refreshUserData();
        final refreshedUser = await _authService.getCurrentUser();
        if (refreshedUser != null) {
          _user = refreshedUser;
        }
      }
      _isInitialized = true;
    } catch (e) {
      _setError('Failed to initialize authentication: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.login(username, password);
      if (user != null) {
        _user = user;
        if (!user.canAccessAdmin) {
          await logout();
          _setError('Access denied. Admin privileges required.');
          return false;
        }
        notifyListeners();
        return true;
      } else {
        _setError('Invalid username or password');
        return false;
      }
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      _user = User.empty;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Logout failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    _setLoading(true);
    _clearError();

    try {
      final success =
          await _authService.changePassword(currentPassword, newPassword);
      if (!success) {
        _setError('Failed to change password');
      }
      return success;
    } catch (e) {
      _setError('Password change failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? avatar,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedUser = await _authService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
        avatar: avatar,
      );
      if (updatedUser != null) {
        _user = updatedUser;
        notifyListeners();
      }
    } catch (e) {
      _setError('Profile update failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshUser() async {
    if (!_user.isAuthenticated) return;

    try {
      await _authService.refreshUserData();
      final refreshedUser = await _authService.getCurrentUser();
      if (refreshedUser != null) {
        _user = refreshedUser;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to refresh user data: ${e.toString()}');
    }
  }

  bool hasPermission(String permission) {
    return _user.hasPermission(permission);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
