import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ekaadh_mobile/models/private_event_model.dart';
import 'package:ekaadh_mobile/widgets/design_network_image.dart';

class InvitationOverlayPreview extends StatelessWidget {
  const InvitationOverlayPreview({
    super.key,
    required this.design,
    required this.fieldValues,
    this.maxWidth = 340,
    this.qrPayload,
    this.showQrChrome = true,
    this.includeQr = true,
  });

  final TicketDesignOption design;
  final Map<String, String> fieldValues;
  final double maxWidth;
  /// When set (ticket view), uses the real QR payload instead of the preview sample.
  final String? qrPayload;
  final bool showQrChrome;
  /// When false, omit QR fields (for social share images).
  final bool includeQr;

  String _textFor(InvitationDesignFieldOption field) {
    final value = fieldValues[field.fieldKey]?.trim();
    if (value != null && value.isNotEmpty) return value;
    return field.defaultText?.trim() ?? field.placeholder?.trim() ?? '';
  }

  Color _parseColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    var h = hex.replaceFirst('#', '');
    if (h.length == 6) h = 'FF$h';
    final parsed = int.tryParse(h, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }

  TextAlign _align(String align) {
    switch (align) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.center;
    }
  }

  FontWeight _weight(String weight) {
    final n = int.tryParse(weight) ?? 400;
    if (n >= 700) return FontWeight.w700;
    if (n >= 600) return FontWeight.w600;
    if (n >= 500) return FontWeight.w500;
    return FontWeight.w400;
  }

  /// Admin / ticket overlay design at 420px wide; scale fonts to this canvas width.
  static const double designCanvasWidth = 420;

  TextStyle _textStyle(
    InvitationDesignFieldOption field,
    Color fallbackText, {
    required double canvasWidth,
  }) {
    final family = field.fontFamily?.trim();
    final scale = canvasWidth / designCanvasWidth;
    final base = TextStyle(
      fontSize: field.fontSize.toDouble() * scale,
      fontWeight: _weight(field.fontWeight),
      fontStyle: field.fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
      color: _parseColor(field.color, fallbackText),
      height: 1.25,
    );
    if (family == null || family.isEmpty) {
      return base.copyWith(fontFamily: 'Montserrat');
    }
    try {
      return GoogleFonts.getFont(family, textStyle: base);
    } catch (_) {
      return base.copyWith(fontFamily: family);
    }
  }

  static const _sampleQrPayload = 'EKAADH-PREVIEW';

  String get _qrData =>
      (qrPayload != null && qrPayload!.trim().isNotEmpty)
          ? qrPayload!.trim()
          : _sampleQrPayload;

  @override
  Widget build(BuildContext context) {
    final cardBg = _parseColor(design.cardBg, Colors.white);
    final textColor = _parseColor(design.text, const Color(0xFF0F1A2E));
    final muted = _parseColor(design.muted, const Color(0xFF64748B));
    final accent = _parseColor(design.accent, const Color(0xFF323891));
    final border = _parseColor(design.border, const Color(0xFFE2E8F0));
    final graphic = design.resolvedGraphicUrl;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: AspectRatio(
          aspectRatio: 3 / 4.2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (graphic != null && graphic.isNotEmpty)
                        Positioned.fill(
                          child: DesignNetworkImage(
                            url: graphic,
                            fit: BoxFit.cover,
                            fallbackColor: cardBg,
                          ),
                        ),
                      for (final field in design.previewFields)
                        if (!field.isQr && _textFor(field).isNotEmpty)
                          Positioned(
                            left: w * field.posX / 100,
                            top: h * field.posY / 100,
                            width: w * field.boxWidth / 100,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4 * (w / designCanvasWidth),
                              ),
                              child: Text(
                                _textFor(field),
                                textAlign: _align(field.textAlign),
                                style: _textStyle(
                                  field,
                                  textColor,
                                  canvasWidth: w,
                                ),
                              ),
                            ),
                          ),
                      for (final field in design.previewFields)
                        if (field.isQr && includeQr)
                          Positioned(
                            left: w * field.posX / 100,
                            top: h * field.posY / 100,
                            width: w * field.boxWidth / 100,
                            child: showQrChrome
                                ? ColoredBox(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AspectRatio(
                                            aspectRatio: 1,
                                            child: ColoredBox(
                                              color: Colors.white,
                                              child: QrImageView(
                                                data: _qrData,
                                                backgroundColor: Colors.white,
                                                eyeStyle: const QrEyeStyle(
                                                  eyeShape: QrEyeShape.square,
                                                  color: Color(0xFF0F1A2E),
                                                ),
                                                dataModuleStyle:
                                                    const QrDataModuleStyle(
                                                  dataModuleShape:
                                                      QrDataModuleShape.square,
                                                  color: Color(0xFF0F1A2E),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text.rich(
                                            TextSpan(
                                              style: TextStyle(
                                                fontSize: 7,
                                                height: 1.25,
                                                color: muted,
                                              ),
                                              children: [
                                                const TextSpan(
                                                    text:
                                                        'Scan at entry · Status: '),
                                                TextSpan(
                                                  text: 'Valid',
                                                  style: TextStyle(
                                                    color: accent,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : AspectRatio(
                                    aspectRatio: 1,
                                    child: ColoredBox(
                                      color: Colors.white,
                                      child: QrImageView(
                                        data: _qrData,
                                        backgroundColor: Colors.white,
                                        eyeStyle: const QrEyeStyle(
                                          eyeShape: QrEyeShape.square,
                                          color: Color(0xFF0F1A2E),
                                        ),
                                        dataModuleStyle:
                                            const QrDataModuleStyle(
                                          dataModuleShape:
                                              QrDataModuleShape.square,
                                          color: Color(0xFF0F1A2E),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
