import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/locale_scope.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/screens/otp_verification_screen.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/services/otp_service.dart';
import 'package:ekaadh_mobile/widgets/ekaadh_logo.dart';
import 'package:ekaadh_mobile/widgets/phone_number_field.dart';
import 'package:ekaadh_mobile/core/user_facing_error.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.auth,
    required this.onSignedIn,
  });

  final AuthService auth;
  final VoidCallback onSignedIn;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = LocaleScope.of(context);
    if (_name.text.trim().isEmpty) {
      setState(() => _error = l10n.t('enter_your_name'));
      return;
    }
    if (!PhoneNumberField.hasLocalNumber(_phone.text)) {
      setState(() => _error = l10n.t('enter_phone'));
      return;
    }
    if (_password.text.length < 8) {
      setState(() => _error = l10n.t('min_8_chars'));
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _error = l10n.t('password_mismatch'));
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sent = await OtpService().send(
        phone: PhoneNumberField.fullNumber(_phone.text),
        purpose: OtpService.purposeRegister,
      );
      if (!mounted) return;
      setState(() => _loading = false);

      final verified = await Navigator.of(context).push<OtpResult>(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            phone: PhoneNumberField.fullNumber(_phone.text),
            purpose: OtpService.purposeRegister,
            alreadySent: true,
            debugHint: sent.debugCode != null
                ? '${l10n.t('testing_code')}: ${sent.debugCode}'
                : null,
          ),
        ),
      );
      if (!mounted || verified?.otpToken == null) return;

      setState(() => _loading = true);
      final error = await widget.auth.register(
        name: _name.text.trim(),
        phone: PhoneNumberField.fullNumber(_phone.text),
        password: _password.text,
        passwordConfirmation: _confirm.text,
        otpToken: verified!.otpToken!,
      );
      if (!mounted) return;
      setState(() => _loading = false);
      if (error == null) {
        widget.onSignedIn();
      } else {
        setState(() => _error = UserFacingError.message(error, t: l10n.t));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = UserFacingError.message(e, t: LocaleScope.of(context).t);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.chevron_left, color: Color(0xFF9CA3AF)),
                label: Text(l10n.t('back'), style: const TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              const Center(child: EkaadhLogo(height: 40)),
              const SizedBox(height: 20),
              Text(
                l10n.t('create_account'),
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: EkaadhColors.dark),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.t('create_account_subtitle'),
                style: const TextStyle(color: EkaadhColors.muted, fontSize: 14),
              ),
              const SizedBox(height: 28),
              _field(l10n.t('full_name'), _name, 'Amina Hassan'),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.t('phone_number').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    PhoneNumberField(controller: _phone),
                  ],
                ),
              ),
              _field(l10n.t('password'), _password, l10n.t('min_8_chars'), obscure: true),
              _field(l10n.t('confirm_password'), _confirm, l10n.t('reenter_password'), obscure: true),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: EkaadhColors.danger)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EkaadhColors.brand,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.t('send_confirmation_code')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    String hint, {
    bool obscure = false,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF9CA3AF),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboard,
            decoration: EkaadhFields.decoration(
              hintText: hint,
              radius: 18,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
