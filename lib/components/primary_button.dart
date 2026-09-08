import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:hooko_v20/utils/app_constants.dart';
import 'package:hooko_v20/theme.dart';

IconData _getButtonFallbackIcon(String iconPath) {
if (iconPath.contains('upload')) return Icons.cloud_upload;
if (iconPath.contains('analize') || iconPath.contains('analyze')) return Icons.analytics;
return Icons.arrow_forward;
}

/// Primary gradient button with optional icon.
/// Optimized for iOS with smooth scale animation.
class PrimaryButton extends StatefulWidget {
final String label;
final String? iconPath;
final VoidCallback? onTap;

const PrimaryButton({
super.key,
required this.label,
this.iconPath,
this.onTap,
});

@override
State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
with SingleTickerProviderStateMixin {
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
final buttonTextStyle = Theme.of(context).extension<ButtonTextStyles>()?.primary;

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
child: AnimatedOpacity(
opacity: _isEnabled ? 1.0 : 0.6,
duration: AppDurations.veryFast, // 100ms
child: Container(
height: ResponsiveSize.buttonHeight(context, AppButtonSizes.extraLarge), // 60
decoration: BoxDecoration(
gradient: const LinearGradient(
colors: [Color(0xFFED6A17), Color(0xFFFF2EC9)],
begin: Alignment.centerLeft,
end: Alignment.centerRight,
),
borderRadius: BorderRadius.circular(ResponsiveSize.radius(context, 30)),
),
child: Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
if (widget.iconPath != null) ...[
SvgPicture.asset(
widget.iconPath!,
width: AppIconSizes.standard, // 24
height: AppIconSizes.standard,
colorFilter: const ColorFilter.mode(offWhite, BlendMode.srcIn),
placeholderBuilder: (context) => Icon(
_getButtonFallbackIcon(widget.iconPath!),
size: AppIconSizes.standard,
color: offWhite,
),
),
SizedBox(width: ResponsiveSize.spacing(context, 10)),
],
Text(
widget.label,
style: buttonTextStyle,
),
],
),
),
),
),
),
);
}
}
