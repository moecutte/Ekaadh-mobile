import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/models/private_event_model.dart';
import 'package:ekaadh_mobile/widgets/html_frame.dart';
import 'package:ekaadh_mobile/widgets/invitation_overlay_preview.dart';
import 'package:ekaadh_mobile/widgets/invitation_theme_preview.dart';

/// Shrink a 420px invitation to [tileWidth] using a numeric scale.
/// CSS `vw` inside an iframe is the screen width, not the tile, so it clips.
String fitCompactInvitationHtml(String html, double tileWidth) {
  final scale = (tileWidth / 420).clamp(0.08, 1.0);
  const marker = 'ekaadh-picker-fit';
  final style = '''
<style id="$marker">
html,body{margin:0!important;padding:0!important;overflow:hidden!important;background:transparent!important;width:100%!important;height:100%!important}
.invite-compact-fit{width:420px!important;transform-origin:top left!important;transform:scale($scale)!important}
body.ekaadh-picker-body{width:420px!important;transform-origin:top left!important;transform:scale($scale)!important}
.invitation-design-card,article.invitation-design-card{margin-left:0!important;margin-right:0!important}
</style>
''';
  var next = html.replaceAll(
    RegExp(r'<style id="ekaadh-picker-fit">[\s\S]*?</style>'),
    '',
  );
  if (next.contains('</head>')) {
    next = next.replaceFirst('</head>', '$style</head>');
  } else {
    next = '$style$next';
  }
  if (!next.contains('invite-compact-fit') && !next.contains('ekaadh-picker-body')) {
    next = next.replaceFirstMapped(
      RegExp(r'<body([^>]*)>'),
      (m) => '<body${m[1]} class="ekaadh-picker-body">',
    );
  }
  return next;
}

/// Renders the same HTML invitation guests receive (`preview-frame`).
class InvitationHtmlPreview extends StatefulWidget {
  const InvitationHtmlPreview({
    super.key,
    required this.html,
    this.compact = false,
    this.minHeight = 520,
    this.fallback,
  });

  final String? html;
  final bool compact;
  final double minHeight;
  final Widget? fallback;

  @override
  State<InvitationHtmlPreview> createState() => _InvitationHtmlPreviewState();
}

class _InvitationHtmlPreviewState extends State<InvitationHtmlPreview> {
  double _height = 560;

  @override
  void initState() {
    super.initState();
    _height = widget.compact ? 220 : widget.minHeight;
  }

  @override
  Widget build(BuildContext context) {
    final html = widget.html;
    if (html == null || html.trim().isEmpty) {
      return widget.fallback ??
          const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
    }

    if (widget.compact) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite && constraints.maxWidth > 0
              ? constraints.maxWidth
              : 160.0;
          final height = constraints.maxHeight.isFinite && constraints.maxHeight > 0
              ? constraints.maxHeight
              : width * 4 / 3;
          return HtmlFrame(
            html: fitCompactInvitationHtml(html, width),
            width: width,
            height: height,
            ignorePointer: true,
          );
        },
      );
    }

    return HtmlFrame(
      html: html,
      height: _height,
      onHeight: (h) {
        final next = h.clamp(360, 1200).toDouble();
        if ((next - _height).abs() < 8) return;
        setState(() => _height = next);
      },
    );
  }
}

class InvitationDesignPreview extends StatelessWidget {
  const InvitationDesignPreview({
    super.key,
    required this.design,
    required this.fieldValues,
    this.html,
    this.compact = false,
    this.minHeight = 560,
    this.includeQr = false,
  });

  final TicketDesignOption design;
  final Map<String, String> fieldValues;
  final String? html;
  final bool compact;
  final double minHeight;
  final bool includeQr;

  @override
  Widget build(BuildContext context) {
    final fallback = design.isOverlay
        ? InvitationOverlayPreview(
            design: design,
            fieldValues: fieldValues,
            includeQr: includeQr,
            showQrChrome: false,
          )
        : InvitationThemePreview(
            design: design,
            fieldValues: fieldValues,
            includeQr: includeQr,
          );

    final sizedFallback = compact
        ? FittedBox(
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            child: SizedBox(width: 420, child: fallback),
          )
        : fallback;

    if (html == null || html!.trim().isEmpty) {
      return sizedFallback;
    }

    return InvitationHtmlPreview(
      html: html,
      compact: compact,
      minHeight: minHeight,
      fallback: ColoredBox(
        color: EkaadhColors.surface,
        child: sizedFallback,
      ),
    );
  }
}
