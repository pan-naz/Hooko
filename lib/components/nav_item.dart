import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:hooko_v20/utils/app_constants.dart';
import 'package:hooko_v20/theme.dart';

IconData _getFallbackIcon(String iconPath) {
  if (iconPath.contains('analysis')) return Icons.bar_chart;
  if (iconPath.contains('history')) return Icons.history;
  if (iconPath.contains('profile')) return Icons.person;
  return Icons.circle;
}

/// A reusable animated navigation item with icon and optional label.
/// Optimized for iOS with efficient animations using AnimationController.
class NavItem extends StatefulWidget {
  final String iconPath;
  final String? label;
  final bool isSelected;
  final VoidCallback onTap;

  const NavItem({
    super.key,
    required this.iconPath,
    this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<NavItem> with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final AnimationController _selectionController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _widthFactorAnimation;
  late final Animation<double> _labelOpacityAnimation;

  @override
  void initState() {
    super.initState();
    
    // Scale animation for press effect
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150), // Slightly longer than veryFast for nav feedback
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.10).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    
    // Selection animation for selected state
    _selectionController = AnimationController(
      vsync: this,
      duration: AppDurations.normal, // 300ms
      value: widget.isSelected ? 1.0 : 0.0,
    );
    
    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _selectionController, curve: Curves.easeInOutCubic),
    );
    
    _widthFactorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _selectionController, curve: Curves.easeInOutCubic),
    );
    
    _labelOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _selectionController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void didUpdateWidget(NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected != widget.isSelected) {
      if (widget.isSelected) {
        _selectionController.forward();
      } else {
        _selectionController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _selectionController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() => _scaleController.reverse();

  @override
  Widget build(BuildContext context) {
    final iconSize = ResponsiveSize.spacing(context, 32);
    final horizontalPadding = ResponsiveSize.spacing(context, 24);
    final verticalPadding = ResponsiveSize.spacing(context, 16);
    final labelSpacing = ResponsiveSize.spacing(context, 8);
    final fontSize = ResponsiveSize.text(context, 14);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: RepaintBoundary(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedBuilder(
            animation: _selectionController,
            builder: (context, child) {
              final bgOpacity = widget.isSelected ? 0.12 : 0.0;
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(254, 254, 254, bgOpacity),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: child,
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _opacityAnimation,
                  child: SvgPicture.asset(
                    widget.iconPath,
                    width: iconSize,
                    height: iconSize,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFFEFEFE),
                      BlendMode.srcIn,
                    ),
                    placeholderBuilder: (context) => Icon(
                      _getFallbackIcon(widget.iconPath),
                      size: iconSize,
                      color: const Color(0xFFFEFEFE),
                    ),
                  ),
                ),
                if (widget.label != null)
                  ClipRect(
                    child: AnimatedBuilder(
                      animation: _widthFactorAnimation,
                      builder: (context, child) => Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: _widthFactorAnimation.value,
                        child: child,
                      ),
                      child: FadeTransition(
                        opacity: _labelOpacityAnimation,
                        child: Padding(
                          padding: EdgeInsets.only(left: labelSpacing),
                          child: Text(
                            widget.label!,
                            style: TextStyle(
                              fontFamily: 'Geom',
                              fontSize: fontSize,
                              fontWeight: FontWeight.w500,
                              color: offWhite,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
