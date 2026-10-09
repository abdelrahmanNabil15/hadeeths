import 'package:flutter/widgets.dart';
import 'package:mynewapp/core/design_system/motion.dart';
import 'package:mynewapp/core/design_system/tokens.dart';

/// Shrinks its child very slightly while a finger is on it. For large tappable cards only.
///
/// It watches the pointer without taking part in the gesture, so the child's own tap, long press
/// and scrolling work exactly as before. With "remove animations" on it does nothing.
class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child});

  final Widget child;

  /// How small it gets (a 2% change is visible but never moves the layout around it).
  static const pressedScale = 0.98;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? PressableScale.pressedScale : 1,
        duration: AppMotion.instant,
        curve: AppMotion.standard,
        child: widget.child,
      ),
    );
  }
}
