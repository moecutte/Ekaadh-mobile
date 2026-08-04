import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/models/ticket_model.dart';
import 'package:ekaadh_mobile/services/ticket_pdf_service.dart';
import 'package:ekaadh_mobile/widgets/invitation_overlay_preview.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TicketViewScreen extends StatefulWidget {
  const TicketViewScreen({super.key, required this.ticket});

  final TicketModel ticket;

  @override
  State<TicketViewScreen> createState() => _TicketViewScreenState();
}

class _TicketViewScreenState extends State<TicketViewScreen> {
  bool _downloading = false;

  TicketModel get ticket => widget.ticket;

  Future<void> _downloadPdf() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      await TicketPdfService().download(ticket);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket PDF ready')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: EkaadhColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Map<String, String> get _overlayValues {
    final design = ticket.invitationDesign!;
    final values = Map<String, String>.from(design.fieldValues);
    final holder = ticket.holderName?.trim();
    if (holder != null && holder.isNotEmpty) {
      values['guest_name'] = holder;
    }
    return values;
  }

  @override
  Widget build(BuildContext context) {
    final thumb = ticket.displayImage;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: EkaadhColors.dark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          ticket.isOverlayInvite ? 'Invitation' : 'Ticket',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        children: [
          if (ticket.isOverlayInvite)
            Center(
              child: InvitationOverlayPreview(
                design: ticket.invitationDesign!.toDesignOption(),
                fieldValues: _overlayValues,
                maxWidth: 420,
                qrPayload: ticket.qrPayload,
                showQrChrome: false,
              ),
            )
          else
            _ClassicTicketCard(ticket: ticket),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEEF0F4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (thumb != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 48,
                            height: 64,
                            child: Image.network(thumb, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ticket.eventTitle ?? 'Event',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      ticket.eventTitle ?? 'Event',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        height: 1.25,
                      ),
                    ),
                  ),
                Text(
                  [
                    if (ticket.eventDateLabel != null) ticket.eventDateLabel!,
                    if (ticket.eventTimeLabel != null) ticket.eventTimeLabel!,
                    if (ticket.venue != null) ticket.venue!,
                  ].join(' · '),
                  style: const TextStyle(
                    color: EkaadhColors.muted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE8EAF0)),
                      ),
                      child: Text(
                        ticket.ticketCode,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w800,
                          color: EkaadhColors.brand,
                          letterSpacing: 1,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: ticket.status == 'valid'
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        ticket.status == 'valid' ? 'Valid' : ticket.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: ticket.status == 'valid'
                              ? const Color(0xFF047857)
                              : EkaadhColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _downloading ? null : _downloadPdf,
              icon: _downloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download_rounded, size: 18),
              label: Text(_downloading ? 'Preparing PDF…' : 'Download PDF'),
              style: FilledButton.styleFrom(
                backgroundColor: EkaadhColors.brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                textStyle:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassicTicketCard extends StatelessWidget {
  const _ClassicTicketCard({required this.ticket});

  final TicketModel ticket;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 40, offset: Offset(0, 16))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 150,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (ticket.displayImage != null)
                  Image.network(ticket.displayImage!, fit: BoxFit.cover)
                else
                  const ColoredBox(color: Color(0xFFE8E8EE)),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x33000000), Color(0x99000000)],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ticket.eventTitle ?? 'Event',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16)),
                      Text(
                        '${ticket.eventDateLabel ?? ''} · ${ticket.eventTimeLabel ?? ''} · ${ticket.venue ?? ''}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ticket Holder',
                          style: TextStyle(
                              fontSize: 11,
                              color: EkaadhColors.soft,
                              fontWeight: FontWeight.w600)),
                      Text(ticket.holderName ?? '—',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Type',
                        style: TextStyle(
                            fontSize: 11,
                            color: EkaadhColors.soft,
                            fontWeight: FontWeight.w600)),
                    Text(ticket.ticketTypeName,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${ticket.ticketCode} · ADMIT ONE',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
              color: EkaadhColors.brand,
              letterSpacing: 2,
              fontSize: 12,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                        color: EkaadhColors.brandDark, shape: BoxShape.circle)),
                const Expanded(child: DashedDivider()),
                Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                        color: EkaadhColors.brandDark, shape: BoxShape.circle)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                QrImageView(
                  data: ticket.qrPayload,
                  size: 210,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  'Scan at entry · ${ticket.status == 'valid' ? 'Valid once only' : ticket.status}',
                  style: const TextStyle(
                      fontSize: 11,
                      color: EkaadhColors.soft,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxes = (constraints.maxWidth / 8).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            boxes,
            (_) =>
                Container(width: 4, height: 2, color: const Color(0xFFE8EDE9)),
          ),
        );
      },
    );
  }
}
