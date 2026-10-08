import 'package:mynewapp/core/errors/failure.dart';

/// Outcome of an operation that can fail in an expected way.
///
/// Repositories return a [Result] instead of throwing, so callers must handle both
/// cases. Use pattern matching:
///
/// ```dart
/// switch (result) {
///   case Success(:final value): ...
///   case Err(:final failure): ...
/// }
/// ```
sealed class Result<T> {
  const Result();

  /// Runs [action] and captures its outcome. A thrown [Failure] becomes an [Err];
  /// anything else is reported as an unexpected failure instead of escaping into the UI.
  static Future<Result<T>> guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } on Failure catch (failure) {
      return Err(failure);
    } catch (error) {
      return Err(Failure(FailureKind.unexpected, debugMessage: '$error'));
    }
  }

  /// Transforms the value of a success; a failure is passed through unchanged.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Success(:final value) => Success(transform(value)),
    Err(:final failure) => Err(failure),
  };
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}
