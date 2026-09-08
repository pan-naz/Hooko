import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:hooko_v20/nav.dart';
import 'package:hooko_v20/components/primary_button.dart';
import 'package:hooko_v20/components/app_bar_with_analysis.dart';
import 'package:hooko_v20/components/animated_ellipsis_text.dart';
import 'package:hooko_v20/components/custom_spinner.dart';
import 'package:hooko_v20/components/video_player_widget.dart';
import 'package:hooko_v20/components/animated_fire_gradient.dart';
import 'package:hooko_v20/services/demo_video_preloader.dart';
import 'package:hooko_v20/services/active_operations_manager.dart';

/// Demo analysis screen with video player and analysis progress.
/// Optimized for iOS with RepaintBoundary and proper lifecycle management.
class DemoScreen2 extends StatefulWidget {
  final VideoPlayerController? preloadedController;
  const DemoScreen2({super.key, this.preloadedController});

  @override
  State<DemoScreen2> createState() => _DemoScreen2State();
}

class _DemoScreen2State extends State<DemoScreen2>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _isMuted = true;
  String? _errorMessage;
  bool _isDisposed = false;

  // Analysis state
  bool _isAnalyzing = false;
  bool _isAnalysisComplete = false;
  bool _redirectScheduled = false;

  // Animation controllers
  AnimationController? _percentageController;
  Animation<int>? _percentageAnimation;
  AnimationController? _backgroundFadeController;
  Animation<double>? _backgroundFadeAnimation;
  AnimationController? _layoutTransitionController;
  Animation<double>? _layoutTransitionAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.preloadedController != null) {
      _usePreloadedController(widget.preloadedController!);
    } else {
      _initializeVideoPlayer();
    }
  }

  void _initAnalysisAnimations() {
    _layoutTransitionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _layoutTransitionAnimation = CurvedAnimation(
      parent: _layoutTransitionController!,
      curve: Curves.easeOutCubic,
    );

    _backgroundFadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _backgroundFadeAnimation = CurvedAnimation(
      parent: _backgroundFadeController!,
      curve: Curves.easeInOut,
    );

    _percentageController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _percentageAnimation = StepTween(begin: 0, end: 100).animate(
      CurvedAnimation(parent: _percentageController!, curve: Curves.easeInOut),
    );

    _layoutTransitionController!.forward();
    _backgroundFadeController!.forward();
    _percentageController!.forward();
  }

  void _startAnalysis() {
    setState(() => _isAnalyzing = true);
    _initAnalysisAnimations();
  }

  void _onAnalysisComplete() {
    if (!mounted || _isDisposed) return;
    setState(() => _isAnalysisComplete = true);
    if (_redirectScheduled) return;
    _redirectScheduled = true;
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || _isDisposed) return;
      _videoController?.pause();
      // Use go() to replace DemoScreen2 with DemoResult (no nesting)
      context.go(AppRoutes.demoResult);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_videoController == null || !_isInitialized) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _videoController!.pause();
        break;
      case AppLifecycleState.resumed:
        // Always resume playing - video should loop continuously
        // Delay slightly for iOS to properly restore video surface
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _videoController != null && _isInitialized) {
            _videoController!.play();
          }
        });
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _usePreloadedController(VideoPlayerController controller) {
    try {
      _videoController = controller;
      // Register with manager for cleanup on hot restart
      ActiveOperationsManager.instance.registerVideoController(controller);
      _isInitialized = controller.value.isInitialized;
      controller.setLooping(true);
      controller.setVolume(0.0);
      controller.play();
// Track that video is playing
      setState(() {});
    } catch (e) {
      debugPrint('Error using preloaded controller: $e');
      setState(() => _errorMessage = 'Failed to use preloaded video');
    }
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      // Use the preloader service for consistent iOS handling
      final controller = await DemoVideoPreloader.instance.takeWhenReady(
        timeout: const Duration(seconds: 10),
      );
      
      if (_isDisposed || !mounted) {
        controller?.dispose();
        return;
      }
      
      if (controller != null) {
        _videoController = controller;
        // Register with manager for cleanup on hot restart
        ActiveOperationsManager.instance.registerVideoController(controller);
        controller.play();
// Track that video is playing
        setState(() => _isInitialized = true);
      } else {
        // Fallback to direct asset loading
        final fallbackController = VideoPlayerController.asset('assets/videos/gym.mp4');
        _videoController = fallbackController;
        // Register with manager for cleanup on hot restart
        ActiveOperationsManager.instance.registerVideoController(fallbackController);
        await fallbackController.initialize();
        await fallbackController.setLooping(true);
        await fallbackController.setVolume(0.0);
        await fallbackController.play();
// Track that video is playing
        
        if (mounted && !_isDisposed) {
          setState(() => _isInitialized = true);
        }
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      if (mounted && !_isDisposed) {
        setState(() => _errorMessage = 'Failed to load video');
      }
    }
  }

  void _toggleMute() {
    if (_videoController != null && _isInitialized) {
      setState(() {
        _isMuted = !_isMuted;
        _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
      });
    }
  }

  void _closeAndNavigateBack() {
    // Unregister and dispose video controller
    if (_videoController != null) {
      ActiveOperationsManager.instance.unregisterVideoController(_videoController!);
      _videoController!.dispose();
    }
    context.go(AppRoutes.demo);
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    // Unregister and dispose video controller
    if (_videoController != null) {
      ActiveOperationsManager.instance.unregisterVideoController(_videoController!);
      _videoController!.dispose();
    }
    _percentageController?.dispose();
    _backgroundFadeController?.dispose();
    _layoutTransitionController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Animated fire gradient - shows through when city background fades out
          if (_isAnalyzing)
            const Positioned.fill(
              child: AnimatedFireGradient(),
            ),
          // City background (fades out during analysis)
          // Uses FadeTransition instead of Opacity for better iOS performance
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _isAnalyzing && _backgroundFadeAnimation != null
                ? RepaintBoundary(
                    child: FadeTransition(
                      opacity: Tween<double>(begin: 1.0, end: 0.0)
                          .animate(_backgroundFadeAnimation!),
                      child: Image.asset('assets/images/city.jpg', fit: BoxFit.cover),
                    ),
                  )
                : Image.asset('assets/images/city.jpg', fit: BoxFit.cover),
          ),
          SafeArea(
            top: true,
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(
                      ResponsiveSize.horizontalPadding(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppBarWithAnalysis(
                          usedCount: 1,
                          totalCount: 0,
                          badgeLabel: 'Demo',
                        ),
                        SizedBox(height: ResponsiveSize.verticalSpacing(context, 24)),
                        Expanded(
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topCenter,
                            child: VideoPlayerWidget(
                              controller: _videoController,
                              isInitialized: _isInitialized,
                              isMuted: _isMuted,
                              onMuteToggle: _toggleMute,
                              errorMessage: _errorMessage,
                            ),
                          ),
                        ),
                        SizedBox(height: ResponsiveSize.verticalSpacing(context, 24)),
                        // Percentage and analyzing text
                        if (_isAnalyzing && _layoutTransitionAnimation != null)
                          RepaintBoundary(
                            child: SizeTransition(
                              sizeFactor: _layoutTransitionAnimation!,
                              axisAlignment: -1.0,
                              child: FadeTransition(
                                opacity: _layoutTransitionAnimation!,
                                child: Column(
                                  children: [
                                    _buildAnalysisPercentage(),
                                    _buildAnalysisStatus(),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        // Card transitions
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 600),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: SizeTransition(
                              sizeFactor: animation,
                              axisAlignment: -1.0,
                              child: child,
                            ),
                          ),
                          child: _isAnalyzing
                              ? DemoAnalysisCard(
                                  key: const ValueKey('analysis'),
                                  onClose: _closeAndNavigateBack,
                                  onComplete: _onAnalysisComplete,
                                )
                              : DemoVideoCard(
                                  key: const ValueKey('button'),
                                  onClose: _closeAndNavigateBack,
                                  onAnalyze: _startAnalysis,
                                ),
                        ),
                        // Warning message during analysis
                        if (_isAnalyzing && _layoutTransitionAnimation != null)
                          RepaintBoundary(
                            child: SizeTransition(
                              sizeFactor: _layoutTransitionAnimation!,
                              axisAlignment: -1.0,
                              child: FadeTransition(
                                opacity: _layoutTransitionAnimation!,
                                child: Column(
                                  children: [
                                    const SizedBox(height: 20),
                                    _buildWarningMessage(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisPercentage() => FadeTransition(
    opacity: _backgroundFadeAnimation!,
    child: Center(
      child: AnimatedBuilder(
        animation: _percentageAnimation!,
        builder: (context, child) => Text(
          '${_percentageAnimation!.value}%',
          style: TextStyle(
            fontFamily: 'Geom',
            fontWeight: FontWeight.w300,
            fontSize: ResponsiveSize.text(context, 18),
            color: const Color(0xFFFEFEFE),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );

  Widget _buildAnalysisStatus() => FadeTransition(
    opacity: _backgroundFadeAnimation!,
    child: Center(
      child: _isAnalysisComplete
          ? Text(
              'Done',
              style: TextStyle(
                fontFamily: 'Geom',
                fontWeight: FontWeight.w300,
                fontSize: ResponsiveSize.text(context, 12),
                color: Colors.white.withValues(alpha: 0.3),
              ),
              textAlign: TextAlign.center,
            )
          : AnimatedEllipsisText(
              baseText: 'Analyzing',
              style: TextStyle(
                fontFamily: 'Geom',
                fontWeight: FontWeight.w300,
                fontSize: ResponsiveSize.text(context, 12),
                color: Colors.white.withValues(alpha: 0.3),
              ),
              textAlign: TextAlign.center,
              maxDots: 3,
              interval: const Duration(milliseconds: 315),
              isAnimating: true,
            ),
    ),
  );

  Widget _buildWarningMessage() => FadeTransition(
    opacity: _backgroundFadeAnimation!,
    child: Center(
      child: FractionallySizedBox(
        widthFactor: ResponsiveSize.isSmallScreen(context) ? 0.9 : 0.7,
        child: Text(
          'Don\'t close the App — analysis in progress, this might take 30-60 sec.',
          style: TextStyle(
            fontFamily: 'Geom',
            fontWeight: FontWeight.w300,
            fontSize: ResponsiveSize.text(context, 12),
            color: const Color(0xFFFEFEFE),
          ),
          textAlign: TextAlign.center,
          softWrap: true,
        ),
      ),
    ),
  );
}

class DemoVideoCard extends StatelessWidget {
  final VoidCallback? onClose;
  final VoidCallback? onAnalyze;

  const DemoVideoCard({super.key, this.onClose, this.onAnalyze});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.spacing(context, 40)),
      decoration: BoxDecoration(
        color: const Color(0x1FFEFEFE),
        borderRadius: BorderRadius.circular(ResponsiveSize.spacing(context, 60)),
      ),
      child: PrimaryButton(
        label: 'Analyze video',
        iconPath: 'assets/icons/analize.svg',
        onTap: onAnalyze,
      ),
    );
  }
}

class DemoAnalysisCard extends StatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onComplete;

  const DemoAnalysisCard({super.key, this.onClose, this.onComplete});

  @override
  State<DemoAnalysisCard> createState() => _DemoAnalysisCardState();
}

class _DemoAnalysisCardState extends State<DemoAnalysisCard>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _entranceController;
  late List<Animation<double>> _stepEntranceAnimations;
  bool _isDisposed = false;

  static const _stepLabels = [
    'Uploading video',
    'Niche detection',
    'Analyzing engagement',
    'Calculating hook score',
    'Generating recommendations',
  ];

  @override
  void initState() {
    super.initState();
    _initEntranceAnimations();
    _startAnimationSequence();
  }

  void _initEntranceAnimations() {
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _stepEntranceAnimations = List.generate(5, (index) {
      final startInterval = index * 0.15;
      final endInterval = min(startInterval + 0.4, 1.0);
      return CurvedAnimation(
        parent: _entranceController,
        curve: Interval(startInterval, endInterval, curve: Curves.easeOutCubic),
      );
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && !_isDisposed) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _entranceController.dispose();
    super.dispose();
  }

  void _startAnimationSequence() {
    final random = Random();
    const totalDuration = 20000;
    const stepCount = 5;

    final randomValues = List.generate(stepCount, (_) => random.nextDouble());
    final sum = randomValues.reduce((a, b) => a + b);
    final durations = randomValues.map((v) => (v / sum * totalDuration).round()).toList();
    durations[stepCount - 1] += totalDuration - durations.reduce((a, b) => a + b);

    int cumulativeDelay = 0;
    for (int i = 0; i < stepCount; i++) {
      cumulativeDelay += durations[i];
      final stepToComplete = i;
      Future.delayed(Duration(milliseconds: cumulativeDelay), () {
        if (mounted && !_isDisposed) {
          HapticFeedback.lightImpact();
          setState(() => _currentStep = stepToComplete + 1);
          if (_currentStep == 5) widget.onComplete?.call();
        }
      });
    }
  }

  Widget _buildStepIcon(int stepIndex) {
    if (stepIndex < _currentStep) {
      return SvgPicture.asset('assets/icons/checked.svg', width: 24, height: 24);
    } else if (stepIndex == _currentStep) {
      return const CustomSpinner(size: 24, strokeWidth: 2.0);
    }
    return SvgPicture.asset('assets/icons/circle.svg', width: 24, height: 24);
  }

  double _getStepOpacity(int stepIndex) => stepIndex <= _currentStep ? 1.0 : 0.3;

  Widget _buildStepRow(int stepIndex) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _stepEntranceAnimations[stepIndex],
      builder: (context, child) {
        final entranceValue = _stepEntranceAnimations[stepIndex].value;
        return Transform.translate(
          offset: Offset(20 * (1 - entranceValue), 0),
          child: Opacity(
            opacity: entranceValue * _getStepOpacity(stepIndex),
            child: child,
          ),
        );
      },
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            const SizedBox(width: 16),
            _buildStepIcon(stepIndex),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _stepLabels[stepIndex],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Geom',
                  fontWeight: FontWeight.w300,
                  fontSize: ResponsiveSize.text(context, 18),
                  color: const Color(0xFFFEFEFE),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.spacing(context, 40)),
      decoration: BoxDecoration(
        color: const Color(0x1FFEFEFE),
        borderRadius: BorderRadius.circular(ResponsiveSize.spacing(context, 60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, _buildStepRow),
      ),
    );
  }
}
