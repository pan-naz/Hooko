import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:hooko_v20/nav.dart';
import 'package:hooko_v20/components/icon_button.dart' as custom;
import 'package:hooko_v20/components/primary_button.dart';
import 'package:hooko_v20/components/secondary_button.dart';
import 'package:hooko_v20/components/bottom_nav_bar.dart';
import 'package:hooko_v20/components/app_bar_with_analysis.dart';
import 'package:hooko_v20/components/video_player_widget.dart';
import 'package:hooko_v20/components/ios_modal_sheet.dart';
import 'package:hooko_v20/state/app_state.dart';
import 'package:hooko_v20/theme.dart';
import 'package:hooko_v20/screens/video_picker_screen.dart';
import 'package:hooko_v20/services/active_operations_manager.dart';
import 'package:hooko_v20/utils/analysis_gate.dart';

class UploadedVideoScreen extends StatefulWidget {
  const UploadedVideoScreen({super.key});

  @override
  State<UploadedVideoScreen> createState() => _UploadedVideoScreenState();
}

class _UploadedVideoScreenState extends State<UploadedVideoScreen>
    with WidgetsBindingObserver {
  int _selectedNavIndex = 0;
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _isMuted = true;
  String? _errorMessage;
  bool _isAnalyzing = false;
  final _scaffoldKey = GlobalKey<IosModalScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeVideoPlayer());
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
        // Web: photo_manager doesn't work on web, show error
        setState(() => _errorMessage = 'Video playback not supported on web');
        return;
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        // Android: Use contentUri with content:// URI
        final mediaUrl = await videoAsset.getMediaUrl();
        if (mediaUrl == null) {
          setState(() => _errorMessage = 'Video URL not available');
          return;
        }
        controller = VideoPlayerController.contentUri(Uri.parse(mediaUrl));
      } else {
        // iOS/macOS: Get the actual file and use file controller
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
// Track that video is playing

      if (mounted) setState(() => _isInitialized = true);
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

  Future<void> _uploadNewVideo() async {
    try {
      // Show video picker modal with background shrinking effect
      final AssetEntity? selectedVideo = await showVideoPickerModalWithScaffold(_scaffoldKey);

      if (!mounted || selectedVideo == null) return;

      // Unregister and dispose old controller
      if (_videoController != null) {
        ActiveOperationsManager.instance.unregisterVideoController(_videoController!);
        _videoController!.dispose();
      }
      setState(() {
        _videoController = null;
        _isInitialized = false;
        _errorMessage = null;
      });

      // Store the new asset
      final appState = AppStateProvider.read(context);
      appState.selectedVideoAsset = selectedVideo;

      // Initialize new video player
      await _initializeVideoPlayer();
    } catch (e) {
      debugPrint('Error uploading new video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload video')),
        );
      }
    }
  }

  void _closeAndNavigateBack() {
    // Unregister and dispose video controller
    if (_videoController != null) {
      ActiveOperationsManager.instance.unregisterVideoController(_videoController!);
      _videoController!.dispose();
    }
    final appState = AppStateProvider.read(context);
    appState.clearSelectedVideo();
    context.go(AppRoutes.home);
  }

  void _handleNavTap(int index) {
    // Unregister and dispose video controller
    if (_videoController != null) {
      ActiveOperationsManager.instance.unregisterVideoController(_videoController!);
      _videoController!.dispose();
    }
    _videoController = null;
    final appState = AppStateProvider.read(context);
    appState.clearSelectedVideo();

    // Navigate to the corresponding page
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.history);
        break;
      case 2:
        context.go(AppRoutes.profile);
        break;
    }
  }

  Future<void> _analyzeVideo() async {
    // Prevent re-entry from rapid double-taps. Without this guard, a second
    // tap fired while the first is still awaiting the AnalysisGate would
    // pass the gate a second time and push /analyzing twice, potentially
    // triggering duplicate analyses (and burning extra tokens).
    if (_isAnalyzing) return;
    _isAnalyzing = true;
    try {
      // Check video length first. Short-form platforms (TikTok / Instagram Reels /
      // YouTube Shorts) cap at 3 minutes, so reject anything longer.
      final appState = AppStateProvider.read(context);
      final asset = appState.selectedVideoAsset;
      if (asset != null) {
        final duration = asset.videoDuration;
        if (duration.inSeconds > 180) {
          _showTooLongVideoDialog(duration);
          return;
        }
      }

      // Subscription + daily-limit gate.
      final canAnalyze = await AnalysisGate.ensureCanAnalyze(context);
      if (!mounted || !canAnalyze) return;

      // Pause and dispose video controller before navigating to analyzing screen
      // This prevents double audio since AnalyzingScreen creates its own controller
      if (_videoController != null) {
        _videoController!.pause();
        ActiveOperationsManager.instance.unregisterVideoController(_videoController!);
        _videoController!.dispose();
        _videoController = null;
      }
      context.push(AppRoutes.analyzing);
    } finally {
      // Reset the guard so the user can retry if they return to this screen
      // (e.g. after cancelling on the analyzing screen or hitting the gate).
      if (mounted) _isAnalyzing = false;
    }
  }

  void _showTooLongVideoDialog(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    final durationLabel =
        '${minutes}:${seconds.toString().padLeft(2, '0')}';

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (dialogContext) {
        return _VideoTooLongDialog(
          durationLabel: durationLabel,
          onCancel: () => Navigator.of(dialogContext).pop(),
          onUploadOther: () {
            Navigator.of(dialogContext).pop();
            _uploadNewVideo();
          },
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Unregister and dispose video controller
    if (_videoController != null) {
      ActiveOperationsManager.instance.unregisterVideoController(_videoController!);
      _videoController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IosModalScaffold(
      key: _scaffoldKey,
      // Match HomeScreen background positioning: center the tree image
      staticBackground: Center(
        child: Opacity(
          opacity: 0.2,
          child: Image.asset('assets/images/tree.jpg', fit: BoxFit.cover),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
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
                      SizedBox(height: ResponsiveSize.horizontalPadding(context)),
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
                            // Use the destination widget during flight for smooth transition
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
                      SizedBox(height: ResponsiveSize.horizontalPadding(context)),
                      // Constrain and center the upload card so it never
                      // touches the screen edges or overflows on small/large widths.
                      Align(
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: UploadedVideoCard(
                            onUploadOther: _uploadNewVideo,
                            onClose: _closeAndNavigateBack,
                            onAnalyze: _analyzeVideo,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              BottomNavBar(
                selectedIndex: _selectedNavIndex,
                onTap: _handleNavTap,
              ),
              // Responsive bottom spacing: safe area + 12dp for consistent look across all iPhones
              SizedBox(height: MediaQuery.of(context).padding.bottom + 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoTooLongDialog extends StatelessWidget {
  final String durationLabel;
  final VoidCallback onCancel;
  final VoidCallback onUploadOther;

  const _VideoTooLongDialog({
    required this.durationLabel,
    required this.onCancel,
    required this.onUploadOther,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(ResponsiveSize.spacing(context, 36));
    final sidePadding = ResponsiveSize.horizontalPadding(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      alignment: Alignment.bottomCenter,
      insetPadding: EdgeInsets.fromLTRB(
        sidePadding,
        sidePadding,
        sidePadding,
        sidePadding,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF110A1D),
            borderRadius: radius,
          ),
          padding: EdgeInsets.all(ResponsiveSize.spacing(context, 28)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: ResponsiveSize.spacing(context, 56),
                  height: ResponsiveSize.spacing(context, 56),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: visualAccent.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    Icons.timer_outlined,
                    color: visualAccent,
                    size: ResponsiveSize.spacing(context, 30),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveSize.verticalSpacing(context, 16)),
              Text(
                'Video is too long',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Geom',
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                  color: offWhite,
                ),
              ),
              SizedBox(height: ResponsiveSize.verticalSpacing(context, 10)),
              Text(
                'Your video is $durationLabel long. Hooko analyzes short-form videos up to 3 minutes — the maximum length supported by TikTok, Instagram Reels, and YouTube Shorts.\n\nPlease upload a shorter clip.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Geom',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  height: 1.4,
                  color: offWhite.withValues(alpha: 0.7),
                ),
              ),
              SizedBox(height: ResponsiveSize.verticalSpacing(context, 24)),
              PrimaryButton(
                label: 'Upload other',
                iconPath: 'assets/icons/upload.svg',
                onTap: onUploadOther,
              ),
              SizedBox(height: ResponsiveSize.verticalSpacing(context, 12)),
              SecondaryButton(
                text: 'Cancel',
                onPressed: onCancel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UploadedVideoCard extends StatelessWidget {
  final VoidCallback? onUploadOther;
  final VoidCallback? onClose;
  final VoidCallback? onAnalyze;

  const UploadedVideoCard({super.key, this.onUploadOther, this.onClose, this.onAnalyze});

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        children: [
          PrimaryButton(
            label: 'Analyze video',
            iconPath: 'assets/icons/analize.svg',
            onTap: onAnalyze ?? () => context.push(AppRoutes.analyzing),
          ),
          SizedBox(height: ResponsiveSize.verticalSpacing(context, 16)),
          Row(
            children: [
              custom.IconButton(
                iconPath: 'assets/icons/close.svg',
                onPressed: onClose ?? () => context.pop(),
              ),
              SizedBox(width: ResponsiveSize.spacing(context, 16)),
              Expanded(
                child: SecondaryButton(
                  text: 'Upload other',
                  onPressed: onUploadOther ?? () => context.pop(),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}
