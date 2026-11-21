import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/core/state/load_status.dart';
import 'package:mynewapp/features/quran/domain/quran_content_repository.dart';
import 'package:mynewapp/features/quran/domain/quran_editions.dart';
import 'package:mynewapp/features/quran/domain/quran_translation_search.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';

class QuranContentState {
  const QuranContentState({
    this.translationEditionsStatus = LoadStatus.initial,
    this.translationEditionsFailure,
    this.translationEditions = const [],
    this.translations = const {},
    this.tafsirEditionsStatus = LoadStatus.initial,
    this.tafsirEditionsFailure,
    this.tafsirEditions = const [],
    this.tafsirs = const {},
    this.tafsirFailures = const {},
    this.searchStatus = LoadStatus.initial,
    this.searchFailure,
    this.searchMatches = const [],
    this.searchPage = 1,
    this.searchHasMore = false,
    this.reciterStatus = LoadStatus.initial,
    this.reciterFailure,
    this.reciters = const [],
  });

  final LoadStatus translationEditionsStatus;

  /// Set only when [translationEditionsStatus] is [LoadStatus.failure].
  final Failure? translationEditionsFailure;
  final List<TranslationEdition> translationEditions;

  /// Fetched translation text, keyed by `"editionId:sura:verse"` so a verse shown under a
  /// different edition is fetched again rather than mixed up with the last one.
  final Map<String, String> translations;

  final LoadStatus tafsirEditionsStatus;

  /// Set only when [tafsirEditionsStatus] is [LoadStatus.failure].
  final Failure? tafsirEditionsFailure;
  final List<TafsirEdition> tafsirEditions;

  /// Fetched tafsir text, keyed the same way as [translations].
  final Map<String, String> tafsirs;

  /// Per-verse tafsir fetches that failed, keyed the same way, holding the real [Failure] so the
  /// sheet can show the same typed error view the rest of the app uses. Unlike a translation
  /// (ambient, silent on failure), a tafsir is opened on an explicit tap, so its sheet needs to
  /// tell the reader the fetch failed rather than spin forever.
  final Map<String, Failure> tafsirFailures;

  /// Status of the current search: the initial query, or a "load more" page. [searchMatches]
  /// keeps the accumulated matches across pages, so a failed "load more" (status [failure] with
  /// [searchMatches] non-empty) still has a list to show behind its retry.
  final LoadStatus searchStatus;

  /// Set only when [searchStatus] is [LoadStatus.failure].
  final Failure? searchFailure;
  final List<TranslationSearchMatch> searchMatches;

  /// The last page fetched; "load more" asks for [searchPage] + 1.
  final int searchPage;
  final bool searchHasMore;

  final LoadStatus reciterStatus;

  /// Set only when [reciterStatus] is [LoadStatus.failure].
  final Failure? reciterFailure;
  final List<Reciter> reciters;

  /// For a plain field update that leaves both edition-list statuses alone (loading one verse's
  /// content does not touch them). [loadTranslationEditions]/[loadTafsirEditions] build their own
  /// states directly instead of through this, since each needs to clear its own old failure
  /// outright on every new attempt -- something a `??`-preserving copyWith cannot express.
  QuranContentState copyWith({
    Map<String, String>? translations,
    Map<String, String>? tafsirs,
    Map<String, Failure>? tafsirFailures,
  }) => QuranContentState(
    translationEditionsStatus: translationEditionsStatus,
    translationEditionsFailure: translationEditionsFailure,
    translationEditions: translationEditions,
    translations: translations ?? this.translations,
    tafsirEditionsStatus: tafsirEditionsStatus,
    tafsirEditionsFailure: tafsirEditionsFailure,
    tafsirEditions: tafsirEditions,
    tafsirs: tafsirs ?? this.tafsirs,
    tafsirFailures: tafsirFailures ?? this.tafsirFailures,
    searchStatus: searchStatus,
    searchFailure: searchFailure,
    searchMatches: searchMatches,
    searchPage: searchPage,
    searchHasMore: searchHasMore,
    reciterStatus: reciterStatus,
    reciterFailure: reciterFailure,
    reciters: reciters,
  );
}

/// Translation, tafsir and recitation-audio content: the edition lists for the reader's pickers,
/// and the content already fetched for the verses on screen. Separate from `QuranCubit`, which
/// stays about the offline, verified text; this is the API-backed, off-by-default extra.
class QuranContentCubit extends Cubit<QuranContentState> {
  QuranContentCubit(this._repository) : super(const QuranContentState());

  final QuranContentRepository _repository;

