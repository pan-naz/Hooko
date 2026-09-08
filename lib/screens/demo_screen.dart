import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooko_v20/components/onboarding_header.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:hooko_v20/nav.dart';
import 'package:hooko_v20/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hooko_v20/components/primary_button.dart';
import 'package:hooko_v20/components/secondary_button.dart';
import 'package:hooko_v20/components/icon_button.dart' as custom;
import 'package:hooko_v20/components/weekly_chart.dart';
import 'package:hooko_v20/services/demo_video_preloader.dart';
import 'package:video_player/video_player.dart';

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  @override
  void initState() {
    super.initState();
    // Start preloading the demo video so DemoScreen2 opens instantly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DemoVideoPreloader.instance.preload();
    });
  }

  @override
  void dispose() {
    // If the controller wasn't taken by DemoScreen2, clean up.
    DemoVideoPreloader.instance.disposeIfUnused();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Match onboarding screens: fixed 24dp horizontal padding
    const double horizontalPadding = 24.0;
    // External spacing should visually match top and bottom. We keep the
    // bottom sheet 24dp from the bottom edge and compensate for the
    // home-indicator inside the sheet (see DemoBottomSheet).

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Image.asset('assets/images/run.jpg', fit: BoxFit.cover),
          ),
          Positioned(
            left: horizontalPadding,
            right: horizontalPadding,
            bottom: horizontalPadding,
            child: DemoBottomSheet(horizontalPadding: horizontalPadding),
          ),
          // OnboardingHeader positioned exactly like SplashScreen's final state
          Positioned(
            left: horizontalPadding,
            top: MediaQuery.of(context).padding.top + 24,
            child: const OnboardingHeader(),
          ),
          // Title and subtitle below the header
          Positioned(
            left: horizontalPadding,
            right: horizontalPadding,
            top: MediaQuery.of(context).padding.top + 24 + 52 + ResponsiveSize.verticalSpacing(context, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DemoTitle(),
                SizedBox(height: ResponsiveSize.verticalSpacing(context, 12)),
                const DemoSubtitle(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DemoTitle extends StatefulWidget {
  const DemoTitle({super.key});

  @override
  State<DemoTitle> createState() => _DemoTitleState();
}

class _DemoTitleState extends State<DemoTitle> with SingleTickerProviderStateMixin {
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
      color: offWhite,
      fontSize: titleSize,
      height: 0.88,
    );

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          Text('Try a demo ', style: titleStyle, softWrap: true),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) {
              const extra = 8.0;
              final rect = Rect.fromLTWH(0, 0, bounds.width, bounds.height + extra);
              return const LinearGradient(
                colors: [Color(0xFFE85D34), Color(0xFFE84679)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(rect);
            },
            child: Text(
              'Analysis',
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
              ),
              style: titleStyle.copyWith(height: 1.0),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

class DemoSubtitle extends StatefulWidget {
  const DemoSubtitle({super.key});

  @override
  State<DemoSubtitle> createState() => _DemoSubtitleState();
}

class _DemoSubtitleState extends State<DemoSubtitle>
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
          'See exactly what you\'ll get before you subscribe.',
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

class DemoBottomSheet extends StatelessWidget {
  final double horizontalPadding;

  const DemoBottomSheet({super.key, required this.horizontalPadding});

  @override
  Widget build(BuildContext context) {
    // Provide symmetric internal padding so the spacing under the secondary
    // button matches the top/left/right. External offset is handled by the
    // Positioned widget (24dp from the screen edge).
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.spacing(context, 32)),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEFE).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            PrimaryButton(
              label: 'Try Analysis',
              iconPath: 'assets/icons/analize.svg',
              onTap: () async {
                // Wait for the preloaded controller and pass it via GoRouter extra
                final VideoPlayerController? ctrl =
                    await DemoVideoPreloader.instance.takeWhenReady();
                if (!context.mounted) return;
                context.go(AppRoutes.demo2, extra: ctrl);
              },
            ),
          SizedBox(height: ResponsiveSize.spacing(context, 16)),
          Row(
            children: [
              custom.IconButton(
                iconPath: 'assets/icons/arrow_left.svg',
                onPressed: () => context.go(
                  AppRoutes.onboarding3,
                  extra: WeeklyChart.screen3Data.map((d) => d.heightRatio).toList(),
                ),
              ),
              SizedBox(width: ResponsiveSize.spacing(context, 12)),
              Expanded(
                child: SecondaryButton(
                  text: 'Skip',
                  onPressed: () => context.go(AppRoutes.home),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TermsText extends StatelessWidget {
  const TermsText({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontFamily: 'Geom',
      fontSize: ResponsiveSize.text(context, 12),
      fontWeight: FontWeight.w300,
      color: const Color(0xFFFEFEFE),
      height: 1.5,
    );

    final linkStyle = textStyle.copyWith(
      decoration: TextDecoration.underline,
      decorationColor: const Color(0xFFFEFEFE),
    );

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: textStyle,
        children: [
          const TextSpan(text: 'By signing up, you agree\nto Hooko '),
          TextSpan(
            text: 'Terms of Use',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                final url = Uri.parse('https://hooko.com/terms');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                final url = Uri.parse('https://hooko.com/privacy');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
          ),
        ],
      ),
    );
  }
}
