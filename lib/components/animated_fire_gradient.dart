import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Animated fire gradient background.
/// 
/// The gradient includes its own solid background (0xFF110A1D) and is
/// wrapped in RepaintBoundary for optimal rendering performance.
/// 
/// Pass [isScrolling] to pause animation during scroll for better performance.
/// Pass [isPaused] to pause animation based on route/screen visibility.
class AnimatedFireGradient extends StatelessWidget {
  /// Optional notifier to pause animation while scrolling
  final ValueNotifier<bool>? isScrolling;
  
  /// Optional notifier to pause animation (e.g., when on static gradient screens)
  final ValueNotifier<bool>? isPaused;
  
  const AnimatedFireGradient({super.key, this.isScrolling, this.isPaused});
  
  /// Convenience getter - creates a new instance each time (safe for widget tree)
  static Widget get instance => const AnimatedFireGradient();
  
  /// Create with scroll notifier for performance optimization
  static Widget withScrollNotifier(ValueNotifier<bool> isScrolling) => 
      AnimatedFireGradient(isScrolling: isScrolling);

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ColoredBox(
        color: const Color(0xFF110A1D), // Permanent solid background
        child: RepaintBoundary(
          child: _AnimatedGradientContent(isScrolling: isScrolling, isPaused: isPaused),
        ),
      ),
    );
  }
}

/// Static fire gradient for older devices - no animation, minimal GPU usage
class StaticFireGradient extends StatelessWidget {
  const StaticFireGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ColoredBox(
        color: const Color(0xFF110A1D),
        child: RepaintBoundary(
          child: CustomPaint(
            painter: const _StaticFireGradientPainter(),
            isComplex: false,
            willChange: false,
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

/// Static gradient painter - paints once, never updates
class _StaticFireGradientPainter extends CustomPainter {
  const _StaticFireGradientPainter();

  static const Color deepRed = Color(0xFFAE1787);
  static const Color orange = Color(0xFFEC6916);
  static const Color brightOrange = Color(0xFFFF8C00);
  
  static const List<double> standardStops = [
    0.0, 0.15, 0.30, 0.45, 0.60, 0.75, 0.88, 1.0
  ];
  
  static const List<double> layer1Alphas = [0.7, 0.55, 0.42, 0.30, 0.20, 0.10, 0.03, 0.0];
  static const List<double> layer2Alphas = [0.5, 0.40, 0.30, 0.22, 0.14, 0.08, 0.02, 0.0];
  static const List<double> layer3Alphas = [0.4, 0.32, 0.24, 0.16, 0.10, 0.05, 0.015, 0.0];
  
  static final List<Color> _layer1Colors = layer1Alphas.map((a) => deepRed.withValues(alpha: a)).toList();
  static final List<Color> _layer2Colors = layer2Alphas.map((a) => orange.withValues(alpha: a)).toList();
  static final List<Color> _layer3Colors = layer3Alphas.map((a) => brightOrange.withValues(alpha: a)).toList();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint();
    
    // Layer 1: Deep base fire (fixed position)
    paint.shader = ui.Gradient.radial(
      Offset(rect.width * 0.5, rect.height * 1.0),
      rect.width * 1.2,
      _layer1Colors,
      standardStops,
      TileMode.clamp,
    );
    canvas.drawRect(rect, paint);

    // Layer 2: Center fire plume (fixed position)
    paint.shader = ui.Gradient.radial(
      Offset(rect.width * 0.5, rect.height * 1.075),
      rect.width * 0.8,
      _layer2Colors,
      standardStops,
      TileMode.clamp,
    );
    canvas.drawRect(rect, paint);

    // Layer 3: Bright highlight (fixed position)
    paint.shader = ui.Gradient.radial(
      Offset(rect.width * 0.5, rect.height * 1.125),
      rect.width * 0.6,
      _layer3Colors,
      standardStops,
      TileMode.clamp,
    );
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_StaticFireGradientPainter oldDelegate) => false;
}

/// The actual animated content - internal only
class _AnimatedGradientContent extends StatefulWidget {
  final ValueNotifier<bool>? isScrolling;
  final ValueNotifier<bool>? isPaused;
  
  const _AnimatedGradientContent({this.isScrolling, this.isPaused});

  @override
  State<_AnimatedGradientContent> createState() => _AnimatedGradientContentState();
}

class _AnimatedGradientContentState extends State<_AnimatedGradientContent>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _elapsed = 0.0;
  Duration _lastTime = Duration.zero;
  bool _animate = true;
  
  // Frame rate - 60fps for smooth animation (localized gradient, disposed when off-screen)
  static const _frameInterval = Duration(milliseconds: 16); // ~60fps
  Duration _lastFrameTime = Duration.zero;
  
  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
    
    // Listen to scroll state changes
    widget.isScrolling?.addListener(_onAnimationStateChanged);
    // Listen to pause state changes (route-based)
    widget.isPaused?.addListener(_onAnimationStateChanged);
    
    // Initial check
    _updateAnimationState();
  }
  
  @override
  void didUpdateWidget(covariant _AnimatedGradientContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isScrolling != widget.isScrolling) {
      oldWidget.isScrolling?.removeListener(_onAnimationStateChanged);
      widget.isScrolling?.addListener(_onAnimationStateChanged);
    }
    if (oldWidget.isPaused != widget.isPaused) {
      oldWidget.isPaused?.removeListener(_onAnimationStateChanged);
      widget.isPaused?.addListener(_onAnimationStateChanged);
    }
  }
  
