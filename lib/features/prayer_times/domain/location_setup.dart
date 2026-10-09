import 'package:mynewapp/core/permissions/permission_flow.dart';
import 'package:mynewapp/core/permissions/permission_gateway.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/location_service.dart';

/// How "use my location" ended.
enum LocationSetupStatus {
  /// A position was read.
  found,

  /// The user closed the explanation, so the system prompt never appeared.
  declinedExplanation,

  /// The system prompt was refused; the user can try again or choose a city.
  denied,

  /// Refused with "don't ask again": only the system settings can change it.
  needsSettings,

  /// This device cannot grant location at all.
  permissionUnavailable,

  /// Permission is fine but location is switched off on the device.
  serviceDisabled,

  /// No position arrived in time.
  timeout,

  /// The device could not provide a position.
  unavailable,
}

class LocationSetupResult {
  const LocationSetupResult(this.status, [this.point]);

  final LocationSetupStatus status;
  final GeoPoint? point;
}

/// The whole "use my location" step: explain, ask, read once. Nothing is stored here; the caller
/// decides what to do with the point (see `PrayerLocation`, which rounds it).
class LocationSetup {
  const LocationSetup(this._permissions, this._location);

  final PermissionFlow _permissions;
  final LocationService _location;

  Future<LocationSetupResult> run({
    required Future<bool> Function() explain,
  }) async {
    final outcome = await _permissions.ensure(
      AppPermission.location,
      explain: explain,
    );
    switch (outcome) {
      case PermissionOutcome.declinedExplanation:
        return const LocationSetupResult(
          LocationSetupStatus.declinedExplanation,
        );
      case PermissionOutcome.denied:
        return const LocationSetupResult(LocationSetupStatus.denied);
      case PermissionOutcome.needsSettings:
        return const LocationSetupResult(LocationSetupStatus.needsSettings);
      case PermissionOutcome.unavailable:
        return const LocationSetupResult(
          LocationSetupStatus.permissionUnavailable,
        );
      case PermissionOutcome.granted:
        break;
    }
    final result = await _location.currentPosition();
    return switch (result) {
      LocationFound(:final point) => LocationSetupResult(
        LocationSetupStatus.found,
        point,
      ),
      LocationFailed(:final problem) => LocationSetupResult(switch (problem) {
        LocationProblem.serviceDisabled => LocationSetupStatus.serviceDisabled,
        LocationProblem.timeout => LocationSetupStatus.timeout,
        LocationProblem.unavailable => LocationSetupStatus.unavailable,
      }),
    };
  }

  Future<bool> openAppSettings() => _permissions.openSettings();

  Future<bool> openLocationSettings() => _location.openLocationSettings();
}
