import 'dart:convert';
import 'dart:io';

import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/qibla.dart';

void main() {
  final fixture =
      jsonDecode(
            File(
              'test/features/prayer_times/fixtures/reference_qibla.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final cases = (fixture['cases'] as List).cast<Map<String, dynamic>>();

  group('against an independent implementation (Aladhan API, 2026-10-09)', () {
    for (final c in cases) {
      test('${c['name']}', () {
        final from = GeoPoint(
          (c['latitude'] as num).toDouble(),
          (c['longitude'] as num).toDouble(),
        );
        final want = (c['bearing'] as num).toDouble();
        final got = Qibla.bearing(from)!;
        final off = Qibla.relativeTurn(got, want).abs();
        expect(
          off,
          lessThan(0.05),
          reason: '${c['name']}: got $got want $want',
        );
      });
    }
  });

  group('against the calculation library', () {
    for (final c in cases) {
      test('${c['name']}', () {
        final lat = (c['latitude'] as num).toDouble();
        final lon = (c['longitude'] as num).toDouble();
        final library = adhan.Qibla.qibla(adhan.Coordinates(lat, lon));
        final ours = Qibla.bearing(GeoPoint(lat, lon))!;
        expect(
          Qibla.relativeTurn(ours, library).abs(),
          lessThan(0.5),
          reason: '${c['name']}',
        );
      });
    }
  });

  group('geometry', () {
    test('due north of Makkah the Qibla is due south (180)', () {
      expect(
        Qibla.bearing(GeoPoint(45, Qibla.kaaba.longitude))!,
        closeTo(180, 1e-6),
      );
    });

    test('due south of Makkah the Qibla is due north (0)', () {
      final b = Qibla.bearing(GeoPoint(-20, Qibla.kaaba.longitude))!;
      expect(Qibla.relativeTurn(b, 0).abs(), lessThan(1e-6));
    });

    test('on the equator west of Makkah it points a little north of east', () {
      final b = Qibla.bearing(GeoPoint(0, 0))!;
      expect(b, inExclusiveRange(0, 90));
    });

    test('on the equator east of Makkah it points a little north of west', () {
      final b = Qibla.bearing(GeoPoint(0, 100))!;
      expect(b, inExclusiveRange(270, 360));
    });

    test('across the date line the short way is chosen', () {
      // From Fiji (east of the date line) Makkah is to the west.
      final b = Qibla.bearing(GeoPoint(-18, 179))!;
      expect(b, inExclusiveRange(240, 300));
      final east = Qibla.bearing(GeoPoint(-18, -179))!;
      expect(east, inExclusiveRange(240, 300));
    });

    test('always within 0 to 360', () {
      for (var lat = -90.0; lat <= 90; lat += 15) {
        for (var lon = -180.0; lon <= 180; lon += 20) {
          final b = Qibla.bearing(GeoPoint(lat, lon));
          if (b != null) expect(b, inInclusiveRange(0, 360));
        }
      }
    });

    test('standing at the Kaaba there is no direction', () {
      expect(Qibla.bearing(Qibla.kaaba), isNull);
      expect(Qibla.bearing(GeoPoint(21.4226, 39.8262)), isNull);
      expect(Qibla.bearing(GeoPoint(21.43, 39.83)), isNotNull);
    });

    test('distance: zero here, half the Earth at the antipode, symmetric', () {
      expect(Qibla.distanceMetres(Qibla.kaaba), closeTo(0, 1));
      final antipode = GeoPoint(
        -Qibla.kaaba.latitude,
        Qibla.kaaba.longitude - 180,
      );
      expect(
        Qibla.distanceMetres(antipode),
        closeTo(3.14159265 * 6371008.8, 1000),
      );
    });

    test('the poles do not break it', () {
      for (final lat in [90.0, -90.0]) {
        final b = Qibla.bearing(GeoPoint(lat, 0));
        expect(b, isNotNull);
        expect(b!.isNaN, isFalse);
        expect(b, inInclusiveRange(0, 360));
      }
    });
  });

  group('turning to face it', () {
    test('relative turn is the short way round, -180 to 180', () {
      expect(Qibla.relativeTurn(90, 0), 90);
      expect(Qibla.relativeTurn(350, 10), -20);
      expect(Qibla.relativeTurn(10, 350), 20);
      expect(Qibla.relativeTurn(180, 0).abs(), 180);
      expect(Qibla.relativeTurn(45, 45), 0);
    });

    test(
      'a magnetic heading is corrected by the declination before comparing',
      () {
        expect(Qibla.trueHeading(350, 15), 5);
        expect(Qibla.trueHeading(10, -15), 355);
        expect(Qibla.trueHeading(100, 0), 100);
      },
    );

    test('normalising wraps any angle', () {
      expect(Qibla.normalizeDegrees(-10), 350);
      expect(Qibla.normalizeDegrees(370), 10);
      expect(Qibla.normalizeDegrees(360), 0);
      expect(Qibla.normalizeDegrees(0), 0);
    });
  });
}
