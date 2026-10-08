import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/tokens.dart';

/// A full-width tappable row: title, optional muted trailing text (for example a count) and
/// a chevron that follows the text direction. At least 56 dp high; grows with the text.
class AppTile extends StatelessWidget {
  const AppTile({
    super.key,
    required this.title,
    required this.onTap,
    this.trailingText,
    this.semanticLabel,
    this.emphasized = false,
    this.maxTitleLines,
  });

  final String title;
  final String? trailingText;

  /// Overrides the screen-reader text (for example title and count in the user's language).
  final String? semanticLabel;
  final VoidCallback onTap;

  /// Uses the brand container colour; for the one primary entry on a screen.
  final bool emphasized;
  final int? maxTitleLines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = emphasized
        ? scheme.primaryContainer
        : scheme.surfaceContainerLowest;
    final foreground = emphasized
        ? scheme.onPrimaryContainer
        : scheme.onSurface;
    final muted = emphasized
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      label: semanticLabel ?? title,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: emphasized
                ? scheme.primary.withValues(alpha: 0.35)
                : scheme.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.minTileHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: maxTitleLines,
                      overflow: maxTitleLines == null
                          ? null
                          : TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppTextSize.body + 1,
                        fontWeight: FontWeight.w600,
                        height: AppLineHeight.body,
                        color: foreground,
                      ),
                    ),
                  ),
                  if (trailingText != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      trailingText!,
                      style: TextStyle(
                        fontSize: AppTextSize.meta,
                        color: muted,
                      ),
                    ),
                  ],
                  const SizedBox(width: AppSpacing.sm),
                  Icon(Icons.arrow_forward_ios, size: 16, color: muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
