import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ekaadh_mobile/core/api_config.dart';
import 'package:ekaadh_mobile/core/locale_scope.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/models/event_model.dart';
import 'package:ekaadh_mobile/screens/checkout_screen.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/services/event_service.dart';
import 'package:ekaadh_mobile/widgets/design_network_image.dart';
import 'package:ekaadh_mobile/core/user_facing_error.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.slug, this.auth});

  final String slug;
  final AuthService? auth;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Future<EventModel> _future;

  @override
  void initState() {
    super.initState();
    _future = EventService().show(widget.slug);
  }

  Future<void> _shareEvent(EventModel e) async {
    final l10n = LocaleScope.of(context);
    final url = ApiConfig.eventShareUrl(e.slug);
    final text = l10n.t('share_event_text').replaceAll(':title', e.title);
    await Share.share('$text\n$url', subject: e.title);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<EventModel>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: EkaadhColors.brand));
          }
          if (snap.hasError || !snap.hasData) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(UserFacingError.message(snap.error ?? l10n.t('event_not_found'), t: l10n.t)),
                  TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.t('go_back'))),
                ],
              ),
            );
          }
          final e = snap.data!;
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 280,
                    pinned: true,
                    backgroundColor: EkaadhColors.dark,
                    leading: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      style: IconButton.styleFrom(backgroundColor: Colors.black38),
                    ),
                    actions: [
                      IconButton(
                        onPressed: () => _shareEvent(e),
                        tooltip: l10n.t('share_event'),
                        icon: const Icon(Icons.ios_share, color: Colors.white),
                        style: IconButton.styleFrom(backgroundColor: Colors.black38),
                      ),
                      const SizedBox(width: 8),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          DesignNetworkImage(
                            url: e.coverImage,
                            fallbackColor: const Color(0xFFC8D8CF),
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.black45, Colors.transparent],
                              ),
                            ),
                          ),
                          if (e.category != null)
                            Positioned(
                              left: 18,
                              bottom: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(color: EkaadhColors.brand, borderRadius: BorderRadius.circular(999)),
                                child: Text(e.category!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Text(e.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.25)),
                        const SizedBox(height: 16),
                        _InfoRow(
                          icon: Icons.access_time,
                          label: l10n.t('date_time'),
                          value: '${e.eventDateLabel ?? ''} ${l10n.t('at_time')} ${e.eventTimeLabel ?? ''}',
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(icon: Icons.location_on_outlined, label: l10n.t('venue'), value: [e.venue, e.city].whereType<String>().where((x) => x.isNotEmpty).join(', ')),
                        if (e.organizerName != null) ...[
                          const SizedBox(height: 12),
                          _InfoRow(icon: Icons.business, label: l10n.t('organizer'), value: e.organizerName!),
                        ],
                        const SizedBox(height: 22),
                        Text(l10n.t('about_this_event'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Text(e.description ?? '', style: const TextStyle(color: EkaadhColors.muted, height: 1.7, fontSize: 14)),
                        if (e.ticketTypes.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text(l10n.t('ticket_types'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 10),
                          ...e.ticketTypes.map((t) => Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFF0F4F2), width: 2),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(t.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                                          if (t.description != null)
                                            Text(t.description!, style: const TextStyle(color: EkaadhColors.soft, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Text('\$${t.price.toStringAsFixed(0)}', style: const TextStyle(color: EkaadhColors.brand, fontWeight: FontWeight.w900, fontSize: 17)),
                                  ],
                                ),
                              )),
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFF0F4F2))),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.t('starting_from'), style: const TextStyle(fontSize: 11, color: EkaadhColors.soft, fontWeight: FontWeight.w600)),
                          Text(
                            e.startingPrice == null ? '—' : '\$${e.startingPrice!.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: EkaadhColors.brand),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                          child: ElevatedButton(
                          onPressed: e.isExpired
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CheckoutScreen(event: e, auth: widget.auth),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: e.isExpired ? const Color(0xFFE2E8F0) : EkaadhColors.brand,
                            foregroundColor: e.isExpired ? const Color(0xFF64748B) : Colors.white,
                            disabledBackgroundColor: const Color(0xFFE2E8F0),
                            disabledForegroundColor: const Color(0xFF64748B),
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          child: Text(e.isExpired ? l10n.t('expired') : l10n.t('get_tickets')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: EkaadhColors.brandLight, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 15, color: EkaadhColors.brand),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: EkaadhColors.soft, fontWeight: FontWeight.w600)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ],
    );
  }
}
