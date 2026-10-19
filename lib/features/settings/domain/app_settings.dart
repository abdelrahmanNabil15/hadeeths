import 'package:equatable/equatable.dart';

/// Which language the UI (and the hadith content) uses.
enum AppLanguage {
  /// Follow the device language; Arabic when the device uses neither Arabic nor English.
  system,
  arabic,
  english;

  /// The language code, or null when following the device.
  String? get code => switch (this) {
    AppLanguage.system => null,
    AppLanguage.arabic => 'ar',
    AppLanguage.english => 'en',
  };
}

enum ThemePreference { system, light, dark }

/// How the verse-number marker is drawn in the Quran reader.
enum AyahMarkerStyle {
  /// The app's own painted rosette (gold ring, sage when bookmarked). The default.
  rosette,

  /// A traced Mushaf ayah-marker glyph from Quran.ws Quran Assets (OFL-1.1, confirmed assets only).
  mushafGlyph,

  /// The Scheherazade New ayah-marker glyph (also from Quran.ws Quran Assets, OFL-1.1, confirmed),
  /// shown in its own full-colour palette — never tinted gold or sage, unlike [mushafGlyph].
  scheherazadeColor,
}

/// How the app writes its own numbers.
enum DigitStyle {
  /// Arabic-Indic digits (٠١٢٣) when the interface is Arabic, Western digits (0123) otherwise.
  automatic,
  arabicIndic,
  western,
}

/// User preferences. They are plain settings; no hadith content is ever stored here.
class AppSettings extends Equatable {
  const AppSettings({
    this.language = AppLanguage.system,
    this.theme = ThemePreference.system,
    this.readingScale = defaultReadingScale,
    this.offlineCopies = true,
    this.digits = DigitStyle.automatic,
    this.ayahMarkerStyle = AyahMarkerStyle.rosette,
  });

  /// Allowed multipliers for the reading text (hadith and explanation), smallest first.
  static const readingScales = <double>[0.85, 1.0, 1.15, 1.3, 1.5, 1.75];
  static const defaultReadingScale = 1.0;

  final AppLanguage language;
  final ThemePreference theme;

  /// Multiplier for the reading text, one of [readingScales]. It is applied on top of the
  /// device's own text-size setting.
  final double readingScale;

  /// Keep hadiths the user opens on the device so they can be read again without a connection.
  final bool offlineCopies;

  /// Which digits the app's own numbers use. Content from sources is never changed.
  final DigitStyle digits;

  /// How the Quran reader draws the verse-number marker.
  final AyahMarkerStyle ayahMarkerStyle;

  /// Index of [readingScale] in [readingScales].
  int get readingScaleIndex => readingScales.indexOf(readingScale);

  bool get canIncreaseReadingScale =>
      readingScaleIndex < readingScales.length - 1;
  bool get canDecreaseReadingScale => readingScaleIndex > 0;

  /// The valid scale nearest to [value] (stored values are never trusted blindly).
  static double snapReadingScale(double value) {
    var best = readingScales.first;
    for (final step in readingScales) {
      if ((step - value).abs() < (best - value).abs()) best = step;
    }
    return best;
  }

  AppSettings copyWith({
    AppLanguage? language,
    ThemePreference? theme,
    double? readingScale,
    bool? offlineCopies,
    DigitStyle? digits,
    AyahMarkerStyle? ayahMarkerStyle,
  }) => AppSettings(
    language: language ?? this.language,
    theme: theme ?? this.theme,
    readingScale: readingScale ?? this.readingScale,
    offlineCopies: offlineCopies ?? this.offlineCopies,
    digits: digits ?? this.digits,
    ayahMarkerStyle: ayahMarkerStyle ?? this.ayahMarkerStyle,
  );

  @override
  List<Object?> get props => [
    language,
    theme,
    readingScale,
    offlineCopies,
    digits,
    ayahMarkerStyle,
  ];
}
