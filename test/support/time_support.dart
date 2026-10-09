import 'package:mynewapp/core/time/clock.dart';
import 'package:mynewapp/core/time/zone.dart';

/// A clock the test moves by hand.
class FakeClock implements Clock {
  FakeClock(DateTime start) : _now = start.toUtc();

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration by) => _now = _now.add(by);

  void set(DateTime to) => _now = to.toUtc();
}

/// A zone whose offset changes at scripted UTC instants (daylight saving).
class ScriptedZone implements TimeZoneRules {
  ScriptedZone(this.initial, this.changes, {this.id = 'scripted'});

  final Duration initial;

  /// Sorted by instant; the offset applies from that instant on.
  final List<(DateTime, Duration)> changes;

  @override
  final String id;

  @override
  Duration offsetAt(DateTime utcInstant) {
    var offset = initial;
    for (final (at, to) in changes) {
      if (!utcInstant.isBefore(at)) offset = to;
    }
    return offset;
  }
}

/// UTC+0 in winter, UTC+1 in summer, switching at 01:00 UTC on the last Sundays of
/// March (2026-03-29, wall clock 01:00 -> 02:00) and October (2026-10-25, 02:00 -> 01:00).
ScriptedZone europeLikeZone() => ScriptedZone(Duration.zero, [
  (DateTime.utc(2026, 3, 29, 1), const Duration(hours: 1)),
  (DateTime.utc(2026, 10, 25, 1), Duration.zero),
]);
