import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:hooko_v20/utils/app_constants.dart';
import 'package:hooko_v20/theme.dart';

/// A reusable secondary button with semi-transparent background.
/// Optimized for iOS with smooth scale animation.
class SecondaryButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final double height;
  /// Optional leading SVG asset path to render an icon before the text.
  final String? leadingIconAsset;
  /// Optional explicit icon size. Defaults to 24 logical pixels.
  final double? leadingIconSize;

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.height = AppButtonSizes.extraLarge, // 60
    this.leadingIconAsset,
    this.leadingIconSize,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

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

  void _handleTapDown(TapDownDetails details) => _scaleController.forward();

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() => _scaleController.reverse();

  @override
  Widget build(BuildContext context) {
    final btnStyles = Theme.of(context).extension<ButtonTextStyles>()!;
    final textStyle = btnStyles.secondary;
    final Color iconColor = textStyle.color ?? ink;
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: SizedBox(
            height: ResponsiveSize.buttonHeight(context, widget.height),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: offWhite.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(ResponsiveSize.radius(context, widget.height / 2)),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.leadingIconAsset != null) ...[
                      SvgPicture.asset(
                        widget.leadingIconAsset!,
                        width: widget.leadingIconSize ?? AppIconSizes.standard, // 24
                        height: widget.leadingIconSize ?? AppIconSizes.standard,
                        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                      ),
                      SizedBox(width: ResponsiveSize.spacing(context, AppSpacing.sm)), // 8
                    ],
                    Text(
                      widget.text,
                      style: textStyle,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
