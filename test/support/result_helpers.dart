import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/result/result.dart';

/// Typed access to a [Result] in tests (no loose casts).
extension ResultTestHelpers<T> on Result<T> {
  bool get ok => this is Success<T>;

  T get value => switch (this) {
    Success(:final value) => value,
    Err() => throw StateError('expected a success, got $this'),
  };

  Failure get failure => switch (this) {
    Err(:final failure) => failure,
    Success() => throw StateError('expected a failure, got $this'),
  };
}
