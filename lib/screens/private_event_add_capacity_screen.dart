import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/locale_scope.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/models/private_event_model.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/services/private_event_service.dart';
import 'package:ekaadh_mobile/screens/private_event_pay_screen.dart';
import 'package:ekaadh_mobile/widgets/design_network_image.dart';

class PrivateEventAddCapacityScreen extends StatefulWidget {
  const PrivateEventAddCapacityScreen({
    super.key,
    required this.auth,
    required this.event,
  });

  final AuthService auth;
  final PrivateEventModel event;

  @override
  State<PrivateEventAddCapacityScreen> createState() =>
      _PrivateEventAddCapacityScreenState();
}

class _PrivateEventAddCapacityScreenState
    extends State<PrivateEventAddCapacityScreen> {
  late final PrivateEventService _service;
  int _qty = 10;
  double _unit = 5;
  double _fee = 1;
  int _max = 500;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  String? get _thumb =>
      widget.event.design?.previewImageUrl ?? widget.event.coverImage;

  @override
  void initState() {
    super.initState();
    _service = PrivateEventService(token: widget.auth.token!);
    _unit = widget.event.ticketTypes.isNotEmpty
        ? widget.event.ticketTypes.first.price
        : 5;
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    try {
      final meta = await _service.meta();
      if (!mounted) return;
      setState(() {
        _fee = meta.serviceFee;
        _max = meta.maxTickets;
        if (widget.event.ticketTypes.isEmpty) {
          _unit = meta.unitPrice;
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await _service.addTickets(
        eventId: widget.event.id,
        quantity: _qty,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PrivateEventPayScreen(
            auth: widget.auth,
            eventId: result.event.id,
            initialOrder: result.order,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    final subtotal = _unit * _qty;
    final total = subtotal + _fee;
    final meta = [
      if (widget.event.eventDateLabel != null) widget.event.eventDateLabel!,
      if (widget.event.eventTimeLabel != null) widget.event.eventTimeLabel!,
      if (widget.event.venue != null) widget.event.venue!,
    ].join(' · ');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          l10n.t('buy_more_tickets'),
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
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _TicketHeader(
                  title: widget.event.title,
                  meta: meta,
                  thumb: _thumb,
                  trailing: Text(
                    '\$${_unit.toStringAsFixed(2)} ${l10n.t('each')}',
                    style: const TextStyle(
                      color: EkaadhColors.brand,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFEEF0F4)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.t('how_many_more_seats'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _QtyButton(
                            icon: Icons.remove_rounded,
                            onPressed: _qty > 1
                                ? () => setState(() => _qty--)
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            child: Text(
                              '$_qty',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          _QtyButton(
                            icon: Icons.add_rounded,
                            onPressed: _qty < _max
                                ? () => setState(() => _qty++)
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Divider(height: 1, color: Color(0xFFEEF0F4)),
                      const SizedBox(height: 14),
                      _priceRow(l10n.t('subtotal'), subtotal),
                      const SizedBox(height: 8),
                      _priceRow(l10n.t('service_fee'), _fee),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.t('total'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: EkaadhColors.brand,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
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
                const SizedBox(height: 22),
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
                      : Text(l10n.t('continue_to_payment')),
                ),
              ],
            ),
    );
  }

  Widget _priceRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: EkaadhColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onPressed == null
          ? const Color(0xFFF3F4F6)
          : EkaadhColors.brandLight,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: onPressed == null ? EkaadhColors.soft : EkaadhColors.brand,
          ),
        ),
      ),
    );
  }
}

class _TicketHeader extends StatelessWidget {
  const _TicketHeader({
    required this.title,
    required this.meta,
    required this.thumb,
    this.trailing,
  });

  final String title;
  final String meta;
  final String? thumb;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    height: 1.25,
                    letterSpacing: -0.2,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
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
                if (trailing != null) ...[
                  const SizedBox(height: 6),
                  trailing!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
