import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:ekaadh_mobile/core/api_config.dart';

class HtmlFrame extends StatefulWidget {
  const HtmlFrame({
    super.key,
    required this.html,
    this.height = 560,
    this.width,
    this.onHeight,
    this.ignorePointer = false,
  });

  final String html;
  final double height;
  final double? width;
  final ValueChanged<double>? onHeight;
  final bool ignorePointer;

  @override
  State<HtmlFrame> createState() => _HtmlFrameState();
}

class _HtmlFrameState extends State<HtmlFrame> {
  late final WebViewController _controller;
  String? _loaded;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'EkaadhPreview',
        onMessageReceived: (message) {
          final h = double.tryParse(message.message);
          if (h != null) widget.onHeight?.call(h);
        },
      );
    _load();
  }

  @override
  void didUpdateWidget(covariant HtmlFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html) {
      _load();
    }
  }

  void _load() {
    if (widget.html == _loaded) return;
    _loaded = widget.html;
    _controller.loadHtmlString(
      widget.html,
      baseUrl: '${ApiConfig.assetOrigin}/',
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = WebViewWidget(controller: _controller);
    return SizedBox(
      height: widget.height,
      width: widget.width ?? double.infinity,
      child: widget.ignorePointer
          ? Stack(
              fit: StackFit.expand,
              children: [
                view,
                const Positioned.fill(
                  child: ColoredBox(color: Color(0x00000000)),
                ),
              ],
            )
          : view,
    );
  }
}
