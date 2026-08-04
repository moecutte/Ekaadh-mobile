import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/models/order_model.dart';
import 'package:ekaadh_mobile/models/ticket_model.dart';
import 'package:ekaadh_mobile/screens/ticket_view_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EkaadhColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(color: EkaadhColors.brand, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 12),
                  const Text('Payment Successful!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  Text('Order ${order.orderNumber}', style: const TextStyle(color: EkaadhColors.soft, fontSize: 13)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: order.eventCover != null
                                ? Image.network(order.eventCover!, fit: BoxFit.cover)
                                : const ColoredBox(color: Color(0xFFE2E8E4)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(order.eventTitle ?? 'Event', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                              Text('${order.eventDateLabel ?? ''} · ${order.eventTimeLabel ?? ''}', style: const TextStyle(color: EkaadhColors.soft, fontSize: 12)),
                              Text(order.venue ?? '', style: const TextStyle(color: EkaadhColors.soft, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(0, 18, 0, 10),
                    child: Text('YOUR TICKETS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: EkaadhColors.soft, letterSpacing: 1)),
                  ),
                  ...order.tickets.map((t) {
                    return InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TicketViewScreen(ticket: _toTicketModel(t)),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 2))],
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(t.holderName ?? order.buyerName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                                        Text(t.ticketTypeName, style: const TextStyle(color: EkaadhColors.soft, fontSize: 12)),
                                        Text(t.ticketCode, style: const TextStyle(color: EkaadhColors.brand, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(color: EkaadhColors.brandLight, borderRadius: BorderRadius.circular(999)),
                                    child: const Text('Valid', style: TextStyle(color: EkaadhColors.brand, fontWeight: FontWeight.w800, fontSize: 11)),
                                  ),
                                ],
                              ),
                            ),
                            QrImageView(data: t.qrPayload, size: 130, backgroundColor: Colors.white),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 14, top: 4),
                              child: Text('Tap for full ticket', style: TextStyle(color: EkaadhColors.soft, fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: EkaadhColors.brandLight, borderRadius: BorderRadius.circular(18)),
                    child: const Text(
                      'Tickets also sent via Email & SMS (WhatsApp when approved). Find them anytime under My Tickets.',
                      style: TextStyle(color: EkaadhColors.muted, fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EkaadhColors.brand,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  child: const Text('View My Tickets'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TicketModel _toTicketModel(OrderTicket t) {
    return TicketModel(
      id: t.id,
      ticketCode: t.ticketCode,
      holderName: t.holderName ?? order.buyerName,
      ticketTypeName: t.ticketTypeName,
      status: t.status,
      qrPayload: t.qrPayload,
      publicUrl: t.publicUrl,
      isUpcoming: true,
      eventTitle: order.eventTitle,
      eventCover: order.eventCover,
      eventDateLabel: order.eventDateLabel,
      eventTimeLabel: order.eventTimeLabel,
      venue: order.venue,
      orderNumber: order.orderNumber,
    );
  }
}
