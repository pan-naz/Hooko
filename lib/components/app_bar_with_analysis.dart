import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:hooko_v20/utils/app_constants.dart';
import 'package:hooko_v20/theme.dart';

/// A reusable app bar with logo and analysis badge.
/// Optimized for iOS with RepaintBoundary.
class AppBarWithAnalysis extends StatelessWidget {
  /// Current used count (numerator)
  final int usedCount;

  /// Total available count (denominator)
  final int totalCount;

  /// When false, a small spinner is shown in place of [usedCount] until the
  /// real value has loaded from the server.
  final bool usageLoaded;

  /// When true, indicates the last attempt to fetch usage failed (e.g. no
  /// internet). Displays an offline indicator instead of a count.
  final bool usageFailed;

  /// Badge label displayed on the right (e.g., Demo). Ignored if [badgeAsset] is set.
  final String badgeLabel;

  /// Optional SVG asset path used as badge content (e.g. plus10, plus20).
  /// When provided, this takes precedence over [badgeLabel].
  final String? badgeAsset;

  /// Optional leading widget on the far left (e.g., a decorative box or back button)
  final Widget? leading;

  /// Optional trailing widget on the far right (e.g., an IconButton)
  final Widget? trailing;

  /// When true, shows only [leading] on the left and [trailing] on the right,
  /// hiding the logo, analysis text, counters and badge.
  final bool minimal;

  /// Optional title shown in the center area when [minimal] is true.
  final String? title;

  /// Optional subtitle shown under [title] when [minimal] is true.
  final String? subtitle;

  /// Optional title shown on the right side instead of analysis count (for history page).
  final String? rightTitle;

  const AppBarWithAnalysis({
    super.key,
    this.usedCount = 0,
    this.totalCount = 10,
    this.usageLoaded = true,
    this.usageFailed = false,
    this.badgeLabel = 'Pro',
    this.badgeAsset,
    this.leading,
    this.trailing,
    this.minimal = false,
    this.title,
    this.subtitle,
    this.rightTitle,
  });

  @override
  Widget build(BuildContext context) {
    if (minimal) {
      return _MinimalAppBar(
        leading: leading,
        trailing: trailing,
        title: title,
        subtitle: subtitle,
      );
    }

    return _FullAppBar(
      usedCount: usedCount,
      totalCount: totalCount,
      usageLoaded: usageLoaded,
      usageFailed: usageFailed,
      badgeLabel: badgeLabel,
      badgeAsset: badgeAsset,
      trailing: trailing,
      rightTitle: rightTitle,
    );
  }
}

class _MinimalAppBar extends StatelessWidget {
  final Widget? leading;
  final Widget? trailing;
  final String? title;
  final String? subtitle;

  const _MinimalAppBar({
    this.leading,
    this.trailing,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    // Base sizes provided by design; scaled via ResponsiveSize for all devices.
    final leadingToTextGap = ResponsiveSize.spacing(
      context, 
      shortestSide >= AppBreakpoints.tablet ? AppSpacing.lg : AppSpacing.md, // 16 : 12
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) leading! else const SizedBox.shrink(),
        if (title != null || subtitle != null) ...[
          SizedBox(width: leadingToTextGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Geom',
                      fontSize: ResponsiveSize.text(context, 16),
                      fontWeight: FontWeight.w600,
                      color: offWhite,
                      height: 1.2,
                    ),
                  ),
                if (subtitle != null) ...[
                  SizedBox(height: ResponsiveSize.spacing(context, AppSpacing.xs)), // 4
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Geom',
                      fontSize: ResponsiveSize.text(context, 14),
                      fontWeight: FontWeight.w300,
                      color: offWhite.withValues(alpha: 0.3),
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ] else ...[
          const Spacer(),
        ],
        if (trailing != null) ...[
          SizedBox(width: ResponsiveSize.spacing(context, AppSpacing.md)), // 12
          trailing!,
        ],
      ],
    );
  }
}

class _FullAppBar extends StatelessWidget {
  final int usedCount;
  final int totalCount;
  final bool usageLoaded;
  final bool usageFailed;
  final String badgeLabel;
  final String? badgeAsset;
  final Widget? trailing;
  final String? rightTitle;

