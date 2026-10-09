import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/features/prayer_times/domain/world_magnetic_model.dart';

/// The model against the 100 test points that NOAA publishes with the coefficients
/// (`WMM2025_TestValues.txt`): date, height, latitude, longitude, then declination, inclination,
/// H, X, Y, Z and F.
void main() {
  final model = WorldMagneticModel.parse(
    File('assets/data/wmm2025.cof').readAsStringSync(),
  );
  final rows = [
    for (final line in File(
      'test/features/prayer_times/fixtures/wmm2025_test_values.txt',
    ).readAsLinesSync())
      if (line.trim().isNotEmpty && !line.startsWith('#'))
        [
          for (final part in line.trim().split(RegExp(r'\s+')))
            double.parse(part),
        ],
  ];

  test('the coefficient file is the 2025 model', () {
    expect(model.epoch, 2025.0);
    expect(rows.length, 100);
  });

  test('every official point matches: X, Y and Z within 0.01 nT', () {
    var worst = 0.0;
    for (final r in rows) {
      final f = model.at(
        latitude: r[2],
        longitude: r[3],
        altitudeKm: r[1],
        decimalYear: r[0],
      );
      for (final (got, want, name) in [
        (f.north, r[7], 'X'),
        (f.east, r[8], 'Y'),
        (f.down, r[9], 'Z'),
      ]) {
        final off = (got - want).abs();
        if (off > worst) worst = off;
        expect(
          off,
          lessThan(0.01),
          reason: '$name at ${r[2]},${r[3]} year ${r[0]}: got $got want $want',
        );
      }
    }
    expect(worst, lessThan(0.01));
  });

  test('declination and inclination match the published values', () {
    for (final r in rows) {
      final f = model.at(
        latitude: r[2],
        longitude: r[3],
        altitudeKm: r[1],
        decimalYear: r[0],
      );
      expect(
        (f.declination - r[4]).abs(),
        lessThan(0.01),
        reason: 'D at ${r[2]},${r[3]}',
      );
      expect(
        (f.inclination - r[5]).abs(),
        lessThan(0.01),
        reason: 'I at ${r[2]},${r[3]}',
      );
      expect((f.horizontal - r[6]).abs(), lessThan(0.01), reason: 'H');
      expect((f.total - r[10]).abs(), lessThan(0.01), reason: 'F');
    }
  });

  group('for our users', () {
    test('Cairo in 2026 is a few degrees east', () {
      final f = model.at(
        latitude: 30.06,
        longitude: 31.25,
        decimalYear: 2026.77,
      );
      expect(f.declination, inInclusiveRange(3.0, 6.0));
    });

    test('Makkah in 2026 is a few degrees east', () {
      final f = model.at(
        latitude: 21.43,
        longitude: 39.83,
        decimalYear: 2026.77,
      );
      expect(f.declination, inInclusiveRange(2.0, 6.0));
    });

    test('London is within a few degrees of true north', () {
      final f = model.at(
        latitude: 51.5,
        longitude: -0.13,
        decimalYear: 2026.77,
      );
      expect(f.declination.abs(), lessThan(3));
    });

    test('New York is west, Seattle is east, as on any chart', () {
      expect(
        model
            .at(latitude: 40.71, longitude: -74.0, decimalYear: 2026.77)
            .declination,
        lessThan(-10),
      );
      expect(
        model
            .at(latitude: 47.6, longitude: -122.3, decimalYear: 2026.77)
            .declination,
        greaterThan(10),
      );
    });

    test('the exact poles do not break the calculation', () {
      for (final lat in [90.0, -90.0]) {
        final f = model.at(latitude: lat, longitude: 0, decimalYear: 2026.0);
        expect(f.north.isNaN, isFalse);
        expect(f.total, greaterThan(50000));
      }
    });
  });

  group('validity', () {
    test('five years from the epoch', () {
      expect(model.isValidAt(2025.0), isTrue);
      expect(model.isValidAt(2029.99), isTrue);
      expect(model.isValidAt(2024.99), isFalse);
      expect(model.isValidAt(2030.0), isFalse);
    });

    test('a date becomes a decimal year', () {
      expect(WorldMagneticModel.decimalYearOf(DateTime.utc(2026)), 2026.0);
      expect(
        WorldMagneticModel.decimalYearOf(DateTime.utc(2026, 7, 2, 12)),
        closeTo(2026.5, 0.002),
      );
      expect(
        WorldMagneticModel.decimalYearOf(DateTime.utc(2025, 12, 31, 23, 59)),
        lessThan(2026.0),
      );
    });
  });
}
