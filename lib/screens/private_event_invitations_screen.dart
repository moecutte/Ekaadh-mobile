import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/locale_scope.dart';
import 'package:ekaadh_mobile/core/user_facing_error.dart';
import 'package:flutter/services.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/models/private_event_model.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/services/private_event_service.dart';
import 'package:ekaadh_mobile/screens/private_event_send_invites_screen.dart';
import 'package:ekaadh_mobile/widgets/design_network_image.dart';
import 'package:ekaadh_mobile/widgets/ekaadh_toast.dart';

class PrivateEventInvitationsScreen extends StatefulWidget {
  const PrivateEventInvitationsScreen({
    super.key,
    required this.auth,
    required this.eventId,
  });

  final AuthService auth;
  final int eventId;

  @override
  State<PrivateEventInvitationsScreen> createState() =>
      _PrivateEventInvitationsScreenState();
}

class _PrivateEventInvitationsScreenState
    extends State<PrivateEventInvitationsScreen> {
  late final PrivateEventService _service;
  final _searchController = TextEditingController();
  List<InvitationModel> _invites = [];
  PrivateEventModel? _event;
  int _remaining = 0;
  bool _loading = true;
  String? _error;
  String _query = '';

  List<InvitationModel> get _filteredInvites {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _invites;
    final digits = q.replaceAll(RegExp(r'\D'), '');
    return _invites.where((invite) {
      final name = (invite.guestName ?? '').toLowerCase();
      final phone = invite.guestPhone.toLowerCase();
      final phoneDigits = invite.guestPhone.replaceAll(RegExp(r'\D'), '');
      if (name.contains(q) || phone.contains(q)) return true;
      if (digits.isNotEmpty && phoneDigits.contains(digits)) return true;
      return false;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _service = PrivateEventService(token: widget.auth.token!);
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.invitations(widget.eventId);
      if (!mounted) return;
      setState(() {
        _invites = result.invitations;
        _remaining = result.remaining;
        _event = result.event;
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

  Future<void> _send() async {
    final event = _event ?? await _service.show(widget.eventId);
    if (!mounted) return;
    final sent = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PrivateEventSendInvitesScreen(
          auth: widget.auth,
          event: event,
        ),
      ),
    );
    if (sent == true && mounted) _load();
  }

  Future<void> _resend(InvitationModel invite) async {
    final channel = await _pickChannel(invite.deliveryChannel);
    if (channel == null || !mounted) return;
    try {
      await _service.resendInvitation(
        eventId: widget.eventId,
        invitationId: invite.id,
        channel: channel,
      );
      if (!mounted) return;
      await EkaadhToast.success(context, message: LocaleScope.of(context).t('invitation_resent'));
      _load();
    } catch (e) {
      if (!mounted) return;
      await EkaadhToast.error(
        context,
        message: UserFacingError.message(e, t: LocaleScope.of(context).t),
      );
    }
  }

  Future<String?> _pickChannel(String? current) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        final l10n = LocaleScope.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('resend_via'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.t('invite_channel_hint'),
                  style: const TextStyle(
                    color: EkaadhColors.muted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: Icon(
                    Icons.chat_rounded,
                    color: current == 'whatsapp'
                        ? EkaadhColors.brand
                        : EkaadhColors.muted,
                  ),
                  title: Text(
                    l10n.t('invite_channel_whatsapp'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onTap: () => Navigator.pop(ctx, 'whatsapp'),
                ),
                ListTile(
                  leading: Icon(
                    Icons.sms_rounded,
                    color: current == 'sms'
                        ? EkaadhColors.brand
                        : EkaadhColors.muted,
                  ),
                  title: Text(
                    l10n.t('invite_channel_sms'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onTap: () => Navigator.pop(ctx, 'sms'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _revoke(InvitationModel invite) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l10n = LocaleScope.of(ctx);
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            l10n.t('revoke_invitation'),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(l10n.t('revoke_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.t('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                l10n.t('revoke'),
                style: const TextStyle(color: EkaadhColors.danger),
              ),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    try {
      await _service.revokeInvitation(
        eventId: widget.eventId,
        invitationId: invite.id,
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      await EkaadhToast.error(
        context,
        message: UserFacingError.message(e, t: LocaleScope.of(context).t),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    final event = _event;
    final thumb = event?.design?.previewImageUrl ?? event?.coverImage;
    final meta = event == null
        ? ''
        : [
            if (event.eventDateLabel != null) event.eventDateLabel!,
            if (event.eventTimeLabel != null) event.eventTimeLabel!,
            if (event.venue != null) event.venue!,
          ].join(' · ');
    final filtered = _filteredInvites;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          l10n.t('invitations'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        foregroundColor: EkaadhColors.dark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _send,
        backgroundColor: EkaadhColors.brand,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.send_rounded),
        label: Text(
          l10n.t('send'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        color: EkaadhColors.brand,
        onRefresh: _load,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: EkaadhColors.brand),
              )
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: EkaadhColors.danger),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                    children: [
                      if (event != null)
                        Container(
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
                                      ? DesignNetworkImage(url: thumb)
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
                                    Text(
                                      event.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
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
                                    const SizedBox(height: 6),
                                    Text(
                                      '$_remaining seats remaining',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: EkaadhColors.brand,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          '$_remaining seats remaining',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: EkaadhColors.brand,
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        decoration: EkaadhFields.decoration(
                          hintText: l10n.t('search_name_phone'),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: EkaadhColors.soft,
                          ),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: EkaadhColors.soft,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_invites.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 48),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.mail_outline_rounded,
                                size: 42,
                                color: EkaadhColors.soft,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n.t('no_invitations_yet'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.t('tap_send_invite'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: EkaadhColors.muted,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.search_off_rounded,
                                size: 40,
                                color: EkaadhColors.soft,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                l10n.t('no_guests_match'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.t('try_another_name_phone'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: EkaadhColors.muted),
                              ),
                            ],
                          ),
                        )
                      else
                        ...filtered.map((invite) => _inviteCard(invite)),
                    ],
                  ),
      ),
    );
  }

  String _initial(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return 'G';
    return trimmed[0].toUpperCase();
  }

  Widget _inviteCard(InvitationModel invite) {
    final l10n = LocaleScope.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF0F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: EkaadhColors.brandLight,
                child: Text(
                  _initial(invite.guestName),
                  style: const TextStyle(
                    color: EkaadhColors.brand,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.guestName?.isNotEmpty == true
                          ? invite.guestName!
                          : l10n.t('guest'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      invite.guestPhone,
                      style: const TextStyle(
                        color: EkaadhColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: invite.isActive
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  invite.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: invite.isActive
                        ? const Color(0xFF059669)
                        : EkaadhColors.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${invite.quantity} × ${invite.ticketTypeName ?? l10n.t('ticket_singular')} · ${invite.deliveryLabel(l10n.t)}',
            style: const TextStyle(fontSize: 12, color: EkaadhColors.soft),
          ),
          if (invite.invitationUrl != null) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                Clipboard.setData(ClipboardData(text: invite.invitationUrl!));
                await EkaadhToast.success(context, message: l10n.t('invitation_link_copied'));
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.link_rounded,
                      size: 16,
                      color: EkaadhColors.brand,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        invite.invitationUrl!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: EkaadhColors.brand,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: EkaadhColors.soft,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (invite.isActive) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _ActionChip(
                  label: l10n.t('resend'),
                  onTap: () => _resend(invite),
                ),
                const SizedBox(width: 6),
                _ActionChip(
                  label: l10n.t('revoke'),
                  danger: true,
                  onTap: () => _revoke(invite),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: danger ? const Color(0xFFFEF2F2) : const Color(0xFFF8F9FC),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: danger ? EkaadhColors.danger : EkaadhColors.dark,
            ),
          ),
        ),
      ),
    );
  }
}
