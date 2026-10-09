/// The only place business rules may ask "what time is it now?".
///
/// Everything that depends on the current time (prayer dates, quiet hours, reminder
/// windows, daily hadith) takes a [Clock] so tests can control it. [now] is always UTC;
/// converting to a calendar date needs a `TimeZoneRules` (see `zone.dart`).
abstract interface class Clock {
  DateTime now();
}

/// The real clock.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now().toUtc();
}
