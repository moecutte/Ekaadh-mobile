import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/locale_scope.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/models/event_model.dart';
import 'package:ekaadh_mobile/models/order_model.dart';
import 'package:ekaadh_mobile/screens/order_confirmation_screen.dart';
import 'package:ekaadh_mobile/screens/otp_verification_screen.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/services/checkout_service.dart';
import 'package:ekaadh_mobile/services/otp_service.dart';
import 'package:ekaadh_mobile/widgets/design_network_image.dart';
import 'package:ekaadh_mobile/widgets/operator_logos.dart';
import 'package:ekaadh_mobile/widgets/phone_number_field.dart';
import 'package:ekaadh_mobile/widgets/wallet_pin_dialog.dart';
import 'package:ekaadh_mobile/core/user_facing_error.dart';
import 'package:ekaadh_mobile/widgets/ekaadh_toast.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.event,
    this.quantities,
    this.auth,
    this.initialStep = 1,
  });

  final EventModel event;
  /// Optional pre-selected quantities. When null, starts at 0 for each type.
  final Map<int, int>? quantities;
  final AuthService? auth;
  final int initialStep;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late int _step;
  late Map<int, int> _qty;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  String _pay = 'waafipay';
  bool _loading = false;
  bool _forceFail = false;
  String? _error;
  bool _signedIn = false;
  String? _otpToken;
  String? _otpPhone;

  List<String> _stepLabels(BuildContext context) {
    final l10n = LocaleScope.of(context);
    if (_isFree) {
      return [l10n.t('step_select_tickets'), l10n.t('step_your_details')];
    }
    return [l10n.t('step_select_tickets'), l10n.t('step_your_details'), l10n.t('step_payment')];
  }

  bool get _isFree => widget.event.isFree;
  int get _paymentStep => 3;
  int get _maxStep => _isFree ? 2 : _paymentStep;

  @override
  void initState() {
    super.initState();
    final user = widget.auth?.user;
    if (user != null) {
      _signedIn = true;
      _name.text = user.name;
      _email.text = user.email.contains('@ekaadh.local') ? '' : user.email;
      _phone.text = PhoneNumberField.localPart(user.phone);
    }
    _step = widget.initialStep.clamp(1, _maxStep);
    _qty = {
      for (final t in widget.event.ticketTypes)
        t.id: widget.quantities?[t.id] ?? 0,
    };
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  int get _ticketCount => _qty.values.fold(0, (a, b) => a + b);

  double get _subtotal {
    double sum = 0;
    for (final t in widget.event.ticketTypes) {
      sum += t.price * (_qty[t.id] ?? 0);
    }
    return sum;
  }

  double get _serviceFee => _isFree ? 0 : widget.event.serviceFee;

  double get _total => _ticketCount > 0 ? _subtotal + _serviceFee : 0;

  Map<int, int> get _selectedQty =>
      Map.from(_qty)..removeWhere((_, v) => v <= 0);

  void _goStep(int n) {
    if (n == 2 && _ticketCount < 1) return;
    setState(() {
      _step = n;
      _error = null;
    });
  }

  void _onBack() {
    if (_step > 1) {
      _goStep(_step - 1);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _continueFromDetails() async {
    final l10n = LocaleScope.of(context);
    if (_name.text.trim().isEmpty || !PhoneNumberField.hasLocalNumber(_phone.text)) {
      setState(() => _error = l10n.t('name_phone_required'));
      return;
    }
    if (_signedIn) {
      if (_isFree) {
        await _payNow();
        return;
      }
      _goStep(3);
      return;
    }
    await _confirmPhoneThenPay();
  }

  Future<void> _confirmPhoneThenPay() async {
    final l10n = LocaleScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sent = await OtpService().send(
        phone: PhoneNumberField.fullNumber(_phone.text),
        purpose: OtpService.purposeCheckout,
      );
      if (!mounted) return;
      setState(() => _loading = false);

      final verified = await Navigator.of(context).push<OtpResult>(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            phone: PhoneNumberField.fullNumber(_phone.text),
            purpose: OtpService.purposeCheckout,
            alreadySent: true,
            debugHint: sent.debugCode != null
                ? '${l10n.t('testing_code')}: ${sent.debugCode}'
                : null,
          ),
        ),
      );
      if (!mounted || verified?.otpToken == null) return;

      setState(() {
        _otpToken = verified!.otpToken;
        _otpPhone = PhoneNumberField.fullNumber(_phone.text);
        _error = null;
      });
      if (_isFree) {
        await _payNow();
        return;
      }
      setState(() => _step = _paymentStep);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = UserFacingError.message(e, t: LocaleScope.of(context).t);
      });
    }
  }

  Future<void> _payNow() async {
    final l10n = LocaleScope.of(context);
    if (widget.event.isExpired) {
      setState(() => _error = l10n.t('event_expired_hint'));
      return;
    }
    if (_name.text.trim().isEmpty || !PhoneNumberField.hasLocalNumber(_phone.text)) {
      setState(() => _error = l10n.t('name_phone_required'));
      return;
    }
    if (_ticketCount < 1) {
      setState(() => _error = l10n.t('select_at_least_1'));
      return;
    }
    if (!_signedIn && (_otpToken == null || _otpToken!.isEmpty)) {
      await _confirmPhoneThenPay();
      return;
    }

    String? walletPin;
    if (!_isFree && widget.event.paymentSandbox) {
      walletPin = await showWalletPinDialog(context);
      if (!mounted || walletPin == null || walletPin.isEmpty) return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ProcessingDialog(),
    );

    try {
      final items = _selectedQty.entries
          .map((e) => {'ticket_type_id': e.key, 'quantity': e.value})
          .toList();

      final order = await CheckoutService().checkout(
        eventId: widget.event.id,
        buyerName: _name.text.trim(),
        buyerPhone: PhoneNumberField.fullNumber(_phone.text),
        buyerEmail: _email.text.trim().isEmpty ? null : _email.text.trim(),
        paymentMethod: _pay,
        items: items,
        forceFail: _forceFail,
        token: widget.auth?.token,
        otpToken: _signedIn ? null : _otpToken,
        otpPhone: _signedIn ? null : _otpPhone,
        walletPin: walletPin,
        locale: LocaleScope.of(context).code,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      if (order.status == 'pending') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => PaymentPendingScreen(
              order: order,
              buyerPhone: PhoneNumberField.fullNumber(_phone.text),
            ),
          ),
          (route) => route.isFirst,
        );
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => OrderConfirmationScreen(order: order)),
        (route) => route.isFirst,
      );
    } on CheckoutFailedException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() => _loading = false);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentFailedScreen(message: e.message, order: e.order),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() {
        _loading = false;
        _error = UserFacingError.message(e, t: LocaleScope.of(context).t);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    if (widget.event.isExpired) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(l10n.t('expired'), style: const TextStyle(fontWeight: FontWeight.w900)),
          leading: IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.event.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
              const SizedBox(height: 8),
              Text(widget.event.eventDateLabel ?? '', style: const TextStyle(color: EkaadhColors.muted)),
              const SizedBox(height: 16),
              Text(l10n.t('event_expired_hint'), textAlign: TextAlign.center, style: const TextStyle(color: EkaadhColors.muted, height: 1.4)),
            ],
          ),
        ),
      );
    }
    final labels = _stepLabels(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          labels[_step - 1],
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _onBack,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: _StepIndicator(step: _step, labels: labels),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                if (_step == 1) _buildTicketsStep(),
                if (_step == 2) _buildDetailsStep(),
                if (_step == _paymentStep) _buildPaymentStep(),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: EkaadhColors.danger)),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(child: _buildBottomBar()),
    );
  }

  Widget _buildBottomBar() {
    final l10n = LocaleScope.of(context);
    if (_step == 1) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: ElevatedButton(
          onPressed: _ticketCount > 0 ? () => _goStep(2) : null,
          style: _primaryButtonStyle(enabled: _ticketCount > 0),
          child: Text(
            _ticketCount > 0
                ? '${l10n.t('continue_to_details')} · \$${_total.toStringAsFixed(0)}'
                : l10n.t('select_at_least_1'),
          ),
        ),
      );
    }

    if (_step == 2) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _goStep(1),
                style: _outlineButtonStyle(),
                child: Text(l10n.t('back')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _loading ? null : _continueFromDetails,
                style: _primaryButtonStyle(enabled: !_loading),
                child: Text(
                  _signedIn
                      ? (_isFree ? l10n.t('claim_free_tickets') : l10n.t('continue_to_payment'))
                      : l10n.t('continue'),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: _loading ? null : _payNow,
            style: _primaryButtonStyle(enabled: !_loading),
            child: Text(
              '${l10n.t('pay_with')} \$${_total.toStringAsFixed(0)} ${l10n.t('with_method')} WaafiPay'.replaceAll(RegExp(r'\s+'), ' ').trim(),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => _goStep(2),
            child: Text(
              l10n.t('back'),
              style: const TextStyle(color: EkaadhColors.muted, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _primaryButtonStyle({required bool enabled}) {
    return ElevatedButton.styleFrom(
      backgroundColor: enabled ? EkaadhColors.brand : const Color(0xFFE2E8E4),
      foregroundColor: Colors.white,
      disabledBackgroundColor: const Color(0xFFE2E8E4),
      disabledForegroundColor: EkaadhColors.soft,
      minimumSize: const Size(double.infinity, 54),
      padding: const EdgeInsets.symmetric(vertical: 17),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
    );
  }

  ButtonStyle _outlineButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: EkaadhColors.dark,
      minimumSize: const Size(0, 54),
      padding: const EdgeInsets.symmetric(vertical: 17),
      side: const BorderSide(color: Color(0xFFE2E8E4)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
    );
  }

  Widget _buildTicketsStep() {
    final l10n = LocaleScope.of(context);
    final event = widget.event;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.t('order_summary'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF0F4F2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: event.coverImage != null
                          ? DesignNetworkImage(url: event.coverImage)
                          : const ColoredBox(color: Color(0xFFE2E8E4)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(
                          '${event.eventDateLabel ?? ''} · ${event.eventTimeLabel ?? ''}',
                          style: const TextStyle(color: EkaadhColors.soft, fontSize: 12),
                        ),
                        if (event.venue != null && event.venue!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(event.venue!, style: const TextStyle(color: EkaadhColors.soft, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: Color(0xFFF0F4F2)),
              ),
              ...event.ticketTypes.map((t) {
                final q = _qty[t.id] ?? 0;
                final max = t.maxPerOrder < t.remaining ? t.maxPerOrder : t.remaining;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            Text(
                              '\$${t.price.toStringAsFixed(0)} · ${t.remaining} ${l10n.t('tickets_left')}',
                              style: const TextStyle(color: EkaadhColors.soft, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      _RoundBtn(
                        icon: Icons.remove,
                        onTap: q > 0 ? () => setState(() => _qty[t.id] = q - 1) : null,
                        outlined: true,
                        active: q > 0,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(
                          width: 24,
                          child: Text(
                            '$q',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ),
                      ),
                      _RoundBtn(
                        icon: Icons.add,
                        onTap: q < max ? () => setState(() => _qty[t.id] = q + 1) : null,
                        filled: true,
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 1, color: Color(0xFFF0F4F2)),
              const SizedBox(height: 14),
              if (_ticketCount > 0 && !_isFree)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.t('service_fee'), style: const TextStyle(color: EkaadhColors.muted, fontSize: 13)),
                      Text('\$${_serviceFee.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.t('total'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  Text(
                    '\$${_total.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: EkaadhColors.brand),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    final l10n = LocaleScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.t('your_details'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        if (_signedIn)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: EkaadhColors.brandLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EkaadhColors.brand.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.person_outline, color: EkaadhColors.brand, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${l10n.t('signed_in_as')} ${_name.text}. ${l10n.t('signed_in_payment_note')}',
                    style: const TextStyle(fontSize: 13, height: 1.45, color: EkaadhColors.dark),
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              l10n.t('guest_checkout_note'),
              style: const TextStyle(fontSize: 13, height: 1.45, color: EkaadhColors.muted),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF0F4F2)),
          ),
          child: Column(
            children: [
              _field(l10n.t('full_name'), _name, 'e.g. Faadumo Hassan', readOnly: _signedIn),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: '${l10n.t('phone_number')} ',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EkaadhColors.muted),
                        children: [
                          TextSpan(
                            text: l10n.t('phone_required_payment'),
                            style: const TextStyle(color: EkaadhColors.brand, fontWeight: FontWeight.w600, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    PhoneNumberField(
                      controller: _phone,
                      borderRadius: 16,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      readOnly: _signedIn,
                    ),
                  ],
                ),
              ),
              _field(
                l10n.t('email_optional'),
                _email,
                'yourname@example.com',
                keyboard: TextInputType.emailAddress,
                readOnly: _signedIn,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    final l10n = LocaleScope.of(context);
    const methodLabel = 'WaafiPay';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.t('payment'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(
          l10n.t('choose_payment'),
          style: const TextStyle(fontSize: 13, color: EkaadhColors.muted),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _PayCard(
                id: 'waafipay',
                label: 'WaafiPay',
                sub: l10n.t('mobile_money_waafipay'),
                selected: true,
                leading: const OperatorLogos(height: 22),
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PayCard(
                id: 'edahab',
                label: 'eDahab',
                sub: l10n.t('mobile_money_edahab'),
                selected: false,
                leading: Image.asset(
                  'assets/images/somtel-logo.png',
                  height: 28,
                  fit: BoxFit.contain,
                ),
                onTap: () {
                  EkaadhToast.error(context, message: l10n.t('edahab_unavailable'));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF0F4F2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _signedIn
                      ? '${l10n.t('charge_on_account_phone')} $methodLabel ${l10n.t('on_your_account_phone')}'
                      : '${l10n.t('enter_number_to_charge')} $methodLabel ${l10n.t('number_to_charge')}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                PhoneNumberField(
                  controller: _phone,
                  borderRadius: 16,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  readOnly: _signedIn && !widget.event.paymentSandbox,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: EkaadhColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.t('total_to_charge'), style: const TextStyle(fontWeight: FontWeight.w600, color: EkaadhColors.muted, fontSize: 13)),
                      Text(
                        '\$${_total.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                      ),
                    ],
                  ),
                ),
                if (kDebugMode)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.t('simulate_fail'),
                      style: const TextStyle(fontSize: 13, color: EkaadhColors.muted),
                    ),
                    value: _forceFail,
                    activeThumbColor: EkaadhColors.brand,
                    onChanged: (v) => setState(() => _forceFail = v),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 14, color: EkaadhColors.brand),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.t('encryption_note'),
                        style: const TextStyle(fontSize: 11, color: EkaadhColors.muted, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController c,
    String hint, {
    TextInputType? keyboard,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EkaadhColors.muted)),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            keyboardType: keyboard,
            readOnly: readOnly,
            decoration: EkaadhFields.decoration(hintText: hint).copyWith(
              fillColor: readOnly ? const Color(0xFFF8FAFC) : EkaadhColors.surface,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step, required this.labels});

  final int step;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: i < step ? EkaadhColors.brand : const Color(0xFFE2E8E4),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i + 1 <= step ? EkaadhColors.brand : const Color(0xFFF1F5F9),
                  boxShadow: i + 1 == step
                      ? [
                          BoxShadow(
                            color: EkaadhColors.brand.withValues(alpha: 0.28),
                            blurRadius: 0,
                            spreadRadius: 4,
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: i + 1 < step
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: i + 1 <= step ? Colors.white : EkaadhColors.muted,
                        ),
                      ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: Text(
                  labels[i],
                  textAlign: i == 0
                      ? TextAlign.left
                      : i == labels.length - 1
                          ? TextAlign.right
                          : TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: i + 1 == step ? EkaadhColors.brand : EkaadhColors.soft,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({
    required this.icon,
    this.onTap,
    this.outlined = false,
    this.filled = false,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool outlined;
  final bool filled;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? EkaadhColors.brand : Colors.transparent,
          border: outlined
              ? Border.all(color: active ? EkaadhColors.brand : const Color(0xFFE8EDE9), width: 2)
              : null,
        ),
        child: Icon(
          icon,
          size: 14,
          color: filled ? Colors.white : (active ? EkaadhColors.brand : EkaadhColors.soft),
        ),
      ),
    );
  }
}

class _PayCard extends StatelessWidget {
  const _PayCard({
    required this.id,
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
    required this.leading,
  });

  final String id, label, sub;
  final bool selected;
  final VoidCallback onTap;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected ? EkaadhColors.brandLight : Colors.white,
          border: Border.all(
            color: selected ? EkaadhColors.brand : const Color(0xFFF0F4F2),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading,
                const SizedBox(height: 10),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(color: EkaadhColors.soft, fontSize: 11)),
              ],
            ),
            if (selected)
              const Positioned(
                top: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: EkaadhColors.brand,
                  child: Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProcessingDialog extends StatelessWidget {
  const _ProcessingDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    return Dialog(
      backgroundColor: EkaadhColors.brandLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(color: EkaadhColors.brand, strokeWidth: 3),
            ),
            const SizedBox(height: 20),
            Text(l10n.t('processing_payment'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 6),
            Text(l10n.t('please_wait'), style: const TextStyle(color: EkaadhColors.muted)),
          ],
        ),
      ),
    );
  }
}

class PaymentFailedScreen extends StatelessWidget {
  const PaymentFailedScreen({super.key, required this.message, this.order});

  final String message;
  final OrderModel? order;

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(color: Color(0xFFFEE2E2), shape: BoxShape.circle),
                child: const Icon(Icons.cancel, size: 56, color: EkaadhColors.danger),
              ),
              const SizedBox(height: 24),
              Text(l10n.t('payment_failed'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text(
                UserFacingError.paymentMessage(message, t: l10n.t),
                textAlign: TextAlign.center,
                style: const TextStyle(color: EkaadhColors.dark, fontWeight: FontWeight.w600, height: 1.65),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.t('payment_failed_hint'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: EkaadhColors.muted, height: 1.5),
              ),
              if (order != null) ...[
                const SizedBox(height: 8),
                Text(order!.orderNumber, style: const TextStyle(fontWeight: FontWeight.w700, color: EkaadhColors.soft)),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EkaadhColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  child: Text(l10n.t('try_again')),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: Text(l10n.t('back_to_home'), style: const TextStyle(color: EkaadhColors.soft, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentPendingScreen extends StatefulWidget {
  const PaymentPendingScreen({
    super.key,
    required this.order,
    required this.buyerPhone,
  });

  final OrderModel order;
  final String buyerPhone;

  @override
  State<PaymentPendingScreen> createState() => _PaymentPendingScreenState();
}

class _PaymentPendingScreenState extends State<PaymentPendingScreen> {
  late OrderModel _order;
  bool _polling = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _poll();
  }

  Future<void> _poll() async {
    for (var i = 0; i < 24 && mounted; i++) {
      await Future<void>.delayed(const Duration(seconds: 5));
      if (!mounted) return;
      try {
        final fresh = await CheckoutService().fetchOrder(
          _order.orderNumber,
          phone: widget.buyerPhone,
        );
        if (!mounted) return;
        if (fresh.status == 'paid') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => OrderConfirmationScreen(order: fresh)),
            (route) => route.isFirst,
          );
          return;
        }
        if (fresh.status == 'failed') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => PaymentFailedScreen(
                message: 'Payment was not confirmed. Please try again.',
                order: fresh,
              ),
            ),
          );
          return;
        }
        setState(() => _order = fresh);
      } catch (e) {
        if (!mounted) return;
        setState(() => _error = UserFacingError.message(e, t: LocaleScope.of(context).t));
      }
    }
    if (mounted) setState(() => _polling = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(color: EkaadhColors.brand),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.t('payment_confirming'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.t('payment_confirming_hint'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: EkaadhColors.muted, height: 1.5),
              ),
              const SizedBox(height: 8),
              Text(
                _order.orderNumber,
                style: const TextStyle(fontWeight: FontWeight.w700, color: EkaadhColors.soft),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: EkaadhColors.danger)),
              ],
              if (!_polling) ...[
                const SizedBox(height: 24),
                Text(
                  l10n.t('payment_confirming_later'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: EkaadhColors.muted, height: 1.5),
                ),
              ],
              const SizedBox(height: 28),
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: Text(l10n.t('back_to_home'), style: const TextStyle(color: EkaadhColors.soft, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
