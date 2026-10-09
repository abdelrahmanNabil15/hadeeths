import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/features/prayer_times/domain/heading_calculator.dart';

import '../../support/compass_support.dart';

double _diff(double a, double b) {
  final d = (a - b) % 360;
  return (d > 180 ? d - 360 : d).abs();
}

void main() {
  group('flat or slightly tilted: the top edge points ahead', () {
    test('every heading, several tilts and several places on Earth', () {
      for (final dip in [0.0, 25.0, 55.0, -55.0, 70.0]) {
        for (var heading = 0.0; heading < 360; heading += 10) {
          for (final pitch in [-30.0, 0.0, 30.0]) {
            for (final roll in [-30.0, 0.0, 30.0]) {
              final got = HeadingCalculator.magneticHeading(
                simulate(heading: heading, pitch: pitch, roll: roll, dip: dip),
              );
              expect(got, isNotNull, reason: '$heading $pitch $roll $dip');
              expect(
                _diff(got!, heading),
                lessThan(1e-6),
                reason:
                    'heading $heading pitch $pitch roll $roll dip $dip: got $got',
              );
            }
          }
        }
      }
    });

    test('the four cardinal directions on a table', () {
      expect(
        HeadingCalculator.magneticHeading(simulate(heading: 0)),
        closeTo(0, 1e-6),
      );
      expect(
        HeadingCalculator.magneticHeading(simulate(heading: 90)),
        closeTo(90, 1e-6),
      );
      expect(
        HeadingCalculator.magneticHeading(simulate(heading: 180)),
        closeTo(180, 1e-6),
      );
      expect(
        HeadingCalculator.magneticHeading(simulate(heading: 270)),
        closeTo(270, 1e-6),
      );
    });

    test('the answer is in 0 up to 360', () {
      for (var h = 0.0; h < 360; h += 7) {
        final got = HeadingCalculator.magneticHeading(simulate(heading: h))!;
        expect(got, inInclusiveRange(0, 360));
      }
    });
  });

  group('held upright: the back of the phone points ahead', () {
    test('every heading at 80, 90 and 100 degrees of pitch', () {
      for (final pitch in [80.0, 90.0, 100.0]) {
        for (var heading = 0.0; heading < 360; heading += 15) {
          final got = HeadingCalculator.magneticHeading(
            simulate(heading: heading, pitch: pitch),
          );
          expect(got, isNotNull);
          expect(
            _diff(got!, heading),
            lessThan(1e-6),
            reason: '$heading $pitch',
          );
        }
      }
    });

    test('there is no jump when the phone passes 45 degrees of tilt', () {
      for (var heading = 0.0; heading < 360; heading += 30) {
        final below = HeadingCalculator.magneticHeading(
          simulate(heading: heading, pitch: 44),
        )!;
        final above = HeadingCalculator.magneticHeading(
          simulate(heading: heading, pitch: 46),
        )!;
        expect(_diff(below, above), lessThan(1e-6));
        expect(_diff(below, heading), lessThan(1e-6));
      }
    });
  });

  group('when it cannot be told', () {
    test('free fall: no gravity reading', () {
      final s = simulate(heading: 30);
      expect(
        HeadingCalculator.magneticHeading(
          CompassSample(
            acceleration: const Vector3(0, 0, 0),
            magneticField: s.magneticField,
          ),
        ),
        isNull,
      );
    });

    test('no magnetic field', () {
      final s = simulate(heading: 30);
      expect(
        HeadingCalculator.magneticHeading(
          CompassSample(
            acceleration: s.acceleration,
            magneticField: const Vector3(0, 0, 0),
          ),
        ),
        isNull,
      );
    });

    test('a field that points straight along gravity (the magnetic poles)', () {
      final s = simulate(heading: 30, dip: 90);
      expect(HeadingCalculator.magneticHeading(s), isNull);
    });

    test('a phone lying on its edge has no well-defined heading from the back', () {
      // Held with the top edge pointing at the ground and the back horizontal... the back axis is
      // then vertical-free, so a heading is found; with the screen facing straight up it is the
      // top edge. Both directions are exercised above; here the sensor noise must not crash it.
      final s = CompassSample(
        acceleration: const Vector3(9.81, 0.0001, 0.0001),
        magneticField: const Vector3(0, 30, -30),
      );
      expect(() => HeadingCalculator.magneticHeading(s), returnsNormally);
    });
  });

  group('wrap360', () {
    test('wraps both ways', () {
      expect(HeadingCalculator.wrap360(-10), 350);
      expect(HeadingCalculator.wrap360(370), 10);
      expect(HeadingCalculator.wrap360(360), 0);
      expect(HeadingCalculator.wrap360(0), 0);
    });
  });

  group('smoothing', () {
    test('the first reading passes through unchanged', () {
      final s = simulate(heading: 123);
      final out = CompassFilter().add(s);
      expect(out.acceleration.x, s.acceleration.x);
      expect(out.magneticField.y, s.magneticField.y);
    });

    test('steady input stays steady', () {
      final filter = CompassFilter();
      final s = simulate(heading: 200);
      CompassSample out = s;
      for (var i = 0; i < 20; i++) {
        out = filter.add(s);
      }
      expect(
        _diff(HeadingCalculator.magneticHeading(out)!, 200),
        lessThan(1e-6),
      );
    });

    test('noise is reduced', () {
      final rng = math.Random(7);
      final filter = CompassFilter();
      var rawWorst = 0.0;
      var smoothWorst = 0.0;
      for (var i = 0; i < 300; i++) {
        final clean = simulate(heading: 90);
        final noisy = CompassSample(
          acceleration: Vector3(
            clean.acceleration.x + rng.nextDouble() - 0.5,
            clean.acceleration.y + rng.nextDouble() - 0.5,
            clean.acceleration.z + rng.nextDouble() - 0.5,
          ),
          magneticField: Vector3(
            clean.magneticField.x + 4 * (rng.nextDouble() - 0.5),
            clean.magneticField.y + 4 * (rng.nextDouble() - 0.5),
            clean.magneticField.z + 4 * (rng.nextDouble() - 0.5),
          ),
        );
        final smooth = filter.add(noisy);
        if (i < 30) continue; // let the average settle
        rawWorst = math.max(
          rawWorst,
          _diff(HeadingCalculator.magneticHeading(noisy)!, 90),
        );
        smoothWorst = math.max(
          smoothWorst,
          _diff(HeadingCalculator.magneticHeading(smooth)!, 90),
        );
      }
      expect(smoothWorst, lessThan(rawWorst));
    });

    test('there is no jump when the heading crosses north', () {
      final filter = CompassFilter();
      double? last;
      for (var h = 350.0; h <= 370; h += 1) {
        final out = filter.add(simulate(heading: h % 360));
        final got = HeadingCalculator.magneticHeading(out)!;
        if (last != null) expect(_diff(got, last), lessThan(5));
        last = got;
      }
    });

    test('reset forgets the past', () {
      final filter = CompassFilter();
      filter.add(simulate(heading: 10));
      filter.reset();
      final s = simulate(heading: 200);
      final out = filter.add(s);
      expect(
        _diff(HeadingCalculator.magneticHeading(out)!, 200),
        lessThan(1e-6),
      );
    });
  });

  test('vectors never print their values', () {
    expect('${const Vector3(1, 2, 3)}', isNot(contains('1')));
  });
}
