import 'package:flutter/material.dart';
import 'package:mynewapp/core/constants/app_colors.dart';
import 'package:mynewapp/core/errors/failure.dart';

/// User-facing Arabic text for a failure. Never shows raw exception text.
String failureMessage(Failure failure) {
  switch (failure.kind) {
    case FailureKind.noConnection:
      return 'لا يوجد اتصال بالإنترنت';
    case FailureKind.timeout:
      return 'انتهت مهلة الاتصال بالخادم';
    case FailureKind.server:
      return 'حدث خطأ في الخادم، حاول مرة أخرى لاحقًا';
    case FailureKind.notFound:
      return 'هذا المحتوى غير متوفر';
    case FailureKind.parse:
      return 'تعذّر قراءة البيانات المستلمة';
    case FailureKind.unexpected:
      return 'حدث خطأ غير متوقع';
  }
}

const _fontFamily = 'Schyler';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(appbarColor),
    ),
  );
}

/// A failure with a retry action. Always scrollable so pull-to-refresh style parents work.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.failure, this.onRetry});

  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final offline = failure.kind == FailureKind.noConnection;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              offline ? Icons.wifi_off : Icons.error_outline,
              size: 48,
              color: mainColor,
            ),
            const SizedBox(height: 16),
            Text(
              failureMessage(failure),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontFamily: _fontFamily, fontSize: 18),
            ),
            if (onRetry != null && failure.isRetryable) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(fontFamily: _fontFamily),
                ),
              ),
            ],
          ],
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
      padding: const EdgeInsets.all(24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontFamily: _fontFamily, fontSize: 18),
      ),
    ),
  );
}

/// Shows [failure] as a transient message, e.g. when a refresh failed but old data stays visible.
void showFailureSnackBar(BuildContext context, Failure failure) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          failureMessage(failure),
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontFamily: _fontFamily),
        ),
      ),
    );
}
