import 'dart:async';
import 'package:flutter/material.dart';

/// A scaffold that provides iOS-style modal presentation with background scaling effect.
/// Wrap your screen content with this widget and use the showModal method to present modals.
/// 
/// Optimized for iOS with smooth animations and proper gesture handling.
class IosModalScaffold extends StatefulWidget {
  final Widget child;
  /// Static background widget that does NOT scale (e.g., gradient backgrounds)
  final Widget? staticBackground;
  final Color backgroundColor;
  final double backgroundScale;
  final double backgroundBorderRadius;

  const IosModalScaffold({
    super.key,
    required this.child,
    this.staticBackground,
    this.backgroundColor = const Color(0xFF110A1D),
    this.backgroundScale = 0.92,
    this.backgroundBorderRadius = 40,
  });

  @override
  State<IosModalScaffold> createState() => IosModalScaffoldState();

  /// Helper to show modal from anywhere given the scaffold state
  static Future<T?> show<T>({
    required GlobalKey<IosModalScaffoldState> scaffoldKey,
    required Widget Function(BuildContext context, VoidCallback dismiss) builder,
    bool isDismissible = true,
    Color barrierColor = Colors.transparent,
  }) {
    final state = scaffoldKey.currentState;
    if (state == null) {
      throw FlutterError('IosModalScaffold not found. Make sure to use the correct GlobalKey.');
    }
    return state.showModal<T>(
      builder: builder,
      isDismissible: isDismissible,
      barrierColor: barrierColor,
    );
  }
}

class IosModalScaffoldState extends State<IosModalScaffold> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _radiusAnimation;
  late Animation<double> _translateAnimation;
  
  bool _isModalVisible = false;
  Widget? _modalContent;
  Completer<dynamic>? _modalCompleter;
  bool _isDismissible = true;
  Color _barrierColor = Colors.transparent;
  // True while the modal is still animating in. Barrier taps are ignored
  // during this window so a rapid second tap (double-press) cannot
  // immediately dismiss a sheet that is still opening.
  bool _isOpening = false;
  // Guards against re-entrant dismiss calls (e.g. double-tap on barrier).
  bool _isDismissing = false;
  
  // Drag state
  double _dragOffset = 0;
  double _modalHeight = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.backgroundScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _radiusAnimation = Tween<double>(
      begin: 0.0,
      end: widget.backgroundBorderRadius,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _translateAnimation = Tween<double>(
      begin: 0.0,
      end: 24.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Shows a modal with iOS-style background scaling effect
  Future<T?> showModal<T>({
    required Widget Function(BuildContext context, VoidCallback dismiss) builder,
    bool isDismissible = true,
    Color barrierColor = Colors.transparent,
  }) async {
    final completer = Completer<T?>();
    _modalCompleter = completer;
    _isDismissible = isDismissible;
    _barrierColor = barrierColor;
    _dragOffset = 0;
    
    setState(() {
      _isModalVisible = true;
      _isOpening = true;
      _isDismissing = false;
      _modalContent = builder(context, () => dismissModal<T>(null));
    });
    
    await _controller.forward();
    if (mounted) {
      setState(() => _isOpening = false);
    } else {
      _isOpening = false;
    }
    
    return completer.future;
  }

  /// Dismisses the current modal with an optional result
  Future<void> dismissModal<T>([T? result]) async {
    if (_isDismissing || !_isModalVisible) return;
    _isDismissing = true;
    await _controller.reverse();
    
    if (mounted) {
      setState(() {
        _isModalVisible = false;
        _modalContent = null;
        _dragOffset = 0;
        _isOpening = false;
      });
    } else {
      _isModalVisible = false;
      _modalContent = null;
      _dragOffset = 0;
      _isOpening = false;
    }
    
    if (_modalCompleter != null && !_modalCompleter!.isCompleted) {
      _modalCompleter!.complete(result);
    }
    _modalCompleter = null;
    _isDismissing = false;
  }

  void _handleBarrierTap() {
    // Ignore taps while the sheet is still animating in. This prevents a
    // rapid second tap on the trigger button (double-press) from being
    // interpreted as a barrier tap that dismisses the just-opened sheet.
    if (_isOpening || _isDismissing) return;
    if (_isDismissible) {
      dismissModal();
    }
  }
  
  void _onDragStart(DragStartDetails details) {
    _modalHeight = MediaQuery.of(context).size.height * 0.7;
  }
  
  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDismissible) return;
    
    setState(() {
      _dragOffset = (_dragOffset + details.primaryDelta!).clamp(0.0, double.infinity);
      final dragProgress = (_dragOffset / _modalHeight).clamp(0.0, 1.0);
      _controller.value = 1.0 - (dragProgress * 0.5);
    });
  }
  
  void _onDragEnd(DragEndDetails details) {
    if (!_isDismissible) return;
    
    final velocity = details.primaryVelocity ?? 0;
    final shouldDismiss = velocity > 500 || _dragOffset > _modalHeight * 0.3;
    
    if (shouldDismiss) {
      dismissModal();
    } else {
      setState(() {
        _dragOffset = 0;
      });
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.backgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Static background (does not scale)
          if (widget.staticBackground != null)
            Positioned.fill(child: widget.staticBackground!),
          // Scaled content
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _translateAnimation.value),
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    alignment: Alignment.topCenter,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(_radiusAnimation.value),
                      child: child,
                    ),
                  ),
                );
              },
              child: widget.child,
            ),
          ),
          
          // Modal overlay
          if (_isModalVisible) ...[
            // Barrier
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return GestureDetector(
                  onTap: _handleBarrierTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    color: _barrierColor.withValues(alpha: _controller.value * 0.3),
                  ),
                );
              },
            ),
            // Modal content sliding up with drag support
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final slideValue = 1.0 - Curves.easeOutCubic.transform(_controller.value);
                    return Transform.translate(
                      offset: Offset(0, slideValue * 300 + _dragOffset),
                      child: child,
                    );
                  },
                  child: GestureDetector(
                    onVerticalDragStart: _isDismissible ? _onDragStart : null,
                    onVerticalDragUpdate: _isDismissible ? _onDragUpdate : null,
                    onVerticalDragEnd: _isDismissible ? _onDragEnd : null,
                    child: _modalContent!,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
