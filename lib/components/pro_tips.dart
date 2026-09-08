import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooko_v20/theme.dart';
import 'package:hooko_v20/utils/responsive_size.dart';

/// Notification dispatched when expandable content changes height
class ContentHeightChangedNotification extends Notification {}

/// Model for a single tip item
class TipItem {
  final String text;

  const TipItem(this.text);
}

/// Model for a tip section (e.g., Audio Tips, Visual Tips)
class TipSection {
  final String title;
  final String? iconAsset;
  final IconData? iconData;
  final Color iconColor;
  final List<TipItem> tips;

  const TipSection({
    required this.title,
    this.iconAsset,
    this.iconData,
    required this.iconColor,
    required this.tips,
  }) : assert(iconAsset != null || iconData != null, 'Either iconAsset or iconData must be provided');
}

/// Collapsible Pro Tips container with gradient border.
///
/// Displays multiple tip sections (Audio, Visual, Timing, General)
/// with customizable content.
class ProTips extends StatefulWidget {
  final String title;
  final List<TipSection> sections;
  final List<TipItem>? generalTips;
  final bool initiallyExpanded;

  const ProTips({
    super.key,
    this.title = 'Pro tips for this hook',
    required this.sections,
    this.generalTips,
    this.initiallyExpanded = false,
  });

  @override
  State<ProTips> createState() => _ProTipsState();
}

class _ProTipsState extends State<ProTips> {
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
                  'assets/icons/tips.svg',
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
                  ...widget.sections.asMap().entries.map((entry) {
                    final isLast = entry.key == widget.sections.length - 1 && widget.generalTips == null;
                    return Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : ResponsiveSize.spacing(context, 20)),
                      child: _TipSectionWidget(section: entry.value),
                    );
                  }),
                  if (widget.generalTips != null && widget.generalTips!.isNotEmpty) ...[
                    SizedBox(height: ResponsiveSize.spacing(context, 4)),
                    _GeneralTipsSection(tips: widget.generalTips!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget for a single tip section
class _TipSectionWidget extends StatelessWidget {
  final TipSection section;

  const _TipSectionWidget({required this.section});

  @override
  Widget build(BuildContext context) {
    Widget iconWidget;
    if (section.iconAsset != null) {
      iconWidget = SvgPicture.asset(
        section.iconAsset!,
        width: ResponsiveSize.icon(context, 24),
        height: ResponsiveSize.icon(context, 24),
        colorFilter: ColorFilter.mode(section.iconColor, BlendMode.srcIn),
      );
    } else {
      iconWidget = Icon(
        section.iconData,
        size: ResponsiveSize.icon(context, 24),
        color: section.iconColor,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            iconWidget,
            SizedBox(width: ResponsiveSize.spacing(context, 8)),
            Flexible(
              child: Text(
                section.title,
                style: TextStyle(
                  fontFamily: 'Geom',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveSize.text(context, 16),
                  color: offWhite,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveSize.spacing(context, 8)),
        // Tip items
        ...section.tips.map((tip) => _TipItemWidget(text: tip.text)),
      ],
    );
  }
}

/// Widget for a single tip item (bullet point)
class _TipItemWidget extends StatelessWidget {
  final String text;

  const _TipItemWidget({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: ResponsiveSize.spacing(context, 22),
        bottom: ResponsiveSize.spacing(context, 4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontFamily: 'Geom',
              fontWeight: FontWeight.w300,
              fontSize: ResponsiveSize.text(context, 16),
              color: offWhite.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Geom',
                fontWeight: FontWeight.w300,
                fontSize: ResponsiveSize.text(context, 16),
                color: offWhite.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// General tips section with clock icon
class _GeneralTipsSection extends StatelessWidget {
  final List<TipItem> tips;

  const _GeneralTipsSection({required this.tips});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Text(
          'General Tips:',
          style: TextStyle(
            fontFamily: 'Geom',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveSize.text(context, 16),
            color: offWhite,
          ),
        ),
        SizedBox(height: ResponsiveSize.spacing(context, 8)),
        // Tip items
        ...tips.map((tip) => Padding(
          padding: EdgeInsets.only(
            left: ResponsiveSize.spacing(context, 8),
            bottom: ResponsiveSize.spacing(context, 4),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: TextStyle(
                  fontFamily: 'Geom',
                  fontWeight: FontWeight.w300,
                  fontSize: ResponsiveSize.text(context, 16),
                  color: offWhite.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
              Expanded(
                child: Text(
                  tip.text,
                  style: TextStyle(
                    fontFamily: 'Geom',
                    fontWeight: FontWeight.w300,
                    fontSize: ResponsiveSize.text(context, 16),
                    color: offWhite.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
