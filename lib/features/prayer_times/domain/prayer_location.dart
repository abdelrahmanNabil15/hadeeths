import 'package:equatable/equatable.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';

/// How the place was chosen.
enum LocationSource {
  /// From the device's position, read once when the user asked (never tracked in the background).
  gps,

  /// Picked or typed by the user. Needs no location permission.
  manual,
}

/// The place prayer times are calculated for.
///
/// Only what is needed is kept: a position rounded to about a kilometre (more precision changes
/// prayer times by seconds), an optional name the user can recognise, and the time zone.
class PrayerLocation extends Equatable {
  PrayerLocation({
    required GeoPoint point,
    required this.source,
    required this.zoneId,
    this.name,
    this.countryCode,
  }) : point = point.rounded();

  /// Rounded to 2 decimal places on construction.
  final GeoPoint point;
  final LocationSource source;

  /// [deviceZoneId] for a place read from the device's position (the zone follows the device
  /// as it travels), otherwise an IANA name such as `Africa/Cairo`.
  final String zoneId;

  /// What the user sees ("Cairo"); null for a device position, which the screen calls "Current
  /// location".
  final String? name;

  /// ISO 3166-1 alpha-2, when known.
  final String? countryCode;

  static const deviceZoneId = 'device';

  bool get usesDeviceZone => zoneId == deviceZoneId;

  @override
  List<Object?> get props => [point, source, zoneId, name, countryCode];
}
