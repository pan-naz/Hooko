import 'package:flutter/material.dart';
import 'package:hooko_v20/utils/responsive_size.dart';

/// Data model for chart columns
class ChartColumnData {
  final String day;
  final double heightRatio;

  const ChartColumnData(this.day, this.heightRatio);
}

/// Animated bar chart widget used in onboarding screens.
/// Optimized with RepaintBoundary for smooth iOS animations.
class WeeklyChart extends StatelessWidget {
  final List<ChartColumnData> data;
  final List<double>? fromHeights;
  final bool animate;

  const WeeklyChart({
    super.key,
    required this.data,
    this.fromHeights,
    this.animate = true,
  });

  /// Default chart data for onboarding screen 1
  static const List<ChartColumnData> screen1Data = [
    ChartColumnData('Mon', 0.68),
    ChartColumnData('Tue', 0.48),
    ChartColumnData('Wed', 0.38),
    ChartColumnData('Thu', 0.28),
    ChartColumnData('Fri', 0.12),
  ];

  /// Default chart data for onboarding screen 2
  static const List<ChartColumnData> screen2Data = [
    ChartColumnData('Mon', 0.85),
    ChartColumnData('Tue', 0.36),
    ChartColumnData('Wed', 0.605),
    ChartColumnData('Thu', 0.35),
    ChartColumnData('Fri', 0.22),
  ];

  /// Default chart data for onboarding screen 3 (ascending)
  static const List<ChartColumnData> screen3Data = [
    ChartColumnData('Mon', 0.12),
    ChartColumnData('Tue', 0.28),
    ChartColumnData('Wed', 0.48),
    ChartColumnData('Thu', 0.62),
    ChartColumnData('Fri', 0.88),
  ];

  /// Default from heights for screen 1
  static const List<double> screen1FromHeights = [0.0, 0.0, 0.0, 0.0, 0.0];

  /// Default from heights for screen 2 (from screen 1)
  static const List<double> screen2FromHeights = [0.68, 0.48, 0.38, 0.28, 0.12];

  /// Default from heights for screen 3 (from screen 2)
  static const List<double> screen3FromHeights = [0.85, 0.36, 0.605, 0.35, 0.22];

  static const _scaleLabels = ['100K', '25K', '300', '100', '0'];
  static const _labelColor = Color.fromRGBO(254, 254, 254, 0.16);

  @override
  Widget build(BuildContext context) {
    final chartHeight = ResponsiveSize.height(context, 0.28).clamp(180.0, 260.0);
    final labelFontSize = ResponsiveSize.text(context, 12);
    final defaultFromHeights = fromHeights ?? List.filled(data.length, 0.0);

    return RepaintBoundary(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: SizedBox(
              height: chartHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 0; i < data.length; i++) ...[
                    if (i > 0) SizedBox(width: ResponsiveSize.spacing(context, 8)),
                    Expanded(
                      child: ChartBar(
                        label: data[i].day,
                        heightRatio: data[i].heightRatio,
                        maxHeight: chartHeight,
                        index: i,
                        animate: animate,
                        fromHeightRatio: defaultFromHeights[i],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(width: ResponsiveSize.spacing(context, 12)),
          Padding(
            padding: EdgeInsets.only(bottom: ResponsiveSize.spacing(context, 26)),
            child: SizedBox(
              height: chartHeight,
              child: IntrinsicWidth(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final label in _scaleLabels)
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: labelFontSize,
                          height: 1,
                          fontFamily: 'Geom',
                          color: _labelColor,
                        ),
                        textAlign: TextAlign.right,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated chart bar with gradient background.
/// Optimized with RepaintBoundary for smooth iOS animations.
class ChartBar extends StatefulWidget {
  final String label;
  final double heightRatio;
  final double maxHeight;
  final int index;
  final bool animate;
  final double? fromHeightRatio;

  const ChartBar({
    super.key,
    required this.label,
    required this.heightRatio,
    this.maxHeight = 280.0,
    this.index = 0,
    this.animate = false,
    this.fromHeightRatio,
  });

  @override
  State<ChartBar> createState() => _ChartBarState();
}

class _ChartBarState extends State<ChartBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isDisposed = false;

  // Cached gradient - shared across all bars
  static const _barGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color.fromRGBO(197, 89, 20, 0.4),
      Color.fromRGBO(230, 44, 176, 0.08),
    ],
  );
  static const _labelColor = Color.fromRGBO(254, 254, 254, 0.16);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    if (widget.animate) {
      Future.delayed(Duration(milliseconds: 100 + (widget.index * 80)), () {
        if (mounted && !_isDisposed) _controller.forward();
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ChartBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && widget.fromHeightRatio != oldWidget.fromHeightRatio) {
      _controller.reset();
      Future.delayed(Duration(milliseconds: 100 + (widget.index * 80)), () {
        if (mounted && !_isDisposed) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fromHeight = widget.maxHeight * (widget.fromHeightRatio ?? 0.0);
    final toHeight = widget.maxHeight * widget.heightRatio;
    final borderRadius = ResponsiveSize.spacing(context, 28);
    final labelFontSize = ResponsiveSize.text(context, 12);
    final cachedBorderRadius = BorderRadius.circular(borderRadius);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final animatedHeight = fromHeight + (toHeight - fromHeight) * _animation.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: cachedBorderRadius,
                  gradient: _barGradient,
                ),
                child: SizedBox(
                  height: animatedHeight,
                  width: double.infinity,
                ),
              ),
              SizedBox(height: ResponsiveSize.spacing(context, 12)),
              child!,
            ],
          );
        },
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: labelFontSize,
            fontFamily: 'Geom',
            color: _labelColor,
          ),
        ),
      ),
    );
  }
}
