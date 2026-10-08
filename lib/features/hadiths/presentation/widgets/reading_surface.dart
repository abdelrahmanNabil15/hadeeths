import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/features/settings/presentation/widgets/reading_text.dart';

/// The hadith text on a calm, bordered surface, in the reading font at the user's reading
/// size. The text is shown exactly as received and can be selected.
class ReadingSurface extends StatelessWidget {
  const ReadingSurface({super.key, required this.text, required this.scale});

  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl - AppSpacing.xs),
        child: SelectionArea(
          child: Text(text, style: readingTextStyle(context, scale: scale)),
        ),
      ),
    );
  }
}

/// Who reported the hadith and how it is graded, as given by the source. The grade is shown
/// as a word in a chip (never by colour alone) and nothing is added or inferred.
class SourceBlock extends StatelessWidget {
  const SourceBlock({
    super.key,
    required this.attribution,
    required this.grade,
  });

  final String attribution;
  final String grade;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (grade.isNotEmpty)
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs + 2,
              ),
              child: Text(
                grade,
                style: TextStyle(
                  fontSize: AppTextSize.body,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
          ),
        if (attribution.isNotEmpty)
          SelectionArea(
            child: Text(
              attribution,
              style: TextStyle(
                fontSize: AppTextSize.body,
                height: AppLineHeight.body,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
