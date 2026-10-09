import 'package:flutter/material.dart';

/// Design tokens: ivory and deep emerald for light, a dark green for dark.
///
/// Every text/background pair used on screen is checked against WCAG AA (4.5:1) in
/// `test/app/accessibility_test.dart`; control borders ([ColorScheme.outline]) reach 3:1.
abstract final class AppPalette {
  static const light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF0E5A47),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFDDEBE4),
    onPrimaryContainer: Color(0xFF0A3D30),
    // Muted gold: grade chips and other small marks, never large areas.
    secondary: Color(0xFF8A6A1F),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF3E9CC),
    onSecondaryContainer: Color(0xFF4A3A0E),
    error: Color(0xFFA12A2A),
    onError: Color(0xFFFFFFFF),
    // surface = canvas, surfaceContainerLowest = reading surface and cards.
    surface: Color(0xFFFAF6EC),
    onSurface: Color(0xFF1C1B17),
    onSurfaceVariant: Color(0xFF5B5446),
    outline: Color(0xFF8B8372),
    outlineVariant: Color(0xFFE4DCC8),
    surfaceContainerLowest: Color(0xFFFFFDF8),
    surfaceContainerLow: Color(0xFFF7F2E5),
    surfaceContainer: Color(0xFFF3EEDF),
    surfaceContainerHigh: Color(0xFFECE6D3),
    surfaceContainerHighest: Color(0xFFE6DFCB),
    inverseSurface: Color(0xFF1C1B17),
    onInverseSurface: Color(0xFFFAF6EC),
    inversePrimary: Color(0xFF6FCBAA),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  static const dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF6FCBAA),
    onPrimary: Color(0xFF06231B),
    primaryContainer: Color(0xFF1D4A3C),
    onPrimaryContainer: Color(0xFFD4F0E4),
    secondary: Color(0xFFD9B35B),
    onSecondary: Color(0xFF2E2307),
    secondaryContainer: Color(0xFF4A3A14),
    onSecondaryContainer: Color(0xFFF3E3B5),
    error: Color(0xFFF29A9A),
    onError: Color(0xFF3B0A0A),
    surface: Color(0xFF0F1512),
    onSurface: Color(0xFFECE6D6),
    onSurfaceVariant: Color(0xFFB3AC9B),
    outline: Color(0xFF76837B),
    outlineVariant: Color(0xFF2A3731),
    surfaceContainerLowest: Color(0xFF161F1A),
    surfaceContainerLow: Color(0xFF19231E),
    surfaceContainer: Color(0xFF1C2721),
    surfaceContainerHigh: Color(0xFF22302A),
    surfaceContainerHighest: Color(0xFF283A33),
    inverseSurface: Color(0xFFECE6D6),
    onInverseSurface: Color(0xFF0F1512),
    inversePrimary: Color(0xFF0E5A47),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class AppRadius {
  /// Tiles, cards and the reading surface.
  static const card = 12.0;

  /// Inputs and buttons.
  static const control = 8.0;

  /// Bottom sheets.
  static const sheet = 16.0;
}

/// Type sizes in logical pixels; they scale with the user's device text-size setting.
abstract final class AppTextSize {
  static const display = 28.0;
  static const title = 22.0;
  static const heading = 18.0;
  static const body = 16.0;
  static const meta = 14.0;

  /// Hadith text at 100% reading size. Naskh (Amiri) reads smaller than Cairo at the same
  /// size, so Arabic starts larger.
  static const readingArabic = 24.0;
  static const readingLatin = 18.0;
}

abstract final class AppLineHeight {
  /// Full diacritics need generous leading.
  static const readingArabic = 2.0;
  static const readingLatin = 1.7;
  static const body = 1.5;
}

abstract final class AppSizes {
  /// Minimum interactive size (Material and WCAG 2.2 AA guidance).
  static const minTouchTarget = 48.0;

  /// Minimum height of a list row.
  static const minTileHeight = 56.0;

  /// Bottom navigation bar (Material 3 default is 80).
  static const navigationBarHeight = 72.0;

  /// Icons that sit beside text.
  static const iconSmall = 20.0;

  /// Longest line length on large screens.
  static const contentMaxWidth = 640.0;
}

/// Durations and curves for every animation in the app.
///
/// Animations are feedback and continuity, never a gate: state, saving and navigation never wait for
/// one to finish. Read durations through `context.motion(...)` (see `motion.dart`) so that the
/// system's "remove animations" setting turns them off. Starting values, to be tuned on devices.
abstract final class AppMotion {
  /// Press feedback, ink, check marks.
  static const instant = Duration(milliseconds: 100);

  /// Switches, chips, selection indicators.
  static const short = Duration(milliseconds: 150);

  /// Expanding and collapsing, loading to content, a banner appearing.
  static const medium = Duration(milliseconds: 250);

  /// A page entering; leaving is a little faster so going back never feels slow.
  static const page = Duration(milliseconds: 280);
  static const pageReverse = Duration(milliseconds: 220);

  /// The longest allowed: only for a first-time reveal that carries meaning.
  static const emphasis = Duration(milliseconds: 400);

  /// Things that move or change in place.
  static const standard = Curves.easeInOutCubic;

  /// Things that appear.
  static const enter = Curves.easeOutCubic;

  /// Things that leave.
  static const exit = Curves.easeInCubic;
}

abstract final class AppFonts {
  /// UI font (Arabic and Latin), bundled Cairo, SIL OFL 1.1.
  static const ui = 'Cairo';

  /// Reading font for Arabic hadith text, bundled Amiri, SIL OFL 1.1.
  static const reading = 'Amiri';

  /// Quran text: Amiri Quran 1.003, bundled, SIL OFL 1.1 (the Amiri licence file covers it).
  static const quran = 'AmiriQuran';
}
