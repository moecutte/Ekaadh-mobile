import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/locale_scope.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/screens/register_screen.dart';
import 'package:ekaadh_mobile/screens/staff_login_screen.dart';
import 'package:ekaadh_mobile/widgets/ekaadh_logo.dart';
import 'package:ekaadh_mobile/widgets/phone_number_field.dart';
import 'package:ekaadh_mobile/core/user_facing_error.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.auth,
    required this.onSignedIn,
    this.allowDismiss = false,
  });

  final AuthService auth;
  final VoidCallback onSignedIn;
  /// When true (pushed from Home), show a close control so guests can go back.
  final bool allowDismiss;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = LocaleScope.of(context);
    if (!PhoneNumberField.hasLocalNumber(_loginController.text)) {
      setState(() => _error = l10n.t('enter_phone'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final error = await widget.auth.login(
        login: PhoneNumberField.fullNumber(_loginController.text),
        password: _passwordController.text,
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
        _error = UserFacingError.message(e, t: l10n.t);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.allowDismiss)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.chevron_left, color: EkaadhColors.soft),
                    label: Text(
                      l10n.t('continue_as_guest'),
                      style: const TextStyle(color: EkaadhColors.soft, fontWeight: FontWeight.w700),
                    ),
                  ),
                )
              else
                const SizedBox(height: 20),
              const Center(child: EkaadhLogo(height: 44)),
              const SizedBox(height: 28),
              Text(
                l10n.t('welcome_back'),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: EkaadhColors.dark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.t('sign_in_subtitle'),
                style: const TextStyle(color: EkaadhColors.muted, fontSize: 14),
              ),
              const SizedBox(height: 28),
              _label(l10n.t('phone_number')),
              PhoneNumberField(controller: _loginController),
              const SizedBox(height: 16),
              _label(l10n.t('password')),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: _inputDecoration('••••••••'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: EkaadhColors.danger)),
              ],
              const SizedBox(height: 22),
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
                      : Text(l10n.t('sign_in')),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RegisterScreen(
                          auth: widget.auth,
                          onSignedIn: () {
                            widget.onSignedIn();
                            if (widget.allowDismiss) {
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            }
                          },
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EkaadhColors.brand,
                    side: const BorderSide(color: EkaadhColors.brand, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  child: Text(l10n.t('create_account')),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StaffLoginScreen(
                          auth: widget.auth,
                          onSignedIn: widget.onSignedIn,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    l10n.t('staff_portal'),
                    style: const TextStyle(
                      color: EkaadhColors.muted,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF9CA3AF),
          letterSpacing: 1,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return EkaadhFields.decoration(
      hintText: hint,
      radius: 18,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }
}
