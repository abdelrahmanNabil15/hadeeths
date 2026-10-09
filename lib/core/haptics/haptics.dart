import 'package:flutter/services.dart';

/// Short physical feedback. It only ever accompanies something already visible, so nothing
/// depends on it, and there is no in-app switch: it follows the system's own touch-feedback
/// settings (the platform decides whether to vibrate).
abstract interface class Haptics {
  /// A choice was made (a switch, an option).
  void selection();

  /// Something important became true (for example the compass is aligned).
  void alignment();
}

class SystemHaptics implements Haptics {
  const SystemHaptics();

  @override
  void selection() => HapticFeedback.selectionClick();

  @override
  void alignment() => HapticFeedback.mediumImpact();
}
