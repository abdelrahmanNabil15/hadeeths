import 'package:equatable/equatable.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';

/// The calculated times for one local calendar day at one place.
///
/// All instants are UTC. Convert for display with the zone of the place, not the device's, so
/// a manual location in another time zone shows its own local times.
class PrayerDay extends Equatable {
  PrayerDay({
    required this.date,
    required Map<Prayer, DateTime> times,
    required this.previousIsha,
    required this.nextFajr,
  }) : times = Map.unmodifiable(times) {
    assert(date.isUtc, 'date is a calendar date carried as a UTC DateTime');
    assert(Prayer.values.every(times.containsKey));
  }

  /// The calendar date (year, month, day; time fields zero), as a UTC `DateTime`.
  final DateTime date;
  final Map<Prayer, DateTime> times;

  /// Isha of the previous day: the prayer that is current until this day's Fajr.
  final DateTime previousIsha;

  /// Fajr of the next day: when the next prayer starts after this day's Isha.
  final DateTime nextFajr;

  DateTime operator [](Prayer prayer) => times[prayer]!;

  /// Whether the times make sense: increasing through the day, after the previous night's Isha
  /// and before the next Fajr. Extreme latitudes can break this.
  ///
  /// Isha may equal the following Fajr: with the "middle of the night" rule in a place where the
  /// twilight never ends, the two meet at exactly the same minute, and that is what the rule
  /// means, not an error.
  bool get isConsistent {
    if (previousIsha.isAfter(this[Prayer.fajr])) return false;
    var previous = this[Prayer.fajr];
    for (final prayer in Prayer.values.skip(1)) {
      if (!this[prayer].isAfter(previous)) return false;
      previous = this[prayer];
    }
    return !nextFajr.isBefore(previous);
  }

  @override
  List<Object?> get props => [date, times, previousIsha, nextFajr];
}
