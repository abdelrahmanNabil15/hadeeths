import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';
import 'package:mynewapp/features/tracker/domain/day_key.dart';

import '../support/fake_backend.dart';
import '../support/prayer_fakes.dart';
import '../support/test_app.dart';
import '../support/tracker_fakes.dart';

PrayerPreferences _savedCairo() {
  final cairo = realCityCatalog().cities.firstWhere((c) => c.nameEn == 'Cairo');
  return PrayerPreferences().withLocation(cairo.toLocation('ar'));
}

final _now = DateTime.utc(2026, 10, 9, 10);
final _today = DayKey(2026, 10, 9);

Future<InMemoryPrayerLog> _openTracker(
  WidgetTester tester, {
  String locale = 'en',
  InMemoryPrayerLog? log,
  bool withLog = true,
  bool tall = true,
}) async {
  if (tall) {
    tester.view.physicalSize = const Size(700, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }
  final prayerLog = log ?? InMemoryPrayerLog();
  final fixture = PrayerFixture(now: _now, saved: _savedCairo());
  await pumpApp(
    tester,
    FakeBackend(),
    locale: locale,
    features: const FeatureFlags(prayer: true),
    prayer: fixture.services,
    prayerLog: withLog ? prayerLog : null,
  );
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(locale == 'ar' ? 'المزيد' : 'More'),
    ),
  );
  await tester.pumpAndSettle();
  final tile = find.text(locale == 'ar' ? 'متابع الصلاة' : 'Prayer tracker');
  if (withLog) {
    await tester.tap(tile);
    await tester.pumpAndSettle();
  }
  return prayerLog;
}

void main() {
  testWidgets('More offers the tracker, and it opens on today', (tester) async {
    await _openTracker(tester);
    expect(find.text('Prayer tracker'), findsWidgets);
    expect(find.text('Today 9'), findsOneWidget);
    expect(find.text('0 of 5 marked'), findsOneWidget);
    for (final name in ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('Sunrise'), findsNothing);
  });

  testWidgets('without storage the tracker is not offered', (tester) async {
    await _openTracker(tester, withLog: false);
    expect(find.text('Prayer tracker'), findsNothing);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('marking a prayer shows the count and is saved', (tester) async {
    final log = await _openTracker(tester);
    await tester.tap(find.text('Fajr'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 5 marked'), findsOneWidget);
    expect(log.data[_today], {Prayer.fajr});
    await tester.tap(find.text('Isha'));
    await tester.pumpAndSettle();
    expect(find.text('2 of 5 marked'), findsOneWidget);
    await tester.tap(find.text('Fajr'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 5 marked'), findsOneWidget);
    expect(log.data[_today], {Prayer.isha});
  });

  testWidgets('another day can be chosen and marked', (tester) async {
    final log = await _openTracker(tester);
    await tester.tap(find.text('Wednesday 7'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maghrib'));
    await tester.pumpAndSettle();
    expect(log.data[DayKey(2026, 10, 7)], {Prayer.maghrib});
    expect(log.data[_today], isNull);
    expect(find.text('1/5'), findsOneWidget);
  });

  testWidgets('what was saved earlier is shown again', (tester) async {
    final log = InMemoryPrayerLog()
      ..data[_today] = {Prayer.fajr, Prayer.dhuhr, Prayer.asr};
    await _openTracker(tester, log: log);
    expect(find.text('3 of 5 marked'), findsOneWidget);
    expect(find.text('3/5'), findsOneWidget);
  });

  testWidgets('a failed save is explained and the mark is taken back', (
    tester,
  ) async {
    final log = InMemoryPrayerLog()..failWrites = StateError('disk');
    await _openTracker(tester, log: log);
    await tester.tap(find.text('Fajr'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not save'), findsOneWidget);
    expect(find.text('0 of 5 marked'), findsOneWidget);
  });

  testWidgets('deleting asks first, and then removes everything', (
    tester,
  ) async {
    final log = InMemoryPrayerLog()
      ..data[_today] = {Prayer.fajr}
      ..data[_today.addDays(-3)] = {Prayer.isha};
    await _openTracker(tester, log: log);
    await tester.scrollUntilVisible(find.text('Delete tracker data'), 300);
    await tester.tap(find.text('Delete tracker data'));
    await tester.pumpAndSettle();
    expect(find.text('Delete all tracker data?'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(log.deletes, 0);
    expect(find.text('1 of 5 marked'), findsOneWidget);

    await tester.tap(find.text('Delete tracker data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(log.deletes, 1);
    expect(log.data, isEmpty);
    expect(find.text('0 of 5 marked'), findsOneWidget);
  });

  testWidgets('Arabic: right to left, Arabic-Indic digits', (tester) async {
    final log = await _openTracker(tester, locale: 'ar');
    expect(find.text('اليوم ٩'), findsOneWidget);
    expect(find.textContaining('٠'), findsWidgets);
    await tester.tap(find.text('الفجر'));
    await tester.pumpAndSettle();
    expect(log.data[_today], {Prayer.fajr});
    expect(find.text('المُعلَّم ١ من ٥'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('اليوم ٩'))),
      TextDirection.rtl,
    );
  });

  group('accessibility', () {
    testWidgets('fits at 200% text on a small phone', (tester) async {
      useSmallPhone(tester, textScale: 2);
      await _openTracker(tester, tall: false);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap targets, labels and contrast hold', (tester) async {
      final handle = tester.ensureSemantics();
      useSmallPhone(tester);
      await _openTracker(tester, tall: false);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets(
      'a day announces its date and how many are marked, and which is chosen',
      (tester) async {
        final handle = tester.ensureSemantics();
        final log = InMemoryPrayerLog()..data[_today] = {Prayer.fajr};
        await _openTracker(tester, log: log);
        expect(
          tester.getSemantics(find.text('Today 9').first),
          isSemantics(
            label: 'Today 9, 1 of 5 marked',
            isButton: true,
            isSelected: true,
            hasSelectedState: true,
            hasTapAction: true,
          ),
        );
        handle.dispose();
      },
    );
  });

  group('privacy', () {
    test('the tracker code has no network access', () {
      final files = [
        for (final e in Directory(
          'lib/features/tracker',
        ).listSync(recursive: true))
          if (e is File && e.path.endsWith('.dart')) e,
      ];
      expect(files.length, greaterThan(4));
      for (final file in files) {
        final text = file.readAsStringSync();
        for (final forbidden in [
          'package:dio',
          'package:http',
          'dart:io',
          'HttpClient',
          'package:share_plus',
          'package:geolocator',
        ]) {
          expect(text, isNot(contains(forbidden)), reason: file.path);
        }
      }
    });

    test('the stored rows carry no place, time or name', () {
      final repo = File(
        'lib/features/tracker/data/prayer_log_repository_impl.dart',
      ).readAsStringSync();
      expect(repo, isNot(contains('latitude')));
      expect(repo, isNot(contains('DateTime.now')));
    });
  });
}
