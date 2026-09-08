import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Manages device orientation based on form factor.
/// 
/// - **Tablets** (shortestSide >= 600): Allow all orientations for rotation
/// - **Phones**: Lock to portrait only
/// 
/// This widget should wrap the entire app to ensure orientation is set
/// before any screens are built.
class OrientationManager extends StatefulWidget {
  final Widget child;

  const OrientationManager({super.key, required this.child});

  @override
  State<OrientationManager> createState() => _OrientationManagerState();
}

class _OrientationManagerState extends State<OrientationManager> with WidgetsBindingObserver {
  bool? _isTablet;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateOrientationIfNeeded();
  }

  @override
  void didChangeMetrics() {
    // Screen metrics changed (could happen on foldables or external displays)
    _updateOrientationIfNeeded();
  }

  void _updateOrientationIfNeeded() {
    // Use MediaQuery for reliable detection across platforms
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final shortestSide = size.shortestSide;
    
    // iPad mini smallest is ~768, most iPads are 1024+
    // Using 600 as threshold (same as MaterialApp tablet breakpoint)
    final isTablet = shortestSide >= 600;

    // Only update if tablet status changed (or first time)
    if (_isTablet != isTablet) {
      debugPrint('OrientationManager: Screen size ${size.width.toInt()}x${size.height.toInt()}, '
          'shortestSide=${shortestSide.toInt()}, isTablet=$isTablet');
      _isTablet = isTablet;
      _setOrientations(isTablet);
    }
  }

  void _setOrientations(bool isTablet) {
    if (isTablet) {
      // Tablets: allow all orientations for rotation
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      debugPrint('OrientationManager: Tablet detected - rotation enabled');
    } else {
      // Phones: portrait only
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      debugPrint('OrientationManager: Phone detected - portrait only');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