  Future<void> loadTranslationEditions() async {
    if (state.translationEditionsStatus == LoadStatus.loading) return;
    emit(
      QuranContentState(
        translationEditionsStatus: LoadStatus.loading,
        translations: state.translations,
        tafsirEditionsStatus: state.tafsirEditionsStatus,
        tafsirEditionsFailure: state.tafsirEditionsFailure,
        tafsirEditions: state.tafsirEditions,
        tafsirs: state.tafsirs,
        tafsirFailures: state.tafsirFailures,
        reciterStatus: state.reciterStatus,
        reciterFailure: state.reciterFailure,
        reciters: state.reciters,
        searchStatus: state.searchStatus,
        searchFailure: state.searchFailure,
        searchMatches: state.searchMatches,
        searchPage: state.searchPage,
        searchHasMore: state.searchHasMore,
      ),
    );
    final result = await _repository.translationEditions();
    if (isClosed) return;
    switch (result) {
      case Success(:final value):
        emit(
          QuranContentState(
            translationEditionsStatus: LoadStatus.success,
            translationEditions: value,
            translations: state.translations,
            tafsirEditionsStatus: state.tafsirEditionsStatus,
            tafsirEditionsFailure: state.tafsirEditionsFailure,
            tafsirEditions: state.tafsirEditions,
            tafsirs: state.tafsirs,
            tafsirFailures: state.tafsirFailures,
            reciterStatus: state.reciterStatus,
            reciterFailure: state.reciterFailure,
            reciters: state.reciters,
            searchStatus: state.searchStatus,
            searchFailure: state.searchFailure,
            searchMatches: state.searchMatches,
            searchPage: state.searchPage,
            searchHasMore: state.searchHasMore,
          ),
        );
      case Err(:final failure):
        emit(
          QuranContentState(
            translationEditionsStatus: LoadStatus.failure,
            translationEditionsFailure: failure,
            translations: state.translations,
            tafsirEditionsStatus: state.tafsirEditionsStatus,
            tafsirEditionsFailure: state.tafsirEditionsFailure,
            tafsirEditions: state.tafsirEditions,
            tafsirs: state.tafsirs,
            tafsirFailures: state.tafsirFailures,
            reciterStatus: state.reciterStatus,
            reciterFailure: state.reciterFailure,
            reciters: state.reciters,
            searchStatus: state.searchStatus,
            searchFailure: state.searchFailure,
            searchMatches: state.searchMatches,
            searchPage: state.searchPage,
            searchHasMore: state.searchHasMore,
          ),
        );
    }
  }

  /// The text already held for [editionId]'s translation of [verse], or `null` if it has not
  /// been fetched (successfully) yet.
  String? translationFor(int editionId, VerseRef verse) =>
      state.translations[_key(editionId, verse)];

  /// Fetches and holds [editionId]'s translation of [verse] if not already held. Failures are
  /// silent (the block under the verse simply stays empty): a translation is a supplement to the
  /// reading, not something an error banner should interrupt it for.
  Future<void> loadTranslation({
    required int editionId,
    required VerseRef verse,
  }) async {
    final key = _key(editionId, verse);
    if (state.translations.containsKey(key)) return;
    final result = await _repository.translation(
      editionId: editionId,
      verse: verse,
    );
    if (isClosed) return;
    if (result case Success(:final value)) {
      emit(state.copyWith(translations: {...state.translations, key: value}));
    }
  }

  Future<void> loadTafsirEditions() async {
    if (state.tafsirEditionsStatus == LoadStatus.loading) return;
    emit(
      QuranContentState(
        translationEditionsStatus: state.translationEditionsStatus,
        translationEditionsFailure: state.translationEditionsFailure,
        translationEditions: state.translationEditions,
        translations: state.translations,
        tafsirEditionsStatus: LoadStatus.loading,
        tafsirs: state.tafsirs,
        tafsirFailures: state.tafsirFailures,
        reciterStatus: state.reciterStatus,
        reciterFailure: state.reciterFailure,
        reciters: state.reciters,
        searchStatus: state.searchStatus,
        searchFailure: state.searchFailure,
        searchMatches: state.searchMatches,
        searchPage: state.searchPage,
        searchHasMore: state.searchHasMore,
      ),
    );
    final result = await _repository.tafsirEditions();
    if (isClosed) return;
    switch (result) {
      case Success(:final value):
        emit(
          QuranContentState(
            translationEditionsStatus: state.translationEditionsStatus,
            translationEditionsFailure: state.translationEditionsFailure,
            translationEditions: state.translationEditions,
            translations: state.translations,
            tafsirEditionsStatus: LoadStatus.success,
            tafsirEditions: value,
            tafsirs: state.tafsirs,
            tafsirFailures: state.tafsirFailures,
            reciterStatus: state.reciterStatus,
            reciterFailure: state.reciterFailure,
            reciters: state.reciters,
            searchStatus: state.searchStatus,
            searchFailure: state.searchFailure,
            searchMatches: state.searchMatches,
            searchPage: state.searchPage,
            searchHasMore: state.searchHasMore,
          ),
        );
      case Err(:final failure):
        emit(
          QuranContentState(
            translationEditionsStatus: state.translationEditionsStatus,
            translationEditionsFailure: state.translationEditionsFailure,
            translationEditions: state.translationEditions,
            translations: state.translations,
            tafsirEditionsStatus: LoadStatus.failure,
            tafsirEditionsFailure: failure,
            tafsirs: state.tafsirs,
            tafsirFailures: state.tafsirFailures,
            reciterStatus: state.reciterStatus,
            reciterFailure: state.reciterFailure,
            reciters: state.reciters,
            searchStatus: state.searchStatus,
            searchFailure: state.searchFailure,
            searchMatches: state.searchMatches,
            searchPage: state.searchPage,
            searchHasMore: state.searchHasMore,
          ),
        );
    }
  }

