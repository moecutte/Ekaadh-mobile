import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/widgets/ekaadh_logo.dart';

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.emoji,
    required this.background,
    required this.title,
    required this.body,
  });

  final String emoji;
  final Color background;
  final String title;
  final String body;
}

const _slides = [
  _OnboardingSlide(
    emoji: '🎪',
    background: EkaadhColors.brandLight,
    title: 'Discover Amazing Events',
    body:
        'Browse concerts, sports, food festivals, and more happening near you — all in one place.',
  ),
  _OnboardingSlide(
    emoji: '⚡',
    background: Color(0xFFEFF0FE),
    title: 'Buy Tickets in Seconds',
    body:
        'Select your seats, choose Zaad or eDahab, and pay instantly. No cash, no queues.',
  ),
  _OnboardingSlide(
    emoji: '📱',
    background: Color(0xFFFFFBEB),
    title: 'Your Ticket, Always Ready',
    body:
        'Your QR-code tickets live in the app. Show them at the door — no printing needed.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _slide = 0;

  bool get _isLast => _slide == _slides.length - 1;

  void _next() {
    if (_isLast) {
      widget.onComplete();
      return;
    }
    setState(() => _slide++);
  }

  @override
  Widget build(BuildContext context) {
    final s = _slides[_slide];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: TextButton(
                  onPressed: widget.onComplete,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB8BFBB),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Center(child: EkaadhLogo(height: 28)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                height: 290,
                decoration: BoxDecoration(
                  color: s.background,
                  borderRadius: BorderRadius.circular(28),
                ),
                alignment: Alignment.center,
                child: Text(s.emoji, style: const TextStyle(fontSize: 96)),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _slide;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? EkaadhColors.brand : const Color(0xFFE2E8E4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: EkaadhColors.dark,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.body,
                    style: const TextStyle(
                      color: Color(0xFF6B7A72),
                      fontSize: 15,
                      height: 1.65,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: EkaadhColors.brand,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLast ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
