import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:ekaadh_mobile/core/api_config.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';

class SupportFaq {
  const SupportFaq({
    required this.id,
    required this.question,
    required this.answer,
  });

  final int id;
  final String question;
  final String answer;

  factory SupportFaq.fromJson(Map<String, dynamic> json) {
    return SupportFaq(
      id: json['id'] as int,
      question: json['question'] as String,
      answer: json['answer'] as String,
    );
  }
}

class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.senderType,
    required this.body,
    required this.createdAt,
  });

  final int id;
  final String senderType;
  final String body;
  final String? createdAt;

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'] as int,
      senderType: json['sender_type'] as String,
      body: json['body'] as String,
      createdAt: json['created_at'] as String?,
    );
  }
}

class SupportConversation {
  const SupportConversation({
    required this.id,
    required this.status,
    this.guestToken,
  });

  final int id;
  final String status;
  final String? guestToken;

  factory SupportConversation.fromJson(Map<String, dynamic> json) {
    return SupportConversation(
      id: json['id'] as int,
      status: json['status'] as String? ?? 'open',
      guestToken: json['guest_token'] as String?,
    );
  }
}

class SupportService {
  SupportService({required this.auth});

  final AuthService auth;
  static const _guestTokenKey = 'support_guest_token';

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (auth.token != null) {
      headers['Authorization'] = 'Bearer ${auth.token}';
    }
    return headers;
  }

  Future<List<SupportFaq>> fetchFaqs(String locale) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/support/faqs').replace(
      queryParameters: {'locale': locale},
    );
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Could not load FAQs');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['faqs'] as List<dynamic>? ?? [];
    return list
        .map((e) => SupportFaq.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String?> guestToken() async {
    if (auth.token != null) return null;
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString(_guestTokenKey);
    if (token == null || token.isEmpty) {
      token = const Uuid().v4();
      await prefs.setString(_guestTokenKey, token);
    }
    return token;
  }

  Future<SupportConversation> ensureConversation() async {
    final guest = await guestToken();
    final payload = <String, dynamic>{};
    if (guest != null) payload['guest_token'] = guest;

    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/support/conversation'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    if (res.statusCode != 200) {
      throw Exception('Could not start support chat');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final conversation = SupportConversation.fromJson(
      body['conversation'] as Map<String, dynamic>,
    );
    if (conversation.guestToken != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_guestTokenKey, conversation.guestToken!);
    }
    return conversation;
  }

  Future<List<SupportMessage>> fetchMessages({
    required int conversationId,
    int since = 0,
  }) async {
    final guest = await guestToken();
    final params = <String, String>{'since': '$since'};
    if (guest != null) params['guest_token'] = guest;

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/support/conversations/$conversationId/messages',
    ).replace(queryParameters: params);

    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Could not load messages');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['messages'] as List<dynamic>? ?? [];
    return list
        .map((e) => SupportMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SupportMessage> sendMessage({
    required int conversationId,
    String? body,
    int? faqId,
  }) async {
    final guest = await guestToken();
    final payload = <String, dynamic>{};
    if (body != null && body.trim().isNotEmpty) payload['body'] = body.trim();
    if (faqId != null) payload['faq_id'] = faqId;
    if (guest != null) payload['guest_token'] = guest;

    final res = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/support/conversations/$conversationId/messages',
      ),
      headers: _headers,
      body: jsonEncode(payload),
    );
    if (res.statusCode != 201) {
      throw Exception('Could not send message');
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return SupportMessage.fromJson(decoded['message'] as Map<String, dynamic>);
  }

  Future<void> clearGuestSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestTokenKey);
  }
}
