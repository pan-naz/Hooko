import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:video_compress/video_compress.dart';
import 'package:hooko_v20/services/analysis_service.dart';

/// Singleton manager that tracks active operations (video players, analysis)
/// and can clean them up on hot restart or app close.
/// 
/// This is necessary because hot restart doesn't trigger normal dispose() lifecycle,
/// leaving video players and analysis processes running in the background.
class ActiveOperationsManager {
  ActiveOperationsManager._();
  static final instance = ActiveOperationsManager._();
  
  /// Active video player controllers
  final Set<VideoPlayerController> _videoControllers = {};
  
  /// Active analysis cancellation tokens
  final Set<AnalysisCancellationToken> _cancellationTokens = {};
  
  /// Whether cleanup has been called this session
  bool _hasCleanedUp = false;
  
  /// Register a video controller for tracking
  void registerVideoController(VideoPlayerController controller) {
    _videoControllers.add(controller);
    debugPrint('ActiveOperationsManager: Registered video controller (total: ${_videoControllers.length})');
  }
  
  /// Unregister a video controller (call in dispose)
  void unregisterVideoController(VideoPlayerController controller) {
    _videoControllers.remove(controller);
    debugPrint('ActiveOperationsManager: Unregistered video controller (total: ${_videoControllers.length})');
  }
  
  /// Register a cancellation token for tracking
  void registerCancellationToken(AnalysisCancellationToken token) {
    _cancellationTokens.add(token);
    debugPrint('ActiveOperationsManager: Registered cancellation token (total: ${_cancellationTokens.length})');
  }
  
  /// Unregister a cancellation token (call when analysis completes)
  void unregisterCancellationToken(AnalysisCancellationToken token) {
    _cancellationTokens.remove(token);
    debugPrint('ActiveOperationsManager: Unregistered cancellation token (total: ${_cancellationTokens.length})');
  }
  
  /// Clean up all active operations
  /// Call this on app startup to handle hot restart scenario
  Future<void> cleanupAll() async {
    if (_hasCleanedUp) {
      debugPrint('ActiveOperationsManager: Already cleaned up this session');
      return;
    }
    _hasCleanedUp = true;
    
    debugPrint('ActiveOperationsManager: Starting cleanup...');
    debugPrint('ActiveOperationsManager: ${_videoControllers.length} video controllers, ${_cancellationTokens.length} cancellation tokens');
    
    // Cancel all ongoing analysis operations
    for (final token in _cancellationTokens.toList()) {
      try {
        await token.cancel();
        debugPrint('ActiveOperationsManager: Cancelled analysis token');
      } catch (e) {
        debugPrint('ActiveOperationsManager: Error cancelling token: $e');
      }
    }
    _cancellationTokens.clear();
    
    // Stop and dispose all video controllers
    for (final controller in _videoControllers.toList()) {
      try {
        if (controller.value.isInitialized) {
          await controller.pause();
          await controller.dispose();
          debugPrint('ActiveOperationsManager: Disposed video controller');
        }
      } catch (e) {
        debugPrint('ActiveOperationsManager: Error disposing controller: $e');
      }
    }
    _videoControllers.clear();
    
    // Cancel any ongoing video compression
    try {
      await VideoCompress.cancelCompression();
      debugPrint('ActiveOperationsManager: Cancelled video compression');
    } catch (e) {
      debugPrint('ActiveOperationsManager: Error cancelling compression: $e');
    }
    
    // Delete any temp files from VideoCompress
    try {
      await VideoCompress.deleteAllCache();
      debugPrint('ActiveOperationsManager: Cleared video compress cache');
    } catch (e) {
      debugPrint('ActiveOperationsManager: Error clearing cache: $e');
    }
    
    debugPrint('ActiveOperationsManager: Cleanup complete');
  }
  
  /// Reset the cleanup flag (call when navigating away from analysis)
  void resetCleanupFlag() {
    _hasCleanedUp = false;
  }
  
  /// Check if there are any active operations
  bool get hasActiveOperations => _videoControllers.isNotEmpty || _cancellationTokens.isNotEmpty;
  
  /// Get count of active video controllers
  int get activeVideoControllerCount => _videoControllers.length;
  
  /// Get count of active analysis operations
  int get activeAnalysisCount => _cancellationTokens.length;
}
