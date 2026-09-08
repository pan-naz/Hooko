import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooko_v20/theme.dart';
import 'package:hooko_v20/utils/responsive_size.dart';

IconData _getIconButtonFallback(String iconPath) {
  if (iconPath.contains('close')) return Icons.close;
  if (iconPath.contains('arrow_left')) return Icons.arrow_back;
  if (iconPath.contains('sound_on')) return Icons.volume_up;
  if (iconPath.contains('sound_off')) return Icons.volume_off;
  return Icons.circle;
}

/// A rounded square button with customizable icon.
/// Optimized for iOS with smooth scale animation using AnimationController.
class IconButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String iconPath;

  const IconButton({
    super.key,
    required this.onPressed,
    required this.iconPath,
  });

  @override
  State<IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<IconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  static const _iconColor = Color(0xFF110A1D);
  static const double _bgAlpha = 0.7;
  static final _decoration = BoxDecoration(
    color: offWhite.withValues(alpha: _bgAlpha),
    borderRadius: BorderRadius.circular(30),
  );

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
    final size = ResponsiveSize.spacing(context, 60).clamp(48.0, 60.0);
    final iconSize = ResponsiveSize.spacing(context, 24);

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
              decoration: _decoration,
              child: Center(
                child: SvgPicture.asset(
                  widget.iconPath,
                  width: iconSize,
                  height: iconSize,
                  colorFilter: const ColorFilter.mode(_iconColor, BlendMode.srcIn),
                  placeholderBuilder: (context) => Icon(
                    _getIconButtonFallback(widget.iconPath),
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
