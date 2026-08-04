import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ekaadh_mobile/core/api_config.dart';
import 'package:ekaadh_mobile/models/ticket_model.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';

class StaffEventSummary {
  final int id;
  final String title;
  final String? venue;
  final String? city;
  final String? coverImage;
  final String? eventDateLabel;
  final String? eventTimeLabel;
  final int ticketsTotal;
  final int ticketsCheckedIn;

  const StaffEventSummary({
    required this.id,
    required this.title,
    required this.venue,
    required this.city,
    required this.coverImage,
    required this.eventDateLabel,
    required this.eventTimeLabel,
    required this.ticketsTotal,
    required this.ticketsCheckedIn,
  });

  factory StaffEventSummary.fromJson(Map<String, dynamic> json) {
    return StaffEventSummary(
      id: json['id'] as int,
      title: json['title'] as String,
      venue: json['venue'] as String?,
      city: json['city'] as String?,
      coverImage: json['cover_image'] as String?,
      eventDateLabel: json['event_date_label'] as String?,
      eventTimeLabel: json['event_time_label'] as String?,
      ticketsTotal: json['tickets_total'] as int? ?? 0,
      ticketsCheckedIn: json['tickets_checked_in'] as int? ?? 0,
    );
  }
}

class CheckInResult {
  final String result; // valid | used | invalid
  final String message;
  final TicketModel? ticket;

  const CheckInResult({
    required this.result,
    required this.message,
    required this.ticket,
  });

  bool get isValid => result == 'valid';
  bool get isUsed => result == 'used';
  bool get isInvalid => result == 'invalid';
}

class CheckInService {
  CheckInService(this.auth);

  final AuthService auth;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (auth.token != null) 'Authorization': 'Bearer ${auth.token}',
      };

  Future<List<StaffEventSummary>> events() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/staff/events'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Could not load events');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => StaffEventSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CheckInResult> scan({
    required String payload,
    int? eventId,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/staff/check-in'),
      headers: _headers,
      body: jsonEncode({
        'payload': payload,
        if (eventId != null) 'event_id': eventId,
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final ticketJson = body['ticket'] as Map<String, dynamic>?;

    return CheckInResult(
      result: body['result'] as String? ?? 'invalid',
      message: body['message'] as String? ?? 'Unknown result',
      ticket: ticketJson != null ? TicketModel.fromJson(ticketJson) : null,
    );
  }
}
