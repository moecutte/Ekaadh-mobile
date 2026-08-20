import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/locale_scope.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/models/private_event_model.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/services/private_event_service.dart';
import 'package:ekaadh_mobile/screens/private_event_add_capacity_screen.dart';
import 'package:ekaadh_mobile/screens/private_event_invitations_screen.dart';
import 'package:ekaadh_mobile/screens/private_event_pay_screen.dart';
import 'package:ekaadh_mobile/widgets/design_network_image.dart';
import 'package:ekaadh_mobile/core/user_facing_error.dart';

class PrivateEventDetailScreen extends StatefulWidget {
  const PrivateEventDetailScreen({
    super.key,
    required this.auth,
    required this.eventId,
  });

  final AuthService auth;
  final int eventId;

  @override
  State<PrivateEventDetailScreen> createState() =>
      _PrivateEventDetailScreenState();
}

class _PrivateEventDetailScreenState extends State<PrivateEventDetailScreen> {
  late final PrivateEventService _service;
  PrivateEventModel? _event;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = PrivateEventService(token: widget.auth.token!);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final event = await _service.show(widget.eventId);
      if (!mounted) return;
      if (!event.isPaid) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PrivateEventPayScreen(
              auth: widget.auth,
              eventId: event.id,
            ),
          ),
        );
        return;
      }
      setState(() {
        _event = event;
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

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    final e = _event;
    final thumb = e?.design?.previewImageUrl ?? e?.coverImage;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          l10n.t('ticket_details'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        foregroundColor: EkaadhColors.dark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: EkaadhColors.brand),
            )
          : e == null
              ? Center(child: Text(_error ?? l10n.t('not_found')))
              : RefreshIndicator(
                  color: EkaadhColors.brand,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: 88,
                              height: 118,
                              child: thumb != null
                                  ? DesignNetworkImage(url: thumb)
                                  : const ColoredBox(
                                      color: EkaadhColors.brandLight,
                                      child: Icon(
                                        Icons.confirmation_number_outlined,
                                        color: EkaadhColors.brand,
                                        size: 28,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    l10n.t('paid'),
                                    style: const TextStyle(
                                      color: Color(0xFF047857),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  e.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    height: 1.2,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  [
                                    if (e.eventDateLabel != null)
                                      e.eventDateLabel!,
                                    if (e.eventTimeLabel != null)
                                      e.eventTimeLabel!,
                                    if (e.venue != null) e.venue!,
                                  ].join(' · '),
                                  style: const TextStyle(
                                    color: EkaadhColors.muted,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          _stat(l10n.t('paid_seats'), '${e.capacity}'),
                          const SizedBox(width: 10),
                          _stat(l10n.t('invited'), '${e.invited}'),
                          const SizedBox(width: 10),
                          _stat(l10n.t('left'), '${e.remaining}'),
                        ],
                      ),
                      const SizedBox(height: 22),
                      FilledButton(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PrivateEventInvitationsScreen(
                                auth: widget.auth,
                                eventId: e.id,
                              ),
                            ),
                          );
                          _load();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: EkaadhColors.brand,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle:
                              const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        child: Text(l10n.t('manage_invitations')),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PrivateEventAddCapacityScreen(
                                auth: widget.auth,
                                event: e,
                              ),
                            ),
                          );
                          _load();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: EkaadhColors.brand,
                          side: const BorderSide(
                            color: Color(0xFFD5DAE8),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle:
                              const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        child: Text(l10n.t('buy_more_tickets')),
                      ),
                      if (e.description != null &&
                          e.description!.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        Text(
                          l10n.t('about'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          e.description!,
                          style: const TextStyle(
                            color: EkaadhColors.muted,
                            height: 1.5,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEF0F4)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: EkaadhColors.brand,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: EkaadhColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
