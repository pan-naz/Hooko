import 'package:flutter/material.dart';
import 'package:hooko_v20/theme.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:hooko_v20/components/segmented_progress_bar.dart';

/// A reusable card for displaying an audio-related score with a segmented
/// progress bar and descriptive content.
class AudioScoreCard extends StatelessWidget {
  /// Card title, e.g., "Your Audio".
  final String title;

  /// Score from 0 to 100 (supports double for animation).
  final double score;

  /// A short quote or preview line related to the audio content.
  final String quote;

  /// A concise subtitle/description beneath the quote.
  final String subtitle;

  const AudioScoreCard({
    super.key,
    required this.title,
    required this.score,
    required this.quote,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveSize.spacing(context, 16);
    
    return RepaintBoundary(
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Geom',
                fontWeight: FontWeight.w300,
                fontSize: ResponsiveSize.text(context, 16),
                color: audioAccent,
              ),
            ),
            SizedBox(height: ResponsiveSize.spacing(context, 8)),
            // Score and segmented bar row
            Row(
              children: [
                Text(
                  '${score.round()}',
                  style: TextStyle(
                    fontFamily: 'Geom',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveSize.text(context, 16),
                    color: audioAccent,
                  ),
                ),
                SizedBox(width: ResponsiveSize.spacing(context, 8)),
                Expanded(
                  child: SegmentedProgressBar(
                    score: score,
                    color: audioAccent,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveSize.spacing(context, 12)),
            // Audio content - quote (truncated to 50 chars)
            Text(
              quote.length > 50 ? '${quote.substring(0, 50)}...' : quote,
              style: TextStyle(
                fontFamily: 'Geom',
                fontWeight: FontWeight.w300,
                fontSize: ResponsiveSize.text(context, 20),
                color: offWhite,
                height: 1.35,
              ),
            ),
            SizedBox(height: ResponsiveSize.spacing(context, 12)),
            // Rationale - full text
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Geom',
                fontWeight: FontWeight.w300,
                fontSize: ResponsiveSize.text(context, 12),
                color: offWhite.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
