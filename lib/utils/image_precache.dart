import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Background images to precache.
/// These are referenced as full-bleed backgrounds across the app
/// (history empty state, demo/uploaded video backgrounds, profile, etc.).
const List<String> backgroundImages = [
  'assets/images/run.jpg',
  'assets/images/city.jpg',
  'assets/images/tree.jpg',
  'assets/images/history.jpg',
  'assets/images/launcher.png',
];

/// Tracks whether we've cached for a specific devicePixelRatio bucket already.
/// Image variants are resolved per-DPR, so caching at 1x doesn't help a 3x
/// device. We keep a per-DPR completion set to avoid duplicate work but still
/// allow the correct variant to be cached as soon as a real context exists.
final Set<double> _dprCached = <double>{};
Future<void>? _inflightNoContext;
final Map<double, Future<void>> _inflightForDpr = {};

/// Precaches all background images in parallel.
///
/// - Can be called from `main()` BEFORE any widgets exist (no context). In
///   that case the 1x variant is loaded into the image cache as a best-effort
///   warm-up (cheap, decoded once at app start).
/// - Should ALSO be called as soon as a real `BuildContext` is available
///   (e.g. from the first widget that mounts). This caches the correct
///   per-DPR variant that subsequent `Image.asset` widgets will actually
///   request, eliminating the perceived delay.
///
/// Safe to call multiple times — work is deduplicated per DPR bucket.
Future<void> precacheBackgroundImages([BuildContext? context]) {
  if (context == null) {
    if (_dprCached.contains(1.0)) return Future.value();
    if (_inflightNoContext != null) return _inflightNoContext!;
    final f = Future.wait(
      backgroundImages.map((p) => _resolveAsset(p, ImageConfiguration.empty)),
    ).then((_) {
      _dprCached.add(1.0);
      debugPrint('Precached ${backgroundImages.length} bg images @1x (no ctx)');
    });
    _inflightNoContext = f;
    return f;
  }

  final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ??
      ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
  if (_dprCached.contains(dpr)) return Future.value();
  if (_inflightForDpr[dpr] != null) return _inflightForDpr[dpr]!;

  final config = createLocalImageConfiguration(context);
  final f = Future.wait(
    backgroundImages.map((p) => _resolveAsset(p, config)),
  ).then((_) {
    _dprCached.add(dpr);
    debugPrint(
        'Precached ${backgroundImages.length} bg images @${dpr}x (with ctx)');
  });
  _inflightForDpr[dpr] = f;
  return f;
}

Future<void> _resolveAsset(String path, ImageConfiguration config) {
  final completer = Completer<void>();
  final image = AssetImage(path);
  final stream = image.resolve(config);
  late ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      if (!completer.isCompleted) completer.complete();
      stream.removeListener(listener);
    },
    onError: (e, _) {
      debugPrint('Failed to precache: $path - $e');
      if (!completer.isCompleted) completer.complete();
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);
  return completer.future;
}

/// Whether the background image precache has completed for the current device.
bool get backgroundImagesReady => _dprCached.isNotEmpty;
