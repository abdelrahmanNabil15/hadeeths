import 'package:flutter/material.dart';

/// Design tokens. They capture the app's existing look in one place; screens must use these
/// instead of literals. The only deliberate change from the original look is the app-bar
/// title colour (see [AppColors.onAppBar]).
abstract final class AppColors {
  /// App-bar background on the home screen (translucent beige over white).
  static const homeAppBar = Color.fromARGB(100, 241, 224, 172);

  /// App-bar background on inner screens (translucent gold over white).
  static const appBar = Color.fromARGB(100, 226, 194, 117);

  /// Title and icon colour on app bars. The original white scored 1.11:1 on the beige bar;
  /// this dark brown scores above 9:1.
  static const onAppBar = Color.fromARGB(250, 73, 51, 35);

  /// Section headings on the details screen.
  static const heading = Color.fromARGB(250, 73, 51, 35);

  /// Grade and attribution on the details screen, word labels.
  static const accent = Color.fromARGB(250, 4, 21, 98);

  /// Hadith titles in the list.
  static const listTitle = Color.fromARGB(250, 40, 82, 122);

  static const ink = Colors.black;

  /// Secondary text. Black at 54% opacity measured about 4.4:1 on the cards; this is above 7:1.
  static const inkMuted = Color(0xFF5B5446);

  static const surface = Colors.white;
  static const sheetDivider = Colors.teal;

  static const cardFill = Colors.white60;
  static const cardBorder = Color.fromARGB(100, 245, 218, 176);
  static const cardShadow = Color.fromARGB(100, 238, 231, 225);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const grid = 20.0;
}

abstract final class AppRadius {
  /// Category cards.
  static const card = 15.0;

  /// Draggable sheets.
  static const sheet = 20.0;

  /// Modal bottom sheet outline.
  static const modal = 30.0;
}

/// Type sizes in logical pixels; they scale with the user's text-size setting.
abstract final class AppTextSize {
  static const display = 30.0;
  static const heading = 24.0;
  static const hadith = 24.0;
  static const body = 19.0;
  static const title = 19.0;
  static const listTitle = 16.0;
  static const meta = 14.0;
}

abstract final class AppSizes {
  /// Minimum interactive size (Material and WCAG 2.2 AA guidance).
  static const minTouchTarget = 48.0;

  /// Reference height of a category card at 100% text scale.
  static const categoryCardHeight = 120.0;
  static const categoryWideCardHeight = 90.0;
  static const categoryCardMaxWidth = 200.0;

  /// Longest line length on large screens.
  static const contentMaxWidth = 640.0;
}

abstract final class AppMotion {
  static const short = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 250);
}

abstract final class AppFonts {
  /// Bundled Cairo (SIL OFL 1.1). Covers Arabic and Latin.
  static const family = 'Cairo';
}
