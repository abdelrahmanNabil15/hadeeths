import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:mynewapp/core/permissions/permission_gateway.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/location_service.dart';

/// Reads one position through the `geolocator` package (MIT). Low accuracy, a time limit, no
/// background use and no stored history.
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService({
    this.timeLimit = const Duration(seconds: 20),
  });

  final Duration timeLimit;

  @override
  Future<LocationResult> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationFailed(LocationProblem.serviceDisabled);
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: timeLimit,
        ),
      );
      return LocationFound(GeoPoint(position.latitude, position.longitude));
    } on TimeoutException {
      return const LocationFailed(LocationProblem.timeout);
    } on LocationServiceDisabledException {
      return const LocationFailed(LocationProblem.serviceDisabled);
    } on Object {
      // Includes a position outside the valid range and any platform error; the position is
      // never put in the message.
      return const LocationFailed(LocationProblem.unavailable);
    }
  }

  @override
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } on Object {
      return false;
    }
  }
}

/// Location permission through `geolocator`. Only [AppPermission.location] is handled here;
/// the others are served by the features that need their own plugins, so they report
/// "unavailable" from this gateway.
class GeolocatorPermissionGateway implements PermissionGateway {
  const GeolocatorPermissionGateway();

  @override
  Future<PermissionState> status(AppPermission permission) async {
    if (permission != AppPermission.location) {
      return PermissionState.unavailable;
    }
    try {
      return mapLocationPermission(await Geolocator.checkPermission());
    } on Object {
      return PermissionState.unavailable;
    }
  }

  @override
  Future<PermissionState> request(AppPermission permission) async {
    if (permission != AppPermission.location) {
      return PermissionState.unavailable;
    }
    try {
      return mapLocationPermission(await Geolocator.requestPermission());
    } on Object {
      return PermissionState.denied;
    }
  }

  @override
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } on Object {
      return false;
    }
  }

  /// Either "while in use" or "always" lets the app read a position; the app only ever asks for
  /// "while in use".
  static PermissionState mapLocationPermission(LocationPermission permission) =>
      switch (permission) {
        LocationPermission.whileInUse ||
        LocationPermission.always => PermissionState.granted,
        LocationPermission.denied => PermissionState.denied,
        LocationPermission.deniedForever => PermissionState.permanentlyDenied,
        LocationPermission.unableToDetermine => PermissionState.denied,
      };
}
