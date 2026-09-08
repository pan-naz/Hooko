import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooko_v20/components/small_icon_button.dart';
import 'package:hooko_v20/theme.dart';
import 'package:hooko_v20/utils/responsive_size.dart';

/// Model for a script section (Say this / Show this after hook)
class ScriptSection {
  final String title;
  final String? timing;
  final String content;
  final String? iconAsset;
  final Color iconColor;
  final bool showCopyButton;

  const ScriptSection({
    required this.title,
    this.timing,
    required this.content,
    this.iconAsset,
    required this.iconColor,
    this.showCopyButton = false,
  });
}

/// Model for a call-to-action tip
class CtaTip {
  final String sayThisTitle;
  final String sayThisContent;
  final String showThisTitle;
  final String showThisContent;

  const CtaTip({
    required this.sayThisTitle,
    required this.sayThisContent,
    required this.showThisTitle,
    required this.showThisContent,
  });
}

/// Non-collapsible "Updated script" section with gradient header.
///
/// Displays rewritten script content for the rest of the video,
/// with Say this / Show this sections and optional CTA tips.
class UpdatedScript extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<ScriptSection> sections;
  final CtaTip? ctaTip;

  const UpdatedScript({
    super.key,
    this.title = 'Updated script',
    this.subtitle = 'Rewritten script for the rest of your video, continuing from the hook above.',
    required this.sections,
    this.ctaTip,
  });

  @override
  State<UpdatedScript> createState() => _UpdatedScriptState();
}

class _UpdatedScriptState extends State<UpdatedScript> {
  int? _copiedIndex;

  void _copyScript(int index, String content) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: content));
    setState(() => _copiedIndex = index);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedIndex = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ResponsiveSize.radius(context, 32)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(ResponsiveSize.radius(context, 32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _UpdatedScriptHeader(title: widget.title),
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(ResponsiveSize.spacing(context, 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.subtitle,
            style: TextStyle(
              fontFamily: 'Geom',
              fontWeight: FontWeight.w300,
              fontSize: ResponsiveSize.text(context, 12),
              color: updatedScriptSubtitleColor,
              height: 1.4,
            ),
          ),
          SizedBox(height: ResponsiveSize.spacing(context, 20)),
          ...widget.sections.asMap().entries.map((entry) {
            final isLast = entry.key == widget.sections.length - 1;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ScriptSectionWidget(
                  section: entry.value,
                  onCopy: entry.value.showCopyButton ? () => _copyScript(entry.key, entry.value.content) : null,
                  copied: _copiedIndex == entry.key,
                ),
                if (!isLast) ...[
                  SizedBox(height: ResponsiveSize.spacing(context, 16)),
                  Divider(color: updatedScriptHeaderBg, height: 1),
                  SizedBox(height: ResponsiveSize.spacing(context, 16)),
                ],
              ],
            );
          }),
          if (widget.ctaTip != null) ...[
            SizedBox(height: ResponsiveSize.spacing(context, 20)),
            _CtaTipSection(ctaTip: widget.ctaTip!),
          ],
        ],
      ),
    );
  }
}

/// Header widget with script icon (no expand/collapse)
class _UpdatedScriptHeader extends StatelessWidget {
  final String title;

  const _UpdatedScriptHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: ResponsiveSize.spacing(context, 72),
      padding: EdgeInsets.symmetric(horizontal: ResponsiveSize.spacing(context, 20)),
      decoration: BoxDecoration(
        color: updatedScriptHeaderBg,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(ResponsiveSize.radius(context, 32)),
          bottomRight: Radius.circular(ResponsiveSize.radius(context, 32)),
        ),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/script.svg',
            width: ResponsiveSize.icon(context, 24),
            height: ResponsiveSize.icon(context, 24),
            colorFilter: const ColorFilter.mode(offWhite, BlendMode.srcIn),
          ),
          SizedBox(width: ResponsiveSize.spacing(context, 8)),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Geom',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveSize.text(context, 16),
                color: offWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper to count words in a string
int _countWords(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  return trimmed.split(RegExp(r'\s+')).length;
}

/// Helper to get first N words from a string
String _getFirstNWords(String text, int n) {
  final words = text.trim().split(RegExp(r'\s+'));
  if (words.length <= n) return text;
  return '${words.take(n).join(' ')}...';
}

/// Widget for a single script section
class _ScriptSectionWidget extends StatefulWidget {
  final ScriptSection section;
  final VoidCallback? onCopy;
  final bool copied;

  const _ScriptSectionWidget({
    required this.section,
    this.onCopy,
    this.copied = false,
  });

  @override
  State<_ScriptSectionWidget> createState() => _ScriptSectionWidgetState();
}

class _ScriptSectionWidgetState extends State<_ScriptSectionWidget> {
  bool _isExpanded = false;
  static const int _maxWordsCollapsed = 100;

