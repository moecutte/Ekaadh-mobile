import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
  late final String _viewType;
  html.IFrameElement? _iframe;
  StreamSubscription<html.MessageEvent>? _messages;

  @override
  void initState() {
    super.initState();
    _viewType = 'ekaadh-invite-${identityHashCode(this)}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..srcdoc = widget.html
        ..style.border = 'none'
        ..style.width = widget.width != null ? '${widget.width}px' : '100%'
        ..style.height = '${widget.height}px'
        ..style.overflow = 'hidden'
        ..style.backgroundColor = 'transparent'
        ..style.pointerEvents = widget.ignorePointer ? 'none' : 'auto';
      iframe.onLoad.listen((_) {
        _listenHeight();
        _disableHostPointerEvents(iframe);
      });
      _iframe = iframe;
      return iframe;
    });
  }

  @override
  void didUpdateWidget(covariant HtmlFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_iframe == null) return;
    if (oldWidget.html != widget.html) {
      _iframe!.srcdoc = widget.html;
    }
    if (oldWidget.width != widget.width) {
      _iframe!.style.width =
          widget.width != null ? '${widget.width}px' : '100%';
    }
    if (oldWidget.height != widget.height) {
      _iframe!.style.height = '${widget.height}px';
    }
    if (oldWidget.ignorePointer != widget.ignorePointer) {
      _iframe!.style.pointerEvents = widget.ignorePointer ? 'none' : 'auto';
    }
  }

  @override
  void dispose() {
    _messages?.cancel();
    super.dispose();
  }

  void _disableHostPointerEvents(html.IFrameElement iframe) {
    if (!widget.ignorePointer) return;
    html.Element? node = iframe;
    for (var i = 0; i < 5 && node != null; i++) {
      node.style.pointerEvents = 'none';
      final tag = node.tagName.toLowerCase();
      if (tag.contains('platform-view')) break;
      node = node.parent;
    }
  }

  void _listenHeight() {
    _messages ??= html.window.onMessage.listen((event) {
      final height = _previewHeight(event.data);
      if (height != null) widget.onHeight?.call(height);
    });
  }

  double? _previewHeight(dynamic data) {
    try {
      final type = data['type']?.toString();
      if (type != 'ekaadh-invite-preview-height') return null;
      final height = data['height'];
      if (height is num) return height.toDouble();
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width ?? double.infinity,
      child: HtmlElementView(
        viewType: _viewType,
        hitTestBehavior: widget.ignorePointer
            ? PlatformViewHitTestBehavior.transparent
            : PlatformViewHitTestBehavior.opaque,
      ),
    );
  }
}
