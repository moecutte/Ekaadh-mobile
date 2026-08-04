import 'package:flutter/material.dart';

/// Brand wordmark. Use [white] on dark / brand-colored backgrounds.
class EkaadhLogo extends StatelessWidget {
  const EkaadhLogo({
    super.key,
    this.height = 36,
    this.white = false,
  });

  final double height;
  final bool white;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      white ? 'assets/images/ekaadh_logo_white.png' : 'assets/images/ekaadh_logo.png',
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
