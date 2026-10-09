import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/time/iana_time_zone.dart';
import 'package:mynewapp/core/time/zone.dart';

void main() {
  aliasTests();
  test('Cairo: +2 in winter, +3 in summer (daylight saving since 2023)', () {
    final cairo = IanaTimeZone('Africa/Cairo');
    expect(cairo.offsetAt(DateTime.utc(2026, 1, 15)), const Duration(hours: 2));
    expect(cairo.offsetAt(DateTime.utc(2026, 4, 1)), const Duration(hours: 2));
    expect(cairo.offsetAt(DateTime.utc(2026, 6, 21)), const Duration(hours: 3));
    expect(cairo.offsetAt(DateTime.utc(2026, 8, 6)), const Duration(hours: 3));
    expect(
      cairo.offsetAt(DateTime.utc(2026, 12, 21)),
      const Duration(hours: 2),
    );
  });

  test('London and New York switch on the right instants', () {
    final london = IanaTimeZone('Europe/London');
    expect(london.offsetAt(DateTime.utc(2026, 3, 29, 0, 59)), Duration.zero);
    expect(
      london.offsetAt(DateTime.utc(2026, 3, 29, 1)),
      const Duration(hours: 1),
    );
    expect(
      london.offsetAt(DateTime.utc(2026, 10, 25, 0, 59)),
      const Duration(hours: 1),
    );
    expect(london.offsetAt(DateTime.utc(2026, 10, 25, 1)), Duration.zero);
    final ny = IanaTimeZone('America/New_York');
    expect(ny.offsetAt(DateTime.utc(2026, 1, 1)), const Duration(hours: -5));
    expect(ny.offsetAt(DateTime.utc(2026, 7, 1)), const Duration(hours: -4));
  });

  test('zones without daylight saving stay fixed', () {
    expect(
      IanaTimeZone('Asia/Riyadh').offsetAt(DateTime.utc(2026, 7, 1)),
      const Duration(hours: 3),
    );
    expect(
      IanaTimeZone('Asia/Karachi').offsetAt(DateTime.utc(2026, 1, 1)),
      const Duration(hours: 5),
    );
  });

  test('half-hour and southern-hemisphere zones', () {
    expect(
      IanaTimeZone('Asia/Kolkata').offsetAt(DateTime.utc(2026, 1, 1)),
      const Duration(hours: 5, minutes: 30),
    );
    final auckland = IanaTimeZone('Pacific/Auckland');
    expect(
      auckland.offsetAt(DateTime.utc(2026, 6, 21)),
      const Duration(hours: 12),
    );
    expect(
      auckland.offsetAt(DateTime.utc(2026, 12, 21)),
      const Duration(hours: 13),
    );
  });

  test(
    'wall-clock helpers work with a real zone across the Cairo summer-time change',
    () {
      final cairo = IanaTimeZone('Africa/Cairo');
      // 2026-06-21 12:57 in Cairo is 09:57 UTC.
      expect(
        cairo.utcFromWallClock(DateTime.utc(2026, 6, 21, 12, 57)),
        DateTime.utc(2026, 6, 21, 9, 57),
      );
      expect(
        cairo.localDateAt(DateTime.utc(2026, 6, 21, 22, 30)),
        DateTime.utc(2026, 6, 22),
      );
    },
  );

  test('unknown names are reported, not guessed', () {
    expect(IanaTimeZone.tryParse('Mars/Olympus'), isNull);
    expect(() => IanaTimeZone('Mars/Olympus'), throwsArgumentError);
  });

  test('the id is the IANA name', () {
    final TimeZoneRules zone = IanaTimeZone('Africa/Cairo');
    expect(zone.id, 'Africa/Cairo');
  });
}

void aliasTests() {
  test(
    'alias zone names that place data uses are known and behave like their neighbours',
    () {
      final cases = {
        'Asia/Kuwait': 'Asia/Riyadh',
        'Europe/Oslo': 'Europe/Berlin',
        'Europe/Amsterdam': 'Europe/Berlin',
        'Africa/Addis_Ababa': 'Africa/Nairobi',
        'Asia/Kuala_Lumpur': 'Asia/Singapore',
      };
      cases.forEach((alias, canonical) {
        final a = IanaTimeZone.tryParse(alias);
        final c = IanaTimeZone(canonical);
        expect(a, isNotNull, reason: alias);
        for (final instant in [
          DateTime.utc(2026, 1, 15),
          DateTime.utc(2026, 7, 15),
        ]) {
          expect(
            a!.offsetAt(instant),
            c.offsetAt(instant),
            reason: '$alias $instant',
          );
        }
      });
    },
  );
}
