import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/cache/cached_fetcher.dart';
import 'package:mynewapp/core/cache/file_response_cache.dart';
import 'package:mynewapp/core/cache/response_cache.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/features/categories/data/categories_remote_data_source.dart';
import 'package:mynewapp/features/categories/data/categories_repository_impl.dart';
import 'package:mynewapp/features/hadiths/data/hadiths_remote_data_source.dart';
import 'package:mynewapp/features/hadiths/data/hadiths_repository_impl.dart';

import '../../support/fake_server.dart';
import '../../support/fixtures.dart';
import '../../support/result_helpers.dart';

typedef _Repos = ({
  CategoriesRepositoryImpl categories,
  HadithsRepositoryImpl hadiths,
});

_Repos _repositories(
  FakeServer server,
  ResponseCache cache, {
  DateTime Function()? now,
}) {
  final client = server.client;
  final fetcher = CachedFetcher(cache, now: now);
  return (
    categories: CategoriesRepositoryImpl(
      HttpCategoriesRemoteDataSource(client, fetcher),
    ),
    hadiths: HadithsRepositoryImpl(
      HttpHadithsRemoteDataSource(client, fetcher),
    ),
  );
}

void main() {
  late FakeServer server;
  late InMemoryResponseCache cache;
  setUp(() {
    server = FakeServer();
    cache = InMemoryResponseCache();
  });

  group('content that was opened while online stays readable offline', () {
    test('categories', () async {
      final repos = _repositories(server, cache);
      expect((await repos.categories.getCategories(language: 'ar')).ok, isTrue);
      server.online = false;
      final offline = await repos.categories.getCategories(language: 'ar');
      expect(offline.ok, isTrue);
      expect(offline.value, hasLength(5));
    });

    test('a hadith list page', () async {
      final repos = _repositories(server, cache);
      await repos.hadiths.getHadithPage(categoryId: '2', language: 'ar');
      server.online = false;
      final offline = await repos.hadiths.getHadithPage(
        categoryId: '2',
        language: 'ar',
      );
      expect(offline.value.items.map((h) => h.id), ['101', '102']);
    });

    test('a hadith, with its Arabic text exactly as received', () async {
      final repos = _repositories(server, cache);
      await repos.hadiths.getHadithDetails('2962', language: 'ar');
      server.online = false;
      final offline = await repos.hadiths.getHadithDetails(
        '2962',
        language: 'ar',
      );
      expect(offline.value.hadeeth, arabicDetailsJson['hadeeth']);
    });
  });

  group('what was never opened is not available offline', () {
    test('a hadith that was never opened is an honest error', () async {
      final repos = _repositories(server, cache);
      await repos.hadiths.getHadithDetails('1', language: 'ar');
      server.online = false;
      final other = await repos.hadiths.getHadithDetails('2', language: 'ar');
      expect(other.ok, isFalse);
      expect(other.failure.kind, FailureKind.noConnection);
    });

    test('Arabic and English copies are separate', () async {
      final repos = _repositories(server, cache);
      await repos.hadiths.getHadithDetails('1', language: 'ar');
      server.online = false;
      final english = await repos.hadiths.getHadithDetails('1', language: 'en');
      expect(english.ok, isFalse);
    });

    test('another page of the same list is a separate copy', () async {
      final repos = _repositories(server, cache);
      await repos.hadiths.getHadithPage(
        categoryId: '2',
        language: 'ar',
        page: 1,
      );
      server.online = false;
      final page2 = await repos.hadiths.getHadithPage(
        categoryId: '2',
        language: 'ar',
        page: 2,
      );
      expect(page2.ok, isFalse);
    });
  });

  group('requests', () {
    test('a recent saved copy avoids asking the server again', () async {
      final repos = _repositories(server, cache);
      for (var i = 0; i < 3; i++) {
        await repos.hadiths.getHadithDetails('2962', language: 'ar');
      }
      expect(server.count('hadeeths/one'), 1);
    });

    test(
      'refresh (pull-to-refresh) asks the server even when a copy is recent',
      () async {
        final repos = _repositories(server, cache);
        await repos.categories.getCategories(language: 'ar');
        await repos.categories.getCategories(language: 'ar', refresh: true);
        expect(server.count('categories/list'), 2);
        await repos.hadiths.getHadithPage(categoryId: '2', language: 'ar');
        await repos.hadiths.getHadithPage(
          categoryId: '2',
          language: 'ar',
          refresh: true,
        );
        expect(server.count('hadeeths/list'), 2);
      },
    );

    test('a refresh that fails offline still shows the saved copy', () async {
      final repos = _repositories(server, cache);
      await repos.categories.getCategories(language: 'ar');
      server.online = false;
      final result = await repos.categories.getCategories(
        language: 'ar',
        refresh: true,
      );
      expect(result.ok, isTrue);
    });
  });

  group('only good answers are saved', () {
    test('a malformed answer is reported and nothing is saved', () async {
      server.malformed = true;
      final repos = _repositories(server, cache);
      final result = await repos.hadiths.getHadithDetails('5', language: 'ar');
      expect(result.failure.kind, FailureKind.parse);
      expect(cache.length, 0);
    });

    test('a good answer is saved', () async {
      final repos = _repositories(server, cache);
      await repos.hadiths.getHadithDetails('5', language: 'ar');
      expect(cache.length, 1);
    });
  });

  group('ageing, with a controllable clock', () {
    late DateTime now;
    setUp(() => now = DateTime.utc(2026, 10, 9));

    _Repos repos() => _repositories(server, cache, now: () => now);

    test('a hadith is re-checked after a week', () async {
      await repos().hadiths.getHadithDetails('5', language: 'ar');
      now = now.add(const Duration(days: 8));
      await repos().hadiths.getHadithDetails('5', language: 'ar');
      expect(server.count('hadeeths/one'), 2);
    });

    test('an old copy is still shown offline, up to 60 days', () async {
      await repos().hadiths.getHadithDetails('5', language: 'ar');
      server.online = false;
      now = now.add(const Duration(days: 40));
      expect(
        (await repos().hadiths.getHadithDetails('5', language: 'ar')).ok,
        isTrue,
      );
      now = now.add(const Duration(days: 30)); // 70 days in total
      expect(
        (await repos().hadiths.getHadithDetails('5', language: 'ar')).ok,
        isFalse,
      );
    });

    test(
      'a hadith the server no longer has is forgotten, not shown from the copy',
      () async {
        await repos().hadiths.getHadithDetails('5', language: 'ar');
        expect(cache.length, 1);
        now = now.add(const Duration(days: 8));
        server.gone = true;
        final result = await repos().hadiths.getHadithDetails(
          '5',
          language: 'ar',
        );
        expect(result.failure.kind, FailureKind.notFound);
        expect(cache.length, 0);
        server.online = false;
        expect(
          (await repos().hadiths.getHadithDetails('5', language: 'ar')).ok,
          isFalse,
        );
      },
    );
  });

  group('with a real on-disk cache', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('offline_data_test'));
    tearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    test(
      'copies survive an app restart (a new cache object over the same folder)',
      () async {
        final first = _repositories(server, FileResponseCache(dir));
        await first.categories.getCategories(language: 'ar');
        await first.hadiths.getHadithDetails('2962', language: 'ar');

        server.online = false;
        final second = _repositories(server, FileResponseCache(dir)); // restart
        expect(
          (await second.categories.getCategories(language: 'ar')).ok,
          isTrue,
        );
        final details = await second.hadiths.getHadithDetails(
          '2962',
          language: 'ar',
        );
        expect(details.value.hadeeth, arabicDetailsJson['hadeeth']);
      },
    );

    test('clearing removes them', () async {
      final onDisk = FileResponseCache(dir);
      final repos = _repositories(server, onDisk);
      await repos.hadiths.getHadithDetails('2962', language: 'ar');
      await onDisk.clear();
      server.online = false;
      expect(
        (await repos.hadiths.getHadithDetails('2962', language: 'ar')).ok,
        isFalse,
      );
    });
  });
}