  void _onAnimationStateChanged() {
    _updateAnimationState();
  }
  
  void _updateAnimationState() {
    final isScrolling = widget.isScrolling?.value ?? false;
    final isPaused = widget.isPaused?.value ?? false;
    final shouldAnimate = !isScrolling && !isPaused;
    
    if (!shouldAnimate && _animate) {
      _animate = false;
    } else if (shouldAnimate && !_animate) {
      _animate = true;
      _lastTime = Duration.zero;
      _lastFrameTime = Duration.zero;
    }
  }
  
  void _onTick(Duration elapsed) {
    if (!_animate) return;
    
    // Frame rate limiting to reduce GPU load
    if (elapsed - _lastFrameTime < _frameInterval) return;
    _lastFrameTime = elapsed;
    
    final delta = (elapsed - _lastTime).inMicroseconds / 1000000.0;
    _lastTime = elapsed;
    
    setState(() {
      _elapsed += delta;
    });
  }
  
  /// Pause animation
  void pauseAnimation() {
    _animate = false;
  }
  
  /// Resume animation
  void resumeAnimation() {
    _animate = true;
    _lastTime = Duration.zero;
    _lastFrameTime = Duration.zero;
  }

  @override
  void dispose() {
    widget.isScrolling?.removeListener(_onAnimationStateChanged);
    widget.isPaused?.removeListener(_onAnimationStateChanged);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _FireGradientPainter(elapsed: _elapsed),
    isComplex: true,
    willChange: _animate,
    size: Size.infinite,
  );
}

class _FireGradientPainter extends CustomPainter {
  final double elapsed;
  
  // Pre-computed colors to avoid allocation during paint
  static const Color deepRed = Color(0xFFAE1787);
  static const Color orange = Color(0xFFEC6916);
  static const Color brightOrange = Color(0xFFFF8C00);
  
  // Cached gradient stops
  static const List<double> standardStops = [
    0.0, 0.15, 0.30, 0.45, 0.60, 0.75, 0.88, 1.0
  ];
  
  // Pre-computed alpha values for each layer
  static const List<double> layer1Alphas = [0.7, 0.55, 0.42, 0.30, 0.20, 0.10, 0.03, 0.0];
  static const List<double> layer2Alphas = [0.5, 0.40, 0.30, 0.22, 0.14, 0.08, 0.02, 0.0];
  static const List<double> layer3Alphas = [0.4, 0.32, 0.24, 0.16, 0.10, 0.05, 0.015, 0.0];
  
  // Pre-computed gradient colors for each layer (cached statically)
  static final List<Color> _layer1Colors = layer1Alphas.map((a) => deepRed.withValues(alpha: a)).toList();
  static final List<Color> _layer2Colors = layer2Alphas.map((a) => orange.withValues(alpha: a)).toList();
  static final List<Color> _layer3Colors = layer3Alphas.map((a) => brightOrange.withValues(alpha: a)).toList();
  
  // Cached Paint object to reduce allocations
  static final Paint _layerPaint = Paint();
  
  const _FireGradientPainter({required this.elapsed});

  // Convert elapsed time to smooth wave using sine
  double _wave(double speed, {double offset = 0}) =>
      math.sin((elapsed * speed + offset) * 2 * math.pi);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Pre-calculate wave values once
    final slowWave = _wave(0.242); // ~4.1 second period
    final mediumWave = _wave(0.354, offset: 0.33); // ~2.8 second period
    
    // Layer 1: Deep base fire (largest, slowest)
    _paintLayerFast(
      canvas, rect,
      center: Alignment(slowWave * 0.22, 1.0 + slowWave * 0.165),
      radius: 1.2,
      colors: _layer1Colors,
    );

    // Layer 2: Center fire plume
    _paintLayerFast(
      canvas, rect,
      center: Alignment(mediumWave * 0.165, 1.15 + slowWave * 0.11),
      radius: 0.8,
      colors: _layer2Colors,
    );

    // Layer 3: Bright highlight
    _paintLayerFast(
      canvas, rect,
      center: Alignment(slowWave * 0.11, 1.25),
      radius: 0.6,
      colors: _layer3Colors,
    );
  }

  /// Optimized paint layer using pre-computed cached colors
  void _paintLayerFast(
    Canvas canvas, 
    Rect rect, {
    required Alignment center,
    required double radius,
    required List<Color> colors,
  }) {
    _layerPaint.shader = ui.Gradient.radial(
      Offset(
        rect.width * (0.5 + center.x * 0.5),
        rect.height * (0.5 + center.y * 0.5),
      ),
      rect.width * radius,
      colors,
      standardStops,
      TileMode.clamp,
    );
    canvas.drawRect(rect, _layerPaint);
  }

  @override
  bool shouldRepaint(_FireGradientPainter oldDelegate) =>
      oldDelegate.elapsed != elapsed;
}
