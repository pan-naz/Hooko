import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hooko_v20/theme.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:hooko_v20/components/small_secondary_button.dart';

/// A half-circle gauge that displays a score from 0.0 to 1.0
/// with a background track and gradient progress arc.
/// Full-width elliptical arc with fixed height.
/// 
/// Optimized for iOS with RepaintBoundary for smooth animations.
class HalfCircleGauge extends StatelessWidget {
  /// Score value from 0.0 to 1.0
  final double score;

  /// Label text shown below the gauge
  final String label;

  /// Fitness benchmark out of 100 that the score is compared against.
  final int benchmark;

  /// Name of the niche to display (e.g., "Fitness", "Tech", etc.)
  final String nicheName;

  /// When true, the label shown below the gauge will be computed based on
  /// whether the score is above or below [benchmark].
  final bool showDynamicLabel;

  /// Text to display when the score is >= benchmark.
  final String aboveLabel;

  /// Text to display when the score is < benchmark.
  final String belowLabel;

  /// Stroke width of the gauge arcs
  final double? strokeWidth;

  /// Optional action for the "See details" button
  final VoidCallback? onSeeDetails;

  const HalfCircleGauge({
    super.key,
    required this.score,
    required this.label,
    this.benchmark = 70,
    this.nicheName = 'General',
    this.showDynamicLabel = true,
    this.aboveLabel = 'Above Benchmark',
    this.belowLabel = 'Below Benchmark',
    this.strokeWidth,
    this.onSeeDetails,
  });

  @override
  Widget build(BuildContext context) {
    final gaugeStroke = strokeWidth ?? ResponsiveSize.spacing(context, 14);
    final clampedScore = score.clamp(0.0, 1.0);
    final scoreValue = (clampedScore * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final radius = (availableWidth - gaugeStroke) / 2;
            const heightRatio = 0.9;
            final halfSweep = math.acos(1 - heightRatio);
            final totalSweep = halfSweep * 2;
            final arcHeight = radius * heightRatio + gaugeStroke;
            
            return SizedBox(
              width: availableWidth,
              height: arcHeight,
              child: Stack(
                children: [
                  // Gauge arc - wrapped in RepaintBoundary for smooth animation
                  RepaintBoundary(
                    child: CustomPaint(
                      size: Size(availableWidth, arcHeight),
                      painter: _HalfCircleGaugePainter(
                        score: clampedScore,
                        benchmark: benchmark / 100.0,
                        strokeWidth: gaugeStroke,
                        backgroundTrackColor: offWhite.withValues(alpha: 0.12),
                        gradientColors: const [
                          Color(0xFFFF2EC9), // Pink (start)
                          Color(0xFFED6A17), // Orange (end)
                        ],
                        radius: radius,
                        sweepAngle: totalSweep,
                        indicatorColor: offWhite,
                      ),
                      isComplex: false,
                      willChange: false,
                    ),
                  ),
                  // Score display
                  Positioned(
                    left: 0,
                    right: 0,
                    top: arcHeight * 0.35,
                    child: _ScoreDisplay(scoreValue: scoreValue),
                  ),
                ],
              ),
            );
          },
        ),
        SizedBox(height: ResponsiveSize.spacing(context, 12)),
        Text(
          _getLabelText(scoreValue),
          style: TextStyle(
            fontFamily: 'Geom',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveSize.text(context, 20),
            color: offWhite,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: ResponsiveSize.spacing(context, 16)),
        _BenchmarkRow(benchmark: benchmark, nicheName: nicheName),
        SizedBox(height: ResponsiveSize.spacing(context, 24)),
        SizedBox(
          width: double.infinity,
          child: SmallSecondaryButton(
            text: 'How it\'s calculated?',
            onPressed: onSeeDetails ?? () {},
          ),
        ),
      ],
    );
  }

  String _getLabelText(int scoreValue) {
    if (!showDynamicLabel) return label;
    return scoreValue >= benchmark ? aboveLabel : belowLabel;
  }
}

class _ScoreDisplay extends StatelessWidget {
  final int scoreValue;

