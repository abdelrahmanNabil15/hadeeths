import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/features/prayer_times/domain/hijri_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';

import '../support/fake_backend.dart';
import '../support/prayer_fakes.dart';
import '../support/test_app.dart';

PrayerPreferences _savedCairo() {
  final cairo = realCityCatalog().cities.firstWhere((c) => c.nameEn == 'Cairo');
  return PrayerPreferences().withLocation(cairo.toLocation('ar'));
}

Future<void> _open(
  WidgetTester tester,
  PrayerFixture fixture, {
  String locale = 'ar',
  AppSettings settings = const AppSettings(),
  bool tall = true,
}) async {
  if (tall) {
    tester.view.physicalSize = const Size(700, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }
  await pumpApp(
    tester,
    FakeBackend(),
    locale: locale,
    features: const FeatureFlags(prayer: true),
    prayer: fixture.services,
    settings: settings,
  );
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(locale == 'ar' ? 'الصلاة' : 'Prayer'),
    ),
  );
  await tester.pumpAndSettle();
}

// 21 June 2026, 08:00 UTC: morning in Cairo, a Sunday.
final _morning = DateTime.utc(2026, 6, 21, 8);

void main() {
  group('dates on the prayer screen', () {
    testWidgets(
      'Arabic: weekday, day, month, year and the Hijri date, in Arabic-Indic digits',
      (tester) async {
        await _open(tester, PrayerFixture(saved: _savedCairo(), now: _morning));
        expect(find.text('الأحد ٢١ يونيو ٢٠٢٦'), findsOneWidget);
        expect(find.text('٦ محرم ١٤٤٨ هـ'), findsOneWidget);
      },
    );

    testWidgets('English interface', (tester) async {
      await _open(
        tester,
        PrayerFixture(saved: _savedCairo(), now: _morning),
        locale: 'en',
      );
      expect(find.text('Sunday 21 June 2026'), findsOneWidget);
      expect(find.text('6 Muharram 1448 AH'), findsOneWidget);
    });

    testWidgets('Western digits can be chosen', (tester) async {
      await _open(
        tester,
        PrayerFixture(saved: _savedCairo(), now: _morning),
        settings: const AppSettings(digits: DigitStyle.western),
      );
      expect(find.text('6 محرم 1448 هـ'), findsOneWidget);
    });

    testWidgets(
      'after Maghrib the Hijri date is the next one, the calendar date is not',
      (tester) async {
        await _open(
          tester,
          PrayerFixture(
            saved: _savedCairo(),
            now: DateTime.utc(2026, 6, 21, 19),
          ),
        );
        expect(find.text('الأحد ٢١ يونيو ٢٠٢٦'), findsOneWidget);
        expect(find.text('٧ محرم ١٤٤٨ هـ'), findsOneWidget);
      },
    );
  });

  group('Hijri page', () {
    testWidgets('choose a correction: the date moves and the choice is saved', (
      tester,
    ) async {
      final f = PrayerFixture(saved: _savedCairo(), now: _morning);
      await _open(tester, f);
      await tester.tap(find.text('التاريخ الهجري'));
      await tester.pumpAndSettle();
      expect(find.text('أم القرى (السعودية)'), findsOneWidget);
      expect(find.textContaining('لم يُتحقق منه بعدُ'), findsOneWidget);
      await tester.tap(find.text('بعد بيوم'));
      await tester.pumpAndSettle();
      expect(f.preferences.stored.hijri.adjustmentDays, 1);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('٧ محرم ١٤٤٨ هـ'), findsOneWidget);
    });

    testWidgets('choose the other reference', (tester) async {
      final f = PrayerFixture(saved: _savedCairo(), now: _morning);
      await _open(tester, f);
      await tester.tap(find.text('التاريخ الهجري'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('المجلس الفقهي لأمريكا الشمالية (حسابي)'));
      await tester.pumpAndSettle();
      expect(f.preferences.stored.hijri.reference, HijriReference.fcna);
    });
  });

  group('Qibla page', () {
    testWidgets(
      'shows the bearing, the direction word, the distance and the honest note',
      (tester) async {
        await _open(tester, PrayerFixture(saved: _savedCairo(), now: _morning));
        await tester.tap(find.text('القبلة'));
        await tester.pumpAndSettle();
        // Cairo to the Kaaba is about 136 degrees: south-east, about 1,200 km.
        expect(find.text('١٣٦°'), findsOneWidget);
        expect(find.text('الجنوب الشرقي'), findsOneWidget);
        expect(find.textContaining('٠٠٠'), findsNothing);
        expect(find.textContaining('كم إلى الكعبة'), findsOneWidget);
        expect(find.textContaining('الشمال الحقيقي'), findsWidgets);
        expect(find.textContaining('الشمال المغناطيسي'), findsOneWidget);
      },
    );

    testWidgets('English interface', (tester) async {
      await _open(
        tester,
        PrayerFixture(saved: _savedCairo(), now: _morning),
        locale: 'en',
      );
      await tester.tap(find.text('Qibla'));
      await tester.pumpAndSettle();
      expect(find.text('136°'), findsOneWidget);
      expect(find.text('South-east'), findsOneWidget);
      expect(find.textContaining('magnetic north'), findsOneWidget);
    });

    testWidgets('is announced as one thing for a screen reader', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(
        tester,
        PrayerFixture(saved: _savedCairo(), now: _morning),
        locale: 'en',
      );
      await tester.tap(find.text('Qibla'));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(
          RegExp(r'136° from true north, clockwise, South-east'),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('accessibility and layout', () {
    for (final locale in ['ar', 'en']) {
      for (final theme in [ThemePreference.light, ThemePreference.dark]) {
        testWidgets(
          'new pages meet the guidelines in $locale / ${theme.name}',
          (tester) async {
            final handle = tester.ensureSemantics();
            await _open(
              tester,
              PrayerFixture(saved: _savedCairo(), now: _morning),
              locale: locale,
              settings: AppSettings(theme: theme),
            );
            await expectLater(tester, meetsGuideline(textContrastGuideline));
            await tester.tap(find.text(locale == 'ar' ? 'القبلة' : 'Qibla'));
            await tester.pumpAndSettle();
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(tester, meetsGuideline(textContrastGuideline));
            await tester.tap(find.byType(BackButton));
            await tester.pumpAndSettle();
            await tester.tap(
              find.text(locale == 'ar' ? 'التاريخ الهجري' : 'Hijri date'),
            );
            await tester.pumpAndSettle();
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
            await expectLater(tester, meetsGuideline(textContrastGuideline));
            handle.dispose();
          },
        );
      }
    }

    for (final scale in [1.3, 2.0]) {
      testWidgets('no overflow at ${(scale * 100).round()}% text', (
        tester,
      ) async {
        useSmallPhone(tester, textScale: scale);
        await _open(
          tester,
          PrayerFixture(saved: _savedCairo(), now: _morning),
          tall: false,
        );
        expect(tester.takeException(), isNull);
        await scrollAndTap(tester, find.text('القبلة'));
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await scrollAndTap(tester, find.text('التاريخ الهجري'));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
