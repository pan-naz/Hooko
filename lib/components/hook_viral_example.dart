import 'package:flutter/material.dart';
import 'package:hooko_v20/components/say_this.dart';
import 'package:hooko_v20/components/small_secondary_button.dart';
import 'package:hooko_v20/theme.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:url_launcher/url_launcher.dart';

/// Card showing a viral example using the suggested hook pattern.
class HookViralExample extends StatelessWidget {
  final String? thumbnailAsset;
  final String? thumbnailUrl;
  final List<String> tags; // Changed from hookType to tags list
  final String description;
  final String? youtubeUrl;

  const HookViralExample({
    super.key,
    this.thumbnailAsset,
    this.thumbnailUrl,
    required this.tags,
    required this.description,
    this.youtubeUrl,
  });

  Future<void> _openYouTube() async {
    final url = youtubeUrl ?? 'https://www.youtube.com/shorts';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

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
          // Title
          Text(
            '🔥 Real Example Using This Hook',
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
              // Video thumbnail - matching _SharedVideoThumbnail styling
              Builder(
                builder: (context) {
                  final borderRadius = ResponsiveSize.radius(context, 16);
                  final thumbnailHeight = ResponsiveSize.cardHeight(context, 115);
                  final thumbnailWidth = thumbnailHeight * (9 / 16);
                  return SizedBox(
                    width: thumbnailWidth,
                    height: thumbnailHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(borderRadius),
                        border: Border.all(color: offWhite.withValues(alpha: 0.15), width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(borderRadius - 2),
                        child: thumbnailUrl != null
                            ? Image.network(
                                thumbnailUrl!,
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
                              )
                            : Image.asset(
                                thumbnailAsset ?? '',
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
                  );
                },
              ),
              SizedBox(width: ResponsiveSize.spacing(context, 16)),
              // Info column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tags row (multiple tags)
                    Wrap(
                      spacing: ResponsiveSize.spacing(context, 8),
                      runSpacing: ResponsiveSize.spacing(context, 6),
                      children: tags.map((tag) => SayThisTag(
                        label: tag,
                        accentColor: audioAccent,
                      )).toList(),
                    ),
                    SizedBox(height: ResponsiveSize.spacing(context, 12)),
                    // Description
                    Text(
                      description,
                      style: TextStyle(
                        fontFamily: 'Geom',
                        fontWeight: FontWeight.w300,
                        fontSize: ResponsiveSize.text(context, 12),
                        color: offWhite.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSize.spacing(context, 20)),
          // Watch on Shorts button
          SmallSecondaryButton(
            text: 'Watch',
            leadingIconAsset: 'assets/icons/youtube.svg',
            preserveLeadingIconColor: true,
            showTrailingPlus: false,
            onPressed: _openYouTube,
          ),
          SizedBox(height: ResponsiveSize.spacing(context, 12)),
          Text(
            'Video is the property of its original creator and is displayed via YouTube for educational and analysis purposes only.',
            style: TextStyle(
              fontFamily: 'Geometr415 Lt BT',
              fontSize: ResponsiveSize.text(context, 10),
              color: const Color(0xFFFEFEFE).withValues(alpha: 0.3),
              height: 1.4,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }
}
