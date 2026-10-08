import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/features/search/data/search_dtos.dart';
import 'package:mynewapp/features/search/data/search_remote_data_source.dart';
import 'package:mynewapp/features/search/data/search_repository_impl.dart';
import 'package:mynewapp/features/search/domain/hadith_search_result.dart';

import '../../support/fake_dio.dart';

const _hit = {
  'id': '2',
  'title': 'عنوان',
  'hadith_text': 'نص الحديث',
  'hadith_text_highlights': 'نص <mark>الحديث</mark>',
};

void main() {
  group('parseSearchResponse', () {
    test('a response with matches is a list', () {
      final dtos = parseSearchResponse([_hit, _hit]);
      expect(dtos, hasLength(2));
      expect(dtos.first.id, '2');
      expect(dtos.first.highlightedText, 'نص <mark>الحديث</mark>');
    });

    test(
      'a search without matches is an object with "suggestions" (live API behaviour)',
      () {
        expect(
          parseSearchResponse({
            'suggestions': {
              'id': null,
              'title': '',
              'hadith_text': '',
              'hadith_text_highlights': '',
            },
          }),
          isEmpty,
        );
      },
    );

    test('any other shape is rejected', () {
      expect(
        () => parseSearchResponse({'unexpected': 1}),
        throwsFormatException,
      );
      expect(() => parseSearchResponse('text'), throwsFormatException);
      expect(() => parseSearchResponse(null), throwsFormatException);
    });

    test('a result without an id is rejected', () {
      expect(
        () => parseSearchResponse([
          {'title': 'x'},
        ]),
        throwsFormatException,
      );
    });

    test('the source text is kept as received', () {
      expect(SearchResultDto.fromJson(_hit).toEntity().text, 'نص الحديث');
    });
  });

  group('HttpSearchRemoteDataSource', () {
    test('requests hadeeths/search with the phrase and language', () async {
      final (client, adapter) = fakeClient(
        (o, n) async => jsonResponse([_hit]),
      );
      await HttpSearchRemoteDataSource(client).search('النية', language: 'en');
      expect(adapter.requests.single.path, 'hadeeths/search');
      expect(adapter.requests.single.queryParameters, {
        'phrase': 'النية',
        'language': 'en',
      });
    });

    test('a bad response is a parse failure', () async {
      final (client, _) = fakeClient((o, n) async => jsonResponse(7));
      expect(
        HttpSearchRemoteDataSource(client).search('abc'),
        throwsA(
          isA<Failure>().having((f) => f.kind, 'kind', FailureKind.parse),
        ),
      );
    });
  });

  group('SearchRepositoryImpl', () {
    SearchRepositoryImpl repo(FakeHandler handler) {
      final (client, _) = fakeClient(handler);
      return SearchRepositoryImpl(HttpSearchRemoteDataSource(client));
    }

    test('maps hits to entities', () async {
      final result = await repo(
        (o, n) async => jsonResponse([_hit]),
      ).search('نص', language: 'ar');
      final hits = (result as Success<List<HadithSearchResult>>).value;
      expect(
        hits.single.segments.where((s) => s.highlighted).single.text,
        'الحديث',
      );
    });

    test('no matches is a successful empty list, not an error', () async {
      final result = await repo(
        (o, n) async => jsonResponse({'suggestions': <String, Object?>{}}),
      ).search('zzzz', language: 'en');
      expect((result as Success<List<HadithSearchResult>>).value, isEmpty);
    });

    test('a 400 (phrase too short) becomes an Err(server)', () async {
      final result = await repo(
        (o, n) async => emptyResponse(400),
      ).search('ab', language: 'en');
      expect(
        (result as Err<List<HadithSearchResult>>).failure.kind,
        FailureKind.server,
      );
    });
  });
}