  Future<void> loadReciters() async {
    if (state.reciterStatus == LoadStatus.loading) return;
    emit(
      QuranContentState(
        translationEditionsStatus: state.translationEditionsStatus,
        translationEditionsFailure: state.translationEditionsFailure,
        translationEditions: state.translationEditions,
        translations: state.translations,
        tafsirEditionsStatus: state.tafsirEditionsStatus,
        tafsirEditionsFailure: state.tafsirEditionsFailure,
        tafsirEditions: state.tafsirEditions,
        tafsirs: state.tafsirs,
        tafsirFailures: state.tafsirFailures,
        reciterStatus: LoadStatus.loading,
        reciters: state.reciters,
        searchStatus: state.searchStatus,
        searchFailure: state.searchFailure,
        searchMatches: state.searchMatches,
        searchPage: state.searchPage,
        searchHasMore: state.searchHasMore,
      ),
    );
    final result = await _repository.reciters();
    if (isClosed) return;
    switch (result) {
      case Success(:final value):
        emit(
          QuranContentState(
            translationEditionsStatus: state.translationEditionsStatus,
            translationEditionsFailure: state.translationEditionsFailure,
            translationEditions: state.translationEditions,
            translations: state.translations,
            tafsirEditionsStatus: state.tafsirEditionsStatus,
            tafsirEditionsFailure: state.tafsirEditionsFailure,
            tafsirEditions: state.tafsirEditions,
            tafsirs: state.tafsirs,
            tafsirFailures: state.tafsirFailures,
            reciterStatus: LoadStatus.success,
            reciters: value,
            searchStatus: state.searchStatus,
            searchFailure: state.searchFailure,
            searchMatches: state.searchMatches,
            searchPage: state.searchPage,
            searchHasMore: state.searchHasMore,
          ),
        );
      case Err(:final failure):
        emit(
          QuranContentState(
            translationEditionsStatus: state.translationEditionsStatus,
            translationEditionsFailure: state.translationEditionsFailure,
            translationEditions: state.translationEditions,
            translations: state.translations,
            tafsirEditionsStatus: state.tafsirEditionsStatus,
            tafsirEditionsFailure: state.tafsirEditionsFailure,
            tafsirEditions: state.tafsirEditions,
            tafsirs: state.tafsirs,
            tafsirFailures: state.tafsirFailures,
            reciterStatus: LoadStatus.failure,
            reciterFailure: failure,
            reciters: state.reciters,
            searchStatus: state.searchStatus,
            searchFailure: state.searchFailure,
            searchMatches: state.searchMatches,
            searchPage: state.searchPage,
            searchHasMore: state.searchHasMore,
          ),
        );
    }
  }

  /// The text already held for [editionId]'s tafsir of [verse], or `null` if it has not been
  /// fetched (successfully) yet.
  String? tafsirFor(int editionId, VerseRef verse) =>
      state.tafsirs[_key(editionId, verse)];

  /// The failure from the last fetch of [editionId]'s tafsir of [verse], or `null` if it has not
  /// failed (it may simply not have been fetched yet). Unlike a translation, the tafsir sheet is
  /// open because the reader asked for it, so it shows this rather than nothing.
  Failure? tafsirFailureFor(int editionId, VerseRef verse) =>
      state.tafsirFailures[_key(editionId, verse)];

