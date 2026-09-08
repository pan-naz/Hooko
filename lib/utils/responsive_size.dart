import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hooko_v20/utils/app_constants.dart';

/// Helper class for responsive sizing based on screen dimensions.
/// Reference device: iPhone 16 Pro Max (430 x 932 @3x)
/// 
/// iPhone Screen Sizes (logical pixels):
/// - iPhone SE (3rd): 375 x 667
/// - iPhone 8: 375 x 667
/// - iPhone 8 Plus: 414 x 736
/// - iPhone 12 mini: 375 x 812
/// - iPhone 12/13/14: 390 x 844
/// - iPhone 12/13/14 Pro: 393 x 852
/// - iPhone 14 Plus: 428 x 926
/// - iPhone 14 Pro Max: 430 x 932
/// - iPhone 15/16: 393 x 852
/// - iPhone 15/16 Pro: 393 x 852
/// - iPhone 15/16 Plus: 430 x 932
/// - iPhone 15/16 Pro Max: 430 x 932
class ResponsiveSize {
  // Reference device dimensions (iPhone 16 Pro Max)
  static const double _refWidth = AppBreakpoints.large; // 430.0
  static const double _refHeight = 932.0;

  // iPhone breakpoints - using centralized constants
  static const double _compactWidth = AppBreakpoints.compact; // 375.0 - SE, mini
  static const double _regularWidth = AppBreakpoints.regular; // 390.0 - Standard iPhones
  // Note: Large devices (430.0 - Plus/Max) are handled implicitly in _getDeviceType

  /// Get scale factors for the current context.
  /// Uses MediaQuery.sizeOf for better performance (avoids full MediaQueryData rebuild).
  static _ScaleFactors _getScaleFactors(BuildContext context) {
    // MediaQuery.sizeOf is more efficient than MediaQuery.of(context).size
    // as it only rebuilds when size changes, not when any MediaQuery property changes
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = size.height;
    
    return _ScaleFactors(
      widthScale: width / _refWidth,
      heightScale: height / _refHeight,
      minScale: min(width / _refWidth, height / _refHeight),
      deviceType: _getDeviceType(width),
    );
  }

  /// Determine device type based on screen width
  static _DeviceType _getDeviceType(double width) {
    if (width <= _compactWidth) return _DeviceType.compact;
    if (width <= _regularWidth + 10) return _DeviceType.regular;
    return _DeviceType.large;
  }

  /// Returns a responsive width based on percentage of screen width
  static double width(BuildContext context, double percentage) =>
      MediaQuery.of(context).size.width * percentage;

  /// Returns a responsive height based on percentage of screen height
  static double height(BuildContext context, double percentage) =>
      MediaQuery.of(context).size.height * percentage;

  /// Returns a responsive text size with device-aware scaling
  /// Scales down on smaller devices but never below 75% of base size
  /// Scales up slightly on larger devices (max 100% of base)
  static double text(BuildContext context, double baseSize) {
    final factors = _getScaleFactors(context);
    
    // Use minimum scale to ensure text fits both dimensions
    final scale = factors.minScale;
    
    // Different clamping based on device type for optimal readability
    switch (factors.deviceType) {
      case _DeviceType.compact:
        // iPhone SE/mini: scale down more aggressively but keep readable
        return (baseSize * scale).clamp(baseSize * 0.72, baseSize * 0.88);
      case _DeviceType.regular:
        // Standard iPhones: moderate scaling
        return (baseSize * scale).clamp(baseSize * 0.80, baseSize * 0.95);
      case _DeviceType.large:
        // Plus/Max models: keep closer to base size
        return (baseSize * scale).clamp(baseSize * 0.90, baseSize * 1.0);
    }
  }

  /// Returns responsive spacing with device-aware scaling
  /// More aggressive scaling for spacing to prevent overflow
  static double spacing(BuildContext context, double baseSize) {
    final factors = _getScaleFactors(context);
    final scale = factors.minScale;
    
    switch (factors.deviceType) {
      case _DeviceType.compact:
        // Compact: reduce spacing more to fit content
        return (baseSize * scale).clamp(baseSize * 0.55, baseSize * 0.80);
      case _DeviceType.regular:
        // Regular: moderate spacing reduction
        return (baseSize * scale).clamp(baseSize * 0.70, baseSize * 0.92);
      case _DeviceType.large:
        // Large: keep spacing close to design
        return (baseSize * scale).clamp(baseSize * 0.88, baseSize * 1.0);
    }
  }

  /// Returns responsive horizontal padding
  /// Ensures minimum touch targets and visual balance
  static double horizontalPadding(BuildContext context) {
    final factors = _getScaleFactors(context);
    
    switch (factors.deviceType) {
      case _DeviceType.compact:
        return 12.0;
      case _DeviceType.regular:
        return 16.0;
      case _DeviceType.large:
        return 20.0;
    }
  }

  /// Returns responsive vertical spacing
  static double verticalSpacing(BuildContext context, double baseSize) {
    final factors = _getScaleFactors(context);
    final scale = factors.heightScale;
    
    switch (factors.deviceType) {
      case _DeviceType.compact:
        return (baseSize * scale).clamp(baseSize * 0.50, baseSize * 0.75);
      case _DeviceType.regular:
        return (baseSize * scale).clamp(baseSize * 0.65, baseSize * 0.90);
      case _DeviceType.large:
        return (baseSize * scale).clamp(baseSize * 0.85, baseSize * 1.0);
    }
  }

