import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/models/private_event_model.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/services/private_event_service.dart';
import 'package:ekaadh_mobile/screens/private_event_create_screen.dart';
import 'package:ekaadh_mobile/screens/private_event_detail_screen.dart';
import 'package:ekaadh_mobile/screens/private_event_pay_screen.dart';

/// Tab: private invitation tickets the signed-in user created.
class PrivateTicketsTab extends StatefulWidget {
  const PrivateTicketsTab({
    super.key,
    required this.auth,
    required this.onSignIn,
    required this.onRegister,
    this.active = true,
  });

  final AuthService auth;
  final VoidCallback onSignIn;
  final VoidCallback onRegister;
  final bool active;

  @override
  State<PrivateTicketsTab> createState() => _PrivateTicketsTabState();
}

class _PrivateTicketsTabState extends State<PrivateTicketsTab> {
  PrivateEventService? _service;
  List<PrivateEventModel> _events = [];
  bool _loading = false;
  String? _error;

  /// all | valid | expired
  String _statusFilter = 'all';

  bool get _signedIn => widget.auth.token != null;

  List<PrivateEventModel> get _filteredEvents {
    return _events.where((e) {
      if (_statusFilter == 'valid' && e.isExpired) return false;
      if (_statusFilter == 'expired' && !e.isExpired) return false;
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    if (_signedIn) {
      _service = PrivateEventService(token: widget.auth.token!);
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant PrivateTicketsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.auth.token != widget.auth.token) {
      if (_signedIn) {
        _service = PrivateEventService(token: widget.auth.token!);
        _load();
      } else {
        setState(() {
          _service = null;
          _events = [];
          _error = null;
          _loading = false;
        });
      }
    } else if (!oldWidget.active && widget.active && _signedIn) {
      _load();
    }
  }

  Future<void> _load() async {
    if (_service == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final events = await _service!.list();
      if (!mounted) return;
      setState(() {
        _events = events;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _create() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrivateEventCreateScreen(auth: widget.auth),
      ),
    );
    _load();
  }

  Future<void> _open(PrivateEventModel event) async {
    if (!event.isPaid) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              PrivateEventPayScreen(auth: widget.auth, eventId: event.id),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              PrivateEventDetailScreen(auth: widget.auth, eventId: event.id),
        ),
      );
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: _signedIn ? _signedInBody() : _guestBody(),
      ),
    );
  }

  Widget _guestBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      children: [
        const Text(
          'Tickets',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 48),
        const Icon(Icons.confirmation_number_outlined,
            size: 56, color: EkaadhColors.soft),
        const SizedBox(height: 16),
        const Text(
          'Create private invitation tickets',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        const SizedBox(height: 8),
        const Text(
          'Log in or create an account to design invitations, pay for capacity, and invite guests.',
          textAlign: TextAlign.center,
          style: TextStyle(color: EkaadhColors.muted, height: 1.45),
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: widget.onSignIn,
          style: FilledButton.styleFrom(
            backgroundColor: EkaadhColors.brand,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          child: const Text('Log in'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: widget.onRegister,
          style: OutlinedButton.styleFrom(
            foregroundColor: EkaadhColors.brand,
            side: const BorderSide(color: EkaadhColors.brand, width: 2),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          child: const Text('Create account'),
        ),
      ],
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

  Widget _signedInBody() {
    final filtered = _filteredEvents;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                'Tickets',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(
                'Private invitations you created',
                style: TextStyle(color: EkaadhColors.muted, fontSize: 13),
              ),
            ),
            if (_events.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: [
                    _filterChip(
                      label: 'All status',
                      active: _statusFilter == 'all',
                      onTap: () => setState(() => _statusFilter = 'all'),
                    ),
                    _filterChip(
                      label: 'Valid',
                      active: _statusFilter == 'valid',
                      onTap: () => setState(() => _statusFilter = 'valid'),
                    ),
                    _filterChip(
                      label: 'Expired',
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
                                child: const Text('Retry'),
                              ),
                            ],
                          )
                        : _events.isEmpty
                            ? ListView(
                                padding: const EdgeInsets.all(24),
                                children: const [
                                  SizedBox(height: 72),
                                  Icon(
                                    Icons.confirmation_number_outlined,
                                    size: 44,
                                    color: EkaadhColors.soft,
                                  ),
                                  SizedBox(height: 14),
                                  Text(
                                    'No tickets yet',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Create a private invitation package\nand invite guests by phone.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: EkaadhColors.muted,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              )
                            : filtered.isEmpty
                                ? ListView(
                                    padding: const EdgeInsets.all(24),
                                    children: const [
                                      SizedBox(height: 48),
                                      Icon(
                                        Icons.filter_list_off_rounded,
                                        size: 40,
                                        color: EkaadhColors.soft,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'No tickets match these filters',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'Try Valid or Expired.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
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
                                    itemBuilder: (context, i) =>
                                        _TicketListTile(
                                      event: filtered[i],
                                      onTap: () => _open(filtered[i]),
                                    ),
                                  ),
              ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 96,
          child: FloatingActionButton.extended(
            onPressed: _create,
            backgroundColor: EkaadhColors.brand,
            foregroundColor: Colors.white,
            elevation: 0,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Create',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _TicketListTile extends StatelessWidget {
  const _TicketListTile({required this.event, required this.onTap});

  final PrivateEventModel event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumb = event.design?.previewImageUrl ?? event.coverImage;
    final meta = [
      if (event.eventDateLabel != null) event.eventDateLabel!,
      if (event.eventTimeLabel != null) event.eventTimeLabel!,
      if (event.venue != null) event.venue!,
    ].join(' · ');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
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
                  child: thumb != null
                      ? Image.network(thumb, fit: BoxFit.cover)
                      : const ColoredBox(
                          color: EkaadhColors.brandLight,
                          child: Icon(
                            Icons.confirmation_number_outlined,
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
                            color: event.isPaid
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            event.isPaid ? 'Paid' : 'Unpaid',
                            style: TextStyle(
                              color: event.isPaid
                                  ? const Color(0xFF047857)
                                  : const Color(0xFFB45309),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: event.isExpired
                                ? const Color(0xFFF3F4F6)
                                : EkaadhColors.brandLight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            event.isExpired ? 'Expired' : 'Valid',
                            style: TextStyle(
                              color: event.isExpired
                                  ? EkaadhColors.muted
                                  : EkaadhColors.brand,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          event.isPaid
                              ? Icons.chevron_right_rounded
                              : Icons.payment_rounded,
                          size: 20,
                          color: EkaadhColors.soft,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.title,
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
                      event.isPaid
                          ? '${event.invited}/${event.capacity} invited · ${event.remaining} left'
                          : 'Finish payment to invite guests',
                      style: TextStyle(
                        color: event.isPaid
                            ? EkaadhColors.brand
                            : const Color(0xFFD97706),
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
