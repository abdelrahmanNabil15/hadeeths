import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/tokens.dart';

/// A heading that screen readers can jump to.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      header: true,
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppTextSize.heading,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}
