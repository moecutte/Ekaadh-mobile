import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ekaadh_mobile/core/api_config.dart';

class ApiClient {
  static const timeout = Duration(seconds: 25);

  static final http.Client _client = http.Client();

  static Map<String, String> jsonHeaders({String? token, String? locale}) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (locale != null && locale.isNotEmpty) 'Accept-Language': locale,
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  static Future<http.Response> get(Uri uri, {Map<String, String>? headers}) {
    return _client.get(uri, headers: headers).timeout(timeout);
  }

  static Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _client.post(uri, headers: headers, body: body).timeout(timeout);
  }

  static Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _client.put(uri, headers: headers, body: body).timeout(timeout);
  }

  static Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _client.delete(uri, headers: headers, body: body).timeout(timeout);
  }

  static Uri api(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  static Map<String, dynamic> decode(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      throw Exception('Could not reach Ekaadh. Please try again.');
    }
  }
}
