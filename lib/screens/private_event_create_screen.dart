import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/locale_scope.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/models/private_event_model.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/services/private_event_service.dart';
import 'package:ekaadh_mobile/screens/private_event_pay_screen.dart';
import 'package:ekaadh_mobile/widgets/ekaadh_date_picker.dart';
import 'package:ekaadh_mobile/widgets/ekaadh_wizard.dart';
import 'package:ekaadh_mobile/widgets/invitation_html_preview.dart';
import 'package:ekaadh_mobile/core/user_facing_error.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class PrivateEventCreateScreen extends StatefulWidget {
  const PrivateEventCreateScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<PrivateEventCreateScreen> createState() => _PrivateEventCreateScreenState();
}

class _PrivateEventCreateScreenState extends State<PrivateEventCreateScreen> {
  List<String> _stepLabels(BuildContext context) {
    final l10n = LocaleScope.of(context);
    return [
      l10n.t('event_info'),
      l10n.t('design'),
      l10n.t('invitation_text'),
      l10n.t('payment'),
    ];
  }

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
  final Map<int, String> _pickerHtml = {};
  String? _liveHtml;
  Timer? _previewDebounce;

  @override
  void initState() {
    super.initState();
    _service = PrivateEventService(token: widget.auth.token!);
    _loadMeta();
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
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
      _ensurePickerHtml();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = UserFacingError.message(e, t: LocaleScope.of(context).t);
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
      _liveHtml = null;
    });
    _clearFieldControllers();
    _ensurePickerHtml();
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
    _queueLivePreview();
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
          _queueLivePreview();
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
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

  Map<String, String> get _previewFields {
    final out = <String, String>{..._fieldValues};
    for (final entry in _fieldControllers.entries) {
      out[entry.key] = entry.value.text;
    }
    return out;
  }

  Future<void> _ensurePickerHtml() async {
    final designs = _meta?.designsForCategory(_categoryId) ?? [];
    final pending = <int, Future<String>>{};
    for (final design in designs) {
      final id = design.invitationDesignId;
      if (id == null || _pickerHtml.containsKey(id) || pending.containsKey(id)) {
        continue;
      }
      pending[id] = _service.previewHtml(
        invitationDesignId: id,
        eventDate: _date != null ? _fmtDate(_date!) : null,
        eventTime: _fmtTime(_time),
        venue: _venue.text.trim(),
        envelope: false,
        compact: true,
      );
    }
    if (pending.isEmpty) return;

    final loaded = <int, String>{};
    await Future.wait(pending.entries.map((entry) async {
      try {
        loaded[entry.key] = await entry.value;
      } catch (_) {}
    }));
    if (!mounted || loaded.isEmpty) return;
    setState(() => _pickerHtml.addAll(loaded));
  }

  void _queueLivePreview() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 350), _loadLivePreview);
  }

  Future<void> _loadLivePreview() async {
    final id = _selectedDesign?.invitationDesignId;
    if (id == null) return;
    try {
      final html = await _service.previewHtml(
        invitationDesignId: id,
        fields: _previewFields,
        eventDate: _date != null ? _fmtDate(_date!) : null,
        eventTime: _fmtTime(_time),
        venue: _venue.text.trim(),
        envelope: true,
        autoOpen: true,
      );
      if (!mounted) return;
      setState(() => _liveHtml = html);
    } catch (_) {}
  }

  String _fmtDateDisplay(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${d.day} ${_monthName(d.month)} ${d.year}';
  }

  String get _categoryName {
    final id = _categoryId;
    final meta = _meta;
    if (id == null || meta == null) return '—';
    for (final c in meta.categories) {
      if (c.id == id) return c.name;
    }
    return '—';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showEkaadhDatePicker(
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
    final picked = await showEkaadhTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() {
        _time = picked;
        _applyBasicsToFieldValues();
      });
    }
  }

  Future<void> _pickCategory() async {
    final meta = _meta;
    if (meta == null || meta.categories.isEmpty) return;
    final picked = await showEkaadhOptionPicker<int>(
      context: context,
      title: LocaleScope.of(context).t('select_category'),
      selected: _categoryId,
      options: [
        for (final c in meta.categories) (c.id, c.name),
      ],
    );
    if (picked != null) _onCategoryChanged(picked);
  }

  TextInputType _keyboardFor(InvitationDesignFieldOption field) {
    if (field.fieldType == 'textarea') return TextInputType.multiline;
    final key = field.fieldKey.toLowerCase();
    if (key.contains('date')) return TextInputType.datetime;
    return TextInputType.text;
  }

  bool _validateStep(int step) {
    final l10n = LocaleScope.of(context);
    setState(() => _error = null);
    switch (step) {
      case 0:
        if (_categoryId == null) {
          setState(() => _error = l10n.t('choose_category'));
          return false;
        }
        if (_description.text.trim().isEmpty) {
          setState(() => _error = l10n.t('enter_description'));
          return false;
        }
        if (_date == null) {
          setState(() => _error = l10n.t('choose_event_date'));
          return false;
        }
        if (_venue.text.trim().isEmpty) {
          setState(() => _error = l10n.t('enter_venue'));
          return false;
        }
        return true;
      case 1:
        if (_designId.isEmpty || _selectedDesign == null) {
          setState(() => _error = l10n.t('choose_design'));
          return false;
        }
        _seedFieldDefaults();
        _syncFieldControllers();
        _applyBasicsToFieldValues();
        return true;
      case 2:
        final design = _selectedDesign;
        if (design == null) {
          setState(() => _error = l10n.t('choose_design'));
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
    if (step == 1) {
      _ensurePickerHtml();
    }
    if (step == 2 || step == 3) {
      _queueLivePreview();
    }
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
      setState(() => _error = LocaleScope.of(context).t('choose_design'));
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
        _error = UserFacingError.message(e, t: LocaleScope.of(context).t);
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

  static const _pagePad = EdgeInsets.fromLTRB(20, 4, 20, 24);

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    final isLast = _step == 3;
    return Scaffold(
      backgroundColor: EkaadhColors.surface,
      appBar: AppBar(
        title: Text(
          l10n.t('create_private_event'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        foregroundColor: EkaadhColors.dark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_step > 0) {
              _backStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _loadingMeta
          ? const Center(child: CircularProgressIndicator(color: EkaadhColors.brand))
          : Column(
              children: [
                ColoredBox(
                  color: Colors.white,
                  child: EkaadhWizardStepper(
                    labels: _stepLabels(context),
                    current: _step,
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
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
                EkaadhWizardFooter(
                  loading: _saving,
                  primaryLabel: isLast
                      ? '${l10n.t('proceed_to_payment')} · \$${_total.toStringAsFixed(2)}'
                      : l10n.t('next'),
                  onPrimary: isLast ? _submit : _nextStep,
                  onBack: () {
                    if (_step > 0) {
                      _backStep();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
    );
  }

  Widget _stepEventInfo() {
    final l10n = LocaleScope.of(context);
    return ListView(
      padding: _pagePad,
      children: [
        EkaadhWizardSection(
          title: l10n.t('event_details'),
          child: EkaadhWizardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(l10n.t('category_required')),
                if (_meta != null && _meta!.categories.isNotEmpty)
                  EkaadhWizardSelectField(
                    value: _categoryName == '—' ? null : _categoryName,
                    placeholder: l10n.t('select_category'),
                    onTap: _pickCategory,
                  ),
                const SizedBox(height: 16),
                _label(l10n.t('description_required')),
                TextField(
                  controller: _description,
                  maxLines: 4,
                  decoration: EkaadhFields.form(hintText: l10n.t('about_your_event')),
                ),
                const SizedBox(height: 16),
                _label(l10n.t('venue_required')),
                TextField(
                  controller: _venue,
                  decoration: EkaadhFields.form(hintText: l10n.t('venue_name')),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        EkaadhWizardSection(
          title: l10n.t('date_time_on_card'),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(l10n.t('date_required')),
                    EkaadhWizardIconField(
                      icon: Icons.calendar_today_outlined,
                      value: _date != null ? _fmtDateDisplay(_date!) : null,
                      placeholder: l10n.t('pick_date'),
                      onTap: _pickDate,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(l10n.t('time_required')),
                    EkaadhWizardIconField(
                      icon: Icons.schedule_rounded,
                      value: _fmtTimeLabel(_time),
                      placeholder: l10n.t('time_required'),
                      onTap: _pickTime,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepDesign() {
    final l10n = LocaleScope.of(context);
    final meta = _meta;
    return ListView(
      padding: _pagePad,
      children: [
        if (meta != null) ...[
          if (meta.standardForCategory(_categoryId).isNotEmpty) ...[
            EkaadhWizardSection(
              title: l10n.t('standard'),
              child: _designGrid(meta.standardForCategory(_categoryId)),
            ),
            const SizedBox(height: 22),
          ],
          if (meta.premiumForCategory(_categoryId).isNotEmpty)
            EkaadhWizardSection(
              title: l10n.t('premium'),
              trailing: Text(
                '${l10n.t('premium_adds')} \$${meta.premiumDesignSurcharge.toStringAsFixed(0)}${l10n.t('per_ticket')}',
                style: const TextStyle(
                  color: EkaadhColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: _designGrid(meta.premiumForCategory(_categoryId)),
            ),
          if (meta.designsForCategory(_categoryId).isEmpty)
            EkaadhWizardCard(
              child: Text(
                l10n.t('no_designs_category'),
                style: const TextStyle(color: EkaadhColors.muted, fontSize: 13),
              ),
            ),
        ],
      ],
    );
  }

  Widget _stepInvitationText() {
    final l10n = LocaleScope.of(context);
    final design = _selectedDesign;
    if (design == null) {
      return Center(
        child: Text(l10n.t('select_design_first'), style: const TextStyle(color: EkaadhColors.muted)),
      );
    }

    return ListView(
      padding: _pagePad,
      children: [
        EkaadhWizardSection(
          title: l10n.t('live_preview'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: EkaadhColors.brandLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              design.isPremium ? l10n.t('premium') : l10n.t('standard'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: EkaadhColors.brand,
              ),
            ),
          ),
          child: EkaadhWizardCard(
            elevated: true,
            child: InvitationDesignPreview(
              design: design,
              fieldValues: _previewFields,
              html: _liveHtml,
              includeQr: false,
            ),
          ),
        ),
        if (design.buyerFields.isNotEmpty) ...[
          const SizedBox(height: 22),
          EkaadhWizardSection(
            title: l10n.t('invitation_text'),
            child: EkaadhWizardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('invitation_text_hint'),
                    style: const TextStyle(color: EkaadhColors.muted, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  for (final field in design.buyerFields) ...[
                    _label('${field.label}${field.isRequired ? ' *' : ''}'),
                    TextField(
                      controller: _fieldControllers[field.fieldKey],
                      keyboardType: _keyboardFor(field),
                      maxLines: field.fieldType == 'textarea' ? 3 : 1,
                      decoration: EkaadhFields.form(
                        hintText: field.placeholder ?? field.defaultText ?? '',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ] else if (design.autoDateFields.isNotEmpty) ...[
          const SizedBox(height: 22),
          EkaadhWizardCard(
            child: Text(
              l10n.t('date_time_auto_hint'),
              style: const TextStyle(color: EkaadhColors.muted, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ],
    );
  }

  Widget _stepPayment() {
    final l10n = LocaleScope.of(context);
    final design = _selectedDesign;
    return ListView(
      padding: _pagePad,
      children: [
        if (design != null) ...[
          EkaadhWizardSection(
            title: l10n.t('live_preview'),
            child: EkaadhWizardCard(
              elevated: true,
              child: InvitationDesignPreview(
                design: design,
                fieldValues: _previewFields,
                html: _liveHtml,
                includeQr: false,
              ),
            ),
          ),
          const SizedBox(height: 22),
        ],
        EkaadhWizardSection(
          title: l10n.t('review_settings'),
          child: EkaadhWizardCard(
            child: Column(
              children: [
                EkaadhWizardSummaryRow(label: l10n.t('category_required'), value: _categoryName),
                const Divider(height: 1, color: Color(0xFFEEF0F4)),
                EkaadhWizardSummaryRow(
                  label: l10n.t('date_required'),
                  value: _date != null ? _fmtDateDisplay(_date!) : '—',
                ),
                const Divider(height: 1, color: Color(0xFFEEF0F4)),
                EkaadhWizardSummaryRow(label: l10n.t('time_required'), value: _fmtTimeLabel(_time)),
                const Divider(height: 1, color: Color(0xFFEEF0F4)),
                EkaadhWizardSummaryRow(
                  label: l10n.t('venue_required'),
                  value: _venue.text.trim().isEmpty ? '—' : _venue.text.trim(),
                ),
                const Divider(height: 1, color: Color(0xFFEEF0F4)),
                EkaadhWizardSummaryRow(
                  label: l10n.t('design'),
                  value: design?.name.isNotEmpty == true
                      ? design!.name
                      : (design?.isPremium == true ? l10n.t('premium') : l10n.t('standard')),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        EkaadhWizardSection(
          title: l10n.t('ticket_settings'),
          trailing: Text(
            '\$${_unitNow.toStringAsFixed(2)} ${l10n.t('each')}',
            style: const TextStyle(
              color: EkaadhColors.brand,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: EkaadhWizardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(l10n.t('ticket_quantity')),
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: EkaadhColors.fieldBorder),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                        icon: const Icon(Icons.remove_rounded),
                        color: EkaadhColors.brand,
                      ),
                      Expanded(
                        child: Text(
                          '$_qty',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        onPressed: _meta != null && _qty < _meta!.maxTickets
                            ? () => setState(() => _qty++)
                            : null,
                        icon: const Icon(Icons.add_rounded),
                        color: EkaadhColors.brand,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _label(l10n.t('ticket_label')),
                TextField(
                  controller: _ticketLabel,
                  decoration: EkaadhFields.form(hintText: 'Invitation'),
                ),
                const SizedBox(height: 16),
                EkaadhWizardSummaryRow(
                  label: l10n.t('price_per_ticket'),
                  value: '\$${_unitNow.toStringAsFixed(2)}',
                ),
                const Divider(height: 1, color: Color(0xFFEEF0F4)),
                EkaadhWizardSummaryRow(
                  label: l10n.t('subtotal'),
                  value: '\$${_subtotal.toStringAsFixed(2)}',
                ),
                const Divider(height: 1, color: Color(0xFFEEF0F4)),
                EkaadhWizardSummaryRow(
                  label: l10n.t('service_fee'),
                  value: '\$${(_meta?.serviceFee ?? 0).toStringAsFixed(2)}',
                ),
                const Divider(height: 1, color: Color(0xFFEEF0F4)),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.t('total_due'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      Text(
                        '\$${_total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: EkaadhColors.brand,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _designGrid(List<TicketDesignOption> designs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 40;
        const gap = 10.0;
        final columns = designs.length == 1
            ? 1
            : (maxW >= 520 ? 3 : 2);
        final tileW = columns == 1
            ? (maxW * 0.72).clamp(160.0, 280.0)
            : (maxW - gap * (columns - 1)) / columns;
        final tileH = tileW * 4 / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final design in designs)
              SizedBox(
                width: tileW,
                height: tileH,
                child: _designTile(design),
              ),
          ],
        );
      },
    );
  }

  Widget _designTile(TicketDesignOption d) {
    final selected = _designId == d.id;
    final html = d.invitationDesignId == null ? null : _pickerHtml[d.invitationDesignId];

    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: InvitationDesignPreview(
                design: d,
                fieldValues: _previewFields,
                html: html,
                compact: true,
                includeQr: false,
              ),
            ),
          ),
          Positioned.fill(
            child: PointerInterceptor(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () => _selectDesign(d.id),
                  borderRadius: BorderRadius.circular(14),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? EkaadhColors.brand : EkaadhColors.fieldBorder,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
          if (d.isPremium)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
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
              ),
            ),
          if (selected)
            Positioned(
              top: 6,
              right: 6,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: EkaadhColors.brand,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
