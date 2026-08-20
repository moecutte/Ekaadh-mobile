import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/locale_scope.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/widgets/ekaadh_wizard.dart';

String formatEkaadhDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y.$m.$d';
}

Future<DateTime?> showEkaadhDatePicker({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final first = firstDate ?? DateTime(today.year - 5);
  final last = lastDate ?? DateTime(today.year + 5, 12, 31);
  var initial = initialDate ?? today;
  if (initial.isBefore(first)) initial = first;
  if (initial.isAfter(last)) initial = last;

  return showDialog<DateTime>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.32),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: _EkaadhDatePickerPopup(
        initialDate: DateTime(initial.year, initial.month, initial.day),
        firstDate: DateTime(first.year, first.month, first.day),
        lastDate: DateTime(last.year, last.month, last.day),
      ),
    ),
  );
}

Future<TimeOfDay?> showEkaadhTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  return showDialog<TimeOfDay>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.32),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: _EkaadhTimePickerPopup(initialTime: initialTime),
    ),
  );
}

class EkaadhDateField extends StatelessWidget {
  const EkaadhDateField({
    super.key,
    required this.value,
    required this.onTap,
    this.placeholder,
  });

  final DateTime? value;
  final VoidCallback onTap;
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    return EkaadhWizardIconField(
      icon: Icons.calendar_today_outlined,
      value: value != null ? formatEkaadhDate(value!) : null,
      placeholder: placeholder ?? '',
      onTap: onTap,
    );
  }
}

