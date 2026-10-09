import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/features/prayer_times/data/adhan_prayer_times_calculator.dart';
import 'package:mynewapp/features/prayer_times/data/hijri_core_converter.dart';
import 'package:mynewapp/features/prayer_times/domain/calculation_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/hijri_converter.dart';
import 'package:mynewapp/features/prayer_times/domain/hijri_date.dart';
import 'package:mynewapp/features/prayer_times/domain/hijri_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';

import '../../support/result_helpers.dart';

const _converter = HijriCoreConverter();

HijriDate? _umm(DateTime d, [int adjust = 0]) =>
    _converter.convert(d, HijriSettings(adjustmentDays: adjust));

/// Days between two dates counted on a flat year of 354 days and months of 29.5 days: only good
/// for judging "about the same day" between two calendars.
double _roughDays(HijriDate h) => h.year * 354 + h.month * 29.5 + h.day;

void main() {
  final fixture =
      jsonDecode(
            File(
              'test/features/prayer_times/fixtures/reference_hijri_uaq.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final cases = (fixture['cases'] as List).cast<Map<String, dynamic>>();

  group('Umm al-Qura against an independent implementation (Aladhan)', () {
    test('the fixture is large enough to mean something', () {
      expect(cases.length, greaterThanOrEqualTo(70));
    });

    test('every date matches exactly', () {
      final wrong = <String>[];
      for (final c in cases) {
        final got = _umm(DateTime.parse(c['gregorian'] as String));
        final want = HijriDate(
          year: c['year'] as int,
          month: c['month'] as int,
          day: c['day'] as int,
        );
        if (got != want) wrong.add('${c['gregorian']}: got $got want $want');
      }
      expect(wrong, isEmpty);
    });
  });

  group('Umm al-Qura details', () {
    test('1 Muharram 1448 is 16 June 2026', () {
      expect(
        _umm(DateTime.utc(2026, 6, 16)),
        const HijriDate(year: 1448, month: 1, day: 1),
      );
      expect(
        _umm(DateTime.utc(2026, 6, 15)),
        const HijriDate(year: 1447, month: 12, day: 29),
      );
    });

    test('only the calendar date counts, not the time or the zone', () {
      expect(
        _umm(DateTime(2026, 6, 16, 23, 59)),
        _umm(DateTime.utc(2026, 6, 16)),
      );
    });

    test('dates outside the tables are reported as unknown, not guessed', () {
      expect(_umm(DateTime.utc(1899, 12, 31)), isNull);
      expect(
        _umm(DateTime.utc(2077, 6, 1)),
        isNotNull,
      ); // still inside year 1500
      expect(_umm(DateTime.utc(2078, 1, 1)), isNull);
    });

    test('months have 29 or 30 days and follow each other (2025 to 2030)', () {
      HijriDate? before;
      for (
        var d = DateTime.utc(2025, 1, 1);
        d.isBefore(DateTime.utc(2031, 1, 1));
        d = d.add(const Duration(days: 1))
      ) {
        final h = _umm(d)!;
        expect(h.day, inInclusiveRange(1, 30));
        if (before != null) {
          final sameMonth = h.year == before.year && h.month == before.month;
          if (sameMonth) {
            expect(h.day, before.day + 1, reason: '$d');
          } else {
            expect(h.day, 1, reason: '$d');
            expect(before.day, anyOf(29, 30), reason: '$d');
            final nextMonth = before.month == 12
                ? (h.year == before.year + 1 && h.month == 1)
                : (h.year == before.year && h.month == before.month + 1);
            expect(nextMonth, isTrue, reason: '$d');
          }
        }
        before = h;
      }
    });
  });

  group('manual correction', () {
    test('moves the date by that many days, across a month end', () {
      final d = DateTime.utc(2026, 6, 16); // 1 Muharram 1448
      expect(_umm(d, 1), const HijriDate(year: 1448, month: 1, day: 2));
      expect(_umm(d, -1), const HijriDate(year: 1447, month: 12, day: 29));
      expect(_umm(d, 2), const HijriDate(year: 1448, month: 1, day: 3));
      expect(_umm(d, -2), const HijriDate(year: 1447, month: 12, day: 28));
    });

    test('is limited to two days either way', () {
      expect(() => HijriSettings(adjustmentDays: 3), throwsRangeError);
      expect(() => HijriSettings(adjustmentDays: -3), throwsRangeError);
      expect(HijriSettings(adjustmentDays: 2).adjustmentDays, 2);
    });

    test('works across a Gregorian month end', () {
      expect(
        _umm(DateTime.utc(2026, 6, 30), 1),
        _umm(DateTime.utc(2026, 7, 1)),
      );
    });
  });

  group('FCNA (calculated), not yet checked against an official table', () {
    final fcna = HijriSettings(reference: HijriReference.fcna);
    HijriDate f(DateTime d) => _converter.convert(d, fcna)!;

    test('is consistent: months of 29 or 30 days following each other', () {
      HijriDate? before;
      for (
        var d = DateTime.utc(2025, 1, 1);
        d.isBefore(DateTime.utc(2031, 1, 1));
        d = d.add(const Duration(days: 1))
      ) {
        final h = f(d);
        if (before != null) {
          if (h.year == before.year && h.month == before.month) {
            expect(h.day, before.day + 1, reason: '$d');
          } else {
            expect(h.day, 1, reason: '$d');
            expect(before.day, anyOf(29, 30), reason: '$d');
          }
        }
        before = h;
      }
    });

    test('stays within about two days of Umm al-Qura', () {
      for (
        var d = DateTime.utc(2025, 1, 1);
        d.isBefore(DateTime.utc(2030, 1, 1));
        d = d.add(const Duration(days: 1))
      ) {
        final diff = _roughDays(f(d)) - _roughDays(_umm(d)!);
        expect(diff.abs(), lessThanOrEqualTo(3), reason: '$d');
      }
    });

    test('has no 1500 limit', () {
      expect(_converter.convert(DateTime.utc(2100, 1, 1), fcna), isNotNull);
    });
  });

  group('the Hijri day starts at sunset', () {
    final day = const AdhanPrayerTimesCalculator()
        .calculate(
          location: GeoPoint(30.0444, 31.2357),
          date: DateTime.utc(2026, 6, 21),
          settings: CalculationSettings(),
        )
        .value;
    final settings = HijriSettings();

    HijriDate? at(DateTime now, [HijriSettings? s]) => hijriDateAt(
      converter: _converter,
      settings: s ?? settings,
      day: day,
      now: now,
    );

    test('before Maghrib it is the date of the calendar day', () {
      expect(
        at(day[Prayer.maghrib].subtract(const Duration(minutes: 1))),
        const HijriDate(year: 1448, month: 1, day: 6),
      );
      expect(
        at(day[Prayer.fajr]),
        const HijriDate(year: 1448, month: 1, day: 6),
      );
    });

    test('from Maghrib it is the next date', () {
      expect(
        at(day[Prayer.maghrib]),
        const HijriDate(year: 1448, month: 1, day: 7),
      );
      expect(
        at(day[Prayer.isha]),
        const HijriDate(year: 1448, month: 1, day: 7),
      );
    });

    test('the manual correction applies on top', () {
      expect(
        at(day[Prayer.maghrib], HijriSettings(adjustmentDays: 1)),
        const HijriDate(year: 1448, month: 1, day: 8),
      );
    });
  });
}
