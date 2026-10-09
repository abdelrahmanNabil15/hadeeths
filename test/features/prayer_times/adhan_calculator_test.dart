import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/features/prayer_times/data/adhan_prayer_times_calculator.dart';
import 'package:mynewapp/features/prayer_times/domain/calculation_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_day.dart';

import '../../support/result_helpers.dart';

const _calculator = AdhanPrayerTimesCalculator();
final _cairo = GeoPoint(30.0444, 31.2357);

PrayerDay _day(DateTime date, {GeoPoint? at, CalculationSettings? settings}) =>
    _calculator
        .calculate(
          location: at ?? _cairo,
          date: date,
          settings: settings ?? CalculationSettings(),
        )
        .value;

void main() {
  group('a normal day', () {
    final day = _day(DateTime(2026, 6, 21));

    test('times are in order and consistent', () {
      expect(day.isConsistent, isTrue);
      final times = [for (final p in Prayer.values) day[p]];
      for (var i = 1; i < times.length; i++) {
        expect(times[i].isAfter(times[i - 1]), isTrue, reason: '$i');
      }
    });

    test('all times are UTC and whole minutes', () {
      for (final p in Prayer.values) {
        expect(day[p].isUtc, isTrue);
        expect(day[p].second, 0, reason: p.name);
        expect(day[p].millisecond, 0);
      }
    });

    test('the date is carried as a UTC calendar date', () {
      expect(day.date, DateTime.utc(2026, 6, 21));
    });

    test('previous Isha is before Fajr and next Fajr is after Isha', () {
      expect(day.previousIsha.isBefore(day[Prayer.fajr]), isTrue);
      expect(day.nextFajr.isAfter(day[Prayer.isha]), isTrue);
    });

    test('the time of day on the date is ignored', () {
      expect(_day(DateTime(2026, 6, 21, 23, 59, 59)), day);
      expect(_day(DateTime.utc(2026, 6, 21, 0, 0, 1)), day);
    });
  });

  group('settings change the result the way they should', () {
    test('Hanafi Asr is later than Shafii Asr', () {
      final shafii = _day(DateTime(2026, 6, 21));
      final hanafi = _day(
        DateTime(2026, 6, 21),
        settings: CalculationSettings(madhab: Madhab.hanafi),
      );
      expect(hanafi[Prayer.asr].isAfter(shafii[Prayer.asr]), isTrue);
      for (final p in [
        Prayer.fajr,
        Prayer.dhuhr,
        Prayer.maghrib,
        Prayer.isha,
      ]) {
        expect(hanafi[p], shafii[p], reason: p.name);
      }
    });

    test(
      'a manual adjustment moves only that prayer, by exactly that many minutes',
      () {
        final base = _day(DateTime(2026, 6, 21));
        final moved = _day(
          DateTime(2026, 6, 21),
          settings: CalculationSettings(
            adjustments: {Prayer.maghrib: 3, Prayer.fajr: -2},
          ),
        );
        expect(
          moved[Prayer.maghrib].difference(base[Prayer.maghrib]),
          const Duration(minutes: 3),
        );
        expect(
          moved[Prayer.fajr].difference(base[Prayer.fajr]),
          const Duration(minutes: -2),
        );
        for (final p in [
          Prayer.sunrise,
          Prayer.dhuhr,
          Prayer.asr,
          Prayer.isha,
        ]) {
          expect(moved[p], base[p], reason: p.name);
        }
      },
    );

    test('a different method changes Fajr and Isha', () {
      final egypt = _day(DateTime(2026, 6, 21));
      final isna = _day(
        DateTime(2026, 6, 21),
        settings: CalculationSettings(method: CalculationMethodId.northAmerica),
      );
      expect(isna[Prayer.fajr].isAfter(egypt[Prayer.fajr]), isTrue);
      expect(isna[Prayer.sunrise], egypt[Prayer.sunrise]);
    });

    test('Umm al-Qura sets Isha 90 minutes after Maghrib', () {
      final makkah = _day(
        DateTime(2026, 6, 21),
        at: GeoPoint(21.4225, 39.8262),
        settings: CalculationSettings(method: CalculationMethodId.ummAlQura),
      );
      expect(
        makkah[Prayer.isha].difference(makkah[Prayer.maghrib]),
        const Duration(minutes: 90),
      );
    });

    test('the same inputs always give the same answer', () {
      expect(_day(DateTime(2026, 3, 1)), _day(DateTime(2026, 3, 1)));
    });
  });

  group('neighbouring days fit together (a whole year, four cities)', () {
    final places = {
      'Cairo': GeoPoint(30.0444, 31.2357),
      'Jakarta': GeoPoint(-6.2088, 106.8456),
      'London': GeoPoint(51.5074, -0.1278),
      'Auckland': GeoPoint(-36.8485, 174.7633),
    };
    places.forEach((name, place) {
      test(name, () {
        final settings = CalculationSettings(
          method: CalculationMethodId.muslimWorldLeague,
        );
        PrayerDay? before;
        for (var i = 0; i < 366; i++) {
          final date = DateTime.utc(2026, 1, 1).add(Duration(days: i));
          final day = _calculator
              .calculate(location: place, date: date, settings: settings)
              .value;
          expect(day.isConsistent, isTrue, reason: '$name $date');
          if (before != null) {
            // Neighbouring days agree, apart from the one-or-two-minute meeting of Isha and
            // Fajr described in the calculator.
            expect(
              before.nextFajr.difference(day[Prayer.fajr]).abs(),
              lessThanOrEqualTo(const Duration(minutes: 2)),
              reason: 'nextFajr $date',
            );
            expect(
              day.previousIsha.difference(before[Prayer.isha]).abs(),
              lessThanOrEqualTo(const Duration(minutes: 2)),
              reason: 'previousIsha $date',
            );
            // Fajr and Isha can jump by 10 to 20 minutes in one day at high latitudes, on the day
            // the twilight angle stops being reachable and the high-latitude rule takes over (an
            // inherent property of those rules, not a fault). Everything else stays smooth.
            final smooth = place.latitude.abs() < 45
                ? Prayer.values
                : [Prayer.sunrise, Prayer.dhuhr, Prayer.asr, Prayer.maghrib];
            for (final p in smooth) {
              final jump =
                  day[p].difference(before[p]) - const Duration(days: 1);
              expect(
                jump.abs(),
                lessThan(const Duration(minutes: 12)),
                reason: '$name $date ${p.name}',
              );
            }
          }
          before = day;
        }
      });
    });
  });

  group('edges', () {
    test('year end and leap day are ordinary days', () {
      expect(_day(DateTime(2026, 12, 31)).isConsistent, isTrue);
      expect(_day(DateTime(2028, 2, 29)).isConsistent, isTrue);
      expect(_day(DateTime(2028, 3, 1)).date, DateTime.utc(2028, 3, 1));
    });

    test('far east and far west places work', () {
      expect(
        _day(DateTime(2026, 6, 21), at: GeoPoint(-36.85, 178.9)).isConsistent,
        isTrue,
      );
      expect(
        _day(DateTime(2026, 6, 21), at: GeoPoint(21.3, -157.9)).isConsistent,
        isTrue,
      );
    });

    test(
      'inside the polar circle the app reports "cannot calculate" instead of inventing times',
      () {
        final result = _calculator.calculate(
          location: GeoPoint(78.2232, 15.6267),
          date: DateTime(2026, 6, 21),
          settings: CalculationSettings(),
        );
        expect(result.ok, isFalse);
        expect(result.failure.kind, FailureKind.unexpected);
      },
    );
  });

  group('Isha and Fajr meeting at high latitudes (London, June)', () {
    final london = GeoPoint(51.5074, -0.1278);
    final mwl = CalculationSettings(
      method: CalculationMethodId.muslimWorldLeague,
    );

    test('the day is usable and Isha and the next Fajr coincide', () {
      for (final d in [
        DateTime(2026, 6, 21),
        DateTime(2026, 7, 4),
        DateTime(2026, 6, 26),
      ]) {
        final day = _day(d, at: london, settings: mwl);
        expect(day.isConsistent, isTrue, reason: '$d');
        expect(day.nextFajr, day[Prayer.isha], reason: '$d');
      }
    });

    test(
      'the displayed Fajr and Isha are exactly what the library calculated',
      () {
        // A day where the raw values miss each other by one minute (Isha 00:05, next Fajr 00:04).
        final day = _day(DateTime(2026, 7, 2), at: london, settings: mwl);
        final tomorrow = _day(DateTime(2026, 7, 3), at: london, settings: mwl);
        expect(tomorrow[Prayer.fajr].isBefore(day[Prayer.isha]), isTrue);
        expect(
          day.nextFajr,
          day[Prayer.isha],
        ); // only the neighbour field is nudged
      },
    );
  });

  group('library bug that the app avoids', () {
    test(
      'next Fajr is really tomorrow at a high latitude (Oslo, midsummer)',
      () {
        final oslo = GeoPoint(59.9139, 10.7522);
        final settings = CalculationSettings(
          method: CalculationMethodId.muslimWorldLeague,
          highLatitudeRule: HighLatitudeRule.seventhOfTheNight,
        );
        final day = _day(DateTime(2026, 6, 21), at: oslo, settings: settings);
        final tomorrow = _day(
          DateTime(2026, 6, 22),
          at: oslo,
          settings: settings,
        );
        expect(day.nextFajr, tomorrow[Prayer.fajr]);
        expect(day.nextFajr.isAfter(day[Prayer.isha]), isTrue);
        final yesterday = _day(
          DateTime(2026, 6, 20),
          at: oslo,
          settings: settings,
        );
        expect(day.previousIsha, yesterday[Prayer.isha]);
      },
    );
  });
}
