/// Centralized app constants for consistent spacing, sizing, and breakpoints.
/// Use these values throughout the app to maintain visual consistency.
library;

/// Standard horizontal padding values for different contexts
class AppPadding {
  AppPadding._();
  
  /// Small horizontal padding (12px) - compact UI elements
  static const double small = 12.0;
  
  /// Medium horizontal padding (16px) - standard content
  static const double medium = 16.0;
  
  /// Large horizontal padding (20px) - spacious layouts
  static const double large = 20.0;
  
  /// Extra large horizontal padding (24px) - screen-level padding
  static const double extraLarge = 24.0;
  
  /// Screen edge padding (24px) - standard screen margin
  static const double screen = 24.0;
  
  /// Top padding below safe area (24px)
  static const double topContent = 24.0;
  
  /// Bottom padding above safe area (8px)
  static const double bottomContent = 8.0;
}

/// Standard spacing values between elements
class AppSpacing {
  AppSpacing._();
  
  /// Extra small spacing (4px)
  static const double xs = 4.0;
  
  /// Small spacing (8px)
  static const double sm = 8.0;
  
  /// Medium spacing (12px)
  static const double md = 12.0;
  
  /// Large spacing (16px)
  static const double lg = 16.0;
  
  /// Extra large spacing (24px)
  static const double xl = 24.0;
  
  /// Double extra large spacing (32px)
  static const double xxl = 32.0;
}

/// Standard border radius values
class AppRadius {
  AppRadius._();
  
  /// Small radius (8px) - subtle rounding
  static const double small = 8.0;
  
  /// Medium radius (12px) - cards, containers
  static const double medium = 12.0;
  
  /// Large radius (16px) - modals, sheets
  static const double large = 16.0;
  
  /// Extra large radius (24px) - prominent elements
  static const double extraLarge = 24.0;
  
  /// Pill/capsule radius (30px) - buttons
  static const double pill = 30.0;
}

/// Device breakpoints for responsive layouts
class AppBreakpoints {
  AppBreakpoints._();
  
  /// Compact devices like iPhone SE, mini (375px)
  static const double compact = 375.0;
  
  /// Regular devices like standard iPhones (390px)
  static const double regular = 390.0;
  
  /// Large devices like Plus/Max models (430px)
  static const double large = 430.0;
  
  /// Tablet threshold (600px)
  static const double tablet = 600.0;
  
  /// Desktop threshold (1024px)
  static const double desktop = 1024.0;
  
  /// Maximum content width for responsive wrapper
  static const double maxContentWidth = 600.0;
}

/// Animation durations for consistent motion
class AppDurations {
  AppDurations._();
  
  /// Instant/none (0ms)
  static const Duration instant = Duration.zero;
  
  /// Very fast (100ms) - button press feedback
  static const Duration veryFast = Duration(milliseconds: 100);
  
  /// Fast (200ms) - micro interactions
  static const Duration fast = Duration(milliseconds: 200);
  
  /// Normal (300ms) - standard transitions
  static const Duration normal = Duration(milliseconds: 300);
  
  /// Slow (500ms) - emphasis animations
  static const Duration slow = Duration(milliseconds: 500);
  
  /// Very slow (800ms) - dramatic effects
  static const Duration verySlow = Duration(milliseconds: 800);
}

/// Icon sizes for consistent iconography
class AppIconSizes {
  AppIconSizes._();
  
  /// Small icon (16px)
  static const double small = 16.0;
  
  /// Medium icon (20px)
  static const double medium = 20.0;
  
  /// Standard icon (24px) - default size
  static const double standard = 24.0;
  
  /// Large icon (32px)
  static const double large = 32.0;
  
  /// Extra large icon (48px)
  static const double extraLarge = 48.0;
}

/// Button sizes for consistent tap targets
class AppButtonSizes {
  AppButtonSizes._();
  
  /// Minimum touch target (44px) - iOS HIG requirement
  static const double minTouchTarget = 44.0;
  
  /// Small button height (40px)
  static const double small = 40.0;
  
  /// Medium button height (48px)
  static const double medium = 48.0;
  
  /// Large button height (56px)
  static const double large = 56.0;
  
  /// Extra large button height (60px) - primary CTAs
  static const double extraLarge = 60.0;
}

/// Default niche configuration for fallback when Gemini doesn't select a niche
/// or when database lookup fails
class AppDefaultNiche {
  AppDefaultNiche._();
  
  /// Default niche category
  static const String category = 'General';
  
  /// Default niche display name
  static const String name = 'General';
  
  /// Default niche slug (used for database lookup fallback)
  static const String slug = 'general';
  
  /// Default average hook score benchmark
  static const int avgHookScore = 70;
  
  /// Default TikTok engagement rate
  static const double tiktokEngagement = 2.5;
  
  /// Default Instagram engagement rate
  static const double instagramEngagement = 2.3;
  
  /// Default YouTube engagement rate
  static const double youtubeEngagement = 1.3;
  
  /// Default average engagement rate
  static const double avgEngagement = 2.0;
}
