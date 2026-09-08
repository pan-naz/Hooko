import 'package:flutter/material.dart';
import 'package:hooko_v20/components/onboarding_step.dart';
import 'package:hooko_v20/components/weekly_chart.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:hooko_v20/nav.dart';
import 'package:hooko_v20/theme.dart';

class OnboardingScreen2 extends StatelessWidget {
  final List<double>? fromHeights;

  const OnboardingScreen2({super.key, this.fromHeights});

  @override
  Widget build(BuildContext context) => OnboardingStep(
        chartData: WeeklyChart.screen2Data,
        fromHeights: fromHeights ?? WeeklyChart.screen2FromHeights,
        title: OnboardingTitle2(key: ValueKey('title2_${fromHeights?.join(',') ?? 'initial'}')),
        subtitle: OnboardingSubtitle2(key: ValueKey('subtitle2_${fromHeights?.join(',') ?? 'initial'}')),
        backRoute: AppRoutes.onboarding,
        backExtra: WeeklyChart.screen2Data.map((d) => d.heightRatio).toList(),
        nextRoute: AppRoutes.onboarding3,
      );
}

class OnboardingTitle2 extends StatefulWidget {
  const OnboardingTitle2({super.key});

  @override
  State<OnboardingTitle2> createState() => _OnboardingTitle2State();
}

class _OnboardingTitle2State extends State<OnboardingTitle2>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleSize = ResponsiveSize.text(context, 60);
    final titleStyle = TextStyle(
      fontFamily: 'Geom',
      fontWeight: FontWeight.w800,
      color: const Color(0xFFFEFEFE),
      fontSize: titleSize,
      height: 0.88,
    );

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text('Viewers', style: titleStyle, softWrap: true),
          Text('leave within', style: titleStyle, softWrap: true),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFE85D34), Color(0xFFE84679)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds),
            child: Text(
              '3 seconds',
              style: titleStyle.copyWith(color: offWhite),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingSubtitle2 extends StatefulWidget {
  const OnboardingSubtitle2({super.key});

  @override
  State<OnboardingSubtitle2> createState() => _OnboardingSubtitle2State();
}

class _OnboardingSubtitle2State extends State<OnboardingSubtitle2>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fadeAnimation,
        child: Text(
          'Your content might be great — but\nwithout a strong hook, no one will\never see it.',
          style: TextStyle(
            color: const Color(0xFFFEFEFE),
            fontSize: ResponsiveSize.text(context, 20),
            fontWeight: FontWeight.w300,
            height: 1.5,
            fontFamily: 'Geom',
          ),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      );
}
