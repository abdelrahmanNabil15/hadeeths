import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/Modules/categories/categories_cubit.dart';
import 'package:mynewapp/Modules/hadiths/hadith_detail_cubit.dart';
import 'package:mynewapp/Modules/hadiths/hadith_list_cubit.dart';
import 'package:mynewapp/Shared/errors/failure.dart';

import '../support/fake_api.dart';
import '../support/fixtures.dart';

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
        final api = FakeHadeethApi();
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
        final cubit = CategoriesCubit(FakeHadeethApi());
        await cubit.load();
        expect(cubit.state.roots.every((c) => c.isRoot), isTrue);
        expect(cubit.state.roots, hasLength(2));
        await cubit.close();
      },
    );

    test('loading twice, or concurrently, performs one request', () async {
      final api = FakeHadeethApi()..gate = Completer<void>();
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
        final api = FakeHadeethApi()..categoriesFailure = noConnection;
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
      final api = FakeHadeethApi();
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
      final api = FakeHadeethApi();
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

  group('HadithListCubit', () {
    FakeHadeethApi twoPages() => FakeHadeethApi(
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
      final api = FakeHadeethApi(
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
      final api = FakeHadeethApi(
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
        final api = FakeHadeethApi(
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
      final api = FakeHadeethApi(pages: {'8:1': samplePage(ids: [])});
      final cubit = HadithListCubit(api, '8');
      await cubit.load();
      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.items, isEmpty);
      await cubit.close();
    });
  });

  group('HadithDetailCubit', () {
    test(
      'loads the hadith it was created for, independent of any list',
      () async {
        final api = FakeHadeethApi();
        final cubit = HadithDetailCubit(api, '2962');
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
      final api = FakeHadeethApi()
        ..detailsFailure = const Failure(FailureKind.notFound, statusCode: 404);
      final cubit = HadithDetailCubit(api, '1');
      await cubit.load();
      expect(cubit.state.status, LoadStatus.failure);
      expect(cubit.state.failure!.isRetryable, isFalse);
      await cubit.close();
    });

    test('load after a failure recovers', () async {
      final api = FakeHadeethApi()..detailsFailure = noConnection;
      final cubit = HadithDetailCubit(api, '1');
      await cubit.load();
      await cubit.load();
      expect(cubit.state.status, LoadStatus.success);
      await cubit.close();
    });

    test('an English response without a reference loads fine', () async {
      final api = FakeHadeethApi(details: sampleDetails(englishDetailsJson));
      final cubit = HadithDetailCubit(api, '2962');
      await cubit.load();
      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.details!.reference, isEmpty);
      await cubit.close();
    });
  });
}
