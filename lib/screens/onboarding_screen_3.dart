import 'package:flutter/material.dart';
import 'package:hooko_v20/components/onboarding_step.dart';
import 'package:hooko_v20/components/weekly_chart.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:hooko_v20/nav.dart';
import 'package:hooko_v20/theme.dart';

class OnboardingScreen3 extends StatelessWidget {
  final List<double>? fromHeights;

  const OnboardingScreen3({super.key, this.fromHeights});

  @override
  Widget build(BuildContext context) => OnboardingStep(
        chartData: WeeklyChart.screen3Data,
        fromHeights: WeeklyChart.screen3FromHeights,
        title: OnboardingTitle3(key: ValueKey('title_${fromHeights?.join('_') ?? 'default'}')),
        subtitle: OnboardingSubtitle3(key: ValueKey('subtitle_${fromHeights?.join('_') ?? 'default'}')),
        backRoute: AppRoutes.onboarding2,
        backExtra: WeeklyChart.screen3Data.map((d) => d.heightRatio).toList(),
        nextRoute: AppRoutes.demo,
      );
}

class OnboardingTitle3 extends StatefulWidget {
  const OnboardingTitle3({super.key});

  @override
  State<OnboardingTitle3> createState() => _OnboardingTitle3State();
}

class _OnboardingTitle3State extends State<OnboardingTitle3>
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
          Text('See what\'s', style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('wrong with', style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFE85D34), Color(0xFFE84679)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds),
            child: Text(
              'your hook',
              style: titleStyle.copyWith(color: offWhite, height: 1.2),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingSubtitle3 extends StatefulWidget {
  const OnboardingSubtitle3({super.key});

  @override
  State<OnboardingSubtitle3> createState() => _OnboardingSubtitle3State();
}

class _OnboardingSubtitle3State extends State<OnboardingSubtitle3>
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
          'Upload any video.\nGet instant analysis.\nFix it and start growing.',
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
