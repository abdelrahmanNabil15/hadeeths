import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/core/database/user_database.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';

import '../support/fake_backend.dart';
import '../support/prayer_fakes.dart';
import '../support/test_app.dart';

int _rows(UserDatabase database, String table) =>
    database.db.select('SELECT COUNT(*) AS n FROM $table').first['n'] as int;

Future<(UserDatabase, PrayerFixture)> _start(
  WidgetTester tester, {
  FeatureFlags features = const FeatureFlags.all(),
}) async {
  tester.view.physicalSize = const Size(700, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final database = UserDatabase.inMemory();
  addTearDown(() {
    try {
      database.close();
    } on Object {
      // Already closed by the test.
    }
  });
  database.db.execute(
    "INSERT INTO prayer_log (day, prayer) VALUES ('2026-10-09', 'fajr')",
  );
  database.db.execute(
    "INSERT INTO favorites (hadith_id, added_at) VALUES ('100', 1)",
  );
  final cairo = realCityCatalog().cities.firstWhere((c) => c.nameEn == 'Cairo');
  final prayer = PrayerFixture(
    now: DateTime.utc(2026, 10, 9, 10),
    saved: PrayerPreferences().withLocation(cairo.toLocation('ar')),
  );
  await pumpApp(
    tester,
    FakeBackend(),
    locale: 'en',
    features: features,
    prayer: prayer.services,
    userData: database,
    settings: const AppSettings(theme: ThemePreference.dark),
  );
  return (database, prayer);
}

Future<void> _openSettingsFromMore(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('More'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();
}

Future<void> _deleteAll(WidgetTester tester) async {
  await tester.scrollUntilVisible(find.text('Delete all my data'), 300);
  await tester.tap(find.text('Delete all my data'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete everything'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the released app (sections off) does not offer it', (
    tester,
  ) async {
    await _start(tester, features: const FeatureFlags());
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    expect(find.text('Delete all my data'), findsNothing);
    expect(find.text('Your data'), findsNothing);
  });

  testWidgets('Settings under More explains it and asks before deleting', (
    tester,
  ) async {
    final (database, _) = await _start(tester);
    await _openSettingsFromMore(tester);
    await tester.scrollUntilVisible(find.text('Delete all my data'), 300);
    expect(find.text('Your data'), findsOneWidget);
    await tester.tap(find.text('Delete all my data'));
    await tester.pumpAndSettle();
    expect(find.text('Delete all your data?'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(_rows(database, 'prayer_log'), 1);
  });

  testWidgets('deleting removes everything and starts the app afresh', (
    tester,
  ) async {
    final (database, prayer) = await _start(tester);
    await _openSettingsFromMore(tester);
    await _deleteAll(tester);

    expect(_rows(database, 'prayer_log'), 0);
    expect(_rows(database, 'favorites'), 0);
    expect((await prayer.preferences.load()).location, isNull);
    // Back on the first page, with the confirmation.
    expect(find.text('Settings'), findsNothing);
    expect(find.text('All your data was deleted.'), findsOneWidget);
    // The settings are back to their defaults (the dark theme is gone).
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
  });

  testWidgets('after deleting, the prayer section asks for a place again', (
    tester,
  ) async {
    await _start(tester);
    await _openSettingsFromMore(tester);
    await _deleteAll(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Prayer'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Set your location'), findsOneWidget);
  });

  testWidgets('a partial failure is reported and nothing restarts', (
    tester,
  ) async {
    final (database, _) = await _start(tester);
    await _openSettingsFromMore(tester);
    database.close();
    await _deleteAll(tester);
    expect(
      find.text('Some of your data could not be deleted. Try again.'),
      findsOneWidget,
    );
    expect(find.text('Your data'), findsOneWidget);
  });

  testWidgets('Sources and rights under More describes what is kept', (
    tester,
  ) async {
    await _start(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('More'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sources and rights'));
    await tester.pumpAndSettle();
    expect(find.textContaining('kept only on this phone'), findsOneWidget);
    expect(find.text('Compass'), findsOneWidget);
  });
}
