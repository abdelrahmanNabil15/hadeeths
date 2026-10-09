import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/features/quran/domain/sura_names.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// The sura's name in the interface language (Arabic name, or its English transliteration).
String suraName(BuildContext context, int sura) => context.apiLanguage == 'ar'
    ? SuraNames.arabic(sura)
    : SuraNames.latin(sura);

/// Style for Quran text: the reading font, right to left whatever the interface language, with
/// generous line height for the marks. Size follows the reading-size setting.
TextStyle quranTextStyle(BuildContext context, {required double scale}) =>
    TextStyle(
      fontFamily: AppFonts.reading,
      fontSize: AppTextSize.readingArabic * 1.15 * scale,
      height: AppLineHeight.readingArabic + 0.2,
      color: Theme.of(context).colorScheme.onSurface,
    );
