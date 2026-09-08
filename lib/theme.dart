import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color offWhite = Color(0xFFFEFEFE);
// Empty progress bar/track color (FEFEFE at 12% opacity)
const Color progressEmptyColor = Color(0x1FFEFEFE);
// UpdatedScript header background (FEFEFE at 8% opacity)
/// #FEFEFE @ 8% opacity (used for subtle dividers / header tints)
const Color updatedScriptHeaderBg = Color(0x14FEFEFE);

/// #FEFEFE @ 4% opacity (used for extra-subtle surfaces like CTA tip)
const Color updatedScriptCtaTipBg = Color(0x0AFEFEFE);
// UpdatedScript subtitle / helper text color (FEFEFE at 30% opacity)
const Color updatedScriptSubtitleColor = Color(0x4DFEFEFE);
// Primary ink color used for dark text on light elements.
const Color ink = Color(0xFF110A1D);
// Accent color for the left hook score card (Audio)
const Color audioAccent = Color(0xFFED6A17);
// Accent color for the right hook score card (Visual)
const Color visualAccent = Color(0xFFFF2EC9);

/// Primary accent gradient used for inline interactive text (e.g., Show more/less).
const LinearGradient accentGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [audioAccent, visualAccent],
);

// Modal background gradient colors
const Color modalGradientTop = Color(0xFFFFD2E8); // #FFD2E8
const Color modalGradientBottom = Color(0xFFFFDAC6); // #FFDAC6

/// Button text styles extension to keep button typography centralized.
class ButtonTextStyles extends ThemeExtension<ButtonTextStyles> {
  final TextStyle primary; // For solid/gradient primary buttons
  final TextStyle secondary; // For secondary buttons on light backgrounds
  final TextStyle smallSecondary; // For compact secondary buttons (Geom, 16, SemiBold)

  const ButtonTextStyles({
    required this.primary,
    required this.secondary,
    required this.smallSecondary,
  });

  @override
  ButtonTextStyles copyWith({TextStyle? primary, TextStyle? secondary, TextStyle? smallSecondary}) =>
      ButtonTextStyles(
        primary: primary ?? this.primary,
        secondary: secondary ?? this.secondary,
        smallSecondary: smallSecondary ?? this.smallSecondary,
      );

  @override
  ThemeExtension<ButtonTextStyles> lerp(ThemeExtension<ButtonTextStyles>? other, double t) {
    if (other is! ButtonTextStyles) return this;
    return ButtonTextStyles(
      primary: TextStyle.lerp(primary, other.primary, t) ?? primary,
      secondary: TextStyle.lerp(secondary, other.secondary, t) ?? secondary,
      smallSecondary: TextStyle.lerp(smallSecondary, other.smallSecondary, t) ?? smallSecondary,
    );
  }
}

ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFF110A1D),
  colorScheme: const ColorScheme.light(
    surface: Color(0xFF110A1D),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  textTheme: _buildTextTheme(),
  extensions: <ThemeExtension<dynamic>>[
    const ButtonTextStyles(
      primary: TextStyle(
        fontFamily: 'Geom',
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: offWhite,
      ),
      secondary: TextStyle(
        fontFamily: 'Geom',
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: ink,
      ),
      smallSecondary: TextStyle(
        fontFamily: 'Geom',
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: ink,
      ),
    ),
  ],
);

ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF110A1D),
  colorScheme: const ColorScheme.dark(
    surface: Color(0xFF110A1D),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  textTheme: _buildTextTheme(),
  extensions: <ThemeExtension<dynamic>>[
    const ButtonTextStyles(
      primary: TextStyle(
        fontFamily: 'Geom',
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: offWhite,
      ),
      secondary: TextStyle(
        fontFamily: 'Geom',
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: ink,
      ),
      smallSecondary: TextStyle(
        fontFamily: 'Geom',
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: ink,
      ),
    ),
  ],
);

TextTheme _buildTextTheme() => const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Geom',
      fontSize: 57.0,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Geom',
      fontSize: 45.0,
      fontWeight: FontWeight.w400,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Geom',
      fontSize: 36.0,
      fontWeight: FontWeight.w400,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'Geom',
      fontSize: 32.0,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Geom',
      fontSize: 28.0,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Geom',
      fontSize: 24.0,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Geom',
      fontSize: 22.0,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Geom',
      fontSize: 16.0,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Geom',
      fontSize: 14.0,
      fontWeight: FontWeight.w500,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Geom',
      fontSize: 14.0,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Geom',
      fontSize: 12.0,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Geom',
      fontSize: 11.0,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Geom',
      fontSize: 16.0,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Geom',
      fontSize: 14.0,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Geom',
      fontSize: 12.0,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
    ),
  );
