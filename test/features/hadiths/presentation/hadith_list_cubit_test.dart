import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/state/load_status.dart';
import 'package:mynewapp/features/hadiths/presentation/state/hadith_list_cubit.dart';

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
  group('HadithListCubit', () {
    FakeBackend twoPages() => FakeBackend(
      pages: {
        '8:1': samplePage(ids: ['1', '2'], page: 1, lastPage: 2, totalItems: 4),
        '8:2': samplePage(ids: ['3', '4'], page: 2, lastPage: 2, totalItems: 4),
      },
    );

    test('loads page one and follows last_page', () async {
      final api = twoPages();
      final cubit = HadithListCubit(api, '8');
      await cubit.load();
      expect(cubit.state.items.map((h) => h.id), ['1', '2']);
      expect(cubit.state.hasMore, isTrue);

      await cubit.loadMore();
      expect(cubit.state.items.map((h) => h.id), ['1', '2', '3', '4']);
      expect(cubit.state.hasMore, isFalse);
      expect(api.pageRequests, ['8:1', '8:2']);

      await cubit.loadMore(); // nothing left: must not call the API
      expect(api.pageRequests, hasLength(2));
      await cubit.close();
    });

    test(
      'never re-requests page one while paging (regression: always fetched page 1)',
      () async {
        final api = twoPages();
        final cubit = HadithListCubit(api, '8');
        await cubit.load();
        await cubit.loadMore();
        expect(api.pageRequests.where((r) => r == '8:1'), hasLength(1));
        await cubit.close();
      },
    );

    test('item count is the loaded count, not the advertised total', () async {
      final api = FakeBackend(
        pages: {
          '8:1': samplePage(
            ids: List.generate(449, (i) => '$i'),
            totalItems: 450,
          ),
        },
      );
      final cubit = HadithListCubit(api, '8');
      await cubit.load();
      expect(cubit.state.items, hasLength(449));
      expect(cubit.state.totalItems, 450);
      expect(cubit.state.hasMore, isFalse);
      await cubit.close();
    });

    test('concurrent loadMore calls fetch the next page once', () async {
      final api = twoPages();
      final cubit = HadithListCubit(api, '8');
      await cubit.load();
      api.gate = Completer<void>();
      final a = cubit.loadMore();
      final b = cubit.loadMore();
      api.gate!.complete();
      await Future.wait([a, b]);
      expect(api.pageRequests.where((r) => r == '8:2'), hasLength(1));
      await cubit.close();
    });

    test('duplicate ids across pages are not shown twice', () async {
      final api = FakeBackend(
        pages: {
          '8:1': samplePage(ids: ['1', '2'], page: 1, lastPage: 2),
          '8:2': samplePage(ids: ['2', '3'], page: 2, lastPage: 2),
        },
      );
      final cubit = HadithListCubit(api, '8');
      await cubit.load();
      await cubit.loadMore();
      expect(cubit.state.items.map((h) => h.id), ['1', '2', '3']);
      await cubit.close();
    });

    test(
      'an empty page before last_page stops paging instead of looping',
      () async {
        final api = FakeBackend(
          pages: {
            '8:1': samplePage(ids: ['1'], page: 1, lastPage: 5),
            '8:2': samplePage(ids: [], page: 2, lastPage: 5),
          },
        );
        final cubit = HadithListCubit(api, '8');
        await cubit.load();
        await cubit.loadMore();
        expect(cubit.state.hasMore, isFalse);
        await cubit.loadMore();
        expect(api.pageRequests, ['8:1', '8:2']);
        await cubit.close();
      },
    );

    test(
      'first-page failure ends in failure; retry via load recovers',
      () async {
        final api = twoPages()..pageFailure = noConnection;
        final cubit = HadithListCubit(api, '8');
        await cubit.load();
        expect(cubit.state.status, LoadStatus.failure);
        await cubit.load();
        expect(cubit.state.status, LoadStatus.success);
        await cubit.close();
      },
    );

    test(
      'a failed next page keeps the loaded items and can be retried',
      () async {
        final api = twoPages();
        final cubit = HadithListCubit(api, '8');
        await cubit.load();
        api.pageFailure = const Failure(FailureKind.timeout);
        await cubit.loadMore();
        expect(cubit.state.items, hasLength(2));
        expect(cubit.state.loadMoreFailure!.kind, FailureKind.timeout);
        expect(cubit.state.isLoadingMore, isFalse);

        await cubit.loadMore();
        expect(cubit.state.items, hasLength(4));
        expect(cubit.state.loadMoreFailure, isNull);
        await cubit.close();
      },
    );

    test(
      'a failed refresh keeps the list; a good refresh replaces it',
      () async {
        final api = twoPages();
        final cubit = HadithListCubit(api, '8');
        await cubit.load();
        await cubit.loadMore();
        api.pageFailure = noConnection;
        await cubit.refresh();
        expect(cubit.state.items, hasLength(4));
        expect(cubit.state.refreshFailure!.kind, FailureKind.noConnection);

        await cubit.refresh();
        expect(cubit.state.items, hasLength(2)); // back to page one
        expect(cubit.state.refreshFailure, isNull);
        await cubit.close();
      },
    );

    test('a slow next page that arrives after a refresh is ignored', () async {
      final api = twoPages();
      final cubit = HadithListCubit(api, '8');
      await cubit.load();
      api.gate = Completer<void>();
      final slow = cubit.loadMore();
      final refresh = cubit.refresh();
      api.gate!.complete();
      await Future.wait([slow, refresh]);
      expect(cubit.state.items.map((h) => h.id), ['1', '2']);
      expect(cubit.state.currentPage, 1);
      await cubit.close();
    });

    test('an empty category is an empty success', () async {
      final api = FakeBackend(pages: {'8:1': samplePage(ids: [])});
      final cubit = HadithListCubit(api, '8');
      await cubit.load();
      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.items, isEmpty);
      await cubit.close();
    });
  });
}
