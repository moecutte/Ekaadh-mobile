import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/services/check_in_service.dart';
import 'package:ekaadh_mobile/screens/scanner_screen.dart';

class StaffEventsScreen extends StatefulWidget {
  const StaffEventsScreen({
    super.key,
    required this.auth,
    required this.onSignOut,
  });

  final AuthService auth;
  final Future<void> Function() onSignOut;

  @override
  State<StaffEventsScreen> createState() => _StaffEventsScreenState();
}

class _StaffEventsScreenState extends State<StaffEventsScreen> {
  late final CheckInService _service = CheckInService(widget.auth);
  List<StaffEventSummary> _events = [];
  bool _loading = true;
  String? _error;
  String _venue = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<String> get _venues {
    final names = _events
        .map((e) => e.venue?.trim())
        .whereType<String>()
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return names;
  }

  List<StaffEventSummary> get _filteredEvents {
    if (_venue == 'All') return _events;
    return _events.where((e) => (e.venue ?? '').trim() == _venue).toList();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final events = await _service.events();
      if (!mounted) return;
      setState(() {
        _events = events;
        if (_venue != 'All' && !events.any((e) => (e.venue ?? '').trim() == _venue)) {
          _venue = 'All';
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load events.';
      });
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Sign out?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'You will need to sign in again to check guests in.',
          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w700),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: EkaadhColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await widget.onSignOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final venues = ['All', ..._venues];
    final filtered = _filteredEvents;

    return Scaffold(
      backgroundColor: EkaadhColors.dark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select event',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Choose where you are checking guests in',
                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _confirmSignOut,
                    tooltip: 'Sign out',
                    icon: const Icon(Icons.logout, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
            if (!_loading && _error == null && _events.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: DropdownButtonFormField<String>(
                  key: ValueKey('venue-$_venue-${venues.join('|')}'),
                  initialValue: venues.contains(_venue) ? _venue : 'All',
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1F2937),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.place_outlined, color: Color(0xFF9CA3AF), size: 20),
                    filled: true,
                    fillColor: const Color(0xFF111827),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: EkaadhColors.brand, width: 1.5),
                    ),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF)),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  items: venues
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(
                            v == 'All' ? 'All Venues' : v,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _venue = v);
                  },
                ),
              ),
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator(color: EkaadhColors.brand)),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Color(0xFFF87171))),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
            else if (_events.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No published events.', style: TextStyle(color: Color(0xFF9CA3AF))),
                ),
              )
            else if (filtered.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No events at this venue.',
                    style: TextStyle(color: Color(0xFF9CA3AF)),
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  color: EkaadhColors.brand,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final event = filtered[index];
                      final progress = event.ticketsTotal == 0
                          ? 0.0
                          : event.ticketsCheckedIn / event.ticketsTotal;
                      return Material(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ScannerScreen(
                                  auth: widget.auth,
                                  event: event,
                                ),
                              ),
                            ).then((_) => _load());
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    event.eventDateLabel,
                                    event.eventTimeLabel,
                                    event.venue,
                                  ].whereType<String>().join(' · '),
                                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 6,
                                    backgroundColor: const Color(0xFF1F2937),
                                    color: EkaadhColors.brand,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${event.ticketsCheckedIn} / ${event.ticketsTotal} checked in',
                                  style: const TextStyle(
                                    color: EkaadhColors.brand,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
