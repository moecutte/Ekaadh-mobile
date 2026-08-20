import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/locale_scope.dart';
import 'package:ekaadh_mobile/core/theme.dart';

/// Numbered circles + connecting lines (done = green check, active = brand).
class EkaadhWizardStepper extends StatelessWidget {
  const EkaadhWizardStepper({
    super.key,
    required this.labels,
    required this.current,
  });

  final List<String> labels;
  final int current;

  @override
  Widget build(BuildContext context) {
    final last = labels.length - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    height: 32,
                    child: Row(
                      children: [
                        Expanded(
                          child: i == 0
                              ? const SizedBox.shrink()
                              : _line(i <= current),
                        ),
                        _circle(i),
                        Expanded(
                          child: i == last
                              ? const SizedBox.shrink()
                              : _line(i < current),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    labels[i],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.25,
                      fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
                      color: i == current
                          ? EkaadhColors.brand
                          : i < current
                              ? EkaadhColors.dark
                              : EkaadhColors.muted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _line(bool complete) {
    return Container(
      height: 2,
      color: complete ? EkaadhColors.success : const Color(0xFFE5E7EB),
    );
  }

  Widget _circle(int i) {
    final done = i < current;
    final active = i == current;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: done
            ? EkaadhColors.success
            : active
                ? EkaadhColors.brand
                : Colors.white,
        shape: BoxShape.circle,
        border: done || active
            ? null
            : Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
      ),
      child: done
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
          : Text(
              '${i + 1}',
              style: TextStyle(
                color: active ? Colors.white : EkaadhColors.muted,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
    );
  }
}

class EkaadhWizardFooter extends StatelessWidget {
  const EkaadhWizardFooter({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onBack,
    this.loading = false,
    this.includeSafeArea = true,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback onBack;
  final bool loading;
  final bool includeSafeArea;

  @override
  Widget build(BuildContext context) {
    final bottom = includeSafeArea ? MediaQuery.paddingOf(context).bottom : 0.0;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEF0F4))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: OutlinedButton(
              onPressed: loading ? null : onBack,
              style: OutlinedButton.styleFrom(
                foregroundColor: EkaadhColors.dark,
                padding: EdgeInsets.zero,
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: loading ? null : onPrimary,
                style: FilledButton.styleFrom(
                  backgroundColor: EkaadhColors.brand,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              primaryLabel,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EkaadhWizardSection extends StatelessWidget {
  const EkaadhWizardSection({
    super.key,
    required this.title,
    this.trailing,
    required this.child,
  });

  final String title;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: EkaadhColors.dark,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Flexible(child: trailing!),
            ],
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class EkaadhWizardSummaryRow extends StatelessWidget {
  const EkaadhWizardSummaryRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: EkaadhColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: EkaadhColors.dark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EkaadhWizardIconField extends StatelessWidget {
  const EkaadhWizardIconField({
    super.key,
    required this.icon,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final IconData icon;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: EkaadhColors.fieldBorder),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: EkaadhColors.soft),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasValue ? value! : placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hasValue ? EkaadhColors.dark : EkaadhColors.hint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EkaadhWizardCard extends StatelessWidget {
  const EkaadhWizardCard({
    super.key,
    required this.child,
    this.elevated = false,
  });

  final Widget child;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F4)),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

class EkaadhChoiceTile extends StatelessWidget {
  const EkaadhChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? EkaadhColors.brand : EkaadhColors.fieldBorder,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 20,
                color: selected ? EkaadhColors.brand : EkaadhColors.soft,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: selected ? EkaadhColors.brand : EkaadhColors.dark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EkaadhPickerShell extends StatelessWidget {
  const EkaadhPickerShell({
    super.key,
    required this.title,
    required this.child,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
  });

  final String title;
  final Widget child;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: EkaadhColors.dark,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          child,
          EkaadhWizardFooter(
            primaryLabel: confirmLabel,
            onPrimary: onConfirm,
            onBack: onCancel,
            includeSafeArea: false,
          ),
        ],
      ),
    );
  }
}

class EkaadhWizardSelectField extends StatelessWidget {
  const EkaadhWizardSelectField({
    super.key,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: EkaadhColors.fieldBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasValue ? value! : placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hasValue ? EkaadhColors.dark : EkaadhColors.hint,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: EkaadhColors.soft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<T?> showEkaadhOptionPicker<T>({
  required BuildContext context,
  required String title,
  required List<(T value, String label)> options,
  T? selected,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.32),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: _EkaadhOptionPickerPopup<T>(
        title: title,
        options: options,
        selected: selected,
      ),
    ),
  );
}

class _EkaadhOptionPickerPopup<T> extends StatefulWidget {
  const _EkaadhOptionPickerPopup({
    required this.title,
    required this.options,
    this.selected,
  });

  final String title;
  final List<(T value, String label)> options;
  final T? selected;

  @override
  State<_EkaadhOptionPickerPopup<T>> createState() =>
      _EkaadhOptionPickerPopupState<T>();
}

class _EkaadhOptionPickerPopupState<T>
    extends State<_EkaadhOptionPickerPopup<T>> {
  late T? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    return EkaadhPickerShell(
      title: widget.title,
      confirmLabel: l10n.t('confirm'),
      onConfirm: () => Navigator.of(context).pop(_selected),
      onCancel: () => Navigator.of(context).pop(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 360),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          itemCount: widget.options.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final option = widget.options[index];
            return EkaadhChoiceTile(
              label: option.$2,
              selected: _selected == option.$1,
              onTap: () => setState(() => _selected = option.$1),
            );
          },
        ),
      ),
    );
  }
}
