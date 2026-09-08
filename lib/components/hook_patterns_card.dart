import 'package:flutter/material.dart';
import 'package:hooko_v20/theme.dart';
import 'package:hooko_v20/utils/responsive_size.dart';

/// Card displaying hook pattern statistics based on niche analysis.
class HookPatternsCard extends StatelessWidget {
  final String niche;
  final String viewsPercentage;
  final String viewsThreshold;
  final String basedOnCount;

  const HookPatternsCard({
    super.key,
    this.niche = 'Fitness & Health',
    this.viewsPercentage = '87%',
    this.viewsThreshold = '500K+',
    this.basedOnCount = '1.5K',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with sparkle emoji
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✨',
              style: TextStyle(
                fontSize: ResponsiveSize.text(context, 20),
              ),
            ),
            SizedBox(width: ResponsiveSize.spacing(context, 8)),
            Expanded(
              child: Text(
                'Hooks based on proven $niche patterns',
                style: TextStyle(
                  fontFamily: 'Geom',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveSize.text(context, 18),
                  color: offWhite,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveSize.spacing(context, 16)),
        // Bullet points
        _BulletPoint(
          text: '$viewsPercentage of videos using this hook type get $viewsThreshold views',
        ),
        SizedBox(height: ResponsiveSize.spacing(context, 12)),
        _BulletPoint(
          text: 'Based on $basedOnCount ${niche.split(' ').first} videos',
        ),
      ],
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: ResponsiveSize.spacing(context, 6)),
          width: ResponsiveSize.spacing(context, 6),
          height: ResponsiveSize.spacing(context, 6),
          decoration: BoxDecoration(
            color: offWhite.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: ResponsiveSize.spacing(context, 12)),
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
    );
  }
}
