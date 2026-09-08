import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:hooko_v20/components/animated_fire_gradient.dart';
import 'package:hooko_v20/components/animated_ellipsis_text.dart';
import 'package:hooko_v20/components/app_bar_with_analysis.dart';
import 'package:hooko_v20/components/video_player_widget.dart';
import 'package:hooko_v20/components/custom_spinner.dart';
import 'package:hooko_v20/components/ios_modal_sheet.dart';
import 'package:hooko_v20/components/primary_button.dart';
import 'package:hooko_v20/components/secondary_button.dart';
import 'package:hooko_v20/nav.dart';
import 'package:hooko_v20/services/analysis_service.dart';
import 'package:hooko_v20/services/active_operations_manager.dart';
import 'package:hooko_v20/models/analysis_result.dart';
import 'package:hooko_v20/state/app_state.dart';
import 'package:hooko_v20/theme.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, debugPrint;

/// Error type for categorizing errors
enum AnalysisErrorType {
  network,         // No internet, connection issues
  timeout,         // Request took too long
  server,          // Server-side issues
  video,           // Video format/corruption issues
  permission,      // Permission/auth issues
  storage,         // Storage/memory issues
  contentBlocked,  // AI safety filters blocked the content
  compressionFailed, // Video compression failed after retry
  videoTooHeavy,   // Video still too large after max compression
  aiResponseMalformed, // AI returned malformed JSON (rare)
  unknown,         // Generic fallback
}

/// Get error type from technical error message
AnalysisErrorType _getErrorType(String technicalError) {
  final lower = technicalError.toLowerCase();
  
  // Video too heavy even after 360p compression (check first - specific error)
  if (lower.contains('video_too_heavy')) {
    return AnalysisErrorType.videoTooHeavy;
  }
  
  // Compression failed after retry (check first - specific error with retry button)
  if (lower.contains('compression_failed')) {
    return AnalysisErrorType.compressionFailed;
  }
  
  // Content blocked by AI safety filters (check first - specific error)
  if (lower.contains('content_blocked') ||
      lower.contains('couldn\'t analyze this video') ||
      lower.contains('blocked due to') ||
      lower.contains('response was blocked') ||
      lower.contains('text not available')) {
    return AnalysisErrorType.contentBlocked;
  }
  
  // AI returned malformed JSON (rare but retryable)
  if (lower.contains('json_parse_failed') ||
      lower.contains('unterminated string') ||
      lower.contains('unexpected end of json') ||
      lower.contains('ai response was malformed')) {
    return AnalysisErrorType.aiResponseMalformed;
  }
  
  // Network errors
  if (lower.contains('socketexception') || 
      lower.contains('connection refused') ||
      lower.contains('network is unreachable') ||
      lower.contains('no internet') ||
      lower.contains('network unreachable') ||
      lower.contains('connection closed') ||
      lower.contains('connection reset') ||
      lower.contains('failed host lookup') ||
      lower.contains('hostname lookup') ||
      lower.contains('host not found') ||
      lower.contains('dns') ||
      lower.contains('clientexception') ||
      lower.contains('connection failed') ||
      lower.contains('failed to connect') ||
      lower.contains('certificate') ||
      lower.contains('ssl') ||
      lower.contains('handshake')) {
    return AnalysisErrorType.network;
  }
  
  // Timeout
  if (lower.contains('timeout') || lower.contains('timed out')) {
    return AnalysisErrorType.timeout;
  }
  
  // Server errors
  if (lower.contains('status: 5') || 
      lower.contains('internal server error') ||
      lower.contains('functionexception') ||
      lower.contains('bad gateway') ||
      lower.contains('service unavailable') ||
      lower.contains('502') ||
      lower.contains('503') ||
      lower.contains('429') ||
      lower.contains('rate limit')) {
    return AnalysisErrorType.server;
  }
  
  // Video issues
  if (lower.contains('file too large') || 
      lower.contains('payload too large') ||
      lower.contains('unsupported') ||
      lower.contains('invalid format') ||
      lower.contains('corrupted') ||
      lower.contains('cannot read') ||
      lower.contains('failed to read') ||
      lower.contains('compression failed') ||
      lower.contains('encoding') ||
      lower.contains('file not found') ||
      lower.contains('could not access')) {
    return AnalysisErrorType.video;
  }
  
  // Permission errors
  if (lower.contains('permission denied') ||
      lower.contains('access denied') ||
      lower.contains('forbidden') ||
      lower.contains('unauthorized') ||
      lower.contains('401') ||
      lower.contains('403')) {
    return AnalysisErrorType.permission;
  }
  
  // Storage/memory errors
  if (lower.contains('quota') ||
      lower.contains('storage full') ||
      lower.contains('out of memory') ||
      lower.contains('disk full')) {
    return AnalysisErrorType.storage;
  }
  
  return AnalysisErrorType.unknown;
}

