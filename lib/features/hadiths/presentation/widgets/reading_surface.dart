import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/app_colors.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/widgets/app_card.dart';
import 'package:mynewapp/features/settings/presentation/widgets/reading_text.dart';

/// The hadith text on a calm, raised reading surface with generous margins, in the reading font at
/// the user's reading size. The text is shown exactly as received and can be selected. No pattern
/// or ornament is ever drawn behind it.
class ReadingSurface extends StatelessWidget {
  const ReadingSurface({super.key, required this.text, required this.scale});

  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      raised: true,
      color: AppColors.of(context).readingSurface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl + AppSpacing.xs,
      ),
      child: SelectionArea(
        child: Text(text, style: readingTextStyle(context, scale: scale)),
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
              borderRadius: BorderRadius.circular(AppRadius.pill),
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
