import 'package:flutter/material.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:hooko_v20/utils/app_constants.dart';
import 'package:hooko_v20/theme.dart';

/// A compact dark-themed button aligned with SmallSecondaryButton sizing/shape.
///
/// - Height: 50
/// - Shape: pill (radius = height/2)
/// - Text: Geom, SemiBold, 16dp (uses smallSecondary sizing) with offWhite color
/// Optimized for iOS with smooth scale animation using AnimationController.
class SmallDarkButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;

  const SmallDarkButton({super.key, required this.label, this.onTap});

  @override
  State<SmallDarkButton> createState() => _SmallDarkButtonState();
}

class _SmallDarkButtonState extends State<SmallDarkButton>
    with SingleTickerProviderStateMixin {
  static const double _height = AppButtonSizes.medium; // 50 -> 48 (medium)
  static const _decoration = BoxDecoration(
    color: ink,
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)), // pill shape
  );

  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  bool get _isEnabled => widget.onTap != null;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: AppDurations.veryFast, // 100ms
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (_isEnabled) _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isEnabled) {
      _scaleController.reverse();
      widget.onTap?.call();
    }
  }

  void _handleTapCancel() {
    if (_isEnabled) _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: RepaintBoundary(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedOpacity(
            opacity: _isEnabled ? 1.0 : 0.6,
            duration: AppDurations.veryFast, // 100ms
            child: SizedBox(
              height: ResponsiveSize.spacing(context, _height).clamp(_height * 0.8, _height),
              width: double.infinity,
              child: const DecoratedBox(
                decoration: _decoration,
                child: Center(
                  child: _ButtonText(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonText extends StatelessWidget {
  const _ButtonText();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_SmallDarkButtonState>()!;
    final btnStyles = Theme.of(context).extension<ButtonTextStyles>()!;
    final textStyle = btnStyles.smallSecondary.copyWith(color: offWhite);

    return Text(
      state.widget.label,
      style: textStyle,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
    );
  }
}
