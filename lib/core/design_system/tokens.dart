import 'package:flutter/material.dart';

/// Design tokens: warm ivory and midnight emerald for light; charcoal with emerald-tinted steps for
/// dark (designed on its own, not an inverted light theme). Muted gold is an accent only.
///
/// Every text/background pair used on screen is checked against WCAG AA (4.5:1) in
/// `test/app/accessibility_test.dart`; control borders ([ColorScheme.outline]) reach 3:1.
abstract final class AppPalette {
  static const light = ColorScheme(
    brightness: Brightness.light,
    // Midnight emerald.
    primary: Color(0xFF0B4A3B),
    onPrimary: Color(0xFFFFFFFF),
    // Soft sage: selected states and the emphasised tile.
    primaryContainer: Color(0xFFDCE8E0),
    onPrimaryContainer: Color(0xFF083A2E),
    // Muted gold: grade chips and other small marks, never large areas.
    secondary: Color(0xFF86651B),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF2E7C8),
    onSecondaryContainer: Color(0xFF47370C),
    error: Color(0xFFA12A2A),
    onError: Color(0xFFFFFFFF),
    // surface = canvas (warm ivory), surfaceContainerLowest = reading surface and cards.
    surface: Color(0xFFFAF6EC),
    // Charcoal with a trace of green, softer than black on ivory.
    onSurface: Color(0xFF1E2320),
    onSurfaceVariant: Color(0xFF585B53),
    outline: Color(0xFF8A8371),
    outlineVariant: Color(0xFFE6DFCD),
    surfaceContainerLowest: Color(0xFFFFFDF8),
    surfaceContainerLow: Color(0xFFF6F1E5),
    surfaceContainer: Color(0xFFF2EDE0),
    surfaceContainerHigh: Color(0xFFEBE5D3),
    surfaceContainerHighest: Color(0xFFE5DECA),
    inverseSurface: Color(0xFF1E2320),
    onInverseSurface: Color(0xFFFAF6EC),
    inversePrimary: Color(0xFF7FD2B1),
    shadow: Color(0xFF1E2320),
    scrim: Color(0xFF000000),
  );

  static const dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF7FD2B1),
    onPrimary: Color(0xFF04261C),
    // Midnight emerald as a container.
    primaryContainer: Color(0xFF143F33),
    onPrimaryContainer: Color(0xFFCDEEE0),
    secondary: Color(0xFFD9B666),
    onSecondary: Color(0xFF2E2307),
    secondaryContainer: Color(0xFF46381A),
    onSecondaryContainer: Color(0xFFF3E3B5),
    error: Color(0xFFF29A9A),
    onError: Color(0xFF3B0A0A),
    // Charcoal canvas; each container step adds a little emerald, so depth reads as light, not grey.
    surface: Color(0xFF0D1311),
    onSurface: Color(0xFFEDE8DA),
    onSurfaceVariant: Color(0xFFB6B1A1),
    outline: Color(0xFF7B877F),
    outlineVariant: Color(0xFF26332D),
    surfaceContainerLowest: Color(0xFF131B18),
    surfaceContainerLow: Color(0xFF16201C),
    surfaceContainer: Color(0xFF1A2420),
    surfaceContainerHigh: Color(0xFF202B26),
    surfaceContainerHighest: Color(0xFF27342E),
    inverseSurface: Color(0xFFEDE8DA),
    onInverseSurface: Color(0xFF0D1311),
    inversePrimary: Color(0xFF0B4A3B),
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
  static const card = 16.0;

  /// Inputs and buttons.
  static const control = 12.0;

  /// Bottom sheets (top corners).
  static const sheet = 24.0;

  /// Dialogs.
  static const dialog = 24.0;

  /// Chips, count pills and the navigation indicator: fully rounded.
  static const pill = 999.0;
}

/// Line widths. Surfaces are separated by hairlines, not by shadows.
abstract final class AppBorders {
  /// Card and divider edges ([ColorScheme.outlineVariant]).
  static const hairline = 1.0;

  /// A focused field or the selected item in a list.
  static const emphasis = 1.5;
}

/// Depth. The app is flat by default; only a raised card (the hero search field, the reading
/// surface) gets this one soft, wide, low shadow.
abstract final class AppShadows {
  static List<BoxShadow> soft(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
    return [
      BoxShadow(
        color: scheme.shadow.withValues(alpha: isLight ? 0.07 : 0.28),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: scheme.shadow.withValues(alpha: isLight ? 0.04 : 0.18),
        blurRadius: 3,
        offset: const Offset(0, 1),
      ),
    ];
  }
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

  /// The tasbeeh count inside its circle (it shrinks to fit long numbers).
  static const counter = 64.0;
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

  /// Icons in app bars, rows and the navigation bar.
  static const icon = 24.0;

  /// The icon medallion in empty and error states.
  static const stateMedallion = 88.0;

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

  /// Editorial display face for large titles: Amiri's Naskh for Arabic and its serif Latin for
  /// English. Same bundled file, no new font.
  static const editorial = 'Amiri';
}
