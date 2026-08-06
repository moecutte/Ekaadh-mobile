import 'package:ekaadh_mobile/core/media_url.dart';

class TicketTypeModel {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int remaining;
  final int maxPerOrder;

  const TicketTypeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.remaining,
    required this.maxPerOrder,
  });

  factory TicketTypeModel.fromJson(Map<String, dynamic> json) {
    return TicketTypeModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      remaining: json['remaining'] as int? ?? 0,
      maxPerOrder: json['max_per_order'] as int? ?? 10,
    );
  }
}

class EventModel {
  final int id;
  final String title;
  final String slug;
  final String? description;
  final String? category;
  final String? venue;
  final String? city;
  final String? eventDate;
  final String? eventDateLabel;
  final String? eventMonth;
  final String? eventDay;
  final String? eventTimeLabel;
  final String? coverImage;
  final bool isFeatured;
  final double? startingPrice;
  final String? organizerName;
  final List<TicketTypeModel> ticketTypes;

  const EventModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.category,
    required this.venue,
    required this.city,
    required this.eventDate,
    required this.eventDateLabel,
    required this.eventMonth,
    required this.eventDay,
    required this.eventTimeLabel,
    required this.coverImage,
    required this.isFeatured,
    required this.startingPrice,
    required this.organizerName,
    required this.ticketTypes,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final organizer = json['organizer'] as Map<String, dynamic>?;
    final types = (json['ticket_types'] as List<dynamic>? ?? [])
        .map((e) => TicketTypeModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return EventModel(
      id: json['id'] as int,
      title: json['title'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      venue: json['venue'] as String?,
      city: json['city'] as String?,
      eventDate: json['event_date'] as String?,
      eventDateLabel: json['event_date_label'] as String?,
      eventMonth: json['event_month'] as String?,
      eventDay: json['event_day'] as String?,
      eventTimeLabel: json['event_time_label'] as String?,
      coverImage: MediaUrl.resolve(json['cover_image'] as String?),
      isFeatured: json['is_featured'] as bool? ?? false,
      startingPrice: json['starting_price'] == null
          ? null
          : (json['starting_price'] as num).toDouble(),
      organizerName: organizer?['business_name'] as String?,
      ticketTypes: types,
    );
  }
}
