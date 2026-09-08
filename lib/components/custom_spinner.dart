import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Minimal rotating gradient spinner.
/// Optimized for iOS with RepaintBoundary, frame rate limiting, and efficient repaints.
class CustomSpinner extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Color color;
  final Color? secondaryColor;
  final Color? trackColor; // retained for API compatibility; unused

  const CustomSpinner({
    super.key,
    this.size = 24,
    this.strokeWidth = 2.0,
    this.color = const Color(0xFFFEFEFE),
    this.secondaryColor,
    this.trackColor,
  });

  @override
  State<CustomSpinner> createState() => _CustomSpinnerState();
}

class _CustomSpinnerState extends State<CustomSpinner>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _rotation = 0.0;
  Duration _lastFrameTime = Duration.zero;
  
  // Target 30fps for spinner - more than enough for a loading indicator
  static const _frameInterval = Duration(milliseconds: 33);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }
  
  void _onTick(Duration elapsed) {
    if (elapsed - _lastFrameTime < _frameInterval) return;
    _lastFrameTime = elapsed;
    
    setState(() {
      // Complete rotation every 1 second
      _rotation = (elapsed.inMilliseconds % 1000) / 1000.0;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSecondaryColor = widget.secondaryColor ?? 
        widget.color.withValues(alpha: 0.35);
    
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _SpinnerPainter(
            color: widget.color,
            secondaryColor: effectiveSecondaryColor,
            strokeWidth: widget.strokeWidth,
            rotationValue: _rotation,
          ),
          isComplex: false,
          willChange: true,
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  final double strokeWidth;
  final Color color;
  final Color secondaryColor;
  final double rotationValue;
  
  // Cached gradient colors - built once per painter instance
  late final List<Color> _gradientColors;
  
  // Cached paint for reuse
  late final Paint _paint;

  _SpinnerPainter({
    required this.strokeWidth,
    required this.color,
    required this.secondaryColor,
    required this.rotationValue,
  }) {
    // Build gradient colors once
    _gradientColors = [
      secondaryColor.withValues(alpha: 0.0),
      secondaryColor.withValues(alpha: 0.0),
      secondaryColor.withValues(alpha: 0.06),
      secondaryColor.withValues(alpha: 0.14),
      secondaryColor.withValues(alpha: 0.26),
      secondaryColor.withValues(alpha: 0.42),
      secondaryColor.withValues(alpha: 0.62),
      color,
      secondaryColor.withValues(alpha: 0.0),
      secondaryColor.withValues(alpha: 0.0),
    ];
    
    // Pre-configure paint
    _paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
  }
  
  // Cached stops - shared across all instances
  static const List<double> _stops = [0.0, 0.15, 0.40, 0.60, 0.75, 0.85, 0.88, 0.92, 0.93, 1.0];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Only create gradient with rotation - colors are cached
    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: math.pi * 2,
      colors: _gradientColors,
      stops: _stops,
      // Offset by -90° so the bright segment starts at 12 o'clock
      transform: GradientRotation((rotationValue * math.pi * 2) - (math.pi / 2)),
    );

    _paint.shader = gradient.createShader(rect);
    canvas.drawArc(rect, 0, math.pi * 2, false, _paint);
  }

  @override
  bool shouldRepaint(covariant _SpinnerPainter oldDelegate) =>
      oldDelegate.rotationValue != rotationValue ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.color != color ||
      oldDelegate.secondaryColor != secondaryColor;
}
