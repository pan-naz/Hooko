import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooko_v20/utils/app_constants.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Reusable video player widget with mute toggle overlay.
/// Used in both UploadedVideoScreen and DemoScreen2.
/// 
/// PERFORMANCE: Auto-pauses when scrolled off-screen, resumes when visible.
/// 
/// For result screens (DemoResult, AnalysisResultScreen):
/// - Left side tap = play/pause toggle
/// - Right side tap = mute/unmute toggle
/// - Set [showPlayPauseControl] to true and provide [onPlayPauseToggle] and [isPlaying]
class VideoPlayerWidget extends StatefulWidget {
  final VideoPlayerController? controller;
  final bool isInitialized;
  final bool isMuted;
  final VoidCallback onMuteToggle;
  final String? errorMessage;
  /// When true, the widget fills the parent's available size and crops video content.
  final bool fillParent;
  /// Controls the opacity of the outer white border around the video frame.
  final double borderOpacity;
  /// Unique key for visibility detection (required for pause-on-scroll).
  final String visibilityKey;
  /// Whether to auto-pause when scrolled off-screen (default: true).
  final bool autoPauseOnScroll;
  /// Whether to show play/pause control on the left side (for result screens).
  final bool showPlayPauseControl;
  /// Callback for play/pause toggle (required when [showPlayPauseControl] is true).
  final VoidCallback? onPlayPauseToggle;
  /// Whether the video is currently playing (required when [showPlayPauseControl] is true).
  final bool isPlaying;

  const VideoPlayerWidget({
    super.key,
    required this.controller,
    required this.isInitialized,
    required this.isMuted,
    required this.onMuteToggle,
    this.errorMessage,
    this.fillParent = false,
    this.borderOpacity = 0.12,
    this.visibilityKey = 'video_player',
    this.autoPauseOnScroll = true,
    this.showPlayPauseControl = false,
    this.onPlayPauseToggle,
    this.isPlaying = true,
  });

  // Video frame styling constants
  static const double _borderWidth = AppSpacing.sm; // 8
  static const double _outerRadius = 60.0;
  static const double _innerRadius = 52.0; // outerRadius - borderWidth

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  bool _wasPlayingBeforeHide = false;
  bool _isVisible = true;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    // Guard: don't access controller after widget is disposed
    if (_isDisposed) return;
    if (!widget.autoPauseOnScroll || widget.controller == null) return;
    
    // Extra safety: check if controller is still usable
    final controller = widget.controller!;
    try {
      // Accessing value will throw if disposed
      final _ = controller.value;
    } catch (e) {
      // Controller is disposed, bail out
      return;
    }
    
    final visibleFraction = info.visibleFraction;
    final isNowVisible = visibleFraction > 0.3; // Consider visible if 30%+ showing
    
