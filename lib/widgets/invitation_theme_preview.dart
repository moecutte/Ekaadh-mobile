import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ekaadh_mobile/models/private_event_model.dart';

class InvitationThemePreview extends StatelessWidget {
  const InvitationThemePreview({
    super.key,
    required this.design,
    required this.fieldValues,
    this.maxWidth = 340,
    this.qrPayload,
    this.includeQr = true,
    this.guestName,
  });

  final TicketDesignOption design;
  final Map<String, String> fieldValues;
  final double maxWidth;
  final String? qrPayload;
  final bool includeQr;
  final String? guestName;

  String _val(String key) => fieldValues[key]?.trim() ?? '';

  Color _parseColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    var h = hex.replaceFirst('#', '');
    if (h.length == 6) h = 'FF$h';
    final parsed = int.tryParse(h, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }

  String get _headline {
    final a = _val('couple_name_1');
    final b = _val('couple_name_2');
    if (a.isNotEmpty && b.isNotEmpty) return '$a & $b';
    if (a.isNotEmpty) return a;
    if (b.isNotEmpty) return b;
    final title = _val('title');
    if (title.isNotEmpty) return title;
    return design.name;
  }

  String get _dateLine {
    final month = _val('date_month');
    final day = _val('date_day');
    final year = _val('date_year');
    if (month.isNotEmpty && day.isNotEmpty && year.isNotEmpty) {
      return '$month $day, $year';
    }
    return [month, day, year].where((s) => s.isNotEmpty).join(' ');
  }

  String get _timeLine => _val('date_time');

  String get _venue => _val('venue');

  @override
  Widget build(BuildContext context) {
    final cardBg = _parseColor(design.cardBg, Colors.white);
    final textColor = _parseColor(design.text, const Color(0xFF0F1A2E));
    final muted = _parseColor(design.muted, const Color(0xFF64748B));
    final accent = _parseColor(design.accent, const Color(0xFF323891));
    final border = _parseColor(design.border, const Color(0xFFE2E8F0));
    final qrData = (qrPayload != null && qrPayload!.trim().isNotEmpty)
        ? qrPayload!.trim()
        : 'EKAADH-PREVIEW';

    TextStyle script(double size) {
      try {
        return GoogleFonts.greatVibes(
          fontSize: size,
          color: accent,
          height: 1.1,
        );
      } catch (_) {
        return TextStyle(
          fontSize: size,
          color: accent,
          fontStyle: FontStyle.italic,
          height: 1.1,
        );
      }
    }

    TextStyle serif({
      required double size,
      FontWeight weight = FontWeight.w600,
      Color? color,
    }) {
      try {
        return GoogleFonts.cormorantGaramond(
          fontSize: size,
          fontWeight: weight,
          color: color ?? textColor,
          height: 1.25,
        );
      } catch (_) {
        return TextStyle(
          fontSize: size,
          fontWeight: weight,
          color: color ?? textColor,
          height: 1.25,
        );
      }
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (design.inviteLine.trim().isNotEmpty)
                  Text(
                    design.inviteLine.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 3.2,
                      fontWeight: FontWeight.w700,
                      color: muted,
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  design.badge.trim().isNotEmpty
                      ? design.badge
                      : "You're Invited",
                  textAlign: TextAlign.center,
                  style: script(34),
                ),
                if (design.requestLine.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    design.requestLine,
                    textAlign: TextAlign.center,
                    style: serif(
                      size: 14,
                      weight: FontWeight.w400,
                      color: muted,
                    ).copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  _headline,
                  textAlign: TextAlign.center,
                  style: serif(size: 26, weight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                if (_dateLine.isNotEmpty)
                  Text(
                    _dateLine,
                    textAlign: TextAlign.center,
                    style: serif(size: 16),
                  ),
                if (_timeLine.isNotEmpty)
                  Text(
                    _timeLine,
                    textAlign: TextAlign.center,
                    style: serif(size: 13, weight: FontWeight.w400, color: muted),
                  ),
                if (_venue.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _venue,
                    textAlign: TextAlign.center,
                    style: serif(size: 14),
                  ),
                ],
                if (guestName != null && guestName!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Guest of honour',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 2,
                      color: muted,
                    ),
                  ),
                  Text(guestName!.trim(), style: script(22)),
                ],
                if (includeQr) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.white,
                    child: QrImageView(
                      data: qrData,
                      size: 108,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
