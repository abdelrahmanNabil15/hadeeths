import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/app.dart';
import 'package:mynewapp/app/app_dependencies.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/core/cache/response_cache.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_services.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';
import 'package:mynewapp/features/settings/domain/settings_repository.dart';
import 'package:mynewapp/features/tracker/domain/prayer_log_repository.dart';

import 'fake_backend.dart';

/// Settings kept in memory; counts how often they were saved.
class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository([this.stored = const AppSettings()]);

  AppSettings stored;
  int saves = 0;

  @override
  Future<AppSettings> load() async => stored;

  @override
  Future<void> save(AppSettings settings) async {
    saves++;
    stored = settings;
  }
}

AppDependencies testDependencies(
  FakeBackend api, {
  SettingsRepository? settings,
  SwitchableResponseCache? cache,
  FeatureFlags features = const FeatureFlags(),
  PrayerServices? prayer,
  PrayerLogRepository? prayerLog,
}) => AppDependencies(
  categories: api,
  hadiths: api,
  search: api,
  settings: settings ?? InMemorySettingsRepository(),
  cache: cache ?? SwitchableResponseCache(InMemoryResponseCache()),
  features: features,
  prayer: prayer,
  prayerLog: prayerLog,
);

/// Starts the app against [api].
///
/// [locale] pins the device language (the default test locale is English); [settings] are the
/// saved preferences. A new key per launch means pumping a second app in one test starts
/// from scratch.
Future<void> pumpApp(
  WidgetTester tester,
  FakeBackend api, {
  String locale = 'ar',
  AppSettings settings = const AppSettings(),
  SettingsRepository? repository,
  bool settle = true,
  FeatureFlags features = const FeatureFlags(),
  PrayerServices? prayer,
  PrayerLogRepository? prayerLog,
}) async {
  tester.platformDispatcher.localesTestValue = [Locale(locale)];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(
    MyApp(
      key: UniqueKey(),
      dependencies: testDependencies(
        api,
        settings: repository ?? InMemorySettingsRepository(settings),
        features: features,
        prayer: prayer,
        prayerLog: prayerLog,
      ),
      initialSettings: settings,
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

/// A small phone: 360x640 logical pixels.
void useSmallPhone(WidgetTester tester, {double textScale = 1.0}) {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Scrolls [finder] into view, then taps it (cards sit below the fold at large text).
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) =>
    tapVisible(tester, find.text(text).first);

/// Taps the app bar's back button. (`tester.pageBack()` looks for the English tooltip.)
Future<void> goBack(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();
}

/// Scrolls the first list until [finder] has been built, then taps it.
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 300);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