    if (isNowVisible != _isVisible) {
      _isVisible = isNowVisible;
      
      if (!isNowVisible) {
        // Scrolled off-screen: pause if playing
        if (controller.value.isPlaying) {
          _wasPlayingBeforeHide = true;
          controller.pause();
        }
      } else {
        // Scrolled back into view: resume if was playing
        if (_wasPlayingBeforeHide) {
          _wasPlayingBeforeHide = false;
          controller.play();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double borderWidth = VideoPlayerWidget._borderWidth;
    const double outerTopRadius = VideoPlayerWidget._outerRadius;
    const double outerBottomRadius = VideoPlayerWidget._outerRadius;
    const double innerTopRadius = VideoPlayerWidget._innerRadius;
    const double innerBottomRadius = VideoPlayerWidget._innerRadius;
    
    return VisibilityDetector(
      key: Key(widget.visibilityKey),
      onVisibilityChanged: _handleVisibilityChanged,
      child: RepaintBoundary(
        child: Center(
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(outerTopRadius),
              topRight: Radius.circular(outerTopRadius),
              bottomLeft: Radius.circular(outerBottomRadius),
              bottomRight: Radius.circular(outerBottomRadius),
            ),
            child: Container(
              padding: const EdgeInsets.all(borderWidth),
              decoration: BoxDecoration(
                color: const Color(0xFFFEFEFE)
                    .withValues(alpha: widget.borderOpacity.clamp(0.0, 1.0)),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(outerTopRadius),
                  topRight: Radius.circular(outerTopRadius),
                  bottomLeft: Radius.circular(outerBottomRadius),
                  bottomRight: Radius.circular(outerBottomRadius),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(innerTopRadius),
                  topRight: Radius.circular(innerTopRadius),
                  bottomLeft: Radius.circular(innerBottomRadius),
                  bottomRight: Radius.circular(innerBottomRadius),
                ),
                child: widget.fillParent
                    ? SizedBox.expand(
                        child: _VideoContent(
                          controller: widget.controller,
                          isInitialized: widget.isInitialized,
                          isMuted: widget.isMuted,
                          onMuteToggle: widget.onMuteToggle,
                          errorMessage: widget.errorMessage,
                          showPlayPauseControl: widget.showPlayPauseControl,
                          onPlayPauseToggle: widget.onPlayPauseToggle,
                          isPlaying: widget.isPlaying,
                        ),
                      )
                    : AspectRatio(
                        aspectRatio: 9 / 16,
                        child: _VideoContent(
                          controller: widget.controller,
                          isInitialized: widget.isInitialized,
                          isMuted: widget.isMuted,
                          onMuteToggle: widget.onMuteToggle,
                          errorMessage: widget.errorMessage,
                          showPlayPauseControl: widget.showPlayPauseControl,
                          onPlayPauseToggle: widget.onPlayPauseToggle,
                          isPlaying: widget.isPlaying,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoContent extends StatelessWidget {
  final VideoPlayerController? controller;
  final bool isInitialized;
  final bool isMuted;
  final VoidCallback onMuteToggle;
  final String? errorMessage;
  final bool showPlayPauseControl;
  final VoidCallback? onPlayPauseToggle;
  final bool isPlaying;

  const _VideoContent({
    required this.controller,
    required this.isInitialized,
    required this.isMuted,
    required this.onMuteToggle,
    this.errorMessage,
    this.showPlayPauseControl = false,
    this.onPlayPauseToggle,
    this.isPlaying = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildContent(),
          if (isInitialized && controller != null) ...[
            if (showPlayPauseControl)
              _buildSplitTapOverlay()
            else
              _buildTapOverlay(),
            if (showPlayPauseControl) _buildPlayPauseIndicator(),
            _buildMuteIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white.withValues(alpha: 0.6),
              size: AppIconSizes.extraLarge, // 48
            ),
            const SizedBox(height: AppSpacing.lg), // 16
            Text(
              errorMessage!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!isInitialized) {
      return Center(
        child: CircularProgressIndicator(
          color: Colors.white.withValues(alpha: 0.8),
          strokeWidth: 2,
        ),
      );
    }

    if (controller != null) {
      final aspectRatio = controller!.value.aspectRatio;
      return SizedBox.expand(
        child: IgnorePointer(
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: aspectRatio > 0 ? 100 * aspectRatio : 100,
              height: 100,
              child: RepaintBoundary(
                child: VideoPlayer(controller!),
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTapOverlay() => Positioned.fill(
    child: GestureDetector(
      onTap: onMuteToggle,
      behavior: HitTestBehavior.translucent,
      child: Container(color: Colors.transparent),
    ),
  );

  /// Split tap overlay: left half for play/pause, right half for mute/unmute
  Widget _buildSplitTapOverlay() => Positioned.fill(
    child: Row(
      children: [
        // Left half - play/pause
        Expanded(
          child: GestureDetector(
            onTap: onPlayPauseToggle,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Right half - mute/unmute
        Expanded(
          child: GestureDetector(
            onTap: onMuteToggle,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    ),
  );

  /// Play/pause indicator on the top left (mirrors mute indicator style)
  Widget _buildPlayPauseIndicator() => Positioned(
    left: AppSpacing.lg, // 16
    top: AppSpacing.lg, // 16
    child: IgnorePointer(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF110A1D).withValues(alpha: 0.30),
          borderRadius: BorderRadius.circular(AppRadius.large), // 16 -> 20 rounded
        ),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: SvgPicture.asset(
              isPlaying
                  ? 'assets/icons/pause.svg'
                  : 'assets/icons/play.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              placeholderBuilder: (context) => Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildMuteIndicator() => Positioned(
    right: AppSpacing.lg, // 16
    top: AppSpacing.lg, // 16
    child: IgnorePointer(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF110A1D).withValues(alpha: 0.30),
          borderRadius: BorderRadius.circular(AppRadius.large), // 16 -> 20 rounded
        ),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: SvgPicture.asset(
              isMuted
                  ? 'assets/icons/sound_off.svg'
                  : 'assets/icons/sound_on.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              placeholderBuilder: (context) => Icon(
                isMuted ? Icons.volume_off : Icons.volume_up,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