  /// Returns responsive icon size
  static double icon(BuildContext context, double baseSize) {
    final factors = _getScaleFactors(context);
    final scale = factors.minScale;
    
    // Icons need to maintain minimum touch target size (44pt on iOS)
    final minSize = baseSize >= 24 ? baseSize * 0.80 : baseSize * 0.85;
    return (baseSize * scale).clamp(minSize, baseSize * 1.0);
  }

  /// Returns responsive border radius
  static double radius(BuildContext context, double baseRadius) {
    final factors = _getScaleFactors(context);
    final scale = factors.minScale;
    
    // Border radius scales proportionally but maintains visual consistency
    return (baseRadius * scale).clamp(baseRadius * 0.75, baseRadius * 1.0);
  }

  /// Returns a responsive card/container height
  static double cardHeight(BuildContext context, double baseHeight) {
    final factors = _getScaleFactors(context);
    
    switch (factors.deviceType) {
      case _DeviceType.compact:
        return baseHeight * 0.82;
      case _DeviceType.regular:
        return baseHeight * 0.92;
      case _DeviceType.large:
        return baseHeight;
    }
  }

  /// Check if screen is compact (iPhone SE, mini, or similar small screens)
  static bool isCompactScreen(BuildContext context) =>
      _getScaleFactors(context).deviceType == _DeviceType.compact;

  /// Check if screen is small (height < 700) - backwards compatibility
  static bool isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.height < 700;

  /// Check if device is a tablet (shortestSide >= 600)
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide >= 600;

  /// Get the current device type
  static String deviceTypeName(BuildContext context) {
    final factors = _getScaleFactors(context);
    switch (factors.deviceType) {
      case _DeviceType.compact:
        return 'compact';
      case _DeviceType.regular:
        return 'regular';
      case _DeviceType.large:
        return 'large';
    }
  }

  /// Returns responsive button height
  /// Ensures minimum tap target of 44pt on iOS
  static double buttonHeight(BuildContext context, double baseHeight) {
    final factors = _getScaleFactors(context);
    final scale = factors.minScale;
    final scaled = baseHeight * scale;
    
    // iOS minimum tap target is 44pt
    return scaled.clamp(44.0, baseHeight);
  }

  /// Returns responsive stroke width for gauges/progress indicators
  static double strokeWidth(BuildContext context, double baseWidth) {
    final factors = _getScaleFactors(context);
    
    switch (factors.deviceType) {
      case _DeviceType.compact:
        return baseWidth * 0.75;
      case _DeviceType.regular:
        return baseWidth * 0.88;
      case _DeviceType.large:
        return baseWidth;
    }
  }
}

enum _DeviceType { compact, regular, large }

class _ScaleFactors {
  final double widthScale;
  final double heightScale;
  final double minScale;
  final _DeviceType deviceType;

  const _ScaleFactors({
    required this.widthScale,
    required this.heightScale,
    required this.minScale,
    required this.deviceType,
  });
}

/// Extension for convenient access to ResponsiveSize methods.
/// Usage: `context.rs.spacing(24)` instead of `ResponsiveSize.spacing(context, 24)`
extension ResponsiveSizeExtension on BuildContext {
  /// Shorthand accessor for responsive sizing utilities.
  _ResponsiveSizeHelper get rs => _ResponsiveSizeHelper(this);
}

/// Helper class that provides a fluent API for responsive sizing.
/// Reduces boilerplate by eliminating repeated context parameter.
class _ResponsiveSizeHelper {
  final BuildContext _context;
  
  const _ResponsiveSizeHelper(this._context);
  
  /// Responsive spacing (general use)
  double s(double baseSize) => ResponsiveSize.spacing(_context, baseSize);
  
  /// Responsive text size
  double t(double baseSize) => ResponsiveSize.text(_context, baseSize);
  
  /// Responsive vertical spacing
  double v(double baseSize) => ResponsiveSize.verticalSpacing(_context, baseSize);
  
  /// Responsive horizontal padding
  double get hp => ResponsiveSize.horizontalPadding(_context);
  
  /// Responsive icon size
  double i(double baseSize) => ResponsiveSize.icon(_context, baseSize);
  
  /// Responsive border radius
  double r(double baseRadius) => ResponsiveSize.radius(_context, baseRadius);
  
  /// Responsive button height
  double bh(double baseHeight) => ResponsiveSize.buttonHeight(_context, baseHeight);
  
  /// Responsive card height
  double ch(double baseHeight) => ResponsiveSize.cardHeight(_context, baseHeight);
  
  /// Responsive stroke width
  double sw(double baseWidth) => ResponsiveSize.strokeWidth(_context, baseWidth);
  
  /// Check if compact screen
  bool get isCompact => ResponsiveSize.isCompactScreen(_context);
  
  /// Check if small screen (height < 700)
  bool get isSmall => ResponsiveSize.isSmallScreen(_context);
  
  /// Check if tablet
  bool get isTablet => ResponsiveSize.isTablet(_context);
  
  /// Get device type name
  String get deviceType => ResponsiveSize.deviceTypeName(_context);
}
