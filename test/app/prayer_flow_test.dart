import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/core/permissions/permission_gateway.dart';
import 'package:mynewapp/core/widgets/app_tile.dart';
import 'package:mynewapp/features/prayer_times/domain/calculation_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_location.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';

import '../support/fake_backend.dart';
import '../support/prayer_fakes.dart';
import '../support/test_app.dart';

Future<void> _open(
  WidgetTester tester,
  PrayerFixture fixture, {
  String locale = 'ar',
  AppSettings settings = const AppSettings(),
  bool tall = true,
}) async {
  if (tall) {
    // A tall screen, so the whole list is built (lists build only what is on screen).
    tester.view.physicalSize = const Size(700, 2400);
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

Future<void> _pickCity(WidgetTester tester, String query, String result) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(AppTile, result));
  await tester.pumpAndSettle();
}

PrayerPreferences _savedCairo() {
  final cairo = realCityCatalog().cities.firstWhere((c) => c.nameEn == 'Cairo');
  return PrayerPreferences().withLocation(cairo.toLocation('ar'));
}

final _arabicTime = RegExp(r'^[٠-٩]{1,2}:[٠-٩]{2} [صم]$');
final _englishTime = RegExp(r'^\d{1,2}:\d{2} (AM|PM)$');

void main() {
  group('first set-up', () {
    testWidgets('with no place the screen offers the two ways to set one', (
      tester,
    ) async {
      await _open(tester, PrayerFixture());
      expect(find.text('حدّد موقعك'), findsOneWidget);
      expect(find.text('استخدم موقعي'), findsOneWidget);
      expect(find.text('اختر مدينة'), findsOneWidget);
    });

    testWidgets(
      'a city picked by name shows the times, with no permission asked',
      (tester) async {
        final f = PrayerFixture();
        await _open(tester, f);
        await tester.tap(find.text('اختر مدينة'));
        await tester.pumpAndSettle();
        await _pickCity(tester, 'الاسكندريه', 'الإسكندرية');

        expect(find.text('الإسكندرية'), findsOneWidget);
        for (final name in [
          'الفجر',
          'الشروق',
          'الظهر',
          'العصر',
          'المغرب',
          'العشاء',
        ]) {
          expect(find.text(name), findsWidgets, reason: name);
        }
        final times = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .where(_arabicTime.hasMatch)
            .toList();
        expect(
          times.length,
          greaterThanOrEqualTo(7),
        ); // six rows plus the next-prayer banner
        expect(find.text('الهيئة المصرية العامة للمساحة'), findsOneWidget);
        expect(find.textContaining('اختيرت تلقائيًا لبلدك'), findsOneWidget);
        expect(f.gateway.requested, isEmpty);
        expect(f.location.reads, 0);
        expect(f.preferences.stored.location!.name, 'الإسكندرية');
      },
    );

    testWidgets('English interface: English names and AM/PM', (tester) async {
      await _open(tester, PrayerFixture(), locale: 'en');
      await tester.tap(find.text('Choose a city'));
      await tester.pumpAndSettle();
      await _pickCity(tester, 'cairo', 'Cairo');
      expect(find.text('Fajr'), findsWidgets);
      expect(find.text('Next prayer'), findsOneWidget);
      final times = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .where(_englishTime.hasMatch);
      expect(times.length, greaterThanOrEqualTo(7));
    });

    testWidgets('a search with no match says so', (tester) async {
      await _open(tester, PrayerFixture());
      await tester.tap(find.text('اختر مدينة'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pumpAndSettle();
      expect(find.textContaining('لا توجد مدينة تطابق'), findsOneWidget);
    });

    testWidgets('western digits can be chosen', (tester) async {
      await _open(
        tester,
        PrayerFixture(saved: _savedCairo()),
        settings: const AppSettings(digits: DigitStyle.western),
      );
      final shown = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '');
      expect(shown.any(RegExp(r'^\d{1,2}:\d{2} [صم]$').hasMatch), isTrue);
      expect(shown.any(_arabicTime.hasMatch), isFalse);
    });
  });

  group('use my location', () {
    testWidgets(
      'explained first, then asked, then the place is "current location"',
      (tester) async {
        final f = PrayerFixture();
        await _open(tester, f);
        await tester.tap(find.text('استخدم موقعي'));
        await tester.pumpAndSettle();
        expect(find.text('استخدام موقعك؟'), findsOneWidget);
        expect(
          f.gateway.requested,
          isEmpty,
        ); // nothing asked before the user agrees
        await tester.tap(find.text('متابعة'));
        await tester.pumpAndSettle();
        expect(f.gateway.requested, [AppPermission.location]);
        expect(find.text('الموقع الحالي'), findsOneWidget);
        expect(f.location.reads, 1);
        expect(f.preferences.stored.location!.usesDeviceZone, isTrue);
      },
    );

    testWidgets('"not now" asks for nothing and stays on the set-up', (
      tester,
    ) async {
      final f = PrayerFixture();
      await _open(tester, f);
      await tester.tap(find.text('استخدم موقعي'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ليس الآن'));
      await tester.pumpAndSettle();
      expect(find.text('حدّد موقعك'), findsOneWidget);
      expect(f.gateway.requested, isEmpty);
      expect(f.location.reads, 0);
      expect(find.text('اختر مدينة'), findsOneWidget);
    });

    testWidgets('a refusal explains and leaves the city choice open', (
      tester,
    ) async {
      final f = PrayerFixture();
      f.gateway.onRequest[AppPermission.location] = PermissionState.denied;
      await _open(tester, f);
      await tester.tap(find.text('استخدم موقعي'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();
      expect(find.textContaining('لم يُمنح إذن الموقع'), findsOneWidget);
      expect(find.text('اختر مدينة'), findsOneWidget);
    });

    testWidgets('permission turned off for good offers the settings page', (
      tester,
    ) async {
      final f = PrayerFixture();
      f.gateway.states[AppPermission.location] =
          PermissionState.permanentlyDenied;
      await _open(tester, f);
      await tester.tap(find.text('استخدم موقعي'));
      await tester.pumpAndSettle();
      expect(find.textContaining('إذن الموقع متوقف'), findsOneWidget);
      await tester.tap(find.text('فتح الإعدادات'));
      await tester.pumpAndSettle();
      expect(f.gateway.settingsOpened, 1);
    });
  });

  group('with a saved place', () {
    testWidgets('opens straight on the times', (tester) async {
      await _open(tester, PrayerFixture(saved: _savedCairo()));
      expect(find.text('القاهرة'), findsOneWidget);
      expect(find.text('حدّد موقعك'), findsNothing);
      expect(find.text('الصلاة التالية'), findsOneWidget);
    });

    testWidgets('the next prayer is the one after the current time', (
      tester,
    ) async {
      // 12:30 UTC = 14:30 in Cairo (winter time): Asr is next.
      final f = PrayerFixture(
        saved: _savedCairo(),
        now: DateTime.utc(2026, 4, 1, 12, 30),
      );
      await _open(tester, f);
      final banner = find.bySemanticsLabel(RegExp('الصلاة التالية: العصر'));
      expect(banner, findsOneWidget);
    });

    testWidgets('changing the location replaces the place and returns', (
      tester,
    ) async {
      final f = PrayerFixture(saved: _savedCairo());
      await _open(tester, f);
      await tester.tap(find.text('تغيير الموقع'));
      await tester.pumpAndSettle();
      expect(find.text('حدّد موقعك'), findsOneWidget);
      await tester.tap(find.text('اختر مدينة'));
      await tester.pumpAndSettle();
      await _pickCity(tester, 'نيويورك', 'نيويورك');
      expect(find.text('نيويورك'), findsOneWidget);
      expect(find.text('حدّد موقعك'), findsNothing);
      // The method that was proposed for Egypt stays.
      expect(find.text('الهيئة المصرية العامة للمساحة'), findsOneWidget);
    });

    testWidgets('the method page shows the numbers and the choice sticks', (
      tester,
    ) async {
      final f = PrayerFixture(saved: _savedCairo());
      await _open(tester, f);
      await tester.tap(find.text('الهيئة المصرية العامة للمساحة'));
      await tester.pumpAndSettle();
      expect(find.textContaining('الفجر ١٩٫٥°، العشاء ١٧٫٥°'), findsOneWidget);
      expect(find.textContaining('بعد المغرب بـ ٩٠ دقيقة'), findsOneWidget);
      await tester.tap(find.text('رابطة العالم الإسلامي'));
      await tester.pumpAndSettle();
      expect(
        f.preferences.stored.settings.method,
        CalculationMethodId.muslimWorldLeague,
      );
      expect(f.preferences.stored.methodOrigin, MethodOrigin.user);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.textContaining('اخترتَها أنت'), findsOneWidget);
    });

    testWidgets('a place with no possible times says so', (tester) async {
      final f = PrayerFixture(
        saved: PrayerPreferences().withLocation(
          PrayerLocation(
            point: GeoPoint(78.22, 15.63),
            source: LocationSource.manual,
            zoneId: 'Europe/Oslo',
            name: 'أقصى الشمال',
            countryCode: 'NO',
          ),
        ),
        now: DateTime.utc(2026, 6, 21, 10),
      );
      await _open(tester, f);
      expect(find.text('تعذّر حساب المواقيت لهذا المكان.'), findsOneWidget);
    });
  });

  group('accessibility and layout', () {
    for (final locale in ['ar', 'en']) {
      for (final theme in [ThemePreference.light, ThemePreference.dark]) {
        testWidgets(
          'the times page meets the guidelines in $locale / ${theme.name}',
          (tester) async {
            final handle = tester.ensureSemantics();
            await _open(
              tester,
              PrayerFixture(saved: _savedCairo()),
              locale: locale,
              settings: AppSettings(theme: theme),
            );
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

    testWidgets('the set-up page meets the guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, PrayerFixture());
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    for (final scale in [1.3, 2.0]) {
      testWidgets('no overflow at ${(scale * 100).round()}% text', (
        tester,
      ) async {
        useSmallPhone(tester, textScale: scale);
        final f = PrayerFixture(saved: _savedCairo());
        await _open(tester, f, tall: false);
        expect(tester.takeException(), isNull);
        await scrollAndTap(tester, find.text('الهيئة المصرية العامة للمساحة'));
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('تغيير الموقع'), -300);
        await tester.pumpAndSettle();
        await tester.tap(find.text('تغيير الموقع'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
