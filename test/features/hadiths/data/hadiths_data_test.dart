import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/features/hadiths/data/hadiths_remote_data_source.dart';
import 'package:mynewapp/features/hadiths/data/hadiths_repository_impl.dart';
import 'package:mynewapp/features/hadiths/domain/hadith_details.dart';
import 'package:mynewapp/features/hadiths/domain/hadith_page.dart';

import '../../../support/fake_dio.dart';
import '../../../support/fixtures.dart';

void main() {
  group('HttpHadithsRemoteDataSource', () {
    test('page: category, page and page size are sent', () async {
      final (client, adapter) = fakeClient(
        (o, n) async => jsonResponse(hadithPageJson(ids: ['1'])),
      );
      await HttpHadithsRemoteDataSource(
        client,
      ).fetchHadithPage(categoryId: '8', page: 3, perPage: 20);
      expect(adapter.requests.single.path, 'hadeeths/list');
      expect(adapter.requests.single.queryParameters, {
        'language': 'ar',
        'category_id': '8',
        'page': 3,
        'per_page': 20,
      });
    });

    test('details: id and language are sent', () async {
      final (client, adapter) = fakeClient(
        (o, n) async => jsonResponse(englishDetailsJson),
      );
      final dto = await HttpHadithsRemoteDataSource(
        client,
      ).fetchHadithDetails('2962', language: 'en');
      expect(dto.grade, 'Sahih');
      expect(adapter.requests.single.path, 'hadeeths/one');
      expect(adapter.requests.single.queryParameters, {
        'language': 'en',
        'id': '2962',
      });
    });

    test('an empty 200 body is a parse failure', () async {
      final (client, _) = fakeClient((o, n) async => emptyResponse(200));
      expect(
        HttpHadithsRemoteDataSource(client).fetchHadithDetails('1'),
        throwsA(
          isA<Failure>().having((f) => f.kind, 'kind', FailureKind.parse),
        ),
      );
    });

    test('a malformed page is a parse failure', () async {
      final (client, _) = fakeClient(
        (o, n) async => jsonResponse({
          'data': ['not an object'],
        }),
      );
      expect(
        HttpHadithsRemoteDataSource(
          client,
        ).fetchHadithPage(categoryId: '1', page: 1, perPage: 20),
        throwsA(
          isA<Failure>().having((f) => f.kind, 'kind', FailureKind.parse),
        ),
      );
    });
  });

  group('HadithsRepositoryImpl', () {
    HadithsRepositoryImpl repo(FakeHandler handler) {
      final (client, _) = fakeClient(handler);
      return HadithsRepositoryImpl(HttpHadithsRemoteDataSource(client));
    }

    test('page: maps to entities and keeps paging metadata', () async {
      final result = await repo(
        (o, n) async => jsonResponse(
          hadithPageJson(ids: ['1', '2'], page: 2, lastPage: 5, totalItems: 97),
        ),
      ).getHadithPage(categoryId: '8', page: 2);
      final page = (result as Success<HadithPage>).value;
      expect(page.items.map((h) => h.id), ['1', '2']);
      expect((page.currentPage, page.lastPage, page.totalItems), (2, 5, 97));
    });

    test('details: maps to an entity, source text untouched', () async {
      final result = await repo(
        (o, n) async => jsonResponse(arabicDetailsJson),
      ).getHadithDetails('2962');
      final details = (result as Success<HadithDetails>).value;
      expect(details.hadeeth, arabicDetailsJson['hadeeth']);
      expect(details.wordsMeanings.single.word, 'كلمة');
    });

    test('a 404 becomes an Err(notFound)', () async {
      final result = await repo(
        (o, n) async => emptyResponse(404),
      ).getHadithDetails('1');
      expect((result as Err).failure.kind, FailureKind.notFound);
    });

    test('a 500 on the list becomes an Err(server)', () async {
      final result = await repo(
        (o, n) async => emptyResponse(500),
      ).getHadithPage(categoryId: '99999');
      expect((result as Err).failure.kind, FailureKind.server);
    });
  });
}
