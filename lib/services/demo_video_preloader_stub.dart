import 'package:video_player/video_player.dart';

/// Stub implementation for web platform
bool get isWebPlatform => true;

Future<VideoPlayerController> createFileController(String assetPath, List<int> bytes) =>
    createAssetController(assetPath);

Future<VideoPlayerController> createAssetController(String assetPath) =>
    Future.value(VideoPlayerController.networkUrl(Uri.parse(assetPath)));