  /// Fetches and holds [editionId]'s tafsir of [verse] if not already held or already failed.
  /// Call again (the sheet's retry) to try a failed fetch once more.
  Future<void> loadTafsir({
    required int editionId,
    required VerseRef verse,
  }) async {
    final key = _key(editionId, verse);
    if (state.tafsirs.containsKey(key) ||
        state.tafsirFailures.containsKey(key)) {
      return;
    }
    final result = await _repository.tafsir(editionId: editionId, verse: verse);
    if (isClosed) return;
    switch (result) {
      case Success(:final value):
        emit(state.copyWith(tafsirs: {...state.tafsirs, key: value}));
      case Err(:final failure):
        emit(
          state.copyWith(
            tafsirFailures: {...state.tafsirFailures, key: failure},
          ),
        );
    }
  }

  /// Clears a failed fetch so [loadTafsir] will try again (the sheet's explicit retry).
  void retryTafsir(int editionId, VerseRef verse) {
    final key = _key(editionId, verse);
    if (!state.tafsirFailures.containsKey(key)) return;
    emit(
      state.copyWith(tafsirFailures: {...state.tafsirFailures}..remove(key)),
    );
  }

  static String _key(int editionId, VerseRef verse) =>
      '$editionId:${verse.sura}:${verse.verse}';

  QuranContentState _withSearch({
    required LoadStatus status,
    Failure? failure,
    List<TranslationSearchMatch>? matches,
    int? page,
    bool? hasMore,
  }) => QuranContentState(
    translationEditionsStatus: state.translationEditionsStatus,
    translationEditionsFailure: state.translationEditionsFailure,
    translationEditions: state.translationEditions,
    translations: state.translations,
    tafsirEditionsStatus: state.tafsirEditionsStatus,
    tafsirEditionsFailure: state.tafsirEditionsFailure,
    tafsirEditions: state.tafsirEditions,
    tafsirs: state.tafsirs,
    tafsirFailures: state.tafsirFailures,
    searchStatus: status,
    searchFailure: failure,
    searchMatches: matches ?? state.searchMatches,
    searchPage: page ?? state.searchPage,
    searchHasMore: hasMore ?? state.searchHasMore,
    reciterStatus: state.reciterStatus,
    reciterFailure: state.reciterFailure,
    reciters: state.reciters,
  );

  /// Starts a new search for [query] inside [editionId]'s translation, replacing any earlier
  /// results. A blank [query] just clears the results instead of running an empty search.
  Future<void> searchTranslation({
    required int editionId,
    required String query,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      emit(
        _withSearch(
          status: LoadStatus.initial,
          matches: const [],
          page: 1,
          hasMore: false,
        ),
      );
      return;
    }
    emit(_withSearch(status: LoadStatus.loading, matches: const [], page: 1));
    final result = await _repository.searchTranslation(
      editionId: editionId,
      query: trimmed,
    );
    if (isClosed) return;
    switch (result) {
      case Success(:final value):
        emit(
          _withSearch(
            status: LoadStatus.success,
            matches: value.matches,
            page: value.page,
            hasMore: value.hasMore,
          ),
        );
      case Err(:final failure):
        emit(
          _withSearch(
            status: LoadStatus.failure,
            failure: failure,
            matches: const [],
            page: 1,
            hasMore: false,
          ),
        );
    }
  }

  /// Fetches the next page of the current search (same [editionId] and [query] as the last
  /// [searchTranslation] call) and appends it. No-ops while a page is already loading or there is
  /// nothing more. A failure here keeps [QuranContentState.searchMatches] as they were, so the
  /// reader still sees what was already found.
  Future<void> loadMoreSearchResults({
    required int editionId,
    required String query,
  }) async {
    if (state.searchStatus == LoadStatus.loading || !state.searchHasMore) {
      return;
    }
    final nextPage = state.searchPage + 1;
    emit(_withSearch(status: LoadStatus.loading));
    final result = await _repository.searchTranslation(
      editionId: editionId,
      query: query.trim(),
      page: nextPage,
    );
    if (isClosed) return;
    switch (result) {
      case Success(:final value):
        emit(
          _withSearch(
            status: LoadStatus.success,
            matches: [...state.searchMatches, ...value.matches],
            page: value.page,
            hasMore: value.hasMore,
          ),
        );
      case Err(:final failure):
        emit(_withSearch(status: LoadStatus.failure, failure: failure));
    }
  }

  /// Resets search state, e.g. when the reader leaves the search page.
  void clearSearch() {
    if (state.searchStatus == LoadStatus.initial &&
        state.searchMatches.isEmpty) {
      return;
    }
    emit(
      _withSearch(
        status: LoadStatus.initial,
        matches: const [],
        page: 1,
        hasMore: false,
      ),
    );
  }
}
