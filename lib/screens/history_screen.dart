import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:hooko_v20/components/app_bar_with_analysis.dart';
import 'package:hooko_v20/models/analysis_result.dart';
import 'package:hooko_v20/state/app_state.dart';
import 'package:hooko_v20/services/analysis_service.dart';
import 'package:hooko_v20/nav.dart';
import 'package:hooko_v20/theme.dart';
import 'package:hooko_v20/utils/app_constants.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with AutomaticKeepAliveClientMixin {
  String? _openCardId; // Track which card is currently swiped open

  @override
  bool get wantKeepAlive => true;

  void _onCardSwipeStart(String id) {
    // Close any other open card when a new one starts swiping
    if (_openCardId != null && _openCardId != id) {
      setState(() => _openCardId = id);
    } else if (_openCardId != id) {
      setState(() => _openCardId = id);
    }
  }

  void _onCardOpened(String id) {
    setState(() => _openCardId = id);
  }

  void _onCardClosed(String id) {
    if (_openCardId == id) {
      setState(() => _openCardId = null);
    }
  }

  void _closeAllCards() {
    if (_openCardId != null) {
      setState(() => _openCardId = null);
    }
  }

  void _openAnalysis(AnalysisResult result) {
    // Mark as viewing from history - static mode, no video playback
    AppStateProvider.of(context).setLatestAnalysisResult(result, fromHistory: true);
    context.push(AppRoutes.analysisResult);
  }

  void _removeItem(String id) {
    AppStateProvider.of(context).removeFromHistory(id);
  }

  void _restoreItem(AnalysisResult item) {
    AppStateProvider.of(context).restoreHistoryItem(item);
  }

  void _deletePersisted(String id, AnalysisResult item) {
    // Fire-and-forget persistence so the UI stays snappy.
    AnalysisService.deleteFromHistory(id).catchError((e) {
      debugPrint('HistoryScreen: Failed to persist delete for $id: $e');
      if (!mounted) return;
      _restoreItem(item);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delete failed. Please try again.')),
      );
    });
  }

  /// Group history items by date
  Map<String, List<AnalysisResult>> _groupByDate(List<AnalysisResult> history, String locale) {
    final Map<String, List<AnalysisResult>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    for (final result in history) {
      final resultDate = DateTime(result.createdAt.year, result.createdAt.month, result.createdAt.day);
      // Show "Today"/"Yesterday" if applicable, otherwise use locale-aware format
      final String dateKey;
      if (resultDate == today) {
        dateKey = 'Today';
      } else if (resultDate == yesterday) {
        dateKey = 'Yesterday';
      } else {
        dateKey = DateFormat.yMMMEd(locale).format(result.createdAt);
      }
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(result);
    }
    
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final appState = AppStateProvider.of(context);
    final history = appState.history;
    final historyLoaded = appState.historyLoaded;
    final padding = ResponsiveSize.horizontalPadding(context);
    final showBackground = historyLoaded && history.isEmpty;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background - solid color when has items, image when empty
        // Background
        Container(color: const Color(0xFF110A1D)),
        if (showBackground)
          Center(
            child: Image.asset(
              'assets/images/history.jpg',
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.fitWidth,
            ),
          ),
        // Content - show when has items or still loading
        if (history.isNotEmpty || !historyLoaded)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(padding, 0, padding, 0),
              child: !historyLoaded
                  ? const Center(
                      child: CircularProgressIndicator(color: offWhite),
                    )
                  : _buildGroupedHistoryList(history),
            ),
          ),
        // Top gradient overlay - content fades under header when scrolling
        if (history.isNotEmpty || !historyLoaded)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: MediaQuery.of(context).padding.top + 100,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF110A1D),
                      Color(0xFF110A1D),
                      Color(0xFA110A1D),
                      Color(0xF5110A1D),
                      Color(0xEE110A1D),
                      Color(0xE5110A1D),
                      Color(0xDA110A1D),
                      Color(0xCC110A1D),
                      Color(0xBB110A1D),
                      Color(0xAA110A1D),
                      Color(0x99110A1D),
                      Color(0x88110A1D),
                      Color(0x77110A1D),
                      Color(0x66110A1D),
                      Color(0x55110A1D),
                      Color(0x44110A1D),
                      Color(0x33110A1D),
                      Color(0x22110A1D),
                      Color(0x11110A1D),
                      Color(0x08110A1D),
                      Color(0x00110A1D),
                    ],
                    stops: [
                      0.0,
                      0.35,
                      0.40,
                      0.45,
                      0.50,
                      0.55,
                      0.60,
                      0.65,
                      0.70,
                      0.74,
                      0.78,
                      0.82,
                      0.85,
                      0.88,
                      0.90,
                      0.92,
                      0.94,
                      0.96,
                      0.98,
                      0.99,
                      1.0
                    ],
                  ),
                ),
              ),
            ),
          ),
        // Bottom gradient overlay - content fades into navbar area
        if (history.isNotEmpty || !historyLoaded)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 140,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00110A1D),
                      Color(0x08110A1D),
                      Color(0x11110A1D),
                      Color(0x1A110A1D),
                      Color(0x26110A1D),
                      Color(0x33110A1D),
                      Color(0x44110A1D),
                      Color(0x55110A1D),
                      Color(0x66110A1D),
                      Color(0x77110A1D),
                      Color(0x88110A1D),
                      Color(0x99110A1D),
                      Color(0xAA110A1D),
                      Color(0xBB110A1D),
                      Color(0xCC110A1D),
                      Color(0xDA110A1D),
                      Color(0xE8110A1D),
                      Color(0xF2110A1D),
                      Color(0xFA110A1D),
                      Color(0xFF110A1D),
                    ],
                    stops: [
                      0.0,
                      0.05,
                      0.10,
                      0.15,
                      0.20,
                      0.26,
                      0.32,
                      0.38,
                      0.44,
                      0.50,
                      0.56,
                      0.62,
                      0.68,
                      0.74,
                      0.80,
                      0.86,
                      0.91,
                      0.95,
                      0.98,
                      1.0
                    ],
                  ),
                ),
              ),
            ),
          ),
        // App bar overlay (stays on top of gradient) - always show
        SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
            child: const AppBarWithAnalysis(rightTitle: 'Analysis history'),
          ),
        ),

      ],
    );
  }

  Widget _buildGroupedHistoryList(List<AnalysisResult> history) {
    final locale = Localizations.localeOf(context).toString();
    final groupedHistory = _groupByDate(history, locale);
    final dateKeys = groupedHistory.keys.toList();
    
    return GestureDetector(
      onTap: _closeAllCards,
      behavior: HitTestBehavior.translucent,
      child: ListView.builder(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.only(top: 80, bottom: 24),
        itemCount: dateKeys.length,
        itemBuilder: (context, index) {
        final dateKey = dateKeys[index];
        final items = groupedHistory[dateKey]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                dateKey,
                style: TextStyle(
                  fontFamily: 'Geom',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
            // Items for this date
            ...items.map((result) => Padding(
              key: ValueKey(result.id),
              padding: const EdgeInsets.only(bottom: 16),
              child: HistoryItemCard(
                result: result,
                onTap: () => _openAnalysis(result),
                onDeletedOptimistic: (deleted) {
                  _removeItem(deleted.id);
                  _deletePersisted(deleted.id, deleted);
                },
                onSwipeStart: () => _onCardSwipeStart(result.id),
                onOpened: () => _onCardOpened(result.id),
                onClosed: () => _onCardClosed(result.id),
                shouldClose: _openCardId != null && _openCardId != result.id,
              ),
            )),
          ],
        );
      },
      ),
    );
  }
}

