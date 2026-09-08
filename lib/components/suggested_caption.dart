import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooko_v20/theme.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:hooko_v20/components/small_icon_button.dart';
import 'package:hooko_v20/components/pro_tips.dart' show ContentHeightChangedNotification;

/// Collapsible Suggested Caption container with gradient border.
///
/// Displays a caption text with a copy button.
class SuggestedCaption extends StatefulWidget {
  final String title;
  final String caption;
  final VoidCallback? onCopy;
  final bool initiallyExpanded;

  const SuggestedCaption({
    super.key,
    this.title = 'Suggested Caption',
    required this.caption,
    this.onCopy,
    this.initiallyExpanded = false,
  });

  @override
  State<SuggestedCaption> createState() => _SuggestedCaptionState();
}

class _SuggestedCaptionState extends State<SuggestedCaption> {
  bool _showCopiedNotification = false;
  late bool _isExpanded;
  late bool _contentExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _contentExpanded = widget.initiallyExpanded;
  }

  void _handleTap() {
    setState(() {
      if (_isExpanded) {
        // Collapsing: first collapse content, then update header
        _contentExpanded = false;
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) {
            setState(() {
              _isExpanded = false;
            });
            // Notify parent that height changed after animation
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) {
                ContentHeightChangedNotification().dispatch(context);
              }
            });
          }
        });
      } else {
        // Expanding: first update header, then expand content
        _isExpanded = true;
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) {
            setState(() {
              _contentExpanded = true;
            });
            // Notify parent that height changed after animation
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) {
                ContentHeightChangedNotification().dispatch(context);
              }
            });
          }
        });
      }
    });
  }

  void _handleCopy() {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: widget.caption));
    
    setState(() {
      _showCopiedNotification = true;
    });
    
    // Hide notification after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showCopiedNotification = false;
        });
      }
    });
    
    if (widget.onCopy != null) {
      widget.onCopy!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header (tappable)
        GestureDetector(
          onTap: _handleTap,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: ResponsiveSize.spacing(context, 72),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveSize.spacing(context, 20),
              vertical: ResponsiveSize.spacing(context, 16),
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [audioAccent, visualAccent],
              ),
              borderRadius: _isExpanded
                  ? BorderRadius.only(
                      topLeft: Radius.circular(ResponsiveSize.radius(context, 32)),
                      topRight: Radius.circular(ResponsiveSize.radius(context, 32)),
                    )
                  : BorderRadius.circular(ResponsiveSize.radius(context, 32)),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/pen.svg',
                  width: ResponsiveSize.icon(context, 24),
                  height: ResponsiveSize.icon(context, 24),
                  colorFilter: const ColorFilter.mode(offWhite, BlendMode.srcIn),
                ),
                SizedBox(width: ResponsiveSize.spacing(context, 8)),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontFamily: 'Geom',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveSize.text(context, 16),
                      color: offWhite,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _contentExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: SvgPicture.asset(
                    'assets/icons/chevron-down.svg',
                    width: ResponsiveSize.icon(context, 24),
                    height: ResponsiveSize.icon(context, 24),
                    colorFilter: const ColorFilter.mode(offWhite, BlendMode.srcIn),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Expanded content - dark card with slide down animation
        ClipRect(
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            heightFactor: _contentExpanded ? 1.0 : 0.0,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(ResponsiveSize.spacing(context, 20)),
              decoration: BoxDecoration(
                color: ink,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(ResponsiveSize.radius(context, 32)),
                  bottomRight: Radius.circular(ResponsiveSize.radius(context, 32)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.caption,
                    style: TextStyle(
                      fontFamily: 'Geom',
                      fontWeight: FontWeight.w300,
                      fontSize: ResponsiveSize.text(context, 20),
                      color: const Color(0xFFFEFEFE),
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: ResponsiveSize.spacing(context, 16)),
                  Row(
                    children: [
                      // Caption copied notification
                      AnimatedOpacity(
                        opacity: _showCopiedNotification ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: ResponsiveSize.icon(context, 16),
                              color: const Color(0xFFFEFEFE).withValues(alpha: 0.7),
                            ),
                            SizedBox(width: ResponsiveSize.spacing(context, 6)),
                            Text(
                              'Caption copied',
                              style: TextStyle(
                                fontFamily: 'Geom',
                                fontWeight: FontWeight.w300,
                                fontSize: ResponsiveSize.text(context, 12),
                                color: const Color(0xFFFEFEFE).withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      SmallIconButton(
                        onPressed: _handleCopy,
                        iconPath: 'assets/icons/copy.svg',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
