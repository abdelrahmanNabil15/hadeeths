import 'package:flutter/widgets.dart';
import 'package:mynewapp/core/design_system/motion.dart';
import 'package:mynewapp/core/design_system/tokens.dart';

/// Fades between the states of one area (loading, content, error). Give each state its own
/// `key`; a change of key starts the fade, a rebuild with the same key does nothing.
///
/// The new state is in the tree immediately, so it can be tapped and read at once; only its
/// opacity animates. With "remove animations" on, the states simply swap.
class AnimatedStateSwitcher extends StatelessWidget {
  const AnimatedStateSwitcher({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return child;
    return AnimatedSwitcher(
      duration: AppMotion.medium,
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.topStart,
        children: [...previous, ?current],
      ),
      child: child,
    );
  }
}
