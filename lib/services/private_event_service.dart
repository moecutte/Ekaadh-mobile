import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ekaadh_mobile/core/api_config.dart';
import 'package:ekaadh_mobile/models/order_model.dart';
import 'package:ekaadh_mobile/models/private_event_model.dart';

class PrivateEventService {
  PrivateEventService({required this.token});

  final String token;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<PrivateEventMeta> meta() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/private-events/meta'),
      headers: _headers,
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw Exception(_error(body) ?? 'Could not load private event pricing.');
    }
    return PrivateEventMeta.fromJson(body);
  }

  Future<List<PrivateEventModel>> list() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/private-events'),
      headers: _headers,
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw Exception(_error(body) ?? 'Could not load private events.');
    }
    final list = body['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => PrivateEventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PrivateEventModel> show(int eventId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/private-events/$eventId'),
      headers: _headers,
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw Exception(_error(body) ?? 'Could not load private event.');
    }
    final data = body['data'] as Map<String, dynamic>? ?? body;
    return PrivateEventModel.fromJson(data);
  }

  Future<({PrivateEventModel event, OrderModel order})> create({
    String? title,
    required String description,
    String? address,
    String? city,
    required int quantity,
    String? ticketLabel,
    required String ticketDesign,
    required int privateEventCategoryId,
    required int invitationDesignId,
    Map<String, String>? invitationFieldValues,
    String? eventDate,
    String? eventTime,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/private-events'),
      headers: _headers,
      body: jsonEncode({
        if (title != null && title.isNotEmpty) 'title': title,
        'description': description,
        if (address != null && address.isNotEmpty) 'address': address,
        if (city != null && city.isNotEmpty) 'city': city,
        'quantity': quantity,
        if (ticketLabel != null && ticketLabel.isNotEmpty) 'ticket_label': ticketLabel,
        'ticket_design': ticketDesign,
        'invitation_design_id': invitationDesignId,
        if (invitationFieldValues != null && invitationFieldValues.isNotEmpty)
          'invitation_field_values': invitationFieldValues,
        if (eventDate != null && eventDate.isNotEmpty) 'event_date': eventDate,
        if (eventTime != null && eventTime.isNotEmpty) 'event_time': eventTime,
        'private_event_category_id': privateEventCategoryId,
      }),
    );
    final body = _decode(response);
    if (response.statusCode >= 400) {
      throw Exception(_error(body) ?? 'Could not create private event.');
    }
    return (
      event: PrivateEventModel.fromJson(body['event'] as Map<String, dynamic>),
      order: OrderModel.fromJson(body['order'] as Map<String, dynamic>),
    );
  }

  Future<({PrivateEventModel event, OrderModel order})> pay({
    required int eventId,
    required String paymentMethod,
    bool forceFail = false,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/private-events/$eventId/pay'),
      headers: _headers,
      body: jsonEncode({
        'payment_method': paymentMethod,
        if (forceFail) 'force_fail': true,
      }),
    );
    final body = _decode(response);
    final orderJson = body['order'] as Map<String, dynamic>?;
    final eventJson = body['event'] as Map<String, dynamic>?;
    if (orderJson == null || eventJson == null) {
      throw Exception(_error(body) ?? 'Payment failed.');
    }
    final order = OrderModel.fromJson(orderJson);
    final event = PrivateEventModel.fromJson(eventJson);
    if (order.status != 'paid') {
      throw Exception(body['message']?.toString() ?? 'Payment could not be completed.');
    }
    return (event: event, order: order);
  }

  Future<({PrivateEventModel event, OrderModel order})> addTickets({
    required int eventId,
    required int quantity,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/private-events/$eventId/add-tickets'),
      headers: _headers,
      body: jsonEncode({'quantity': quantity}),
    );
    final body = _decode(response);
    if (response.statusCode >= 400) {
      throw Exception(_error(body) ?? 'Could not add tickets.');
    }
    return (
      event: PrivateEventModel.fromJson(body['event'] as Map<String, dynamic>),
      order: OrderModel.fromJson(body['order'] as Map<String, dynamic>),
    );
  }

  Future<({List<InvitationModel> invitations, int remaining, PrivateEventModel? event})>
      invitations(int eventId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/private-events/$eventId/invitations'),
      headers: _headers,
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw Exception(_error(body) ?? 'Could not load invitations.');
    }
    final list = (body['data'] as List<dynamic>? ?? [])
        .map((e) => InvitationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final eventJson = body['event'] as Map<String, dynamic>?;
    return (
      invitations: list,
      remaining: body['remaining'] as int? ?? 0,
      event: eventJson == null ? null : PrivateEventModel.fromJson(eventJson),
    );
  }

  Future<int> sendInvitations({
    required int eventId,
    required List<Map<String, dynamic>> guests,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/private-events/$eventId/invitations'),
      headers: _headers,
      body: jsonEncode({'guests': guests}),
    );
    final body = _decode(response);
    if (response.statusCode >= 400) {
      throw Exception(_error(body) ?? 'Could not send invitations.');
    }
    return body['created'] as int? ?? guests.length;
  }

  Future<void> resendInvitation({
    required int eventId,
    required int invitationId,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/private-events/$eventId/invitations/$invitationId/resend',
      ),
      headers: _headers,
      body: jsonEncode({}),
    );
    final body = _decode(response);
    if (response.statusCode >= 400) {
      throw Exception(_error(body) ?? 'Could not resend invitation.');
    }
  }

  Future<void> updatePhone({
    required int eventId,
    required int invitationId,
    required String phone,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/private-events/$eventId/invitations/$invitationId/phone',
      ),
      headers: _headers,
      body: jsonEncode({'phone': phone}),
    );
    final body = _decode(response);
    if (response.statusCode >= 400) {
      throw Exception(_error(body) ?? 'Could not update phone.');
    }
  }

  Future<void> revokeInvitation({
    required int eventId,
    required int invitationId,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/private-events/$eventId/invitations/$invitationId/revoke',
      ),
      headers: _headers,
      body: jsonEncode({}),
    );
    final body = _decode(response);
    if (response.statusCode >= 400) {
      throw Exception(_error(body) ?? 'Could not revoke invitation.');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) return {};
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  String? _error(Map<String, dynamic> body) {
    if (body['errors'] is Map) {
      final errors = body['errors'] as Map<String, dynamic>;
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    return body['message']?.toString();
  }
}
