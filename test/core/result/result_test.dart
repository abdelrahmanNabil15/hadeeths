import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/result/result.dart';

void main() {
  group('Result.guard', () {
    test('wraps a value in Success', () async {
      final result = await Result.guard(() async => 42);
      expect(result, isA<Success<int>>());
      expect((result as Success<int>).value, 42);
    });

    test('turns a thrown Failure into Err with the same failure', () async {
      const failure = Failure(FailureKind.timeout);
      final result = await Result.guard<int>(() async => throw failure);
      expect((result as Err<int>).failure, failure);
    });

    test(
      'reports any other exception as unexpected instead of throwing',
      () async {
        final result = await Result.guard<int>(
          () async => throw StateError('x'),
        );
        expect((result as Err<int>).failure.kind, FailureKind.unexpected);
      },
    );
  });

  group('map', () {
    test('transforms a success', () {
      final mapped = const Success(2).map((v) => v * 10);
      expect((mapped as Success<int>).value, 20);
    });

    test('passes a failure through untouched', () {
      const failure = Failure(FailureKind.noConnection);
      final mapped = const Err<int>(failure).map((v) => v * 10);
      expect((mapped as Err<int>).failure, failure);
    });
  });

  test('exhaustive pattern matching compiles for both cases', () {
    String describe(Result<int> r) => switch (r) {
      Success(:final value) => 'ok $value',
      Err(:final failure) => 'err ${failure.kind.name}',
    };
    expect(describe(const Success(1)), 'ok 1');
    expect(describe(const Err(Failure(FailureKind.parse))), 'err parse');
  });
}
