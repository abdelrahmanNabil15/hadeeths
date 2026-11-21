import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/app_colors.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/design_system/typography.dart';
import 'package:mynewapp/core/widgets/app_card.dart';

/// One row in a translation/tafsir/reciter edition picker: title, optional subtitle (author), a
/// gold border and a check mark when selected.
class EditionTile extends StatelessWidget {
  const EditionTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = AppColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: subtitle == null ? title : '$title, $subtitle',
      excludeSemantics: true,
      onTap: onTap,
      child: AppCard(
        onTap: onTap,
        borderColor: selected ? colors.gold : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.of(
                        context,
                      ).body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (subtitle != null)
                      Text(subtitle!, style: AppTypography.of(context).meta),
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.check, color: scheme.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
