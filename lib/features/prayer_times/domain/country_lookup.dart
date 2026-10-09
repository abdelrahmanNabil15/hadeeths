import 'dart:math' as math;

import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';

/// Finds the country a position is in, offline, from simplified country borders
/// (Natural Earth 1:110m, public domain; see `assets/data/countries_110m.json`).
///
/// Meant only for *suggesting* a default (for example a calculation method) that the user can
/// always change. It is not accurate near borders (the outlines are drawn at a scale of about a
/// kilometre or more) and it does not know very small countries (Singapore, Bahrain, the
/// Maldives, Malta), for which it returns null.
class CountryLookup {
  CountryLookup._(this._polygons);

  /// Reads the compact format of `countries_110m.json`: a `countries` map from ISO 3166-1 alpha-2
  /// code to polygons, each polygon a list of rings, each ring a flat list of hundredths of a
  /// degree `[lon, lat, lon, lat, ...]` (first ring the outline, the others holes).
  factory CountryLookup.fromJson(Map<String, dynamic> json) {
    final polygons = <_Polygon>[];
    final countries = json['countries'] as Map<String, dynamic>;
    countries.forEach((code, value) {
      for (final polygon in (value as List).cast<List<dynamic>>()) {
        final rings = [
          for (final ring in polygon)
            [for (final n in (ring as List).cast<num>()) n / 100],
        ];
        polygons.add(_Polygon(code, rings));
      }
    });
    return CountryLookup._(polygons);
  }

  final List<_Polygon> _polygons;

  /// How far outside the drawn border still counts as that country, for coastal cities that fall
  /// just outside a simplified coastline (about 55 km).
  static const coastToleranceDegrees = 0.5;

  /// The ISO 3166-1 alpha-2 code of the country at [point], or null when none is close enough.
  String? countryAt(GeoPoint point) {
    for (final polygon in _polygons) {
      if (polygon.contains(point.longitude, point.latitude)) {
        return polygon.code;
      }
    }
    String? nearest;
    var best = coastToleranceDegrees;
    for (final polygon in _polygons) {
      final d = polygon.distanceTo(point.longitude, point.latitude, best);
      if (d != null && d < best) {
        best = d;
        nearest = polygon.code;
      }
    }
    return nearest;
  }
}

class _Polygon {
  _Polygon(this.code, this.rings) {
    var minLon = double.infinity;
    var maxLon = -double.infinity;
    var minLat = double.infinity;
    var maxLat = -double.infinity;
    for (final ring in rings) {
      for (var i = 0; i < ring.length; i += 2) {
        minLon = math.min(minLon, ring[i]);
        maxLon = math.max(maxLon, ring[i]);
        minLat = math.min(minLat, ring[i + 1]);
        maxLat = math.max(maxLat, ring[i + 1]);
      }
    }
    this.minLon = minLon;
    this.maxLon = maxLon;
    this.minLat = minLat;
    this.maxLat = maxLat;
  }

  final String code;
  final List<List<double>> rings;
  late final double minLon;
  late final double maxLon;
  late final double minLat;
  late final double maxLat;

  /// Even-odd rule over all rings, so holes are outside.
  bool contains(double lon, double lat) {
    if (lon < minLon || lon > maxLon || lat < minLat || lat > maxLat) {
      return false;
    }
    var inside = false;
    for (final ring in rings) {
      final n = ring.length ~/ 2;
      for (var i = 0, j = n - 1; i < n; j = i++) {
        final xi = ring[2 * i];
        final yi = ring[2 * i + 1];
        final xj = ring[2 * j];
        final yj = ring[2 * j + 1];
        if ((yi > lat) != (yj > lat) &&
            lon < (xj - xi) * (lat - yi) / (yj - yi) + xi) {
          inside = !inside;
        }
      }
    }
    return inside;
  }

  /// Distance in degrees (longitude scaled by latitude) to the nearest outline segment, or null
  /// when farther than [limit].
  double? distanceTo(double lon, double lat, double limit) {
    if (lon < minLon - limit * 2 ||
        lon > maxLon + limit * 2 ||
        lat < minLat - limit ||
        lat > maxLat + limit) {
      return null;
    }
    final scale = math.cos(lat * math.pi / 180);
    double? best;
    for (final ring in rings) {
      final n = ring.length ~/ 2;
      for (var i = 0, j = n - 1; i < n; j = i++) {
        final d = _segmentDistance(
          lon * scale,
          lat,
          ring[2 * j] * scale,
          ring[2 * j + 1],
          ring[2 * i] * scale,
          ring[2 * i + 1],
        );
        if (best == null || d < best) best = d;
      }
    }
    return best != null && best <= limit ? best : null;
  }

  static double _segmentDistance(
    double px,
    double py,
    double ax,
    double ay,
    double bx,
    double by,
  ) {
    final dx = bx - ax;
    final dy = by - ay;
    final lengthSquared = dx * dx + dy * dy;
    var t = lengthSquared == 0
        ? 0.0
        : ((px - ax) * dx + (py - ay) * dy) / lengthSquared;
    t = t.clamp(0.0, 1.0);
    final cx = ax + t * dx;
    final cy = ay + t * dy;
    return math.sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
  }
}
