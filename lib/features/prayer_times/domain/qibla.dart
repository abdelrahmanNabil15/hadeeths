import 'dart:math' as math;

import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';

/// The direction of the Kaaba from a place: a geographic bearing, not a compass reading.
///
/// - [bearing] is degrees clockwise from **true** north (0 to 360), along the shortest path
///   over the Earth (great circle), on a spherical Earth. The sphere model is accurate to a
///   fraction of a degree for this purpose.
/// - A phone compass reports a **magnetic** or noisy heading; use [relativeTurn] with a
///   heading converted to true north to know how far to turn.
abstract final class Qibla {
  /// The Kaaba in Makkah, in degrees (accurate to roughly 10 metres).
  static final kaaba = GeoPoint(21.4225241, 39.8261818);

  /// Closer than this to the Kaaba the direction is meaningless and [bearing] is null.
  static const hereThresholdMetres = 100.0;

  static const _earthRadiusMetres = 6371008.8;

  /// Initial great-circle bearing to the Kaaba, or null when standing at the Kaaba.
  static double? bearing(GeoPoint from) {
    if (distanceMetres(from) < hereThresholdMetres) return null;
    final phi1 = _rad(from.latitude);
    final phi2 = _rad(kaaba.latitude);
    final dLambda = _rad(kaaba.longitude - from.longitude);
    final y = math.sin(dLambda) * math.cos(phi2);
    final x =
        math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(dLambda);
    return normalizeDegrees(_deg(math.atan2(y, x)));
  }

  /// Great-circle distance to the Kaaba in metres (haversine).
  static double distanceMetres(GeoPoint from) {
    final phi1 = _rad(from.latitude);
    final phi2 = _rad(kaaba.latitude);
    final dPhi = phi2 - phi1;
    final dLambda = _rad(kaaba.longitude - from.longitude);
    final a =
        math.pow(math.sin(dPhi / 2), 2) +
        math.cos(phi1) * math.cos(phi2) * math.pow(math.sin(dLambda / 2), 2);
    return 2 * _earthRadiusMetres * math.asin(math.min(1, math.sqrt(a)));
  }

  /// A compass heading relative to true north, from a magnetic heading and the local magnetic
  /// declination (east positive): true = magnetic + declination.
  static double trueHeading(double magneticHeading, double declination) =>
      normalizeDegrees(magneticHeading + declination);

  /// How far to turn from [trueHeading] to face [qiblaBearing]: -180 to 180, positive meaning
  /// turn clockwise (to the right).
  static double relativeTurn(double qiblaBearing, double trueHeading) {
    final diff = normalizeDegrees(qiblaBearing - trueHeading);
    return diff > 180 ? diff - 360 : diff;
  }

  /// Wraps any angle into 0 (inclusive) to 360 (exclusive).
  static double normalizeDegrees(double degrees) {
    final wrapped = degrees % 360;
    return wrapped < 0 ? wrapped + 360 : wrapped;
  }

  static double _rad(double degrees) => degrees * math.pi / 180;

  static double _deg(double radians) => radians * 180 / math.pi;
}
