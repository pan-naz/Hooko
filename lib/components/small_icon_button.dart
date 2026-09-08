import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooko_v20/theme.dart';
import 'package:hooko_v20/utils/responsive_size.dart';

IconData _getSmallIconButtonFallback(String iconPath) {
  if (iconPath.contains('close')) return Icons.close;
  if (iconPath.contains('arrow_left')) return Icons.arrow_back;
  if (iconPath.contains('sound_on')) return Icons.volume_up;
  if (iconPath.contains('sound_off')) return Icons.volume_off;
  return Icons.circle;
}

/// A smaller rounded square button with customizable icon (50dp size).
/// Optimized for iOS with smooth scale animation using AnimationController.
class SmallIconButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String iconPath;

  const SmallIconButton({
    super.key,
    required this.onPressed,
    required this.iconPath,
  });

  @override
  State<SmallIconButton> createState() => _SmallIconButtonState();
}

class _SmallIconButtonState extends State<SmallIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  static const _iconColor = Color(0xFF110A1D);
  static const double _baseSize = 50;
  static const double _bgAlpha = 0.7;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
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
    final size = ResponsiveSize.buttonHeight(context, _baseSize);
    final iconSize = ResponsiveSize.icon(context, 20);
    final borderRadius = ResponsiveSize.radius(context, _baseSize / 2);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: RepaintBoundary(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SizedBox(
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                // Keep surfaces slightly off-white (FEFEFE) to avoid pure white (FFFFFF).
                color: offWhite.withValues(alpha: _bgAlpha),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Center(
                child: SvgPicture.asset(
                  widget.iconPath,
                  width: iconSize,
                  height: iconSize,
                  colorFilter: const ColorFilter.mode(_iconColor, BlendMode.srcIn),
                  placeholderBuilder: (context) => Icon(
                    _getSmallIconButtonFallback(widget.iconPath),
                    size: iconSize,
                    color: _iconColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
