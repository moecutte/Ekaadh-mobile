import 'package:ekaadh_mobile/core/api_client.dart';
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
    final response = await ApiClient.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode != 200) {
      throw Exception('Could not load tickets. Please try again.');
    }
    final body = ApiClient.decode(response);
    final data = body['data'] as List<dynamic>? ?? [];
    return data.map((e) => TicketModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TicketModel> show(String code, {String? token, String? phone}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/tickets/$code').replace(
      queryParameters: {
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
    final response = await ApiClient.get(uri, headers: {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    });
    if (response.statusCode != 200) {
      throw Exception('Ticket not found');
    }
    final body = ApiClient.decode(response);
    final data = body['data'] as Map<String, dynamic>? ?? body;
    return TicketModel.fromJson(data);
  }
}
