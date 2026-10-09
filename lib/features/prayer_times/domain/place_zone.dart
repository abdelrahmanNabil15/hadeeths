import 'package:mynewapp/core/time/iana_time_zone.dart';
import 'package:mynewapp/core/time/zone.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_location.dart';

/// The zone to show a place's times in: the device's own for a device position, otherwise the IANA
/// zone saved with the place (the device's if that name is no longer known).
TimeZoneRules zoneForPlace(PrayerLocation place) {
  if (place.usesDeviceZone) return const DeviceTimeZone();
  return IanaTimeZone.tryParse(place.zoneId) ?? const DeviceTimeZone();
}
