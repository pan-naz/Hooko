import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooko_v20/theme.dart';
import 'package:hooko_v20/utils/responsive_size.dart';

/// Solid background decoration for modal cards (FEFEFE @ 100%)
BoxDecoration modalCardDecoration() => BoxDecoration(
      color: offWhite,
      borderRadius: BorderRadius.circular(24),
    );

/// Gradient background for small tag/pill elements inside modal
BoxDecoration modalTagDecoration() => BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [modalGradientTop, modalGradientBottom],
      ),
      borderRadius: BorderRadius.circular(20),
    );

/// Score details card showing user score, gap, niche, and average
class ScoreDetailsCard extends StatelessWidget {
  final String scoreValue;
  final String gapValue;
  final String niche;
  final String averageValue;

  const ScoreDetailsCard({
    super.key,
    required this.scoreValue,
    required this.gapValue,
    required this.niche,
    required this.averageValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: modalCardDecoration(),
      child: Column(
        children: [
          DetailRow(label: 'Your Score:', value: scoreValue),
          const SizedBox(height: 12),
          DetailRow(label: 'Gap:', value: gapValue),
          const SizedBox(height: 12),
          DetailRow(label: 'Niche:', value: niche),
          const SizedBox(height: 12),
          DetailRow(label: 'Average in $niche:', value: averageValue),
        ],
      ),
    );
  }
}

/// Row showing label and pill-styled value
class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Geom',
              fontWeight: FontWeight.w300,
              fontSize: ResponsiveSize.text(context, 12),
              color: ink,
            ),
            softWrap: true,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: modalTagDecoration(),
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Geom',
              fontWeight: FontWeight.w300,
              fontSize: ResponsiveSize.text(context, 12),
              color: ink,
            ),
          ),
        ),
      ],
    );
  }
}

/// Industry data card showing engagement stats
class IndustryDataCard extends StatelessWidget {
  final String niche;
  final int benchmarkScore;
  final double? tiktokEngagement;
  final double? instagramEngagement;
  final double? youtubeEngagement;
  final double? avgEngagementFromDb;

  const IndustryDataCard({
    super.key,
    required this.niche,
    required this.benchmarkScore,
    this.tiktokEngagement,
    this.instagramEngagement,
    this.youtubeEngagement,
    this.avgEngagementFromDb,
  });

  @override
  Widget build(BuildContext context) {
    // Use real values from DB or calculate fallback from benchmark
    final tiktok = tiktokEngagement ?? ((benchmarkScore - 50) / 10 + 0.5);
    final instagram = instagramEngagement ?? ((benchmarkScore - 50) / 10 + 0.3);
    final youtube = youtubeEngagement ?? ((benchmarkScore - 50) / 10 - 0.7);
    // Use pre-calculated avg from DB, or calculate as fallback
    final avgEngagement = (avgEngagementFromDb ?? ((tiktok + instagram + youtube) / 3)).toStringAsFixed(1);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: modalCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Industry data for $niche:',
            style: TextStyle(
              fontFamily: 'Geom',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveSize.text(context, 16),
              color: ink,
            ),
          ),
          const SizedBox(height: 16),
          _IndustryBenchmarkRow(label: 'TikTok', value: '${tiktok.toStringAsFixed(1)}% engagement'),
          const SizedBox(height: 8),
          _IndustryBenchmarkRow(label: 'Instagram', value: '${instagram.toStringAsFixed(1)}% engagement'),
          const SizedBox(height: 8),
          _IndustryBenchmarkRow(label: 'YouTube', value: '${youtube.toStringAsFixed(1)}% engagement'),
          const SizedBox(height: 12),
          Text(
            'Average: $avgEngagement%',
            style: TextStyle(
              fontFamily: 'Geom',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveSize.text(context, 16),
              color: ink,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Formula:',
                style: TextStyle(
                  fontFamily: 'Geom',
                  fontWeight: FontWeight.w300,
                  fontSize: ResponsiveSize.text(context, 12),
                  color: ink,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: modalTagDecoration(),
                  child: Text(
                    '($avgEngagement × 10) + 50 = $benchmarkScore/100',
                    style: TextStyle(
                      fontFamily: 'Geom',
                      fontWeight: FontWeight.w300,
                      fontSize: ResponsiveSize.text(context, 12),
                      color: ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IndustryBenchmarkRow extends StatelessWidget {
  final String label;
  final String value;

  const _IndustryBenchmarkRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Geom',
            fontWeight: FontWeight.w300,
            fontSize: ResponsiveSize.text(context, 14),
            color: ink,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: modalTagDecoration(),
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Geom',
              fontWeight: FontWeight.w300,
              fontSize: ResponsiveSize.text(context, 12),
              color: ink,
            ),
          ),
        ),
      ],
    );
  }
}

