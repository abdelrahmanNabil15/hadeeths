import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/features/search/domain/hadith_search_result.dart';

abstract interface class SearchRepository {
  /// The server rejects shorter phrases (HTTP 400), so callers must not ask.
  static const minPhraseLength = 3;

  /// The server returns at most this many results and has no paging.
  static const maxResults = 100;

  /// Hadiths matching [phrase]; an empty list when nothing matches. The server normalizes
  /// Arabic diacritics itself, so no local index is involved.
  Future<Result<List<HadithSearchResult>>> search(
    String phrase, {
    required String language,
  });
}
