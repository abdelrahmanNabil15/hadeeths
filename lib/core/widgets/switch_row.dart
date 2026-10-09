import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/tokens.dart';

/// A card with a title, an optional line of explanation and a switch. The whole row is the control,
/// and a screen reader announces the title, the explanation and the state together.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;

  /// Null disables the row.
  final ValueChanged<bool>? onChanged;

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
      child: SwitchListTile(
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: AppTextSize.body + 1,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: TextStyle(
                  fontSize: AppTextSize.meta,
                  height: AppLineHeight.body,
                  color: scheme.onSurfaceVariant,
                ),
              ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
