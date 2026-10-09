import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/heading_calculator.dart';
import 'package:mynewapp/features/prayer_times/domain/qibla.dart';
import 'package:mynewapp/features/prayer_times/domain/world_magnetic_model.dart';
import 'package:mynewapp/features/prayer_times/presentation/state/qibla_compass_cubit.dart';

import '../../../support/compass_support.dart';
import '../../../support/prayer_fakes.dart';

// Cairo's city centre, as the app stores it.
final _cairo = GeoPoint(30.06, 31.25);

void main() {
  late PrayerFixture f;
  late double declination;
  late double expectedField;
  late double bearing;

  setUp(() {
    f = PrayerFixture(now: DateTime.utc(2026, 10, 9, 10));
    final year = WorldMagneticModel.decimalYearOf(f.clock.now());
    final field = realMagneticModel().at(
      latitude: _cairo.latitude,
      longitude: _cairo.longitude,
      decimalYear: year,
    );
    declination = field.declination;
    expectedField = field.total / 1000;
    bearing = Qibla.bearing(_cairo)!;
  });

  QiblaCompassCubit cubit({Duration? timeout}) => QiblaCompassCubit(
    services: f.services,
    place: _cairo,
    qiblaBearing: bearing,
    startTimeout: timeout ?? const Duration(seconds: 4),
  );

  /// A sample for a phone whose true heading is [trueHeading].
  CompassSample sampleFacing(double trueHeading, {double? fieldScale}) {
    final magnetic = HeadingCalculator.wrap360(trueHeading - declination);
    return simulate(
      heading: magnetic,
      field: expectedField * (fieldScale ?? 1),
      dip: 40,
    );
  }

  test('the sensors are not touched until the compass is started', () async {
    final c = cubit();
    expect(c.state.status, CompassStatus.off);
    expect(f.compass.starts, 0);
    await c.close();
  });

  test(
    'starting shows "starting", then a heading with the magnetic correction applied',
    () async {
      final c = cubit();
      await c.start();
      expect(c.state.status, CompassStatus.starting);
      expect(f.compass.starts, 1);
      f.compass.emit(sampleFacing(100));
      await Future<void>.delayed(Duration.zero);
      expect(c.state.status, CompassStatus.active);
      expect(c.state.trueHeading, closeTo(100, 0.01));
      expect(c.state.declination, closeTo(declination, 1e-9));
      await c.close();
    },
  );

  test('how far to turn, and to which side', () async {
    final c = cubit();
    await c.start();
    f.compass.emit(sampleFacing(bearing - 40));
    await Future<void>.delayed(Duration.zero);
    expect(c.state.turn, closeTo(40, 0.01)); // turn right
    expect(c.state.aligned, isFalse);
    await c.close();

    final left = cubit();
    final f2 = f;
    await left.start();
    f2.compass.emit(sampleFacing(bearing + 25));
    await Future<void>.delayed(Duration.zero);
    expect(left.state.turn, closeTo(-25, 0.01)); // turn left
    await left.close();
  });

  test('facing the Qibla within five degrees counts as aligned', () async {
    final c = cubit();
    await c.start();
    f.compass.emit(sampleFacing(bearing + 4));
    await Future<void>.delayed(Duration.zero);
    expect(c.state.aligned, isTrue);
    await c.close();
  });

  test('just outside five degrees is not aligned', () async {
    final c = cubit();
    await c.start();
    f.compass.emit(sampleFacing(bearing + 8));
    await Future<void>.delayed(Duration.zero);
    expect(c.state.aligned, isFalse);
    await c.close();
  });

  test('works from the other side of north', () async {
    final c = cubit();
    await c.start();
    f.compass.emit(sampleFacing(350));
    await Future<void>.delayed(Duration.zero);
    // Bearing is about 136: turning from 350 is 146 to the right.
    expect(c.state.turn, closeTo(Qibla.relativeTurn(bearing, 350), 0.01));
    expect(c.state.turn!.abs(), lessThanOrEqualTo(180));
    await c.close();
  });

  group('interference', () {
    test('a normal field is fine', () async {
      final c = cubit();
      await c.start();
      f.compass.emit(sampleFacing(100));
      await Future<void>.delayed(Duration.zero);
      expect(c.state.interference, isFalse);
      await c.close();
    });

    test('a field far stronger than the Earth\'s is flagged', () async {
      final c = cubit();
      await c.start();
      f.compass.emit(sampleFacing(100, fieldScale: 3));
      await Future<void>.delayed(Duration.zero);
      expect(c.state.interference, isTrue);
      await c.close();
    });

    test(
      'a disturbed reading is never called aligned, even when it points at the Qibla',
      () async {
        final c = cubit();
        await c.start();
        f.compass.emit(sampleFacing(bearing, fieldScale: 3));
        await Future<void>.delayed(Duration.zero);
        expect(c.state.interference, isTrue);
        expect(c.state.aligned, isFalse);
        await c.close();
      },
    );

    test('a field far weaker is flagged too', () async {
      final c = cubit();
      await c.start();
      f.compass.emit(sampleFacing(100, fieldScale: 0.3));
      await Future<void>.delayed(Duration.zero);
      expect(c.state.interference, isTrue);
      await c.close();
    });
  });

  group('stopping', () {
    test('stop releases the sensors and returns to off', () async {
      final c = cubit();
      await c.start();
      f.compass.emit(sampleFacing(100));
      await Future<void>.delayed(Duration.zero);
      await c.stop();
      expect(c.state.status, CompassStatus.off);
      expect(f.compass.running, isFalse);
      expect(f.compass.stops, 1);
      await c.close();
    });

    test('closing the cubit also releases them', () async {
      final c = cubit();
      await c.start();
      await c.close();
      expect(f.compass.running, isFalse);
    });

    test('it can be started again after a stop', () async {
      final c = cubit();
      await c.start();
      await c.stop();
      await c.start();
      expect(f.compass.starts, 2);
      f.compass.emit(sampleFacing(10));
      await Future<void>.delayed(Duration.zero);
      expect(c.state.status, CompassStatus.active);
      await c.close();
    });

    test('starting twice listens once', () async {
      final c = cubit();
      await c.start();
      await c.start();
      expect(f.compass.starts, 1);
      await c.close();
    });
  });

  group('when it cannot work', () {
    test(
      'a sensor error means unavailable, and the sensors are released',
      () async {
        f.compass.failWith = StateError('no magnetometer');
        final c = cubit();
        await c.start();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(c.state.status, CompassStatus.unavailable);
        expect(f.compass.running, isFalse);
        await c.close();
      },
    );

    test('no reading within the time limit means unavailable', () async {
      final c = cubit(timeout: const Duration(milliseconds: 40));
      await c.start();
      expect(c.state.status, CompassStatus.starting);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(c.state.status, CompassStatus.unavailable);
      expect(f.compass.running, isFalse);
      await c.close();
    });

    test('readings that cannot give a heading are ignored', () async {
      final c = cubit();
      await c.start();
      f.compass.emit(
        const CompassSample(
          acceleration: Vector3(0, 0, 0),
          magneticField: Vector3(0, 30, -30),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(c.state.status, CompassStatus.starting);
      await c.close();
    });

    test(
      'after the model\'s five years the compass is not offered and no sensor starts',
      () async {
        final late = PrayerFixture(now: DateTime.utc(2031, 1, 1));
        final c = QiblaCompassCubit(
          services: late.services,
          place: _cairo,
          qiblaBearing: bearing,
        );
        await c.start();
        expect(c.state.status, CompassStatus.modelExpired);
        expect(late.compass.starts, 0);
        await c.close();
      },
    );

    test('before the model\'s epoch it is not offered either', () async {
      final early = PrayerFixture(now: DateTime.utc(2024, 6, 1));
      final c = QiblaCompassCubit(
        services: early.services,
        place: _cairo,
        qiblaBearing: bearing,
      );
      await c.start();
      expect(c.state.status, CompassStatus.modelExpired);
      await c.close();
    });
  });

  test('the arrow is steady when the readings are steady', () async {
    final c = cubit();
    await c.start();
    final states = <QiblaCompassState>[];
    final sub = c.stream.listen(states.add);
    for (var i = 0; i < 30; i++) {
      f.compass.emit(sampleFacing(100));
      await Future<void>.delayed(Duration.zero);
    }
    await sub.cancel();
    // After the first reading nothing changes, so nothing is redrawn.
    expect(states.length, lessThanOrEqualTo(1));
    await c.close();
  });
}
