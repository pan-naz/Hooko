import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooko_v20/theme.dart';
import 'package:hooko_v20/utils/responsive_size.dart';

/// Reusable card UI for displaying a suggested visual/action hook.
///
/// Matches the "Show this:" container styling used in the Demo Result screen.
class ShowThis extends StatelessWidget {
  final String title;
  final String quote;
  final List<String> tags;
  final String rationaleTitle;
  final String rationaleBody;
  final Color accentColor;
  final String iconAsset;

  const ShowThis({
    super.key,
    this.title = 'Show this:',
    required this.quote,
    required this.tags,
    this.rationaleTitle = 'Why this will work?',
    required this.rationaleBody,
    this.accentColor = visualAccent,
    this.iconAsset = 'assets/icons/camera.svg',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveSize.spacing(context, 20)),
      decoration: BoxDecoration(
        color: ink,
        borderRadius: BorderRadius.circular(ResponsiveSize.radius(context, 32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                iconAsset,
                width: ResponsiveSize.icon(context, 24),
                height: ResponsiveSize.icon(context, 24),
                colorFilter: ColorFilter.mode(accentColor, BlendMode.srcIn),
              ),
              SizedBox(width: ResponsiveSize.spacing(context, 8)),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Geom',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveSize.text(context, 16),
                  color: accentColor,
                ),
              ),
              const Spacer(),
              Text(
                'first 3 sec',
                style: TextStyle(
                  fontFamily: 'Geom',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveSize.text(context, 16),
                  color: accentColor,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSize.spacing(context, 16)),
          Text(
            quote,
            style: TextStyle(
              fontFamily: 'Geom',
              fontWeight: FontWeight.w300,
              fontSize: ResponsiveSize.text(context, 20),
              color: offWhite,
              height: 1.4,
            ),
          ),
          SizedBox(height: ResponsiveSize.spacing(context, 16)),
          Wrap(
            spacing: ResponsiveSize.spacing(context, 8),
            runSpacing: ResponsiveSize.spacing(context, 8),
            children: tags.map((t) => _ShowThisTag(label: t, accentColor: accentColor)).toList(growable: false),
          ),
          SizedBox(height: ResponsiveSize.spacing(context, 16)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(ResponsiveSize.spacing(context, 16)),
            decoration: BoxDecoration(
              color: visualAccent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(ResponsiveSize.radius(context, 20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rationaleTitle,
                  style: TextStyle(
                    fontFamily: 'Geom',
                    fontWeight: FontWeight.w300,
                    fontSize: ResponsiveSize.text(context, 12),
                    color: offWhite.withValues(alpha: 0.3),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: ResponsiveSize.spacing(context, 4)),
                Text(
                  rationaleBody,
                  style: TextStyle(
                    fontFamily: 'Geom',
                    fontWeight: FontWeight.w300,
                    fontSize: ResponsiveSize.text(context, 12),
                    color: offWhite,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowThisTag extends StatelessWidget {
  final String label;
  final Color accentColor;

  const _ShowThisTag({required this.label, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSize.spacing(context, 12),
        vertical: ResponsiveSize.spacing(context, 6),
      ),
      decoration: BoxDecoration(
        border: Border.all(color: accentColor.withValues(alpha: 0.6), width: 1.5),
        borderRadius: BorderRadius.circular(ResponsiveSize.radius(context, 20)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Geom',
          fontWeight: FontWeight.w300,
          fontSize: ResponsiveSize.text(context, 12),
          color: accentColor,
        ),
      ),
    );
  }
}
