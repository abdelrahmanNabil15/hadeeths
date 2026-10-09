import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/motion.dart';
import 'package:mynewapp/core/design_system/tokens.dart';

/// [next] (degrees) moved by whole turns so it is within 180 degrees of [previous]. An animation
/// between the two then takes the short way round (359 to 1 is a 2 degree move, not 358).
double unwrapAngle(double previous, double next) {
  var delta = (next - previous) % 360;
  if (delta > 180) delta -= 360;
  return previous + delta;
}

/// Builds with [angle] eased towards each new value over a short time, so a dial that receives a
/// reading about every degree moves smoothly. Only the drawing is eased: the reading itself (and
/// anything derived from it, such as "aligned") is untouched. A missing angle is shown at once, and
/// the next one appears without sweeping in from an old position. With "remove animations" on it
/// follows the reading directly.
class SmoothAngle extends StatefulWidget {
  const SmoothAngle({super.key, required this.angle, required this.builder});

  final double? angle;
  final Widget Function(BuildContext context, double? angle) builder;

  @override
  State<SmoothAngle> createState() => _SmoothAngleState();
}

class _SmoothAngleState extends State<SmoothAngle> {
  double? _target;

  @override
  void initState() {
    super.initState();
    _target = widget.angle;
  }

  @override
  void didUpdateWidget(SmoothAngle old) {
    super.didUpdateWidget(old);
    final next = widget.angle;
    final previous = _target;
    _target = next == null
        ? null
        : previous == null
        ? next
        : unwrapAngle(previous, next);
  }

  @override
  Widget build(BuildContext context) {
    final target = _target;
    if (target == null) return widget.builder(context, null);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: target),
      duration: context.motion(AppMotion.instant),
      curve: Curves.easeOut,
      builder: (context, value, _) => widget.builder(context, value),
    );
  }
}
