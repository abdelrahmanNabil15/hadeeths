import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/tokens.dart';

/// A mutually exclusive list of choices; the chosen one shows a check mark (not colour alone).
/// Each choice may carry a smaller line of explanation under its label.
class OptionGroup<T> extends StatelessWidget {
  const OptionGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.subtitles,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;

  /// Optional explanation for each option, in the same order; read aloud with the label.
  final List<String?>? subtitles;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const Divider(),
            _row(context, scheme, i),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, ColorScheme scheme, int i) {
    final value = options[i].$1;
    final label = options[i].$2;
    final subtitle = subtitles == null ? null : subtitles![i];
    final isSelected = value == selected;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: isSelected,
      button: true,
      label: subtitle == null ? label : '$label. $subtitle',
      excludeSemantics: true,
      onTap: () => onSelected(value),
      child: InkWell(
        onTap: () => onSelected(value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTileHeight),
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
                        label,
                        style: TextStyle(
                          fontSize: AppTextSize.body + 1,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: scheme.onSurface,
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: AppTextSize.meta,
                              height: AppLineHeight.body,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected) Icon(Icons.check_circle, color: scheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
