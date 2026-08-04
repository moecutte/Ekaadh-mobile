import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ekaadh_mobile/core/api_config.dart';
import 'package:ekaadh_mobile/models/ticket_model.dart';

class TicketService {
  Future<List<TicketModel>> mine({
    required String token,
    String tab = 'upcoming',
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/my-tickets').replace(
      queryParameters: {'tab': tab},
    );
    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode != 200) {
      throw Exception('Failed to load tickets (${response.statusCode})');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? [];
    return data.map((e) => TicketModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TicketModel> show(String code) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/tickets/$code'),
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Ticket not found');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? body;
    return TicketModel.fromJson(data);
  }
}
