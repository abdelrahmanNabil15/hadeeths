import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/features/search/domain/hadith_search_result.dart';
import 'package:mynewapp/features/search/domain/search_repository.dart';

enum SearchStatus {
  /// Nothing typed yet.
  idle,

  /// Fewer characters than the server accepts; no request is made.
  tooShort,
  loading,
  success,
  failure,
}

class SearchState extends Equatable {
  const SearchState({
    this.query = '',
    this.status = SearchStatus.idle,
    this.results = const [],
    this.failure,
  });

  /// The trimmed phrase the state belongs to.
  final String query;
  final SearchStatus status;
  final List<HadithSearchResult> results;
  final Failure? failure;

  /// True when the server may have had more matches than it returned.
  bool get mayBeTruncated => results.length >= SearchRepository.maxResults;

  @override
  List<Object?> get props => [query, status, results, failure];
}

/// Search-as-you-type over the server's search endpoint: waits for a pause in typing, never
/// asks for fewer characters than the server accepts, and ignores answers that arrive after
/// the phrase changed.
class SearchCubit extends Cubit<SearchState> {
  SearchCubit(
    this._repository, {
    required this.language,
    this.debounce = const Duration(milliseconds: 400),
  }) : super(const SearchState());

  final SearchRepository _repository;
  final String language;
  final Duration debounce;

  Timer? _timer;
  int _generation = 0;

  void onQueryChanged(String raw) {
    final query = raw.trim();
    _timer?.cancel();
    final generation = ++_generation;
    if (query.isEmpty) {
      emit(const SearchState());
      return;
    }
    if (query.length < SearchRepository.minPhraseLength) {
      emit(SearchState(query: query, status: SearchStatus.tooShort));
      return;
    }
    emit(SearchState(query: query, status: SearchStatus.loading));
    _timer = Timer(debounce, () => _run(query, generation));
  }

  /// Repeats the current phrase (after a failure).
  void retry() {
    final query = state.query;
    if (query.length < SearchRepository.minPhraseLength) return;
    _timer?.cancel();
    final generation = ++_generation;
    emit(SearchState(query: query, status: SearchStatus.loading));
    _run(query, generation);
  }

  Future<void> _run(String query, int generation) async {
    final result = await _repository.search(query, language: language);
    if (isClosed || generation != _generation) return;
    switch (result) {
      case Success(:final value):
        emit(
          SearchState(
            query: query,
            status: SearchStatus.success,
            results: value,
          ),
        );
      case Err(:final failure):
        emit(
          SearchState(
            query: query,
            status: SearchStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
