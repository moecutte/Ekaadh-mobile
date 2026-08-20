import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/locale_scope.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/models/ticket_model.dart';
import 'package:ekaadh_mobile/screens/otp_verification_screen.dart';
import 'package:ekaadh_mobile/screens/ticket_view_screen.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/services/otp_service.dart';
import 'package:ekaadh_mobile/services/ticket_service.dart';
import 'package:ekaadh_mobile/widgets/design_network_image.dart';
import 'package:ekaadh_mobile/widgets/phone_number_field.dart';
import 'package:ekaadh_mobile/core/user_facing_error.dart';

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
  /// all | valid | expired
  String _statusFilter = 'all';
  List<TicketModel> _tickets = [];
  bool _loading = false;
  String? _error;
  final _phoneController = TextEditingController();
  bool _lookingUp = false;
  String? _lookupError;
  List<TicketModel>? _guestTickets;

  bool get _signedIn => widget.auth.token != null;

  List<TicketModel> get _filteredTickets {
    return _tickets.where((t) {
      if (_statusFilter == 'valid' && !t.isUpcoming) return false;
      if (_statusFilter == 'expired' && t.isUpcoming) return false;
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    if (_signedIn) _load();
  }

  @override
  void didUpdateWidget(covariant MyTicketsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.auth.token != widget.auth.token) {
      if (_signedIn) {
        _load();
      } else {
        setState(() {
          _tickets = [];
          _error = null;
          _loading = false;
        });
      }
    } else if (!oldWidget.active && widget.active && _signedIn) {
      _load();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = widget.auth.token;
    if (token == null) return;
    final showSpinner = _tickets.isEmpty;
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final service = TicketService();
      final results = await Future.wait([
        service.mine(token: token, tab: 'upcoming'),
        service.mine(token: token, tab: 'past'),
      ]);
      final seen = <int>{};
      final tickets = [...results[0], ...results[1]]
          .where((t) => !t.isPrivate && seen.add(t.id))
          .toList();
      if (!mounted) return;
      setState(() {
        _tickets = tickets;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = UserFacingError.message(e, t: LocaleScope.of(context).t);
        _loading = false;
      });
    }
  }

  Future<void> _lookupTickets() async {
    final l10n = LocaleScope.of(context);
    if (!PhoneNumberField.hasLocalNumber(_phoneController.text)) {
      setState(() => _lookupError = l10n.t('enter_phone'));
      return;
    }
    setState(() {
      _lookingUp = true;
      _lookupError = null;
    });
    try {
      final sent = await OtpService().send(
        phone: PhoneNumberField.fullNumber(_phoneController.text),
        purpose: OtpService.purposeFindTickets,
      );
      if (!mounted) return;
      setState(() => _lookingUp = false);

      final verified = await Navigator.of(context).push<OtpResult>(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            phone: PhoneNumberField.fullNumber(_phoneController.text),
            purpose: OtpService.purposeFindTickets,
            alreadySent: true,
            debugHint: sent.debugCode != null
                ? '${l10n.t('testing_code')}: ${sent.debugCode}'
                : null,
          ),
        ),
      );
      if (!mounted || verified == null) return;
      setState(() => _guestTickets = verified.tickets);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lookingUp = false;
        _lookupError = UserFacingError.message(e, t: LocaleScope.of(context).t);
      });
    }
  }

  void _resetGuestLookup() {
    setState(() {
      _guestTickets = null;
      _lookupError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_signedIn) {
      if (_guestTickets != null) {
        return _GuestTicketsResult(
          tickets: _guestTickets!.where((t) => !t.isPrivate).toList(),
          onBack: _resetGuestLookup,
        );
      }
      return _GuestTicketsGate(
        phoneController: _phoneController,
        lookingUp: _lookingUp,
        lookupError: _lookupError,
        onSignIn: widget.onRequestSignIn,
        onLookup: _lookupTickets,
      );
    }

    final l10n = LocaleScope.of(context);
    final filtered = _filteredTickets;
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                l10n.t('booked_events'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(
                l10n.t('booked_events_desc'),
                style: const TextStyle(color: EkaadhColors.muted, fontSize: 13),
              ),
            ),
            if (_tickets.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: [
                    _filterChip(
                      label: l10n.t('all_status'),
                      active: _statusFilter == 'all',
                      onTap: () => setState(() => _statusFilter = 'all'),
                    ),
                    _filterChip(
                      label: l10n.t('valid'),
                      active: _statusFilter == 'valid',
                      onTap: () => setState(() => _statusFilter = 'valid'),
                    ),
                    _filterChip(
                      label: l10n.t('expired'),
                      active: _statusFilter == 'expired',
                      onTap: () => setState(() => _statusFilter = 'expired'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                color: EkaadhColors.brand,
                onRefresh: _load,
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: EkaadhColors.brand,
                        ),
                      )
                    : _error != null
                        ? ListView(
                            padding: const EdgeInsets.all(24),
                            children: [
                              Text(
                                _error!,
                                style: const TextStyle(color: EkaadhColors.danger),
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: _load,
                                style: FilledButton.styleFrom(
                                  backgroundColor: EkaadhColors.brand,
                                ),
                                child: Text(l10n.t('retry')),
                              ),
                            ],
                          )
                        : _tickets.isEmpty
                            ? ListView(
                                padding: const EdgeInsets.all(24),
                                children: [
                                  const SizedBox(height: 72),
                                  const Icon(
                                    Icons.event_available_outlined,
                                    size: 44,
                                    color: EkaadhColors.soft,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    l10n.t('no_booked_yet'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.t('buy_or_invitation'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: EkaadhColors.muted,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              )
                            : filtered.isEmpty
                                ? ListView(
                                    padding: const EdgeInsets.all(24),
                                    children: [
                                      const SizedBox(height: 48),
                                      const Icon(
                                        Icons.filter_list_off_rounded,
                                        size: 40,
                                        color: EkaadhColors.soft,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        l10n.t('no_tickets_filters'),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        l10n.t('try_valid_expired'),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: EkaadhColors.muted,
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 4, 16, 110),
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (_, i) =>
                                        _TicketCard(ticket: filtered[i]),
                                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: active ? EkaadhColors.brand : const Color(0xFFF3F4F8),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: active ? Colors.white : EkaadhColors.dark,
              ),
            ),
          ),
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
    final l10n = LocaleScope.of(context);
    final expired = !ticket.isUpcoming;
    final statusLabel = expired
        ? l10n.t('expired')
        : ticket.status == 'valid'
            ? l10n.t('valid')
            : ticket.status[0].toUpperCase() + ticket.status.substring(1);
    final meta = [
      if (ticket.eventDateLabel != null && ticket.eventDateLabel!.isNotEmpty)
        ticket.eventDateLabel!,
      if (ticket.eventTimeLabel != null && ticket.eventTimeLabel!.isNotEmpty)
        ticket.eventTimeLabel!,
      if (ticket.venue != null && ticket.venue!.isNotEmpty) ticket.venue!,
    ].join(' · ');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TicketViewScreen(ticket: ticket)),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEEF0F4)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 52,
                  height: 68,
                  child: ticket.displayImage != null
                      ? DesignNetworkImage(url: ticket.displayImage)
                      : const ColoredBox(
                          color: EkaadhColors.brandLight,
                          child: Icon(
                            Icons.event_available_outlined,
                            color: EkaadhColors.brand,
                            size: 22,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: expired
                                ? const Color(0xFFF3F4F6)
                                : EkaadhColors.brandLight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: expired
                                  ? EkaadhColors.muted
                                  : EkaadhColors.brand,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (ticket.ticketTypeName.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F8),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                ticket.ticketTypeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: EkaadhColors.dark,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: EkaadhColors.soft,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ticket.eventTitle ?? l10n.t('event'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: EkaadhColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      expired
                          ? ticket.ticketCode
                          : '${l10n.t('view_qr')} · ${ticket.ticketCode}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: expired ? EkaadhColors.muted : EkaadhColors.brand,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
    final l10n = LocaleScope.of(context);
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
                Text(l10n.t('your_tickets'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Expanded(
            child: tickets.isEmpty
                ? Center(
                    child: Text(
                      l10n.t('no_valid_tickets_phone'),
                      style: const TextStyle(color: EkaadhColors.muted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    itemCount: tickets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
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
    required this.lookingUp,
    required this.lookupError,
    required this.onSignIn,
    required this.onLookup,
  });

  final TextEditingController phoneController;
  final bool lookingUp;
  final String? lookupError;
  final VoidCallback onSignIn;
  final VoidCallback onLookup;

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
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
          Text(
            l10n.t('booked_events'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.t('booked_guest_prompt'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: EkaadhColors.muted, fontSize: 14, height: 1.5),
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
              child: Text(l10n.t('sign_in_with_phone')),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(l10n.t('or').toUpperCase(), style: const TextStyle(color: EkaadhColors.soft, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const Expanded(child: Divider()),
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
                Text(
                  l10n.t('find_tickets_by_phone'),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 12),
                PhoneNumberField(
                  controller: phoneController,
                  borderRadius: 14,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
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
                        : Text(l10n.t('find_tickets')),
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



