import 'package:ekaadh_mobile/core/api_client.dart';
import 'package:ekaadh_mobile/core/api_config.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    required this.meta,
    required this.readAt,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String kind;
  final Map<String, String> meta;
  final DateTime? readAt;
  final DateTime? createdAt;

  bool get isUnread => readAt == null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawMeta = json['meta'];
    final meta = <String, String>{};
    if (rawMeta is Map) {
      rawMeta.forEach((key, value) {
        if (value != null) meta['$key'] = '$value';
      });
    }
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      kind: json['kind'] as String? ?? '',
      meta: meta,
      readAt: DateTime.tryParse(json['read_at'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

class NotificationListResult {
  const NotificationListResult({
    required this.notifications,
    required this.unreadCount,
  });

  final List<AppNotification> notifications;
  final int unreadCount;
}

class NotificationService {
  NotificationService({required this.token});

  final String token;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<NotificationListResult> list() async {
    final response = await ApiClient.get(
      Uri.parse('${ApiConfig.baseUrl}/notifications'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Could not load notifications.');
    }
    final body = ApiClient.decode(response);
    final data = body['data'] as List<dynamic>? ?? [];
    return NotificationListResult(
      notifications: data
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList(),
      unreadCount: body['unread_count'] as int? ?? 0,
    );
  }

  Future<int> unreadCount() async {
    final response = await ApiClient.get(
      Uri.parse('${ApiConfig.baseUrl}/notifications/unread-count'),
      headers: _headers,
    );
    if (response.statusCode != 200) return 0;
    final body = ApiClient.decode(response);
    return body['unread_count'] as int? ?? 0;
  }

  Future<void> markRead(String id) async {
    await ApiClient.post(
      Uri.parse('${ApiConfig.baseUrl}/notifications/$id/read'),
      headers: _headers,
    );
  }

  Future<void> markAllRead() async {
    await ApiClient.post(
      Uri.parse('${ApiConfig.baseUrl}/notifications/read-all'),
      headers: _headers,
    );
  }
}
