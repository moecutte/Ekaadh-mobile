import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/models/private_event_model.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/services/private_event_service.dart';
import 'package:ekaadh_mobile/screens/private_event_pay_screen.dart';
import 'package:ekaadh_mobile/widgets/design_network_image.dart';
import 'package:ekaadh_mobile/widgets/invitation_overlay_preview.dart';

class PrivateEventCreateScreen extends StatefulWidget {
  const PrivateEventCreateScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<PrivateEventCreateScreen> createState() => _PrivateEventCreateScreenState();
}

class _PrivateEventCreateScreenState extends State<PrivateEventCreateScreen> {
  static const _stepLabels = ['Event info', 'Design', 'Invitation text', 'Payment'];

  late final PrivateEventService _service;
  final _pageController = PageController();
  final _description = TextEditingController();
  final _venue = TextEditingController();
  final _ticketLabel = TextEditingController(text: 'Invitation');
  final Map<String, TextEditingController> _fieldControllers = {};
  final Map<String, String> _fieldValues = {};

  PrivateEventMeta? _meta;
  String _designId = '';
  int? _categoryId;
  DateTime? _date;
  TimeOfDay _time = const TimeOfDay(hour: 18, minute: 0);
  int _qty = 20;
  int _step = 0;
  bool _loadingMeta = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = PrivateEventService(token: widget.auth.token!);
    _loadMeta();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _description.dispose();
    _venue.dispose();
    _ticketLabel.dispose();
    for (final c in _fieldControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadMeta() async {
    try {
      final meta = await _service.meta();
      if (!mounted) return;
      setState(() {
        _meta = meta;
        _categoryId = meta.categories.isNotEmpty ? meta.categories.first.id : null;
        _designId = '';
        _loadingMeta = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loadingMeta = false;
      });
    }
  }

  TicketDesignOption? get _selectedDesign {
    final meta = _meta;
    if (meta == null || _designId.isEmpty) return null;
    for (final d in meta.designsForCategory(_categoryId)) {
      if (d.id == _designId) return d;
    }
    return null;
  }

  bool get _isPremium => _selectedDesign?.isPremium ?? false;

  void _onCategoryChanged(int? v) {
    setState(() {
      _categoryId = v;
      _designId = '';
    });
    _clearFieldControllers();
  }

  void _clearFieldControllers() {
    for (final c in _fieldControllers.values) {
      c.dispose();
    }
    _fieldControllers.clear();
    _fieldValues.clear();
  }

  void _selectDesign(String id) {
    setState(() => _designId = id);
    _seedFieldDefaults();
    _syncFieldControllers();
    _applyBasicsToFieldValues();
  }

  void _seedFieldDefaults() {
    final design = _selectedDesign;
    if (design == null) return;
    for (final field in design.buyerFields) {
      final current = _fieldValues[field.fieldKey];
      if (current == null || current.trim().isEmpty) {
        _fieldValues[field.fieldKey] = field.defaultText ?? '';
      }
    }
  }

  void _syncFieldControllers() {
    final design = _selectedDesign;
    final keys = design?.buyerFields.map((f) => f.fieldKey).toSet() ?? {};

    for (final key in _fieldControllers.keys.toList()) {
      if (!keys.contains(key)) {
        _fieldControllers[key]!.dispose();
        _fieldControllers.remove(key);
        _fieldValues.remove(key);
      }
    }

    for (final field in design?.buyerFields ?? const <InvitationDesignFieldOption>[]) {
      if (!_fieldControllers.containsKey(field.fieldKey)) {
        final controller = TextEditingController(
          text: _fieldValues[field.fieldKey] ?? field.defaultText ?? '',
        );
        controller.addListener(() {
          _fieldValues[field.fieldKey] = controller.text;
          setState(() {});
        });
        _fieldControllers[field.fieldKey] = controller;
        _fieldValues[field.fieldKey] = controller.text;
      }
    }
  }

  void _applyBasicsToFieldValues() {
    final design = _selectedDesign;
    if (design == null) return;

    final dateStr = _date != null ? _fmtDate(_date!) : '';
    final venueStr = _venue.text.trim();
    final monthName = _date != null ? _monthName(_date!.month) : '';
    final day = _date != null ? '${_date!.day}' : '';
    final year = _date != null ? '${_date!.year}' : '';
    final timeLabel = _fmtTimeLabel(_time);

    for (final field in design.valueFields) {
      final key = field.fieldKey.toLowerCase();
      final label = field.label.toLowerCase();
      final sample = (field.defaultText ?? '').trim();
      final looksLikeTime = field.fieldType == 'date_time' ||
          key == 'event_time' ||
          key == 'date_time' ||
          key.contains('time') ||
          label == 'time' ||
          label.contains('time') ||
          RegExp(r'^\d{1,2}:\d{2}(\s*[ap]m)?$', caseSensitive: false)
              .hasMatch(sample);

      String? value;
      if (field.fieldType == 'date_month' && monthName.isNotEmpty) {
        value = monthName;
      } else if (field.fieldType == 'date_day' && day.isNotEmpty) {
        value = day;
      } else if (field.fieldType == 'date_year' && year.isNotEmpty) {
        value = year;
      } else if (looksLikeTime && timeLabel.isNotEmpty) {
        value = timeLabel;
      } else if ((key == 'event_date' || label == 'date') && dateStr.isNotEmpty) {
        value = dateStr;
      } else if ((key.contains('venue') ||
              key.contains('location') ||
              label.contains('venue')) &&
          venueStr.isNotEmpty) {
        value = venueStr;
      }
      if (value == null) continue;
      _fieldValues[field.fieldKey] = value;
      final controller = _fieldControllers[field.fieldKey];
      if (controller != null) {
        controller.text = value;
      }
    }
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    if (month < 1 || month > 12) return '';
    return names[month - 1];
  }

  String _fmtTimeLabel(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  double get _unitNow {
    final design = _selectedDesign;
    if (design?.unitPrice != null) return design!.unitPrice!;
    final meta = _meta;
    if (meta == null) return 0;
    return meta.unitPrice + (_isPremium ? meta.premiumDesignSurcharge : 0);
  }

  double get _subtotal => _unitNow * _qty;
  double get _total => _subtotal + (_meta?.serviceFee ?? 0);

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _applyBasicsToFieldValues();
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() {
        _time = picked;
        _applyBasicsToFieldValues();
      });
    }
  }

  TextInputType _keyboardFor(InvitationDesignFieldOption field) {
    if (field.fieldType == 'textarea') return TextInputType.multiline;
    final key = field.fieldKey.toLowerCase();
    if (key.contains('date')) return TextInputType.datetime;
    return TextInputType.text;
  }

  bool _validateStep(int step) {
    setState(() => _error = null);
    switch (step) {
      case 0:
        if (_categoryId == null) {
          setState(() => _error = 'Choose a category.');
          return false;
        }
        if (_description.text.trim().isEmpty) {
          setState(() => _error = 'Enter a description.');
          return false;
        }
        if (_date == null) {
          setState(() => _error = 'Choose an event date.');
          return false;
        }
        if (_venue.text.trim().isEmpty) {
          setState(() => _error = 'Enter a venue.');
          return false;
        }
        return true;
      case 1:
        if (_designId.isEmpty || _selectedDesign == null) {
          setState(() => _error = 'Choose an invitation design.');
          return false;
        }
        _seedFieldDefaults();
        _syncFieldControllers();
        _applyBasicsToFieldValues();
        return true;
      case 2:
        final design = _selectedDesign;
        if (design == null) {
          setState(() => _error = 'Choose an invitation design.');
          return false;
        }
        for (final field in design.buyerFields) {
          final value =
              (_fieldControllers[field.fieldKey]?.text ?? _fieldValues[field.fieldKey] ?? '').trim();
          if (field.isRequired && value.isEmpty) {
            setState(() => _error = '${field.label} is required.');
            return false;
          }
        }
        return true;
      default:
        return true;
    }
  }

  void _goToStep(int step) {
    if (step < 0 || step > 3) return;
    setState(() {
      _step = step;
      _error = null;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    if (!_validateStep(_step)) return;
    _goToStep(_step + 1);
  }

  void _backStep() {
    if (_step == 0) return;
    setState(() => _error = null);
    _goToStep(_step - 1);
  }

  Future<void> _submit() async {
    if (!_validateStep(2)) {
      _goToStep(2);
      return;
    }

    final design = _selectedDesign;
    if (design == null || design.invitationDesignId == null) {
      setState(() => _error = 'Choose an invitation design.');
      return;
    }

    final fieldValues = <String, String>{};
    for (final field in design.valueFields) {
      final value =
          (_fieldControllers[field.fieldKey]?.text ?? _fieldValues[field.fieldKey] ?? '').trim();
      if (value.isNotEmpty) {
        fieldValues[field.fieldKey] = value;
      } else if ((field.defaultText ?? '').trim().isNotEmpty) {
        fieldValues[field.fieldKey] = field.defaultText!.trim();
      }
    }
    if (_date != null) {
      fieldValues['event_date'] = _fmtDate(_date!);
    }
    fieldValues['event_time'] = _fmtTime(_time);

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final result = await _service.create(
        description: _description.text.trim(),
        quantity: _qty,
        ticketLabel: _ticketLabel.text.trim(),
        ticketDesign: _designId,
        privateEventCategoryId: _categoryId!,
        invitationDesignId: design.invitationDesignId!,
        invitationFieldValues: fieldValues.isEmpty ? null : fieldValues,
        eventDate: _date != null ? _fmtDate(_date!) : null,
        eventTime: _fmtTime(_time),
      );
      if (!mounted) return;
      setState(() => _saving = false);
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PrivateEventPayScreen(
            auth: widget.auth,
            eventId: result.event.id,
            initialOrder: result.order,
          ),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: EkaadhColors.dark,
            letterSpacing: -0.1,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _stepLabels[_step],
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
            Text(
              'Step ${_step + 1} of 4',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: EkaadhColors.muted,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: EkaadhColors.dark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _backStep,
              )
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: _loadingMeta
          ? const Center(child: CircularProgressIndicator(color: EkaadhColors.brand))
          : Column(
              children: [
                _stepIndicator(),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Container(
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
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _step = i),
                    children: [
                      _stepEventInfo(),
                      _stepDesign(),
                      _stepInvitationText(),
                      _stepPayment(),
                    ],
                  ),
                ),
                _bottomBar(),
              ],
            ),
    );
  }

  Widget _stepIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: List.generate(4, (i) {
          final active = i == _step;
          final done = i < _step;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 3 ? 6 : 0),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 3,
                    decoration: BoxDecoration(
                      color: active || done
                          ? EkaadhColors.brand
                          : const Color(0xFFE8EAF0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _stepLabels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      color: active ? EkaadhColors.brand : EkaadhColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _bottomBar() {
    final isLast = _step == 3;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8EAF0))),
      ),
      child: Row(
        children: [
          if (_step > 0)
            OutlinedButton(
              onPressed: _saving ? null : _backStep,
              style: OutlinedButton.styleFrom(
                foregroundColor: EkaadhColors.dark,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                side: const BorderSide(color: EkaadhColors.fieldBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          if (_step > 0) const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: _saving
                  ? null
                  : isLast
                      ? _submit
                      : _nextStep,
              style: FilledButton.styleFrom(
                backgroundColor: EkaadhColors.brand,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isLast
                          ? 'Continue to payment · \$${_total.toStringAsFixed(2)}'
                          : 'Continue',
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepEventInfo() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        const Text(
          'Tell us about your event. Date and venue will be applied to your invitation design.',
          style: TextStyle(color: EkaadhColors.muted, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 16),
        _card([
          _label('Category *'),
          if (_meta != null && _meta!.categories.isNotEmpty)
            DropdownButtonFormField<int>(
              key: ValueKey(_categoryId ?? 'category'),
              initialValue: _categoryId,
              decoration: EkaadhFields.decoration(hintText: 'Select category'),
              items: _meta!.categories
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: _onCategoryChanged,
            ),
          const SizedBox(height: 12),
          _label('Description *'),
          TextField(
            controller: _description,
            maxLines: 4,
            decoration: EkaadhFields.decoration(hintText: 'About your event'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Date *'),
                    OutlinedButton(
                      onPressed: _pickDate,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        backgroundColor: EkaadhColors.surface,
                        side: const BorderSide(color: EkaadhColors.fieldBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _date == null ? 'Pick date' : _fmtDate(_date!),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Time *'),
                    OutlinedButton(
                      onPressed: _pickTime,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        backgroundColor: EkaadhColors.surface,
                        side: const BorderSide(color: EkaadhColors.fieldBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _fmtTimeLabel(_time),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _label('Venue *'),
          TextField(
            controller: _venue,
            decoration: EkaadhFields.decoration(hintText: 'Venue name'),
          ),
        ]),
      ],
    );
  }

  Widget _stepDesign() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        const Text(
          'Choose an invitation design for your category.',
          style: TextStyle(color: EkaadhColors.muted, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 16),
        if (_meta != null) ...[
          _card([
            if (_meta!.designsForCategory(_categoryId).isEmpty)
              const Text(
                'No designs for this category yet. Go back and pick another category, or ask an admin to upload designs.',
                style: TextStyle(color: EkaadhColors.muted, fontSize: 13),
              )
            else ...[
              Text(
                'Premium adds \$${_meta!.premiumDesignSurcharge.toStringAsFixed(2)}/ticket.',
                style: const TextStyle(color: EkaadhColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 14),
              if (_meta!.standardForCategory(_categoryId).isNotEmpty) ...[
                _label('Standard'),
                const SizedBox(height: 8),
                _designGrid(_meta!.standardForCategory(_categoryId)),
              ],
              if (_meta!.premiumForCategory(_categoryId).isNotEmpty) ...[
                const SizedBox(height: 14),
                _label('Premium'),
                const SizedBox(height: 8),
                _designGrid(_meta!.premiumForCategory(_categoryId)),
              ],
            ],
          ]),
        ],
      ],
    );
  }

  Widget _stepInvitationText() {
    final design = _selectedDesign;
    if (design == null) {
      return const Center(
        child: Text('Select a design first.', style: TextStyle(color: EkaadhColors.muted)),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        const Text(
          'Preview your invitation and edit the text shown on the design.',
          style: TextStyle(color: EkaadhColors.muted, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 16),
        _card([
          Row(
            children: [
              const Text('Live preview', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: EkaadhColors.brandLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  design.isPremium ? 'Premium' : 'Standard',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: EkaadhColors.brand),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InvitationOverlayPreview(design: design, fieldValues: _fieldValues),
        ]),
        if (design.buyerFields.isNotEmpty) ...[
          const SizedBox(height: 14),
          _card([
            const Text(
              'Invitation text',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
            const SizedBox(height: 4),
            const Text(
              'Change sample text for each field on the card. Date and time parts fill from step 1.',
              style: TextStyle(color: EkaadhColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            for (final field in design.buyerFields) ...[
              _label('${field.label}${field.isRequired ? ' *' : ''}'),
              TextField(
                controller: _fieldControllers[field.fieldKey],
                keyboardType: _keyboardFor(field),
                maxLines: field.fieldType == 'textarea' ? 3 : 1,
                decoration: EkaadhFields.decoration(
                  hintText: field.placeholder ?? field.defaultText ?? '',
                ),
              ),
              const SizedBox(height: 10),
            ],
          ]),
        ] else if (design.autoDateFields.isNotEmpty) ...[
          const SizedBox(height: 14),
          _card([
            const Text(
              'Date & time on the card',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
            const SizedBox(height: 6),
            const Text(
              'Month, day, year, and time update automatically from the event date and time you chose.',
              style: TextStyle(color: EkaadhColors.muted, fontSize: 12),
            ),
          ]),
        ],
      ],
    );
  }

  Widget _stepPayment() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        const Text(
          'Set how many tickets to buy and review pricing before payment.',
          style: TextStyle(color: EkaadhColors.muted, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 16),
        _card([
          _label('Ticket quantity'),
          Row(
            children: [
              IconButton(
                onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: EkaadhColors.brand,
              ),
              Text('$_qty', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              IconButton(
                onPressed: _meta != null && _qty < _meta!.maxTickets
                    ? () => setState(() => _qty++)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                color: EkaadhColors.brand,
              ),
              const Spacer(),
              Text(
                '\$${_unitNow.toStringAsFixed(2)} each',
                style: const TextStyle(color: EkaadhColors.muted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _label('Ticket label'),
          TextField(
            controller: _ticketLabel,
            decoration: EkaadhFields.decoration(hintText: 'Invitation'),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: EkaadhColors.brandLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _totalRow('Price / ticket', _unitNow),
                _totalRow('Subtotal', _subtotal),
                _totalRow('Service fee', _meta?.serviceFee ?? 0),
                const Divider(height: 18),
                _totalRow('Total due', _total, bold: true),
              ],
            ),
          ),
        ]),
      ],
    );
  }

  Widget _designGrid(List<TicketDesignOption> designs) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 3 / 4,
      ),
      itemCount: designs.length,
      itemBuilder: (context, index) => _designTile(designs[index]),
    );
  }

  Widget _designTile(TicketDesignOption d) {
    final selected = _designId == d.id;
    final card = _parseColor(d.cardBg);

    return InkWell(
      onTap: () => _selectDesign(d.id),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? (d.isPremium ? const Color(0xFFF59E0B) : EkaadhColors.brand)
                : EkaadhColors.fieldBorder,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: DesignNetworkImage(
                    url: d.previewImageUrl,
                    fallbackColor: card,
                  ),
                ),
                if (d.isPremium)
                  Container(
                    color: const Color(0xFFFFFBEB),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '+\$${_meta!.premiumDesignSurcharge.toStringAsFixed(0)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFB45309),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            if (selected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: EkaadhColors.brand,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    var h = hex.replaceFirst('#', '');
    if (h.length == 6) h = 'FF$h';
    return Color(int.parse(h, radix: 16));
  }

  Widget _totalRow(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
              color: bold ? EkaadhColors.dark : EkaadhColors.muted,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color: bold ? EkaadhColors.brand : EkaadhColors.dark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF0F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
