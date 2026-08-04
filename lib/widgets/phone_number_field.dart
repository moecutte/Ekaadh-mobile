import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ekaadh_mobile/core/theme.dart';

/// Somalia dial code shown as a fixed chip beside phone inputs.
class PhoneNumberField extends StatelessWidget {
  const PhoneNumberField({
    super.key,
    required this.controller,
    this.hint = '61 234 5678',
    this.borderRadius = 16,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    this.readOnly = false,
  });

  static const dialCode = '+252';

  final TextEditingController controller;
  final String hint;
  final double borderRadius;
  final EdgeInsetsGeometry contentPadding;
  final bool readOnly;

  /// Digits after the country code (strips +252 / leading 252).
  static String localPart(String? full) {
    if (full == null || full.trim().isEmpty) return '';
    var digits = full.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('252')) {
      digits = digits.substring(3);
    }
    return digits;
  }

  /// Full E.164-style number: `+252` + local digits.
  static String fullNumber(String localOrFull) {
    final local = localPart(localOrFull);
    if (local.isEmpty) return dialCode;
    return '$dialCode$local';
  }

  static bool hasLocalNumber(String localOrFull) =>
      localPart(localOrFull).isNotEmpty;

  static List<TextInputFormatter> get inputFormatters => [
        FilteringTextInputFormatter.allow(RegExp(r'[\d\s]')),
      ];

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(borderRadius);

    return Container(
      decoration: BoxDecoration(
        color: EkaadhColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: EkaadhColors.fieldBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: EkaadhColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: radius,
                bottomLeft: radius,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 10),
              child: Text(
                dialCode,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: EkaadhColors.muted,
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: EkaadhColors.fieldBorder,
          ),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: const InputDecorationTheme(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: false,
                  fillColor: Colors.transparent,
                ),
              ),
              child: TextField(
                controller: controller,
                readOnly: readOnly,
                keyboardType: TextInputType.phone,
                inputFormatters: inputFormatters,
                style: TextStyle(
                  color: readOnly ? EkaadhColors.muted : EkaadhColors.dark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: EkaadhTextStyles.fieldHint,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: contentPadding,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
