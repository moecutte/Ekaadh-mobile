import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/locale_scope.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/models/private_event_model.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/services/private_event_service.dart';
import 'package:ekaadh_mobile/widgets/design_network_image.dart';
import 'package:ekaadh_mobile/widgets/phone_number_field.dart';
import 'package:ekaadh_mobile/core/user_facing_error.dart';
import 'package:ekaadh_mobile/widgets/ekaadh_toast.dart';

class _GuestRow {
  final name = TextEditingController();
  final phone = TextEditingController();
  int quantity = 1;
  late int ticketTypeId;

  void dispose() {
    name.dispose();
    phone.dispose();
  }
}

class PrivateEventSendInvitesScreen extends StatefulWidget {
  const PrivateEventSendInvitesScreen({
    super.key,
    required this.auth,
    required this.event,
  });

  final AuthService auth;
  final PrivateEventModel event;

  @override
  State<PrivateEventSendInvitesScreen> createState() =>
      _PrivateEventSendInvitesScreenState();
}

class _PrivateEventSendInvitesScreenState
    extends State<PrivateEventSendInvitesScreen> {
  late final PrivateEventService _service;
  final List<_GuestRow> _rows = [];
  bool _saving = false;
  String? _error;
  String _channel = 'whatsapp';

  String? get _thumb =>
      widget.event.design?.previewImageUrl ?? widget.event.coverImage;

  @override
  void initState() {
    super.initState();
    _service = PrivateEventService(token: widget.auth.token!);
    _addRow();
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    final row = _GuestRow();
    row.ticketTypeId = widget.event.ticketTypes.isNotEmpty
        ? widget.event.ticketTypes.first.id
        : 0;
    setState(() => _rows.add(row));
  }

  void _removeRow(int i) {
    if (_rows.length <= 1) return;
    setState(() {
      _rows[i].dispose();
      _rows.removeAt(i);
    });
  }

  Future<void> _submit() async {
    final l10n = LocaleScope.of(context);
    final guests = <Map<String, dynamic>>[];
    for (var i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      if (!PhoneNumberField.hasLocalNumber(row.phone.text)) {
        setState(() => _error = '${l10n.t('guest_n')} ${i + 1}: ${l10n.t('guest_enter_phone')}');
        return;
      }
      if (row.ticketTypeId == 0) {
        setState(() => _error = '${l10n.t('guest_n')} ${i + 1}: ${l10n.t('guest_select_type')}');
        return;
      }
      guests.add({
        'name': row.name.text.trim().isEmpty ? null : row.name.text.trim(),
        'phone': PhoneNumberField.fullNumber(row.phone.text),
        'quantity': row.quantity,
        'ticket_type_id': row.ticketTypeId,
      });
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final created = await _service.sendInvitations(
        eventId: widget.event.id,
        guests: guests,
        channel: _channel,
      );
      if (!mounted) return;
      final l10n = LocaleScope.of(context);
      await EkaadhToast.success(
        context,
        message: '${l10n.t('sent_invitations')} $created ${l10n.t('invitations_count')}',
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = UserFacingError.message(e, t: LocaleScope.of(context).t);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    final meta = [
      if (widget.event.eventDateLabel != null) widget.event.eventDateLabel!,
      if (widget.event.eventTimeLabel != null) widget.event.eventTimeLabel!,
      if (widget.event.venue != null) widget.event.venue!,
    ].join(' · ');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          l10n.t('send_invitations'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        foregroundColor: EkaadhColors.dark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
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
                    child: _thumb != null
                        ? DesignNetworkImage(url: _thumb)
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
                        widget.event.title,
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
                        '${widget.event.remaining} ${l10n.t('seats_remaining')}',
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
          ),
          const SizedBox(height: 12),
          Text(
            l10n.t('guests_link_note'),
            style: const TextStyle(
              color: EkaadhColors.muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_rows.length, (i) => _guestCard(i)),
          OutlinedButton.icon(
            onPressed: _addRow,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l10n.t('add_guest')),
            style: OutlinedButton.styleFrom(
              foregroundColor: EkaadhColors.brand,
              side: const BorderSide(color: Color(0xFFD5DAE8)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: EkaadhColors.danger,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            l10n.t('invite_send_via'),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.t('invite_channel_hint'),
            style: const TextStyle(
              color: EkaadhColors.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ChannelChoice(
                  label: l10n.t('invite_channel_whatsapp'),
                  icon: Icons.chat_rounded,
                  selected: _channel == 'whatsapp',
                  onTap: () => setState(() => _channel = 'whatsapp'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ChannelChoice(
                  label: l10n.t('invite_channel_sms'),
                  icon: Icons.sms_rounded,
                  selected: _channel == 'sms',
                  onTap: () => setState(() => _channel = 'sms'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _saving ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: EkaadhColors.brand,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(l10n.t('issue_send')),
          ),
        ],
      ),
    );
  }

  Widget _guestCard(int index) {
    final l10n = LocaleScope.of(context);
    final row = _rows[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: EkaadhColors.brandLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: EkaadhColors.brand,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${l10n.t('guest_n')} ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (_rows.length > 1)
                IconButton(
                  onPressed: () => _removeRow(index),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: EkaadhColors.danger,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: row.name,
            decoration: EkaadhFields.decoration(hintText: l10n.t('name_optional')),
          ),
          const SizedBox(height: 10),
          PhoneNumberField(controller: row.phone),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: ValueKey('type-$index-${row.ticketTypeId}'),
                  initialValue: row.ticketTypeId == 0 &&
                          widget.event.ticketTypes.isNotEmpty
                      ? widget.event.ticketTypes.first.id
                      : row.ticketTypeId,
                  decoration: EkaadhFields.decoration(hintText: l10n.t('type')),
                  items: widget.event.ticketTypes
                      .map(
                        (t) => DropdownMenuItem(
                          value: t.id,
                          child: Text('${t.name} (${t.remaining})'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => row.ticketTypeId = v);
                  },
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 72,
                child: TextFormField(
                  initialValue: '${row.quantity}',
                  decoration: EkaadhFields.decoration(hintText: l10n.t('qty')),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final n = int.tryParse(v) ?? 1;
                    row.quantity = n < 1 ? 1 : n;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChannelChoice extends StatelessWidget {
  const _ChannelChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? EkaadhColors.brandLight : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? EkaadhColors.brand : const Color(0xFFEEF0F4),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? EkaadhColors.brand : EkaadhColors.muted,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: selected ? EkaadhColors.brand : EkaadhColors.dark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