/// Converts technical error messages to user-friendly text
String _getUserFriendlyError(String technicalError) {
  final lower = technicalError.toLowerCase();
  
  // Video too heavy even after max compression
  if (lower.contains('video_too_heavy')) {
    return 'Video too heavy, please record a lower-quality video.';
  }
  
  // Compression failed after automatic retry
  if (lower.contains('compression_failed')) {
    return 'Failed to compress video. Please try again.';
  }
  
  // Content blocked by AI safety filters
  if (lower.contains('content_blocked') ||
      lower.contains('couldn\'t analyze this video') ||
      lower.contains('blocked due to') ||
      lower.contains('response was blocked') ||
      lower.contains('text not available')) {
    return 'We couldn\'t analyze this video. The content may contain elements that our AI cannot process. Please try a different video.';
  }
  
  // AI returned malformed JSON (rare but retryable)
  if (lower.contains('json_parse_failed') ||
      lower.contains('unterminated string') ||
      lower.contains('unexpected end of json') ||
      lower.contains('ai response was malformed')) {
    return 'The AI response was incomplete. This is rare - please try again.';
  }
  
  // Network/connection errors - No internet
  if (lower.contains('socketexception') || 
      lower.contains('connection refused') ||
      lower.contains('network is unreachable') ||
      lower.contains('no internet') ||
      lower.contains('network unreachable') ||
      lower.contains('connection closed') ||
      lower.contains('connection reset')) {
    return 'No internet connection. Please check your network and try again.';
  }
  
  // DNS resolution failures
  if (lower.contains('failed host lookup') ||
      lower.contains('hostname lookup') ||
      lower.contains('host not found') ||
      lower.contains('getaddrinfo') ||
      lower.contains('dns')) {
    return 'Can\'t reach the server. Please check your internet connection.';
  }
  
  // SSL/TLS certificate errors
  if (lower.contains('certificate') ||
      lower.contains('ssl') ||
      lower.contains('handshake') ||
      lower.contains('secure connection')) {
    return 'Secure connection failed. Please check your network settings.';
  }
  
  // HTTP client errors (offline, etc.)
  if (lower.contains('clientexception') ||
      lower.contains('connection failed') ||
      lower.contains('failed to connect')) {
    return 'Can\'t connect to the server. Please check your internet.';
  }
  
  // Timeout errors
  if (lower.contains('timeout') || lower.contains('timed out')) {
    return 'The request took too long. Please try again.';
  }
  
  // Server errors (500, 502, 503, etc.)
  if (lower.contains('status: 5') || 
      lower.contains('internal server error') ||
      lower.contains('functionexception') ||
      lower.contains('bad gateway') ||
      lower.contains('service unavailable') ||
      lower.contains('502') ||
      lower.contains('503')) {
    return 'Something went wrong on our end. Please try again in a moment.';
  }
  
  // Rate limiting
  if (lower.contains('429') || lower.contains('rate limit') || lower.contains('too many requests')) {
    return 'Too many requests. Please wait a moment and try again.';
  }
  
  // File/video issues - size
  if (lower.contains('file too large') || 
      lower.contains('payload too large') ||
      lower.contains('413') ||
      lower.contains('entity too large')) {
    return 'Video file is too large. Please try a shorter video.';
  }
  
  // File/video issues - format
  if (lower.contains('unsupported') || 
      lower.contains('invalid format') ||
      lower.contains('unsupported media') ||
      lower.contains('415')) {
    return 'Video format not supported. Please try a different video.';
  }
  
  // File corruption / read errors
  if (lower.contains('corrupted') ||
      lower.contains('cannot read') ||
      lower.contains('could not read') ||
      lower.contains('failed to read') ||
      lower.contains('data error') ||
      lower.contains('invalid data')) {
    return 'The video file appears to be damaged. Please try a different video.';
  }
  
  // File access / not found
  if (lower.contains('file not found') ||
      lower.contains('no such file') ||
      lower.contains('could not access') ||
      lower.contains('access video file') ||
      lower.contains('404')) {
    return 'Can\'t access the video. Please select it again.';
  }
  
  // Permission errors
  if (lower.contains('permission denied') ||
      lower.contains('access denied') ||
      lower.contains('forbidden') ||
      lower.contains('403')) {
    return 'Permission denied. Please allow access in your device settings.';
  }
  
  // Storage quota / space errors
  if (lower.contains('quota') ||
      lower.contains('storage full') ||
      lower.contains('insufficient space') ||
      lower.contains('no space left') ||
      lower.contains('disk full')) {
    return 'Storage space is full. Please free up some space and try again.';
  }
  
  // Out of memory errors
  if (lower.contains('out of memory') ||
      lower.contains('memory allocation') ||
      lower.contains('heap')) {
    return 'Not enough memory. Please close other apps and try again.';
  }
  
  // Auth errors
  if (lower.contains('unauthorized') || 
      lower.contains('401') || 
      lower.contains('authentication') ||
      lower.contains('unauthenticated')) {
    return 'Session expired. Please sign in again.';
  }
  
  // JSON / Parse errors
  if (lower.contains('json') ||
      lower.contains('parse error') ||
      lower.contains('unexpected format') ||
      lower.contains('invalid response')) {
    return 'Received unexpected data. Please try again.';
  }
  
  // Supabase specific errors
  if (lower.contains('bucket not found') ||
      lower.contains('storage object')) {
    return 'Upload failed. Please try again.';
  }
  
  // Video compression specific
  if (lower.contains('compression failed') ||
      lower.contains('could not compress') ||
      lower.contains('encoding')) {
    return 'Failed to process video. Please try a different video.';
  }
  
  // Generic fallback - don't expose technical details
  return 'Something went wrong. Please try again.';
}

