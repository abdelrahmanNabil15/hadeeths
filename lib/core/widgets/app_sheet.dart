import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/design_system/typography.dart';

/// One choice in an options sheet.
class SheetOption<T> {
  const SheetOption({
    required this.value,
    required this.label,
    required this.icon,
  });

  final T value;
  final String label;
  final IconData icon;
}

/// A bottom sheet offering a short list of choices; returns the chosen value, or null when the
/// sheet is dismissed. Shape, handle and colours come from the sheet theme, so every options sheet
/// in the app looks the same. Each row is a full-width button at least 56 dp high.
Future<T?> showOptionsSheet<T>(
  BuildContext context, {
  required List<SheetOption<T>> options,
  String? title,
}) => showModalBottomSheet<T>(
  context: context,
  builder: (sheetContext) {
    final scheme = Theme.of(sheetContext).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: AppTypography.of(sheetContext).heading,
                  ),
                ),
              ),
            for (final option in options)
              ListTile(
                minTileHeight: AppSizes.minTileHeight,
                leading: Icon(option.icon, color: scheme.primary),
                title: Text(
                  option.label,
                  style: AppTypography.of(
                    sheetContext,
                  ).body.copyWith(fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.of(sheetContext).pop(option.value),
              ),
          ],
        ),
      ),
    );
  },
);
