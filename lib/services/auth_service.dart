import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ekaadh_mobile/core/api_config.dart';
import 'package:ekaadh_mobile/models/user_model.dart';

class AuthService {
  static const _tokenKey = 'ekaadh_token';

  String? token;
  UserModel? user;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
  }

  Future<void> _persistToken(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, value);
    }
    token = value;
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<String?> login({
    required String login,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: _headers,
      body: jsonEncode({
        'login': login,
        'password': password,
        'device_name': 'flutter',
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
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
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'otp_token': otpToken,
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
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
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/auth/me'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
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
  }) async {
    if (token == null) return 'Sign in to update your profile.';

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        if (email != null) 'email': email,
      }),
    );

    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

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

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/password'),
      headers: _headers,
      body: jsonEncode({
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

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

  Future<void> logout() async {
    try {
      if (token != null) {
        await http.post(
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
