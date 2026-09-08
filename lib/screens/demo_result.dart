import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:hooko_v20/components/app_bar_with_analysis.dart';
import 'package:hooko_v20/components/small_icon_button.dart';
import 'package:hooko_v20/components/animated_fire_gradient.dart';
import 'package:hooko_v20/components/video_player_widget.dart';
import 'package:hooko_v20/components/half_circle_gauge.dart';
import 'package:hooko_v20/components/small_dark_button.dart';
import 'package:hooko_v20/components/ios_modal_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:hooko_v20/nav.dart';
import 'package:hooko_v20/theme.dart';
import 'package:hooko_v20/components/audio_score_card.dart';
import 'package:hooko_v20/components/visual_score_card.dart';
import 'package:hooko_v20/components/say_this.dart';
import 'package:hooko_v20/components/show_this.dart';
import 'package:hooko_v20/components/pro_tips.dart';
import 'package:hooko_v20/components/suggested_caption.dart';
import 'package:hooko_v20/components/suggested_hashtags.dart';
import 'package:hooko_v20/components/updated_script.dart';
import 'package:hooko_v20/components/hook_viral_example.dart';
import 'package:hooko_v20/components/synced_height_row.dart';
import 'package:hooko_v20/components/result_shared_widgets.dart';
import 'package:hooko_v20/services/active_operations_manager.dart';

class DemoResult extends StatefulWidget {
  const DemoResult({super.key});

  @override
  State<DemoResult> createState() => _DemoResultState();
}

class _DemoResultLeadingBox extends StatelessWidget {
  const _DemoResultLeadingBox();

  @override
  Widget build(BuildContext context) {
    const double size = 50.0;
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: offWhite.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Icon(
            Icons.fitness_center,
            size: 20,
            color: offWhite,
          ),
        ),
      ),
    );
  }
}

class _DemoResultState extends State<DemoResult>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _isMuted = false; // Start unmuted when results appear
  bool _isPlaying = false; // Start paused when results appear
  String? _errorMessage;

// Analysis state
  bool _isAnalyzing = false;
  bool _analysisComplete = true;

// Scroll controller for detecting scroll position
  final ScrollController _scrollController = ScrollController();
  bool _showBottomTabs = false;
  int _selectedAlternative = 0; // 0 = 1# Alternative, 1 = 2#, 2 = 3#
// Threshold for showing the bottom tabs (when scrolled past hook alternative section)
  final double _tabShowThreshold = 850;
// Visibility-based video pause state (replaced scroll offset approach)
  bool _videoPausedByVisibility = false;
  
  // Debounce timer for visibility changes to prevent rapid state updates
  Timer? _visibilityDebounceTimer;
  
  // Track if controller is disposed to allow recreation
  bool _isControllerDisposed = false;

// PageController for horizontal sliding between hook alternatives
  late PageController _hookPageController;

// Target score value (0.0 to 1.0) - update this based on results
  final double _targetScore = 0.55; // Example: 55% score

// Target scores for audio and visual cards
  final double _targetAudioScore = 68.0;
  final double _targetVisualScore = 42.0;

// Animation controllers
  AnimationController? _percentageController;
  AnimationController? _backgroundFadeController;
  Animation<double>? _backgroundFadeAnimation;

// Score animation controller - use ValueNotifier for efficient updates
  late AnimationController _scoreAnimationController;
  late Animation<double> _scoreAnimation;
  late Animation<double> _audioScoreAnimation;
  late Animation<double> _visualScoreAnimation;

// ValueNotifiers for score animations to avoid rebuilding entire tree
  final ValueNotifier<double> _scoreNotifier = ValueNotifier(0.0);
  final ValueNotifier<double> _audioScoreNotifier = ValueNotifier(0.0);
  final ValueNotifier<double> _visualScoreNotifier = ValueNotifier(0.0);

// Track last score value for haptic feedback
  int _lastHapticScore = -1;
  // Throttle haptics so we don't fire >1 click per ~32ms on ProMotion 120Hz.
  DateTime _lastHapticAt = DateTime.fromMillisecondsSinceEpoch(0);

// Guard against double-tap on close
  bool _isExiting = false;

// iOS Modal key
  final _iosModalKey = GlobalKey<IosModalScaffoldState>();

// Why not working expanded state - separate states for sequential animation
  bool _whyNotWorkingExpanded = false;
  bool _headerExpanded = false; // Controls header border radius
  bool _contentExpanded = false; // Controls content height

// Fade-in animation controller (runs once on page load)
  late AnimationController _fadeInController;
  late Animation<double> _fadeInAnimation;

// Cached dimension values (computed once in didChangeDependencies)
  double _cachedVideoHeight = 0;
  double _cachedGaugeContainerHeight = 0;
  double _cachedGaugeOverlap = 0;
  double _cachedGaugePadding = 0;
  double _cachedGaugeHorizontalInset = 0;
  bool _dimensionsCached = false;
  


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hookPageController = PageController(initialPage: 0);
    _initializeVideoPlayer();
    _initScoreAnimation();
    _initFadeInAnimation();
    _scrollController.addListener(_onScroll);
  }

  void _initFadeInAnimation() {
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeOutCubic,
    );
// Start fade-in immediately
    _fadeInController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
