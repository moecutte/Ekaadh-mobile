import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ekaadh_mobile/core/api_client.dart';
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
    String? otpPhone,
    String? walletPin,
    String? locale,
  }) async {
    final response = await ApiClient.post(
      Uri.parse('${ApiConfig.baseUrl}/checkout'),
      headers: ApiClient.jsonHeaders(token: token, locale: locale),
      body: jsonEncode({
        'event_id': eventId,
        'buyer_name': buyerName,
        'buyer_phone': buyerPhone,
        if (buyerEmail != null && buyerEmail.isNotEmpty) 'buyer_email': buyerEmail,
        'payment_method': paymentMethod,
        'items': items,
        'pay_now': true,
        if (kDebugMode && forceFail) 'force_fail': true,
        if (otpToken != null && otpToken.isNotEmpty) 'otp_token': otpToken,
        if (otpPhone != null && otpPhone.isNotEmpty) 'otp_phone': otpPhone,
        if (walletPin != null && walletPin.isNotEmpty) 'wallet_pin': walletPin,
      }),
    );

    final body = ApiClient.decode(response);
    if (body['order'] == null) {
      final msg = _firstError(body) ?? body['message']?.toString() ?? 'Checkout failed';
      throw Exception(msg);
    }

    final order = OrderModel.fromJson(body['order'] as Map<String, dynamic>);
    if (order.status == 'failed') {
      throw CheckoutFailedException(order, body['message']?.toString() ?? 'Payment failed');
    }
    if (response.statusCode >= 400 && order.status != 'paid' && order.status != 'pending') {
      throw Exception(_firstError(body) ?? 'Checkout failed');
    }
    return order;
  }

  Future<OrderModel> fetchOrder(String orderNumber, {required String phone}) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/orders/${Uri.encodeComponent(orderNumber.trim())}',
    ).replace(queryParameters: {'phone': phone.trim()});
    final response = await ApiClient.get(
      uri,
      headers: {'Accept': 'application/json'},
    );
    final body = ApiClient.decode(response);
    if (response.statusCode == 404) {
      throw Exception('No order found for that phone + order number.');
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
            'Could not look up that order. Please try again.',
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
