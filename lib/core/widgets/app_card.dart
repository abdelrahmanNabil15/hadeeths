import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/tokens.dart';

/// The app's one surface for grouped content: card colour, 16 dp corners and a hairline edge.
/// Tiles, option groups, the search field look-alike and the reading surface are all built on it,
/// so every card in the app has the same shape and edge.
///
/// - [onTap] adds an ink response clipped to the shape (semantics stay with the caller).
/// - [emphasized] uses the sage brand container, for the one primary entry on a screen.
/// - [raised] adds the single soft shadow ([AppShadows.soft]); flat otherwise.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.emphasized = false,
    this.raised = false,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final bool emphasized;
  final bool raised;

  /// Overrides the surface colour (for example the reading surface role).
  final Color? color;

  /// Overrides the hairline, for example [ColorScheme.outline] where the edge marks a control and
  /// must reach 3:1.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.card);
    final content = padding == null
        ? child
        : Padding(padding: padding!, child: child);
    final card = Material(
      color:
          color ??
          (emphasized
              ? scheme.primaryContainer
              : scheme.surfaceContainerLowest),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color:
              borderColor ??
              (emphasized
                  ? scheme.primary.withValues(alpha: 0.3)
                  : scheme.outlineVariant),
          width: AppBorders.hairline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
    if (!raised) return card;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppShadows.soft(scheme),
      ),
      child: card,
    );
  }
}