/// Sources card
class SourcesCard extends StatelessWidget {
  const SourcesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: modalCardDecoration(),
      child: Text(
        'Sources: 2M+ videos analyzed\n(Socialinsider, Hootsuite, Sprout Social)',
        style: TextStyle(
          fontFamily: 'Geom',
          fontWeight: FontWeight.w300,
          fontSize: ResponsiveSize.text(context, 16),
          height: 1.4,
          color: ink,
        ),
      ),
    );
  }
}

/// Bottom sticky tabs for switching hook alternatives
class HookAlternativeTabs extends StatelessWidget {
  final int selectedIndex;
  final int count;
  final ValueChanged<int> onTabSelected;

  const HookAlternativeTabs({
    super.key,
    required this.selectedIndex,
    required this.count,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ResponsiveSize.horizontalPadding(context),
        16,
        ResponsiveSize.horizontalPadding(context),
        safeBottom > 0 ? safeBottom : 16,
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: offWhite,
            borderRadius: BorderRadius.circular(60),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(count.clamp(1, 3), (index) {
              return HookTabItem(
                label: selectedIndex == index
                    ? '${index + 1}# Alternative'
                    : '${index + 1}#',
                isSelected: selectedIndex == index,
                onTap: () => onTabSelected(index),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Individual tab item for hook alternatives with scale animation and haptic feedback
class HookTabItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const HookTabItem({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<HookTabItem> createState() => _HookTabItemState();
}

class _HookTabItemState extends State<HookTabItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.10).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() => _scaleController.reverse();

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 250);
    const curve = Curves.easeOutCubic;
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: duration,
          curve: curve,
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveSize.spacing(context, 20),
            vertical: ResponsiveSize.spacing(context, 16),
          ),
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [audioAccent, visualAccent],
                  )
                : null,
            borderRadius: BorderRadius.circular(50),
          ),
          child: AnimatedSize(
            duration: duration,
            curve: curve,
            child: AnimatedDefaultTextStyle(
              duration: duration,
              curve: curve,
              style: TextStyle(
                fontFamily: 'Geom',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveSize.text(context, 16),
                color: widget.isSelected ? offWhite : ink,
              ),
              child: Text(widget.label),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wrapper widget that allows measuring content height.
///
/// Uses [SizeChangedLayoutNotifier] so any parent can react instantly
/// to size changes (e.g. when an expand/collapse animation grows/shrinks
/// nested content), avoiding the need for delayed one-shot notifications.
class MeasurableContent extends StatelessWidget {
  final Widget child;
  const MeasurableContent({super.key, required this.child});

  @override
  Widget build(BuildContext context) => SizeChangedLayoutNotifier(child: child);
}

/// Optimized transform widget that only rebuilds itself, not the content
class OptimizedPageTransform extends StatelessWidget {
  final int index;
  final ValueNotifier<double> pageNotifier;
  final Widget child;

  const OptimizedPageTransform({
    super.key,
    required this.index,
    required this.pageNotifier,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: pageNotifier,
      builder: (context, page, cachedChild) {
        final diff = index - page;
        final translateX = diff * 24.0;
        final scale = 1.0 - (diff.abs() * 0.02).clamp(0.0, 0.02);

        return Transform.translate(
          offset: Offset(translateX, 0),
          child: Transform.scale(
            scale: scale,
            alignment: diff <= 0 ? Alignment.centerRight : Alignment.centerLeft,
            child: cachedChild,
          ),
        );
      },
      child: RepaintBoundary(child: child),
    );
  }
}
