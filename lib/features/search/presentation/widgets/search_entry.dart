import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/widgets/app_card.dart';
import 'package:mynewapp/core/widgets/app_icons.dart';

/// A search-field look-alike for the home screen: tapping it opens the search screen. [raised]
/// gives it the soft shadow, for when it sits on the edge of the home header.
class SearchEntry extends StatelessWidget {
  const SearchEntry({
    super.key,
    required this.hint,
    required this.onTap,
    this.raised = false,
  });

  final String hint;
  final VoidCallback onTap;
  final bool raised;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: hint,
      excludeSemantics: true,
      onTap: onTap,
      child: AppCard(
        // The control's boundary: this colour meets the 3:1 non-text contrast.
        borderColor: scheme.outline,
        raised: raised,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSizes.minTouchTarget + 4,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(AppIcons.search, color: scheme.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    hint,
                    style: TextStyle(
                      fontSize: AppTextSize.body + 1,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
