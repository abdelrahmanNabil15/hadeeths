import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';
import 'package:mynewapp/features/settings/domain/settings_repository.dart';

/// Holds the user's preferences for the whole app. Changes apply immediately and are saved
/// in the background.
class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit(this._repository, AppSettings initial) : super(initial);

  final SettingsRepository _repository;

  Future<void> setLanguage(AppLanguage language) =>
      _update(state.copyWith(language: language));

  Future<void> setTheme(ThemePreference theme) =>
      _update(state.copyWith(theme: theme));

  Future<void> setDigits(DigitStyle digits) =>
      _update(state.copyWith(digits: digits));

  Future<void> setQuranReadingMode(QuranReadingMode mode) =>
      _update(state.copyWith(quranReadingMode: mode));

  /// `null` shows no translation. [name] is required when [editionId] is not null, so the
  /// credit line under each verse never needs the edition list reloaded.
  Future<void> setQuranTranslationEdition(int? editionId, {String? name}) =>
      _update(
        editionId == null
            ? state.copyWith(clearQuranTranslationEditionId: true)
            : state.copyWith(
                quranTranslationEditionId: editionId,
                quranTranslationEditionName: name,
              ),
      );

  /// `null` shows no tafsir. [name] is required when [editionId] is not null, same rule as
  /// [setQuranTranslationEdition].
  Future<void> setQuranTafsirEdition(int? editionId, {String? name}) => _update(
    editionId == null
        ? state.copyWith(clearQuranTafsirEditionId: true)
        : state.copyWith(
            quranTafsirEditionId: editionId,
            quranTafsirEditionName: name,
          ),
  );

  /// `null` means no reciter is chosen. [name] is required when [reciterId] is not null, same
  /// rule as [setQuranTranslationEdition].
  Future<void> setQuranReciter(int? reciterId, {String? name}) => _update(
    reciterId == null
        ? state.copyWith(clearQuranReciterId: true)
        : state.copyWith(quranReciterId: reciterId, quranReciterName: name),
  );

  Future<void> setOfflineCopies({required bool enabled}) =>
      _update(state.copyWith(offlineCopies: enabled));

  Future<void> setAyahMarkerStyle(AyahMarkerStyle style) =>
      _update(state.copyWith(ayahMarkerStyle: style));

  Future<void> setMushafLayoutStyle(MushafLayoutStyle style) =>
      _update(state.copyWith(mushafLayoutStyle: style));

  Future<void> setSurahHeaderStyle(SurahHeaderStyle style) =>
      _update(state.copyWith(surahHeaderStyle: style));

  Future<void> setPageFrameStyle(PageFrameStyle style) =>
      _update(state.copyWith(pageFrameStyle: style));

  Future<void> setReadingScale(double scale) => _update(
    state.copyWith(readingScale: AppSettings.snapReadingScale(scale)),
  );

  Future<void> increaseReadingScale() async {
    if (!state.canIncreaseReadingScale) return;
    await setReadingScale(
      AppSettings.readingScales[state.readingScaleIndex + 1],
    );
  }

  Future<void> decreaseReadingScale() async {
    if (!state.canDecreaseReadingScale) return;
    await setReadingScale(
      AppSettings.readingScales[state.readingScaleIndex - 1],
    );
  }

  /// Back to the defaults (after "Delete all my data"); the defaults are saved too.
  Future<void> resetToDefaults() => _update(const AppSettings());

  Future<void> _update(AppSettings next) async {
    if (next == state) return;
    emit(next);
    try {
      await _repository.save(next);
    } catch (_) {
      // The preference still applies for this session; failing to persist it must not break
      // the screen the user is on.
    }
  }
}
