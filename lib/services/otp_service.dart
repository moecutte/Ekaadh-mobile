import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ekaadh_mobile/core/api_client.dart';
import 'package:ekaadh_mobile/core/api_config.dart';
import 'package:ekaadh_mobile/models/ticket_model.dart';

class OtpResult {
  const OtpResult({
    required this.phone,
    required this.message,
    this.debugCode,
    this.otpToken,
    this.tickets = const [],
  });

  final String phone;
  final String message;
  final String? debugCode;
  final String? otpToken;
  final List<TicketModel> tickets;
}

class OtpService {
  static const purposeRegister = 'register';
  static const purposeCheckout = 'checkout';
  static const purposeFindTickets = 'find_tickets';

  Future<OtpResult> send({
    required String phone,
    required String purpose,
  }) async {
    final body = await _post('/otp/send', {
      'phone': phone,
      'purpose': purpose,
    });

    return OtpResult(
      phone: body['phone']?.toString() ?? phone,
      message: body['message']?.toString() ?? 'Code sent.',
      debugCode: kDebugMode ? body['debug_code']?.toString() : null,
    );
  }

  Future<OtpResult> verify({
    required String phone,
    required String purpose,
    required String otp,
  }) async {
    final body = await _post('/otp/verify', {
      'phone': phone,
      'purpose': purpose,
      'otp': otp,
    });

    final ticketsJson = body['tickets'] as List<dynamic>? ?? [];
    final tickets = ticketsJson
        .map((e) => TicketModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return OtpResult(
      phone: body['phone']?.toString() ?? phone,
      message: body['message']?.toString() ?? 'Phone confirmed.',
      otpToken: body['otp_token']?.toString(),
      tickets: tickets,
    );
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> payload) async {
    final response = await ApiClient.post(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: ApiClient.jsonHeaders(),
        body: jsonEncode(payload),
      );

    final body = ApiClient.decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _firstError(body) ??
            body['message']?.toString() ??
            'Something went wrong. Please try again.',
      );
    }

    return body;
  }

  String? _firstError(Map<String, dynamic> body) {
    if (body['errors'] is Map) {
      final errors = body['errors'] as Map<String, dynamic>;
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    return null;
  }
}