/// Screen shown while video is being analyzed
class AnalyzingScreen extends StatefulWidget {
  const AnalyzingScreen({super.key});

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _isMuted = true;
  String? _errorMessage;
  bool _wasPlayingBeforePause = false;
  final _scaffoldKey = GlobalKey<IosModalScaffoldState>();

  // Analysis state
  String? _analysisError;
  AnalysisErrorType _errorType = AnalysisErrorType.unknown;
  int _currentStep = 0;
  int _lastHapticStep = -1;
  
  // Cancellation token to stop analysis when app closes
  AnalysisCancellationToken? _cancellationToken;
  bool _analysisCompleted = false;
  bool _isAnalysisComplete = false; // For UI "Done" state
  
  // Progress mapping: Backend progress → UI steps
  // | Backend % | UI Step |
  // |-----------|---------|
  // | 0-15%     | Step 0: Uploading video |
  // | 15-35%    | Step 1: Niche detection |
  // | 35-55%    | Step 2: Analyzing engagement |
  // | 55-75%    | Step 3: Calculating hook score |
  // | 75-100%   | Step 4: Generating recommendations |
  bool _backendComplete = false;
  double _currentBackendProgress = 0.0;

  // Step labels (same as demo)
  static const _stepLabels = [
    'Uploading video',
    'Niche detection',
    'Analyzing engagement',
    'Calculating hook score',
    'Generating recommendations',
  ];

