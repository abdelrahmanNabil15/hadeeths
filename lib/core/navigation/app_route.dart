import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/motion.dart';
import 'package:mynewapp/core/design_system/tokens.dart';

/// A page route with the app's own transition, chosen per call site (it is not the default).
///
/// - iOS keeps the platform slide, including swipe-back.
/// - Elsewhere the page fades in with a very small upward move; going back is faster.
/// - With "remove animations" on, nothing moves.
///
/// The move is vertical, so it needs no change for right-to-left layouts, and it is applied to
/// the whole page: nothing inside a reading screen moves on its own.
Route<T> appRoute<T>({
  required WidgetBuilder builder,
  RouteSettings? settings,
  bool fullscreenDialog = false,
}) => AppPageRoute<T>(
  builder: builder,
  settings: settings,
  fullscreenDialog: fullscreenDialog,
);

class AppPageRoute<T> extends MaterialPageRoute<T> {
  AppPageRoute({
    required super.builder,
    super.settings,
    super.fullscreenDialog,
  });

  /// Whether the system asks for no animations. Read from the navigator the route lives in, so
  /// the page is simply there (no waiting for a transition to run its time) when it is on.
  bool get _removeAnimations {
    final context = navigator?.context;
    return context != null &&
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
  }

  @override
  Duration get transitionDuration =>
      _removeAnimations ? Duration.zero : AppMotion.page;

  @override
  Duration get reverseTransitionDuration =>
      _removeAnimations ? Duration.zero : AppMotion.pageReverse;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return super.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
    if (context.reduceMotion) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.enter,
      reverseCurve: AppMotion.exit,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
