import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/tokens.dart';

/// Centres [child] and caps its width so lines stay readable on large screens.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
      child: child,
    ),
  );
}
