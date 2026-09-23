import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/core/locale_scope.dart';

/// Opens WaafiPay HPP; pops with true on success callback, false on failure.
class CardPaymentWebViewScreen extends StatefulWidget {
  const CardPaymentWebViewScreen({super.key, required this.url});

  final String url;

  @override
  State<CardPaymentWebViewScreen> createState() => _CardPaymentWebViewScreenState();
}

class _CardPaymentWebViewScreenState extends State<CardPaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;
            if (url.contains('/payments/waafi/hpp/success')) {
              _finish(true);
              return NavigationDecision.prevent;
            }
            if (url.contains('/payments/waafi/hpp/failure')) {
              _finish(false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _finish(bool success) {
    if (_done || !mounted) return;
    _done = true;
    Navigator.of(context).pop(success);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          l10n.t('card_visa_mastercard'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        foregroundColor: EkaadhColors.dark,
        elevation: 0,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
