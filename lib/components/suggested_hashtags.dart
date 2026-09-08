import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooko_v20/theme.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:hooko_v20/components/small_icon_button.dart';
import 'package:hooko_v20/components/pro_tips.dart' show ContentHeightChangedNotification;

/// Collapsible Suggested Hashtags container with gradient border.
///
/// Displays hashtags as individual selectable chips with a copy button.
class SuggestedHashtags extends StatefulWidget {
  final String title;
  final List<String> hashtags;
  final VoidCallback? onCopy;
  final bool initiallyExpanded;

  const SuggestedHashtags({
    super.key,
    this.title = 'Suggested Hashtags',
    required this.hashtags,
    this.onCopy,
    this.initiallyExpanded = false,
  });

  @override
  State<SuggestedHashtags> createState() => _SuggestedHashtagsState();
}

class _SuggestedHashtagsState extends State<SuggestedHashtags> {
  bool _showCopiedNotification = false;
  int _copiedCount = 0;
  final Set<String> _selectedHashtags = {};
  late bool _isExpanded;
  late bool _contentExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _contentExpanded = widget.initiallyExpanded;
  }

  String get _selectedHashtagsText => _selectedHashtags.map((tag) => tag.startsWith('#') ? tag : '#$tag').join(' ');

  int get _selectedCount => _selectedHashtags.length;

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

  void _toggleHashtag(String tag) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedHashtags.contains(tag)) {
        _selectedHashtags.remove(tag);
      } else {
        _selectedHashtags.add(tag);
      }
    });
  }

  void _clearSelection() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedHashtags.clear();
    });
  }

  void _handleCopy() {
    HapticFeedback.lightImpact();
    // Copy selected hashtags if any, otherwise copy all
    final bool copyAll = _selectedCount == 0;
    final textToCopy = copyAll 
        ? widget.hashtags.map((tag) => tag.startsWith('#') ? tag : '#$tag').join(' ') 
        : _selectedHashtagsText;
    _copiedCount = copyAll ? widget.hashtags.length : _selectedCount;
    Clipboard.setData(ClipboardData(text: textToCopy));
    
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
                  'assets/icons/hashtag.svg',
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
                  // Hashtag chips in wrap layout
                  Wrap(
                    spacing: ResponsiveSize.spacing(context, 8),
                    runSpacing: ResponsiveSize.spacing(context, 10),
                    children: widget.hashtags.map((tag) => _HashtagChip(
                      tag: tag,
                      isSelected: _selectedHashtags.contains(tag),
                      onTap: () => _toggleHashtag(tag),
                    )).toList(),
                  ),
                  SizedBox(height: ResponsiveSize.spacing(context, 20)),
                  Row(
                    children: [
                      // Selection count or copied notification
                      if (_showCopiedNotification)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: ResponsiveSize.icon(context, 16),
                              color: const Color(0xFFFEFEFE).withValues(alpha: 0.7),
                            ),
                            SizedBox(width: ResponsiveSize.spacing(context, 6)),
                            Text(
                              '$_copiedCount hashtag${_copiedCount == 1 ? '' : 's'} copied',
                              style: TextStyle(
                                fontFamily: 'Geom',
                                fontWeight: FontWeight.w300,
                                fontSize: ResponsiveSize.text(context, 12),
                                color: const Color(0xFFFEFEFE).withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        )
                      else if (_selectedCount > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/hashtag.svg',
                              width: ResponsiveSize.icon(context, 16),
                              height: ResponsiveSize.icon(context, 16),
                              colorFilter: ColorFilter.mode(
                                const Color(0xFFFEFEFE).withValues(alpha: 0.7),
                                BlendMode.srcIn,
                              ),
                            ),
                            SizedBox(width: ResponsiveSize.spacing(context, 6)),
                            Text(
                              '$_selectedCount selected',
                              style: TextStyle(
                                fontFamily: 'Geom',
                                fontWeight: FontWeight.w300,
                                fontSize: ResponsiveSize.text(context, 12),
                                color: const Color(0xFFFEFEFE).withValues(alpha: 0.7),
                              ),
                            ),
                            SizedBox(width: ResponsiveSize.spacing(context, 8)),
                            GestureDetector(
                              onTap: _clearSelection,
                              child: Text(
                                'Clear',
                                style: TextStyle(
                                  fontFamily: 'Geom',
                                  fontWeight: FontWeight.w300,
                                  fontSize: ResponsiveSize.text(context, 12),
                                  color: const Color(0xFFFEFEFE).withValues(alpha: 0.7),
                                  decoration: TextDecoration.underline,
                                  decorationColor: const Color(0xFFFEFEFE).withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
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

/// Individual selectable hashtag chip widget
class _HashtagChip extends StatelessWidget {
  final String tag;
  final bool isSelected;
  final VoidCallback onTap;

  const _HashtagChip({
    required this.tag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveSize.spacing(context, 14),
          vertical: ResponsiveSize.spacing(context, 8),
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [audioAccent, visualAccent],
                )
              : null,
          color: isSelected ? null : const Color(0xFFFEFEFE).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(ResponsiveSize.radius(context, 20)),
        ),
        child: Text(
          tag.startsWith('#') ? tag : '#$tag',
          style: TextStyle(
            fontFamily: 'Geom',
            fontWeight: FontWeight.w300,
            fontSize: ResponsiveSize.text(context, 16),
            color: const Color(0xFFFEFEFE),
          ),
        ),
      ),
    );
  }
}
