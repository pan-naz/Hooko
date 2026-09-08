import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:go_router/go_router.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:hooko_v20/components/app_bar_with_analysis.dart';
import 'package:hooko_v20/components/small_icon_button.dart';
import 'package:hooko_v20/components/animated_fire_gradient.dart';
import 'package:hooko_v20/components/video_player_widget.dart';
import 'package:hooko_v20/components/half_circle_gauge.dart';
import 'package:hooko_v20/components/small_dark_button.dart';
import 'package:hooko_v20/components/ios_modal_sheet.dart';
import 'package:hooko_v20/nav.dart';
import 'package:hooko_v20/theme.dart';
import 'package:hooko_v20/components/audio_score_card.dart';
import 'package:hooko_v20/components/visual_score_card.dart';
import 'package:hooko_v20/components/say_this.dart';
import 'package:hooko_v20/components/show_this.dart';
import 'package:hooko_v20/components/pro_tips.dart' show ProTips, TipSection, TipItem, ContentHeightChangedNotification;
import 'package:hooko_v20/components/suggested_caption.dart';
import 'package:hooko_v20/components/suggested_hashtags.dart';
import 'package:hooko_v20/components/updated_script.dart';
import 'package:hooko_v20/components/hook_viral_example.dart';
import 'package:hooko_v20/components/synced_height_row.dart';
import 'package:hooko_v20/components/result_shared_widgets.dart';
import 'package:hooko_v20/utils/niche_icon_mapping.dart';
import 'package:hooko_v20/models/analysis_result.dart';
import 'package:hooko_v20/models/niche.dart';
import 'package:hooko_v20/state/app_state.dart';
// NicheService not needed - niche data is cached in AnalysisResult
import 'package:hooko_v20/services/active_operations_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, debugPrint;

/// Screen displaying real analysis results from Gemini AI
class AnalysisResultScreen extends StatefulWidget {
  final AnalysisResult? analysisResult;
  final AssetEntity? videoAsset;

  const AnalysisResultScreen({
    super.key,
    this.analysisResult,
    this.videoAsset,
  });

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _isMuted = false; // Start unmuted when results appear
  bool _isPlaying = false; // Start paused when results appear
  String? _errorMessage;

  final ScrollController _scrollController = ScrollController();
  bool _showBottomTabs = false;
  // Removed _selectedAlternative - now managed by _HookAlternativesController
  double _tabShowThreshold = 850;
  
  // Controller for managing hook alternatives state (tabs + slider)
  final _hookAlternativesController = _HookAlternativesControllerState();
  // Visibility-based video pause state (same as DemoResult)
  bool _videoPausedByVisibility = false;
  
  // Debounce timer for visibility changes to prevent rapid state updates
  Timer? _visibilityDebounceTimer;
  
  // Track if controller is disposed to allow recreation
  bool _isControllerDisposed = false;

  // PageController is now managed by _HookAlternativesController

  // Analysis result - from widget or AppState
  late AnalysisResult _analysisResult;
  AssetEntity? _videoAsset;
  
  // Niche data from Supabase
  Niche? _niche;
  bool _nicheLoading = true;

  // Animation controllers
  late AnimationController _scoreAnimationController;
  late Animation<double> _scoreAnimation;
  late Animation<double> _audioScoreAnimation;
  late Animation<double> _visualScoreAnimation;

  final ValueNotifier<double> _scoreNotifier = ValueNotifier(0.0);
  final ValueNotifier<double> _audioScoreNotifier = ValueNotifier(0.0);
  final ValueNotifier<double> _visualScoreNotifier = ValueNotifier(0.0);

  int _lastHapticScore = -1;
  // Throttle haptics so we don't fire >1 click per ~32ms on ProMotion 120Hz.
  DateTime _lastHapticAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _isExiting = false;
  
  /// Whether viewing a saved history result (static mode, no video playback)
  bool _isFromHistory = false;
  final _iosModalKey = GlobalKey<IosModalScaffoldState>();

  // Removed _whyNotWorkingExpanded, _headerExpanded, _contentExpanded - now managed by _WhyNotWorkingSection widget

