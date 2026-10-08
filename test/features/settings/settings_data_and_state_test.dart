import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/features/settings/data/settings_repository_impl.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';
import 'package:mynewapp/features/settings/domain/settings_repository.dart';
import 'package:mynewapp/features/settings/presentation/state/settings_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_app.dart';

Future<SettingsRepositoryImpl> _repo([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(initial);
  return SettingsRepositoryImpl(await SharedPreferences.getInstance());
}

class _FailingRepository implements SettingsRepository {
  @override
  Future<AppSettings> load() async => const AppSettings();

  @override
  Future<void> save(AppSettings settings) async =>
      throw StateError('disk full');
}

void main() {
  group('AppSettings', () {
    test('the default reading size is one of the allowed steps', () {
      expect(
        AppSettings.readingScales,
        contains(AppSettings.defaultReadingScale),
      );
    });

    test('snapReadingScale picks the nearest allowed step', () {
      expect(AppSettings.snapReadingScale(1.0), 1.0);
      expect(AppSettings.snapReadingScale(1.6), 1.5);
      expect(AppSettings.snapReadingScale(0.1), 0.85);
      expect(AppSettings.snapReadingScale(99), 1.75);
    });

    test('language codes', () {
      expect(AppLanguage.system.code, isNull);
      expect(AppLanguage.arabic.code, 'ar');
      expect(AppLanguage.english.code, 'en');
    });
  });

  group('SettingsRepositoryImpl', () {
    test('an empty store gives the defaults', () async {
      expect(await (await _repo()).load(), const AppSettings());
    });

    test('saved settings are read back', () async {
      final repo = await _repo();
      const saved = AppSettings(
        language: AppLanguage.english,
        theme: ThemePreference.dark,
        readingScale: 1.3,
      );
      await repo.save(saved);
      expect(await repo.load(), saved);
    });

    test('settings survive a new repository over the same store', () async {
      final prefs = await (() async {
        SharedPreferences.setMockInitialValues({});
        return SharedPreferences.getInstance();
      })();
      await SettingsRepositoryImpl(prefs).save(
        const AppSettings(
          language: AppLanguage.arabic,
          theme: ThemePreference.light,
        ),
      );
      final reloaded = await SettingsRepositoryImpl(prefs).load();
      expect(reloaded.language, AppLanguage.arabic);
      expect(reloaded.theme, ThemePreference.light);
    });

    test('unknown stored names fall back to the defaults', () async {
      final repo = await _repo({
        SettingsRepositoryImpl.languageKey: 'klingon',
        SettingsRepositoryImpl.themeKey: 'neon',
      });
      final settings = await repo.load();
      expect(settings.language, AppLanguage.system);
      expect(settings.theme, ThemePreference.system);
    });

    test('a reading size that is not an allowed step is snapped', () async {
      final repo = await _repo({SettingsRepositoryImpl.readingScaleKey: 1.6});
      expect((await repo.load()).readingScale, 1.5);
    });

    test(
      'a value of the wrong type is treated as missing, not as a crash',
      () async {
        final repo = await _repo({
          SettingsRepositoryImpl.readingScaleKey: 'big',
          SettingsRepositoryImpl.languageKey: 42,
        });
        final settings = await repo.load();
        expect(settings.readingScale, AppSettings.defaultReadingScale);
        expect(settings.language, AppLanguage.system);
      },
    );
  });

  group('SettingsCubit', () {
    test('changes apply immediately and are saved', () async {
      final repo = InMemorySettingsRepository();
      final cubit = SettingsCubit(repo, const AppSettings());
      await cubit.setLanguage(AppLanguage.english);
      await cubit.setTheme(ThemePreference.dark);
      expect(cubit.state.language, AppLanguage.english);
      expect(cubit.state.theme, ThemePreference.dark);
      expect(repo.stored, cubit.state);
      expect(repo.saves, 2);
      await cubit.close();
    });

    test('setting the same value again does nothing', () async {
      final repo = InMemorySettingsRepository();
      final cubit = SettingsCubit(repo, const AppSettings());
      await cubit.setTheme(ThemePreference.system);
      expect(repo.saves, 0);
      await cubit.close();
    });

    test(
      'reading size moves one step at a time and stops at both ends',
      () async {
        final cubit = SettingsCubit(
          InMemorySettingsRepository(),
          const AppSettings(),
        );
        for (var i = 0; i < 10; i++) {
          await cubit.increaseReadingScale();
        }
        expect(cubit.state.readingScale, AppSettings.readingScales.last);
        expect(cubit.state.canIncreaseReadingScale, isFalse);
        for (var i = 0; i < 10; i++) {
          await cubit.decreaseReadingScale();
        }
        expect(cubit.state.readingScale, AppSettings.readingScales.first);
        expect(cubit.state.canDecreaseReadingScale, isFalse);
        await cubit.close();
      },
    );

    test('an arbitrary reading size is snapped to a step', () async {
      final cubit = SettingsCubit(
        InMemorySettingsRepository(),
        const AppSettings(),
      );
      await cubit.setReadingScale(1.6);
      expect(cubit.state.readingScale, 1.5);
      await cubit.close();
    });

    test('a failed save does not undo the change for this session', () async {
      final cubit = SettingsCubit(_FailingRepository(), const AppSettings());
      await cubit.setTheme(ThemePreference.dark);
      expect(cubit.state.theme, ThemePreference.dark);
      await cubit.close();
    });
  });
}
