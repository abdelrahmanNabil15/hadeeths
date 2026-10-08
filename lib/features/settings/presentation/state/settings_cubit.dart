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

  Future<void> setOfflineCopies({required bool enabled}) =>
      _update(state.copyWith(offlineCopies: enabled));

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
