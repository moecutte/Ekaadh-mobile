import 'dart:async';
import 'dart:io';

import 'package:ekaadh_mobile/l10n/app_strings.dart';
import 'package:ekaadh_mobile/services/checkout_service.dart';
import 'package:http/http.dart' as http;

/// Maps exceptions / HTTP failures to short user-facing copy.
class UserFacingError {
  UserFacingError._();

  static bool isNetwork(Object error) {
    if (error is SocketException ||
        error is http.ClientException ||
        error is TimeoutException ||
        error is HandshakeException) {
      return true;
    }
    final text = error.toString().toLowerCase();
    return text.contains('socketexception') ||
        text.contains('clientexception') ||
        text.contains('failed host lookup') ||
        text.contains('connection refused') ||
        text.contains('connection reset') ||
        text.contains('network is unreachable') ||
        text.contains('software caused connection abort') ||
        text.contains('timed out') ||
        text.contains('timeout') ||
        text.contains('broken pipe');
  }

  /// Prefer [t] from [LocaleScope.of(context).t] when available.
  static String message(
    Object? error, {
    String Function(String key)? t,
  }) {
    String tr(String key) => t != null ? t(key) : AppStrings.t('en', key);

    if (error == null) return tr('error_generic');

    if (error is CheckoutFailedException) {
      return paymentMessage(error.message, t: t);
    }

    if (isNetwork(error)) {
      return tr('error_offline');
    }

    var text = error.toString().trim();
    text = text.replaceFirst(RegExp(r'^Exception:\s*'), '');
    text = text.replaceFirst(RegExp(r'^ApiException:\s*'), '');

    if (text.isEmpty) return tr('error_generic');

    // Status-code dumps from older service throws.
    if (RegExp(r'failed to load .+\(\d{3}\)$', caseSensitive: false)
            .hasMatch(text) ||
        RegExp(r'request failed \(\d{3}\)$', caseSensitive: false)
            .hasMatch(text) ||
        RegExp(r'could not look up order \(\d{3}\)$', caseSensitive: false)
            .hasMatch(text)) {
      if (text.contains('(401)') || text.contains('(403)')) {
        return tr('error_session');
      }
      if (text.contains('(404)')) return tr('error_not_found');
      if (text.contains('(429)')) return tr('error_too_many');
      return tr('error_generic');
    }

    if (_looksTechnical(text)) {
      return tr('error_generic');
    }

    return paymentMessage(text, t: t);
  }

  /// Maps gateway / API payment errors to copy the user can act on.
  static String paymentMessage(
    String? raw, {
    String Function(String key)? t,
  }) {
    String tr(String key) => t != null ? t(key) : AppStrings.t('en', key);
    final text = (raw ?? '').trim();
    if (text.isEmpty) return tr('error_payment_failed');

    final lower = text.toLowerCase();
    if (lower == 'payment failed' ||
        lower == 'payment failed.' ||
        lower == 'payment could not be completed.' ||
        lower == 'payment could not be completed') {
      return tr('error_payment_failed');
    }

    if (_looksTechnical(text)) {
      return tr('error_payment_failed');
    }

    if (lower.contains('not sufficient') ||
        lower.contains('insufficient') ||
        lower.contains('enough money') ||
        lower.contains('top up') ||
        lower.contains('kuma filna')) {
      return tr('payment_failed_insufficient');
    }

    if (lower.contains('user_rejected') ||
        lower.contains('cancelled on your phone') ||
        lower.contains('approve the wallet') ||
        lower.contains('lagaga noqday')) {
      return tr('payment_failed_cancelled');
    }

    if (lower.contains('invalid phone') ||
        lower.contains('charge that phone') ||
        lower.contains('lama dallaci karin')) {
      return tr('payment_failed_invalid_phone');
    }

    if (lower.contains('temporarily unavailable') ||
        lower.contains('hadda lama heli karo')) {
      return tr('payment_failed_unavailable');
    }

    return text;
  }

  static bool _looksTechnical(String text) {
    final lower = text.toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('clientexception') ||
        lower.contains('formatexception') ||
        lower.contains('typeerror') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused') ||
        lower.contains('is the laravel') ||
        lower.contains('stack trace') ||
        lower.contains('sqlstate') ||
        lower.contains('curl') ||
        lower.contains('ssl') ||
        lower.contains('certificate') ||
        lower.contains('cafile') ||
        lower.startsWith('rcs_') ||
        RegExp(r'your balance is\s*\)').hasMatch(lower) ||
        lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        RegExp(r'\bat\s+.+\.dart:\d+').hasMatch(text);
  }
}
