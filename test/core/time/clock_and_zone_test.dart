import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/time/clock.dart';
import 'package:mynewapp/core/time/zone.dart';

import '../../support/time_support.dart';

void main() {
  group('clock', () {
    test('the system clock is UTC and close to the real time', () {
      final now = const SystemClock().now();
      expect(now.isUtc, isTrue);
      expect(
        now.difference(DateTime.now().toUtc()).abs().inSeconds,
        lessThan(5),
      );
    });

    test('a fake clock only moves when told to', () {
      final clock = FakeClock(DateTime.utc(2026, 1, 1));
      expect(clock.now(), DateTime.utc(2026, 1, 1));
      clock.advance(const Duration(hours: 5));
      expect(clock.now(), DateTime.utc(2026, 1, 1, 5));
    });
  });

  group('wall clock helpers', () {
    const cairo = FixedOffsetZone(Duration(hours: 2));

    test('local date and minute follow the offset', () {
      final instant = DateTime.utc(
        2026,
        6,
        30,
        22,
        30,
      ); // 00:30 next day in UTC+2
      expect(cairo.localDateAt(instant), DateTime.utc(2026, 7, 1));
      expect(cairo.minuteOfDayAt(instant), 30);
    });

    test('negative offsets work', () {
      const ny = FixedOffsetZone(Duration(hours: -5));
      final instant = DateTime.utc(2026, 1, 1, 3, 0);
      expect(ny.localDateAt(instant), DateTime.utc(2025, 12, 31));
      expect(ny.minuteOfDayAt(instant), 22 * 60);
    });

    test('an ordinary local time maps to one instant and back', () {
      final wall = DateTime.utc(2026, 6, 1, 14, 20);
      final utc = cairo.utcFromWallClock(wall);
      expect(utc, DateTime.utc(2026, 6, 1, 12, 20));
      expect(cairo.wallClockAt(utc), wall);
    });
  });

  group('daylight saving', () {
    final zone = europeLikeZone();

    test('offsets change at the scripted instants', () {
      expect(zone.offsetAt(DateTime.utc(2026, 3, 29, 0, 59)), Duration.zero);
      expect(
        zone.offsetAt(DateTime.utc(2026, 3, 29, 1)),
        const Duration(hours: 1),
      );
      expect(zone.offsetAt(DateTime.utc(2026, 10, 25, 1)), Duration.zero);
    });

    test('a time that does not exist lands after the gap', () {
      // On 2026-03-29 the wall clock jumps from 01:00 to 02:00, so 01:30 never happens.
      final utc = zone.utcFromWallClock(DateTime.utc(2026, 3, 29, 1, 30));
      expect(utc, DateTime.utc(2026, 3, 29, 1, 30));
      expect(zone.wallClockAt(utc), DateTime.utc(2026, 3, 29, 2, 30));
    });

    test('a time that happens twice maps to its first occurrence', () {
      // On 2026-10-25 the wall clock goes from 02:00 back to 01:00, so 01:30 happens twice:
      // at 00:30 UTC (summer time) and at 01:30 UTC (winter time).
      final utc = zone.utcFromWallClock(DateTime.utc(2026, 10, 25, 1, 30));
      expect(utc, DateTime.utc(2026, 10, 25, 0, 30));
    });

    test('times on either side of a change convert correctly', () {
      expect(
        zone.utcFromWallClock(DateTime.utc(2026, 3, 29, 12)),
        DateTime.utc(2026, 3, 29, 11),
      );
      expect(
        zone.utcFromWallClock(DateTime.utc(2026, 3, 28, 12)),
        DateTime.utc(2026, 3, 28, 12),
      );
      expect(
        zone.utcFromWallClock(DateTime.utc(2026, 10, 25, 12)),
        DateTime.utc(2026, 10, 25, 12),
      );
    });

    test('a spring-forward day is 23 hours long', () {
      final start = zone.utcFromWallClock(DateTime.utc(2026, 3, 29));
      final end = zone.utcFromWallClock(DateTime.utc(2026, 3, 30));
      expect(end.difference(start), const Duration(hours: 23));
    });

    test('a fall-back day is 25 hours long', () {
      final start = zone.utcFromWallClock(DateTime.utc(2026, 10, 25));
      final end = zone.utcFromWallClock(DateTime.utc(2026, 10, 26));
      expect(end.difference(start), const Duration(hours: 25));
    });
  });

  test('the device zone agrees with the runtime', () {
    const zone = DeviceTimeZone();
    final instant = DateTime.utc(2026, 7, 4, 9, 15);
    final local = instant.toLocal();
    expect(zone.minuteOfDayAt(instant), local.hour * 60 + local.minute);
    expect(zone.id, 'device');
  });
}
