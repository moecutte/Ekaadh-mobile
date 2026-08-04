import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/services/otp_service.dart';
import 'package:ekaadh_mobile/widgets/ekaadh_logo.dart';
import 'package:ekaadh_mobile/widgets/phone_number_field.dart';

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
  final _otp = TextEditingController();
  bool _loading = false;
  bool _otpSent = false;
  String? _otpHint;
  String? _otpToken;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!PhoneNumberField.hasLocalNumber(_phone.text)) {
      setState(() => _error = 'Enter your phone number.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await OtpService().send(
        phone: PhoneNumberField.fullNumber(_phone.text),
        purpose: OtpService.purposeRegister,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _otpSent = true;
        _otpHint = result.debugCode != null
            ? 'Testing code: ${result.debugCode}'
            : result.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _submit() async {
    if (!_otpSent) {
      await _sendOtp();
      return;
    }

    if (_otp.text.trim().isEmpty) {
      setState(() => _error = 'Enter the confirmation code.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      String? token = _otpToken;
      if (token == null) {
        final verified = await OtpService().verify(
          phone: PhoneNumberField.fullNumber(_phone.text),
          purpose: OtpService.purposeRegister,
          otp: _otp.text.trim(),
        );
        token = verified.otpToken;
        if (token == null) {
          throw Exception('Could not confirm phone.');
        }
        _otpToken = token;
      }

      final error = await widget.auth.register(
        name: _name.text.trim(),
        phone: PhoneNumberField.fullNumber(_phone.text),
        password: _password.text,
        passwordConfirmation: _confirm.text,
        otpToken: token,
      );
      if (!mounted) return;
      setState(() => _loading = false);
      if (error == null) {
        widget.onSignedIn();
      } else {
        setState(() {
          _error = error;
          _otpToken = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
        _otpToken = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                label: const Text('Back', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              const Center(child: EkaadhLogo(height: 40)),
              const SizedBox(height: 20),
              const Text(
                'Create account',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: EkaadhColors.dark),
              ),
              const SizedBox(height: 6),
              const Text(
                'Join Ekaadh and start discovering events',
                style: TextStyle(color: EkaadhColors.muted, fontSize: 14),
              ),
              const SizedBox(height: 28),
              _field('Full Name', _name, 'Amina Hassan'),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PHONE NUMBER',
                      style: TextStyle(
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
              _field('Password', _password, 'Min. 8 characters', obscure: true),
              _field('Confirm Password', _confirm, 'Re-enter password', obscure: true),
              if (_otpSent) ...[
                const SizedBox(height: 4),
                _field('Confirmation code', _otp, '123456', keyboard: TextInputType.number),
                if (_otpHint != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _otpHint!,
                      style: const TextStyle(color: EkaadhColors.brand, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                TextButton(
                  onPressed: _loading ? null : _sendOtp,
                  child: const Text('Resend code', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
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
                      : Text(_otpSent ? 'Verify & Create Account' : 'Send Confirmation Code'),
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
