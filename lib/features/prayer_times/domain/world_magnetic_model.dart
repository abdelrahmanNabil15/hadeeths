import 'dart:math' as math;

/// The Earth's magnetic field at a place and time, in the geodetic frame (north, east, down),
/// in nanotesla.
class MagneticField {
  const MagneticField({
    required this.north,
    required this.east,
    required this.down,
  });

  final double north;
  final double east;
  final double down;

  /// Angle from true north to magnetic north, in degrees, east positive. Add it to a magnetic
  /// compass heading to get a heading from true north.
  double get declination => math.atan2(east, north) * 180 / math.pi;

  /// Dip of the field below the horizontal, in degrees.
  double get inclination =>
      math.atan2(down, math.sqrt(north * north + east * east)) * 180 / math.pi;

  double get horizontal => math.sqrt(north * north + east * east);

  double get total => math.sqrt(north * north + east * east + down * down);
}

/// The World Magnetic Model (WMM): spherical-harmonic model of the Earth's main magnetic field,
/// published by NOAA's National Centers for Environmental Information and the British Geological
/// Survey. Used here only to turn a magnetic compass heading into a heading from true north.
///
/// This is a direct implementation of the model as described in the WMM technical report, checked
/// against the 100 official test points (see `test/.../world_magnetic_model_test.dart`). A set of
/// coefficients is valid for five years from its epoch; outside that the field drifts and the
/// result is flagged by [isValidAt].
class WorldMagneticModel {
  WorldMagneticModel._(this.epoch, this._g, this._h, this._gDot, this._hDot);

  /// Reads the text of an official coefficient file (`WMM.COF`): a header line holding the epoch
  /// first, then one line per coefficient `n m g h gDot hDot`, ending with a line of nines.
  factory WorldMagneticModel.parse(String cofText) {
    final lines = cofText.split(RegExp(r'\r?\n'));
    final header = lines.first.trim().split(RegExp(r'\s+'));
    final epoch = double.parse(header.first);
    final size = degree + 1;
    List<List<double>> table() =>
        List.generate(size, (_) => List<double>.filled(size, 0));
    final g = table();
    final h = table();
    final gDot = table();
    final hDot = table();
    for (final line in lines.skip(1)) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length < 6) continue;
      final n = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      g[n][m] = double.parse(parts[2]);
      h[n][m] = double.parse(parts[3]);
      gDot[n][m] = double.parse(parts[4]);
      hDot[n][m] = double.parse(parts[5]);
    }
    return WorldMagneticModel._(epoch, g, h, gDot, hDot);
  }

  /// The WMM has degree and order 12.
  static const degree = 12;

  /// How long one set of coefficients is valid after its epoch.
  static const validYears = 5.0;

  /// Start of validity, as a decimal year (2025.0 for WMM2025).
  final double epoch;

  final List<List<double>> _g;
  final List<List<double>> _h;
  final List<List<double>> _gDot;
  final List<List<double>> _hDot;

  bool isValidAt(double decimalYear) =>
      decimalYear >= epoch && decimalYear < epoch + validYears;

  /// A date as a decimal year (for example mid-year 2026 is about 2026.5).
  static double decimalYearOf(DateTime date) {
    final utc = date.toUtc();
    final start = DateTime.utc(utc.year);
    final end = DateTime.utc(utc.year + 1);
    return utc.year +
        utc.difference(start).inMicroseconds /
            end.difference(start).inMicroseconds;
  }

  // WGS-84 ellipsoid and the model's reference radius.
  static const _a = 6378.137; // km
  static const _f = 1 / 298.257223563;
  static const _re = 6371.2; // km

  /// The field at geodetic [latitude] and [longitude] in degrees, [altitudeKm] above the WGS-84
  /// ellipsoid, at [decimalYear].
  MagneticField at({
    required double latitude,
    required double longitude,
    double altitudeKm = 0,
    required double decimalYear,
  }) {
    // The formulas divide by sin(colatitude); stay a hair away from the exact poles.
    final lat = latitude.clamp(-89.999999, 89.999999);
    final phi = lat * math.pi / 180;
    final lambda = longitude * math.pi / 180;
    final e2 = _f * (2 - _f);
    final sinPhi = math.sin(phi);
    final cosPhi = math.cos(phi);

    // Geodetic to geocentric spherical coordinates.
    final rc = _a / math.sqrt(1 - e2 * sinPhi * sinPhi);
    final p = (rc + altitudeKm) * cosPhi;
    final z = (rc * (1 - e2) + altitudeKm) * sinPhi;
    final r = math.sqrt(p * p + z * z);
    final sinPhiC = z / r;
    final cosPhiC = p / r;
    final phiC = math.asin(sinPhiC);

    // Colatitude theta' = 90 degrees - geocentric latitude.
    final cosT = sinPhiC;
    final sinT = cosPhiC;

    final size = degree + 1;
    final pn = List.generate(size, (_) => List<double>.filled(size, 0));
    final dp = List.generate(size, (_) => List<double>.filled(size, 0));
    pn[0][0] = 1;
    for (var n = 1; n <= degree; n++) {
      for (var m = 0; m <= n; m++) {
        if (n == m) {
          final k = n == 1 ? 1.0 : math.sqrt((2 * n - 1) / (2 * n));
          pn[n][n] = k * sinT * pn[n - 1][n - 1];
          dp[n][n] = k * (sinT * dp[n - 1][n - 1] + cosT * pn[n - 1][n - 1]);
        } else {
          final low = n >= 2 ? pn[n - 2][m] : 0.0;
          final lowD = n >= 2 ? dp[n - 2][m] : 0.0;
          final root = math.sqrt((n - 1) * (n - 1) - m * m);
          final denom = math.sqrt((n * n - m * m).toDouble());
          pn[n][m] = ((2 * n - 1) * cosT * pn[n - 1][m] - root * low) / denom;
          dp[n][m] =
              ((2 * n - 1) * (cosT * dp[n - 1][m] - sinT * pn[n - 1][m]) -
                  root * lowD) /
              denom;
        }
      }
    }

    final dt = decimalYear - epoch;
    final ar = _re / r;
    var br = 0.0;
    var bt = 0.0;
    var bp = 0.0;
    var arn = ar * ar; // (re / r) to the power n + 2, starting at n = 0
    for (var n = 1; n <= degree; n++) {
      arn *= ar;
      for (var m = 0; m <= n; m++) {
        final g = _g[n][m] + _gDot[n][m] * dt;
        final h = _h[n][m] + _hDot[n][m] * dt;
        final cosM = math.cos(m * lambda);
        final sinM = math.sin(m * lambda);
        br += (n + 1) * arn * (g * cosM + h * sinM) * pn[n][m];
        bt -= arn * (g * cosM + h * sinM) * dp[n][m];
        bp += arn * m * (g * sinM - h * cosM) * pn[n][m];
      }
    }
    bp /= sinT;

    // North, east, down in the geocentric frame, then rotated to the geodetic one.
    final xg = -bt;
    final yg = bp;
    final zg = -br;
    final psi = phiC - phi;
    return MagneticField(
      north: xg * math.cos(psi) - zg * math.sin(psi),
      east: yg,
      down: xg * math.sin(psi) + zg * math.cos(psi),
    );
  }
}
