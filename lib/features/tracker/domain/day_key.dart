import 'package:equatable/equatable.dart';

/// A calendar day (year, month, day) with no time and no zone: "the 9th of October 2026" wherever
/// the user is. Which day it is *now* is decided from the user's own clock and place, once, by
/// whoever builds the key; after that a key never changes meaning when the phone changes zone.
class DayKey extends Equatable implements Comparable<DayKey> {
  /// Throws [ArgumentError] for a day that does not exist (for example 31 November).
  DayKey(this.year, this.month, this.day) {
    final check = DateTime.utc(year, month, day);
    if (check.year != year || check.month != month || check.day != day) {
      throw ArgumentError('not a calendar day: $year-$month-$day');
    }
  }

  /// The day shown on a wall clock. Only year, month and day are read, so it does not matter
  /// whether [wallClock] is flagged as UTC or local.
  factory DayKey.fromWallClock(DateTime wallClock) =>
      DayKey(wallClock.year, wallClock.month, wallClock.day);

  /// Reads "2026-10-09". Throws [FormatException] for anything else.
  factory DayKey.parse(String text) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
    if (match == null) throw FormatException('not a day key', text);
    try {
      return DayKey(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
    } on ArgumentError {
      throw FormatException('not a calendar day', text);
    }
  }

  final int year;
  final int month;
  final int day;

  /// "2026-10-09": sorts the same as the dates do, which the database relies on.
  String get id =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  /// Midnight of this day as a UTC-flagged date, for weekday and month names.
  DateTime get date => DateTime.utc(year, month, day);

  /// Monday is 1 and Sunday is 7.
  int get weekday => date.weekday;

  /// The day [days] after this one (before it if negative). Whole days of the calendar, so a
  /// daylight-saving change cannot skip or repeat one.
  DayKey addDays(int days) =>
      DayKey.fromWallClock(date.add(Duration(days: days)));

  @override
  int compareTo(DayKey other) => id.compareTo(other.id);

  bool isBefore(DayKey other) => compareTo(other) < 0;

  bool isAfter(DayKey other) => compareTo(other) > 0;

  @override
  List<Object?> get props => [year, month, day];

  @override
  String toString() => id;
}
