import 'package:flutter/material.dart';
import 'package:hooko_v20/theme.dart';

/// Reusable segmented progress bar widget used by AudioScoreCard and VisualScoreCard.
/// Extracted to avoid code duplication and ensure consistent rendering.
/// Optimized for iOS with cached decorations and RepaintBoundary.
class SegmentedProgressBar extends StatelessWidget {
  final double score;
  final Color color;
  final int totalSegments;
  final double spacing;
  final double height;

  const SegmentedProgressBar({
    super.key,
    required this.score,
    required this.color,
    this.totalSegments = 20,
    this.spacing = 2,
    this.height = 12,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0.0, 100.0);
    final exact = (clamped / 100) * totalSegments;
    final fullSegments = exact.floor();
    final partialFraction = (exact - fullSegments).clamp(0.0, 1.0);

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 0;
          final double totalSpacing = spacing * (totalSegments - 1);
          final double segmentWidth = totalSegments > 0 ? (maxWidth - totalSpacing) / totalSegments : 0;

          return Row(
            children: [
              for (int i = 0; i < totalSegments; i++) ...[
                if (i > 0) SizedBox(width: spacing),
                _buildSegment(i, fullSegments, partialFraction, segmentWidth),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSegment(int index, int fullSegments, double partialFraction, double width) {
    final bool isFull = index < fullSegments;
    final bool isPartial = index == fullSegments && 
                           partialFraction > 0 && 
                           fullSegments < totalSegments;

    if (isFull) {
      return _FullSegment(width: width, height: height, color: color);
    } else if (isPartial) {
      return _PartialSegment(
        width: width,
        height: height,
        color: color,
        fraction: partialFraction,
      );
    } else {
      return _EmptySegment(width: width, height: height);
    }
  }
}

class _FullSegment extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const _FullSegment({
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: const BorderRadius.all(Radius.circular(4)),
    ),
    child: SizedBox(width: width, height: height),
  );
}

class _PartialSegment extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double fraction;

  const _PartialSegment({
    required this.width,
    required this.height,
    required this.color,
    required this.fraction,
  });

  static const _emptyDecoration = BoxDecoration(
    color: progressEmptyColor,
    borderRadius: BorderRadius.all(Radius.circular(4)),
  );

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(decoration: _emptyDecoration),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: width * fraction,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
          ),
        ),
      ],
    ),
  );
}

class _EmptySegment extends StatelessWidget {
  final double width;
  final double height;

  const _EmptySegment({
    required this.width,
    required this.height,
  });

  static const _decoration = BoxDecoration(
    color: progressEmptyColor,
    borderRadius: BorderRadius.all(Radius.circular(4)),
  );

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: _decoration,
    child: SizedBox(width: width, height: height),
  );
}
