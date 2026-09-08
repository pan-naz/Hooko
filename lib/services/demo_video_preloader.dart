import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'demo_video_preloader_io.dart'
    if (dart.library.html) 'demo_video_preloader_stub.dart' as platform;

/// Preloads demo video for DemoScreen2
class DemoVideoPreloader {
  DemoVideoPreloader._();
  static final DemoVideoPreloader instance = DemoVideoPreloader._();

  VideoPlayerController? _controller;
  Completer<VideoPlayerController?>? _completer;
  bool _isStarting = false;
  static const String _assetPath = 'assets/videos/gym.mp4';

  Future<VideoPlayerController> _createController() async {
    if (platform.isWebPlatform) {
      return platform.createAssetController(_assetPath);
    }
    
    try {
      final byteData = await rootBundle.load(_assetPath);
      final bytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      return await platform.createFileController(_assetPath, bytes);
    } catch (e) {
      debugPrint('DemoVideoPreloader: Failed to load from bundle: $e');
      return platform.createAssetController(_assetPath);
    }
  }

  Future<void> preload() async {
    if (_controller != null || _isStarting) return;
    _isStarting = true;
    _completer ??= Completer<VideoPlayerController?>();
    
    try {
      final controller = await _createController();
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0.0);
      _controller = controller;
      
      if (!(_completer?.isCompleted ?? true)) {
        _completer?.complete(_controller);
      }
    } catch (e) {
      debugPrint('DemoVideoPreloader: preload failed: $e');
      if (!(_completer?.isCompleted ?? true)) {
        _completer?.complete(null);
      }
    } finally {
      _isStarting = false;
    }
  }

  Future<VideoPlayerController?> takeWhenReady({Duration? timeout}) async {
    unawaited(preload());

    Future<VideoPlayerController?> waitFuture;
    if (_controller != null) {
      waitFuture = Future.value(_controller);
    } else {
      _completer ??= Completer<VideoPlayerController?>();
      waitFuture = _completer!.future;
    }

    VideoPlayerController? ctrl;
    try {
      ctrl = timeout == null
          ? await waitFuture
          : await waitFuture.timeout(timeout);
    } catch (e) {
      debugPrint('DemoVideoPreloader: takeWhenReady error: $e');
      ctrl = null;
    }

    _controller = null;
    _completer = null;
    return ctrl;
  }

  Future<void> disposeIfUnused() async {
    try {
      await _controller?.dispose();
    } catch (_) {}
    _controller = null;
    _completer = null;
    _isStarting = false;
  }
}
