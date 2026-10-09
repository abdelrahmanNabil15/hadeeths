import 'package:equatable/equatable.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_day.dart';

/// Where [now] falls in a day: which period it is, and what comes next.
///
/// A period starts at its time and lasts until the next one starts, so at the exact instant
/// of Asr the current period is already Asr. Between sunrise and Dhuhr the current period is
/// [Prayer.sunrise] (no obligatory prayer is current then). Before Fajr the current period is
/// the previous day's Isha, and after Isha the next prayer is the next day's Fajr.
class PrayerMoment extends Equatable {
  const PrayerMoment({
    required this.current,
    required this.currentStartedAt,
    required this.next,
    required this.nextAt,
    required this.nextIsOnNextDay,
  });

  /// Chooses the moment for [now] within [day], which must be the day [now] belongs to
  /// (the local calendar date at the place). Throws [ArgumentError] otherwise, because
  /// answering from the wrong day would show a wrong "next prayer".
  factory PrayerMoment.at(PrayerDay day, DateTime now) {
    final instant = now.toUtc();
    if (instant.isBefore(day.previousIsha) || !instant.isBefore(day.nextFajr)) {
      throw ArgumentError.value(
        now,
        'now',
        'is outside the span of the given PrayerDay (previous Isha up to next Fajr)',
      );
    }
    var current = Prayer.isha;
    var currentStartedAt = day.previousIsha;
    for (final prayer in Prayer.values) {
      if (day[prayer].isAfter(instant)) {
        return PrayerMoment(
          current: current,
          currentStartedAt: currentStartedAt,
          next: prayer,
          nextAt: day[prayer],
          nextIsOnNextDay: false,
        );
      }
      current = prayer;
      currentStartedAt = day[prayer];
    }
    return PrayerMoment(
      current: current,
      currentStartedAt: currentStartedAt,
      next: Prayer.fajr,
      nextAt: day.nextFajr,
      nextIsOnNextDay: true,
    );
  }

  final Prayer current;
  final DateTime currentStartedAt;
  final Prayer next;
  final DateTime nextAt;

  /// True after Isha, when [next] is tomorrow's Fajr.
  final bool nextIsOnNextDay;

  /// Time left until [next] begins (never negative).
  Duration remaining(DateTime now) {
    final left = nextAt.difference(now.toUtc());
    return left.isNegative ? Duration.zero : left;
  }

  @override
  List<Object?> get props => [
    current,
    currentStartedAt,
    next,
    nextAt,
    nextIsOnNextDay,
  ];
}
