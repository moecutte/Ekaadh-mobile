import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/locale_scope.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/models/order_model.dart';
import 'package:ekaadh_mobile/models/private_event_model.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/services/private_event_service.dart';
import 'package:ekaadh_mobile/screens/private_event_detail_screen.dart';

class PrivateEventPayScreen extends StatefulWidget {
  const PrivateEventPayScreen({
    super.key,
    required this.auth,
    required this.eventId,
    this.initialOrder,
  });

  final AuthService auth;
  final int eventId;
  final OrderModel? initialOrder;

  @override
  State<PrivateEventPayScreen> createState() => _PrivateEventPayScreenState();
}

class _PrivateEventPayScreenState extends State<PrivateEventPayScreen> {
  late final PrivateEventService _service;
  PrivateEventModel? _event;
  OrderModel? _order;
  String _method = 'zaad';
  bool _loading = true;
  bool _paying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = PrivateEventService(token: widget.auth.token!);
    _order = widget.initialOrder;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final event = await _service.show(widget.eventId);
      if (!mounted) return;
      if (event.isPaid && event.pendingOrder == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PrivateEventDetailScreen(
              auth: widget.auth,
              eventId: event.id,
            ),
          ),
        );
        return;
      }
      OrderModel? order = _order;
      if (event.pendingOrder != null) {
        order = OrderModel.fromJson(event.pendingOrder!);
      }
      setState(() {
        _event = event;
        _order = order;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _pay() async {
    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      final result = await _service.pay(
        eventId: widget.eventId,
        paymentMethod: _method,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleScope.of(context).t('payment_successful_short'))),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => PrivateEventDetailScreen(
            auth: widget.auth,
            eventId: result.event.id,
          ),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _paying = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    final order = _order;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.t('pay_for_tickets'), style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: EkaadhColors.dark,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: EkaadhColors.brand))
          : order == null
              ? Center(
                  child: Text(
                    _error ?? l10n.t('no_pending_payment'),
                    style: const TextStyle(color: EkaadhColors.danger),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_event != null)
                      Text(
                        _event!.title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          ...order.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.quantity} × ${item.ticketTypeName ?? l10n.t('ticket_singular')}',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Text(
                                    '\$${item.subtotal.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l10n.t('service_fee'), style: const TextStyle(color: EkaadhColors.muted)),
                              Text('\$${order.serviceFee.toStringAsFixed(2)}'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l10n.t('total'), style: const TextStyle(fontWeight: FontWeight.w900)),
                              Text(
                                '\$${order.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: EkaadhColors.brand,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${l10n.t('order_ref')} ${order.orderNumber}',
                            style: const TextStyle(fontSize: 11, color: EkaadhColors.soft),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t('payment').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF9CA3AF),
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _methodChip('zaad', 'Zaad')),
                              const SizedBox(width: 10),
                              Expanded(child: _methodChip('edahab', 'eDahab')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: EkaadhColors.danger)),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _paying ? null : _pay,
                        style: FilledButton.styleFrom(
                          backgroundColor: EkaadhColors.brand,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        child: _paying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text('${l10n.t('pay_with')} \$${order.totalAmount.toStringAsFixed(2)}'),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _methodChip(String value, String label) {
    final selected = _method == value;
    return InkWell(
      onTap: () => setState(() => _method = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? EkaadhColors.brandLight : EkaadhColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? EkaadhColors.brand : EkaadhColors.fieldBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: selected ? EkaadhColors.brand : EkaadhColors.dark,
          ),
        ),
      ),
    );
  }
}
