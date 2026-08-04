import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/models/private_event_model.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/services/private_event_service.dart';
import 'package:ekaadh_mobile/screens/private_event_create_screen.dart';
import 'package:ekaadh_mobile/screens/private_event_detail_screen.dart';
import 'package:ekaadh_mobile/screens/private_event_pay_screen.dart';

class PrivateEventsListScreen extends StatefulWidget {
  const PrivateEventsListScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<PrivateEventsListScreen> createState() => _PrivateEventsListScreenState();
}

class _PrivateEventsListScreenState extends State<PrivateEventsListScreen> {
  late final PrivateEventService _service;
  List<PrivateEventModel> _events = [];
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
      final events = await _service.list();
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
          builder: (_) => PrivateEventPayScreen(auth: widget.auth, eventId: event.id),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PrivateEventDetailScreen(auth: widget.auth, eventId: event.id),
        ),
      );
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EkaadhColors.surface,
      appBar: AppBar(
        title: const Text('Private Events', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: EkaadhColors.dark,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: EkaadhColors.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        color: EkaadhColors.brand,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: EkaadhColors.brand))
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(_error!, style: const TextStyle(color: EkaadhColors.danger)),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _load,
                        style: FilledButton.styleFrom(backgroundColor: EkaadhColors.brand),
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                : _events.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(24),
                        children: const [
                          SizedBox(height: 80),
                          Text(
                            'No private events yet.\nPay for tickets, then invite guests by phone.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: EkaadhColors.muted, height: 1.5),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _events.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final e = _events[i];
                          return InkWell(
                            onTap: () => _open(e),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        if (e.design != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            e.design!.name,
                            style: TextStyle(
                              color: e.design!.isPremium
                                  ? const Color(0xFFB45309)
                                  : EkaadhColors.brand,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (e.eventDateLabel != null) e.eventDateLabel!,
                            if (e.venue != null) e.venue!,
                          ].join(' · '),
                          style: const TextStyle(
                            color: EkaadhColors.muted,
                            fontSize: 13,
                          ),
                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          e.isPaid
                                              ? '${e.invited}/${e.capacity} invited · ${e.remaining} left'
                                              : 'Awaiting payment',
                                          style: TextStyle(
                                            color: e.isPaid
                                                ? EkaadhColors.brand
                                                : const Color(0xFFD97706),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    e.isPaid ? Icons.chevron_right : Icons.payment,
                                    color: EkaadhColors.soft,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
