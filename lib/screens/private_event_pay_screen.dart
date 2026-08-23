import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/locale_scope.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/models/order_model.dart';
import 'package:ekaadh_mobile/models/private_event_model.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/services/private_event_service.dart';
import 'package:ekaadh_mobile/screens/private_event_detail_screen.dart';
import 'package:ekaadh_mobile/core/user_facing_error.dart';
import 'package:ekaadh_mobile/widgets/operator_logos.dart';
import 'package:ekaadh_mobile/widgets/phone_number_field.dart';
import 'package:ekaadh_mobile/widgets/wallet_pin_dialog.dart';
import 'package:ekaadh_mobile/widgets/ekaadh_toast.dart';
import 'package:ekaadh_mobile/widgets/invitation_html_preview.dart';

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
  String _method = 'waafipay';
  bool _loading = true;
  bool _paying = false;
  String? _error;
  bool _payFailed = false;
  String? _previewHtml;
  final TextEditingController _chargePhone = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service = PrivateEventService(token: widget.auth.token!);
    _order = widget.initialOrder;
    _load();
  }

  @override
  void dispose() {
    _chargePhone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _payFailed = false;
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
      final pending = event.pendingOrder;
      if (pending != null) {
        try {
          order = OrderModel.fromJson(pending);
        } catch (_) {}
      }
      setState(() {
        _event = event;
        _order = order;
        _loading = false;
      });
      _loadPreview();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = UserFacingError.message(e, t: LocaleScope.of(context).t);
        _loading = false;
      });
    }
  }

  Future<void> _loadPreview() async {
    final event = _event;
    final id = event?.design?.invitationDesignId;
    if (event == null || id == null) return;
    try {
      final html = await _service.previewHtml(
        invitationDesignId: id,
        fields: event.invitationFieldValues,
        eventDate: event.eventDate,
        eventTime: event.eventTime,
        venue: event.venue,
        envelope: true,
        autoOpen: true,
      );
      if (!mounted) return;
      setState(() => _previewHtml = html);
    } catch (_) {}
  }

  Future<void> _pay() async {
    final l10n = LocaleScope.of(context);
    final sandbox = _event?.paymentSandbox == true;
    String? chargePhone;
    if (sandbox) {
      if (!PhoneNumberField.hasLocalNumber(_chargePhone.text)) {
        setState(() => _error = l10n.t('sandbox_charge_phone_required'));
        return;
      }
      chargePhone = PhoneNumberField.fullNumber(_chargePhone.text);
    }

    String? walletPin;
    if (sandbox) {
      walletPin = await showWalletPinDialog(context);
      if (!mounted || walletPin == null || walletPin.isEmpty) return;
    }

    setState(() {
      _paying = true;
      _error = null;
      _payFailed = false;
    });
    try {
      final result = await _service.pay(
        eventId: widget.eventId,
        paymentMethod: _method,
        locale: LocaleScope.of(context).code,
        walletPin: walletPin,
        buyerPhone: chargePhone,
      );
      if (!mounted) return;
      await EkaadhToast.success(
        context,
        message: LocaleScope.of(context).t('payment_successful_short'),
      );
      if (!mounted) return;
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
        _payFailed = true;
        _error = UserFacingError.message(e, t: LocaleScope.of(context).t);
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
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error ?? l10n.t('no_pending_payment'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: EkaadhColors.danger, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _loading ? null : _load,
                          child: Text(l10n.t('try_again')),
                        ),
                      ],
                    ),
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
                    if (_event?.design != null) ...[
                      InvitationDesignPreview(
                        design: _event!.design!,
                        fieldValues: _event!.invitationFieldValues,
                        html: _previewHtml,
                        includeQr: false,
                      ),
                      const SizedBox(height: 16),
                    ],
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
                    if (_event?.paymentSandbox == true) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'WaafiPay sandbox',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.t('wallet_pin_test_hint'),
                              style: const TextStyle(fontSize: 12, color: EkaadhColors.muted, height: 1.4),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final wallet in _event!.testWallets)
                                  ActionChip(
                                    label: Text('${wallet.brand} · ${wallet.local}'),
                                    onPressed: () => setState(() => _chargePhone.text = wallet.local),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            PhoneNumberField(
                              controller: _chargePhone,
                              hint: '611111111',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
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
                              const Expanded(
                                child: _PrivatePayMethod(
                                  selected: true,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      OperatorLogos(height: 18),
                                      SizedBox(height: 8),
                                      Text('WaafiPay', style: TextStyle(fontWeight: FontWeight.w800)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _PrivatePayMethod(
                                  selected: false,
                                  onTap: () {
                                    EkaadhToast.error(context, message: l10n.t('edahab_unavailable'));
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Image.asset(
                                        'assets/images/somtel-logo.png',
                                        height: 22,
                                        fit: BoxFit.contain,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text('eDahab', style: TextStyle(fontWeight: FontWeight.w800)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: EkaadhColors.danger,
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                      ),
                      if (_payFailed) ...[
                        const SizedBox(height: 6),
                        Text(
                          l10n.t('payment_failed_hint'),
                          style: const TextStyle(color: EkaadhColors.muted, height: 1.4),
                        ),
                      ],
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
}

class _PrivatePayMethod extends StatelessWidget {
  const _PrivatePayMethod({
    required this.selected,
    required this.child,
    this.onTap,
  });

  final bool selected;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? EkaadhColors.brandLight : EkaadhColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? EkaadhColors.brand : EkaadhColors.fieldBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}