  // Animation
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _entranceController;
  late List<Animation<double>> _stepEntranceAnimations;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('AnalyzingScreen: initState - currentStep=$_currentStep, backendComplete=$_backendComplete');
    _initAnimations();
    _initializeVideoPlayer();
    _startAnalysis();
  }

  void _initAnimations() {
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // Match transition duration
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut), // Delay start, then fade in
    );
    _fadeController.forward();

    // Step entrance animations (same as demo)
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

    // Start entrance animation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _entranceController.forward();
    });
  }

  /// Map backend progress to UI step
  /// | Backend % | UI Step |
  /// |-----------|---------|
  /// | 0-15%     | Step 0: Uploading video |
  /// | 15-35%    | Step 1: Niche detection |
  /// | 35-55%    | Step 2: Analyzing engagement |
  /// | 55-75%    | Step 3: Calculating hook score |
  /// | 75-100%   | Step 4: Generating recommendations |
  int _getStepFromProgress(double progress) {
    if (progress < 0.15) return 0;
    if (progress < 0.35) return 1;
    if (progress < 0.55) return 2;
    if (progress < 0.75) return 3;
    return 4;
  }
  
  /// Calculate overall UI progress from backend progress
  /// Each step is 20% of the UI progress bar
  double _getUIProgressFromBackend(double backendProgress) {
    if (backendProgress < 0.15) {
      // Step 0: 0-15% backend → 0-20% UI
      return (backendProgress / 0.15) * 0.2;
    } else if (backendProgress < 0.35) {
      // Step 1: 15-35% backend → 20-40% UI
      return 0.2 + ((backendProgress - 0.15) / 0.20) * 0.2;
    } else if (backendProgress < 0.55) {
      // Step 2: 35-55% backend → 40-60% UI
      return 0.4 + ((backendProgress - 0.35) / 0.20) * 0.2;
    } else if (backendProgress < 0.75) {
      // Step 3: 55-75% backend → 60-80% UI
      return 0.6 + ((backendProgress - 0.55) / 0.20) * 0.2;
    } else {
      // Step 4: 75-100% backend → 80-100% UI
      return 0.8 + ((backendProgress - 0.75) / 0.25) * 0.2;
    }
  }

  /// Fast-forward remaining steps when backend completes
  void _fastForwardToComplete() {
    debugPrint('AnalyzingScreen: Fast-forwarding from step $_currentStep');
    
    // Quickly animate through remaining steps
    if (_currentStep < 5) {
      _animateRemainingSteps();
    }
  }

  /// Animate through remaining steps quickly
  Future<void> _animateRemainingSteps() async {
    for (int i = _currentStep; i < 5; i++) {
      if (!mounted) return;
      
      setState(() => _currentStep = i);
      if (i > _lastHapticStep) {
        HapticFeedback.lightImpact();
        _lastHapticStep = i;
      }
      
      final progress = (i + 1) / 5.0;
      _animateProgressTo(progress);
      
      // Quick delay between steps for visual feedback
      await Future.delayed(const Duration(milliseconds: 150));
    }
    
    // Mark all complete
    if (mounted) {
      setState(() {
        _currentStep = 5;
        _isAnalysisComplete = true;
      });
      _animateProgressTo(1.0);
    }
  }

  /// Smoothly animate progress bar to target value
  /// Duration scales with delta size for smoother transitions
  void _animateProgressTo(double target) {
    if (!mounted) return;
    
    final currentValue = _progressAnimation.value;
    final clampedTarget = target.clamp(0.0, 1.0);
    final delta = (clampedTarget - currentValue).abs();
    
    // Dynamic duration: ~50ms per 1% change, min 150ms, max 1200ms
    // This makes small jumps (1-2%) quick, large jumps (20%+) smooth
    final durationMs = (delta * 5000).clamp(150.0, 1200.0).toInt();
    
    _progressController.duration = Duration(milliseconds: durationMs);
    _progressAnimation = Tween<double>(
      begin: currentValue,
      end: clampedTarget,
    ).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _progressController.forward(from: 0);
  }

  /// Called by backend to report progress
  /// Maps backend progress directly to UI steps
  void _updateProgress(double newProgress) {
    if (!mounted) return;
    
    // Only log when percentage changes (avoid duplicate logs)
    final newPercent = (newProgress * 100).toInt();
    final oldPercent = (_currentBackendProgress * 100).toInt();
    if (newPercent != oldPercent) {
      debugPrint('AnalyzingScreen: Backend progress: $newPercent%');
    }
    
    _currentBackendProgress = newProgress;
    
    // Calculate UI step from backend progress
    final targetStep = _getStepFromProgress(newProgress);
    
    // Update step if changed
    if (_currentStep != targetStep) {
      setState(() => _currentStep = targetStep);
      // Haptic feedback on step change
      if (targetStep > _lastHapticStep) {
        HapticFeedback.lightImpact();
        _lastHapticStep = targetStep;
      }
    }
    
    // Calculate and animate UI progress
    // Cap at 95% until fully complete to prevent premature "done" state
    final uiProgress = newProgress >= 1.0 
        ? 1.0 
        : _getUIProgressFromBackend(newProgress).clamp(0.0, 0.95);
    _animateProgressTo(uiProgress);
    
    // When backend completes, trigger completion flow
    if (newProgress >= 1.0 && !_backendComplete) {
      debugPrint('AnalyzingScreen: Backend complete!');
      _backendComplete = true;
      _fastForwardToComplete();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Pause video - only set flag if video is currently playing
        // This prevents overwriting the flag when going from inactive → paused
        if (_videoController != null && _isInitialized && _videoController!.value.isPlaying) {
          _wasPlayingBeforePause = true;
          _videoController!.pause();
        }
        break;
      case AppLifecycleState.resumed:
        // Resume video
        if (_videoController != null && _isInitialized && _wasPlayingBeforePause) {
          _videoController!.play();
          _wasPlayingBeforePause = false; // Reset flag after resuming
        }
        break;
      case AppLifecycleState.detached:
        // App is being closed - cancel analysis to prevent token spending
        _cancelAnalysisOnClose();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }
  
  /// Cancel ongoing analysis when app is being closed to prevent unnecessary costs
  void _cancelAnalysisOnClose() {
    if (_cancellationToken != null && !_analysisCompleted) {
      debugPrint('AnalyzingScreen: App closing, cancelling analysis to save costs');
      _cancellationToken!.cancel();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    final appState = AppStateProvider.read(context);
    final videoAsset = appState.selectedVideoAsset;

    if (videoAsset == null) {
      setState(() => _errorMessage = 'No video selected');
      return;
    }

    try {
      VideoPlayerController controller;

      if (kIsWeb) {
        setState(() => _errorMessage = 'Video playback not supported on web');
        return;
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final mediaUrl = await videoAsset.getMediaUrl();
        if (mediaUrl == null) {
          setState(() => _errorMessage = 'Video URL not available');
          return;
        }
        controller = VideoPlayerController.contentUri(Uri.parse(mediaUrl));
      } else {
        final file = await videoAsset.file;
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
      await controller.setVolume(0.0);
      await controller.play();

      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      if (mounted) setState(() => _errorMessage = 'Failed to load video');
    }
  }

  Future<void> _startAnalysis() async {
    final appState = AppStateProvider.read(context);
    final videoAsset = appState.selectedVideoAsset;

    if (videoAsset == null) {
      setState(() => _analysisError = 'No video selected');
      return;
    }

    // Create cancellation token for this analysis
    _cancellationToken = AnalysisCancellationToken();
    _analysisCompleted = false;
    _backendComplete = false;
    
    // Register with manager for cleanup on hot restart
    ActiveOperationsManager.instance.registerCancellationToken(_cancellationToken!);

    AnalysisResult? result;
    try {
      result = await AnalysisService.analyzeVideo(
        videoAsset,
        onProgress: (status, progress) {
          if (mounted) {
            _updateProgress(progress);
          }
        },
        cancellationToken: _cancellationToken,
      );

      _analysisCompleted = true;
      
      // Mark backend complete to trigger fast-forward
      if (!_backendComplete) {
        _backendComplete = true;
        _fastForwardToComplete();
      }
      
      // Unregister token on successful completion
      if (_cancellationToken != null) {
        ActiveOperationsManager.instance.unregisterCancellationToken(_cancellationToken!);
      }

      // Wait for UI animation to complete
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (mounted) {
        // Show "Done" state for 1 second before navigating (matching demo flow)
        setState(() => _isAnalysisComplete = true);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          final appState = AppStateProvider.read(context);
          appState.setLatestAnalysisResult(result);
          // Refresh history so it's ready when user goes to history screen
          appState.refreshHistory();
          // Count this analysis against the user's daily limit (server-side).
          // Fire-and-forget so navigation isn't blocked on the network call.
          // ignore: discarded_futures
          appState.recordAnalysisUsed();
          context.go(AppRoutes.analysisResult);
        }
      }
    } on AnalysisCancelledException {
      // Analysis was cancelled (app closed or user navigated away)
      debugPrint('AnalyzingScreen: Analysis cancelled');
      // Don't show error, just silently handle cancellation
      if (mounted && !_analysisCompleted) {
        // Navigate back to home if still on this screen
        final appState = AppStateProvider.read(context);
        appState.clearSelectedVideo();
        context.go(AppRoutes.home);
      }
    } catch (e) {
      debugPrint('Analysis error: $e');
      if (mounted) {
        final errorString = e.toString();
        setState(() {
          _analysisError = _getUserFriendlyError(errorString);
          _errorType = _getErrorType(errorString);
        });
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

  void _cancelAndGoBack() {
    // Cancel any ongoing analysis before navigating away
    if (_cancellationToken != null) {
      if (!_analysisCompleted) {
        _cancellationToken!.cancel();
      }
      ActiveOperationsManager.instance.unregisterCancellationToken(_cancellationToken!);
    }
    
    // Unregister and dispose video controller
    if (_videoController != null) {
      ActiveOperationsManager.instance.unregisterVideoController(_videoController!);
      _videoController!.dispose();
    }
    
    final appState = AppStateProvider.read(context);
    appState.clearSelectedVideo();
    context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    // Cancel analysis if still running (prevents token spending on hot restart/close)
    if (_cancellationToken != null) {
      if (!_analysisCompleted) {
        debugPrint('AnalyzingScreen: Disposing, cancelling analysis');
        _cancellationToken!.cancel();
      }
      // Unregister from manager
      ActiveOperationsManager.instance.unregisterCancellationToken(_cancellationToken!);
    }
    
    // Unregister and dispose video controller
    if (_videoController != null) {
      ActiveOperationsManager.instance.unregisterVideoController(_videoController!);
      _videoController!.dispose();
    }
    
    _progressController.dispose();
    _fadeController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IosModalScaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent, // Start transparent, fade in with content
      staticBackground: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          color: const Color(0xFF110A1D),
          child: AnimatedFireGradient.instance,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
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
                        Builder(
                          builder: (context) {
                            final appState = AppStateProvider.of(context);
                            return Hero(
                              tag: 'main_app_bar',
                              flightShuttleBuilder: (
                                flightContext,
                                animation,
                                flightDirection,
                                fromHeroContext,
                                toHeroContext,
                              ) {
                                // Use Material to prevent rendering artifacts during flight
                                return Material(
                                  type: MaterialType.transparency,
                                  child: toHeroContext.widget,
                                );
                              },
                              child: AppBarWithAnalysis(
                                usedCount: appState.dailyAnalysisUsed,
                                totalCount: appState.dailyAnalysisTotal,
                                usageLoaded: !appState.isProSubscribed || appState.dailyUsageLoaded,
                                usageFailed: appState.isProSubscribed && appState.dailyUsageFailed,
                                badgeLabel: appState.subscriptionBadgeLabel,
                                badgeAsset: appState.subscriptionBadgeAsset,
                              ),
                            );
                          },
                        ),
                        SizedBox(
                            height:
                                ResponsiveSize.horizontalPadding(context)),
                        Expanded(
                          child: Hero(
                            tag: 'uploaded_video_player',
                            flightShuttleBuilder: (
                              flightContext,
                              animation,
                              flightDirection,
                              fromHeroContext,
                              toHeroContext,
                            ) {
                              // Use the destination widget during flight
                              return toHeroContext.widget;
                            },
                            child: VideoPlayerWidget(
                              controller: _videoController,
                              isInitialized: _isInitialized,
                              isMuted: _isMuted,
                              onMuteToggle: _toggleMute,
                              errorMessage: _errorMessage,
                            ),
                          ),
                        ),
                        SizedBox(height: ResponsiveSize.verticalSpacing(context, 12)),
                        // Percentage and "Analyzing.." ABOVE the card - centered
                        Center(child: _buildPercentageAndStatus()),
                        SizedBox(height: ResponsiveSize.verticalSpacing(context, 16)),
                        // Card with ONLY the 5 steps
                        Align(
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: _buildBottomCard(),
                          ),
                        ),
                        // Warning text BELOW the card
                        SizedBox(height: ResponsiveSize.verticalSpacing(context, 12)),
                        _buildWarningMessage(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCard() {
    final radius = BorderRadius.circular(ResponsiveSize.spacing(context, 60));

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(ResponsiveSize.spacing(context, 40)),
        decoration: BoxDecoration(
          color: const Color(0x1FFEFEFE),
          borderRadius: radius,
        ),
        child: _analysisError != null
            ? _buildErrorContent()
            : _buildAnalyzingContent(),
      ),
    );
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
                  color: offWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildPercentageAndStatus() {
    if (_analysisError != null) return const SizedBox.shrink();
    
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        final percent = (_progressAnimation.value * 100).clamp(0, 100).toInt();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Percentage counter (smaller, centered)
            Text(
              '$percent%',
              style: TextStyle(
                fontFamily: 'Geom',
                fontWeight: FontWeight.w300,
                fontSize: ResponsiveSize.text(context, 14),
                color: offWhite,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            // Show "Done" when complete, otherwise animated "Analyzing.." (matching demo)
            _isAnalysisComplete
                ? Text(
                    'Done',
                    style: TextStyle(
                      fontFamily: 'Geom',
                      fontWeight: FontWeight.w300,
                      fontSize: ResponsiveSize.text(context, 12),
                      color: offWhite.withValues(alpha: 0.3),
                    ),
                    textAlign: TextAlign.center,
                  )
                : AnimatedEllipsisText(
                    baseText: 'Analyzing',
                    style: TextStyle(
                      fontFamily: 'Geom',
                      fontWeight: FontWeight.w300,
                      fontSize: ResponsiveSize.text(context, 12),
                      color: offWhite.withValues(alpha: 0.3),
                    ),
                    textAlign: TextAlign.center,
                    maxDots: 3,
                    interval: const Duration(milliseconds: 315),
                    isAnimating: true,
                  ),
          ],
        );
      },
    );
  }

  Widget _buildWarningMessage() {
    if (_analysisError != null) return const SizedBox.shrink();
    
    return Center(
      child: FractionallySizedBox(
        widthFactor: ResponsiveSize.isSmallScreen(context) ? 0.9 : 0.7,
        child: Text(
          'Don\'t close the App — analysis in progress, this might take 30-60 sec.',
          style: TextStyle(
            fontFamily: 'Geom',
            fontWeight: FontWeight.w300,
            fontSize: ResponsiveSize.text(context, 12),
            color: offWhite,
          ),
          textAlign: TextAlign.center,
          softWrap: true,
        ),
      ),
    );
  }

  Widget _buildAnalyzingContent() {
    // Card contains ONLY the 5-step progress (matching demo)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, _buildStepRow),
    );
  }


  Widget _buildErrorContent() {
    // Determine error title, icon and message based on error type
    String errorTitle;
    IconData errorIcon;
    Color iconColor;
    
    switch (_errorType) {
      case AnalysisErrorType.network:
        errorTitle = 'No Connection';
        errorIcon = Icons.wifi_off_rounded;
        iconColor = const Color(0xFFFF9500);
      case AnalysisErrorType.timeout:
        errorTitle = 'Request Timeout';
        errorIcon = Icons.timer_off_outlined;
        iconColor = const Color(0xFFFF9500);
      case AnalysisErrorType.server:
        errorTitle = 'Server Error';
        errorIcon = Icons.cloud_off_rounded;
        iconColor = const Color(0xFFED1717);
      case AnalysisErrorType.video:
        errorTitle = 'Video Error';
        errorIcon = Icons.videocam_off_outlined;
        iconColor = const Color(0xFFFF9500);
      case AnalysisErrorType.permission:
        errorTitle = 'Permission Denied';
        errorIcon = Icons.lock_outline_rounded;
        iconColor = const Color(0xFFFF9500);
      case AnalysisErrorType.storage:
        errorTitle = 'Storage Issue';
        errorIcon = Icons.storage_rounded;
        iconColor = const Color(0xFFFF9500);
      case AnalysisErrorType.contentBlocked:
        errorTitle = 'Unable to Analyze';
        errorIcon = Icons.block_rounded;
        iconColor = const Color(0xFFFF9500);
      case AnalysisErrorType.compressionFailed:
        errorTitle = 'Compression Failed';
        errorIcon = Icons.video_settings_outlined;
        iconColor = const Color(0xFFFF9500);
      case AnalysisErrorType.videoTooHeavy:
        errorTitle = 'Video Too Heavy';
        errorIcon = Icons.file_download_off_outlined;
        iconColor = const Color(0xFFFF9500);
      case AnalysisErrorType.unknown:
        errorTitle = 'Analysis Failed';
        errorIcon = Icons.error_outline;
        iconColor = const Color(0xFFED1717);
      case AnalysisErrorType.aiResponseMalformed:
        errorTitle = 'Analysis Error';
        errorIcon = Icons.psychology_alt_outlined;
        iconColor = const Color(0xFFFF9500);
    }
    
    final errorMessage = _analysisError ?? 'Unknown error';
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          errorIcon,
          color: iconColor,
          size: 48,
        ),
        SizedBox(height: ResponsiveSize.verticalSpacing(context, 16)),
        Text(
          errorTitle,
          style: TextStyle(
            fontFamily: 'Geom',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveSize.text(context, 18),
            color: offWhite,
          ),
        ),
        SizedBox(height: ResponsiveSize.verticalSpacing(context, 8)),
        Text(
          errorMessage,
          style: TextStyle(
            fontFamily: 'Geom',
            fontWeight: FontWeight.w300,
            fontSize: ResponsiveSize.text(context, 14),
            color: offWhite.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: ResponsiveSize.verticalSpacing(context, 20)),
        // Show Retry + Cancel for all errors EXCEPT contentBlocked
        if (_errorType != AnalysisErrorType.contentBlocked) ...[
          // Cancel (left) + Retry (right) in a row
          Row(
            children: [
              // Cancel button (secondary, left)
              Expanded(child: SecondaryButton(text: 'Cancel', onPressed: _cancelAndGoBack)),
              SizedBox(width: ResponsiveSize.spacing(context, 12)),
              // Retry button (primary, right)
              Expanded(child: PrimaryButton(label: 'Retry', onTap: _retryAnalysis)),
            ],
          ),
        ] else ...[
          // Cancel button only for contentBlocked errors
          SecondaryButton(text: 'Cancel', onPressed: _cancelAndGoBack),
        ],
      ],
    );
  }

  /// Retry the analysis after a compression failure
  void _retryAnalysis() {
    setState(() {
      _analysisError = null;
      _errorType = AnalysisErrorType.unknown;
      _currentStep = 0;
      _lastHapticStep = -1;
      _backendComplete = false;
      _currentBackendProgress = 0.0;
      _isAnalysisComplete = false;
    });
    
    // Reset progress animation
    _animateProgressTo(0.0);
    
    // Restart analysis
    _startAnalysis();
  }
}

