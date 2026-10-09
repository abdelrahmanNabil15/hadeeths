import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/heading_calculator.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';
import 'package:mynewapp/features/prayer_times/domain/qibla.dart';
import 'package:mynewapp/features/prayer_times/domain/world_magnetic_model.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';

import '../support/compass_support.dart';
import '../support/fake_backend.dart';
import '../support/prayer_fakes.dart';
import '../support/test_app.dart';

final _now = DateTime.utc(2026, 10, 9, 10);

PrayerPreferences _savedCairo() {
  final cairo = realCityCatalog().cities.firstWhere((c) => c.nameEn == 'Cairo');
  return PrayerPreferences().withLocation(cairo.toLocation('ar'));
}

/// What a phone facing [trueHeading] (degrees from true north) would read in Cairo.
CompassSample facing(double trueHeading, {double fieldScale = 1}) {
  final point = GeoPoint(30.06, 31.25);
  final field = realMagneticModel().at(
    latitude: point.latitude,
    longitude: point.longitude,
    decimalYear: WorldMagneticModel.decimalYearOf(_now),
  );
  return simulate(
    heading: HeadingCalculator.wrap360(trueHeading - field.declination),
    field: field.total / 1000 * fieldScale,
  );
}

final _bearing = Qibla.bearing(GeoPoint(30.06, 31.25))!;

