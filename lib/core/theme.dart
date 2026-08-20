import 'package:flutter/material.dart';

/// Matches customer-webview / admin brand tokens.
///
/// App UI uses the platform typeface (SF Pro on iOS, Roboto on Android).
class EkaadhColors {
  static const Color brand = Color(0xFF323891);
  static const Color brandDark = Color(0xFF262A6D);
  static const Color brandLight = Color(0xFFEEF0F8);
  static const Color dark = Color(0xFF0F1A2E);
  static const Color muted = Color(0xFF64748B);
  static const Color soft = Color(0xFF94A3B8);
  static const Color surface = Color(0xFFF2F4F8);
  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  /// Quiet placeholder text for inputs.
  static const Color hint = Color(0xFFC5CBD6);
  /// Soft field border (matches Search / Home inputs).
  static const Color fieldBorder = Color(0xFFE2E8E4);
}

class EkaadhTextStyles {
  static const TextStyle fieldHint = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: EkaadhColors.hint,
    height: 1.3,
  );
}

/// Shared gray input style used by Search and customer form fields.
class EkaadhFields {
  static InputDecoration decoration({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    double radius = 16,
    Color fillColor = EkaadhColors.surface,
    EdgeInsetsGeometry contentPadding =
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  }) {
    final borderRadius = BorderRadius.circular(radius);
    return InputDecoration(
      hintText: hintText,
      hintStyle: EkaadhTextStyles.fieldHint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor,
      contentPadding: contentPadding,
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: EkaadhColors.fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: EkaadhColors.brand, width: 1.5),
      ),
    );
  }

  /// White outlined fields used by create/checkout wizards.
  static InputDecoration form({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return decoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      fillColor: Colors.white,
      radius: 12,
    );
  }
}