class _EkaadhDatePickerPopup extends StatefulWidget {
  const _EkaadhDatePickerPopup({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_EkaadhDatePickerPopup> createState() => _EkaadhDatePickerPopupState();
}

class _EkaadhDatePickerPopupState extends State<_EkaadhDatePickerPopup> {
  late DateTime _selected;
  late DateTime _visibleMonth;

  static const _enMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _soMonths = [
    'Jannaayo', 'Febraayo', 'Maarso', 'Abriil', 'Maajo', 'Juun',
    'Luuliyo', 'Agoosto', 'Sebtembar', 'Oktoobar', 'Nofembar', 'Disembar',
  ];
  static const _enDays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
  static const _soDays = ['Ax', 'Is', 'Tl', 'Ar', 'Kh', 'Jm', 'Sb'];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
    _visibleMonth = DateTime(_selected.year, _selected.month);
  }

  bool get _isSomali => LocaleScope.maybeOf(context)?.isSomali ?? false;

  String get _monthTitle {
    final months = _isSomali ? _soMonths : _enMonths;
    return '${months[_visibleMonth.month - 1]} ${_visibleMonth.year}';
  }

  DateTime get _monthStart =>
      DateTime(_visibleMonth.year, _visibleMonth.month, 1);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _inRange(DateTime d) =>
      !d.isBefore(widget.firstDate) && !d.isAfter(widget.lastDate);

  bool get _canPrev {
    final prev = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
    final lastOfPrev = DateTime(prev.year, prev.month + 1, 0);
    return !lastOfPrev.isBefore(widget.firstDate);
  }

  bool get _canNext {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    return !next.isAfter(widget.lastDate);
  }

  void _shiftMonth(int delta) {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
    if (delta < 0 && !_canPrev) return;
    if (delta > 0 && !_canNext) return;
    setState(() => _visibleMonth = next);
  }

  void _select(DateTime day) {
    if (!_inRange(day)) return;
    setState(() {
      _selected = day;
      _visibleMonth = DateTime(day.year, day.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    return EkaadhPickerShell(
      title: l10n.t('select_date'),
      confirmLabel: l10n.t('confirm'),
      onConfirm: () => Navigator.of(context).pop(_selected),
      onCancel: () => Navigator.of(context).pop(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(),
            const SizedBox(height: 12),
            _weekdayRow(),
            const SizedBox(height: 6),
            _dayGrid(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        _chevron(
          Icons.chevron_left_rounded,
          _canPrev ? () => _shiftMonth(-1) : null,
        ),
        Expanded(
          child: Text(
            _monthTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: EkaadhColors.dark,
            ),
          ),
        ),
        _chevron(
          Icons.chevron_right_rounded,
          _canNext ? () => _shiftMonth(1) : null,
        ),
      ],
    );
  }

  Widget _chevron(IconData icon, VoidCallback? onTap) {
    return Material(
      color: EkaadhColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            color: onTap == null ? EkaadhColors.hint : EkaadhColors.brand,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _weekdayRow() {
    final days = _isSomali ? _soDays : _enDays;
    return Row(
      children: [
        for (final d in days)
          Expanded(
            child: Text(
              d,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: EkaadhColors.muted,
              ),
            ),
          ),
      ],
    );
  }

  Widget _dayGrid() {
    final start = _monthStart;
    final leading = start.weekday % 7;
    final gridStart = start.subtract(Duration(days: leading));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      children: List.generate(6, (row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: List.generate(7, (col) {
              final day = gridStart.add(Duration(days: row * 7 + col));
              return Expanded(child: _dayCell(day, today));
            }),
          ),
        );
      }),
    );
  }

  Widget _dayCell(DateTime day, DateTime today) {
    final inMonth = day.month == _visibleMonth.month;
    final selected = _sameDay(day, _selected);
    final isToday = _sameDay(day, today);
    final enabled = _inRange(day);

    Color textColor;
    if (!enabled) {
      textColor = EkaadhColors.hint;
    } else if (selected) {
      textColor = Colors.white;
    } else if (!inMonth) {
      textColor = EkaadhColors.hint;
    } else if (isToday) {
      textColor = EkaadhColors.brand;
    } else {
      textColor = EkaadhColors.dark;
    }

    return GestureDetector(
      onTap: enabled ? () => _select(day) : null,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected
                ? EkaadhColors.brand
                : (isToday && inMonth
                    ? EkaadhColors.brandLight
                    : Colors.transparent),
          ),
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 14,
              fontWeight:
                  selected || isToday ? FontWeight.w800 : FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _EkaadhTimePickerPopup extends StatefulWidget {
  const _EkaadhTimePickerPopup({required this.initialTime});

  final TimeOfDay initialTime;

  @override
  State<_EkaadhTimePickerPopup> createState() => _EkaadhTimePickerPopupState();
}

class _EkaadhTimePickerPopupState extends State<_EkaadhTimePickerPopup> {
  late int _hour;
  late int _minute;
  late bool _pm;

  @override
  void initState() {
    super.initState();
    final t = widget.initialTime;
    _hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    _minute = t.minute;
    _pm = t.period == DayPeriod.pm;
  }

  TimeOfDay get _value {
    final hour24 = _pm
        ? (_hour == 12 ? 12 : _hour + 12)
        : (_hour == 12 ? 0 : _hour);
    return TimeOfDay(hour: hour24, minute: _minute);
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  void _stepHour(int delta) {
    setState(() {
      var next = _hour + delta;
      if (next < 1) next = 12;
      if (next > 12) next = 1;
      _hour = next;
    });
  }

  void _stepMinute(int delta) {
    setState(() {
      var next = _minute + delta;
      if (next < 0) next = 59;
      if (next > 59) next = 0;
      _minute = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    return EkaadhPickerShell(
      title: l10n.t('select_time'),
      confirmLabel: l10n.t('confirm'),
      onConfirm: () => Navigator.of(context).pop(_value),
      onCancel: () => Navigator.of(context).pop(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_hour:${_two(_minute)} ${_pm ? l10n.t('pm') : l10n.t('am')}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: EkaadhColors.brand,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _stepperColumn(
                    label: '$_hour',
                    onUp: () => _stepHour(1),
                    onDown: () => _stepHour(-1),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    ':',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: EkaadhColors.dark,
                    ),
                  ),
                ),
                Expanded(
                  child: _stepperColumn(
                    label: _two(_minute),
                    onUp: () => _stepMinute(1),
                    onDown: () => _stepMinute(-1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: EkaadhChoiceTile(
                    label: l10n.t('am'),
                    selected: !_pm,
                    onTap: () => setState(() => _pm = false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: EkaadhChoiceTile(
                    label: l10n.t('pm'),
                    selected: _pm,
                    onTap: () => setState(() => _pm = true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepperColumn({
    required String label,
    required VoidCallback onUp,
    required VoidCallback onDown,
  }) {
    return Column(
      children: [
        _stepBtn(Icons.keyboard_arrow_up_rounded, onUp),
        const SizedBox(height: 6),
        Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: EkaadhColors.fieldBorder),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: EkaadhColors.dark,
            ),
          ),
        ),
        const SizedBox(height: 6),
        _stepBtn(Icons.keyboard_arrow_down_rounded, onDown),
      ],
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: EkaadhColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 48,
          height: 36,
          child: Icon(icon, color: EkaadhColors.brand),
        ),
      ),
    );
  }
}
