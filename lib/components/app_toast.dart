import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooko_v20/theme.dart';

/// Visual tone of the toast.
enum AppToastVariant { success, info, error }

/// A branded, minimal toast overlay that matches Hooko's design system.
///
/// - Slides up from the bottom with a subtle fade
/// - Auto-dismisses after [duration]
/// - Tap to dismiss immediately
/// - Renders above modal routes (works on top of the paywall)
class AppToast {
  AppToast._();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  /// Show a toast anchored to the root overlay.
  static void show(
    BuildContext context, {
    required String message,
    AppToastVariant variant = AppToastVariant.info,
    Duration duration = const Duration(milliseconds: 2600),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);

    // Dismiss any existing toast first so we never stack.
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    final key = GlobalKey<_AppToastViewState>();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _AppToastView(
        key: key,
        message: message,
        variant: variant,
        onDismiss: () {
          if (_currentEntry == entry) {
            _dismissTimer?.cancel();
            entry.remove();
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, () {
      if (_currentEntry == entry) {
        key.currentState?.animateOut();
      }
    });
  }
}

class _AppToastView extends StatefulWidget {
  final String message;
  final AppToastVariant variant;
  final VoidCallback onDismiss;

  const _AppToastView({
    super.key,
    required this.message,
    required this.variant,
    required this.onDismiss,
  });

  @override
  State<_AppToastView> createState() => _AppToastViewState();
}

class _AppToastViewState extends State<_AppToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> animateOut() => _dismiss();

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    if (!mounted) return;
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.padding.bottom;

    final config = _configFor(widget.variant);

    return Positioned(
      left: 20,
      right: 20,
      bottom: bottomInset + 24,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _dismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: ink,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: offWhite.withValues(alpha: 0.12),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: config.iconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          config.iconPath,
                          width: 16,
                          height: 16,
                          colorFilter: ColorFilter.mode(
                            config.iconColor,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          fontFamily: 'Geom',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: offWhite,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ToastVisual _configFor(AppToastVariant v) {
    switch (v) {
      case AppToastVariant.success:
        return _ToastVisual(
          iconPath: 'assets/icons/checked.svg',
          iconColor: ink,
          iconBg: offWhite,
        );
      case AppToastVariant.info:
        return _ToastVisual(
          iconPath: 'assets/icons/checked.svg',
          iconColor: offWhite,
          iconBg: offWhite.withValues(alpha: 0.18),
        );
      case AppToastVariant.error:
        return const _ToastVisual(
          iconPath: 'assets/icons/warning.svg',
          iconColor: offWhite,
          iconBg: audioAccent,
        );
    }
  }
}

class _ToastVisual {
  final String iconPath;
  final Color iconColor;
  final Color iconBg;
  const _ToastVisual({
    required this.iconPath,
    required this.iconColor,
    required this.iconBg,
  });
}
