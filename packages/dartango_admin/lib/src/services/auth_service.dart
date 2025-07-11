import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../utils/storage_utils.dart';
import '../utils/constants.dart';

class AuthService {
  final http.Client _client;
  final StorageUtils _storage;
  final String _baseUrl;

  AuthService({
    required http.Client client,
    required StorageUtils storage,
    String? baseUrl,
  })  : _client = client,
        _storage = storage,
        _baseUrl = baseUrl ?? Constants.defaultApiUrl;

  Future<User?> login(String username, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/login/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = User.fromJson(data['user'] as Map<String, dynamic>);
        final token = data['token'] as String;

        await _storage.saveSecure('auth_token', token);
        await _storage.saveSecure('user_data', jsonEncode(user.toJson()));

        return user;
      } else if (response.statusCode == 401) {
        return null;
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Login error: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      final token = await _storage.getSecure('auth_token');
      if (token != null) {
        await _client.post(
          Uri.parse('$_baseUrl/auth/logout/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      }
    } catch (e) {
      // Ignore logout errors as we'll clear local storage anyway
    } finally {
      await _storage.deleteSecure('auth_token');
      await _storage.deleteSecure('user_data');
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final userDataString = await _storage.getSecure('user_data');
      if (userDataString != null) {
        final userData = jsonDecode(userDataString) as Map<String, dynamic>;
        return User.fromJson(userData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> refreshUserData() async {
    try {
      final token = await _storage.getSecure('auth_token');
      if (token == null) return;

      final response = await _client.get(
        Uri.parse('$_baseUrl/auth/user/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body) as Map<String, dynamic>;
        final user = User.fromJson(userData);
        await _storage.saveSecure('user_data', jsonEncode(user.toJson()));
      } else if (response.statusCode == 401) {
        await logout();
      }
    } catch (e) {
      throw Exception('Failed to refresh user data: ${e.toString()}');
    }
  }

  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final token = await _storage.getSecure('auth_token');
      if (token == null) return false;

      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/change-password/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to change password: ${e.toString()}');
    }
  }

  Future<User?> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? avatar,
  }) async {
    try {
      final token = await _storage.getSecure('auth_token');
      if (token == null) return null;

      final body = <String, dynamic>{};
      if (firstName != null) body['first_name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;
      if (email != null) body['email'] = email;
      if (avatar != null) body['avatar'] = avatar;

      final response = await _client.patch(
        Uri.parse('$_baseUrl/auth/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body) as Map<String, dynamic>;
        final user = User.fromJson(userData);
        await _storage.saveSecure('user_data', jsonEncode(user.toJson()));
        return user;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/reset-password/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to reset password: ${e.toString()}');
    }
  }

  Future<bool> verifyToken() async {
    try {
      final token = await _storage.getSecure('auth_token');
      if (token == null) return false;

      final response = await _client.get(
        Uri.parse('$_baseUrl/auth/verify-token/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        await logout();
        return false;
      }

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getAuthToken() async {
    return await _storage.getSecure('auth_token');
  }

  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getAuthToken();
    if (token == null) return {};

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }
}
