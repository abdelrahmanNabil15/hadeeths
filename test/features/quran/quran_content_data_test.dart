import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/features/quran/data/quran_content_remote_data_source.dart';
import 'package:mynewapp/features/quran/data/quran_content_repository_impl.dart';
import 'package:mynewapp/features/quran/domain/quran_editions.dart';
import 'package:mynewapp/features/quran/domain/quran_translation_search.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';

import '../../support/fake_dio.dart';

// Structural fixtures only -- field shapes confirmed against the deployed proxy, never real
// Quran translation or tafsir text (house rule: no source content in code or tests).
Map<String, Object?> _editionsJson(
  String key,
  List<Map<String, Object?>> entries,
) => {key: entries};

void main() {
  group('HttpQuranContentRemoteDataSource', () {
    test(
      'translation editions: language is sent, entries are parsed',
      () async {
        final (client, adapter) = fakeQuranContentClient(
          (o, n) async => jsonResponse(
            _editionsJson('translations', [
              {
                'id': 85,
                'name': 'Edition Name',
                'author_name': 'Some Author',
                'language_name': 'english',
              },
            ]),
          ),
        );
        final dtos = await HttpQuranContentRemoteDataSource(
          client,
          uncachedFetcher(),
        ).fetchTranslationEditions(language: 'en');
        expect(dtos.single.id, 85);
        expect(dtos.single.authorName, 'Some Author');
        expect(adapter.requests.single.path, 'editions/translations');
        expect(adapter.requests.single.queryParameters, {'language': 'en'});
      },
    );

    test('tafsir editions: a null author is kept null, not "null"', () async {
      final (client, _) = fakeQuranContentClient(
        (o, n) async => jsonResponse(
          _editionsJson('tafsirs', [
            {
              'id': 926,
              'name': 'Edition Name',
              'author_name': null,
              'language_name': 'arabic',
            },
          ]),
        ),
      );
      final dtos = await HttpQuranContentRemoteDataSource(
        client,
        uncachedFetcher(),
      ).fetchTafsirEditions();
      expect(dtos.single.authorName, isNull);
    });

    test('reciters: the reciter-specific field name is read', () async {
      final (client, _) = fakeQuranContentClient(
        (o, n) async => jsonResponse(
          _editionsJson('recitations', [
            {'id': 6, 'reciter_name': 'A Reciter', 'style': null},
          ]),
        ),
      );
      final dtos = await HttpQuranContentRemoteDataSource(
        client,
        uncachedFetcher(),
      ).fetchReciters();
      expect(dtos.single.name, 'A Reciter');
      expect(dtos.single.style, isNull);
    });

    test(
      'translation content: the ayah key is in the path, text is the first entry',
      () async {
        final (client, adapter) = fakeQuranContentClient(
          (o, n) async => jsonResponse({
            'translations': [
              {'id': 1, 'resource_id': 85, 'text': 'placeholder text'},
            ],
            'pagination': {'total_records': 1},
          }),
        );
        final text = await HttpQuranContentRemoteDataSource(
          client,
          uncachedFetcher(),
        ).fetchTranslation(editionId: 85, verseKey: '1:1');
        expect(text, 'placeholder text');
        expect(adapter.requests.single.path, 'translations/85/ayah/1:1');
      },
    );

    test('tafsir content: text comes from the nested tafsir object', () async {
      final (client, adapter) = fakeQuranContentClient(
        (o, n) async => jsonResponse({
          'tafsir': {'resource_id': 926, 'text': 'placeholder commentary'},
        }),
      );
      final text = await HttpQuranContentRemoteDataSource(
        client,
        uncachedFetcher(),
      ).fetchTafsir(editionId: 926, verseKey: '1:1');
      expect(text, 'placeholder commentary');
      expect(adapter.requests.single.path, 'tafsirs/926/ayah/1:1');
    });

    test(
      'recitation audio: a protocol-relative url is normalised to https',
      () async {
        final (client, adapter) = fakeQuranContentClient(
          (o, n) async => jsonResponse({
            'audio_files': [
              {'verse_key': '1:1', 'url': '//mirrors.example.com/001001.mp3'},
            ],
            'pagination': {'total_records': 1},
          }),
        );
        final url = await HttpQuranContentRemoteDataSource(
          client,
          uncachedFetcher(),
        ).fetchRecitationAudioUrl(reciterId: 6, verseKey: '1:1');
        expect(url.toString(), 'https://mirrors.example.com/001001.mp3');
        expect(adapter.requests.single.path, 'recitations/6/ayah/1:1');
      },
    );

    test('an empty audio-files list is a parse failure, not a crash', () async {
      final (client, _) = fakeQuranContentClient(
        (o, n) async => jsonResponse({
          'audio_files': <Object?>[],
          'pagination': <String, Object?>{},
        }),
      );
      expect(
        HttpQuranContentRemoteDataSource(
          client,
          uncachedFetcher(),
        ).fetchRecitationAudioUrl(reciterId: 6, verseKey: '1:1'),
        throwsA(
          isA<Failure>().having((f) => f.kind, 'kind', FailureKind.parse),
        ),
      );
    });

    test('a malformed response is a parse failure', () async {
      final (client, _) = fakeQuranContentClient(
        (o, n) async => jsonResponse({'translations': 'not a list'}),
      );
      expect(
        HttpQuranContentRemoteDataSource(
          client,
          uncachedFetcher(),
        ).fetchTranslationEditions(language: 'en'),
        throwsA(
          isA<Failure>().having((f) => f.kind, 'kind', FailureKind.parse),
        ),
      );
    });

    test(
      'translation search: the edition, query and page are sent, matches and '
      'pagination are parsed',
      () async {
        final (client, adapter) = fakeQuranContentClient(
          (o, n) async => jsonResponse({
            'pagination': {
              'current_page': 2,
              'total_pages': 5,
              'per_page': 2,
              'total_records': 9,
            },
            'result': {
              'navigation': <Object?>[],
              'verses': [
                {'result_type': 'ayah', 'key': '1:1', 'name': 'snippet one'},
                {'result_type': 'ayah', 'key': '2:255', 'name': 'snippet two'},
              ],
            },
          }),
        );
        final results = await HttpQuranContentRemoteDataSource(
          client,
          uncachedFetcher(),
        ).searchTranslation(editionId: 85, query: 'mercy', page: 2);
        expect(results.page, 2);
        expect(results.totalPages, 5);
        expect(results.matches, hasLength(2));
        expect(results.matches.first.verse, const VerseRef(1, 1));
        expect(results.matches.first.snippet, 'snippet one');
        expect(results.matches.last.verse, const VerseRef(2, 255));
        expect(adapter.requests.single.path, 'search');
        expect(adapter.requests.single.queryParameters, {
          'query': 'mercy',
          'translation_ids': '85',
          'page': '2',
        });
      },
    );

    test(
      'translation search: an unparsable verse key is a parse failure',
      () async {
        final (client, _) = fakeQuranContentClient(
          (o, n) async => jsonResponse({
            'pagination': {'current_page': 1, 'total_pages': 1},
            'result': {
              'verses': [
                {'result_type': 'ayah', 'key': 'not-a-key', 'name': 'x'},
              ],
            },
          }),
        );
        expect(
          HttpQuranContentRemoteDataSource(
            client,
            uncachedFetcher(),
          ).searchTranslation(editionId: 85, query: 'x', page: 1),
          throwsA(
            isA<Failure>().having((f) => f.kind, 'kind', FailureKind.parse),
          ),
        );
      },
    );
  });

  group('QuranContentRepositoryImpl', () {
    QuranContentRepositoryImpl repo(FakeHandler handler) {
      final (client, _) = fakeQuranContentClient(handler);
      return QuranContentRepositoryImpl(
        HttpQuranContentRemoteDataSource(client, uncachedFetcher()),
      );
    }

    test('translation editions: maps DTOs to entities', () async {
      final result = await repo(
        (o, n) async => jsonResponse(
          _editionsJson('translations', [
            {
              'id': 85,
              'name': 'Edition Name',
              'author_name': 'Some Author',
              'language_name': 'english',
            },
          ]),
        ),
      ).translationEditions(language: 'en');
      final editions = (result as Success<List<TranslationEdition>>).value;
      expect(editions.single.id, 85);
    });

    test('translation: builds the verse key from sura and verse', () async {
      final result = await repo(
        (o, n) async => jsonResponse({
          'translations': [
            {'id': 1, 'resource_id': 85, 'text': 'placeholder text'},
          ],
          'pagination': <String, Object?>{},
        }),
      ).translation(editionId: 85, verse: const VerseRef(2, 255));
      expect((result as Success<String>).value, 'placeholder text');
    });

    test('a 404 becomes an Err(notFound)', () async {
      final result = await repo(
        (o, n) async => emptyResponse(404),
      ).tafsir(editionId: 1, verse: const VerseRef(1, 1));
      expect((result as Err).failure.kind, FailureKind.notFound);
    });

    test('a 500 becomes an Err(server)', () async {
      final result = await repo((o, n) async => emptyResponse(500)).reciters();
      expect((result as Err).failure.kind, FailureKind.server);
    });

    test('translation search: maps the parsed page through', () async {
      final result = await repo(
        (o, n) async => jsonResponse({
          'pagination': {'current_page': 1, 'total_pages': 1},
          'result': {
            'verses': [
              {'result_type': 'ayah', 'key': '1:1', 'name': 'snippet'},
            ],
          },
        }),
      ).searchTranslation(editionId: 85, query: 'mercy');
      final results = (result as Success<TranslationSearchResults>).value;
      expect(results.matches.single.snippet, 'snippet');
      expect(results.hasMore, isFalse);
    });
  });
}