  late AnimationController _fadeInController;
  late Animation<double> _fadeInAnimation;

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
    // PageController is now managed by _HookAlternativesController
    
    // Get analysis result from widget or AppState
    final appState = AppStateProvider.read(context);
    final storedResult = widget.analysisResult ?? appState.latestAnalysisResult;
    
    // Check if viewing from history (static mode)
    _isFromHistory = appState.isViewingFromHistory;
    
    if (storedResult == null) {
      // No result available - redirect to home after build
      debugPrint('AnalysisResultScreen: No analysis result found, redirecting to home');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.home);
      });
      // Use a placeholder to prevent null errors during initial build
      _analysisResult = AnalysisResult.placeholder();
    } else {
      _analysisResult = storedResult;
    }
    
    _videoAsset = widget.videoAsset ?? appState.selectedVideoAsset;
    
    // Only initialize video player for fresh analysis (not from history)
    if (!_isFromHistory) {
      _initializeVideoPlayer();
      // Refresh today's server-side usage now that the result is on screen.
      // Moved here from AnalysisGate so tapping "Upload Video" doesn't pay
      // for a network round-trip before the picker opens.
      // ignore: discarded_futures
      appState.refreshDailyUsage();
    }
    
    _initScoreAnimation();
    _initFadeInAnimation();
    _scrollController.addListener(_onScroll);
    
    // ALWAYS use cached niche data from the saved result
    // This ensures niche info is STATIC - it won't change even if the niche table is updated later
    // For history view, we use exactly what was saved at analysis time
    _nicheLoading = false;
    _niche = Niche(
      id: '',
      // Use saved nicheName, or convert slug to readable name for older saved results
      name: _analysisResult.nicheName ?? _formatNicheSlugToName(_analysisResult.nicheSlug),
      slug: _analysisResult.nicheSlug,
      category: _analysisResult.nicheCategory ?? '',
      // CRITICAL: Always use the saved benchmark, never a hardcoded default
      avgHookScore: _analysisResult.benchmark,
      createdAt: DateTime.now(),
    );
    
  }