// Cache dimensions once - these don't change after initial layout
    if (!_dimensionsCached) {
      final screenHeight = MediaQuery.sizeOf(context).height;
      _cachedVideoHeight = screenHeight * 0.45;
      _cachedGaugeContainerHeight = ResponsiveSize.cardHeight(context, 200);
      _cachedGaugeOverlap = _cachedGaugeContainerHeight * 0.5;
      _cachedGaugePadding = ResponsiveSize.spacing(context, 32);
      _cachedGaugeHorizontalInset = ResponsiveSize.spacing(context, 40);
      _dimensionsCached = true;
    }
  }

  void _onScroll() {
    // Guard: don't access controller after widget is disposed
    if (!mounted) return;
    
    final offset = _scrollController.offset;
    
    // Show/hide bottom tabs only - video pause is handled by visibility detector
    final shouldShow = offset > _tabShowThreshold;
    if (shouldShow != _showBottomTabs) {
      setState(() => _showBottomTabs = shouldShow);
    }
  }
  
  /// Called when the VisualScoreCard visibility changes.
  /// Pauses video when thumbnail is completely off-screen.
  /// Uses debouncing to prevent rapid state updates from small visibility changes.
  void _onThumbnailVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;
    
    final isVisible = info.visibleFraction > 0;
    
    // Cancel any pending debounce
    _visibilityDebounceTimer?.cancel();
    
    // Debounce visibility changes to prevent rapid state updates
    _visibilityDebounceTimer = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      
      if (!isVisible && !_videoPausedByVisibility) {
        // Thumbnail went completely off-screen - pause and dispose controller
        _videoPausedByVisibility = true;
        
        if (_videoController != null && _isInitialized && !_isControllerDisposed) {
          _videoController!.pause();
          // Dispose controller to free GPU resources
          _disposeVideoController();
        }
        
        if (mounted) {
          setState(() => _isPlaying = false);
        }
      } else if (isVisible && _videoPausedByVisibility) {
        // Thumbnail came back on screen - recreate controller so thumbnail shows video frame
        // but do NOT auto-play, user must manually tap to play
        _videoPausedByVisibility = false;
        if (_isControllerDisposed) {
          _recreateVideoController();
        }
      }
    });
  }
  
  /// Disposes the video controller to free GPU resources
  void _disposeVideoController() {
    if (_videoController != null && !_isControllerDisposed) {
      ActiveOperationsManager.instance.unregisterVideoController(_videoController!);
      _videoController!.dispose();
      _videoController = null; // Set to null so thumbnail shows loading state
      _isControllerDisposed = true;
      _isInitialized = false;
    }
  }
  
  /// Recreates the video controller when user wants to play
  Future<void> _recreateVideoController() async {
    if (!_isControllerDisposed) return;
    
    try {
      final controller = VideoPlayerController.asset('assets/videos/gym.mp4');
      _videoController = controller;
      _isControllerDisposed = false;
      
      ActiveOperationsManager.instance.registerVideoController(controller);
      
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(_isMuted ? 0.0 : 1.0);
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error recreating video player: $e');
      if (mounted) setState(() => _errorMessage = 'Failed to load video');
    }
  }

  void _animateToHookAlternative(int index) {
    _hookPageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _closeWithAnimation() {
    if (_isExiting) return;
    setState(() => _isExiting = true);

    // Navigate to home - GoRouter's reverse transition handles the slide down
    // Note: Free users will see home but can't upload (paywall later with RevenueCat)
    if (mounted) context.go(AppRoutes.home);
  }

  void _initScoreAnimation() {
    _scoreAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

// Use the same curve for all animations
    final curvedAnimation = CurvedAnimation(
      parent: _scoreAnimationController,
// Strong ease-out so the final 8-10 points slow down noticeably
      curve: Curves.easeOutExpo,
    );

    _scoreAnimation =
        Tween<double>(begin: 0.0, end: _targetScore).animate(curvedAnimation);

    _audioScoreAnimation = Tween<double>(begin: 0.0, end: _targetAudioScore)
        .animate(curvedAnimation);

    _visualScoreAnimation = Tween<double>(begin: 0.0, end: _targetVisualScore)
        .animate(curvedAnimation);

    _scoreAnimationController.addListener(() {
      final newScore = _scoreAnimation.value;
      final newScoreInt = (newScore * 100).round();

// Trigger haptic feedback when integer score value changes
      if (newScoreInt != _lastHapticScore) {
        _lastHapticScore = newScoreInt;
        final now = DateTime.now();
        if (now.difference(_lastHapticAt).inMilliseconds >= 32) {
          _lastHapticAt = now;
          HapticFeedback.selectionClick();
        }
      }

// Update via ValueNotifier - only rebuilds listening widgets, not entire tree
      _scoreNotifier.value = newScore;
      _audioScoreNotifier.value = _audioScoreAnimation.value;
      _visualScoreNotifier.value = _visualScoreAnimation.value;
    });

// Start the animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
// Reset haptic tracking and start animation
        _lastHapticScore = -1;
        _scoreAnimationController.forward();
      }
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
        // Only resume if user had it playing before app went to background
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _videoController != null && _isInitialized && _isPlaying) {
            _videoController!.play();
          }
        });
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      final controller = VideoPlayerController.asset('assets/videos/gym.mp4');
      _videoController = controller;
      
      // Register with manager for cleanup on hot restart
      ActiveOperationsManager.instance.registerVideoController(controller);

      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(_isMuted ? 0.0 : 1.0);
      // Don't auto-play - video starts paused when results appear
      // User can tap left side to play

      if (mounted) setState(() {
        _isInitialized = true;
        _isPlaying = false;
      });
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      if (mounted) setState(() => _errorMessage = 'Failed to load video');
    }
  }

  Future<void> _togglePlayPause() async {
    // If controller was disposed, recreate it first
    if (_isControllerDisposed) {
      setState(() => _isPlaying = true); // Show loading state
      await _recreateVideoController();
      if (mounted && _videoController != null && _isInitialized) {
        _videoController!.play();
      }
      return;
    }
    
    if (_videoController != null && _isInitialized) {
      setState(() {
        _isPlaying = !_isPlaying;
        if (_isPlaying) {
          _videoController!.play();
        } else {
          _videoController!.pause();
        }
      });
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

  Future<void> _showScoreDetailsSheet() async {
    debugPrint('DemoResult: _showScoreDetailsSheet invoked');
    final scoreInt = (_targetScore * 100).round();
    final benchmarkScore = 70;
    final gap = scoreInt - benchmarkScore;
    final niche = 'Fitness & Health';

    await _iosModalKey.currentState?.showModal(
      builder: (context, dismiss) {
// Ensure bottom spacing is visually 40dp total (including safe area).
        final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
        double bottomPad = 40.0 - safeBottom;
        if (bottomPad < 0) bottomPad = 0;

        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [modalGradientTop, modalGradientBottom],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(60)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(40, 20, 40, bottomPad),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'How is this calculated?',
                    style: TextStyle(
                      fontFamily: 'Geom',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveSize.text(context, 18),
                      color: ink,
                    ),
                  ),
                  SizedBox(height: ResponsiveSize.verticalSpacing(context, 20)),
// Score details card
                  ScoreDetailsCard(
                    scoreValue: '$scoreInt/100',
                    gapValue: '$gap points below benchmark',
                    niche: niche,
                    averageValue: '$benchmarkScore/100',
                  ),
                  SizedBox(height: ResponsiveSize.verticalSpacing(context, 12)),
// Industry data card
                  IndustryDataCard(
                    niche: niche,
                    benchmarkScore: benchmarkScore,
                    // Demo uses hardcoded values for Fitness & Health niche
                    tiktokEngagement: 2.5,
                    instagramEngagement: 2.3,
                    youtubeEngagement: 1.3,
                    avgEngagementFromDb: 2.0,
                  ),
                  SizedBox(height: ResponsiveSize.verticalSpacing(context, 12)),
// Sources card
                  const SourcesCard(),
                  SizedBox(height: ResponsiveSize.verticalSpacing(context, 20)),
// Dark "Got it" button
                  SizedBox(
                    width: double.infinity,
                    child: SmallDarkButton(
                      label: 'Got it',
                      onTap: () {
                        debugPrint('DemoResult: Bottom sheet "Got it" tapped');
                        dismiss();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _visibilityDebounceTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _hookPageController.dispose();
    // Unregister and dispose video controller
    if (_videoController != null && !_isControllerDisposed) {
      ActiveOperationsManager.instance.unregisterVideoController(_videoController!);
      _videoController!.dispose();
    }
    _percentageController?.dispose();
    _backgroundFadeController?.dispose();
    _scoreAnimationController.dispose();
    _fadeInController.dispose();
    _scoreNotifier.dispose();
    _audioScoreNotifier.dispose();
    _visualScoreNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IosModalScaffold(
            key: _iosModalKey,
            staticBackground: const StaticFireGradient(),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: FadeTransition(
                opacity: _fadeInAnimation,
                child: Stack(
                  children: [
// Scrollable content (behind gradient overlay)
                    SafeArea(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          ResponsiveSize.horizontalPadding(context),
                          ResponsiveSize.horizontalPadding(context),
                          ResponsiveSize.horizontalPadding(context),
                          ResponsiveSize.horizontalPadding(context),
                        ),
                        child: Column(
                          children: [
// Spacer for app bar
                            SizedBox(
                                height: 60 +
                                    ResponsiveSize.verticalSpacing(
                                        context, 24)),
// When analysis is complete, keep the video but reduce its height by 30%
// and pin it to the top. Use Flexible/Spacer to avoid unbounded height issues.
                            _analysisComplete
                                ? Expanded(
                                    child: ScrollConfiguration(
                                      behavior: ScrollConfiguration.of(context)
                                          .copyWith(scrollbars: false),
                                      child: RepaintBoundary(
                                        child: SingleChildScrollView(
                                          controller: _scrollController,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          clipBehavior: Clip.none,
                                          child: Column(
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: offWhite.withValues(
                                                      alpha: 0.12),
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(60),
                                                    topRight:
                                                        Radius.circular(60),
                                                    bottomLeft:
                                                        Radius.circular(52),
                                                    bottomRight:
                                                        Radius.circular(52),
                                                  ),
                                                ),
                                                clipBehavior: Clip.none,
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SizedBox(
                                                      height: _cachedVideoHeight +
                                                          _cachedGaugeOverlap +
                                                          ResponsiveSize
                                                              .spacing(
                                                                  context, 76),
                                                      child: Stack(
                                                        clipBehavior: Clip.none,
                                                        children: [
                                                          SizedBox(
                                                            height:
                                                                _cachedVideoHeight,
                                                            child:
                                                                VideoPlayerWidget(
                                                              controller:
                                                                  _videoController,
                                                              isInitialized:
                                                                  _isInitialized,
                                                              isMuted: _isMuted,
                                                              onMuteToggle:
                                                                  _toggleMute,
                                                              errorMessage:
                                                                  _errorMessage,
                                                              borderOpacity:
                                                                  0.0,
                                                              fillParent: true,
                                                              // Disable auto-pause here - let the thumbnail's visibility detector control pause/resume
                                                              autoPauseOnScroll: false,
                                                              // Show play/pause control on left, mute on right
                                                              showPlayPauseControl: true,
                                                              onPlayPauseToggle: _togglePlayPause,
                                                              isPlaying: _isPlaying,
                                                            ),
                                                          ),
                                                          Positioned(
                                                            left:
                                                                _cachedGaugeHorizontalInset,
                                                            right:
                                                                _cachedGaugeHorizontalInset,
                                                            bottom:
                                                                ResponsiveSize
                                                                    .spacing(
                                                                        context,
                                                                        32),
                                                            child: Container(
                                                              width: double
                                                                  .infinity,
                                                              padding:
                                                                  EdgeInsets.all(
                                                                      _cachedGaugePadding),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .surface,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .only(
                                                                  topLeft: Radius
                                                                      .circular(
                                                                    ResponsiveSize
                                                                        .radius(
                                                                            context,
                                                                            190),
                                                                  ),
                                                                  topRight: Radius
                                                                      .circular(
                                                                    ResponsiveSize
                                                                        .radius(
                                                                            context,
                                                                            190),
                                                                  ),
                                                                  bottomLeft: Radius
                                                                      .circular(
                                                                    ResponsiveSize
                                                                        .radius(
                                                                            context,
                                                                            60),
                                                                  ),
                                                                  bottomRight:
                                                                      Radius
                                                                          .circular(
                                                                    ResponsiveSize
                                                                        .radius(
                                                                            context,
                                                                            60),
                                                                  ),
                                                                ),
                                                              ),
                                                              child:
                                                                  ValueListenableBuilder<
                                                                      double>(
                                                                valueListenable:
                                                                    _scoreNotifier,
                                                                builder: (context,
                                                                        score,
                                                                        _) =>
                                                                    HalfCircleGauge(
                                                                  score: score,
                                                                  label: '',
                                                                  benchmark: 70,
                                                                  nicheName: 'Fitness & Health',
                                                                  onSeeDetails:
                                                                      () =>
                                                                          _showScoreDetailsSheet(),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.fromLTRB(
                                                        ResponsiveSize.spacing(
                                                            context, 20),
                                                        0,
                                                        ResponsiveSize.spacing(
                                                            context, 20),
                                                        ResponsiveSize.spacing(
                                                            context, 24),
                                                      ),
                                                      child: Column(
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Flexible(
                                                                child: Text(
                                                                  'Your current hook',
                                                                  style:
                                                                      TextStyle(
                                                                    fontFamily:
                                                                        'Geom',
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    fontSize:
                                                                        ResponsiveSize.text(
                                                                            context,
                                                                            20),
                                                                    color:
                                                                        offWhite,
                                                                  ),
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  width: ResponsiveSize
                                                                      .spacing(
                                                                          context,
                                                                          8)),
                                                              Container(
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                  horizontal: ResponsiveSize
                                                                      .spacing(
                                                                          context,
                                                                          12),
                                                                  vertical: ResponsiveSize
                                                                      .spacing(
                                                                          context,
                                                                          6),
                                                                ),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: offWhite
                                                                      .withValues(
                                                                          alpha:
                                                                              0.12),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                    ResponsiveSize
                                                                        .radius(
                                                                            context,
                                                                            20),
                                                                  ),
                                                                ),
                                                                child: Text(
                                                                  '0-3 seconds',
                                                                  style:
                                                                      TextStyle(
                                                                    fontFamily:
                                                                        'Geom',
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w300,
                                                                    fontSize:
                                                                        ResponsiveSize.text(
                                                                            context,
                                                                            12),
                                                                    color:
                                                                        offWhite,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(
                                                              height:
                                                                  ResponsiveSize
                                                                      .spacing(
                                                                          context,
                                                                          16)),
                                                          VisibilityDetector(
                                                            key: const Key('visual-score-card-visibility'),
                                                            onVisibilityChanged: _onThumbnailVisibilityChanged,
                                                            child: SyncedHeightRow(
                                                              spacing: ResponsiveSize.spacing(context, 12),
                                                              left: ValueListenableBuilder<double>(
                                                                valueListenable: _audioScoreNotifier,
                                                                builder: (context, audioScore, _) =>
                                                                    AudioScoreCard(
                                                                  title: 'Your Audio',
                                                                  score: audioScore,
                                                                  quote: '"Stop doing sit-ups. Seriously. I wasted..."',
                                                                  subtitle: 'Good script with emotional hook',
                                                                ),
                                                              ),
                                                              right: ValueListenableBuilder<double>(
                                                                valueListenable: _visualScoreNotifier,
                                                                builder: (context, visualScore, _) =>
                                                                    VisualScoreCard(
                                                                  title: 'Your Visual',
                                                                  score: visualScore,
                                                                  videoAsset: 'assets/videos/gym.mp4',
                                                                  description: 'Static shot, no movement',
                                                                  videoController: _videoController,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                              height:
                                                                  ResponsiveSize
                                                                      .spacing(
                                                                          context,
                                                                          12)),
                                                          _buildWhyNotWorkingSection(),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 40),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      width: 50,
                                                      height: 50,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            offWhite.withValues(
                                                                alpha: 0.12),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16),
                                                      ),
                                                      child: Center(
                                                        child: SvgPicture.asset(
                                                          'assets/icons/icon_logo.svg',
                                                          width: 26,
                                                          height: 26,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            'Complete Hook Alternatives',
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Geom',
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize:
                                                                  ResponsiveSize
                                                                      .text(
                                                                          context,
                                                                          16),
                                                              color: offWhite,
                                                              height: 1.2,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                              height:
                                                                  ResponsiveSize
                                                                      .spacing(
                                                                          context,
                                                                          4)),
                                                          Text(
                                                            'Visual + Audio optimized for your audience',
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Geom',
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w300,
                                                              fontSize:
                                                                  ResponsiveSize
                                                                      .text(
                                                                          context,
                                                                          14),
                                                              color: offWhite
                                                                  .withValues(
                                                                      alpha:
                                                                          0.3),
                                                              height: 1.3,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(
                                                  height: ResponsiveSize
                                                      .verticalSpacing(
                                                          context, 16)),
                                              _HookAlternativesSlider(
                                                selectedIndex:
                                                    _selectedAlternative,
                                                pageController:
                                                    _hookPageController,
                                                onPageChanged: (index) {
                                                  setState(() =>
                                                      _selectedAlternative =
                                                          index);
                                                },
                                              ),
                                              SizedBox(
                                                  height: ResponsiveSize
                                                      .verticalSpacing(
                                                          context, 64)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Expanded(
                                    child:
                                        Container()), // Placeholder when not complete
                            if (_isAnalyzing &&
                                _backgroundFadeAnimation != null) ...[
                              const SizedBox(height: 20),
                              _buildWarningMessage(),
                            ],
                          ],
                        ),
                      ),
                    ),
// Top overlay - full width, content scrolls under this (middle layer)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: RepaintBoundary(child: Container(
                          height: MediaQuery.of(context).padding.top + 104,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF110A1D), // 100% at top
                                Color(0xFF110A1D), // 100% at 50%
                                Color(0xF7110A1D), // 97%
                                Color(0xF2110A1D), // 95%
                                Color(0xE6110A1D), // 90%
                                Color(0xD9110A1D), // 85%
                                Color(0xCC110A1D), // 80%
                                Color(0xB3110A1D), // 70%
                                Color(0x99110A1D), // 60%
                                Color(0x80110A1D), // 50%
                                Color(0x66110A1D), // 40%
                                Color(0x4D110A1D), // 30%
                                Color(0x33110A1D), // 20%
                                Color(0x1A110A1D), // 10%
                                Color(0x0D110A1D), // 5%
                                Color(0x00110A1D), // 0% at bottom
                              ],
                              stops: [
                                0.0,
                                0.5,
                                0.53,
                                0.56,
                                0.6,
                                0.64,
                                0.68,
                                0.72,
                                0.76,
                                0.8,
                                0.84,
                                0.88,
                                0.92,
                                0.95,
                                0.98,
                                1.0
                              ],
                            ),
                          ),
                        )),
                      ),
                    ),
// App bar on top (in front of gradient overlay)
                    SafeArea(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          ResponsiveSize.horizontalPadding(context),
                          ResponsiveSize.horizontalPadding(context),
                          ResponsiveSize.horizontalPadding(context),
                          0,
                        ),
                        child: AppBarWithAnalysis(
                          minimal: true,
                          leading: const _DemoResultLeadingBox(),
                          title: 'Fitness & Health',
                          subtitle: 'Scored against Fitness standarts',
                          trailing: SmallIconButton(
                            onPressed: _closeWithAnimation,
                            iconPath: 'assets/icons/close.svg',
                          ),
                        ),
                      ),
                    ),
// Bottom sticky tabs for hook alternatives
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      bottom: _showBottomTabs ? 0 : -120,
                      left: 0,
                      right: 0,
                      child: HookAlternativeTabs(
                        selectedIndex: _selectedAlternative,
                        count: 3,
                        onTabSelected: (index) {
                          setState(() => _selectedAlternative = index);
                          _animateToHookAlternative(index);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        );
  }

  Widget _buildWhyNotWorkingSection() {
    final reasons = [
      'Static visual: Standing still from top-to-knees, no movement to stop the scroll',
      'No pattern interrupt: First 2 seconds look like every other gym video - nothing unique',
      'Strong script, weak delivery: "I wasted 3 years" is powerful but buried 3 seconds in',
      'No text overlay: 85% of viewers watch on mute - they\'ll scroll past before hearing your hook',
      'Too much value too late: Squats, deadlifts, diet advice comes after most viewers have left',
    ];

    final redCircle = const Color(0xFFED1717).withValues(alpha: 0.12);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
// Gradient header
        GestureDetector(
          onTap: () async {
            if (_whyNotWorkingExpanded) {
// Closing: first collapse content, then change header border radius
              setState(() {
                _contentExpanded = false;
              });
              await Future.delayed(const Duration(milliseconds: 200));
              setState(() {
                _headerExpanded = false;
                _whyNotWorkingExpanded = false;
              });
            } else {
// Opening: first change header, then expand content after delay
              setState(() {
                _whyNotWorkingExpanded = true;
                _headerExpanded = true;
              });
              await Future.delayed(const Duration(milliseconds: 200));
              setState(() {
                _contentExpanded = true;
              });
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            constraints: BoxConstraints(
              minHeight: ResponsiveSize.spacing(context, 72),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveSize.spacing(context, 16),
              vertical: ResponsiveSize.spacing(context, 16),
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [audioAccent, visualAccent],
              ),
              borderRadius: _headerExpanded
                  ? BorderRadius.only(
                      topLeft:
                          Radius.circular(ResponsiveSize.spacing(context, 32)),
                      topRight:
                          Radius.circular(ResponsiveSize.spacing(context, 32)),
                    )
                  : BorderRadius.circular(ResponsiveSize.spacing(context, 32)),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/warning.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    offWhite,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Why its not working',
                    style: TextStyle(
                      fontFamily: 'Geom',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveSize.text(context, 16),
                      color: offWhite,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _whyNotWorkingExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: SvgPicture.asset(
                    'assets/icons/chevron-down.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      offWhite,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
// Expanded content - dark card with bullet points (slide down animation)
        ClipRect(
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            heightFactor: _contentExpanded ? 1.0 : 0.0,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveSize.spacing(context, 16),
                vertical: 24,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF110A1D),
                borderRadius: BorderRadius.only(
                  bottomLeft:
                      Radius.circular(ResponsiveSize.spacing(context, 32)),
                  bottomRight:
                      Radius.circular(ResponsiveSize.spacing(context, 32)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: reasons.asMap().entries.map((entry) {
                  final isLast = entry.key == reasons.length - 1;
                  final reason = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
// Orange circle with X
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: redCircle,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '×',
                              style: TextStyle(
                                fontFamily: 'Geom',
                                fontWeight: FontWeight.w600,
                                fontSize: ResponsiveSize.text(context, 16),
                                color: const Color(0xFFED1717),
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reason,
                            style: TextStyle(
                              fontFamily: 'Geom',
                              fontWeight: FontWeight.w300,
                              fontSize: ResponsiveSize.text(context, 16),
                              color: offWhite.withValues(alpha: 0.7),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWarningMessage() => AnimatedBuilder(
        animation: _backgroundFadeAnimation!,
        builder: (context, child) => Opacity(
          opacity: _backgroundFadeAnimation!.value,
          child: child,
        ),
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
        borderRadius:
            BorderRadius.circular(ResponsiveSize.spacing(context, 60)),
      ),
    );
  }
}

// Modal widgets moved to result_shared_widgets.dart

// Tab widgets moved to result_shared_widgets.dart

/// Hook tag pill with orange border
// ignore: unused_element
class _HookTag extends StatelessWidget {
  final String label;

  const _HookTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
// Match the sizing of the "0-3 seconds" badge container.
        horizontal: ResponsiveSize.spacing(context, 12),
        vertical: ResponsiveSize.spacing(context, 6),
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: audioAccent.withValues(alpha: 0.6),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(ResponsiveSize.radius(context, 20)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Geom',
          fontWeight: FontWeight.w300,
          fontSize: ResponsiveSize.text(context, 12),
          color: audioAccent,
        ),
      ),
    );
  }
}

/// Horizontal slider for hook alternatives with bounce animation
/// Optimized: Pre-measures all slides once on init, caches content widgets
/// Listens for ContentHeightChangedNotification to recalculate heights

class _HookAlternativesSlider extends StatefulWidget {
  final int selectedIndex;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;

  const _HookAlternativesSlider({
    required this.selectedIndex,
    required this.pageController,
    required this.onPageChanged,
  });

  @override
  State<_HookAlternativesSlider> createState() =>
      _HookAlternativesSliderState();
}

class _HookAlternativesSliderState extends State<_HookAlternativesSlider> {
// Precached heights - recalculated when content changes
  final List<double> _precachedHeights = [0, 0, 0];
  bool _heightsCalculated = false;
  double _currentHeight = 0;
  bool _isScrolling = false;
  bool _isResizing = false;
  Timer? _resizeEndTimer;
  int _measureAttempts = 0;

// Precached content widgets - built once, reused always
  late final List<Widget> _cachedContent;

// Keys for measuring each slide
  final List<GlobalKey> _measureKeys = [GlobalKey(), GlobalKey(), GlobalKey()];

// ValueNotifier for scroll position - avoids rebuilding entire widget tree
  final ValueNotifier<double> _pageNotifier = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
// Pre-build content widgets once - wrap in keyed containers for measurement
    _cachedContent = [
      MeasurableContent(key: _measureKeys[0], child: const _HookAlternative1Content()),
      MeasurableContent(key: _measureKeys[1], child: const _HookAlternative2Content()),
      MeasurableContent(key: _measureKeys[2], child: const _HookAlternative3Content()),
    ];
    widget.pageController.addListener(_onPageScroll);
// Schedule height calculation after a short delay to ensure layout is complete
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _calculateHeights();
    });
  }

  @override
  void dispose() {
    _resizeEndTimer?.cancel();
    widget.pageController.removeListener(_onPageScroll);
    _pageNotifier.dispose();
    super.dispose();
  }

  void _calculateHeights() {
    if (!mounted) return;

    _measureAttempts++;
    
    // Try to measure current page first
    final pageIndex = (widget.pageController.page?.round() ?? 0).clamp(0, 2);
    final renderBox =
        _measureKeys[pageIndex].currentContext?.findRenderObject() as RenderBox?;
    
    if (renderBox != null && renderBox.hasSize && renderBox.size.height > 100) {
      final height = renderBox.size.height;
      _precachedHeights[pageIndex] = height;
      
      setState(() {
        _heightsCalculated = true;
        _currentHeight = height;
      });
      
      // Try to measure other pages in background
      for (int i = 0; i < 3; i++) {
        if (i == pageIndex) continue;
        final otherBox =
            _measureKeys[i].currentContext?.findRenderObject() as RenderBox?;
        if (otherBox != null && otherBox.hasSize && otherBox.size.height > 100) {
          _precachedHeights[i] = otherBox.size.height;
        } else {
          // Use current page height as fallback for unmeasured pages
          _precachedHeights[i] = height;
        }
      }
    } else if (_measureAttempts < 15) {
      // Retry on next frame if not measured yet
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) _calculateHeights();
      });
    } else {
      // Fallback: use screen-based height
      final screenHeight = MediaQuery.sizeOf(context).height;
      setState(() {
        _heightsCalculated = true;
        _currentHeight = screenHeight * 1.2;
        for (int i = 0; i < 3; i++) {
          _precachedHeights[i] = _currentHeight;
        }
      });
    }
  }

  /// Recalculate heights when expandable content changes
  void _recalculateHeights() {
    if (!mounted) return;
    // Delay to let layout settle after expansion/collapse animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final pageIndex = (widget.pageController.page?.round() ?? 0).clamp(0, 2);
        final renderBox =
            _measureKeys[pageIndex].currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final newHeight = renderBox.size.height;
          _precachedHeights[pageIndex] = newHeight;
          if (newHeight != _currentHeight) {
            setState(() {
              _currentHeight = newHeight;
              _heightsCalculated = true;
            });
          }
        }
      });
    });
  }

  /// Called every frame the inner content's size changes (during the
  /// expand/collapse animation of nested expandable cards). This keeps the
  /// outer container height in sync with content so it never clips.
  void _onContentResized() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pageIndex = (widget.pageController.page?.round() ?? 0).clamp(0, 2);
      final renderBox = _measureKeys[pageIndex].currentContext?.findRenderObject()
          as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final newHeight = renderBox.size.height;
        if (newHeight > 0 && newHeight != _currentHeight) {
          _precachedHeights[pageIndex] = newHeight;
          setState(() {
            _currentHeight = newHeight;
            _heightsCalculated = true;
            _isResizing = true;
          });
          _resizeEndTimer?.cancel();
          _resizeEndTimer = Timer(const Duration(milliseconds: 350), () {
            if (mounted) setState(() => _isResizing = false);
          });
        }
      }
    });
  }

  void _onPageScroll() {
// Update page notifier for transform animations (no setState)
    if (widget.pageController.hasClients) {
      _pageNotifier.value = widget.pageController.page ?? 0.0;
    }

    if (!_heightsCalculated) return;

    final page = widget.pageController.page ?? 0;
    final isAtRest = (page - page.round()).abs() < 0.01;

    double newHeight;
    bool newIsScrolling;
    if (isAtRest) {
// At rest - measure actual content height for this page
      final pageIndex = page.round().clamp(0, 2);
      
      // Try to get fresh measurement from actual rendered content
      final renderBox =
          _measureKeys[pageIndex].currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize && renderBox.size.height > 100) {
        _precachedHeights[pageIndex] = renderBox.size.height;
      }
      
      newHeight = _precachedHeights[pageIndex];
      newIsScrolling = false;
    } else {
// During scroll - use maximum of all precached heights
      newHeight = _precachedHeights.reduce((a, b) => a > b ? a : b);
      newIsScrolling = true;
    }

    if (newHeight != _currentHeight || newIsScrolling != _isScrolling) {
      setState(() {
        _currentHeight = newHeight;
        _isScrolling = newIsScrolling;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
// Use larger fallback to ensure content is never clipped initially
    final screenHeight = MediaQuery.sizeOf(context).height;
    final fallbackHeight = screenHeight * 1.5;
    final duration = _isResizing
        ? const Duration(milliseconds: 0)
        : _isScrolling
            ? const Duration(milliseconds: 150)
            : const Duration(milliseconds: 300);

// Determine effective height - use fallback if heights not yet calculated
    final effectiveHeight = (_heightsCalculated && _currentHeight > 0)
        ? _currentHeight
        : fallbackHeight;

    return NotificationListener<ContentHeightChangedNotification>(
      onNotification: (notification) {
        _recalculateHeights();
        return true; // Stop propagation
      },
      child: NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (_) {
          _onContentResized();
          return true;
        },
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          height: effectiveHeight,
          child: PageView.builder(
            controller: widget.pageController,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            onPageChanged: widget.onPageChanged,
            itemCount: 3,
            itemBuilder: (context, index) {
// Use precached content directly - measurement keys are embedded in content
              return OptimizedPageTransform(
                index: index,
                pageNotifier: _pageNotifier,
                child: RepaintBoundary(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: _cachedContent[index],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// MeasurableContent and OptimizedPageTransform moved to result_shared_widgets.dart

/// Content for 1# Hook Alternative
class _HookAlternative1Content extends StatelessWidget {
  const _HookAlternative1Content();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
// Hook Alternative card
        Container(
          decoration: BoxDecoration(
            color: offWhite.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(52),
          ),
          clipBehavior: Clip.antiAlias,
          padding: EdgeInsets.all(ResponsiveSize.spacing(context, 24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '1# Hook Alternative',
                style: TextStyle(
                  fontFamily: 'Geom',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveSize.text(context, 20),
                  color: offWhite,
                ),
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 8)),
              Text(
                'Estimated Score:',
                style: TextStyle(
                  fontFamily: 'Geom',
                  fontWeight: FontWeight.w300,
                  fontSize: ResponsiveSize.text(context, 16),
                  color: offWhite.withValues(alpha: 0.30),
                ),
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 12)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset('assets/icons/fire.svg',
                      width: 32, height: 32),
                  SizedBox(width: ResponsiveSize.spacing(context, 4)),
                  const Text(
                    '78',
                    style: TextStyle(
                      fontFamily: 'Geom',
                      fontWeight: FontWeight.w800,
                      fontSize: 40,
                      color: Color(0xFFFEFEFE),
                      height: 1.0,
                    ),
                  ),
                  Text(
                    '/100',
                    style: TextStyle(
                      fontFamily: 'Geom',
                      fontWeight: FontWeight.w300,
                      fontSize: 16,
                      color: const Color(0xFFFEFEFE).withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 20)),
              SayThis(
                quote:
                    '"I wasted 3 YEARS doing hundreds of crunches. My belly fat? Went absolutely NOWHERE. Here\'s what actually works..."',
                tags: const [
                  'Frustrated confession',
                  'Dramatic pause',
                  'Emotional hook'
                ],
                rationaleBody:
                    'Leading with personal failure creates instant relatability - viewers who\'ve struggled feel seen.',
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 16)),
              ShowThis(
                quote:
                    'Open with close-up of belly pinch, zoom out to your frustrated face. Text overlay: "3 YEARS WASTED" in bold red. Then cut to gym setting.',
                tags: const [
                  'Belly close-up',
                  'Zoom out reveal',
                  'Bold text overlay'
                ],
                rationaleBody:
                    'Visual of belly immediately signals "weight loss content" and creates pattern interrupt.',
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 16)),
              ProTips(
                sections: [
                  TipSection(
                    title: 'Audio Tips:',
                    iconAsset: 'assets/icons/mic.svg',
                    iconColor: audioAccent,
                    tips: const [
                      TipItem(
                          'Lead with emotion: "I WASTED 3 years" hits harder than "Stop doing sit-ups"'),
                      TipItem(
                          'Emphasize "NOWHERE" with genuine disappointment in your voice'),
                      TipItem(
                          'Pause 1 second after "Here\'s what actually works..." - builds anticipation'),
                    ],
                  ),
                  TipSection(
                    title: 'Visual Tips:',
                    iconAsset: 'assets/icons/camera.svg',
                    iconColor: visualAccent,
                    tips: const [
                      TipItem(
                          'Start with belly pinch close-up (immediate pattern interrupt)'),
                      TipItem('Zoom out to reveal your frustrated expression'),
                      TipItem(
                          'Text overlay "3 YEARS WASTED" in bold red - hooks silent scrollers'),
                    ],
                  ),
                  TipSection(
                    title: 'Timing Tips:',
                    iconData: Icons.timer_outlined,
                    iconColor: offWhite,
                    tips: const [
                      TipItem('0-1 sec: Belly close-up + "I wasted 3 YEARS"'),
                      TipItem('1-2 sec: Zoom to frustrated face + "crunches"'),
                      TipItem(
                          '2-3 sec: Zoom out + "My belly fat went absolutely NOWHERE"'),
                      TipItem(
                          '3-5 sec: "Here\'s what actually works..." + cut to squat demo'),
                    ],
                  ),
                ],
                generalTips: const [
                  TipItem(
                      'Your "I wasted 3 years" line is GOLD - move it to the very first second'),
                  TipItem(
                      'Confession-style opening builds trust before you give advice'),
                  TipItem(
                      'Then deliver your value: squats, deadlifts, balanced diet'),
                ],
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 16)),
              UpdatedScript(
                sections: [
                  ScriptSection(
                    title: 'Say this after hook:',
                    iconAsset: 'assets/icons/mic.svg',
                    iconColor: audioAccent,
                    showCopyButton: true,
                    content:
                        '"Crunches only target a tiny muscle group — they DON\'T burn fat. What does? Compound movements. Squats. Deadlifts. Overhead press. These hit multiple muscles at once and torch way more calories. Pair that with a balanced diet — not a crash diet — and you\'ll see more results in 3 months than I saw in 3 years of sit-ups. And don\'t forget — sleep matters too. Your body recovers and burns fat while you rest. Consistency beats intensity every single time."',
                  ),
                  ScriptSection(
                    title: 'Show this after hook:',
                    iconAsset: 'assets/icons/camera.svg',
                    iconColor: visualAccent,
                    content:
                        'Cut to gym B-roll: quick clips of you doing squats, deadlifts, overhead press (1–2 sec each). Text overlays pop in: "Squats ✅", "Deadlifts ✅", "Balanced Diet ✅". Use dynamic camera angles — low angle on squats, side angle on deadlifts. End with you back on camera, confident posture, direct eye contact.',
                  ),
                ],
                ctaTip: CtaTip(
                  sayThisTitle: 'Say this:',
                  sayThisContent:
                      '"Follow me for more fitness myths I had to learn the hard way. Save this before your next workout."',
                  showThisTitle: 'Show this:',
                  showThisContent:
                      'Point at camera on "Follow me." Text overlay: "SAVE THIS 📌" with animated bookmark icon. Keep eye contact, confident energy.',
                ),
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 16)),
              SuggestedCaption(
                caption:
                    'I can\'t believe I wasted 3 YEARS doing the wrong exercises 😭 If you\'re doing endless crunches expecting abs, STOP. Here\'s what actually worked for me... (and the science backs it up) 💪',
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 16)),
              SuggestedHashtags(
                hashtags: const [
                  '#fitness',
                  '#gym',
                  '#workout',
                  '#bellyfat',
                  '#fatloss',
                  '#absworkout',
                  '#fitnessmyths',
                  '#gymfails',
                  '#weightloss',
                  '#fitnesstransformation',
                ],
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 16)),
              HookViralExample(
                thumbnailUrl: 'https://img.youtube.com/vi/ocL5odaibsQ/maxresdefault.jpg',
                tags: ['Emotional Confession', 'Solution'],
                description: 'Opens with a personal confession about the common belly fat mistakes everyone makes — the exact same "I did X wrong, here\'s the truth" emotional structure suggested in Hook #1.',
                youtubeUrl: 'https://www.youtube.com/shorts/ocL5odaibsQ',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Content for 2# Hook Alternative
class _HookAlternative2Content extends StatelessWidget {
  const _HookAlternative2Content();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
// Hook Alternative card
        Container(
          decoration: BoxDecoration(
            color: offWhite.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(52),
          ),
          clipBehavior: Clip.antiAlias,
          padding: EdgeInsets.all(ResponsiveSize.spacing(context, 24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '2# Hook Alternative',
                style: TextStyle(
                  fontFamily: 'Geom',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveSize.text(context, 20),
                  color: offWhite,
                ),
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 8)),
              Text(
                'Estimated Score:',
                style: TextStyle(
                  fontFamily: 'Geom',
                  fontWeight: FontWeight.w300,
                  fontSize: ResponsiveSize.text(context, 16),
                  color: offWhite.withValues(alpha: 0.30),
                ),
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 12)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset('assets/icons/fire.svg',
                      width: 32, height: 32),
                  SizedBox(width: ResponsiveSize.spacing(context, 4)),
                  const Text(
                    '75',
                    style: TextStyle(
                      fontFamily: 'Geom',
                      fontWeight: FontWeight.w800,
                      fontSize: 40,
                      color: Color(0xFFFEFEFE),
                      height: 1.0,
                    ),
                  ),
                  Text(
                    '/100',
                    style: TextStyle(
                      fontFamily: 'Geom',
                      fontWeight: FontWeight.w300,
                      fontSize: 16,
                      color: const Color(0xFFFEFEFE).withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 20)),
              SayThis(
                quote:
                    '"This mistake cost me 3 years. I did hundreds of sit-ups daily and NOTHING changed. Here\'s the truth about burning belly fat..."',
                tags: const [
                  'Confession hook',
                  'Time loss emphasis',
                  'Truth reveal'
                ],
                rationaleBody:
                    'Leading with "This mistake cost me 3 years" creates curiosity—what mistake? Viewers stay to find out.',
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 16)),
              ShowThis(
                quote:
                    'Open with you doing sit-ups, then abruptly stop and shake your head. Text overlay: "3 YEARS WASTED" flashes. Cut to you standing up and gesturing to gym equipment.',
                tags: const [
                  'Action demonstration',
                  'Abrupt stop',
                  'Flash text overlay'
                ],
                rationaleBody:
                    'Showing the "wrong" exercise first, then stopping creates a pattern interrupt - viewers expect you to continue.',
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 16)),
              ProTips(
                sections: [
                  TipSection(
                    title: 'Audio Tips:',
                    iconAsset: 'assets/icons/mic.svg',
                    iconColor: audioAccent,
                    tips: const [
                      TipItem(
                          'Start with intrigue: "This mistake cost me 3 years" - creates immediate curiosity'),
                      TipItem(
                          'Emphasize "hundreds" and "NOTHING" to show effort vs. zero results'),
                      TipItem(
                          'Pause before "Here\'s the truth" - builds anticipation'),
                    ],
                  ),
                  TipSection(
                    title: 'Visual Tips:',
                    iconAsset: 'assets/icons/camera.svg',
                    iconColor: visualAccent,
                    tips: const [
                      TipItem(
                          'Start mid-action doing sit-ups (shows what NOT to do)'),
                      TipItem('Abruptly stop and shake head in frustration'),
                      TipItem(
                          'Flash "3 YEARS WASTED" in bold red text for silent scrollers'),
                      TipItem('Stand up and gesture toward proper equipment'),
                    ],
                  ),
                  TipSection(
                    title: 'Timing Tips:',
                    iconData: Icons.timer_outlined,
                    iconColor: offWhite,
                    tips: const [
                      TipItem(
                          '0-1 sec: Mid sit-up + "This mistake cost me 3 years"'),
                      TipItem(
                          '1-2 sec: Stop abruptly + "I did hundreds of sit-ups daily"'),
                      TipItem(
                          '2-3 sec: Shake head + flash "3 YEARS WASTED" text'),
                      TipItem(
                          '3-5 sec: Stand up + "Here\'s the truth about burning belly fat" + gesture to equipment'),
                    ],
                  ),
                ],
                generalTips: const [
                  TipItem(
                      'This version uses action-based pattern interrupt - showing the wrong exercise first hooks viewers'),
                  TipItem(
                      'The abrupt stop creates surprise and breaks expectations'),
                  TipItem(
                      'Demonstrating what NOT to do before showing what works builds credibility'),
                ],
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 16)),
              UpdatedScript(
                sections: [
                  ScriptSection(
                    title: 'Say this after hook:',
                    iconAsset: 'assets/icons/mic.svg',
                    iconColor: audioAccent,
                    showCopyButton: true,
                    content:
                        '"The truth is — sit-ups and crunches are one of the LEAST effective ways to lose belly fat. You can\'t spot-reduce fat. Period. What actually works is full-body strength training. Squats, deadlifts, compound movements that engage your entire body. Add a clean, balanced diet — not some 7-day detox — and your body will start burning fat everywhere, including your belly. Throw in consistent cardio and proper sleep, and you\'ve got the formula. It\'s not complicated — it just takes consistency."',
                  ),
                  ScriptSection(
                    title: 'Show this after hook:',
                    iconAsset: 'assets/icons/camera.svg',
                    iconColor: visualAccent,
                    content:
                        'Stand up from sit-up position and gesture toward gym equipment. Quick cuts: you performing squats (front angle), deadlifts (side angle), then a meal prep shot. Text overlays: "❌ Spot Reduction = MYTH", "✅ Compound Lifts", "✅ Balanced Diet". End back on camera with confident, direct eye contact.',
                  ),
                ],
                ctaTip: CtaTip(
                  sayThisTitle: 'Say this:',
                  sayThisContent:
                      '"Don\'t make the same mistake I did for 3 years. Drop a 💪 if you\'re switching to compound lifts — and follow for more no-BS fitness tips."',
                  showThisTitle: 'Show this:',
                  showThisContent:
                      'Direct eye contact, point at camera on "Don\'t make the same mistake." Text overlay: "DROP A 💪 + FOLLOW" with subtle animation. End on your handle.',
                ),
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 16)),
              SuggestedCaption(
                caption:
                    'This mistake stole 3 YEARS of my life 😭 Hundreds of sit-ups daily and my belly fat didn\'t budge. If you\'re making the same mistake, watch this before you waste another day. The truth about fat loss 👇💪',
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 16)),
              SuggestedHashtags(
                hashtags: const [
                  '#fitness',
                  '#gym',
                  '#workout',
                  '#fitnessmyths',
                  '#bellyfat',
                  '#absworkout',
                  '#situps',
                  '#crunches',
                  '#compoundlifts',
                  '#squats',
                ],
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 16)),
              HookViralExample(
                thumbnailUrl: 'https://img.youtube.com/vi/S65AAXwYP14/maxresdefault.jpg',
                tags: ['Mistake', 'Curiosity Gap'],
                description: 'Leads with common fat loss mistakes to avoid — a numbered curiosity-driven opener that mirrors Hook #2\'s "This mistake cost me 3 years" structure. Viewers stay to find out which mistakes they\'re making.',
                youtubeUrl: 'https://www.youtube.com/shorts/S65AAXwYP14',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Content for 3# Hook Alternative
class _HookAlternative3Content extends StatelessWidget {
  const _HookAlternative3Content();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
// Hook Alternative card
        Container(
          decoration: BoxDecoration(
            color: offWhite.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(52),
          ),
          clipBehavior: Clip.antiAlias,
          padding: EdgeInsets.all(ResponsiveSize.spacing(context, 24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '3# Hook Alternative',
                style: TextStyle(
                  fontFamily: 'Geom',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveSize.text(context, 20),
                  color: offWhite,
                ),
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 8)),
              Text(
                'Estimated Score:',
                style: TextStyle(
                  fontFamily: 'Geom',
                  fontWeight: FontWeight.w300,
                  fontSize: ResponsiveSize.text(context, 16),
                  color: offWhite.withValues(alpha: 0.30),
                ),
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 12)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset('assets/icons/fire.svg',
                      width: 32, height: 32),
                  SizedBox(width: ResponsiveSize.spacing(context, 4)),
                  const Text(
                    '82',
                    style: TextStyle(
                      fontFamily: 'Geom',
                      fontWeight: FontWeight.w800,
                      fontSize: 40,
                      color: Color(0xFFFEFEFE),
                      height: 1.0,
                    ),
                  ),
                  Text(
                    '/100',
                    style: TextStyle(
                      fontFamily: 'Geom',
                      fontWeight: FontWeight.w300,
                      fontSize: 16,
                      color: const Color(0xFFFEFEFE).withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 20)),
              SayThis(
                quote:
                    '"Crunches DON\'T burn belly fat. Squats and deadlifts do. Here\'s what 3 years of failure taught me..."',
                tags: const [
                  'Myth-busting',
                  'Solution upfront',
                  'Authority tone'
                ],
                rationaleBody:
                    'Leads with bold claim + immediate solution - gives value in first 3 seconds.',
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 16)),
              ShowThis(
                quote:
                    'Split screen: Top = someone doing crunches with ❌ overlay, Bottom = you doing squat with ✓ overlay. Text: "This burns fat →" pointing to squat.',
                tags: const [
                  'Split screen',
                  '❌ vs ✓ overlay',
                  'Exercise demo'
                ],
                rationaleBody:
                    'Visual comparison is instantly understood - no audio needed to get the point.',
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 16)),
              ProTips(
                sections: [
                  TipSection(
                    title: 'Audio Tips:',
                    iconAsset: 'assets/icons/mic.svg',
                    iconColor: audioAccent,
                    tips: const [
                      TipItem(
                          'Lead with bold myth-bust: "Crunches DON\'T burn belly fat"'),
                      TipItem(
                          'Immediately give the solution: "Squats and deadlifts do"'),
                      TipItem(
                          '"3 years of failure" adds credibility — you\'ve been there'),
                    ],
                  ),
                  TipSection(
                    title: 'Visual Tips:',
                    iconAsset: 'assets/icons/camera.svg',
                    iconColor: visualAccent,
                    tips: const [
                      TipItem(
                          'Split screen: crunches on top with ❌, your squat on bottom with ✓'),
                      TipItem(
                          'YOU demonstrating the squat (not stock footage)'),
                      TipItem(
                          'Text arrow: "This burns fat →" pointing to compound movement'),
                    ],
                  ),
                  TipSection(
                    title: 'Timing Tips:',
                    iconData: Icons.timer_outlined,
                    iconColor: offWhite,
                    tips: const [
                      TipItem(
                          '0-2 sec: Split screen + "Crunches DON\'T burn belly fat"'),
                      TipItem('2-3 sec: "Squats and deadlifts do." (squat demo)'),
                      TipItem(
                          '3-5 sec: "Here\'s what 3 years of failure taught me..."'),
                      TipItem(
                          '5+ sec: Transition to your full advice (diet, cardio, sleep)'),
                    ],
                  ),
                ],
                generalTips: const [
                  TipItem(
                      'This version delivers YOUR actual advice (compound movements) upfront'),
                  TipItem(
                      'Visual comparison works for silent viewers — no audio needed'),
                  TipItem(
                      'Matches your script\'s message about squats and deadlifts perfectly'),
                ],
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 16)),
              UpdatedScript(
                sections: [
                  ScriptSection(
                    title: 'Say this after hook:',
                    iconAsset: 'assets/icons/mic.svg',
                    iconColor: audioAccent,
                    showCopyButton: true,
                    content:
                        '"I spent 3 years doing hundreds of crunches every single day. My belly didn\'t change at ALL. Then I learned the science — you can\'t target fat loss. Your body decides where it burns fat. So what actually works? Compound lifts that use your WHOLE body. Squats, deadlifts, rows. They burn 3x more calories than isolation exercises. Combine that with eating in a slight caloric deficit — real food, not starvation — consistent cardio, and proper sleep. The fat melts off when you stop overcomplicating it."',
                  ),
                  ScriptSection(
                    title: 'Show this after hook:',
                    iconAsset: 'assets/icons/camera.svg',
                    iconColor: visualAccent,
                    content:
                        'Transition from split screen to full frame. Quick montage: you doing squats (low angle, powerful), deadlifts (side profile), barbell rows. Insert a "science fact" text card: "Compound lifts burn 3x more calories." Then a quick shot of a balanced meal plate. Keep cuts fast — 1.5 sec each. End back on camera with confident look.',
                  ),
                ],
                ctaTip: CtaTip(
                  sayThisTitle: 'Say this:',
                  sayThisContent:
                      '"That\'s 3 years of mistakes so you don\'t have to make them. Tag someone still doing 100 crunches a day. Follow for more myths I\'m exposing this week."',
                  showThisTitle: 'Show this:',
                  showThisContent:
                      'Crunches ❌ side fades out, you doing squats ✅ goes full screen. Text overlay: "TAG A FRIEND + FOLLOW 🔥". Confident look at camera, subtle nod.',
                ),
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 16)),
              SuggestedCaption(
                caption:
                    'The fitness industry LIED to you about belly fat 🚨 Crunches ❌ Squats & Deadlifts ✅ After 3 years of doing it wrong, here\'s what finally worked. Tag someone who needs to see this! 💪',
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 16)),
              SuggestedHashtags(
                hashtags: const [
                  '#fitness',
                  '#gym',
                  '#workout',
                  '#fitnessmyths',
                  '#bellyfat',
                  '#fatloss',
                  '#squats',
                  '#deadlifts',
                  '#compoundlifts',
                  '#strengthtraining',
                ],
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 16)),
              HookViralExample(
                thumbnailUrl: 'https://img.youtube.com/vi/0BNhpx_nxDM/maxresdefault.jpg',
                tags: ['Myth-Bust', 'Do This Instead'],
                description: 'Boldly calls out why most ab workouts are wrong and what actually works — the exact same myth-busting "Crunches DON\'T work, do THIS instead" structure suggested in Hook #3. Instantly understood even on mute.',
                youtubeUrl: 'https://www.youtube.com/shorts/0BNhpx_nxDM',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
