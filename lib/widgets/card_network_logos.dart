import 'package:flutter/material.dart';

/// Standard Visa wordmark + Mastercard interlocking circles (checkout logos).
class CardNetworkLogos extends StatelessWidget {
  const CardNetworkLogos({super.key, this.height = 28, this.padding});

  final double height;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final visaW = height * 2.9;
    final mcW = height * 1.65;
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: height,
            width: visaW,
            child: CustomPaint(painter: _VisaLogoPainter()),
          ),
          Container(
            width: 1,
            height: height * 0.7,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: const Color(0xFFE2E8F0),
          ),
          SizedBox(
            height: height,
            width: mcW,
            child: CustomPaint(painter: _MastercardLogoPainter()),
          ),
        ],
      ),
    );
  }
}

class _VisaLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.12, size.width, size.height * 0.76),
      Radius.circular(size.height * 0.12),
    );
    canvas.drawRRect(r, Paint()..color = const Color(0xFF1A1F71));

    final tp = TextPainter(
      text: TextSpan(
        text: 'VISA',
        style: TextStyle(
          color: Colors.white,
          fontSize: size.height * 0.48,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: size.height * 0.06,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.08,
          size.height * 0.72,
          size.width * 0.22,
          size.height * 0.08,
        ),
        Radius.circular(size.height * 0.04),
      ),
      Paint()..color = const Color(0xFFF7B600),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MastercardLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height * 0.42;
    final cy = size.height / 2;
    final left = Offset(size.width * 0.34, cy);
    final right = Offset(size.width * 0.66, cy);

    canvas.drawCircle(left, r, Paint()..color = const Color(0xFFEB001B));
    canvas.drawCircle(right, r, Paint()..color = const Color(0xFFF79E1B));

    final overlap = Path.combine(
      PathOperation.intersect,
      Path()..addOval(Rect.fromCircle(center: left, radius: r)),
      Path()..addOval(Rect.fromCircle(center: right, radius: r)),
    );
    canvas.drawPath(overlap, Paint()..color = const Color(0xFFFF5F00));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
