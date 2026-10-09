import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';

/// Why the device could not give a position (permission problems are handled separately,
/// by the permission flow).
enum LocationProblem {
  /// Location is switched off in the device settings.
  serviceDisabled,

  /// No position arrived in time (indoors, poor signal).
  timeout,

  /// The device or the platform could not provide one.
  unavailable,
}

sealed class LocationResult {
  const LocationResult();
}

class LocationFound extends LocationResult {
  const LocationFound(this.point);

  final GeoPoint point;
}

class LocationFailed extends LocationResult {
  const LocationFailed(this.problem);

  final LocationProblem problem;
}

/// Reads the device position once, when asked. It never tracks in the background and never
/// asks for permission itself.
abstract interface class LocationService {
  /// A single position. Low accuracy is enough (prayer times change by seconds over a few
  /// kilometres) and works with the "approximate location" choice on newer phones.
  Future<LocationResult> currentPosition();

  /// Opens the system page where location can be switched on.
  Future<bool> openLocationSettings();
}
