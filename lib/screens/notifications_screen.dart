import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/locale_scope.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/core/user_facing_error.dart';
import 'package:ekaadh_mobile/screens/support_screen.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = const [];
  bool _loading = true;
  Object? _error;

  bool get _signedIn => widget.auth.token != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = widget.auth.token;
    if (token == null) {
      setState(() {
        _loading = false;
        _items = const [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await NotificationService(token: token).list();
      if (!mounted) return;
      setState(() {
        _items = page.notifications;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _open(AppNotification note) async {
    final token = widget.auth.token;
    if (token != null && note.isUnread) {
      try {
        await NotificationService(token: token).markRead(note.id);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _items = _items
              .map(
                (n) => n.id == note.id
                    ? AppNotification(
                        id: n.id,
                        title: n.title,
                        body: n.body,
                        kind: n.kind,
                        meta: n.meta,
                        readAt: DateTime.now(),
                        createdAt: n.createdAt,
                      )
                    : n,
              )
              .toList();
        });
      }
    }

    if (!mounted) return;
    if (note.kind == 'support_reply') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SupportScreen(auth: widget.auth)),
      );
    }
  }

  Future<void> _markAll() async {
    final token = widget.auth.token;
    if (token == null) return;
    try {
      await NotificationService(token: token).markAllRead();
      if (!mounted) return;
      setState(() {
        _items = _items
            .map(
              (n) => AppNotification(
                id: n.id,
                title: n.title,
                body: n.body,
                kind: n.kind,
                meta: n.meta,
                readAt: n.readAt ?? DateTime.now(),
                createdAt: n.createdAt,
              ),
            )
            .toList();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    final hasUnread = _items.any((n) => n.isUnread);

    return Scaffold(
      backgroundColor: EkaadhColors.surface,
      appBar: AppBar(
        backgroundColor: EkaadhColors.surface,
        foregroundColor: EkaadhColors.dark,
        elevation: 0,
        title: Text(
          l10n.t('notifications'),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          if (_signedIn && hasUnread)
            TextButton(
              onPressed: _markAll,
              child: Text(
                l10n.t('mark_all_read'),
                style: const TextStyle(
                  color: EkaadhColors.brand,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: EkaadhColors.brand))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          UserFacingError.message(_error, t: l10n.t),
                          textAlign: TextAlign.center,
                        ),
                        TextButton(onPressed: _load, child: Text(l10n.t('retry'))),
                      ],
                    ),
                  ),
                )
              : !_signedIn
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.t('notifications_sign_in'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: EkaadhColors.muted, fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                  : _items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              l10n.t('no_notifications'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: EkaadhColors.muted, fontWeight: FontWeight.w600),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: EkaadhColors.brand,
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final n = _items[i];
                              return Material(
                                color: n.isUnread ? EkaadhColors.brandLight : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  onTap: () => _open(n),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: n.isUnread ? EkaadhColors.brand : const Color(0xFFE8ECF1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            _iconFor(n.kind),
                                            size: 20,
                                            color: n.isUnread ? Colors.white : EkaadhColors.muted,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                n.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 14,
                                                  color: EkaadhColors.dark,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                n.body,
                                                style: const TextStyle(
                                                  color: EkaadhColors.muted,
                                                  fontSize: 13,
                                                  height: 1.35,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (n.isUnread)
                                          const Padding(
                                            padding: EdgeInsets.only(top: 6, left: 8),
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: EkaadhColors.brand,
                                                shape: BoxShape.circle,
                                              ),
                                              child: SizedBox(width: 8, height: 8),
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
    );
  }

  IconData _iconFor(String kind) {
    switch (kind) {
      case 'support_reply':
        return Icons.chat_bubble_outline;
      case 'event_reminder':
        return Icons.event_available_outlined;
      case 'tickets_ready':
        return Icons.confirmation_number_outlined;
      case 'invitation_received':
        return Icons.mail_outline;
      case 'private_event_paid':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_none_rounded;
    }
  }
}
