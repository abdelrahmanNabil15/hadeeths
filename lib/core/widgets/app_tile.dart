import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/app_colors.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/widgets/app_card.dart';
import 'package:mynewapp/core/widgets/app_icons.dart';
import 'package:mynewapp/core/widgets/pressable_scale.dart';

/// A full-width tappable row on an [AppCard]: optional leading icon, title, optional trailing
/// count (in a sage pill) and a chevron that follows the text direction. At least 56 dp high; grows
/// with the text.
class AppTile extends StatelessWidget {
  const AppTile({
    super.key,
    required this.title,
    required this.onTap,
    this.trailingText,
    this.semanticLabel,
    this.emphasized = false,
    this.maxTitleLines,
    this.pressFeedback = false,
    this.leadingIcon,
  });

  final String title;
  final String? trailingText;

  /// Overrides the screen-reader text (for example title and count in the user's language).
  final String? semanticLabel;
  final VoidCallback onTap;

  /// Uses the brand container colour; for the one primary entry on a screen.
  final bool emphasized;
  final int? maxTitleLines;

  /// Shrinks the tile slightly while pressed. Off by default so existing screens look as before.
  final bool pressFeedback;

  /// A small icon before the title, in the brand colour (for navigation rows such as More).
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = AppColors.of(context);
    final foreground = emphasized
        ? scheme.onPrimaryContainer
        : scheme.onSurface;
    final muted = emphasized
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;
    final tile = Semantics(
      button: true,
      label: semanticLabel ?? title,
      excludeSemantics: true,
      onTap: onTap,
      child: AppCard(
        emphasized: emphasized,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTileHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, size: AppSizes.icon, color: scheme.primary),
                  const SizedBox(width: AppSpacing.md),
                ],
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
                  _CountPill(
                    text: trailingText!,
                    background: emphasized ? null : colors.sage,
                    foreground: emphasized ? muted : colors.onSage,
                  ),
                ],
                const SizedBox(width: AppSpacing.sm),
                Icon(AppIcons.chevron, size: AppSizes.iconSmall, color: muted),
              ],
            ),
          ),
        ),
      ),
    );
    return pressFeedback ? PressableScale(child: tile) : tile;
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color? background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs / 2,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppTextSize.meta - 1,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    ),
  );
}
