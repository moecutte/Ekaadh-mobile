import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/screens/staff_events_screen.dart';
import 'package:ekaadh_mobile/widgets/ekaadh_logo.dart';

class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({
    super.key,
    required this.auth,
    required this.onSignedIn,
  });

  final AuthService auth;
  final VoidCallback onSignedIn;

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final _loginController = TextEditingController(text: 'staff@ekaadh.com');
  final _passwordController = TextEditingController(text: 'password');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final error = await widget.auth.login(
      login: _loginController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _loading = false;
        _error = error;
      });
      return;
    }

    final role = widget.auth.user?.role;
    if (role != 'staff' && role != 'admin') {
      await widget.auth.logout();
      setState(() {
        _loading = false;
        _error = 'Staff credentials required.';
      });
      return;
    }

    setState(() => _loading = false);
    widget.onSignedIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EkaadhColors.dark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white70),
              ),
              const SizedBox(height: 12),
              const Center(child: EkaadhLogo(height: 44, white: true)),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Staff Portal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Sign in to scan and check in guests',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                ),
              ),
              const SizedBox(height: 32),
              _label('Email or phone'),
              TextField(
                controller: _loginController,
                style: const TextStyle(color: Colors.white),
                decoration: _decoration('staff@ekaadh.com'),
              ),
              const SizedBox(height: 16),
              _label('Password'),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: _decoration('••••••••'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Color(0xFFF87171))),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Enter scanner'),
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
          color: Color(0xFF6B7280),
          letterSpacing: 1,
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF4B5563)),
      filled: true,
      fillColor: const Color(0xFF111827),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }
}

/// Thin wrapper used after staff login from root.
class StaffHome extends StatelessWidget {
  const StaffHome({
    super.key,
    required this.auth,
    required this.onSignOut,
  });

  final AuthService auth;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return StaffEventsScreen(auth: auth, onSignOut: onSignOut);
  }
}
