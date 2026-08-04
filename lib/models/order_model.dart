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
      id: json['id'] as int,
      ticketCode: json['ticket_code'] as String,
      holderName: json['holder_name'] as String?,
      ticketTypeName: json['ticket_type_name'] as String,
      status: json['status'] as String,
      qrPayload: json['qr_payload'] as String? ?? json['ticket_code'] as String,
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
      id: json['id'] as int,
      ticketTypeName: json['ticket_type_name'] as String?,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
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
    required this.items,
    required this.tickets,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final event = json['event'] as Map<String, dynamic>?;
    return OrderModel(
      id: json['id'] as int,
      orderNumber: json['order_number'] as String,
      status: json['status'] as String,
      buyerName: json['buyer_name'] as String,
      buyerEmail: json['buyer_email'] as String?,
      buyerPhone: json['buyer_phone'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
      serviceFee: (json['service_fee'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String?,
      eventTitle: event?['title'] as String?,
      eventCover: event?['cover_image'] as String?,
      eventDateLabel: event?['event_date_label'] as String?,
      eventTimeLabel: event?['event_time_label'] as String?,
      venue: event?['venue'] as String?,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItemLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      tickets: (json['tickets'] as List<dynamic>? ?? [])
          .map((e) => OrderTicket.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
