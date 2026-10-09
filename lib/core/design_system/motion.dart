import 'package:flutter/widgets.dart';

/// Whether the system asks apps to remove animations ("remove animations" on Android, "Reduce
/// Motion" on iOS). Every animation in the app goes through this.
extension MotionContext on BuildContext {
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);

  /// [duration], or zero when animations are switched off.
  Duration motion(Duration duration) => reduceMotion ? Duration.zero : duration;
}
