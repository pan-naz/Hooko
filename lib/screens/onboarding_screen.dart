import 'package:flutter/material.dart';
import 'package:hooko_v20/components/onboarding_step.dart';
import 'package:hooko_v20/components/weekly_chart.dart';
import 'package:hooko_v20/nav.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:hooko_v20/theme.dart';

class OnboardingScreen extends StatelessWidget {
  final List<double>? fromHeights;

  const OnboardingScreen({super.key, this.fromHeights});

  @override
  Widget build(BuildContext context) => OnboardingStep(
        chartData: WeeklyChart.screen1Data,
        fromHeights: fromHeights,
        title: OnboardingTitle(key: ValueKey('title_${fromHeights?.join(',') ?? 'initial'}')),
        subtitle: OnboardingSubtitle(key: ValueKey('subtitle_${fromHeights?.join(',') ?? 'initial'}')),
        nextRoute: AppRoutes.onboarding2,
      );
}

class OnboardingTitle extends StatefulWidget {
  const OnboardingTitle({super.key});

  @override
  State<OnboardingTitle> createState() => _OnboardingTitleState();
}

class _OnboardingTitleState extends State<OnboardingTitle>
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
          Text('Stuck at', style: titleStyle, softWrap: true),
          Row(
            children: [
              Flexible(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFE85D34), Color(0xFFE84679)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(bounds),
                  child: Text(
                    'low views',
                    style: titleStyle.copyWith(color: offWhite),
                    softWrap: true,
                  ),
                ),
              ),
              Text(
                '?',
                style: titleStyle.copyWith(color: const Color(0xFFE84679)),
              ),
            ],
          ),
          Text('Fix your', style: titleStyle, softWrap: true),
          Text('hook first', style: titleStyle, softWrap: true),
        ],
      ),
    );
  }
}

class OnboardingSubtitle extends StatefulWidget {
  const OnboardingSubtitle({super.key});

  @override
  State<OnboardingSubtitle> createState() => _OnboardingSubtitleState();
}

class _OnboardingSubtitleState extends State<OnboardingSubtitle>
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
          '70% of viewers swipe away instantly,\nyour hook decides everything!',
          style: TextStyle(
            color: const Color(0xFFFEFEFE),
            fontSize: ResponsiveSize.text(context, 20),
            fontWeight: FontWeight.w300,
            height: 1.5,
            fontFamily: 'Geom',
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      );
}