Future<PrayerFixture> _openQibla(
  WidgetTester tester, {
  String locale = 'ar',
  AppSettings settings = const AppSettings(),
  bool tall = true,
  DateTime? now,
}) async {
  if (tall) {
    tester.view.physicalSize = const Size(700, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }
  final fixture = PrayerFixture(saved: _savedCairo(), now: now ?? _now);
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
  final tile = find.text(locale == 'ar' ? 'القبلة' : 'Qibla');
  if (!tall) await tester.scrollUntilVisible(tile, 300);
  await tester.tap(tile);
  await tester.pumpAndSettle();
  return fixture;
}

void main() {
  testWidgets('the sensors are off until the user asks', (tester) async {
    final f = await _openQibla(tester);
    expect(f.compass.starts, 0);
    expect(find.text('استخدم البوصلة'), findsOneWidget);
    expect(find.textContaining('حسّاسات الحركة'), findsOneWidget);
  });

  testWidgets('starting shows progress, then the instruction to turn right', (
    tester,
  ) async {
    final f = await _openQibla(tester);
    await tester.tap(find.text('استخدم البوصلة'));
    await tester.pump();
    expect(f.compass.starts, 1);
    expect(find.text('جارٍ قراءة البوصلة…'), findsOneWidget);
    f.compass.emit(facing(_bearing - 40));
    await tester.pump();
    await tester.pump();
    expect(find.text('استدر يمينًا ٤٠°'), findsOneWidget);
    expect(find.text('إيقاف البوصلة'), findsOneWidget);
    expect(find.textContaining('التصحيح من الشمال المغناطيسي'), findsOneWidget);
  });

  testWidgets('turn left, in English with Western digits', (tester) async {
    final f = await _openQibla(tester, locale: 'en');
    await tester.tap(find.text('Use the compass'));
    await tester.pump();
    f.compass.emit(facing(_bearing + 60));
    await tester.pump();
    await tester.pump();
    expect(find.text('Turn left 60°'), findsOneWidget);
  });

  testWidgets('facing the Qibla says so, with an icon as well as colour', (
    tester,
  ) async {
    final f = await _openQibla(tester);
    await tester.tap(find.text('استخدم البوصلة'));
    await tester.pump();
    f.compass.emit(facing(_bearing + 2));
    await tester.pump();
    await tester.pump();
    expect(find.text('أنت متجه نحو القبلة'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets(
    'lining up with the Qibla gives one short vibration, turning does not',
    (tester) async {
      final vibrations = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            vibrations.add(call.arguments as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final f = await _openQibla(tester);
      await tester.tap(find.text('استخدم البوصلة'));
      await tester.pump();
      f.compass.emit(facing(_bearing - 40));
      await tester.pump();
      await tester.pump();
      expect(vibrations, isEmpty);
      // The readings are averaged, so it takes a few steady ones to settle on the Qibla.
      for (var i = 0; i < 25; i++) {
        f.compass.emit(facing(_bearing + 1));
        await tester.pump();
      }
      await tester.pump();
      expect(vibrations, ['HapticFeedbackType.mediumImpact']);
      for (var i = 0; i < 5; i++) {
        f.compass.emit(facing(_bearing + 2));
        await tester.pump();
      }
      expect(vibrations, hasLength(1));
    },
  );

  testWidgets('the interference warning is a labelled, announced message', (
    tester,
  ) async {
    final f = await _openQibla(tester);
    await tester.tap(find.text('استخدم البوصلة'));
    await tester.pump();
    f.compass.emit(facing(_bearing - 40, fieldScale: 3));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    for (var i = 0; i < 25; i++) {
      f.compass.emit(facing(_bearing - 40));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });

  testWidgets('interference is reported in words', (tester) async {
    final f = await _openQibla(tester);
    await tester.tap(find.text('استخدم البوصلة'));
    await tester.pump();
    f.compass.emit(facing(_bearing - 40, fieldScale: 3));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('شيء قريب يؤثر في البوصلة'), findsOneWidget);
    // While it is disturbed there is no instruction and no claim of facing the Qibla.
    expect(find.text('البوصلة غير موثوقة هنا الآن'), findsOneWidget);
    expect(find.textContaining('استدر'), findsNothing);
    expect(find.text('أنت متجه نحو القبلة'), findsNothing);
  });

  testWidgets('a disturbed reading never says you are facing the Qibla', (
    tester,
  ) async {
    final f = await _openQibla(tester);
    await tester.tap(find.text('استخدم البوصلة'));
    await tester.pump();
    f.compass.emit(facing(_bearing, fieldScale: 3));
    await tester.pump();
    await tester.pump();
    expect(find.text('أنت متجه نحو القبلة'), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('stopping releases the sensors and brings the numbers back', (
    tester,
  ) async {
    final f = await _openQibla(tester);
    await tester.tap(find.text('استخدم البوصلة'));
    await tester.pump();
    f.compass.emit(facing(_bearing - 40));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('إيقاف البوصلة'));
    await tester.pumpAndSettle();
    expect(f.compass.running, isFalse);
    expect(find.text('استخدم البوصلة'), findsOneWidget);
    expect(find.text('١٣٦°'), findsOneWidget);
  });

  testWidgets('leaving the screen releases the sensors', (tester) async {
    final f = await _openQibla(tester);
    await tester.tap(find.text('استخدم البوصلة'));
    await tester.pump();
    f.compass.emit(facing(_bearing - 40));
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(f.compass.running, isFalse);
    expect(f.compass.stops, 1);
  });

  testWidgets('sending the app to the background releases the sensors', (
    tester,
  ) async {
    final f = await _openQibla(tester);
    await tester.tap(find.text('استخدم البوصلة'));
    await tester.pump();
    f.compass.emit(facing(_bearing - 40));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    await tester.pump();
    expect(f.compass.running, isFalse);
    // Coming back does not turn it on by itself.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(f.compass.running, isFalse);
    expect(find.text('استخدم البوصلة'), findsOneWidget);
  });

  testWidgets('no sensor: an honest message, and the direction still shows', (
    tester,
  ) async {
    final f = await _openQibla(tester);
    f.compass.failWith = StateError('none');
    await tester.tap(find.text('استخدم البوصلة'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      find.textContaining('لا يتوفر في هذا الهاتف حسّاس بوصلة'),
      findsOneWidget,
    );
    expect(find.text('١٣٦°'), findsOneWidget);
  });

  testWidgets('out-of-date magnetic data: the compass is not offered', (
    tester,
  ) async {
    final f = await _openQibla(tester, now: DateTime.utc(2031, 1, 1));
    await tester.tap(find.text('استخدم البوصلة'));
    await tester.pump();
    await tester.pump();
    expect(
      find.textContaining('بيانات التصحيح المغناطيسي قديمة'),
      findsOneWidget,
    );
    expect(find.text('استخدم البوصلة'), findsNothing);
    expect(f.compass.starts, 0);
  });

  testWidgets('a screen reader hears the instruction as a live region', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final f = await _openQibla(tester, locale: 'en');
    await tester.tap(find.text('Use the compass'));
    await tester.pump();
    f.compass.emit(facing(_bearing - 40));
    await tester.pump();
    await tester.pump();
    expect(find.bySemanticsLabel('Turn right 40°'), findsWidgets);
    handle.dispose();
  });

  group('accessibility and layout while the compass runs', () {
    for (final locale in ['ar', 'en']) {
      for (final theme in [ThemePreference.light, ThemePreference.dark]) {
        testWidgets('guidelines hold in $locale / ${theme.name}', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          final f = await _openQibla(
            tester,
            locale: locale,
            settings: AppSettings(theme: theme),
          );
          await tester.tap(
            find.text(locale == 'ar' ? 'استخدم البوصلة' : 'Use the compass'),
          );
          await tester.pump();
          f.compass.emit(facing(_bearing - 40, fieldScale: 3));
          await tester.pump();
          await tester.pump();
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          handle.dispose();
        });
      }
    }

    for (final scale in [1.3, 2.0]) {
      testWidgets('no overflow at ${(scale * 100).round()}% text', (
        tester,
      ) async {
        useSmallPhone(tester, textScale: scale);
        final f = await _openQibla(tester, tall: false);
        await tester.scrollUntilVisible(find.text('استخدم البوصلة'), 300);
        await tester.tap(find.text('استخدم البوصلة'));
        await tester.pump();
        f.compass.emit(facing(_bearing - 40, fieldScale: 3));
        await tester.pump();
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
