import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooko_v20/components/animated_fire_gradient.dart';
import 'package:hooko_v20/components/icon_button.dart' as custom;
import 'package:hooko_v20/components/onboarding_header.dart';
import 'package:hooko_v20/components/weekly_chart.dart';
import 'package:hooko_v20/components/secondary_button.dart';
import 'package:hooko_v20/utils/responsive_size.dart';

/// Reusable scaffold for onboarding steps to avoid duplication
class OnboardingStep extends StatelessWidget {
  final List<ChartColumnData> chartData;
  final List<double>? fromHeights;
  final Widget title;
  final Widget subtitle;
  final String? backRoute;
  final Object? backExtra;
  final String nextRoute;
  final Object? nextExtra;

  const OnboardingStep({
    super.key,
    required this.chartData,
    required this.title,
    required this.subtitle,
    required this.nextRoute,
    this.fromHeights,
    this.backRoute,
    this.backExtra,
    this.nextExtra,
  });

  // Fixed positioning to match SplashScreen's final state exactly
  static const double _fixedHorizontalPadding = 24.0;
  static const double _fixedTopPadding = 24.0;
  static const double _headerHeight = 52.0; // OnboardingHeader logo size

  @override
  Widget build(BuildContext context) {
    final responsiveHorizontalPadding = ResponsiveSize.horizontalPadding(context);
    final safeAreaTop = MediaQuery.of(context).padding.top;
    // Get the actual screen width to ensure consistent positioning
    final screenWidth = MediaQuery.of(context).size.width;
    // Chart extends off left edge for visual effect but stays within right bound
    final leftOffset = -ResponsiveSize.spacing(context, 52);
    final buttonBottomPadding = ResponsiveSize.verticalSpacing(context, 60);
    final chartBottomPosition = buttonBottomPadding + ResponsiveSize.spacing(context, 80);
    final backButtonSpacing = ResponsiveSize.spacing(context, 12);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.expand(
        child: Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            // Local animated gradient - only runs while onboarding screens are mounted
            const Positioned.fill(
              child: AnimatedFireGradient(),
            ),
            Positioned(
              left: leftOffset,
              bottom: chartBottomPosition,
              width: screenWidth + leftOffset.abs() - 12, // Explicit width from left edge to 12dp from right
              child: WeeklyChart(
                data: chartData,
                animate: true,
                fromHeights: fromHeights,
              ),
            ),
            // OnboardingHeader positioned exactly like SplashScreen's final state
            Positioned(
              left: _fixedHorizontalPadding,
              top: safeAreaTop + _fixedTopPadding,
              child: const OnboardingHeader(),
            ),
            // Title and subtitle below the header
            Positioned(
              left: _fixedHorizontalPadding,
              right: _fixedHorizontalPadding,
              top: safeAreaTop + _fixedTopPadding + _headerHeight + ResponsiveSize.verticalSpacing(context, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  SizedBox(height: ResponsiveSize.verticalSpacing(context, 12)),
                  subtitle,
                ],
              ),
            ),
            Positioned(
              left: responsiveHorizontalPadding,
              right: responsiveHorizontalPadding,
              bottom: buttonBottomPadding,
              child: backRoute == null
                  ? _NextButton(nextRoute: nextRoute, nextExtra: nextExtra)
                  : Row(
                      children: [
                        custom.IconButton(
                          iconPath: 'assets/icons/arrow_left.svg',
                          onPressed: () => context.go(backRoute!, extra: backExtra),
                        ),
                        SizedBox(width: backButtonSpacing),
                        Expanded(
                          child: _NextButton(nextRoute: nextRoute, nextExtra: nextExtra),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final String nextRoute;
  final Object? nextExtra;
  const _NextButton({required this.nextRoute, this.nextExtra});

  @override
  Widget build(BuildContext context) => SecondaryButton(
        text: 'Next',
        onPressed: () => context.go(nextRoute, extra: nextExtra),
      );
}
