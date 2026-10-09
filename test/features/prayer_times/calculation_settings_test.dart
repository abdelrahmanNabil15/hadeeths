import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/features/prayer_times/data/adhan_prayer_times_calculator.dart';
import 'package:mynewapp/features/prayer_times/domain/calculation_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';

void main() {
  group('settings', () {
    test('defaults are explicit and visible', () {
      final s = CalculationSettings();
      expect(s.method, CalculationSettings.defaultMethod);
      expect(s.madhab, Madhab.shafii);
      expect(s.highLatitudeRule, HighLatitudeRule.middleOfTheNight);
      expect(s.adjustments, isEmpty);
    });

    test('zero adjustments are not kept, so equal settings compare equal', () {
      expect(
        CalculationSettings(adjustments: {Prayer.fajr: 0, Prayer.asr: 0}),
        CalculationSettings(),
      );
      expect(
        CalculationSettings(adjustments: {Prayer.fajr: 2}),
        isNot(CalculationSettings()),
      );
    });

    test('adjustments beyond 30 minutes are refused', () {
      expect(
        () => CalculationSettings(adjustments: {Prayer.isha: 31}),
        throwsRangeError,
      );
      expect(
        () => CalculationSettings(adjustments: {Prayer.isha: -31}),
        throwsRangeError,
      );
      expect(
        CalculationSettings(
          adjustments: {Prayer.isha: 30},
        ).adjustmentFor(Prayer.isha),
        30,
      );
    });

    test('adjustments cannot be changed after the fact', () {
      final s = CalculationSettings(adjustments: {Prayer.fajr: 1});
      expect(() => s.adjustments[Prayer.fajr] = 5, throwsUnsupportedError);
    });

    test('copyWith changes only what is asked', () {
      final s = CalculationSettings(
        method: CalculationMethodId.karachi,
        adjustments: {Prayer.fajr: 3},
      ).copyWith(madhab: Madhab.hanafi);
      expect(s.method, CalculationMethodId.karachi);
      expect(s.madhab, Madhab.hanafi);
      expect(s.adjustmentFor(Prayer.fajr), 3);
    });
  });

  group('what the user is told about each method matches the calculation', () {
    for (final id in CalculationMethodId.values) {
      test(id.name, () {
        final info = methodInfo[id]!;
        final p = AdhanPrayerTimesCalculator.parametersFor(
          CalculationSettings(method: id),
        );
        expect(p.fajrAngle, info.fajrAngle);
        if (info.ishaIntervalMinutes != null) {
          expect(p.ishaInterval, info.ishaIntervalMinutes);
        } else {
          expect(p.ishaAngle, info.ishaAngle);
          expect(p.ishaInterval ?? 0, 0);
        }
        expect(
          p.methodAdjustments[adhan.Prayer.dhuhr] ?? 0,
          info.dhuhrOffsetMinutes,
        );
      });
    }

    test('every method has a description', () {
      expect(methodInfo.keys.toSet(), CalculationMethodId.values.toSet());
    });
  });

  group('settings reach the library unchanged', () {
    test('madhab, high-latitude rule and manual adjustments', () {
      final p = AdhanPrayerTimesCalculator.parametersFor(
        CalculationSettings(
          madhab: Madhab.hanafi,
          highLatitudeRule: HighLatitudeRule.twilightAngle,
          adjustments: {Prayer.fajr: -2, Prayer.maghrib: 3},
        ),
      );
      expect(p.madhab, adhan.Madhab.hanafi);
      expect(p.highLatitudeRule, adhan.HighLatitudeRule.twilightAngle);
      expect(p.adjustments[adhan.Prayer.fajr], -2);
      expect(p.adjustments[adhan.Prayer.maghrib], 3);
      expect(p.adjustments[adhan.Prayer.isha], 0);
    });
  });

  group('geo point', () {
    test('rejects impossible coordinates', () {
      expect(() => GeoPoint(91, 0), throwsRangeError);
      expect(() => GeoPoint(-91, 0), throwsRangeError);
      expect(() => GeoPoint(0, 181), throwsRangeError);
      expect(() => GeoPoint(double.nan, 0), throwsRangeError);
    });

    test('rounding keeps about a kilometre', () {
      expect(GeoPoint(30.04442, 31.23571).rounded(), GeoPoint(30.04, 31.24));
      expect(GeoPoint(30.04442, 31.23571).rounded(3), GeoPoint(30.044, 31.236));
    });

    test('never prints the position', () {
      expect('${GeoPoint(30.0444, 31.2357)}', isNot(contains('30')));
    });
  });
}
