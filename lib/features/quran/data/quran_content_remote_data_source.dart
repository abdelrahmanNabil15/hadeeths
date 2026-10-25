import 'package:mynewapp/core/cache/cached_fetcher.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/network/hadeeth_client.dart' show parseResponse;
import 'package:mynewapp/core/network/quran_content_client.dart';
import 'package:mynewapp/core/network/quran_content_endpoints.dart';
import 'package:mynewapp/features/quran/data/quran_content_dtos.dart';
import 'package:mynewapp/features/quran/domain/qiraat.dart';
import 'package:mynewapp/features/quran/domain/quran_translation_search.dart';

abstract interface class QuranContentRemoteDataSource {
  /// All methods throw a `Failure` on any error.
  Future<List<TranslationEditionDto>> fetchTranslationEditions({
    required String language,
  });

  Future<List<TafsirEditionDto>> fetchTafsirEditions();

  Future<List<ReciterDto>> fetchReciters();

  Future<String> fetchTranslation({
    required int editionId,
    required String verseKey,
  });

  Future<String> fetchTafsir({
    required int editionId,
    required String verseKey,
  });

  Future<Uri> fetchRecitationAudioUrl({
    required int reciterId,
    required String verseKey,
  });

  Future<TranslationSearchResults> searchTranslation({
    required int editionId,
    required String query,
    required int page,
  });

  Future<QiraatMatrix> fetchQiraatMatrix({required String verseKey});
}

class HttpQuranContentRemoteDataSource implements QuranContentRemoteDataSource {
  HttpQuranContentRemoteDataSource(this._client, this._fetcher);

  final QuranContentClient _client;
  final CachedFetcher _fetcher;

  /// Edition lists change rarely (a new translation or reciter added); a month is generous
  /// without asking on every reader open.
  static const editionsPolicy = CachePolicy(fresh: Duration(days: 30));

  /// Published translation, tafsir and recitation content for a verse never changes once an
  /// edition is published; the same freshness as the edition lists.
  static const contentPolicy = CachePolicy(fresh: Duration(days: 30));

  @override
  Future<List<TranslationEditionDto>> fetchTranslationEditions({
    required String language,
  }) {
    final query = {'language': language};
    return _fetcher.fetch(
      key: CachedFetcher.keyFor(translationEditionsPath, query),
      policy: editionsPolicy,
      load: () => _client.get(translationEditionsPath, query),
      parse: (data) => parseResponse(() => translationEditionsFromJson(data)),
    );
  }

  @override
  Future<List<TafsirEditionDto>> fetchTafsirEditions() {
    const query = <String, dynamic>{};
    return _fetcher.fetch(
      key: CachedFetcher.keyFor(tafsirEditionsPath, query),
      policy: editionsPolicy,
      load: () => _client.get(tafsirEditionsPath, query),
      parse: (data) => parseResponse(() => tafsirEditionsFromJson(data)),
    );
  }

  @override
  Future<List<ReciterDto>> fetchReciters() {
    const query = <String, dynamic>{};
    return _fetcher.fetch(
      key: CachedFetcher.keyFor(recitationEditionsPath, query),
      policy: editionsPolicy,
      load: () => _client.get(recitationEditionsPath, query),
      parse: (data) => parseResponse(() => recitersFromJson(data)),
    );
  }

  @override
  Future<String> fetchTranslation({
    required int editionId,
    required String verseKey,
  }) {
    final path = translationByAyahPath(editionId, verseKey);
    const query = <String, dynamic>{};
    return _fetcher.fetch(
      key: CachedFetcher.keyFor(path, query),
      policy: contentPolicy,
      load: () => _client.get(path, query),
      parse: (data) => parseResponse(() => translationTextFromJson(data)),
    );
  }

  @override
  Future<String> fetchTafsir({
    required int editionId,
    required String verseKey,
  }) {
    final path = tafsirByAyahPath(editionId, verseKey);
    const query = <String, dynamic>{};
    return _fetcher.fetch(
      key: CachedFetcher.keyFor(path, query),
      policy: contentPolicy,
      load: () => _client.get(path, query),
      parse: (data) => parseResponse(() => tafsirTextFromJson(data)),
    );
  }

  @override
  Future<Uri> fetchRecitationAudioUrl({
    required int reciterId,
    required String verseKey,
  }) {
    final path = recitationByAyahPath(reciterId, verseKey);
    const query = <String, dynamic>{};
    return _fetcher.fetch(
      key: CachedFetcher.keyFor(path, query),
      policy: contentPolicy,
      load: () => _client.get(path, query),
      parse: (data) => parseResponse(() => recitationAudioUrlFromJson(data)),
    );
  }

  @override
  Future<TranslationSearchResults> searchTranslation({
    required int editionId,
    required String query,
    required int page,
  }) async {
    // Not cached through `_fetcher`: a search result depends on live query text and page, so
    // there is nothing stable to key a cache entry by (unlike editions and per-ayah content,
    // which never change once published).
    final data = await _client.get(translationSearchPath, {
      'query': query,
      'translation_ids': '$editionId',
      'page': '$page',
    });
    return parseResponse(() => translationSearchResultsFromJson(data));
  }

  @override
  Future<QiraatMatrix> fetchQiraatMatrix({required String verseKey}) async {
    final path = qiraatMatrixPath(verseKey);
    const query = <String, dynamic>{};
    try {
      return await _fetcher.fetch(
        key: CachedFetcher.keyFor(path, query),
        policy: contentPolicy,
        load: () => _client.get(path, query),
        parse: (data) => parseResponse(() => qiraatMatrixFromJson(data)),
      );
    } on Failure catch (e) {
      // The upstream API's own way of saying "this verse has no approved variations" -- the
      // normal case for most verses, not an error.
      if (e.kind == FailureKind.notFound) return QiraatMatrix.empty;
      rethrow;
    }
  }
}
