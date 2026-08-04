import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/models/event_model.dart';
import 'package:ekaadh_mobile/models/order_model.dart';
import 'package:ekaadh_mobile/screens/order_confirmation_screen.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/services/checkout_service.dart';
import 'package:ekaadh_mobile/services/otp_service.dart';
import 'package:ekaadh_mobile/widgets/phone_number_field.dart';

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
  static const _serviceFee = 1.0;

  late int _step;
  late Map<int, int> _qty;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  String? _pay;
  bool _loading = false;
  bool _forceFail = false;
  String? _error;
  bool _signedIn = false;
  String? _otpToken;
  String? _otpHint;

  List<String> get _stepLabels => _signedIn
      ? const ['Select Tickets', 'Your Details', 'Payment']
      : const ['Select Tickets', 'Your Details', 'Confirm', 'Payment'];

  int get _paymentStep => _signedIn ? 3 : 4;
  int get _maxStep => _paymentStep;

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
    _otp.dispose();
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
    if (_name.text.trim().isEmpty || !PhoneNumberField.hasLocalNumber(_phone.text)) {
      setState(() => _error = 'Name and phone are required');
      return;
    }
    if (_signedIn) {
      _goStep(3);
      return;
    }
    await _sendCheckoutOtp(thenGoToConfirm: true);
  }

  Future<void> _sendCheckoutOtp({bool thenGoToConfirm = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await OtpService().send(
        phone: PhoneNumberField.fullNumber(_phone.text),
        purpose: OtpService.purposeCheckout,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _otpHint = result.debugCode != null
            ? 'Testing code: ${result.debugCode}'
            : result.message;
        _otpToken = null;
        if (thenGoToConfirm) _step = 3;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _verifyCheckoutOtp() async {
    if (_otp.text.trim().isEmpty) {
      setState(() => _error = 'Enter the confirmation code');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await OtpService().verify(
        phone: PhoneNumberField.fullNumber(_phone.text),
        purpose: OtpService.purposeCheckout,
        otp: _otp.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _otpToken = result.otpToken;
        _step = 4;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _payNow() async {
    if (_pay == null) {
      setState(() => _error = 'Choose Zaad or eDahab');
      return;
    }
    if (_name.text.trim().isEmpty || !PhoneNumberField.hasLocalNumber(_phone.text)) {
      setState(() => _error = 'Name and phone are required');
      return;
    }
    if (_ticketCount < 1) {
      setState(() => _error = 'Select at least 1 ticket');
      return;
    }
    if (!_signedIn && (_otpToken == null || _otpToken!.isEmpty)) {
      setState(() {
        _error = 'Confirm your phone number first';
        _step = 3;
      });
      return;
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
        paymentMethod: _pay!,
        items: items,
        forceFail: _forceFail,
        token: widget.auth?.token,
        otpToken: _signedIn ? null : _otpToken,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
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
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _stepLabels[_step - 1],
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
            child: _StepIndicator(step: _step, labels: _stepLabels),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                if (_step == 1) _buildTicketsStep(),
                if (_step == 2) _buildDetailsStep(),
                if (_step == 3 && !_signedIn) _buildOtpStep(),
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
    if (_step == 1) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: ElevatedButton(
          onPressed: _ticketCount > 0 ? () => _goStep(2) : null,
          style: _primaryButtonStyle(enabled: _ticketCount > 0),
          child: Text(
            _ticketCount > 0
                ? 'Continue to Your Details · \$${_total.toStringAsFixed(0)}'
                : 'Select at least 1 ticket',
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
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _loading ? null : _continueFromDetails,
                style: _primaryButtonStyle(enabled: !_loading),
                child: Text(_signedIn ? 'Continue to Payment' : 'Continue'),
              ),
            ),
          ],
        ),
      );
    }

    if (_step == 3 && !_signedIn) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _loading ? null : _verifyCheckoutOtp,
              style: _primaryButtonStyle(enabled: !_loading),
              child: const Text('Confirm & continue to payment'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _loading ? null : () => _sendCheckoutOtp(),
              child: const Text(
                'Resend code',
                style: TextStyle(color: EkaadhColors.brand, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: () => _goStep(2),
              child: const Text(
                'Back to Details',
                style: TextStyle(color: EkaadhColors.muted, fontWeight: FontWeight.w700),
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
            onPressed: _loading || _pay == null ? null : _payNow,
            style: _primaryButtonStyle(enabled: _pay != null && !_loading),
            child: Text(
              _pay == null
                  ? 'Choose a payment method'
                  : 'Pay \$${_total.toStringAsFixed(0)} with ${_pay == 'zaad' ? 'Zaad' : 'eDahab'}',
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => _goStep(_signedIn ? 2 : 3),
            child: const Text(
              'Back',
              style: TextStyle(color: EkaadhColors.muted, fontWeight: FontWeight.w700),
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
    final event = widget.event;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Summary', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
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
                          ? Image.network(event.coverImage!, fit: BoxFit.cover)
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
                              '\$${t.price.toStringAsFixed(0)} · ${t.remaining} left',
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
              if (_ticketCount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Service fee', style: TextStyle(color: EkaadhColors.muted, fontSize: 13)),
                      Text('\$${_serviceFee.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
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
                    'Signed in as ${_name.text}. Payment and tickets will use your account details.',
                    style: const TextStyle(fontSize: 13, height: 1.45, color: EkaadhColors.dark),
                  ),
                ),
              ],
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Guest checkout — no account needed. We\'ll confirm your phone, then send tickets via SMS and WhatsApp.',
              style: TextStyle(fontSize: 13, height: 1.45, color: EkaadhColors.muted),
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
              _field('Full Name', _name, 'e.g. Faadumo Hassan', readOnly: _signedIn),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text.rich(
                      TextSpan(
                        text: 'Phone Number ',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EkaadhColors.muted),
                        children: [
                          TextSpan(
                            text: '(Required for payment)',
                            style: TextStyle(color: EkaadhColors.brand, fontWeight: FontWeight.w600, fontSize: 11),
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
                'Email Address (Optional)',
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

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Confirm phone', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-digit code sent to ${PhoneNumberField.fullNumber(_phone.text)}.',
          style: const TextStyle(fontSize: 13, height: 1.45, color: EkaadhColors.muted),
        ),
        if (_otpHint != null) ...[
          const SizedBox(height: 8),
          Text(
            _otpHint!,
            style: const TextStyle(color: EkaadhColors.brand, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _otp,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 8, fontSize: 20),
          decoration: EkaadhFields.decoration(hintText: '123456').copyWith(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text(
          'Choose your preferred mobile money method',
          style: TextStyle(fontSize: 13, color: EkaadhColors.muted),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _PayCard(
                id: 'zaad',
                label: 'Zaad',
                sub: 'Telesom mobile money',
                abbr: 'Z',
                bg: const Color(0xFFFFF3E0),
                fg: const Color(0xFFE65100),
                selected: _pay == 'zaad',
                onTap: () => setState(() => _pay = 'zaad'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PayCard(
                id: 'edahab',
                label: 'eDahab',
                sub: 'Hormuud mobile money',
                abbr: 'eD',
                bg: const Color(0xFFE3F2FD),
                fg: const Color(0xFF1565C0),
                selected: _pay == 'edahab',
                onTap: () => setState(() => _pay = 'edahab'),
              ),
            ),
          ],
        ),
        if (_pay != null) ...[
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
                      ? 'Charge ${_pay == 'zaad' ? 'Zaad (Telesom)' : 'eDahab (Hormuud)'} on your account phone'
                      : 'Enter your ${_pay == 'zaad' ? 'Zaad (Telesom)' : 'eDahab (Hormuud)'} number to charge',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                PhoneNumberField(
                  controller: _phone,
                  borderRadius: 16,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  readOnly: _signedIn,
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
                      const Text('Total to charge', style: TextStyle(fontWeight: FontWeight.w600, color: EkaadhColors.muted, fontSize: 13)),
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
                    title: const Text(
                      'Simulate failed payment (debug)',
                      style: TextStyle(fontSize: 13, color: EkaadhColors.muted),
                    ),
                    value: _forceFail,
                    activeThumbColor: EkaadhColors.brand,
                    onChanged: (v) => setState(() => _forceFail = v),
                  ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.verified_user_outlined, size: 14, color: EkaadhColors.brand),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Your payment is encrypted and secure. A confirmation SMS will be sent immediately.',
                        style: TextStyle(fontSize: 11, color: EkaadhColors.muted, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
    required this.abbr,
    required this.bg,
    required this.fg,
    required this.selected,
    required this.onTap,
  });

  final String id, label, sub, abbr;
  final Color bg, fg;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
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
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
                  alignment: Alignment.center,
                  child: Text(abbr, style: TextStyle(fontWeight: FontWeight.w900, color: fg, fontSize: 15)),
                ),
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
    return Dialog(
      backgroundColor: EkaadhColors.brandLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: const Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(color: EkaadhColors.brand, strokeWidth: 3),
            ),
            SizedBox(height: 20),
            Text('Processing Payment', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            SizedBox(height: 6),
            Text('Please wait…', style: TextStyle(color: EkaadhColors.muted)),
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
              const Text('Payment Failed', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: EkaadhColors.muted, height: 1.65)),
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
                  child: const Text('Try Again'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Back to Home', style: TextStyle(color: EkaadhColors.soft, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
