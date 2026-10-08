import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/widgets/custom_text.dart';

/// The rounded white card used for category entries (same look as the original grid).
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.semanticLabel,
  });

  final String title;
  final String? subtitle;

  /// Overrides the screen-reader text (title and count in the user's language).
  final String? semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel ?? title,
      excludeSemantics: true,
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
          border: Border.all(color: AppColors.cardBorder, width: 0.7),
          borderRadius: BorderRadius.circular(AppRadius.card),
          color: AppColors.cardFill,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  fontWeight: FontWeight.bold,
                  alignment: Alignment.center,
                  text: title,
                  fontSize: AppTextSize.title,
                ),
                if (subtitle != null)
                  CustomText(
                    fontWeight: FontWeight.normal,
                    alignment: Alignment.center,
                    color: AppColors.inkMuted,
                    text: subtitle!,
                    fontSize: AppTextSize.meta,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
