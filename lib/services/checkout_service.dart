import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ekaadh_mobile/core/api_config.dart';
import 'package:ekaadh_mobile/models/order_model.dart';

class CheckoutService {
  Future<OrderModel> checkout({
    required int eventId,
    required String buyerName,
    required String buyerPhone,
    String? buyerEmail,
    required String paymentMethod,
    required List<Map<String, int>> items,
    bool forceFail = false,
    String? token,
    String? otpToken,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/checkout'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'event_id': eventId,
        'buyer_name': buyerName,
        'buyer_phone': buyerPhone,
        if (buyerEmail != null && buyerEmail.isNotEmpty) 'buyer_email': buyerEmail,
        'payment_method': paymentMethod,
        'items': items,
        'pay_now': true,
        if (forceFail) 'force_fail': true,
        if (otpToken != null && otpToken.isNotEmpty) 'otp_token': otpToken,
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['order'] == null) {
      final msg = _firstError(body) ?? body['message']?.toString() ?? 'Checkout failed';
      throw Exception(msg);
    }

    final order = OrderModel.fromJson(body['order'] as Map<String, dynamic>);
    if (order.status == 'failed') {
      throw CheckoutFailedException(order, body['message']?.toString() ?? 'Payment failed');
    }
    if (response.statusCode >= 400 && order.status != 'paid') {
      throw Exception(_firstError(body) ?? 'Checkout failed');
    }
    return order;
  }

  Future<OrderModel> fetchOrder(String orderNumber, {required String phone}) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/orders/${Uri.encodeComponent(orderNumber.trim())}',
    ).replace(queryParameters: {'phone': phone.trim()});
    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};
    if (response.statusCode == 404) {
      throw Exception('No paid order found for that phone + order number.');
    }
    if (response.statusCode == 422) {
      throw Exception(
        body['message']?.toString() ??
            'Enter both the checkout phone and order number.',
      );
    }
    if (response.statusCode != 200) {
      throw Exception(
        body['message']?.toString() ??
            'Could not look up order (${response.statusCode})',
      );
    }
    final data = body['data'] as Map<String, dynamic>? ?? body;
    return OrderModel.fromJson(data);
  }

  String? _firstError(Map<String, dynamic> body) {
    if (body['errors'] is Map) {
      final errors = body['errors'] as Map<String, dynamic>;
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    return null;
  }
}

class CheckoutFailedException implements Exception {
  CheckoutFailedException(this.order, this.message);
  final OrderModel order;
  final String message;

  @override
  String toString() => message;
}
