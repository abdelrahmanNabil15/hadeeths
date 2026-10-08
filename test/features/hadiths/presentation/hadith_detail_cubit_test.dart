import 'package:bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/state/load_status.dart';
import 'package:mynewapp/features/hadiths/presentation/state/hadith_detail_cubit.dart';

import '../../../support/fake_backend.dart';
import '../../../support/fixtures.dart';

/// Runs [action] and returns every state the cubit emitted meanwhile.
Future<List<S>> emitted<S>(
  BlocBase<S> cubit,
  Future<void> Function() action,
) async {
  final states = <S>[];
  final sub = cubit.stream.listen(states.add);
  await action();
  await Future<void>.delayed(Duration.zero);
  await sub.cancel();
  return states;
}

void main() {
  group('HadithDetailCubit', () {
    test(
      'loads the hadith it was created for, independent of any list',
      () async {
        final api = FakeBackend();
        final cubit = HadithDetailCubit(api, '2962', language: 'ar');
        final states = await emitted(cubit, cubit.load);
        expect(states.map((s) => s.status), [
          LoadStatus.loading,
          LoadStatus.success,
        ]);
        expect(api.detailsRequests, ['2962']);
        expect(cubit.state.details!.id, '2962');
        await cubit.close();
      },
    );

    test('not found ends in a non-retryable failure', () async {
      final api = FakeBackend()
        ..detailsFailure = const Failure(FailureKind.notFound, statusCode: 404);
      final cubit = HadithDetailCubit(api, '1', language: 'ar');
      await cubit.load();
      expect(cubit.state.status, LoadStatus.failure);
      expect(cubit.state.failure!.isRetryable, isFalse);
      await cubit.close();
    });

    test('load after a failure recovers', () async {
      final api = FakeBackend()..detailsFailure = noConnection;
      final cubit = HadithDetailCubit(api, '1', language: 'ar');
      await cubit.load();
      await cubit.load();
      expect(cubit.state.status, LoadStatus.success);
      await cubit.close();
    });

    test('an English response without a reference loads fine', () async {
      final api = FakeBackend(details: sampleDetails(englishDetailsJson));
      final cubit = HadithDetailCubit(api, '2962', language: 'ar');
      await cubit.load();
      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.details!.reference, isEmpty);
      await cubit.close();
    });
  });
}
