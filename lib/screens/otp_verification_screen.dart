import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ekaadh_mobile/core/locale_scope.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/core/user_facing_error.dart';
import 'package:ekaadh_mobile/services/otp_service.dart';
import 'package:ekaadh_mobile/widgets/ekaadh_toast.dart';
import 'package:ekaadh_mobile/widgets/phone_number_field.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.phone,
    required this.purpose,
    this.debugHint,
    this.alreadySent = false,
  });

  final String phone;
  final String purpose;
  final String? debugHint;
  final bool alreadySent;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  bool _loading = false;
  bool _sending = false;
  String? _debugHint;
  int _resendIn = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _debugHint = widget.debugHint;
    _code.addListener(() => setState(() {}));
    if (widget.alreadySent) {
      _startResendCooldown();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode());
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendIn = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendIn <= 1) {
        t.cancel();
        setState(() => _resendIn = 0);
      } else {
        setState(() => _resendIn -= 1);
      }
    });
  }

  Future<void> _sendCode() async {
    if (_sending || _resendIn > 0) return;
    setState(() => _sending = true);
    try {
      final result = await OtpService().send(
        phone: widget.phone,
        purpose: widget.purpose,
      );
      if (!mounted) return;
      final l10n = LocaleScope.of(context);
      setState(() {
        _sending = false;
        _debugHint = result.debugCode != null
            ? '${l10n.t('testing_code')}: ${result.debugCode}'
            : null;
      });
      _startResendCooldown();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      await EkaadhToast.error(
        context,
        message: UserFacingError.message(e, t: LocaleScope.of(context).t),
      );
    }
  }

  Future<void> _verify() async {
    final l10n = LocaleScope.of(context);
    final otp = _code.text.trim();
    if (otp.length < 6) {
      await EkaadhToast.error(context, message: l10n.t('enter_confirmation_code'));
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await OtpService().verify(
        phone: widget.phone,
        purpose: widget.purpose,
        otp: otp,
      );
      if (!mounted) return;
      setState(() => _loading = false);
      if (widget.purpose != OtpService.purposeFindTickets &&
          (result.otpToken == null || result.otpToken!.isEmpty)) {
        await EkaadhToast.error(context, message: l10n.t('could_not_confirm_phone'));
        return;
      }
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      await EkaadhToast.error(
        context,
        message: UserFacingError.message(e, t: LocaleScope.of(context).t),
      );
    }
  }

  String get _prettyPhone {
    final digits = widget.phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('252') && digits.length >= 12) {
      return '+252-${digits.substring(3, 6)}-${digits.substring(6, 9)}-${digits.substring(9)}';
    }
    return PhoneNumberField.fullNumber(widget.phone);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    final canResend = !_sending && _resendIn == 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: EkaadhColors.dark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  children: [
                    const _OtpMailIllustration(),
                    const SizedBox(height: 8),
                    Text(
                      l10n.t('otp_verification'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: EkaadhColors.dark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: EkaadhColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(text: '${l10n.t('enter_otp_sent_to')} '),
                          TextSpan(
                            text: _prettyPhone,
                            style: const TextStyle(
                              color: EkaadhColors.dark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    _OtpBoxes(
                      controller: _code,
                      focusNode: _focus,
                      enabled: !_loading,
                      onCompleted: (_) => _verify(),
                    ),
                    if (_debugHint != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _debugHint!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: EkaadhColors.brand,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    Text(
                      l10n.t('dont_receive_otp'),
                      style: const TextStyle(
                        color: EkaadhColors.soft,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: canResend ? _sendCode : null,
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: EkaadhColors.brand),
                            )
                          : Text(
                              _resendIn > 0
                                  ? '${l10n.t('resend_otp')} (${_resendIn}s)'
                                  : l10n.t('resend_otp'),
                              style: TextStyle(
                                color: canResend ? EkaadhColors.brand : EkaadhColors.soft,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 0.6,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _loading ? null : _verify,
                  style: FilledButton.styleFrom(
                    backgroundColor: EkaadhColors.brand,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: EkaadhColors.brand.withValues(alpha: 0.55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.t('verify')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpBoxes extends StatelessWidget {
  const _OtpBoxes({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    this.onCompleted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String>? onCompleted;

  @override
  Widget build(BuildContext context) {
    final value = controller.text;
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final box = ((constraints.maxWidth - gap * 5) / 6).clamp(40.0, 56.0);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? () => focusNode.requestFocus() : null,
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < value.length;
                  final active = enabled && i == value.length;
                  return Container(
                    width: box,
                    height: box,
                    margin: EdgeInsets.only(left: i == 0 ? 0 : gap),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active ? EkaadhColors.brand : const Color(0xFFE8ECF1),
                        width: active ? 1.6 : 1,
                      ),
                    ),
                    child: Text(
                      filled ? value[i] : '*',
                      style: TextStyle(
                        fontSize: filled ? 22 : 20,
                        fontWeight: FontWeight.w800,
                        color: filled ? EkaadhColors.dark : EkaadhColors.hint,
                      ),
                    ),
                  );
                }),
              ),
              Positioned(
                left: 0,
                top: 0,
                width: 1,
                height: 1,
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    maxLength: 6,
                    showCursor: false,
                    enableInteractiveSelection: false,
                    style: const TextStyle(color: Colors.transparent, fontSize: 1, height: 0.01),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onChanged: (v) {
                      if (v.length == 6) onCompleted?.call(v);
                    },
                    decoration: const InputDecoration.collapsed(hintText: '').copyWith(
                      counterText: '',
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OtpMailIllustration extends StatelessWidget {
  const _OtpMailIllustration();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 236,
      width: double.infinity,
      child: CustomPaint(painter: _MailboxScenePainter()),
    );
  }
}

class _MailboxScenePainter extends CustomPainter {
  const _MailboxScenePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 6;

    canvas.drawCircle(
      Offset(cx, cy - 6),
      92,
      Paint()..color = const Color(0xFFF2F4F8),
    );

    void dot(Offset c, double r, Color color) {
      canvas.drawCircle(c, r, Paint()..color = color);
    }

    dot(Offset(cx - 78, cy - 62), 5, EkaadhColors.brand);
    dot(Offset(cx + 76, cy - 48), 4.2, const Color(0xFFFFB020));
    dot(Offset(cx - 70, cy + 58), 3.6, const Color(0xFFFF7A3D));
    dot(Offset(cx + 68, cy + 42), 3.2, EkaadhColors.brand);
    dot(Offset(cx - 86, cy + 8), 2.6, const Color(0xFFFFB020));
    dot(Offset(cx + 88, cy + 10), 2.4, const Color(0xFF7C83C7));

    final dash = Paint()
      ..color = EkaadhColors.brand.withValues(alpha: 0.28)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx - 40, cy - 8), radius: 70),
      3.4,
      0.9,
      false,
      dash,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx + 18, cy + 4), radius: 82),
      -0.35,
      0.7,
      false,
      dash,
    );

    final stroke = Paint()
      ..color = EkaadhColors.brand
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = Colors.white;

    final box = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 10, cy + 8), width: 92, height: 62),
      const Radius.circular(10),
    );
    canvas.drawRRect(box, fill);
    canvas.drawRRect(box, stroke);

    final door = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 32, cy - 10, 44, 28),
      const Radius.circular(4),
    );
    canvas.drawRRect(door, stroke);

    final post = Rect.fromCenter(center: Offset(cx - 10, cy + 50), width: 10, height: 22);
    canvas.drawRect(post, Paint()..color = EkaadhColors.brand);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 10, cy + 62), width: 38, height: 8),
        const Radius.circular(2),
      ),
      Paint()..color = EkaadhColors.brand,
    );

    final flagPole = Path()
      ..moveTo(cx - 56, cy - 6)
      ..lineTo(cx - 56, cy - 34);
    canvas.drawPath(flagPole, stroke);
    final flag = Path()
      ..moveTo(cx - 56, cy - 32)
      ..lineTo(cx - 36, cy - 26)
      ..lineTo(cx - 56, cy - 20)
      ..close();
    canvas.drawPath(flag, Paint()..color = EkaadhColors.brand);

    canvas.save();
    canvas.translate(cx + 38, cy - 46);
    canvas.rotate(0.22);
    final envelope = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 62, 42),
      const Radius.circular(7),
    );
    canvas.drawRRect(envelope, fill);
    canvas.drawRRect(envelope, stroke);
    final flap = Path()
      ..moveTo(6, 8)
      ..lineTo(31, 24)
      ..lineTo(56, 8);
    canvas.drawPath(flap, stroke);
    final starPaint = Paint()
      ..color = EkaadhColors.brand
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final x = 14.0 + i * 10;
      canvas.drawLine(Offset(x, 30), Offset(x + 5, 34), starPaint);
      canvas.drawLine(Offset(x + 5, 34), Offset(x + 10, 30), starPaint);
    }
    canvas.restore();

    canvas.drawCircle(
      Offset(cx + 92, cy - 52),
      7,
      Paint()..color = const Color(0xFFFF7A3D),
    );
    canvas.drawCircle(
      Offset(cx + 92, cy - 52),
      7,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