void _initFadeInAnimation() {
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      // For history view, start at full opacity to prevent any blink
      value: _isFromHistory ? 1.0 : 0.0,
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeOutCubic,
    );
    // Only animate for fresh analysis, not history
    if (!_isFromHistory) {
      _fadeInController.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dimensionsCached) {
      final screenHeight = MediaQuery.sizeOf(context).height;
      _cachedVideoHeight = screenHeight * 0.45;
      _cachedGaugeContainerHeight = ResponsiveSize.cardHeight(context, 200);
      _cachedGaugeOverlap = _cachedGaugeContainerHeight * 0.5;
      _cachedGaugePadding = ResponsiveSize.spacing(context, 32);
      _cachedGaugeHorizontalInset = ResponsiveSize.spacing(context, 40);
      
      // Responsive scroll threshold based on screen height
      // Reference: iPhone 16 Pro Max (932h) -> tabShow: 850
      _tabShowThreshold = screenHeight * 0.91;
      
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
    if (!_isControllerDisposed || _videoAsset == null) return;
    
    try {
      VideoPlayerController controller;
      
      if (kIsWeb) {
        setState(() => _errorMessage = 'Video playback not supported on web');
        return;
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final mediaUrl = await _videoAsset!.getMediaUrl();
        if (mediaUrl == null) {
          setState(() => _errorMessage = 'Video URL not available');
          return;
        }
        controller = VideoPlayerController.contentUri(Uri.parse(mediaUrl));
      } else {
        final file = await _videoAsset!.file;
        if (file == null) {
          setState(() => _errorMessage = 'Video file not available');
          return;
        }
        controller = VideoPlayerController.file(file);
      }
      
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

  // _animateToHookAlternative moved to _HookAlternativesController

  void _closeWithAnimation() {
    if (_isExiting) return;
    setState(() => _isExiting = true);
    
    // If viewing from history, go back to history page
    if (_isFromHistory) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _initScoreAnimation() {
    final result = _analysisResult;
    final targetScore = result.overallScore / 100.0;
    final targetAudioScore = result.audioScore.toDouble();
    final targetVisualScore = result.visualScore.toDouble();

    _scoreAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    // If viewing from history, skip animation and set final values directly
    if (_isFromHistory) {
      _scoreNotifier.value = targetScore;
      _audioScoreNotifier.value = targetAudioScore;
      _visualScoreNotifier.value = targetVisualScore;
      return;
    }

    final curvedAnimation = CurvedAnimation(
      parent: _scoreAnimationController,
      curve: Curves.easeOutExpo,
    );

    _scoreAnimation =
        Tween<double>(begin: 0.0, end: targetScore).animate(curvedAnimation);

    _audioScoreAnimation = Tween<double>(begin: 0.0, end: targetAudioScore)
        .animate(curvedAnimation);

    _visualScoreAnimation = Tween<double>(begin: 0.0, end: targetVisualScore)
        .animate(curvedAnimation);

    _scoreAnimationController.addListener(() {
      final newScore = _scoreAnimation.value;
      final newScoreInt = (newScore * 100).round();

      if (newScoreInt != _lastHapticScore) {
        _lastHapticScore = newScoreInt;
        final now = DateTime.now();
        if (now.difference(_lastHapticAt).inMilliseconds >= 32) {
          _lastHapticAt = now;
          HapticFeedback.selectionClick();
        }
      }

      _scoreNotifier.value = newScore;
      _audioScoreNotifier.value = _audioScoreAnimation.value;
      _visualScoreNotifier.value = _visualScoreAnimation.value;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
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
    if (_videoAsset == null) {
      setState(() => _errorMessage = 'No video available');
      return;
    }

    try {
      VideoPlayerController controller;

      if (kIsWeb) {
        setState(() => _errorMessage = 'Video playback not supported on web');
        return;
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final mediaUrl = await _videoAsset!.getMediaUrl();
        if (mediaUrl == null) {
          setState(() => _errorMessage = 'Video URL not available');
          return;
        }
        controller = VideoPlayerController.contentUri(Uri.parse(mediaUrl));
      } else {
        final file = await _videoAsset!.file;
        if (file == null) {
          setState(() => _errorMessage = 'Video file not available');
          return;
        }
        controller = VideoPlayerController.file(file);
      }

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

  void _toggleMute() {
    if (_videoController != null && _isInitialized) {
      setState(() {
        _isMuted = !_isMuted;
        _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
      });
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

  Future<void> _showScoreDetailsSheet() async {
    final result = _analysisResult;
    final scoreInt = result.overallScore;
    final benchmarkScore = _niche?.avgHookScore ?? result.benchmark;
    final gap = scoreInt - benchmarkScore;
    final niche = _niche?.name ?? 'General';

    await _iosModalKey.currentState?.showModal(
      builder: (context, dismiss) {
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
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(60)),
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
                  SizedBox(
                      height: ResponsiveSize.verticalSpacing(context, 20)),
                  ScoreDetailsCard(
                    scoreValue: '$scoreInt/100',
                    gapValue: gap >= 0
                        ? '$gap points above benchmark'
                        : '${gap.abs()} points below benchmark',
                    niche: niche,
                    averageValue: '$benchmarkScore/100',
                  ),
                  SizedBox(
                      height: ResponsiveSize.verticalSpacing(context, 12)),
                  IndustryDataCard(
                    niche: niche,
                    benchmarkScore: benchmarkScore,
                    tiktokEngagement: result.industryBenchmarkTiktok,
                    instagramEngagement: result.industryBenchmarkInstagram,
                    youtubeEngagement: result.industryBenchmarkYoutube,
                    avgEngagementFromDb: result.industryBenchmarkAvg,
                  ),
                  SizedBox(
                      height: ResponsiveSize.verticalSpacing(context, 12)),
                  const SourcesCard(),
                  SizedBox(
                      height: ResponsiveSize.verticalSpacing(context, 20)),
                  SizedBox(
                    width: double.infinity,
                    child: SmallDarkButton(
                      label: 'Got it',
                      onTap: () => dismiss(),
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
    _hookAlternativesController.dispose();
    // Unregister and dispose video controller
    if (_videoController != null && !_isControllerDisposed) {
      ActiveOperationsManager.instance.unregisterVideoController(_videoController!);
      _videoController!.dispose();
    }
    _scoreAnimationController.dispose();
    _fadeInController.dispose();
    _scoreNotifier.dispose();
    _audioScoreNotifier.dispose();
    _visualScoreNotifier.dispose();
    super.dispose();
  }

  /// Builds a static thumbnail for history view (no video playback)
  Widget _buildHistoryThumbnail() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(60),
        topRight: Radius.circular(60),
        bottomLeft: Radius.circular(52),
        bottomRight: Radius.circular(52),
      ),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: _analysisResult.thumbnailBase64 != null && _analysisResult.thumbnailBase64!.isNotEmpty
            ? Image.memory(
                base64Decode(_analysisResult.thumbnailBase64!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholderThumbnail(),
              )
            : _buildPlaceholderThumbnail(),
      ),
    );
  }

  /// Placeholder when no thumbnail is available
  Widget _buildPlaceholderThumbnail() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Icon(
          Icons.videocam_outlined,
          color: Colors.white.withValues(alpha: 0.3),
          size: 64,
        ),
      ),
    );
  }

  /// Converts a niche slug (e.g., "relatable_pov_comedy") to a readable name ("Relatable Pov Comedy")
  /// Used as fallback for older saved results that don't have nicheName cached
  String _formatNicheSlugToName(String slug) {
    if (slug.isEmpty) return 'General';
    return slug
        .split('_')
        .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  IconData _getNicheIcon(String? nicheName, String? category) =>
      NicheIconMapping.getIcon(nicheName, category);

  @override
  Widget build(BuildContext context) {
    final result = _analysisResult;

    return IosModalScaffold(
      key: _iosModalKey,
      staticBackground: const StaticFireGradient(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FadeTransition(
          opacity: _fadeInAnimation,
          child: Stack(
            children: [
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
                      SizedBox(
                          height: 60 +
                              ResponsiveSize.verticalSpacing(context, 24)),
                      Expanded(
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context)
                              .copyWith(scrollbars: false),
                          child: RepaintBoundary(
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              clipBehavior: Clip.none,
                              child: Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: offWhite.withValues(alpha: 0.12),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(60),
                                        topRight: Radius.circular(60),
                                        bottomLeft: Radius.circular(52),
                                        bottomRight: Radius.circular(52),
                                      ),
                                    ),
                                    clipBehavior: Clip.none,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          height: _cachedVideoHeight +
                                              _cachedGaugeOverlap +
                                              ResponsiveSize.spacing(
                                                  context, 76),
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              SizedBox(
                                                height: _cachedVideoHeight,
                                                child: _isFromHistory 
                                                    ? _buildHistoryThumbnail()
                                                    : VideoPlayerWidget(
                                                        controller: _videoController,
                                                        isInitialized: _isInitialized,
                                                        isMuted: _isMuted,
                                                        onMuteToggle: _toggleMute,
                                                        errorMessage: _errorMessage,
                                                        borderOpacity: 0.0,
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
                                                left: _cachedGaugeHorizontalInset,
                                                right: _cachedGaugeHorizontalInset,
                                                bottom: ResponsiveSize.spacing(
                                                    context, 32),
                                                child: Container(
                                                  width: double.infinity,
                                                  padding: EdgeInsets.all(
                                                      _cachedGaugePadding),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .surface,
                                                    borderRadius:
                                                        BorderRadius.only(
                                                      topLeft: Radius.circular(
                                                        ResponsiveSize.radius(
                                                            context, 190),
                                                      ),
                                                      topRight: Radius.circular(
                                                        ResponsiveSize.radius(
                                                            context, 190),
                                                      ),
                                                      bottomLeft:
                                                          Radius.circular(
                                                        ResponsiveSize.radius(
                                                            context, 60),
                                                      ),
                                                      bottomRight:
                                                          Radius.circular(
                                                        ResponsiveSize.radius(
                                                            context, 60),
                                                      ),
                                                    ),
                                                  ),
                                                  child: ValueListenableBuilder<
                                                      double>(
                                                    valueListenable:
                                                        _scoreNotifier,
                                                    builder:
                                                        (context, score, _) =>
                                                            HalfCircleGauge(
                                                      score: score,
                                                      label: '',
                                                      benchmark: _niche?.avgHookScore ?? result.benchmark,
                                                      nicheName: _niche?.name ?? 'General',
                                                      onSeeDetails: () =>
                                                          _showScoreDetailsSheet(),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.fromLTRB(
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
                                                      style: TextStyle(
                                                        fontFamily: 'Geom',
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize:
                                                            ResponsiveSize.text(
                                                                context, 20),
                                                        color: offWhite,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                      width:
                                                          ResponsiveSize.spacing(
                                                              context, 8)),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal:
                                                          ResponsiveSize
                                                              .spacing(
                                                                  context, 12),
                                                      vertical:
                                                          ResponsiveSize
                                                              .spacing(
                                                                  context, 6),
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: offWhite.withValues(
                                                          alpha: 0.12),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        ResponsiveSize.radius(
                                                            context, 20),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      '0-3 seconds',
                                                      style: TextStyle(
                                                        fontFamily: 'Geom',
                                                        fontWeight:
                                                            FontWeight.w300,
                                                        fontSize:
                                                            ResponsiveSize.text(
                                                                context, 12),
                                                        color: offWhite,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                  height: ResponsiveSize.spacing(
                                                      context, 16)),
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
                                                      quote: result.currentHookQuote.isNotEmpty
                                                          ? (result.currentHookQuote == '[No speech detected]'
                                                              ? 'No clear voice hook detected'
                                                              : '"${result.currentHookQuote}"')
                                                          : '"Analyzing audio..."',
                                                      subtitle: result.audioFeedback,
                                                    ),
                                                  ),
                                                  right: ValueListenableBuilder<double>(
                                                    valueListenable: _visualScoreNotifier,
                                                    builder: (context, visualScore, _) =>
                                                        VisualScoreCard(
                                                      title: 'Your Visual',
                                                      score: visualScore,
                                                      videoAsset: '',
                                                      description: result.visualFeedback,
                                                      videoController: _videoController,
                                                      isStatic: _isFromHistory,
                                                      thumbnailBase64: _isFromHistory ? result.thumbnailBase64 : null,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                  height: ResponsiveSize.spacing(
                                                      context, 12)),
                                              _buildWhyNotWorkingSection(),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _buildHookAlternativesHeader(),
                                  SizedBox(
                                      height: ResponsiveSize.verticalSpacing(
                                          context, 16)),
                                  _HookAlternativesSlider(
                                    controller: _hookAlternativesController,
                                    hookAlternatives: result.hookAlternatives,
                                    audioType: result.audioType,
                                  ),
                                  SizedBox(
                                      height: ResponsiveSize.verticalSpacing(
                                          context, 64)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Top gradient overlay
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
                          Color(0xFF110A1D),
                          Color(0xFF110A1D),
                          Color(0xF7110A1D),
                          Color(0xF2110A1D),
                          Color(0xE6110A1D),
                          Color(0xD9110A1D),
                          Color(0xCC110A1D),
                          Color(0xB3110A1D),
                          Color(0x99110A1D),
                          Color(0x80110A1D),
                          Color(0x66110A1D),
                          Color(0x4D110A1D),
                          Color(0x33110A1D),
                          Color(0x1A110A1D),
                          Color(0x0D110A1D),
                          Color(0x00110A1D),
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
              // App bar
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
                    leading: _LeadingBox(
                        icon: _getNicheIcon(_niche?.name, _niche?.category)),
                    title: _nicheLoading ? 'Loading...' : (_niche?.name ?? 'General'),
                    subtitle: _nicheLoading 
                        ? 'Fetching niche data...' 
                        : 'Scored against ${_niche?.name ?? 'General'} standards',
                    trailing: SmallIconButton(
                      onPressed: _closeWithAnimation,
                      iconPath: 'assets/icons/close.svg',
                    ),
                  ),
                ),
              ),
              // Bottom tabs
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                bottom: _showBottomTabs ? 0 : -120,
                left: 0,
                right: 0,
                child: _HookAlternativeTabs(
                  controller: _hookAlternativesController,
                  count: result.hookAlternatives.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHookAlternativesHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: offWhite.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Complete Hook Alternatives',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Geom',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveSize.text(context, 16),
                    color: offWhite,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: ResponsiveSize.spacing(context, 4)),
                Text(
                  'Visual + Audio optimized for your audience',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Geom',
                    fontWeight: FontWeight.w300,
                    fontSize: ResponsiveSize.text(context, 14),
                    color: offWhite.withValues(alpha: 0.3),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyNotWorkingSection() {
    final reasons = _analysisResult.whyNotWorking;
    if (reasons.isEmpty) return const SizedBox.shrink();
    
    // Hide section if score is above benchmark
    final benchmark = _niche?.avgHookScore ?? _analysisResult.benchmark;
    if (_analysisResult.overallScore >= benchmark) return const SizedBox.shrink();

    return _WhyNotWorkingSection(reasons: reasons);
  }
}

/// Isolated StatefulWidget for "Why it's not working" expandable section
/// This prevents re-renders from affecting the parent result screen
class _WhyNotWorkingSection extends StatefulWidget {
  final List<String> reasons;

  const _WhyNotWorkingSection({required this.reasons});

  @override
  State<_WhyNotWorkingSection> createState() => _WhyNotWorkingSectionState();
}

class _WhyNotWorkingSectionState extends State<_WhyNotWorkingSection> {
  bool _isExpanded = false;
  bool _headerExpanded = false;
  bool _contentExpanded = false;

  void _handleTap() async {
    if (_isExpanded) {
      setState(() => _contentExpanded = false);
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        setState(() {
          _headerExpanded = false;
          _isExpanded = false;
        });
      }
    } else {
      setState(() {
        _isExpanded = true;
        _headerExpanded = true;
      });
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) setState(() => _contentExpanded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final redCircle = const Color(0xFFED1717).withValues(alpha: 0.12);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _handleTap,
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
                      topLeft: Radius.circular(
                          ResponsiveSize.spacing(context, 32)),
                      topRight: Radius.circular(
                          ResponsiveSize.spacing(context, 32)),
                    )
                  : BorderRadius.circular(
                      ResponsiveSize.spacing(context, 32)),
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
                  turns: _isExpanded ? 0.5 : 0,
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
                  bottomLeft: Radius.circular(
                      ResponsiveSize.spacing(context, 32)),
                  bottomRight: Radius.circular(
                      ResponsiveSize.spacing(context, 32)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.reasons.asMap().entries.map((entry) {
                  final isLast = entry.key == widget.reasons.length - 1;
                  final reason = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
}

class _LeadingBox extends StatelessWidget {
  final IconData icon;
  const _LeadingBox({required this.icon});

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
          child: Icon(icon, size: 20, color: offWhite),
        ),
      ),
    );
  }
}

/// Controller for managing hook alternatives selection state
/// Isolates state changes from the parent widget to prevent rebuilds
class _HookAlternativesControllerState extends ChangeNotifier {
  int _selectedIndex = 0;
  PageController? _pageController;
  
  int get selectedIndex => _selectedIndex;
  PageController get pageController {
    _pageController ??= PageController(initialPage: 0);
    return _pageController!;
  }
  
  void setSelectedIndex(int index, {bool animate = true}) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
      if (animate && _pageController != null && _pageController!.hasClients) {
        _pageController!.animateToPage(
          index,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }
  
  void updateFromPageScroll(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }
}

class _HookAlternativeTabs extends StatelessWidget {
  final _HookAlternativesControllerState controller;
  final int count;

  const _HookAlternativeTabs({
    required this.controller,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            ResponsiveSize.horizontalPadding(context),
            16,
            ResponsiveSize.horizontalPadding(context),
            safeBottom > 0 ? safeBottom : 16,
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: offWhite,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(count.clamp(1, 3), (index) {
                  return HookTabItem(
                    label: controller.selectedIndex == index
                        ? '${index + 1}# Alternative'
                        : '${index + 1}#',
                    isSelected: controller.selectedIndex == index,
                    onTap: () => controller.setSelectedIndex(index),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}

// HookTabItem moved to result_shared_widgets.dart

class _HookAlternativesSlider extends StatefulWidget {
  final _HookAlternativesControllerState controller;
  final List<HookAlternative> hookAlternatives;
  final String audioType;

  const _HookAlternativesSlider({
    required this.controller,
    required this.hookAlternatives,
    required this.audioType,
  });

  @override
  State<_HookAlternativesSlider> createState() =>
      _HookAlternativesSliderState();
}

class _HookAlternativesSliderState extends State<_HookAlternativesSlider> {
  final List<double> _precachedHeights = [0, 0, 0];
  bool _heightsCalculated = false;
  double _currentHeight = 0;
  bool _isScrolling = false;
  bool _isResizing = false;
  int _measureAttempts = 0;
  final List<GlobalKey> _measureKeys = [GlobalKey(), GlobalKey(), GlobalKey()];
  final ValueNotifier<double> _pageNotifier = ValueNotifier<double>(0.0);

  PageController get _pageController => widget.controller.pageController;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageScroll);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _calculateHeights();
    });
  }

  @override
  void dispose() {
    _resizeEndTimer?.cancel();
    _pageController.removeListener(_onPageScroll);
    _pageNotifier.dispose();
    super.dispose();
  }

  /// Recalculate heights when expandable content changes
  void _recalculateHeights() {
    if (!mounted) return;
    // Delay to let layout settle after expansion/collapse animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final pageIndex = (_pageController.page?.round() ?? 0).clamp(0, 2);
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
  Timer? _resizeEndTimer;
  void _onContentResized() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pageIndex = (_pageController.page?.round() ?? 0).clamp(0, 2);
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

  void _calculateHeights() {
    if (!mounted) return;
    _measureAttempts++;

    final pageIndex =
        (_pageController.page?.round() ?? 0).clamp(0, 2);
    final renderBox = _measureKeys[pageIndex].currentContext?.findRenderObject()
        as RenderBox?;

    if (renderBox != null && renderBox.hasSize && renderBox.size.height > 100) {
      final height = renderBox.size.height;
      _precachedHeights[pageIndex] = height;

      setState(() {
        _heightsCalculated = true;
        _currentHeight = height;
      });

      for (int i = 0; i < 3; i++) {
        if (i == pageIndex) continue;
        final otherBox =
            _measureKeys[i].currentContext?.findRenderObject() as RenderBox?;
        if (otherBox != null &&
            otherBox.hasSize &&
            otherBox.size.height > 100) {
          _precachedHeights[i] = otherBox.size.height;
        } else {
          _precachedHeights[i] = height;
        }
      }
    } else if (_measureAttempts < 15) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) _calculateHeights();
      });
    } else {
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

  void _onPageScroll() {
    if (_pageController.hasClients) {
      _pageNotifier.value = _pageController.page ?? 0.0;
    }

    if (!_heightsCalculated) return;

    final page = _pageController.page ?? 0;
    final isAtRest = (page - page.round()).abs() < 0.01;

    double newHeight;
    bool newIsScrolling;
    if (isAtRest) {
      final pageIndex = page.round().clamp(0, 2);
      final renderBox = _measureKeys[pageIndex].currentContext?.findRenderObject()
          as RenderBox?;
      if (renderBox != null && renderBox.hasSize && renderBox.size.height > 100) {
        _precachedHeights[pageIndex] = renderBox.size.height;
      }
      newHeight = _precachedHeights[pageIndex];
      newIsScrolling = false;
    } else {
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
    final screenHeight = MediaQuery.sizeOf(context).height;
    final fallbackHeight = screenHeight * 1.5;
    final duration = _isResizing
        ? const Duration(milliseconds: 0)
        : _isScrolling
            ? const Duration(milliseconds: 150)
            : const Duration(milliseconds: 300);

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
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            onPageChanged: (index) => widget.controller.updateFromPageScroll(index),
            itemCount: widget.hookAlternatives.length.clamp(1, 3),
            itemBuilder: (context, index) {
              if (index >= widget.hookAlternatives.length) {
                return const SizedBox.shrink();
              }
              return OptimizedPageTransform(
                index: index,
                pageNotifier: _pageNotifier,
                child: RepaintBoundary(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: MeasurableContent(
                      key: _measureKeys[index],
                      child: _HookAlternativeContent(
                        alternative: widget.hookAlternatives[index],
                      ),
                    ),
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

/// Dynamic content for a hook alternative from Gemini analysis
class _HookAlternativeContent extends StatelessWidget {
  final HookAlternative alternative;

  const _HookAlternativeContent({
    required this.alternative,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
                '${alternative.index}# Hook Alternative',
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
                  Text(
                    '${alternative.estimatedScore}',
                    style: const TextStyle(
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
                quote: '"${alternative.sayThisQuote}"',
                tags: alternative.audioTechniques,
                rationaleBody: alternative.sayThisRationale,
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 16)),
              ShowThis(
                quote: alternative.showThisQuote,
                tags: alternative.visualTechniques,
                rationaleBody: alternative.showThisRationale,
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 16)),
              ProTips(
                sections: alternative.proTips
                    .map((tip) => TipSection(
                          title: tip.iconType == 'audio'
                              ? 'Audio Tips'
                              : tip.iconType == 'visual'
                                  ? 'Visual Tips'
                                  : tip.iconType == 'timing'
                                      ? 'Timing Tips'
                                      : 'General Tips',
                          iconAsset: tip.iconType == 'audio'
                              ? 'assets/icons/mic.svg'
                              : tip.iconType == 'visual'
                                  ? 'assets/icons/camera.svg'
                                  : null,
                          iconData: tip.iconType == 'timing'
                              ? Icons.timer_outlined
                              : null,
                          iconColor: tip.iconType == 'audio'
                              ? audioAccent
                              : tip.iconType == 'visual'
                                  ? visualAccent
                                  : offWhite,
                          tips: tip.tips.map((t) => TipItem(t)).toList(),
                        ))
                    .toList(),
                generalTips:
                    alternative.generalTips.map((t) => TipItem(t)).toList(),
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 16)),
              UpdatedScript(
                sections: [
                  ScriptSection(
                    title: 'Say this after hook:',
                    iconAsset: 'assets/icons/mic.svg',
                    iconColor: audioAccent,
                    showCopyButton: true,
                    content: alternative.scriptAfterHook,
                  ),
                  ScriptSection(
                    title: 'Show this after hook:',
                    iconAsset: 'assets/icons/camera.svg',
                    iconColor: visualAccent,
                    content: alternative.visualAfterHook,
                  ),
                ],
                ctaTip: alternative.cta != null
                    ? CtaTip(
                        sayThisTitle: 'Say this:',
                        sayThisContent: alternative.cta!.sayThisContent,
                        showThisTitle: 'Show this:',
                        showThisContent: alternative.cta!.showThisContent,
                      )
                    : null,
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 16)),
              SuggestedCaption(caption: alternative.suggestedCaption),
              SizedBox(height: ResponsiveSize.spacing(context, 16)),
              SuggestedHashtags(hashtags: alternative.suggestedHashtags),
              if (alternative.viralExample != null) ...[
                SizedBox(height: ResponsiveSize.spacing(context, 16)),
                HookViralExample(
                  thumbnailUrl: alternative.viralExample!.thumbnailUrl,
                  tags: alternative.viralExample!.tags,
                  description: alternative.viralExample!.description,
                  youtubeUrl: alternative.viralExample!.youtubeUrl,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// Modal widgets moved to result_shared_widgets.dart
