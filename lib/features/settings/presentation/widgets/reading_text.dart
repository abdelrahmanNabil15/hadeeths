import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/tokens.dart';

/// Style for hadith and explanation text.
///
/// Arabic uses the Naskh reading font (Amiri) with generous leading for full diacritics;
/// English uses the UI font. [scale] is the user's reading-size setting and [factor] lets
/// secondary text (explanation) sit a little below the hadith itself.
TextStyle readingTextStyle(
  BuildContext context, {
  required double scale,
  double factor = 1.0,
}) {
  final arabic = Localizations.localeOf(context).languageCode == 'ar';
  return TextStyle(
    fontFamily: arabic ? AppFonts.reading : AppFonts.ui,
    fontSize:
        (arabic ? AppTextSize.readingArabic : AppTextSize.readingLatin) *
        scale *
        factor,
    height: arabic ? AppLineHeight.readingArabic : AppLineHeight.readingLatin,
    color: Theme.of(context).colorScheme.onSurface,
  );
}