  const _FullAppBar({
    required this.usedCount,
    required this.totalCount,
    required this.usageLoaded,
    required this.usageFailed,
    required this.badgeLabel,
    this.badgeAsset,
    this.trailing,
    this.rightTitle,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = ResponsiveSize.spacing(context, 40);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SvgPicture.asset(
          'assets/icons/icon_logo.svg',
          width: logoSize,
          height: logoSize,
        ),
        if (rightTitle != null)
          Text(
            rightTitle!,
            style: TextStyle(
              fontFamily: 'Geom',
              fontSize: ResponsiveSize.text(context, 18),
              fontWeight: FontWeight.w600,
              color: offWhite,
            ),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _UsageStatus(
                usedCount: usedCount,
                totalCount: totalCount,
                usageLoaded: usageLoaded,
                usageFailed: usageFailed,
              ),
              SizedBox(width: ResponsiveSize.spacing(context, AppSpacing.md)), // 12
              _AnalysisBadge(label: badgeLabel, asset: badgeAsset),
              if (trailing != null) ...[
                SizedBox(width: ResponsiveSize.spacing(context, AppSpacing.md)), // 12
                trailing!,
              ],
            ],
          ),
      ],
    );
  }
}

class _UsageStatus extends StatelessWidget {
  final int usedCount;
  final int totalCount;
  final bool usageLoaded;
  final bool usageFailed;

  const _UsageStatus({
    required this.usedCount,
    required this.totalCount,
    required this.usageLoaded,
    required this.usageFailed,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontFamily: 'Geom',
      fontSize: ResponsiveSize.text(context, 12),
      color: offWhite.withValues(alpha: 0.3),
    );

    // Offline state: no successful load AND failed
    if (usageFailed && !usageLoaded) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('No internet connection', style: labelStyle),
          SizedBox(width: ResponsiveSize.spacing(context, AppSpacing.sm)), // 8
          Icon(
            Icons.wifi_off,
            size: ResponsiveSize.spacing(context, 16),
            color: offWhite.withValues(alpha: 0.5),
          ),
        ],
      );
    }

    // Loading state
    if (!usageLoaded) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Fetching analyses', style: labelStyle),
          SizedBox(width: ResponsiveSize.spacing(context, AppSpacing.sm)), // 8
          SizedBox(
            width: ResponsiveSize.spacing(context, 11),
            height: ResponsiveSize.spacing(context, 11),
            child: CircularProgressIndicator(
              strokeWidth: 1.2,
              valueColor: AlwaysStoppedAnimation<Color>(
                offWhite.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      );
    }

    // Loaded state
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Daily analyses:', style: labelStyle),
        SizedBox(width: ResponsiveSize.spacing(context, AppSpacing.sm)), // 8
        Text(
          '$usedCount',
          style: TextStyle(
            fontFamily: 'Geom',
            fontSize: ResponsiveSize.text(context, 20),
            fontWeight: FontWeight.w300,
            color: offWhite,
          ),
        ),
        Text('/$totalCount', style: labelStyle),
      ],
    );
  }
}

class _AnalysisBadge extends StatelessWidget {
  final String label;
  final String? asset;

  const _AnalysisBadge({required this.label, this.asset});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ResponsiveSize.spacing(context, 70),
      height: ResponsiveSize.spacing(context, 30),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSize.spacing(context, AppSpacing.sm),
      ),
      decoration: BoxDecoration(
        color: offWhite,
        borderRadius: BorderRadius.circular(ResponsiveSize.radius(context, AppRadius.medium)),
      ),
      child: asset != null
          ? SvgPicture.asset(
              asset!,
              height: ResponsiveSize.spacing(context, 18),
              fit: BoxFit.contain,
            )
          : Text(
              label,
              style: TextStyle(
                fontFamily: 'Geom',
                fontSize: ResponsiveSize.text(context, 12),
                fontWeight: FontWeight.w800,
                color: const Color(0xFF110A1D),
              ),
            ),
    );
  }
}
