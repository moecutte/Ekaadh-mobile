import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/locale_scope.dart';
import 'package:ekaadh_mobile/core/theme.dart';

enum EkaadhToastKind { success, error, processing }

/// Status bottom sheet used instead of Material snackbars / toasts.
class EkaadhToast {
  static Future<void> success(
    BuildContext context, {
    String? title,
    required String message,
    String? actionLabel,
  }) {
    return show(
      context,
      kind: EkaadhToastKind.success,
      title: title,
      message: message,
      actionLabel: actionLabel,
    );
  }

  static Future<void> error(
    BuildContext context, {
    String? title,
    required String message,
    VoidCallback? onRetry,
  }) {
    return show(
      context,
      kind: EkaadhToastKind.error,
      title: title,
      message: message,
      onRetry: onRetry,
    );
  }

  static Future<void> processing(
    BuildContext context, {
    String? title,
    required String message,
  }) {
    return show(
      context,
      kind: EkaadhToastKind.processing,
      title: title,
      message: message,
    );
  }

  static Future<void> show(
    BuildContext context, {
    required EkaadhToastKind kind,
    String? title,
    required String message,
    String? actionLabel,
    VoidCallback? onRetry,
  }) {
    if (!context.mounted) return Future.value();
    final dismissible = kind != EkaadhToastKind.processing;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: dismissible,
      enableDrag: dismissible,
      backgroundColor: Colors.white,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return _EkaadhToastSheet(
          kind: kind,
          title: title,
          message: message,
          actionLabel: actionLabel,
          onRetry: onRetry,
        );
      },
    );
  }
}

class _EkaadhToastSheet extends StatefulWidget {
  const _EkaadhToastSheet({
    required this.kind,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onRetry,
  });

  final EkaadhToastKind kind;
  final String? title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onRetry;

  @override
  State<_EkaadhToastSheet> createState() => _EkaadhToastSheetState();
}

class _EkaadhToastSheetState extends State<_EkaadhToastSheet> {
  Timer? _autoClose;

  @override
  void initState() {
    super.initState();
    if (widget.kind == EkaadhToastKind.success && widget.onRetry == null) {
      _autoClose = Timer(const Duration(milliseconds: 2400), () {
        if (mounted) Navigator.of(context).maybePop();
      });
    }
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    super.dispose();
  }

  void _close() {
    _autoClose?.cancel();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final title = widget.title ??
        (widget.kind == EkaadhToastKind.error
            ? l10n.t('toast_problem')
            : widget.kind == EkaadhToastKind.processing
                ? l10n.t('toast_processing')
                : l10n.t('toast_success'));

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 10, 24, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD8DEE6),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 22),
          _ToastGlyph(kind: widget.kind),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: EkaadhColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: EkaadhColors.muted,
            ),
          ),
          if (widget.kind != EkaadhToastKind.processing) ...[
            const SizedBox(height: 22),
            if (widget.kind == EkaadhToastKind.error)
              Row(
                children: [
                  Expanded(
                    child: _ToastButton(
                      label: l10n.t('close'),
                      primary: false,
                      onTap: _close,
                    ),
                  ),
                  if (widget.onRetry != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ToastButton(
                        label: l10n.t('try_again'),
                        primary: true,
                        onTap: () {
                          _close();
                          widget.onRetry!();
                        },
                      ),
                    ),
                  ],
                ],
              )
            else
              _ToastButton(
                label: widget.actionLabel ?? l10n.t('nice_one'),
                primary: true,
                onTap: _close,
              ),
          ],
        ],
      ),
    );
  }
}

class _ToastGlyph extends StatelessWidget {
  const _ToastGlyph({required this.kind});

  final EkaadhToastKind kind;

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case EkaadhToastKind.success:
        return Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Color(0xFF22C55E),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 38),
        );
      case EkaadhToastKind.error:
        return Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFACC15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            '!',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F1A2E),
              height: 1,
            ),
          ),
        );
      case EkaadhToastKind.processing:
        return Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: EkaadhColors.brandLight,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.send_rounded, color: EkaadhColors.brand, size: 32),
        );
    }
  }
}

class _ToastButton extends StatelessWidget {
  const _ToastButton({
    required this.label,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: primary ? EkaadhColors.brand : EkaadhColors.surface,
          foregroundColor: primary ? Colors.white : EkaadhColors.dark,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        child: Text(label),
      ),
    );
  }
}
