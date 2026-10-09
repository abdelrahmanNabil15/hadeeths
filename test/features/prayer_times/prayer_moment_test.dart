import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_day.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_moment.dart';

// A made-up but plausible day, in UTC: easy to read, not tied to any place.
DateTime _t(int h, [int m = 0]) => DateTime.utc(2026, 6, 21, h, m);

final _day = PrayerDay(
  date: DateTime.utc(2026, 6, 21),
  times: {
    Prayer.fajr: _t(2, 10),
    Prayer.sunrise: _t(3, 50),
    Prayer.dhuhr: _t(10, 5),
    Prayer.asr: _t(13, 40),
    Prayer.maghrib: _t(16, 55),
    Prayer.isha: _t(18, 25),
  },
  previousIsha: DateTime.utc(2026, 6, 20, 18, 24),
  nextFajr: DateTime.utc(2026, 6, 22, 2, 10),
);

void main() {
  test('before Fajr: the period is last night\'s Isha and Fajr is next', () {
    final m = PrayerMoment.at(_day, _t(1));
    expect(m.current, Prayer.isha);
    expect(m.currentStartedAt, DateTime.utc(2026, 6, 20, 18, 24));
    expect(m.next, Prayer.fajr);
    expect(m.nextAt, _t(2, 10));
    expect(m.nextIsOnNextDay, isFalse);
  });

  test('during the day each period leads to the next prayer', () {
    final cases = [
      (_t(3), Prayer.fajr, Prayer.sunrise),
      (_t(5), Prayer.sunrise, Prayer.dhuhr),
      (_t(11), Prayer.dhuhr, Prayer.asr),
      (_t(14), Prayer.asr, Prayer.maghrib),
      (_t(17), Prayer.maghrib, Prayer.isha),
    ];
    for (final (now, current, next) in cases) {
      final m = PrayerMoment.at(_day, now);
      expect(m.current, current, reason: '$now');
      expect(m.next, next, reason: '$now');
      expect(m.nextIsOnNextDay, isFalse);
    }
  });

  test('after Isha the next prayer is tomorrow\'s Fajr', () {
    final m = PrayerMoment.at(_day, _t(22));
    expect(m.current, Prayer.isha);
    expect(m.currentStartedAt, _t(18, 25));
    expect(m.next, Prayer.fajr);
    expect(m.nextAt, DateTime.utc(2026, 6, 22, 2, 10));
    expect(m.nextIsOnNextDay, isTrue);
  });

  test('a period begins at the exact minute of its prayer', () {
    expect(PrayerMoment.at(_day, _t(13, 40)).current, Prayer.asr);
    expect(PrayerMoment.at(_day, _t(13, 39)).current, Prayer.dhuhr);
    expect(PrayerMoment.at(_day, _t(2, 10)).current, Prayer.fajr);
    expect(PrayerMoment.at(_day, _t(18, 25)).current, Prayer.isha);
  });

  test('just after midnight still belongs to the evening before', () {
    final late = PrayerMoment.at(
      PrayerDay(
        date: DateTime.utc(2026, 6, 22),
        times: _day.times.map(
          (k, v) => MapEntry(k, v.add(const Duration(days: 1))),
        ),
        previousIsha: _t(18, 25),
        nextFajr: DateTime.utc(2026, 6, 23, 2, 10),
      ),
      DateTime.utc(2026, 6, 22, 0, 30),
    );
    expect(late.current, Prayer.isha);
    expect(late.currentStartedAt, _t(18, 25));
    expect(late.next, Prayer.fajr);
  });

  test('remaining time counts down and never goes negative', () {
    final m = PrayerMoment.at(_day, _t(13, 0));
    expect(m.remaining(_t(13, 0)), const Duration(minutes: 40));
    expect(m.remaining(_t(13, 40)), Duration.zero);
    expect(m.remaining(_t(15)), Duration.zero);
  });

  test('a time from another day is refused instead of answered wrongly', () {
    expect(
      () => PrayerMoment.at(_day, DateTime.utc(2026, 6, 20, 12)),
      throwsArgumentError,
    );
    expect(
      () => PrayerMoment.at(_day, DateTime.utc(2026, 6, 22, 2, 10)),
      throwsArgumentError,
    );
    expect(
      () => PrayerMoment.at(_day, DateTime.utc(2026, 6, 23)),
      throwsArgumentError,
    );
  });

  test('a non-UTC "now" means the same instant', () {
    final local = _t(14).toLocal();
    expect(PrayerMoment.at(_day, local).current, Prayer.asr);
  });

  test(
    'Isha and the next Fajr may coincide (high latitudes) and the day is still usable',
    () {
      final day = PrayerDay(
        date: DateTime.utc(2026, 6, 21),
        times: {
          Prayer.fajr: DateTime.utc(2026, 6, 21, 0, 2),
          Prayer.sunrise: DateTime.utc(2026, 6, 21, 3, 43),
          Prayer.dhuhr: DateTime.utc(2026, 6, 21, 12, 3),
          Prayer.asr: DateTime.utc(2026, 6, 21, 16, 25),
          Prayer.maghrib: DateTime.utc(2026, 6, 21, 20, 22),
          Prayer.isha: DateTime.utc(2026, 6, 22, 0, 2),
        },
        previousIsha: DateTime.utc(2026, 6, 21, 0, 2),
        nextFajr: DateTime.utc(2026, 6, 22, 0, 2),
      );
      expect(day.isConsistent, isTrue);
      expect(
        PrayerMoment.at(day, DateTime.utc(2026, 6, 21, 12)).next,
        Prayer.dhuhr,
      );
    },
  );

  test('inconsistent days are reported as such', () {
    final broken = PrayerDay(
      date: DateTime.utc(2026, 6, 21),
      times: {..._day.times, Prayer.asr: _t(9)},
      previousIsha: _day.previousIsha,
      nextFajr: _day.nextFajr,
    );
    expect(broken.isConsistent, isFalse);
  });
}
