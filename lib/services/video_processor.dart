import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_compress/video_compress.dart';
import 'package:hooko_v20/services/video_file_reader.dart';

/// Video processing configuration
class VideoProcessingConfig {
  /// Target resolution for first compression (480p)
  static const int targetHeight480p = 480;
  
  /// Target resolution for second compression (360p)
  static const int targetHeight360p = 360;
  
  /// Target frame rate
  static const int targetFps = 24;
  
  /// Quality setting - using MediumQuality for smaller files
  static const VideoQuality quality = VideoQuality.MediumQuality;
  
  /// Lower quality for 360p fallback
  static const VideoQuality qualityLow = VideoQuality.LowQuality;
  
  /// Max compression attempts per stage
  static const int maxAttempts = 2;
  
  /// Max file size in MB for Gemini inline upload
  static const double maxSizeMB = 15.0;
  
  // MediumQuality: Lower bitrate, smaller files (~15-25 MB per minute)
}

/// Service for preprocessing video before analysis
/// 
/// Processing: Convert any video to MP4, MediumQuality, 24fps
class VideoProcessor {
  /// Process video - convert to MP4, MediumQuality, 24fps
  /// Returns processed video bytes ready for upload
  static Future<VideoProcessingResult> processVideo(
    AssetEntity videoAsset, {
    Function(String status, double progress)? onProgress,
    bool isRetry = false,
  }) async {
    try {
      onProgress?.call('Getting video info...', 0.05);
      
      // Get the original video file first to determine size
      final file = await videoAsset.file;
      if (file == null) {
        throw Exception('Could not access video file');
      }
      
      final filePath = file.path;
      final duration = videoAsset.videoDuration;
      final durationSeconds = duration.inSeconds;
      final originalSizeBytes = await file.length();
      final originalSizeMB = originalSizeBytes / (1024 * 1024);
      
      // CRITICAL: Warm up video_compress plugin to prevent first-try failures
      // The plugin often returns original file on first call if not properly initialized
      try {
        // Step 1: Clear any existing cache
        await VideoCompress.deleteAllCache();
        
        // Step 2: "Warm up" the plugin by getting media info first
        // This initializes the native codec pipeline
        debugPrint('VideoProcessor: Warming up compression pipeline...');
        await VideoCompress.getMediaInfo(filePath);
        
        // Step 3: Additional delay for large files to ensure codec is ready
        final warmupDelay = originalSizeMB > 100 ? 1000 : (originalSizeMB > 50 ? 700 : 400);
        await Future.delayed(Duration(milliseconds: warmupDelay));
        
        debugPrint('VideoProcessor: Pipeline ready (warmup: ${warmupDelay}ms for ${originalSizeMB.toStringAsFixed(1)}MB file)');
      } catch (e) {
        debugPrint('VideoProcessor: Warmup failed (non-fatal): $e');
        // Continue anyway - compression might still work
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      debugPrint('VideoProcessor: Original video - duration: ${durationSeconds}s, size: ${originalSizeMB.toStringAsFixed(2)} MB');
      
      // Generate high-quality thumbnail from ORIGINAL video BEFORE compression
      onProgress?.call('Generating thumbnail...', 0.08);
      final thumbnailBytes = await _generateHighQualityThumbnail(
        filePath, // Use original file, not compressed
        videoAsset,
        durationSeconds,
      );
      debugPrint('VideoProcessor: Thumbnail generated from original video');
      
      onProgress?.call('Processing video...', 0.1);
      
      // === STAGE 1: Compress to 480p ===
      onProgress?.call('Compressing video (480p)...', 0.1);
      
      var progressSubscription = VideoCompress.compressProgress$.subscribe((progress) {
        final mappedProgress = 0.1 + (progress / 100.0) * 0.3;
        onProgress?.call('Compressing video (480p)...', mappedProgress);
      });
      
      String? compressedPath = await _compressWithRetry(
        filePath,
        VideoProcessingConfig.quality,
        VideoProcessingConfig.targetFps,
      );
      
      progressSubscription.unsubscribe();
      
      if (compressedPath == null) {
        throw Exception('COMPRESSION_FAILED: Failed to compress video. Please try again.');
      }
      
      onProgress?.call('Checking video size...', 0.45);
      
      var videoBytes = await readFileFromPath(compressedPath);
      
      if (videoBytes == null || videoBytes.isEmpty) {
        throw Exception('Failed to read compressed video');
      }
      
      var sizeMB = videoBytes.length / (1024 * 1024);
      debugPrint('VideoProcessor: 480p size: ${sizeMB.toStringAsFixed(2)} MB');
      
      // === STAGE 2: Check if recompression to 360p is needed ===
      if (sizeMB > VideoProcessingConfig.maxSizeMB) {
        debugPrint('VideoProcessor: Video > ${VideoProcessingConfig.maxSizeMB}MB, recompressing to 360p...');
        
        // Clear cache before second compression
        await VideoCompress.deleteAllCache();
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Warm up again for the original file
        try {
          await VideoCompress.getMediaInfo(filePath);
          await Future.delayed(const Duration(milliseconds: 400));
        } catch (_) {}
        
        onProgress?.call('Recompressing video (360p)...', 0.5);
        
        progressSubscription = VideoCompress.compressProgress$.subscribe((progress) {
          final mappedProgress = 0.5 + (progress / 100.0) * 0.3;
          onProgress?.call('Recompressing video (360p)...', mappedProgress);
        });
        
        // Compress to 360p with lower quality
        compressedPath = await _compressWithRetry(
          filePath,
          VideoProcessingConfig.qualityLow,
          VideoProcessingConfig.targetFps,
        );
        
        progressSubscription.unsubscribe();
        
        if (compressedPath == null) {
          throw Exception('COMPRESSION_FAILED: Failed to recompress video to 360p. Please try again.');
        }
        
        onProgress?.call('Checking video size...', 0.85);
        
        videoBytes = await readFileFromPath(compressedPath);
        
        if (videoBytes == null || videoBytes.isEmpty) {
          throw Exception('Failed to read recompressed video');
        }
        
        sizeMB = videoBytes.length / (1024 * 1024);
        debugPrint('VideoProcessor: 360p size: ${sizeMB.toStringAsFixed(2)} MB');
        
        // Final size check
        if (sizeMB > VideoProcessingConfig.maxSizeMB) {
          throw Exception('VIDEO_TOO_HEAVY: Video too heavy, please record a lower-quality video.');
        }
      }
      
      debugPrint('VideoProcessor: Final size: ${sizeMB.toStringAsFixed(2)} MB');
      
      await VideoCompress.deleteAllCache();
      onProgress?.call('Processing complete', 1.0);
      
      // Use thumbnail generated from original video (before compression)
      return VideoProcessingResult(
        videoBytes: videoBytes,
        thumbnailBytes: thumbnailBytes,
        durationSeconds: durationSeconds,
        sizeMB: sizeMB,
      );
    } catch (e) {
      debugPrint('VideoProcessor: Error: $e');
      try {
        await VideoCompress.deleteAllCache();
      } catch (_) {}
      rethrow;
    }
  }
  
  /// Fallback processing without native compression
  static Future<VideoProcessingResult> processVideoFallback(
    AssetEntity videoAsset, {
    Function(String status, double progress)? onProgress,
  }) async {
    try {
      onProgress?.call('Getting video...', 0.1);
      
      final file = await videoAsset.file;
      if (file == null) {
        throw Exception('Could not access video file');
      }
      
      final duration = videoAsset.videoDuration;
      final durationSeconds = duration.inSeconds;
      
      // Generate high-quality thumbnail from original video FIRST
      onProgress?.call('Generating thumbnail...', 0.2);
      final thumbData = await _generateHighQualityThumbnail(
        file.path,
        videoAsset,
        durationSeconds,
      );
      debugPrint('VideoProcessor (fallback): Thumbnail generated from original video');
      
      onProgress?.call('Reading video...', 0.5);
      
      final videoBytes = await file.readAsBytes();
      final sizeMB = videoBytes.length / (1024 * 1024);
      
      debugPrint('VideoProcessor (fallback): Size: ${sizeMB.toStringAsFixed(2)} MB');
      
      onProgress?.call('Complete', 1.0);
      
      return VideoProcessingResult(
        videoBytes: videoBytes,
        thumbnailBytes: thumbData,
        durationSeconds: durationSeconds,
        sizeMB: sizeMB,
      );
    } catch (e) {
      debugPrint('VideoProcessor: Fallback error: $e');
      rethrow;
    }
  }
  
  /// Cancel any ongoing compression
  static Future<void> cancelCompression() async {
    await VideoCompress.cancelCompression();
  }
  
  /// Helper method to compress video with retry logic
  static Future<String?> _compressWithRetry(
    String filePath,
    VideoQuality quality,
    int frameRate,
  ) async {
    final maxAttempts = VideoProcessingConfig.maxAttempts;
    
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      debugPrint('VideoProcessor: Compression attempt $attempt/$maxAttempts (quality: $quality)');
      
      try {
        final compressResult = await VideoCompress.compressVideo(
          filePath,
          quality: quality,
          includeAudio: true,
          frameRate: frameRate,
        );
        
        if (compressResult?.file != null) {
          final compressedPath = compressResult!.file!.path;
          
          // Check if it actually created a new file (not original)
          if (compressedPath != filePath && compressedPath.toLowerCase().endsWith('.mp4')) {
            debugPrint('VideoProcessor: Compression succeeded on attempt $attempt');
            debugPrint('VideoProcessor: Compressed to: $compressedPath');
            return compressedPath;
          }
          
          debugPrint('VideoProcessor: Compression returned original/invalid file on attempt $attempt');
        } else {
          debugPrint('VideoProcessor: Compression returned null on attempt $attempt');
        }
        
        // Clear cache before retry
        if (attempt < maxAttempts) {
          await VideoCompress.deleteAllCache();
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        debugPrint('VideoProcessor: Compression error on attempt $attempt: $e');
        if (attempt < maxAttempts) {
          await VideoCompress.deleteAllCache();
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }
    
    return null;
  }
  
  /// Generate a high-quality thumbnail from video
  /// Captures the FIRST frame (position 0) of the video
  /// Uses 720x1280 resolution with 95% quality
  static Future<Uint8List?> _generateHighQualityThumbnail(
    String videoPath,
    AssetEntity videoAsset,
    int durationSeconds,
  ) async {
    try {
      // Capture the first frame of the video (position 0)
      const positionMs = 0;
      
      // Try VideoCompress for better quality thumbnail
      final thumbFile = await VideoCompress.getFileThumbnail(
        videoPath,
        quality: 95, // Higher quality
        position: positionMs, // First frame
      );
      
      if (thumbFile.existsSync()) {
        final bytes = await thumbFile.readAsBytes();
        if (bytes.isNotEmpty) {
          debugPrint('VideoProcessor: Generated HD thumbnail from first frame, size: ${(bytes.length / 1024).toStringAsFixed(1)} KB');
          return bytes;
        }
      }
    } catch (e) {
      debugPrint('VideoProcessor: VideoCompress thumbnail failed: $e');
    }
    
    // Fallback to photo_manager thumbnail with higher resolution
    try {
      final thumbData = await videoAsset.thumbnailDataWithSize(
        const ThumbnailSize(720, 1280), // Higher resolution
        quality: 95, // Higher quality
      );
      if (thumbData != null) {
        debugPrint('VideoProcessor: Generated fallback thumbnail, size: ${(thumbData.length / 1024).toStringAsFixed(1)} KB');
      }
      return thumbData;
    } catch (e) {
      debugPrint('VideoProcessor: Fallback thumbnail failed: $e');
      return null;
    }
  }
}

/// Result of video processing
class VideoProcessingResult {
  /// Processed video bytes ready for upload
  final Uint8List videoBytes;
  
  /// Thumbnail bytes for preview
  final Uint8List? thumbnailBytes;
  
  /// Video duration in seconds
  final int durationSeconds;
  
  /// Video size in MB
  final double sizeMB;
  
  const VideoProcessingResult({
    required this.videoBytes,
    this.thumbnailBytes,
    required this.durationSeconds,
    required this.sizeMB,
  });
  
  /// Check if video is ready for upload
  bool get isValid => videoBytes.isNotEmpty;
}
