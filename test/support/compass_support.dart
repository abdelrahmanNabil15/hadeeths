import 'dart:math' as math;

import 'package:mynewapp/features/prayer_times/domain/heading_calculator.dart';

double _rad(double d) => d * math.pi / 180;

/// What the sensors would read for a phone at a given orientation in a field of a given dip.
///
/// World axes: east, north, up. The phone starts flat, screen up, top edge pointing at [heading]
/// (degrees clockwise from magnetic north). Then it is tilted: [pitch] raises the top edge,
/// [roll] raises the right edge.
CompassSample simulate({
  required double heading,
  double pitch = 0,
  double roll = 0,
  double dip = 40,
  double field = 45,
}) {
  final h = _rad(heading);
  final p = _rad(pitch);
  final r = _rad(roll);
  const up = Vector3(0, 0, 1);
  final x0 = Vector3(math.cos(h), -math.sin(h), 0);
  final y0 = Vector3(math.sin(h), math.cos(h), 0);
  final y1 = y0 * math.cos(p) + up * math.sin(p);
  final z1 = y0 * -math.sin(p) + up * math.cos(p);
  final x2 = x0 * math.cos(r) + z1 * -math.sin(r);
  final z2 = x0 * math.sin(r) + z1 * math.cos(r);
  final y2 = y1;
  Vector3 inDevice(Vector3 world) =>
      Vector3(x2.dot(world), y2.dot(world), z2.dot(world));
  final d = _rad(dip);
  final earth = Vector3(0, field * math.cos(d), -field * math.sin(d));
  return CompassSample(
    acceleration: inDevice(up * 9.81),
    magneticField: inDevice(earth),
  );
}
