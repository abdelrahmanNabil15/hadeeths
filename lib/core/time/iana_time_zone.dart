import 'package:mynewapp/core/time/zone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// A time zone from the IANA database (for example `Africa/Cairo`), with its daylight-saving
/// rules, from the `timezone` package. Used for a place the user picked by hand, whose zone may
/// differ from the device's.
///
/// The database is bundled with the app, so this works offline. It reflects the rules known when
/// the package was released; a country that changes its rules later (Egypt did in 2023) needs an
/// app update.
class IanaTimeZone implements TimeZoneRules {
  IanaTimeZone._(this.id, this._location);

  /// The zone with this IANA name, or throws [ArgumentError] when there is none.
  factory IanaTimeZone(String id) =>
      tryParse(id) ??
      (throw ArgumentError.value(id, 'id', 'unknown time zone'));

  /// The zone with this IANA name, or null when there is none.
  static IanaTimeZone? tryParse(String id) {
    _ensureInitialized();
    try {
      return IanaTimeZone._(id, tz.getLocation(id));
    } on tz.LocationNotFoundException {
      return null;
    }
  }

  static bool _initialized = false;

  static void _ensureInitialized() {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    _initialized = true;
  }

  @override
  final String id;

  final tz.Location _location;

  @override
  Duration offsetAt(DateTime utcInstant) =>
      _location.timeZone(utcInstant.toUtc().millisecondsSinceEpoch).offset;
}
