import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/core/locale_scope.dart';
import 'package:ekaadh_mobile/widgets/ekaadh_logo.dart';

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.emoji,
    required this.background,
    required this.titleKey,
    required this.bodyKey,
  });

  final String emoji;
  final Color background;
  final String titleKey;
  final String bodyKey;
}

const _slides = [
  _OnboardingSlide(
    emoji: '🎪',
    background: EkaadhColors.brandLight,
    titleKey: 'onboard_1_title',
    bodyKey: 'onboard_1_body',
  ),
  _OnboardingSlide(
    emoji: '⚡',
    background: Color(0xFFEFF0FE),
    titleKey: 'onboard_2_title',
    bodyKey: 'onboard_2_body',
  ),
  _OnboardingSlide(
    emoji: '📱',
    background: Color(0xFFFFFBEB),
    titleKey: 'onboard_3_title',
    bodyKey: 'onboard_3_body',
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
    final l10n = LocaleScope.of(context);
    final s = _slides[_slide];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: EkaadhColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8E4)),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _OnboardLangChip(
                          label: l10n.t('eng'),
                          selected: l10n.code == 'en',
                          onTap: () => l10n.setLocale('en'),
                        ),
                        _OnboardLangChip(
                          label: l10n.t('som'),
                          selected: l10n.code == 'so',
                          onTap: () => l10n.setLocale('so'),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onComplete,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFB8BFBB),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: Text(
                      l10n.t('skip'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
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
                    l10n.t(s.titleKey),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: EkaadhColors.dark,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.t(s.bodyKey),
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
                        _isLast ? l10n.t('get_started') : l10n.t('next'),
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

class _OnboardLangChip extends StatelessWidget {
  const _OnboardLangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? EkaadhColors.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : EkaadhColors.muted,
          ),
        ),
      ),
    );
  }
}
