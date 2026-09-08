import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hooko_v20/components/animated_fire_gradient.dart';
import 'package:hooko_v20/nav.dart';
import 'package:hooko_v20/services/demo_video_preloader.dart';
import 'package:hooko_v20/state/app_state.dart';
import 'package:hooko_v20/utils/app_constants.dart';
import 'package:hooko_v20/utils/image_precache.dart';
import 'package:hooko_v20/utils/svg_precache.dart';

/// Animated splash screen with logo scale, typing, and move animations.
/// Optimized for iOS with RepaintBoundary and efficient listenable merging.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _typingController;
  late AnimationController _moveController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _moveAnimation;
  late Listenable _mergedListenable;
  
  static const _text = 'HOOKO';
  static const _baseLogoSize = 64.0;
  static const _targetLogoSize = 52.0;
  static const _gap = AppSpacing.lg; // 16.0
  static const _horizontalPadding = AppPadding.screen; // 24.0
  static const _topPadding = AppPadding.topContent; // 24.0
  static const _textStyle = TextStyle(
    fontFamily: 'Geom',
    fontWeight: FontWeight.w900,
    fontSize: 26,
    color: Color(0xFFFEFEFE),
    letterSpacing: 1.5,
  );

  late final double _fullTextWidth;
  bool _precacheStarted = false;

  @override
  void initState() {
    super.initState();
    _fullTextWidth = _measureTextWidth(_textStyle);
    _initAnimations();
    _startAnimationSequence();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fire-and-forget: kick off precache as early as possible. It continues
    // running across navigation; the splash never waits for it.
    if (!_precacheStarted) {
      _precacheStarted = true;
      // Fire-and-forget all asset precaches in parallel. None of these
      // are awaited — animations and navigation must not be blocked.
      precacheBackgroundImages(context);
      precacheSvgAssets();
      DemoVideoPreloader.instance.preload();
    }
  }

  void _initAnimations() {
    // Phase 1: Logo scale (300% → 100%)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 3.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    // Phase 2: Typing animation
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Phase 3: Move to top-left
    _moveController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _moveAnimation = CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeOutCubic,
    );

    // Merge all listenables for efficient single rebuild
    _mergedListenable = Listenable.merge([
      _scaleController,
      _typingController,
      _moveController,
    ]);
  }

  void _startAnimationSequence() {
    // Start scale after 0.5s delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _scaleController.forward();
    });

    // Chain animations
    _scaleController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _typingController.forward();
      }
    });

    _typingController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _moveController.forward();
        });
      }
    });

    _moveController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _navigateToNextScreen();
      }
    });
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;
    final appState = AppStateProvider.read(context);

    // Wait (briefly) for RevenueCat's initial entitlement sync so subscribed
    // users skip onboarding/demo and land on Home directly. Cap the wait so
    // a slow / failed RC fetch never traps the splash.
    if (!appState.rcInitialSyncComplete) {
      await appState.rcInitialSyncFuture
          .timeout(const Duration(seconds: 2), onTimeout: () {});
    }
    if (!mounted) return;

    // Note: we intentionally do NOT wait for daily-usage to load here, so the
    // splash never appears stuck. The home app bar shows a small inline
    // spinner in place of the count until the real value arrives.

    if (appState.isProSubscribed) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _typingController.dispose();
    _moveController.dispose();
    super.dispose();
  }

  double _measureTextWidth(TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: _text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.width;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safeAreaTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Local animated gradient - only runs while SplashScreen is mounted
          const Positioned.fill(
            child: AnimatedFireGradient(),
          ),
          AnimatedBuilder(
            animation: _mergedListenable,
            builder: (context, child) {
              final typingProgress =
                  Curves.easeOutCubic.transform(_typingController.value);
              final moveProgress = _moveAnimation.value;

              // Combined scale
              final moveScale =
                  1.0 - (1.0 - _targetLogoSize / _baseLogoSize) * moveProgress;
              final totalScale = _scaleAnimation.value * moveScale;
              final displayedLogoSize = _baseLogoSize * totalScale;

              // Visible text section width
              final visibleTextWidth =
                  (_gap + _fullTextWidth) * typingProgress * moveScale;
              final totalRowWidth = displayedLogoSize + visibleTextWidth;

              // Calculate positions
              final centerX = screenSize.width / 2;
              final centerY = screenSize.height / 2;
              final centeredX = centerX - totalRowWidth / 2;
              final centeredY = centerY - displayedLogoSize / 2;
              final targetX = _horizontalPadding;
              final targetY = safeAreaTop + _topPadding;

              final rowX = centeredX + (targetX - centeredX) * moveProgress;
              final rowY = centeredY + (targetY - centeredY) * moveProgress;

              return Positioned(
                left: rowX,
                top: rowY,
                child: RepaintBoundary(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/icon_logo.svg',
                        width: displayedLogoSize,
                        height: displayedLogoSize,
                      ),
                      if (typingProgress > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: _gap * moveScale),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(_text.length, (index) {
                                final letterStart = index / _text.length;
                                final letterEnd = (index + 1) / _text.length;
                                final letterProgress = ((typingProgress - letterStart) / (letterEnd - letterStart)).clamp(0.0, 1.0);
                                
                                return Opacity(
                                  opacity: letterProgress,
                                  child: Text(
                                    _text[index],
                                    style: _textStyle.copyWith(
                                      fontSize: 26 * moveScale,
                                      letterSpacing: 1.5 * moveScale,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
