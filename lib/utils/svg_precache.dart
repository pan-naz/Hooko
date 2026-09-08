import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// List of all SVG assets used in the app that should be precached
const List<String> _svgAssets = [
  'assets/icons/checked.svg',
  'assets/icons/sound_on.svg',
  'assets/icons/close.svg',
  'assets/icons/analize.svg',
  'assets/icons/icon_logo.svg',
  'assets/icons/circle.svg',
  'assets/icons/google.svg',
  'assets/icons/sound_off.svg',
  'assets/icons/arrow_left.svg',
  'assets/icons/arrow_upright.svg',
  'assets/icons/upload.svg',
  'assets/icons/icon_history.svg',
  'assets/icons/icon_profile.svg',
  'assets/icons/apple.svg',
  'assets/icons/icon_analysis.svg',
  'assets/icons/copy.svg',
  'assets/icons/tips.svg',
  'assets/icons/plus.svg',
  'assets/icons/pen.svg',
  'assets/icons/chevron-down.svg',
  'assets/icons/mic.svg',
  'assets/icons/chevron-up.svg',
  'assets/icons/youtube.svg',
  'assets/icons/hashtag.svg',
  'assets/icons/script.svg',
  'assets/icons/warning.svg',
  'assets/icons/camera.svg',
  'assets/icons/tiktok.svg',
  'assets/icons/fire.svg',
  'assets/icons/star.svg',
  'assets/icons/chat.svg',
  'assets/icons/trash.svg',
  'assets/icons/play.svg',
  'assets/icons/pause.svg',
];

bool _svgPrecacheCompleted = false;
Future<void>? _inflightSvgPrecache;

/// Precaches all SVG assets so they're immediately available when the UI renders.
/// Safe to call multiple times — the work runs at most once per app session.
Future<void> precacheSvgAssets() {
  if (_svgPrecacheCompleted) return Future.value();
  if (_inflightSvgPrecache != null) return _inflightSvgPrecache!;

  final future = Future.wait(_svgAssets.map(_precacheSingleSvg)).then((_) {
    _svgPrecacheCompleted = true;
    debugPrint('Precached ${_svgAssets.length} SVG assets');
  });
  _inflightSvgPrecache = future;
  return future;
}

Future<void> _precacheSingleSvg(String assetPath) async {
  try {
    final loader = SvgAssetLoader(assetPath);
    await svg.cache.putIfAbsent(
      loader.cacheKey(null),
      () => loader.loadBytes(null),
    );
  } catch (e) {
    debugPrint('Failed to precache SVG: $assetPath - $e');
  }
}
