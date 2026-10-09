import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/features/prayer_times/data/adhan_prayer_times_calculator.dart';
import 'package:mynewapp/features/prayer_times/domain/calculation_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';

import '../../support/result_helpers.dart';

/// The Egyptian method for Cairo against times that Egyptian newspapers published as the Egyptian
/// General Authority of Survey's timetable. A secondary source (see the fixture's `about`), so
/// this proves close agreement with what Egyptians were shown, not agreement with the primary
/// document. Tolerance: 2 minutes.
void main() {
  final fixture =
      jsonDecode(
            File(
              'test/features/prayer_times/fixtures/egsa_press_reports.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final point = GeoPoint(
    (fixture['latitude'] as num).toDouble(),
    (fixture['longitude'] as num).toDouble(),
  );

  for (final c in (fixture['cases'] as List).cast<Map<String, dynamic>>()) {
    test('Cairo ${c['date']} (Egyptian method)', () {
      final day = const AdhanPrayerTimesCalculator()
          .calculate(
            location: point,
            date: DateTime.parse(c['date'] as String),
            settings: CalculationSettings(method: CalculationMethodId.egyptian),
          )
          .value;
      final offset = Duration(hours: c['utcOffsetHours'] as int);
      final local = (c['local'] as Map).cast<String, String>();
      for (final entry in local.entries) {
        final prayer = Prayer.values.byName(entry.key);
        final shown = day[prayer].add(offset);
        final parts = entry.value.split(':');
        final want = DateTime.utc(
          shown.year,
          shown.month,
          shown.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
        expect(
          shown.difference(want).abs(),
          lessThanOrEqualTo(const Duration(minutes: 2)),
          reason: '${c['date']} ${entry.key}: app $shown, published $want',
        );
      }
    });
  }
}
