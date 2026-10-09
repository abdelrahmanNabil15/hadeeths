import 'package:equatable/equatable.dart';

/// A place on Earth in degrees: latitude -90..90 (north positive), longitude -180..180
/// (east positive).
class GeoPoint extends Equatable {
  GeoPoint(this.latitude, this.longitude) {
    if (!(latitude >= -90 && latitude <= 90)) {
      throw RangeError.value(latitude, 'latitude', 'must be within -90..90');
    }
    if (!(longitude >= -180 && longitude <= 180)) {
      throw RangeError.value(
        longitude,
        'longitude',
        'must be within -180..180',
      );
    }
  }

  final double latitude;
  final double longitude;

  /// Rounds to [decimals] places (2 is about 1 km): the least precise location that still
  /// gives correct prayer times, for storing instead of an exact position.
  GeoPoint rounded([int decimals = 2]) {
    double r(double v) => double.parse(v.toStringAsFixed(decimals));
    return GeoPoint(r(latitude), r(longitude));
  }

  @override
  List<Object?> get props => [latitude, longitude];

  /// Deliberately omits the numbers so a location never ends up in logs by accident.
  @override
  String toString() => 'GeoPoint(<hidden>)';
}
