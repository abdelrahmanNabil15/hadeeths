import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/design_system/typography.dart';

/// The quiet label above a group of cards, aligned with the text inside them. A heading that
/// screen readers can jump to.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
        child: Text(text, style: AppTypography.of(context).sectionLabel),
      ),
    );
  }
}
