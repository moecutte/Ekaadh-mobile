import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({
    super.key,
    required this.auth,
    required this.onSignOut,
    required this.onSignIn,
    required this.onRegister,
    required this.onOpenTickets,
    required this.onOpenBooked,
  });

  final AuthService auth;
  final Future<void> Function() onSignOut;
  final VoidCallback onSignIn;
  final VoidCallback onRegister;
  final VoidCallback onOpenTickets;
  final VoidCallback onOpenBooked;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  Widget build(BuildContext context) {
    final user = widget.auth.user;
    final signedIn = widget.auth.token != null && user != null;

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            const Text(
              'Profile',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 20),
            _HeroCard(
              initial: signedIn && user.name.isNotEmpty
                  ? user.name[0].toUpperCase()
                  : 'G',
              title: signedIn ? user.name : 'Guest',
              subtitle: signedIn
                  ? (user.phone ?? user.email)
                  : 'Browse and buy without an account',
            ),
            if (signedIn) ...[
              const SizedBox(height: 28),
              const _SectionLabel('Account'),
              const SizedBox(height: 8),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.badge_outlined,
                    title: 'Display name',
                    subtitle: user.name,
                    onTap: () => _editName(user.name),
                  ),
                  _SettingsTile(
                    icon: Icons.phone_outlined,
                    title: 'Phone',
                    subtitle: user.phone ?? 'Not set',
                    showChevron: false,
                  ),
                  _SettingsTile(
                    icon: Icons.mail_outline,
                    title: 'Email',
                    subtitle: _displayEmail(user.email),
                    onTap: () => _editEmail(user.email),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionLabel('Security'),
              const SizedBox(height: 8),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.lock_outline,
                    title: 'Change password',
                    subtitle: 'Update your sign-in password',
                    onTap: _changePasswordSheet,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionLabel('Your activity'),
              const SizedBox(height: 8),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.event_available_outlined,
                    title: 'Booked Events',
                    subtitle: 'Tickets you purchased',
                    onTap: widget.onOpenBooked,
                  ),
                  _SettingsTile(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Tickets',
                    subtitle: 'Private invitations you created',
                    onTap: widget.onOpenTickets,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: widget.onSignOut,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EkaadhColors.danger,
                    side: const BorderSide(color: Color(0xFFFECACA), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  child: const Text('Sign out'),
                ),
              ),
            ] else ...[
              const SizedBox(height: 32),
              const Text(
                'Sign in to manage your account, booked events, and private tickets.',
                style: TextStyle(color: EkaadhColors.muted, height: 1.45),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: widget.onSignIn,
                style: FilledButton.styleFrom(
                  backgroundColor: EkaadhColors.brand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                child: const Text('Sign in'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: widget.onRegister,
                style: OutlinedButton.styleFrom(
                  foregroundColor: EkaadhColors.brand,
                  side: const BorderSide(color: EkaadhColors.brand, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                child: const Text('Create account'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _displayEmail(String email) {
    if (email.endsWith('@ekaadh.local')) return 'Not set';
    return email;
  }

  Future<void> _editName(String current) async {
    final controller = TextEditingController(text: current);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String? error;
        var saving = false;
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Display name',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'This name appears on your account and bookings.',
                    style: TextStyle(color: EkaadhColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: EkaadhFields.decoration(hintText: 'Your name'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(error!, style: const TextStyle(color: EkaadhColors.danger)),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              final name = controller.text.trim();
                              if (name.isEmpty) {
                                setModal(() => error = 'Enter your name.');
                                return;
                              }
                              setModal(() {
                                saving = true;
                                error = null;
                              });
                              final err = await widget.auth.updateProfile(name: name);
                              if (!ctx.mounted) return;
                              if (err != null) {
                                setModal(() {
                                  saving = false;
                                  error = err;
                                });
                                return;
                              }
                              Navigator.of(ctx).pop(true);
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: EkaadhColors.brand,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    controller.dispose();
    if (saved == true && mounted) setState(() {});
  }

  Future<void> _editEmail(String current) async {
    final initial = current.endsWith('@ekaadh.local') ? '' : current;
    final controller = TextEditingController(text: initial);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String? error;
        var saving = false;
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Email',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Optional. Used for receipts and account recovery.',
                    style: TextStyle(color: EkaadhColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    decoration: EkaadhFields.decoration(hintText: 'you@example.com'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(error!, style: const TextStyle(color: EkaadhColors.danger)),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              final name = widget.auth.user?.name ?? '';
                              final email = controller.text.trim();
                              setModal(() {
                                saving = true;
                                error = null;
                              });
                              final err = await widget.auth.updateProfile(
                                name: name,
                                email: email.isEmpty ? null : email,
                              );
                              if (!ctx.mounted) return;
                              if (err != null) {
                                setModal(() {
                                  saving = false;
                                  error = err;
                                });
                                return;
                              }
                              Navigator.of(ctx).pop(true);
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: EkaadhColors.brand,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    controller.dispose();
    if (saved == true && mounted) setState(() {});
  }

  Future<void> _changePasswordSheet() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String? error;
        String? success;
        var saving = false;
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Change password',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: current,
                    obscureText: true,
                    decoration: EkaadhFields.decoration(hintText: 'Current password'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: next,
                    obscureText: true,
                    decoration:
                        EkaadhFields.decoration(hintText: 'New password (min. 8)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirm,
                    obscureText: true,
                    decoration:
                        EkaadhFields.decoration(hintText: 'Confirm new password'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(error!, style: const TextStyle(color: EkaadhColors.danger)),
                  ],
                  if (success != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      success!,
                      style: const TextStyle(
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (current.text.isEmpty ||
                                  next.text.isEmpty ||
                                  confirm.text.isEmpty) {
                                setModal(() => error = 'Fill in all fields.');
                                return;
                              }
                              if (next.text != confirm.text) {
                                setModal(
                                  () => error =
                                      'New password and confirmation do not match.',
                                );
                                return;
                              }
                              setModal(() {
                                saving = true;
                                error = null;
                                success = null;
                              });
                              final err = await widget.auth.changePassword(
                                currentPassword: current.text,
                                password: next.text,
                                passwordConfirmation: confirm.text,
                              );
                              if (!ctx.mounted) return;
                              if (err != null) {
                                setModal(() {
                                  saving = false;
                                  error = err;
                                });
                                return;
                              }
                              current.clear();
                              next.clear();
                              confirm.clear();
                              setModal(() {
                                saving = false;
                                success = 'Password updated successfully.';
                              });
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: EkaadhColors.brand,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Update password',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    current.dispose();
    next.dispose();
    confirm.dispose();
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.initial,
    required this.title,
    required this.subtitle,
  });

  final String initial;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EkaadhColors.brandLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: EkaadhColors.brand,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: EkaadhColors.dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: EkaadhColors.muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: EkaadhColors.soft,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E8EE)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0xFFF0F0F4)),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: EkaadhColors.brandLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: EkaadhColors.brand, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: EkaadhColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron && onTap != null)
              const Icon(Icons.chevron_right, color: EkaadhColors.soft),
          ],
        ),
      ),
    );
  }
}
