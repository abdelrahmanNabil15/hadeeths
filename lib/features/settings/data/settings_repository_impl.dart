import 'package:mynewapp/features/settings/domain/app_settings.dart';
import 'package:mynewapp/features/settings/domain/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores the settings in `shared_preferences` (simple key-value settings only).
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  static const languageKey = 'settings.language';
  static const themeKey = 'settings.theme';
  static const readingScaleKey = 'settings.readingScale';
  static const offlineCopiesKey = 'settings.offlineCopies';
  static const digitsKey = 'settings.digits';
  static const ayahMarkerStyleKey = 'settings.ayahMarkerStyle';
  static const mushafLayoutStyleKey = 'settings.mushafLayoutStyle';
  static const surahHeaderStyleKey = 'settings.surahHeaderStyle';
  static const pageFrameStyleKey = 'settings.pageFrameStyle';
  static const quranReadingModeKey = 'settings.quranReadingMode';
  static const quranTranslationEditionIdKey =
      'settings.quranTranslationEditionId';
  static const quranTranslationEditionNameKey =
      'settings.quranTranslationEditionName';
  static const quranTafsirEditionIdKey = 'settings.quranTafsirEditionId';
  static const quranTafsirEditionNameKey = 'settings.quranTafsirEditionName';
  static const quranReciterIdKey = 'settings.quranReciterId';
  static const quranReciterNameKey = 'settings.quranReciterName';

  @override
  Future<AppSettings> load() async {
    return AppSettings(
      language:
          _enumByName(
            AppLanguage.values,
            _read(() => _prefs.getString(languageKey)),
          ) ??
          AppLanguage.system,
      theme:
          _enumByName(
            ThemePreference.values,
            _read(() => _prefs.getString(themeKey)),
          ) ??
          ThemePreference.system,
      readingScale: AppSettings.snapReadingScale(
        _read(() => _prefs.getDouble(readingScaleKey)) ??
            AppSettings.defaultReadingScale,
      ),
      offlineCopies: _read(() => _prefs.getBool(offlineCopiesKey)) ?? true,
      digits:
          _enumByName(
            DigitStyle.values,
            _read(() => _prefs.getString(digitsKey)),
          ) ??
          DigitStyle.automatic,
      ayahMarkerStyle:
          _enumByName(
            AyahMarkerStyle.values,
            _read(() => _prefs.getString(ayahMarkerStyleKey)),
          ) ??
          AyahMarkerStyle.rosette,
      mushafLayoutStyle:
          _enumByName(
            MushafLayoutStyle.values,
            _read(() => _prefs.getString(mushafLayoutStyleKey)),
          ) ??
          MushafLayoutStyle.madinah15,
      surahHeaderStyle:
          _enumByName(
            SurahHeaderStyle.values,
            _read(() => _prefs.getString(surahHeaderStyleKey)),
          ) ??
          SurahHeaderStyle.madinah,
      pageFrameStyle:
          _enumByName(
            PageFrameStyle.values,
            _read(() => _prefs.getString(pageFrameStyleKey)),
          ) ??
          PageFrameStyle.madinah,
      quranReadingMode:
          _enumByName(
            QuranReadingMode.values,
            _read(() => _prefs.getString(quranReadingModeKey)),
          ) ??
          QuranReadingMode.mushaf,
      quranTranslationEditionId: _read(
        () => _prefs.getInt(quranTranslationEditionIdKey),
      ),
      quranTranslationEditionName: _read(
        () => _prefs.getString(quranTranslationEditionNameKey),
      ),
      quranTafsirEditionId: _read(() => _prefs.getInt(quranTafsirEditionIdKey)),
      quranTafsirEditionName: _read(
        () => _prefs.getString(quranTafsirEditionNameKey),
      ),
      quranReciterId: _read(() => _prefs.getInt(quranReciterIdKey)),
      quranReciterName: _read(() => _prefs.getString(quranReciterNameKey)),
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _prefs.setString(languageKey, settings.language.name);
    await _prefs.setString(themeKey, settings.theme.name);
    await _prefs.setDouble(readingScaleKey, settings.readingScale);
    await _prefs.setBool(offlineCopiesKey, settings.offlineCopies);
    await _prefs.setString(digitsKey, settings.digits.name);
    await _prefs.setString(ayahMarkerStyleKey, settings.ayahMarkerStyle.name);
    await _prefs.setString(
      mushafLayoutStyleKey,
      settings.mushafLayoutStyle.name,
    );
    await _prefs.setString(surahHeaderStyleKey, settings.surahHeaderStyle.name);
    await _prefs.setString(pageFrameStyleKey, settings.pageFrameStyle.name);
    await _prefs.setString(quranReadingModeKey, settings.quranReadingMode.name);
    final editionId = settings.quranTranslationEditionId;
    if (editionId == null) {
      await _prefs.remove(quranTranslationEditionIdKey);
      await _prefs.remove(quranTranslationEditionNameKey);
    } else {
      await _prefs.setInt(quranTranslationEditionIdKey, editionId);
      await _prefs.setString(
        quranTranslationEditionNameKey,
        settings.quranTranslationEditionName ?? '',
      );
    }
    final tafsirEditionId = settings.quranTafsirEditionId;
    if (tafsirEditionId == null) {
      await _prefs.remove(quranTafsirEditionIdKey);
      await _prefs.remove(quranTafsirEditionNameKey);
    } else {
      await _prefs.setInt(quranTafsirEditionIdKey, tafsirEditionId);
      await _prefs.setString(
        quranTafsirEditionNameKey,
        settings.quranTafsirEditionName ?? '',
      );
    }
    final reciterId = settings.quranReciterId;
    if (reciterId == null) {
      await _prefs.remove(quranReciterIdKey);
      await _prefs.remove(quranReciterNameKey);
    } else {
      await _prefs.setInt(quranReciterIdKey, reciterId);
      await _prefs.setString(
        quranReciterNameKey,
        settings.quranReciterName ?? '',
      );
    }
  }

  /// A value of the wrong type (a corrupted or hand-edited store) counts as missing.
  static T? _read<T>(T? Function() read) {
    try {
      return read();
    } catch (_) {
      return null;
    }
  }

  static T? _enumByName<T extends Enum>(List<T> values, String? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
