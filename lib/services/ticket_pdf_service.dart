import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ekaadh_mobile/models/private_event_model.dart';
import 'package:ekaadh_mobile/models/ticket_model.dart';
import 'package:ekaadh_mobile/services/invitation_pdf_fonts.dart';

/// Builds a PDF that mirrors the invitation design (overlay) or classic ticket.
class TicketPdfService {
  static const _brand = 0xFF323891;
  static const _brandDark = 0xFF262A6D;
  static const _soft = 0xFF94A3B8;
  static const _dash = 0xFFE8EDE9;

  Future<File> download(TicketModel ticket) async {
    final bytes = await buildPdf(ticket);
    final dir = await getTemporaryDirectory();
    final safeCode = ticket.ticketCode.replaceAll(RegExp(r'[^\w\-]+'), '_');
    final file = File('${dir.path}/Ekaadh-$safeCode.pdf');
    await file.writeAsBytes(bytes, flush: true);
    await OpenFilex.open(file.path);
    return file;
  }

  Future<Uint8List> buildPdf(TicketModel ticket) async {
    if (ticket.isOverlayInvite) {
      return _buildOverlayPdf(ticket);
    }
    return _buildClassicPdf(ticket);
  }

  Future<Uint8List> _buildOverlayPdf(TicketModel ticket) async {
    final design = ticket.invitationDesign!;
    final qrBytes = await _qrPngBytes(ticket.qrPayload);
    final graphicBytes = await _coverBytes(design.resolvedGraphicUrl);
    const fallbackText = 0xFF0F1A2E;
    final pageFormat = const PdfPageFormat(420, 588);
    final pageW = pageFormat.width;
    final pageH = pageFormat.height;

    final fontByField = <String, pw.Font?>{};
    for (final field in design.cardFields) {
      if (field.isQr) continue;
      final weight = int.tryParse(field.fontWeight) ?? 400;
      fontByField[field.fieldKey] = await InvitationPdfFonts.load(
        field.fontFamily,
        weight: weight,
        italic: field.fontStyle == 'italic',
      );
    }

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Container(
            width: pageW,
            height: pageH,
            color: _pdfColor(design.cardBg, 0xFFFFFFFF),
            child: pw.Stack(
              children: [
                if (graphicBytes != null)
                  pw.Positioned.fill(
                    child: pw.Image(
                      pw.MemoryImage(graphicBytes),
                      fit: pw.BoxFit.cover,
                    ),
                  ),
                ...[
                  for (final field in design.cardFields)
                    if (!field.isQr)
                      ..._textFieldWidgets(
                        ticket: ticket,
                        field: field,
                        values: design.fieldValues,
                        pageW: pageW,
                        pageH: pageH,
                        fallbackText: fallbackText,
                        font: fontByField[field.fieldKey],
                      ),
                ],
                ...[
                  for (final field in design.cardFields)
                    if (field.isQr)
                      pw.Positioned(
                        left: pageW * field.posX / 100,
                        top: pageH * field.posY / 100,
                        child: pw.SizedBox(
                          width: pageW * field.boxWidth / 100,
                          child: pw.Center(
                            child: pw.Image(
                              pw.MemoryImage(qrBytes),
                              width: (pageW * field.boxWidth / 100)
                                  .clamp(48, 160),
                              height: (pageW * field.boxWidth / 100)
                                  .clamp(48, 160),
                            ),
                          ),
                        ),
                      ),
                ],
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  List<pw.Widget> _textFieldWidgets({
    required TicketModel ticket,
    required InvitationDesignFieldOption field,
    required Map<String, String> values,
    required double pageW,
    required double pageH,
    required int fallbackText,
    pw.Font? font,
  }) {
    var raw = values[field.fieldKey]?.trim() ?? '';
    if (field.fieldKey == 'guest_name') {
      final holder = ticket.holderName?.trim();
      if (holder != null && holder.isNotEmpty) raw = holder;
    }
    if (raw.isEmpty) {
      raw = field.defaultText?.trim() ?? '';
    }
    if (raw.isEmpty) return const [];

    final weightNum = int.tryParse(field.fontWeight) ?? 400;
    final align = switch (field.textAlign) {
      'left' => pw.TextAlign.left,
      'right' => pw.TextAlign.right,
      _ => pw.TextAlign.center,
    };

    return [
      pw.Positioned(
        left: pageW * field.posX / 100,
        top: pageH * field.posY / 100,
        child: pw.SizedBox(
          width: pageW * field.boxWidth / 100,
          child: pw.Text(
            raw,
            textAlign: align,
            style: pw.TextStyle(
              font: font,
              fontSize: field.fontSize.toDouble().clamp(8, 48),
              fontWeight:
                  weightNum >= 600 ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontStyle: field.fontStyle == 'italic'
                  ? pw.FontStyle.italic
                  : pw.FontStyle.normal,
              color: _pdfColor(field.color, fallbackText),
              lineSpacing: 1.5,
            ),
          ),
        ),
      ),
    ];
  }

  Future<Uint8List> _buildClassicPdf(TicketModel ticket) async {
    final qrBytes = await _qrPngBytes(ticket.qrPayload);
    final coverBytes = await _coverBytes(ticket.eventCover);
    final logo = await _logoBytes();

    final brand = PdfColor.fromInt(_brand);
    final brandDark = PdfColor.fromInt(_brandDark);
    final soft = PdfColor.fromInt(_soft);
    final dash = PdfColor.fromInt(_dash);

    final meta = [
      ticket.eventDateLabel,
      ticket.eventTimeLabel,
      ticket.venue,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

    final statusLine = ticket.status == 'valid'
        ? 'Scan at entry · Valid once only'
        : 'Scan at entry · ${ticket.status}';

    const pageFormat = PdfPageFormat(420, 680);
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Container(
            color: brandDark,
            padding: const pw.EdgeInsets.all(28),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Row(
                  children: [
                    if (logo != null)
                      pw.Image(pw.MemoryImage(logo), height: 22)
                    else
                      pw.Text(
                        'ekaadh',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    pw.Spacer(),
                    pw.Text(
                      'Your Ticket',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 18),
                pw.Expanded(
                  child: pw.ClipRRect(
                    horizontalRadius: 24,
                    verticalRadius: 24,
                    child: pw.Container(
                      color: PdfColors.white,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          pw.Container(
                            height: 132,
                            color: PdfColor.fromInt(0xFFC8D8CF),
                            child: pw.Stack(
                              children: [
                                if (coverBytes != null)
                                  pw.Positioned.fill(
                                    child: pw.Image(
                                      pw.MemoryImage(coverBytes),
                                      fit: pw.BoxFit.cover,
                                    ),
                                  ),
                                pw.Positioned.fill(
                                  child: pw.Container(
                                    decoration: pw.BoxDecoration(
                                      gradient: pw.LinearGradient(
                                        begin: pw.Alignment.topCenter,
                                        end: pw.Alignment.bottomCenter,
                                        colors: [
                                          PdfColor.fromInt(0x33000000),
                                          PdfColor.fromInt(0x99000000),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                pw.Positioned(
                                  left: 18,
                                  right: 18,
                                  bottom: 14,
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        ticket.eventTitle ?? 'Event',
                                        style: pw.TextStyle(
                                          color: PdfColors.white,
                                          fontSize: 15,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                      if (meta.isNotEmpty)
                                        pw.Padding(
                                          padding:
                                              const pw.EdgeInsets.only(top: 3),
                                          child: pw.Text(
                                            meta,
                                            style: pw.TextStyle(
                                              color: PdfColor.fromInt(
                                                  0xB3FFFFFF),
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.Padding(
                            padding:
                                const pw.EdgeInsets.fromLTRB(20, 16, 20, 10),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Expanded(
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        'Ticket Holder',
                                        style: pw.TextStyle(
                                          color: soft,
                                          fontSize: 9,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                      pw.SizedBox(height: 3),
                                      pw.Text(
                                        ticket.holderName ?? '—',
                                        style: pw.TextStyle(
                                          fontSize: 15,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                                  children: [
                                    pw.Text(
                                      'Type',
                                      style: pw.TextStyle(
                                        color: soft,
                                        fontSize: 9,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                    pw.SizedBox(height: 3),
                                    pw.Text(
                                      ticket.ticketTypeName,
                                      style: pw.TextStyle(
                                        fontSize: 13,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          pw.Center(
                            child: pw.Text(
                              '${ticket.ticketCode} · ADMIT ONE',
                              style: pw.TextStyle(
                                color: brand,
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                letterSpacing: 1.8,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            child: pw.Row(
                              children: [
                                pw.Container(
                                  width: 22,
                                  height: 22,
                                  decoration: pw.BoxDecoration(
                                    color: brandDark,
                                    shape: pw.BoxShape.circle,
                                  ),
                                ),
                                pw.Expanded(
                                  child: pw.Padding(
                                    padding: const pw.EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: pw.Row(
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment.spaceBetween,
                                      children: List.generate(
                                        28,
                                        (_) => pw.Container(
                                          width: 4,
                                          height: 2,
                                          color: dash,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                pw.Container(
                                  width: 22,
                                  height: 22,
                                  decoration: pw.BoxDecoration(
                                    color: brandDark,
                                    shape: pw.BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Column(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Container(
                                  padding: const pw.EdgeInsets.all(10),
                                  decoration: pw.BoxDecoration(
                                    color: PdfColors.white,
                                    border: pw.Border.all(
                                      color: PdfColor.fromInt(0xFFF1F5F9),
                                    ),
                                    borderRadius: pw.BorderRadius.circular(12),
                                  ),
                                  child: pw.Image(
                                    pw.MemoryImage(qrBytes),
                                    width: 168,
                                    height: 168,
                                  ),
                                ),
                                pw.SizedBox(height: 12),
                                pw.Text(
                                  statusLine,
                                  style: pw.TextStyle(
                                    color: soft,
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                if (ticket.orderNumber != null) ...[
                                  pw.SizedBox(height: 6),
                                  pw.Text(
                                    'Order ${ticket.orderNumber}',
                                    style: pw.TextStyle(
                                      color: soft,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 14),
                pw.Text(
                  'Present this ticket at the venue entrance. Do not share your QR with others.',
                  style: pw.TextStyle(
                    color: PdfColor.fromInt(0xB3FFFFFF),
                    fontSize: 9,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  PdfColor _pdfColor(String? hex, int fallback) {
    if (hex == null || hex.isEmpty) return PdfColor.fromInt(fallback);
    var h = hex.replaceFirst('#', '');
    if (h.length == 6) h = 'FF$h';
    final parsed = int.tryParse(h, radix: 16);
    return PdfColor.fromInt(parsed ?? fallback);
  }

  Future<Uint8List> _qrPngBytes(String data) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF0F1A2E),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF0F1A2E),
      ),
    );
    final imageData =
        await painter.toImageData(512, format: ui.ImageByteFormat.png);
    if (imageData == null) {
      throw Exception('Could not generate QR image');
    }
    return imageData.buffer.asUint8List();
  }

  Future<Uint8List?> _coverBytes(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        return null;
      }
      return response.bodyBytes;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _logoBytes() async {
    try {
      final data = await rootBundle.load('assets/images/ekaadh_logo_white.png');
      return data.buffer.asUint8List();
    } catch (_) {
      try {
        final data = await rootBundle.load('assets/images/ekaadh_logo.png');
        return data.buffer.asUint8List();
      } catch (_) {
        return null;
      }
    }
  }
}
