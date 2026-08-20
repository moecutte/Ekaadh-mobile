import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ekaadh_mobile/core/api_client.dart';
import 'package:ekaadh_mobile/core/api_config.dart';
import 'package:ekaadh_mobile/models/user_model.dart';

class AuthService {
  static const _tokenKey = 'ekaadh_token';
  static const _storage = FlutterSecureStorage();

  String? token;
  UserModel? user;

  Future<void> init() async {
    token = await _storage.read(key: _tokenKey);
    if (token != null && token!.isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_tokenKey);
    if (legacy == null || legacy.isEmpty) return;
    await _storage.write(key: _tokenKey, value: legacy);
    await prefs.remove(_tokenKey);
    token = legacy;
  }

  Future<void> _persistToken(String? value) async {
    if (value == null) {
      await _storage.delete(key: _tokenKey);
    } else {
      await _storage.write(key: _tokenKey, value: value);
    }
    token = value;
  }

  Map<String, String> get _headers => ApiClient.jsonHeaders(token: token);

  Future<String?> login({
    required String login,
    required String password,
  }) async {
    final response = await ApiClient.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: _headers,
      body: jsonEncode({
        'login': login,
        'password': password,
        'device_name': 'flutter',
      }),
    );

    final body = ApiClient.decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      await _persistToken(body['token'] as String);
      user = UserModel.fromJson(body['user'] as Map<String, dynamic>);
      return null;
    }

    if (body['errors'] is Map) {
      final errors = body['errors'] as Map<String, dynamic>;
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) {
        return first.first.toString();
      }
    }
    return body['message']?.toString() ?? 'Login failed';
  }

  Future<String?> register({
    required String name,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required String otpToken,
    String? email,
  }) async {
    final response = await ApiClient.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'otp_token': otpToken,
        if (email != null && email.isNotEmpty) 'email': email,
      }),
    );

    final body = ApiClient.decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      await _persistToken(body['token'] as String);
      user = UserModel.fromJson(body['user'] as Map<String, dynamic>);
      return null;
    }

    if (body['errors'] is Map) {
      final errors = body['errors'] as Map<String, dynamic>;
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) {
        return first.first.toString();
      }
    }
    return body['message']?.toString() ?? 'Registration failed';
  }

  Future<bool> fetchMe() async {
    if (token == null) return false;
    final response = await ApiClient.get(
      Uri.parse('${ApiConfig.baseUrl}/auth/me'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final body = ApiClient.decode(response);
      user = UserModel.fromJson(body['user'] as Map<String, dynamic>);
      return true;
    }
    await _persistToken(null);
    user = null;
    return false;
  }

  Future<String?> updateProfile({
    required String name,
    String? email,
    bool? pushNotificationsEnabled,
  }) async {
    if (token == null) return 'Sign in to update your profile.';

    final response = await ApiClient.put(
      Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        if (email != null) 'email': email,
        if (pushNotificationsEnabled != null)
          'push_notifications_enabled': pushNotificationsEnabled,
      }),
    );

    final body = ApiClient.decode(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body['user'] is Map<String, dynamic>) {
        user = UserModel.fromJson(body['user'] as Map<String, dynamic>);
      }
      return null;
    }

    if (body['errors'] is Map) {
      final errors = body['errors'] as Map<String, dynamic>;
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) {
        return first.first.toString();
      }
    }
    return body['message']?.toString() ?? 'Could not update profile';
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (token == null) return 'Sign in to change your password.';

    final response = await ApiClient.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/password'),
      headers: _headers,
      body: jsonEncode({
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    final body = ApiClient.decode(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return null;
    }

    if (body['errors'] is Map) {
      final errors = body['errors'] as Map<String, dynamic>;
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) {
        return first.first.toString();
      }
    }
    return body['message']?.toString() ?? 'Could not update password';
  }

  Future<String?> deleteAccount({required String password}) async {
    if (token == null) return 'Sign in to delete your account.';

    final response = await ApiClient.delete(
      Uri.parse('${ApiConfig.baseUrl}/auth/account'),
      headers: _headers,
      body: jsonEncode({'password': password}),
    );

    final body = ApiClient.decode(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      await _persistToken(null);
      user = null;
      return null;
    }

    if (body['errors'] is Map) {
      final errors = body['errors'] as Map<String, dynamic>;
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) {
        return first.first.toString();
      }
    }
    return body['message']?.toString() ?? 'Could not delete account';
  }

  Future<void> logout() async {
    try {
      if (token != null) {
        await ApiClient.post(
          Uri.parse('${ApiConfig.baseUrl}/auth/logout'),
          headers: _headers,
        );
      }
    } catch (_) {
      // Ignore network errors on logout.
    }
    await _persistToken(null);
    user = null;
  }
}
