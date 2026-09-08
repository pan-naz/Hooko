import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:hooko_v20/theme.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:hooko_v20/components/segmented_progress_bar.dart';

/// A reusable card for displaying a visual-related score with a segmented
/// progress bar and a video thumbnail preview.
/// 
/// PERFORMANCE OPTIMIZATION: Pass an existing [videoController] to avoid
/// creating a second video decoder. On older iPhones, running 2 video
/// decoders simultaneously is very expensive.
class VisualScoreCard extends StatelessWidget {
  /// Card title, e.g., "Your Visual".
  final String title;

  /// Score from 0 to 100 (supports double for animation).
  final double score;

  /// Path to the local video asset used for the thumbnail preview.
  /// Only used if [videoController] is not provided.
  final String videoAsset;

  /// A concise subtitle/description beneath the thumbnail.
  final String description;

  /// Optional: Pass an existing video controller to share with main player.
  /// This avoids creating a second video decoder (major performance win).
  final VideoPlayerController? videoController;
  
  /// If true, shows static placeholder instead of loading spinner (for history view)
  final bool isStatic;
  
  /// Optional: Base64 encoded thumbnail to display when isStatic is true
  final String? thumbnailBase64;

  const VisualScoreCard({
    super.key,
    required this.title,
    required this.score,
    required this.videoAsset,
    required this.description,
    this.videoController,
    this.isStatic = false,
    this.thumbnailBase64,
  });

  // Base thumbnail height for the video preview
  static const double _baseThumbnailHeight = 115;

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveSize.spacing(context, 16);
    final thumbnailHeight = ResponsiveSize.cardHeight(context, _baseThumbnailHeight);
    final thumbnailWidth = thumbnailHeight * (9 / 16);
    
    return RepaintBoundary(
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Geom',
                fontWeight: FontWeight.w300,
                fontSize: ResponsiveSize.text(context, 16),
                color: visualAccent,
              ),
            ),
            SizedBox(height: ResponsiveSize.spacing(context, 8)),
            // Score and segmented bar row
            Row(
              children: [
                Text(
                  '${score.round()}',
                  style: TextStyle(
                    fontFamily: 'Geom',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveSize.text(context, 16),
                    color: visualAccent,
                  ),
                ),
                SizedBox(width: ResponsiveSize.spacing(context, 8)),
                Expanded(
                  child: SegmentedProgressBar(
                    score: score,
                    color: visualAccent,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveSize.spacing(context, 16)),
            // Visual content - Fixed size thumbnail
            Center(
              child: videoController != null
                  ? _SharedVideoThumbnail(controller: videoController!, height: thumbnailHeight, width: thumbnailWidth)
                  : _VideoStaticPlaceholder(
                      height: thumbnailHeight, 
                      width: thumbnailWidth, 
                      showLoader: !isStatic,
                      thumbnailBase64: thumbnailBase64,
                    ),
            ),
            SizedBox(height: ResponsiveSize.spacing(context, 12)),
            // Rationale - full text
            Text(
              description,
              style: TextStyle(
                fontFamily: 'Geom',
                fontWeight: FontWeight.w300,
                fontSize: ResponsiveSize.text(context, 12),
                color: offWhite.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared video thumbnail that reuses an existing VideoPlayerController.
/// This avoids creating a second video decoder - major performance win on older iPhones.
/// NOTE: No visibility logic here - the main video player handles pause/resume.
/// This thumbnail just mirrors whatever the main player shows.
class _SharedVideoThumbnail extends StatelessWidget {
  final VideoPlayerController controller;
  final double? height;
  final double? width;
  
  static const double _baseThumbnailHeight = 115;
  
  const _SharedVideoThumbnail({required this.controller, this.height, this.width});

  @override
  Widget build(BuildContext context) {
    final isReady = controller.value.isInitialized;
    final thumbnailHeight = height ?? ResponsiveSize.cardHeight(context, _baseThumbnailHeight);
    final thumbnailWidth = width ?? (thumbnailHeight * (9 / 16));
    final borderRadius = ResponsiveSize.radius(context, 16);
    
    return RepaintBoundary(
      child: SizedBox(
        width: thumbnailWidth,
        height: thumbnailHeight,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: offWhite.withValues(alpha: 0.15), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius - 2),
            child: isReady
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: controller.value.size.width,
                      height: controller.value.size.height,
                      child: IgnorePointer(
                        child: RepaintBoundary(
                          child: VideoPlayer(controller),
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: const Color(0xFF2A1F3D),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: offWhite.withValues(alpha: 0.3),
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

/// Static placeholder shown when video controller is not available
class _VideoStaticPlaceholder extends StatelessWidget {
  final double height;
  final double width;
  final bool showLoader;
  final String? thumbnailBase64;
  
  const _VideoStaticPlaceholder({
    required this.height, 
    required this.width, 
    this.showLoader = true,
    this.thumbnailBase64,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = ResponsiveSize.radius(context, 16);
    
    // Try to decode thumbnail if available
    Widget? thumbnailWidget;
    if (thumbnailBase64 != null && thumbnailBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(thumbnailBase64!);
        thumbnailWidget = Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      } catch (e) {
        thumbnailWidget = null;
      }
    }
    
    return RepaintBoundary(
      child: SizedBox(
        width: width,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: offWhite.withValues(alpha: 0.15), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius - 2),
            child: thumbnailWidget ?? Container(
              color: const Color(0xFF2A1F3D),
              child: showLoader
                  ? Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: offWhite.withValues(alpha: 0.3),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF2A1F3D),
    );
  }
}
