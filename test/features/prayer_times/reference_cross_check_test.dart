import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/features/prayer_times/data/adhan_prayer_times_calculator.dart';
import 'package:mynewapp/features/prayer_times/domain/calculation_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';

import '../../support/result_helpers.dart';

/// Compares the app's calculation with values from an independent implementation (the Aladhan
/// public API, retrieved 2026-10-09; see the fixture file). That service is a cross-check, not
/// an official authority: these tests prove the wrapper uses the library correctly and that
/// two independent programs agree, not that the times match any particular mosque.
///
/// Tolerance: 2 minutes per prayer. The library adds a one-minute margin to Dhuhr for most
/// methods, and sources round to whole minutes.
const _tolerance = Duration(minutes: 2);

void main() {
  final fixture =
      jsonDecode(
            File(
              'test/features/prayer_times/fixtures/reference_prayer_times.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final cases = (fixture['cases'] as List).cast<Map<String, dynamic>>();

  test('the fixture has the expected cases', () {
    expect(cases.length, greaterThanOrEqualTo(10));
    expect(fixture['retrieved'], isNotNull);
  });

  for (final c in cases) {
    test('${c['id']}: every time is within 2 minutes', () {
      final result = const AdhanPrayerTimesCalculator().calculate(
        location: GeoPoint(
          (c['latitude'] as num).toDouble(),
          (c['longitude'] as num).toDouble(),
        ),
        date: DateTime.parse(c['date'] as String),
        settings: CalculationSettings(
          method: CalculationMethodId.values.byName(c['method'] as String),
          madhab: c['madhab'] == 'hanafi' ? Madhab.hanafi : Madhab.shafii,
          highLatitudeRule: HighLatitudeRule.values.byName(
            c['highLatitudeRule'] as String,
          ),
        ),
      );
      final day = result.value;
      final expected = (c['timingsUtc'] as Map).cast<String, String>();
      for (final prayer in Prayer.values) {
        var want = DateTime.parse(expected[prayer.name]!);
        if (prayer == Prayer.asr && c['asrIndependentCheckUtc'] != null) {
          want = DateTime.parse(c['asrIndependentCheckUtc'] as String);
        }
        final off = day[prayer].difference(want).abs();
        expect(
          off,
          lessThanOrEqualTo(_tolerance),
          reason: '${c['id']} ${prayer.name}: got ${day[prayer]}, want $want',
        );
      }
    });
  }
}
