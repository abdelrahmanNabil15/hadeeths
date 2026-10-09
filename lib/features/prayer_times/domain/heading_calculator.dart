import 'dart:math' as math;

/// A reading along the three axes of the phone: x to the right of the screen, y toward the top
/// edge, z out of the screen toward the user.
class Vector3 {
  const Vector3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  double get length => math.sqrt(x * x + y * y + z * z);

  Vector3 operator +(Vector3 o) => Vector3(x + o.x, y + o.y, z + o.z);

  Vector3 operator *(double k) => Vector3(x * k, y * k, z * k);

  double dot(Vector3 o) => x * o.x + y * o.y + z * o.z;

  Vector3 cross(Vector3 o) =>
      Vector3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);

  Vector3? normalized() {
    final l = length;
    return l < 1e-9 ? null : Vector3(x / l, y / l, z / l);
  }

  @override
  String toString() => 'Vector3(<hidden>)';
}

/// One pair of sensor readings.
class CompassSample {
  const CompassSample({
    required this.acceleration,
    required this.magneticField,
  });

  /// What the accelerometer reports, in m/s², including gravity: at rest it points **up**
  /// (away from the ground) with a length of about 9.8. Same convention on Android and iOS.
  final Vector3 acceleration;

  /// The magnetic field in microtesla, in the phone's axes.
  final Vector3 magneticField;
}

/// Works out which way the phone points, from the accelerometer and the magnetometer.
///
/// The accelerometer says where "up" is; the magnetometer's component along the ground says where
/// magnetic north is; together they give a heading that stays correct when the phone is tilted
/// (tilt compensation).
///
/// Which edge points "ahead" depends on how the phone is held: flat on the palm, the top edge
/// points ahead; held upright in front of the face, the back of the phone does. The calculation
/// switches between the two when the phone is tilted more than 45 degrees from flat, and the two
/// give the same answer at exactly 45.
abstract final class HeadingCalculator {
  /// The heading of the direction the phone points, in degrees clockwise from **magnetic** north
  /// (0 up to 360), or null when it cannot be told (free fall, no field, or a field that points
  /// straight along gravity such as near the magnetic poles).
  static double? magneticHeading(CompassSample sample) {
    final up = sample.acceleration.normalized();
    final field = sample.magneticField;
    if (up == null || field.length < 1e-6) return null;
    final eastRaw = field.cross(up);
    // The part of the field that lies along the ground must be a reasonable share of the whole.
    if (eastRaw.length < 0.1 * field.length) return null;
    final east = eastRaw.normalized()!;
    final north = up.cross(east); // already unit length
    final flat = up.z.abs() >= math.sqrt1_2;
    final ahead = flat ? const Vector3(0, 1, 0) : const Vector3(0, 0, -1);
    final e = east.dot(ahead);
    final n = north.dot(ahead);
    if (math.sqrt(e * e + n * n) < 0.3) return null;
    final degrees = math.atan2(e, n) * 180 / math.pi;
    return degrees < 0 ? degrees + 360 : degrees;
  }

  /// Wraps an angle into 0 up to 360.
  static double wrap360(double degrees) {
    final r = degrees % 360;
    return r < 0 ? r + 360 : r;
  }
}

/// Smooths a stream of samples so the arrow does not jitter: the sensor vectors are averaged with
/// an exponential filter before the heading is calculated. Averaging vectors (not angles) has no
/// jump at 0 and 360.
class CompassFilter {
  CompassFilter({this.smoothing = 0.2});

  /// Share of each new reading that enters the average (1 means no smoothing).
  final double smoothing;

  Vector3? _acceleration;
  Vector3? _field;

  CompassSample add(CompassSample sample) {
    _acceleration = _blend(_acceleration, sample.acceleration);
    _field = _blend(_field, sample.magneticField);
    return CompassSample(acceleration: _acceleration!, magneticField: _field!);
  }

  void reset() {
    _acceleration = null;
    _field = null;
  }

  Vector3 _blend(Vector3? old, Vector3 fresh) =>
      old == null ? fresh : old * (1 - smoothing) + fresh * smoothing;
}
