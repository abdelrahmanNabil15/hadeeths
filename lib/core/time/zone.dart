/// What the planner needs to know about a time zone: the UTC offset at a given instant.
///
/// Keeping this tiny interface lets the logic be tested with scripted daylight-saving
/// rules, without a time-zone database dependency. A production implementation backed
/// by the IANA database can be added later without changing callers.
abstract interface class TimeZoneRules {
  /// A stable identifier stored next to records that depend on the zone.
  String get id;

  /// The offset from UTC in effect at [utcInstant].
  Duration offsetAt(DateTime utcInstant);
}

/// The device's current zone, as reported by the Dart runtime (it follows daylight saving).
///
/// The Dart runtime does not expose an IANA name, so [id] is the fixed text `device`.
class DeviceTimeZone implements TimeZoneRules {
  const DeviceTimeZone();

  @override
  String get id => 'device';

  @override
  Duration offsetAt(DateTime utcInstant) =>
      utcInstant.toUtc().toLocal().timeZoneOffset;
}

/// A zone with a constant offset (useful for tests and for fixed-offset locations).
class FixedOffsetZone implements TimeZoneRules {
  const FixedOffsetZone(this.offset, {this.id = 'fixed'});

  final Duration offset;

  @override
  final String id;

  @override
  Duration offsetAt(DateTime utcInstant) => offset;
}

/// Wall-clock helpers. A "wall-clock" value is a `DateTime` flagged as UTC whose fields
/// are the local calendar date and time (it is only a carrier for the fields).
extension ZoneConversions on TimeZoneRules {
  /// The local wall-clock fields at [utcInstant].
  DateTime wallClockAt(DateTime utcInstant) {
    final utc = utcInstant.toUtc();
    return utc.add(offsetAt(utc));
  }

  /// Minutes since local midnight (0 to 1439) at [utcInstant].
  int minuteOfDayAt(DateTime utcInstant) {
    final wall = wallClockAt(utcInstant);
    return wall.hour * 60 + wall.minute;
  }

  /// The local calendar date (time fields zero) at [utcInstant].
  DateTime localDateAt(DateTime utcInstant) {
    final wall = wallClockAt(utcInstant);
    return DateTime.utc(wall.year, wall.month, wall.day);
  }

  /// The UTC instant at which the local wall clock reads [wallClock].
  ///
  /// - Normal times map to exactly one instant.
  /// - A time that happens twice (clocks go back) maps to its **first** occurrence.
  /// - A time that does not exist (clocks go forward) maps to the same offset that was
  ///   in force before the change, so the result lands after the gap, not before it.
  ///
  /// Assumes there is at most one offset change within 24 hours of [wallClock].
  DateTime utcFromWallClock(DateTime wallClock) {
    assert(wallClock.isUtc, 'wall-clock values are carried as UTC DateTimes');
    const day = Duration(days: 1);
    final early = wallClock.subtract(offsetAt(wallClock.subtract(day)));
    final late = wallClock.subtract(offsetAt(wallClock.add(day)));
    final earlyValid = wallClockAt(early) == wallClock;
    final lateValid = wallClockAt(late) == wallClock;
    if (earlyValid && lateValid) return early.isBefore(late) ? early : late;
    if (earlyValid) return early;
    if (lateValid) return late;
    return early; // inside a gap
  }
}
