import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ekaadh_mobile/core/locale_scope.dart';
import 'package:ekaadh_mobile/core/theme.dart';

Future<String?> showWalletPinDialog(BuildContext context) {
  final l10n = LocaleScope.of(context);
  final controller = TextEditingController();
  String? error;

  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              l10n.t('wallet_pin_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.t('wallet_pin_hint'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: EkaadhColors.muted, height: 1.4, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.t('wallet_pin_test_hint'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: EkaadhColors.brand,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: 10,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••',
                    filled: true,
                    fillColor: EkaadhColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: EkaadhColors.brand, width: 2),
                    ),
                  ),
                  onSubmitted: (_) {
                    final pin = controller.text.replaceAll(RegExp(r'\D'), '');
                    if (pin.length != 4) {
                      setLocal(() => error = l10n.t('wallet_pin_required'));
                      return;
                    }
                    Navigator.pop(ctx, pin);
                  },
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: EkaadhColors.danger, fontSize: 13)),
                ],
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.t('cancel')),
              ),
              FilledButton(
                onPressed: () {
                  final pin = controller.text.replaceAll(RegExp(r'\D'), '');
                  if (pin.length != 4) {
                    setLocal(() => error = l10n.t('wallet_pin_required'));
                    return;
                  }
                  Navigator.pop(ctx, pin);
                },
                style: FilledButton.styleFrom(backgroundColor: EkaadhColors.brand),
                child: Text(l10n.t('wallet_pin_continue')),
              ),
            ],
          );
        },
      );
    },
  );
}
