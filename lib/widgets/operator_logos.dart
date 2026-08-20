import 'package:flutter/material.dart';

class OperatorLogos extends StatelessWidget {
  const OperatorLogos({super.key, this.height = 28, this.padding});

  final double height;
  final EdgeInsetsGeometry? padding;

  static const _assets = [
    'assets/images/telesom-logo.png',
    'assets/images/golis-logo.png',
    'assets/images/hormuud-logo.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _assets.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: height * 0.7,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: const Color(0xFFE2E8F0),
              ),
            Image.asset(_assets[i], height: height, fit: BoxFit.contain),
          ],
        ],
      ),
    );
  }
}
