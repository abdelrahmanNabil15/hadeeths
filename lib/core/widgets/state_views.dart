import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/errors/failure.dart';
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
    child: const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.appBar),
      ),
    ),
  );
}

/// A failure with a retry action. Announced to screen readers when it appears.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.failure, this.onRetry});

  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
              Icon(
                offline ? Icons.wifi_off : Icons.error_outline,
                size: 48,
                color: AppColors.heading,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                failureMessage(l10n, failure),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: AppTextSize.title),
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
  const EmptyView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Semantics(
        liveRegion: true,
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: AppTextSize.title),
        ),
      ),
    ),
  );
}

/// Shows [failure] as a transient message, e.g. when a refresh failed but old data stays visible.
void showFailureSnackBar(BuildContext context, Failure failure) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(failureMessage(context.l10n, failure))),
    );
}
