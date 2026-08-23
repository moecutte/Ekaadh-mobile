import 'package:ekaadh_mobile/core/media_url.dart';

class OrderTicket {
  final int id;
  final String ticketCode;
  final String? holderName;
  final String ticketTypeName;
  final String status;
  final String qrPayload;
  final String? publicUrl;

  const OrderTicket({
    required this.id,
    required this.ticketCode,
    required this.holderName,
    required this.ticketTypeName,
    required this.status,
    required this.qrPayload,
    required this.publicUrl,
  });

  factory OrderTicket.fromJson(Map<String, dynamic> json) {
    return OrderTicket(
      id: _asInt(json['id']),
      ticketCode: json['ticket_code']?.toString() ?? '',
      holderName: json['holder_name'] as String?,
      ticketTypeName: json['ticket_type_name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      qrPayload: json['qr_payload']?.toString() ?? json['ticket_code']?.toString() ?? '',
      publicUrl: json['public_url'] as String?,
    );
  }
}

class OrderItemLine {
  final int id;
  final String? ticketTypeName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  const OrderItemLine({
    required this.id,
    required this.ticketTypeName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderItemLine.fromJson(Map<String, dynamic> json) {
    return OrderItemLine(
      id: _asInt(json['id']),
      ticketTypeName: json['ticket_type_name'] as String?,
      quantity: _asInt(json['quantity']),
      unitPrice: _asDouble(json['unit_price']),
      subtotal: _asDouble(json['subtotal']),
    );
  }
}

class OrderModel {
  final int id;
  final String orderNumber;
  final String status;
  final String buyerName;
  final String? buyerEmail;
  final String buyerPhone;
  final double subtotal;
  final double serviceFee;
  final double totalAmount;
  final String? paymentMethod;
  final String? eventTitle;
  final String? eventCover;
  final String? eventDateLabel;
  final String? eventTimeLabel;
  final String? venue;
  final bool isFree;
  final List<OrderItemLine> items;
  final List<OrderTicket> tickets;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.buyerName,
    required this.buyerEmail,
    required this.buyerPhone,
    required this.subtotal,
    required this.serviceFee,
    required this.totalAmount,
    required this.paymentMethod,
    required this.eventTitle,
    required this.eventCover,
    required this.eventDateLabel,
    required this.eventTimeLabel,
    required this.venue,
    required this.isFree,
    required this.items,
    required this.tickets,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final nested = json['data'];
    if (json['id'] == null && nested is Map<String, dynamic>) {
      json = nested;
    }
    final event = json['event'] as Map<String, dynamic>?;
    return OrderModel(
      id: _asInt(json['id']),
      orderNumber: json['order_number']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      buyerName: (json['buyer_name'] as String?)?.trim().isNotEmpty == true
          ? json['buyer_name'] as String
          : 'Customer',
      buyerEmail: json['buyer_email'] as String?,
      buyerPhone: json['buyer_phone']?.toString() ?? '',
      subtotal: _asDouble(json['subtotal']),
      serviceFee: _asDouble(json['service_fee']),
      totalAmount: _asDouble(json['total_amount']),
      paymentMethod: json['payment_method'] as String?,
      eventTitle: event?['title'] as String?,
      eventCover: MediaUrl.resolve(event?['cover_image'] as String?),
      eventDateLabel: event?['event_date_label'] as String?,
      eventTimeLabel: event?['event_time_label'] as String?,
      venue: event?['venue'] as String?,
      isFree: event?['is_free'] as bool? ??
          (_asDouble(json['total_amount']) <= 0 && json['payment_method'] == null),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItemLine.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      tickets: (json['tickets'] as List<dynamic>? ?? [])
          .map((e) => OrderTicket.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double _asDouble(dynamic value, [double fallback = 0]) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}
