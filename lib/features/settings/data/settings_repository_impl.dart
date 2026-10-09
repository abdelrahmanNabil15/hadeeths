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
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _prefs.setString(languageKey, settings.language.name);
    await _prefs.setString(themeKey, settings.theme.name);
    await _prefs.setDouble(readingScaleKey, settings.readingScale);
    await _prefs.setBool(offlineCopiesKey, settings.offlineCopies);
    await _prefs.setString(digitsKey, settings.digits.name);
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
