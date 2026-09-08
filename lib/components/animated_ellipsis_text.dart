import 'dart:async';
import 'package:flutter/material.dart';

/// AnimatedEllipsisText cycles trailing dots to convey a loading state.
/// Example: baseText "Analyzing" -> "Analyzing.", "Analyzing..", "Analyzing..."
/// 
/// Optimized for iOS with RepaintBoundary and efficient timer management.
class AnimatedEllipsisText extends StatefulWidget {
  /// The base text to display before the animated dots.
  final String baseText;

  /// TextStyle applied to the entire text.
  final TextStyle? style;

  /// Max number of dots to cycle through (default: 3).
  final int maxDots;

  /// Interval between dot updates (default: 400ms).
  final Duration interval;

  /// Text alignment inside the Text widget.
  final TextAlign textAlign;

  /// Whether the animation is active. When false, no dots are shown.
  final bool isAnimating;

  const AnimatedEllipsisText({
    super.key,
    required this.baseText,
    this.style,
    this.maxDots = 3,
    this.interval = const Duration(milliseconds: 400),
    this.textAlign = TextAlign.start,
    this.isAnimating = true,
  });

  @override
  State<AnimatedEllipsisText> createState() => _AnimatedEllipsisTextState();
}

class _AnimatedEllipsisTextState extends State<AnimatedEllipsisText> {
  Timer? _timer;
  int _dots = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.isAnimating) {
      _timer = Timer.periodic(widget.interval, (_) {
        if (!mounted) return;
        setState(() => _dots = (_dots + 1) % (widget.maxDots + 1));
      });
    }
  }

  @override
  void didUpdateWidget(AnimatedEllipsisText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isAnimating != widget.isAnimating) {
      if (!widget.isAnimating) {
        _timer?.cancel();
        _timer = null;
        setState(() => _dots = 0);
      } else {
        _startTimer();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = widget.style ?? DefaultTextStyle.of(context).style;

    return RepaintBoundary(
      child: RichText(
        textAlign: widget.textAlign,
        text: TextSpan(
          style: effectiveStyle,
          children: [
            TextSpan(text: widget.baseText, style: effectiveStyle),
            for (int i = 1; i <= widget.maxDots; i++)
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: AnimatedOpacity(
                  opacity: i <= _dots ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: Text('.', style: effectiveStyle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
