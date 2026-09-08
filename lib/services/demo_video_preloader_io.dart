import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

bool get isWebPlatform => false;

Future<VideoPlayerController> createFileController(String assetPath, List<int> bytes) async {
  final tempDir = await getTemporaryDirectory();
  final tempFile = File('${tempDir.path}/demo_video.mp4');
  await tempFile.writeAsBytes(bytes, flush: true);
  return VideoPlayerController.file(tempFile);
}

Future<VideoPlayerController> createAssetController(String assetPath) =>
    Future.value(VideoPlayerController.asset(assetPath));
