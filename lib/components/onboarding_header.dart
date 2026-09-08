import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Logo header used across onboarding screens
/// Matches the final state of splash screen animation EXACTLY
/// Optimized with RepaintBoundary for smooth performance.
class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({super.key});

  // Exact values from splash screen's final state:
  // baseLogoSize = 64, targetLogoSize = 52, scale = 52/64 = 0.8125
  static const _logoSize = 52.0;
  static const _gap = 13.0; // 16 * 0.8125
  static const _fontSize = 21.125; // 26 * 0.8125
  static const _letterSpacing = 1.21875; // 1.5 * 0.8125
  static const _textColor = Color(0xFFFEFEFE);

  static const _textStyle = TextStyle(
    fontFamily: 'Geom',
    fontWeight: FontWeight.w900,
    fontSize: _fontSize,
    color: _textColor,
    letterSpacing: _letterSpacing,
  );

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/icons/icon_logo.svg',
          width: _logoSize,
          height: _logoSize,
        ),
        const SizedBox(width: _gap),
        const Text('HOOKO', style: _textStyle),
      ],
    ),
  );
}
