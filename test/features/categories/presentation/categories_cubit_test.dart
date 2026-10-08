import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/state/load_status.dart';
import 'package:mynewapp/features/categories/presentation/state/categories_cubit.dart';

import '../../../support/fake_backend.dart';

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
  group('CategoriesCubit', () {
    test(
      'loads and exposes the tree: roots, children, grandchildren',
      () async {
        final api = FakeBackend();
        final cubit = CategoriesCubit(api);
        final states = await emitted(cubit, cubit.load);

        expect(states.map((s) => s.status), [
          LoadStatus.loading,
          LoadStatus.success,
        ]);
        final s = cubit.state;
        expect(s.roots.map((c) => c.id), ['1', '2']);
        expect(s.childrenOf('1').map((c) => c.id), ['8', '9']);
        expect(s.childrenOf('8').map((c) => c.id), ['20']);
        expect(s.hasChildren('1'), isTrue);
        expect(s.hasChildren('2'), isFalse);
        expect(s.byId('20')?.title, 'حفيد');
        await cubit.close();
      },
    );

    test(
      'roots never include sub-categories (regression: grid showed 20 mixed nodes)',
      () async {
        final cubit = CategoriesCubit(FakeBackend());
        await cubit.load();
        expect(cubit.state.roots.every((c) => c.isRoot), isTrue);
        expect(cubit.state.roots, hasLength(2));
        await cubit.close();
      },
    );

    test('loading twice, or concurrently, performs one request', () async {
      final api = FakeBackend()..gate = Completer<void>();
      final cubit = CategoriesCubit(api);
      final first = cubit.load();
      final second = cubit.load();
      api.gate!.complete();
      await Future.wait([first, second]);
      await cubit.load();
      expect(api.categoriesCalls, 1);
      await cubit.close();
    });

    test(
      'failure ends in a failure state (no endless loading) and retry recovers',
      () async {
        final api = FakeBackend()..categoriesFailure = noConnection;
        final cubit = CategoriesCubit(api);
        await cubit.load();
        expect(cubit.state.status, LoadStatus.failure);
        expect(cubit.state.failure!.kind, FailureKind.noConnection);

        await cubit.retry();
        expect(cubit.state.status, LoadStatus.success);
        expect(cubit.state.failure, isNull);
        expect(api.categoriesCalls, 2);
        await cubit.close();
      },
    );

    test('a failed refresh keeps the tree and reports the failure', () async {
      final api = FakeBackend();
      final cubit = CategoriesCubit(api);
      await cubit.load();
      api.categoriesFailure = const Failure(FailureKind.timeout);
      await cubit.refresh();
      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.roots, hasLength(2));
      expect(cubit.state.refreshFailure!.kind, FailureKind.timeout);
      await cubit.close();
    });

    test('the same refresh failure twice is observable twice', () async {
      final api = FakeBackend();
      final cubit = CategoriesCubit(api);
      await cubit.load();
      final failures = <Failure>[];
      final sub = cubit.stream.listen((s) {
        if (s.refreshFailure != null) failures.add(s.refreshFailure!);
      });
      for (var i = 0; i < 2; i++) {
        api.categoriesFailure = noConnection;
        await cubit.refresh();
      }
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(failures, hasLength(2));
      await cubit.close();
    });
  });
}