  @override
  Widget build(BuildContext context) {
    final wordCount = _countWords(widget.section.content);
    final needsTruncation = wordCount > _maxWordsCollapsed;
    final displayContent = _isExpanded || !needsTruncation
        ? widget.section.content
        : _getFirstNWords(widget.section.content, _maxWordsCollapsed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.section.iconAsset != null) ...[
              SvgPicture.asset(
                widget.section.iconAsset!,
                width: ResponsiveSize.icon(context, 20),
                height: ResponsiveSize.icon(context, 20),
                colorFilter: ColorFilter.mode(widget.section.iconColor, BlendMode.srcIn),
              ),
              SizedBox(width: ResponsiveSize.spacing(context, 8)),
            ],
            Expanded(
              child: Text(
                widget.section.title,
                style: TextStyle(
                  fontFamily: 'Geom',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveSize.text(context, 14),
                  color: widget.section.iconColor,
                ),
              ),
            ),
            if (widget.section.timing != null && widget.section.timing!.isNotEmpty)
              Text(
                widget.section.timing!,
                style: TextStyle(
                  fontFamily: 'Geom',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveSize.text(context, 14),
                  color: widget.section.iconColor,
                ),
              ),
          ],
        ),
        SizedBox(height: ResponsiveSize.spacing(context, 12)),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topLeft,
          child: Text(
            displayContent,
            style: TextStyle(
              fontFamily: 'Geom',
              fontWeight: FontWeight.w300,
              fontStyle: widget.section.showCopyButton ? FontStyle.italic : FontStyle.normal,
              fontSize: ResponsiveSize.text(context, 16),
              color: offWhite,
              height: 1.5,
            ),
          ),
        ),
        if (needsTruncation) ...[
          SizedBox(height: ResponsiveSize.spacing(context, 8)),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _isExpanded = !_isExpanded);
            },
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => accentGradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
              child: Text(
                _isExpanded ? 'Show less' : 'Show more',
                style: TextStyle(
                  fontFamily: 'Geom',
                  fontWeight: FontWeight.w500,
                  fontSize: ResponsiveSize.text(context, 14),
                  color: offWhite,
                ),
              ),
            ),
          ),
        ],
        if (widget.section.showCopyButton) ...[
          SizedBox(height: ResponsiveSize.spacing(context, 16)),
          Row(
            children: [
              if (widget.copied) ...[
                SvgPicture.asset(
                  'assets/icons/checked.svg',
                  width: ResponsiveSize.icon(context, 16),
                  height: ResponsiveSize.icon(context, 16),
                  colorFilter: ColorFilter.mode(offWhite.withValues(alpha: 0.5), BlendMode.srcIn),
                ),
                SizedBox(width: ResponsiveSize.spacing(context, 6)),
                Text(
                  'Script copied',
                  style: TextStyle(
                    fontFamily: 'Geom',
                    fontWeight: FontWeight.w300,
                    fontSize: ResponsiveSize.text(context, 12),
                    color: offWhite.withValues(alpha: 0.5),
                  ),
                ),
              ],
              const Spacer(),
              SmallIconButton(
                onPressed: widget.onCopy!,
                iconPath: 'assets/icons/copy.svg',
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Call-to-action tip section
class _CtaTipSection extends StatelessWidget {
  final CtaTip ctaTip;

  const _CtaTipSection({required this.ctaTip});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveSize.spacing(context, 16)),
      decoration: BoxDecoration(
        color: updatedScriptCtaTipBg,
        borderRadius: BorderRadius.circular(ResponsiveSize.radius(context, 20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggested Call To Action',
            style: TextStyle(
              fontFamily: 'Geom',
              fontWeight: FontWeight.w300,
              fontSize: ResponsiveSize.text(context, 12),
              color: const Color(0xFFFEFEFE).withValues(alpha: 0.3),
              height: 1.4,
            ),
          ),
          SizedBox(height: ResponsiveSize.spacing(context, 16)),
          Divider(color: updatedScriptCtaTipBg, height: 1),
          SizedBox(height: ResponsiveSize.spacing(context, 16)),
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/mic.svg',
                width: ResponsiveSize.icon(context, 20),
                height: ResponsiveSize.icon(context, 20),
                colorFilter: const ColorFilter.mode(audioAccent, BlendMode.srcIn),
              ),
              SizedBox(width: ResponsiveSize.spacing(context, 8)),
              Expanded(
                child: Text(
                  ctaTip.sayThisTitle,
                  style: TextStyle(
                    fontFamily: 'Geom',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveSize.text(context, 14),
                    color: offWhite,
                  ),
                ),
              ),
              Text(
                'last 3–5 sec',
                style: TextStyle(
                  fontFamily: 'Geom',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveSize.text(context, 14),
                  color: offWhite,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSize.spacing(context, 8)),
          Text(
            ctaTip.sayThisContent,
            style: TextStyle(
              fontFamily: 'Geom',
              fontWeight: FontWeight.w300,
              fontStyle: FontStyle.italic,
              fontSize: ResponsiveSize.text(context, 14),
              color: offWhite.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
          SizedBox(height: ResponsiveSize.spacing(context, 16)),
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/camera.svg',
                width: ResponsiveSize.icon(context, 20),
                height: ResponsiveSize.icon(context, 20),
                colorFilter: const ColorFilter.mode(visualAccent, BlendMode.srcIn),
              ),
              SizedBox(width: ResponsiveSize.spacing(context, 8)),
              Expanded(
                child: Text(
                  ctaTip.showThisTitle,
                  style: TextStyle(
                    fontFamily: 'Geom',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveSize.text(context, 14),
                    color: offWhite,
                  ),
                ),
              ),
              Text(
                'last 3–5 sec',
                style: TextStyle(
                  fontFamily: 'Geom',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveSize.text(context, 14),
                  color: offWhite,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSize.spacing(context, 8)),
          Text(
            ctaTip.showThisContent,
            style: TextStyle(
              fontFamily: 'Geom',
              fontWeight: FontWeight.w300,
              fontSize: ResponsiveSize.text(context, 14),
              color: offWhite.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
