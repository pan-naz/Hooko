import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:hooko_v20/utils/app_constants.dart';
import 'package:hooko_v20/theme.dart';

/// A compact standalone secondary-style button with fixed height of 50.
///
/// Typography: Geom, SemiBold, 16. Text color: #110A1D at 100%.
/// Background: offWhite at 70% opacity, pill shape, subtle press scale.
/// Optimized for iOS with smooth scale animation using AnimationController.
class SmallSecondaryButton extends StatefulWidget {
final String text;
final VoidCallback onPressed;
/// Optional leading SVG asset path to render an icon before the text.
final String? leadingIconAsset;
/// Optional explicit icon size. Defaults to [AppIconSizes.standard] (24).
final double? leadingIconSize;
/// When true, preserves the original SVG colors instead of applying a tint.
final bool preserveLeadingIconColor;
  /// When true (default), shows the trailing plus icon used in some flows.
  /// Set to false when the button already has a distinct leading icon (e.g. YouTube)
  /// and you don't want a duplicated icon treatment.
  final bool showTrailingPlus;

const SmallSecondaryButton({
super.key,
required this.text,
required this.onPressed,
this.leadingIconAsset,
this.leadingIconSize,
this.preserveLeadingIconColor = false,
  this.showTrailingPlus = true,
});

@override
State<SmallSecondaryButton> createState() => _SmallSecondaryButtonState();
}

class _SmallSecondaryButtonState extends State<SmallSecondaryButton>
with SingleTickerProviderStateMixin {
late final AnimationController _scaleController;
late final Animation<double> _scaleAnimation;

static const double _baseHeight = 50;

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
final textStyle = btnStyles.smallSecondary;
final Color iconColor = textStyle.color ?? ink;
final iconSize = widget.leadingIconSize ?? AppIconSizes.standard; // 24

return GestureDetector(
behavior: HitTestBehavior.opaque,
onTapDown: _handleTapDown,
onTapUp: _handleTapUp,
onTapCancel: _handleTapCancel,
child: RepaintBoundary(
child: ScaleTransition(
scale: _scaleAnimation,
child: SizedBox(
height: ResponsiveSize.buttonHeight(context, _baseHeight),
child: DecoratedBox(
decoration: BoxDecoration(
color: offWhite.withValues(alpha: 0.7),
borderRadius: BorderRadius.circular(ResponsiveSize.radius(context, _baseHeight / 2)),
),
child: Center(
child: Row(
mainAxisSize: MainAxisSize.min,
mainAxisAlignment: MainAxisAlignment.center,
children: [
if (widget.leadingIconAsset != null) ...[
SvgPicture.asset(
widget.leadingIconAsset!,
width: iconSize,
height: iconSize,
colorFilter: widget.preserveLeadingIconColor ? null : ColorFilter.mode(iconColor, BlendMode.srcIn),
),
SizedBox(width: ResponsiveSize.spacing(context, AppSpacing.sm)), // 8
],
Text(
widget.text,
style: textStyle,
softWrap: false,
overflow: TextOverflow.ellipsis,
),
  if (widget.showTrailingPlus) ...[
  SizedBox(width: ResponsiveSize.spacing(context, AppSpacing.xs)), // 4
  SvgPicture.asset(
  'assets/icons/plus.svg',
  width: AppIconSizes.standard, // 24
  height: AppIconSizes.standard,
  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
  ),
  ],
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