  const _ScoreDisplay({required this.scoreValue});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Your Score',
          style: TextStyle(
            fontFamily: 'Geom',
            fontWeight: FontWeight.w300,
            fontSize: ResponsiveSize.text(context, 16),
            color: offWhite.withValues(alpha: 0.3),
          ),
        ),
        SizedBox(height: ResponsiveSize.spacing(context, 4)),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$scoreValue',
              style: TextStyle(
                fontFamily: 'Geom',
                fontWeight: FontWeight.w800,
                fontSize: ResponsiveSize.text(context, 40),
                color: offWhite,
                height: 1.0,
              ),
            ),
            Text(
              '/100',
              style: TextStyle(
                fontFamily: 'Geom',
                fontWeight: FontWeight.w300,
                fontSize: ResponsiveSize.text(context, 16),
                color: offWhite.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BenchmarkRow extends StatelessWidget {
  final int benchmark;
  final String nicheName;

  const _BenchmarkRow({required this.benchmark, required this.nicheName});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: ResponsiveSize.spacing(context, 8),
      runSpacing: ResponsiveSize.spacing(context, 8),
      children: [
        Text(
          '$nicheName benchmark:',
          style: TextStyle(
            fontFamily: 'Geom',
            fontWeight: FontWeight.w300,
            fontSize: ResponsiveSize.text(context, 12),
            color: offWhite,
          ),
          textAlign: TextAlign.center,
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveSize.spacing(context, 16),
            vertical: ResponsiveSize.spacing(context, 8),
          ),
          decoration: BoxDecoration(
            color: offWhite.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(ResponsiveSize.spacing(context, 20)),
          ),
          child: Text(
            '${benchmark.clamp(0, 100)}/100',
            style: TextStyle(
              fontFamily: 'Geom',
              fontWeight: FontWeight.w300,
              fontSize: ResponsiveSize.text(context, 12),
              color: offWhite,
            ),
          ),
        ),
      ],
    );
  }
}

class _HalfCircleGaugePainter extends CustomPainter {
  final double score;
  final double benchmark;
  final double strokeWidth;
  final Color backgroundTrackColor;
  final List<Color> gradientColors;
  final double radius;
  final double sweepAngle;
  final Color indicatorColor;

  // Cached paints - reused across frames to reduce GC pressure
  late final Paint _backgroundPaint;
  late final Paint _indicatorLinePaint;
  late final Paint _indicatorCirclePaint;

  _HalfCircleGaugePainter({
    required this.score,
    required this.benchmark,
    required this.strokeWidth,
    required this.backgroundTrackColor,
    required this.gradientColors,
    required this.radius,
    required this.sweepAngle,
    required this.indicatorColor,
  }) {
    // Initialize cached paints once
    _backgroundPaint = Paint()
      ..color = backgroundTrackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    _indicatorLinePaint = Paint()
      ..color = indicatorColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    
    _indicatorCirclePaint = Paint()
      ..color = indicatorColor
      ..style = PaintingStyle.fill;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = radius + strokeWidth / 2;

    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: radius * 2,
      height: radius * 2,
    );

    final startAngle = math.pi + (math.pi - sweepAngle) / 2;

    // Background track - use cached paint
    canvas.drawArc(rect, startAngle, sweepAngle, false, _backgroundPaint);

    // Score arc
    if (score > 0) {
      // Gradient shader must be created per-paint since it depends on rect
      final gradientShader = SweepGradient(
        center: Alignment.center,
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: gradientColors,
        stops: const [0.0, 1.0],
      ).createShader(rect);

      final scorePaint = Paint()
        ..shader = gradientShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final scoreSweep = sweepAngle * score;
      canvas.drawArc(rect, startAngle, scoreSweep, false, scorePaint);
    }

    // Benchmark indicator
    _drawBenchmarkIndicator(canvas, centerX, centerY, startAngle);
  }

  void _drawBenchmarkIndicator(
    Canvas canvas, 
    double centerX, 
    double centerY, 
    double startAngle,
  ) {
    final benchmarkAngle = startAngle + sweepAngle * benchmark.clamp(0.0, 1.0);
    final lineLength = strokeWidth * 2.5;
    final halfLine = lineLength / 2;

    final lineStartX = centerX + (radius - halfLine) * math.cos(benchmarkAngle);
    final lineStartY = centerY + (radius - halfLine) * math.sin(benchmarkAngle);
    final lineEndX = centerX + (radius + halfLine) * math.cos(benchmarkAngle);
    final lineEndY = centerY + (radius + halfLine) * math.sin(benchmarkAngle);

    // Use cached paints
    canvas.drawLine(
      Offset(lineStartX, lineStartY),
      Offset(lineEndX, lineEndY),
      _indicatorLinePaint,
    );

    canvas.drawCircle(Offset(lineEndX, lineEndY), 4.0, _indicatorCirclePaint);
  }

  @override
  bool shouldRepaint(covariant _HalfCircleGaugePainter oldDelegate) =>
      oldDelegate.score != score ||
      oldDelegate.benchmark != benchmark ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.backgroundTrackColor != backgroundTrackColor ||
      oldDelegate.radius != radius ||
      oldDelegate.sweepAngle != sweepAngle ||
      oldDelegate.indicatorColor != indicatorColor;
}
