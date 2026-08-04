import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ekaadh_mobile/core/api_config.dart';
import 'package:ekaadh_mobile/models/event_model.dart';

class EventListResult {
  const EventListResult({
    required this.events,
    required this.categories,
    required this.cities,
  });

  final List<EventModel> events;
  final List<String> categories;
  final List<String> cities;
}

class EventService {
  Future<List<EventModel>> list({
    String? q,
    String? category,
    String? city,
    bool featured = false,
  }) async {
    final page = await search(
      q: q,
      category: category,
      city: city,
      featured: featured,
    );
    return page.events;
  }

  Future<EventListResult> search({
    String? q,
    String? category,
    String? city,
    bool featured = false,
  }) async {
    final params = <String, String>{
      'per_page': '50',
      if (q != null && q.isNotEmpty) 'q': q,
      if (category != null && category.isNotEmpty && category != 'All') 'category': category,
      if (city != null && city.isNotEmpty && city != 'All') 'city': city,
      if (featured) 'featured': '1',
    };

    final uri = Uri.parse('${ApiConfig.baseUrl}/events').replace(queryParameters: params);
    final response = await http.get(uri, headers: {'Accept': 'application/json'});
    if (response.statusCode != 200) {
      throw Exception('Failed to load events (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? [];
    final filters = body['filters'] as Map<String, dynamic>? ?? {};
    final categories = (filters['categories'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    final cities = (filters['cities'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();

    return EventListResult(
      events: data.map((e) => EventModel.fromJson(e as Map<String, dynamic>)).toList(),
      categories: categories,
      cities: cities,
    );
  }

  Future<EventModel> show(String idOrSlug) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/events/$idOrSlug'),
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load event');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? body;
    return EventModel.fromJson(data);
  }
}
