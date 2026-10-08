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

/// User preferences. They are plain settings; no hadith content is ever stored here.
class AppSettings extends Equatable {
  const AppSettings({
    this.language = AppLanguage.system,
    this.theme = ThemePreference.system,
    this.readingScale = defaultReadingScale,
    this.offlineCopies = true,
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
  }) => AppSettings(
    language: language ?? this.language,
    theme: theme ?? this.theme,
    readingScale: readingScale ?? this.readingScale,
    offlineCopies: offlineCopies ?? this.offlineCopies,
  );

  @override
  List<Object?> get props => [language, theme, readingScale, offlineCopies];
}
