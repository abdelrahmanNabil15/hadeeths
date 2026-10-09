import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/app_colors.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/design_system/typography.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/widgets/geometric_pattern.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// User-facing text for a failure. Never shows raw exception text.
String failureMessage(AppLocalizations l10n, Failure failure) {
  switch (failure.kind) {
    case FailureKind.noConnection:
      return l10n.errorNoConnection;
    case FailureKind.timeout:
      return l10n.errorTimeout;
    case FailureKind.server:
      return l10n.errorServer;
    case FailureKind.notFound:
      return l10n.errorNotFound;
    case FailureKind.parse:
      return l10n.errorParse;
    case FailureKind.unexpected:
      return l10n.errorUnexpected;
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.loading,
    liveRegion: true,
    child: const Center(child: CircularProgressIndicator()),
  );
}

/// Grey placeholder rows shown while a list loads. Static (no animation), announced once
/// as "Loading".
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.count = 7,
    this.rowHeight = AppSizes.minTileHeight,
  });

  final int count;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: context.l10n.loading,
      liveRegion: true,
      excludeSemantics: true,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: count,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) => DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: SizedBox(height: rowHeight, width: double.infinity),
        ),
      ),
    );
  }
}

/// A failure with a retry action. Announced to screen readers when it appears.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.failure, this.onRetry});

  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final offline = failure.kind == FailureKind.noConnection;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Semantics(
          liveRegion: true,
          container: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StateMedallion(
                icon: offline ? Icons.wifi_off : Icons.error_outline,
                color: offline ? scheme.primary : scheme.error,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                failureMessage(l10n, failure),
                textAlign: TextAlign.center,
                style: AppTypography.of(context).editorial,
              ),
              if (onRetry != null && failure.isRetryable) ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message, this.icon});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // Scrolls when the space is short (a small box, very large text) instead of overflowing.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Semantics(
          liveRegion: true,
          container: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                StateMedallion(icon: icon!),
                const SizedBox(height: AppSpacing.xl),
              ],
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.of(context).editorial,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The round emblem of an empty or error state: a sage disc with a faint star lattice and the
/// state's icon. Decoration only; the words carry the meaning.
class StateMedallion extends StatelessWidget {
  const StateMedallion({super.key, required this.icon, this.color});

  final IconData icon;

  /// The icon colour; the brand colour by default.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: AppSizes.stateMedallion,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.sage,
            shape: BoxShape.circle,
            border: Border.all(color: colors.goldSoft),
          ),
          child: ClipOval(
            child: Stack(
              fit: StackFit.expand,
              children: [
                GeometricPattern(
                  color: colors.gold.withValues(alpha: 0.16),
                  tileSize: AppSizes.stateMedallion / 3,
                ),
                Icon(
                  icon,
                  size: AppSizes.stateMedallion * 0.4,
                  color: color ?? Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows [failure] as a transient message, e.g. when a refresh failed but old data stays visible.
void showFailureSnackBar(BuildContext context, Failure failure) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(failureMessage(context.l10n, failure))),
    );
}