/// Single history item card with iMessage-style swipe-to-delete
class HistoryItemCard extends StatefulWidget {
  final AnalysisResult result;
  final VoidCallback onTap;
  final ValueChanged<AnalysisResult>? onDeletedOptimistic;
  final VoidCallback? onSwipeStart;
  final VoidCallback? onOpened;
  final VoidCallback? onClosed;
  final bool shouldClose;

  const HistoryItemCard({
    super.key,
    required this.result,
    required this.onTap,
    this.onDeletedOptimistic,
    this.onSwipeStart,
    this.onOpened,
    this.onClosed,
    this.shouldClose = false,
  });

  @override
  State<HistoryItemCard> createState() => _HistoryItemCardState();
}

class _HistoryItemCardState extends State<HistoryItemCard>
    with TickerProviderStateMixin {
  Uint8List? _cachedThumbnailBytes;
  Widget? _cachedThumbnailWidget; // Cache the entire widget to prevent rebuilds
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _swipeController;
  late final AnimationController _iconSnapController;
  late final Animation<double> _iconSnapAnimation;
  
  double _dragExtent = 0.0;
  bool _isDeleting = false;
  bool _isDragging = false;
  bool _iconSnapped = false; // Track if icon has snapped to left
  
  // iMessage-style thresholds
  static const double _buttonBaseSize = 60.0;
  static const double _scalePhaseEnd = 0.15; // 0-15% swipe = button scales 0→100%
  static const double _openThreshold = 0.25; // 25% to stay open
  static const double _deleteThreshold = 0.60; // 60% to delete (when icon snaps left)

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: AppDurations.veryFast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _iconSnapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _iconSnapAnimation = CurvedAnimation(
      parent: _iconSnapController,
      curve: Curves.easeOutBack,
    );
    _decodeThumbnailAndBuildWidget();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _swipeController.dispose();
    _iconSnapController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    // Close any other open card when this card is tapped
    widget.onSwipeStart?.call();
    if (_dragExtent == 0) _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
    if (_dragExtent == 0) {
      widget.onTap();
    } else {
      _animateTo(0, notifyClosed: true);
    }
  }

  void _handleTapCancel() => _scaleController.reverse();
  
  @override
  void didUpdateWidget(covariant HistoryItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Close this card if parent requests it
    if (widget.shouldClose && !oldWidget.shouldClose && _dragExtent != 0) {
      _animateTo(0, notifyClosed: true);
    }
  }

  void _onDragStart(DragStartDetails details) {
    _swipeController.stop();
    _iconSnapController.stop();
    _isDragging = true;
    widget.onSwipeStart?.call();
  }
  
  void _onDragUpdate(DragUpdateDetails details) {
    if (_isDeleting) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final prevSwipeRatio = _dragExtent.abs() / screenWidth;
    
    setState(() {
      _dragExtent += details.delta.dx;
      _dragExtent = _dragExtent.clamp(-screenWidth, 0.0);
    });
    
    final newSwipeRatio = _dragExtent.abs() / screenWidth;
    
    // Trigger light haptic and snap animation when crossing 60% threshold
    if (newSwipeRatio >= _deleteThreshold && prevSwipeRatio < _deleteThreshold) {
      HapticFeedback.lightImpact();
      _iconSnapped = true;
      _iconSnapController.forward(from: 0);
    } else if (newSwipeRatio < _deleteThreshold && prevSwipeRatio >= _deleteThreshold) {
      // Reverse snap when going back below 60%
      _iconSnapped = false;
      _iconSnapController.reverse(from: 1);
    }
  }
  
  void _onDragEnd(DragEndDetails details) {
    _isDragging = false;
    if (_isDeleting) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final swipeRatio = _dragExtent.abs() / screenWidth;
    
    if (swipeRatio >= _deleteThreshold) {
      // 60%+ = delete on release
      _performDelete();
    } else if (swipeRatio >= _openThreshold) {
      // 25-60% = stay open showing delete button
      _animateTo(-(_buttonBaseSize + 16), notifyOpened: true);
    } else {
      // <25% = snap back closed
      _animateTo(0, notifyClosed: true);
    }
  }
  
  void _animateTo(double target, {bool notifyOpened = false, bool notifyClosed = false}) {
    final start = _dragExtent;
    final anim = Tween<double>(begin: start, end: target).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeOut),
    );
    void listener() => setState(() => _dragExtent = anim.value);
    anim.addListener(listener);
    // Reset icon snap state when closing
    if (target == 0 && _iconSnapped) {
      _iconSnapped = false;
      _iconSnapController.reverse(from: 1);
    }
    _swipeController.forward(from: 0).then((_) {
      anim.removeListener(listener);
      if (notifyOpened && target != 0) widget.onOpened?.call();
      if (notifyClosed || target == 0) widget.onClosed?.call();
    });
  }
  
  Future<void> _performDelete() async {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);
    
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    // Slide card off screen
    final screenWidth = MediaQuery.of(context).size.width;
    final anim = Tween<double>(begin: _dragExtent, end: -screenWidth - 100).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeIn),
    );
    void listener() => setState(() => _dragExtent = anim.value);
    anim.addListener(listener);
    await _swipeController.forward(from: 0);
    anim.removeListener(listener);

    // Optimistically remove from the list immediately. Persistence is handled
    // by the parent to avoid perceived delays.
    widget.onDeletedOptimistic?.call(widget.result);
  }

  void _decodeThumbnailAndBuildWidget() {
    if (widget.result.thumbnailBase64 != null && widget.result.thumbnailBase64!.isNotEmpty) {
      try {
        _cachedThumbnailBytes = base64Decode(widget.result.thumbnailBase64!);
        // Cache the entire widget to prevent rebuilds causing blinking
        _cachedThumbnailWidget = RepaintBoundary(
          child: Image.memory(
            _cachedThumbnailBytes!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholderThumbnail(),
          ),
        );
      } catch (e) {
        debugPrint('Failed to decode thumbnail: $e');
        _cachedThumbnailWidget = _buildPlaceholderThumbnail();
      }
    } else {
      _cachedThumbnailWidget = _buildPlaceholderThumbnail();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hookPreview = widget.result.hookAlternatives.isNotEmpty
        ? widget.result.hookAlternatives.first.sayThisQuote
        : widget.result.currentHookQuote;

    final screenWidth = MediaQuery.of(context).size.width;
    final swipeRatio = _dragExtent.abs() / screenWidth;
    final showButton = _dragExtent < -5 || _isDeleting;
    
    // Phase 1: Scale (0% → 15% swipe = 0% → 100% scale)
    final scaleProgress = (swipeRatio / _scalePhaseEnd).clamp(0.0, 1.0);
    final buttonScale = Curves.easeOut.transform(scaleProgress);
    
    // Phase 2: Stretch (15% → 80% swipe = button width grows)
    final stretchProgress = ((swipeRatio - _scalePhaseEnd) / (_deleteThreshold - _scalePhaseEnd)).clamp(0.0, 1.0);
    final extraWidth = stretchProgress * (screenWidth * 0.4);
    final buttonWidth = _buttonBaseSize + extraWidth;
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: SizedBox(
        height: 184,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Delete button - scales up then stretches (always rendered to prevent blinking)
            Positioned(
              right: showButton ? _dragExtent.abs() - buttonWidth - (8 * screenWidth / 375) : -100,
              top: 0,
              bottom: 0,
              child: Center(
                child: Opacity(
                  opacity: showButton ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: _isDragging || !showButton,
                    child: GestureDetector(
                      onTap: _performDelete,
                      child: RepaintBoundary(
                        child: Transform.scale(
                          scale: buttonScale,
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: buttonWidth,
                            height: _buttonBaseSize,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6769).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(_buttonBaseSize / 2),
                            ),
                            child: AnimatedBuilder(
                              animation: _iconSnapAnimation,
                              builder: (context, child) {
                                final snapProgress = _iconSnapAnimation.value.clamp(0.0, 1.0);
                                // Scale bounce effect when snapping
                                final scaleValue = 1.0 + (0.2 * snapProgress);
                                return Align(
                                  // Snap fully to left when animation reaches 1.0
                                  alignment: Alignment.lerp(
                                    Alignment.center,
                                    Alignment.centerLeft,
                                    snapProgress,
                                  )!,
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 16.0 * snapProgress),
                                    child: Transform.scale(
                                      scale: scaleValue,
                                      child: child,
                                    ),
                                  ),
                                );
                              },
                              child: _isDeleting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : SvgPicture.asset(
                                      'assets/icons/trash.svg',
                                      width: 18,
                                      height: 18,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Main card
            Transform.translate(
              offset: Offset(_dragExtent, 0),
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
                child: RepaintBoundary(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEFEFE).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: SizedBox(
                            width: 96,
                            height: 160,
                            child: _buildThumbnail(),
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Score',
                                  style: TextStyle(
                                    fontFamily: 'Geom',
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(right: context.rs.s(16)),
                                  child: Text(
                                    _formatTimeAgo(widget.result.createdAt, context),
                                    style: TextStyle(
                                      fontFamily: 'Geom',
                                      fontSize: context.rs.t(13),
                                      color: Colors.white.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${widget.result.overallScore}',
                                  style: const TextStyle(
                                    fontFamily: 'Geom',
                                    fontSize: 42,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ),
                                Text(
                                  '/100',
                                  style: TextStyle(
                                    fontFamily: 'Geom',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              hookPreview.isNotEmpty ? '"$hookPreview"' : 'No hook detected',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Geom',
                                fontSize: 15,
                                height: 1.4,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    // Return cached widget to prevent rebuilds causing blinking
    return _cachedThumbnailWidget ?? _buildPlaceholderThumbnail();
  }

  Widget _buildPlaceholderThumbnail() {
    return Container(
      color: Colors.white.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.play_circle_outline,
          color: Colors.white.withValues(alpha: 0.4),
          size: 36,
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} sec ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else {
      // Show exact time in locale-aware format (e.g., "2:30 PM" for US, "14:30" for EU)
      final locale = Localizations.localeOf(context).toString();
      return DateFormat.jm(locale).format(date);
    }
  }
}
