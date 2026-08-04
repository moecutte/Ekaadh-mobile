import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/models/ticket_model.dart';
import 'package:ekaadh_mobile/screens/ticket_view_screen.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/services/otp_service.dart';
import 'package:ekaadh_mobile/services/ticket_service.dart';
import 'package:ekaadh_mobile/widgets/phone_number_field.dart';

class MyTicketsTab extends StatefulWidget {
  const MyTicketsTab({
    super.key,
    required this.auth,
    required this.onRequestSignIn,
    this.active = true,
  });

  final AuthService auth;
  final VoidCallback onRequestSignIn;
  final bool active;

  @override
  State<MyTicketsTab> createState() => _MyTicketsTabState();
}

class _MyTicketsTabState extends State<MyTicketsTab> {
  String _tab = 'upcoming';
  late Future<List<TicketModel>> _future;
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _lookingUp = false;
  bool _otpSent = false;
  String? _lookupError;
  String? _otpHint;
  List<TicketModel>? _guestTickets;

  bool get _signedIn => widget.auth.token != null;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant MyTicketsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.auth.token != widget.auth.token) {
      _reload();
    } else if (!oldWidget.active && widget.active && _signedIn) {
      _reload();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<List<TicketModel>> _load() {
    final token = widget.auth.token;
    if (token == null) return Future.value([]);
    return TicketService().mine(token: token, tab: _tab);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _sendFindOtp() async {
    if (!PhoneNumberField.hasLocalNumber(_phoneController.text)) {
      setState(() => _lookupError = 'Enter your phone number.');
      return;
    }
    setState(() {
      _lookingUp = true;
      _lookupError = null;
    });
    try {
      final result = await OtpService().send(
        phone: PhoneNumberField.fullNumber(_phoneController.text),
        purpose: OtpService.purposeFindTickets,
      );
      if (!mounted) return;
      setState(() {
        _lookingUp = false;
        _otpSent = true;
        _otpHint = result.debugCode != null
            ? 'Testing code: ${result.debugCode}'
            : result.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lookingUp = false;
        _lookupError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _lookupTickets() async {
    if (!_otpSent) {
      await _sendFindOtp();
      return;
    }
    if (_otpController.text.trim().isEmpty) {
      setState(() => _lookupError = 'Enter the confirmation code.');
      return;
    }
    setState(() {
      _lookingUp = true;
      _lookupError = null;
    });
    try {
      final result = await OtpService().verify(
        phone: PhoneNumberField.fullNumber(_phoneController.text),
        purpose: OtpService.purposeFindTickets,
        otp: _otpController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _lookingUp = false;
        _guestTickets = result.tickets;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lookingUp = false;
        _lookupError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _resetGuestLookup() {
    setState(() {
      _guestTickets = null;
      _otpSent = false;
      _otpController.clear();
      _otpHint = null;
      _lookupError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_signedIn) {
      if (_guestTickets != null) {
        return _GuestTicketsResult(
          tickets: _guestTickets!,
          onBack: _resetGuestLookup,
        );
      }
      return _GuestTicketsGate(
        phoneController: _phoneController,
        otpController: _otpController,
        lookingUp: _lookingUp,
        otpSent: _otpSent,
        otpHint: _otpHint,
        lookupError: _lookupError,
        onSignIn: widget.onRequestSignIn,
        onLookup: _lookupTickets,
        onResend: _sendFindOtp,
      );
    }

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text('Booked Events', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(
              'Tickets you bought or were invited to',
              style: TextStyle(color: EkaadhColors.muted, fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: EkaadhColors.surface, borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  _TabBtn(label: 'Upcoming', active: _tab == 'upcoming', onTap: () {
                    setState(() => _tab = 'upcoming');
                    _reload();
                  }),
                  _TabBtn(label: 'Past', active: _tab == 'past', onTap: () {
                    setState(() => _tab = 'past');
                    _reload();
                  }),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: EkaadhColors.brand,
              onRefresh: () async => _reload(),
              child: FutureBuilder<List<TicketModel>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: EkaadhColors.brand));
                  }
                  if (snap.hasError) {
                    return ListView(children: [
                      const SizedBox(height: 80),
                      Text('${snap.error}', textAlign: TextAlign.center),
                      TextButton(onPressed: _reload, child: const Text('Retry')),
                    ]);
                  }
                  final tickets = snap.data ?? [];
                  if (tickets.isEmpty) {
                    return ListView(children: [
                      const SizedBox(height: 100),
                      const Icon(Icons.event_available_outlined, size: 48, color: EkaadhColors.soft),
                      const SizedBox(height: 12),
                      Text(
                        _tab == 'upcoming' ? 'No upcoming booked events' : 'No past booked events',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Buy tickets from Home, or open an invitation sent to your phone.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: EkaadhColors.muted),
                      ),
                    ]);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: tickets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => _TicketCard(ticket: tickets[i]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final TicketModel ticket;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TicketViewScreen(ticket: ticket)),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8E8EE)),
          ),
          child: Column(
          children: [
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (ticket.displayImage != null)
                    Image.network(ticket.displayImage!, fit: BoxFit.cover)
                  else
                    ColoredBox(
                      color: ticket.isPrivate
                          ? EkaadhColors.brandLight
                          : const Color(0xFFE2E8E4),
                      child: ticket.isPrivate
                          ? const Icon(Icons.mail_outline, color: EkaadhColors.brand, size: 40)
                          : null,
                    ),
                  const ColoredBox(color: Color(0x61000000)),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ticket.eventTitle ?? 'Event', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                        Text(
                          [
                            if (ticket.eventDateLabel != null && ticket.eventDateLabel!.isNotEmpty)
                              ticket.eventDateLabel!,
                            if (ticket.eventTimeLabel != null && ticket.eventTimeLabel!.isNotEmpty)
                              ticket.eventTimeLabel!,
                            if (ticket.venue != null && ticket.venue!.isNotEmpty) ticket.venue!,
                          ].join(' · '),
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      children: [
                        if (ticket.isPrivate)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Invitation',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: ticket.status == 'valid' ? EkaadhColors.brand : const Color(0xFF9CA3AF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            ticket.status == 'valid' ? 'Valid' : ticket.status[0].toUpperCase() + ticket.status.substring(1),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ticket.ticketTypeName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EkaadhColors.muted)),
                        Text(ticket.ticketCode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: EkaadhColors.brand, fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                  const Icon(Icons.qr_code_2, color: EkaadhColors.brand, size: 18),
                  const SizedBox(width: 4),
                  const Text('View QR', style: TextStyle(color: EkaadhColors.brand, fontWeight: FontWeight.w700, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _GuestTicketsResult extends StatelessWidget {
  const _GuestTicketsResult({
    required this.tickets,
    required this.onBack,
  });

  final List<TicketModel> tickets;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
            child: Row(
              children: [
                IconButton(onPressed: onBack, icon: const Icon(Icons.chevron_left)),
                const Text('Your tickets', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Expanded(
            child: tickets.isEmpty
                ? const Center(
                    child: Text(
                      'No available valid tickets for this phone.',
                      style: TextStyle(color: EkaadhColors.muted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    itemCount: tickets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => _TicketCard(ticket: tickets[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GuestTicketsGate extends StatelessWidget {
  const _GuestTicketsGate({
    required this.phoneController,
    required this.otpController,
    required this.lookingUp,
    required this.otpSent,
    required this.otpHint,
    required this.lookupError,
    required this.onSignIn,
    required this.onLookup,
    required this.onResend,
  });

  final TextEditingController phoneController;
  final TextEditingController otpController;
  final bool lookingUp;
  final bool otpSent;
  final String? otpHint;
  final String? lookupError;
  final VoidCallback onSignIn;
  final VoidCallback onLookup;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: EkaadhColors.brandLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.event_available_outlined, color: EkaadhColors.brand, size: 32),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Booked Events',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign in to view your booked events, or find guest tickets with the phone used at checkout.',
            textAlign: TextAlign.center,
            style: TextStyle(color: EkaadhColors.muted, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onSignIn,
              style: FilledButton.styleFrom(
                backgroundColor: EkaadhColors.brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              child: const Text('Sign In with Phone Number'),
            ),
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('OR', style: TextStyle(color: EkaadhColors.soft, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8EDEB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Find tickets by phone',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 12),
                PhoneNumberField(
                  controller: phoneController,
                  borderRadius: 14,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                if (otpSent) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 6),
                    decoration: EkaadhFields.decoration(
                      hintText: 'Confirmation code',
                      radius: 14,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                  if (otpHint != null) ...[
                    const SizedBox(height: 8),
                    Text(otpHint!, style: const TextStyle(color: EkaadhColors.brand, fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                  TextButton(
                    onPressed: lookingUp ? null : onResend,
                    child: const Text('Resend code', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
                if (lookupError != null) ...[
                  const SizedBox(height: 10),
                  Text(lookupError!, style: const TextStyle(color: EkaadhColors.danger, fontSize: 13)),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: lookingUp ? null : onLookup,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: EkaadhColors.dark,
                      side: const BorderSide(color: Color(0xFFE8EDEB)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    child: lookingUp
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: EkaadhColors.brand),
                          )
                        : Text(otpSent ? 'Verify & Show Tickets' : 'Find Tickets'),
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

class _TabBtn extends StatelessWidget {
  const _TabBtn({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? EkaadhColors.brand : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: active ? Colors.white : EkaadhColors.soft,
            ),
          ),
        ),
      ),
    );
  }
}
