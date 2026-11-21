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

  /// The end-of-verse ornament of the King Fahd Complex's own font (KFGQPC HAFS Uthmanic
  /// Script), the one the printed Madinah mushaf uses, in the colour of the text.
  mushafFont,
}

/// How a page of the Quran reader is set when it fits the screen (default reading size and text
/// scale; otherwise the page always runs as one paragraph and scrolls).
enum MushafLayoutStyle {
  /// Line for line as the 15-line Madinah mushaf, in the King Fahd Complex's own script. The
  /// default.
  madinah15,

  /// The verses of the page run on as one justified paragraph.
  flowing,
}

/// How the sura banner at the head of a sura is drawn in the Quran reader's running-paragraph
/// layout. (The 15-line layout always uses the Madinah-style header, the height of one line.)
enum SurahHeaderStyle {
  /// A Madinah-style cartouche drawn by the app, the sura's name set in the King Fahd Complex's
  /// script. The default.
  madinah,

  /// The app's simpler painted band (gold border, stars).
  banner,
}

/// Whether the Quran reader's fitted (one-page-per-screen) view is wrapped in a page frame. Has
/// no effect when the page scrolls instead (larger reading size or text scale): a frame has no
/// natural size to wrap a page that does not end.
enum PageFrameStyle {
  /// A Madinah-style frame drawn by the app: gold double rules with corner pieces. The default.
  madinah,

  /// No frame.
  none,
}

/// How the Quran reader lays out a sura's verses.
enum QuranReadingMode {
  /// The current mushaf page, turned like a printed copy.
  mushaf,

  /// One verse per block, scrolled through a single sura.
  verseByVerse,
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
    this.mushafLayoutStyle = MushafLayoutStyle.madinah15,
    this.surahHeaderStyle = SurahHeaderStyle.madinah,
    this.pageFrameStyle = PageFrameStyle.madinah,
    this.quranReadingMode = QuranReadingMode.mushaf,
    this.quranTranslationEditionId,
    this.quranTranslationEditionName,
    this.quranTafsirEditionId,
    this.quranTafsirEditionName,
    this.quranReciterId,
    this.quranReciterName,
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

  /// How the Quran reader sets a page that fits the screen.
  final MushafLayoutStyle mushafLayoutStyle;

  /// How the Quran reader draws the banner at the head of a sura.
  final SurahHeaderStyle surahHeaderStyle;

  /// Whether the Quran reader's fitted page view is wrapped in a decorative frame.
  final PageFrameStyle pageFrameStyle;

  /// Which layout the Quran reader opens with.
  final QuranReadingMode quranReadingMode;

  /// The translation edition shown under each verse in verse-by-verse mode (an id from the Quran
  /// Foundation API, via `QuranContentRepository`); `null` shows no translation.
  final int? quranTranslationEditionId;

  /// The chosen edition's name, saved alongside its id so the credit line can be shown without
  /// needing the full edition list loaded again.
  final String? quranTranslationEditionName;

  /// The tafsir edition read per verse in verse-by-verse mode; `null` means no tafsir is offered
  /// per verse (the reader still has only the bookmark action).
  final int? quranTafsirEditionId;
  final String? quranTafsirEditionName;

  /// The reciter the mini player uses; `null` means no reciter is chosen and "Listen" is not
  /// offered per verse.
  final int? quranReciterId;
  final String? quranReciterName;

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
    MushafLayoutStyle? mushafLayoutStyle,
    SurahHeaderStyle? surahHeaderStyle,
    PageFrameStyle? pageFrameStyle,
    QuranReadingMode? quranReadingMode,
    int? quranTranslationEditionId,
    String? quranTranslationEditionName,
    bool clearQuranTranslationEditionId = false,
    int? quranTafsirEditionId,
    String? quranTafsirEditionName,
    bool clearQuranTafsirEditionId = false,
    int? quranReciterId,
    String? quranReciterName,
    bool clearQuranReciterId = false,
  }) => AppSettings(
    language: language ?? this.language,
    theme: theme ?? this.theme,
    readingScale: readingScale ?? this.readingScale,
    offlineCopies: offlineCopies ?? this.offlineCopies,
    digits: digits ?? this.digits,
    ayahMarkerStyle: ayahMarkerStyle ?? this.ayahMarkerStyle,
    mushafLayoutStyle: mushafLayoutStyle ?? this.mushafLayoutStyle,
    surahHeaderStyle: surahHeaderStyle ?? this.surahHeaderStyle,
    pageFrameStyle: pageFrameStyle ?? this.pageFrameStyle,
    quranReadingMode: quranReadingMode ?? this.quranReadingMode,
    quranTranslationEditionId: clearQuranTranslationEditionId
        ? null
        : (quranTranslationEditionId ?? this.quranTranslationEditionId),
    quranTranslationEditionName: clearQuranTranslationEditionId
        ? null
        : (quranTranslationEditionName ?? this.quranTranslationEditionName),
    quranTafsirEditionId: clearQuranTafsirEditionId
        ? null
        : (quranTafsirEditionId ?? this.quranTafsirEditionId),
    quranTafsirEditionName: clearQuranTafsirEditionId
        ? null
        : (quranTafsirEditionName ?? this.quranTafsirEditionName),
    quranReciterId: clearQuranReciterId
        ? null
        : (quranReciterId ?? this.quranReciterId),
    quranReciterName: clearQuranReciterId
        ? null
        : (quranReciterName ?? this.quranReciterName),
  );

  @override
  List<Object?> get props => [
    language,
    theme,
    readingScale,
    offlineCopies,
    digits,
    ayahMarkerStyle,
    mushafLayoutStyle,
    surahHeaderStyle,
    pageFrameStyle,
    quranReadingMode,
    quranTranslationEditionId,
    quranTranslationEditionName,
    quranTafsirEditionId,
    quranTafsirEditionName,
    quranReciterId,
    quranReciterName,
  ];
}
