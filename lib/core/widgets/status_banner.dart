import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/app_colors.dart';
import 'package:mynewapp/core/design_system/tokens.dart';

enum StatusKind { info, success, warning, error }

/// A short message about the state of something (a permission, a failed step), with an optional
/// action. The kind is also given by the icon and the words, never by colour alone, and the
/// message is announced to screen readers when it appears.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    this.kind = StatusKind.info,
    this.actionLabel,
    this.onAction,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'give both an action label and a callback, or neither',
       );

  final String message;
  final StatusKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = AppColors.of(context);
    final (background, foreground, icon) = switch (kind) {
      StatusKind.info => (
        scheme.surfaceContainerLowest,
        scheme.onSurface,
        Icons.info_outline,
      ),
      StatusKind.success => (
        colors.successContainer,
        colors.onSuccessContainer,
        Icons.check_circle_outline,
      ),
      StatusKind.warning => (
        colors.warningContainer,
        colors.onWarningContainer,
        Icons.warning_amber_outlined,
      ),
      StatusKind.error => (
        scheme.surfaceContainerLowest,
        scheme.onSurface,
        Icons.error_outline,
      ),
    };
    final border = kind == StatusKind.error ? scheme.error : scheme.outline;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: AppSizes.iconSmall,
                  color: kind == StatusKind.error ? scheme.error : foreground,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: AppTextSize.body,
                      height: AppLineHeight.body,
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
            if (actionLabel != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
      ),
    );
  }
}
