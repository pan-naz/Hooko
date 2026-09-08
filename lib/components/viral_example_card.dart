import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooko_v20/theme.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:url_launcher/url_launcher.dart';

/// Card showing a viral example video in the user's niche.
class ViralExampleCard extends StatelessWidget {
  final String thumbnailAsset;
  final String username;
  final String viewCount;
  final String category;
  final String? tiktokUrl;

  const ViralExampleCard({
    super.key,
    required this.thumbnailAsset,
    this.username = '@maiahenryfit',
    this.viewCount = '2.3M Views',
    this.category = 'Fitness & Health',
    this.tiktokUrl,
  });

  Future<void> _openTikTok() async {
    final url = tiktokUrl ?? 'https://www.tiktok.com/${username.replaceFirst('@', '')}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'Viral example in your niche',
          style: TextStyle(
            fontFamily: 'Geom',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveSize.text(context, 18),
            color: offWhite,
          ),
        ),
        SizedBox(height: ResponsiveSize.spacing(context, 20)),
        // Content row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(ResponsiveSize.radius(context, 24)),
              child: SizedBox(
                width: ResponsiveSize.spacing(context, 120),
                height: ResponsiveSize.spacing(context, 200),
                child: Image.asset(
                  thumbnailAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: offWhite.withValues(alpha: 0.12),
                    child: Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 40,
                        color: offWhite.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: ResponsiveSize.spacing(context, 16)),
            // Info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username
                  Text(
                    username,
                    style: TextStyle(
                      fontFamily: 'Geom',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveSize.text(context, 16),
                      color: visualAccent,
                    ),
                  ),
                  SizedBox(height: ResponsiveSize.spacing(context, 12)),
                  // Views badge
                  _InfoBadge(text: viewCount),
                  SizedBox(height: ResponsiveSize.spacing(context, 8)),
                  // Category badge
                  _InfoBadge(text: category),
                  SizedBox(height: ResponsiveSize.spacing(context, 16)),
                  // Open on TikTok button
                  GestureDetector(
                    onTap: _openTikTok,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveSize.spacing(context, 20),
                        vertical: ResponsiveSize.spacing(context, 12),
                      ),
                      decoration: BoxDecoration(
                        color: offWhite,
                        borderRadius: BorderRadius.circular(ResponsiveSize.radius(context, 24)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/tiktok.svg',
                            width: ResponsiveSize.icon(context, 20),
                            height: ResponsiveSize.icon(context, 20),
                            colorFilter: ColorFilter.mode(ink, BlendMode.srcIn),
                          ),
                          SizedBox(width: ResponsiveSize.spacing(context, 8)),
                          Text(
                            'Open on TikTok',
                            style: TextStyle(
                              fontFamily: 'Geom',
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveSize.text(context, 14),
                              color: ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String text;

  const _InfoBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSize.spacing(context, 14),
        vertical: ResponsiveSize.spacing(context, 8),
      ),
      decoration: BoxDecoration(
        color: offWhite.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ResponsiveSize.radius(context, 20)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Geom',
          fontWeight: FontWeight.w300,
          fontSize: ResponsiveSize.text(context, 14),
          color: offWhite,
        ),
      ),
    );
  }
}
