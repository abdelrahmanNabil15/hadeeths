import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../Model/hadith_page.dart';
import '../../Shared/errors/failure.dart';
import '../../Shared/Network/hadeeth_api.dart';
import '../categories/categories_cubit.dart' show LoadStatus;

class HadithListState extends Equatable {
  const HadithListState({
    this.status = LoadStatus.initial,
    this.items = const [],
    this.currentPage = 0,
    this.lastPage = 0,
    this.totalItems = 0,
    this.isLoadingMore = false,
    this.failure,
    this.loadMoreFailure,
    this.refreshFailure,
  });

  final LoadStatus status;

  /// Everything loaded so far. The UI must size its list from this, never from [totalItems].
  final List<HadithSummary> items;
  final int currentPage;
  final int lastPage;

  /// Server-reported total; informational only.
  final int totalItems;
  final bool isLoadingMore;
  final Failure? failure;
  final Failure? loadMoreFailure;
  final Failure? refreshFailure;

  bool get hasMore => currentPage < lastPage;

  HadithListState copyWith({
    LoadStatus? status,
    List<HadithSummary>? items,
    int? currentPage,
    int? lastPage,
    int? totalItems,
    bool? isLoadingMore,
    Failure? failure,
    Failure? loadMoreFailure,
    Failure? refreshFailure,
  }) => HadithListState(
    status: status ?? this.status,
    items: items ?? this.items,
    currentPage: currentPage ?? this.currentPage,
    lastPage: lastPage ?? this.lastPage,
    totalItems: totalItems ?? this.totalItems,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    failure: failure,
    loadMoreFailure: loadMoreFailure,
    refreshFailure: refreshFailure,
  );

  @override
  List<Object?> get props => [
    status,
    items,
    currentPage,
    lastPage,
    totalItems,
    isLoadingMore,
    failure,
    loadMoreFailure,
    refreshFailure,
  ];
}

/// Paged hadith list of one category, following the API's `page` / `last_page` contract.
class HadithListCubit extends Cubit<HadithListState> {
  HadithListCubit(this._api, this.categoryId) : super(const HadithListState());

  final HadeethApi _api;
  final String categoryId;

  /// Bumped on every reload so a slow response from before a reload is ignored.
  int _generation = 0;

  /// Loads the first page (also used to retry after a failure).
  Future<void> load() async {
    final generation = ++_generation;
    emit(const HadithListState(status: LoadStatus.loading));
    try {
      final page = await _api.getHadithPage(categoryId: categoryId, page: 1);
      if (isClosed || generation != _generation) return;
      emit(_fromFirstPage(page));
    } on Failure catch (f) {
      if (isClosed || generation != _generation) return;
      emit(HadithListState(status: LoadStatus.failure, failure: f));
    }
  }

  /// Pull-to-refresh: replaces the list on success; keeps it, and reports the failure, otherwise.
  Future<void> refresh() async {
    if (state.status != LoadStatus.success) return load();
    final generation = ++_generation;
    emit(
      state.copyWith(isLoadingMore: false),
    ); // clears any previous refresh error
    try {
      final page = await _api.getHadithPage(categoryId: categoryId, page: 1);
      if (isClosed || generation != _generation) return;
      emit(_fromFirstPage(page));
    } on Failure catch (f) {
      if (isClosed || generation != _generation) return;
      emit(state.copyWith(isLoadingMore: false, refreshFailure: f));
    }
  }

  /// Fetches the next page, if there is one and none is already being fetched.
  Future<void> loadMore() async {
    if (state.status != LoadStatus.success ||
        !state.hasMore ||
        state.isLoadingMore) {
      return;
    }
    final generation = _generation;
    final requested = state.currentPage + 1;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final page = await _api.getHadithPage(
        categoryId: categoryId,
        page: requested,
      );
      if (isClosed || generation != _generation) return;
      final known = {for (final h in state.items) h.id};
      final fresh = page.items.where((h) => !known.contains(h.id)).toList();
      emit(
        state.copyWith(
          items: [...state.items, ...fresh],
          currentPage: requested,
          // An empty page before the advertised last page would otherwise loop forever.
          lastPage: page.items.isEmpty ? requested : page.lastPage,
          totalItems: page.totalItems,
          isLoadingMore: false,
        ),
      );
    } on Failure catch (f) {
      if (isClosed || generation != _generation) return;
      emit(state.copyWith(isLoadingMore: false, loadMoreFailure: f));
    }
  }

  HadithListState _fromFirstPage(HadithPage page) => HadithListState(
    status: LoadStatus.success,
    items: _dedupe(page.items),
    currentPage: page.currentPage,
    lastPage: page.lastPage,
    totalItems: page.totalItems,
  );

  static List<HadithSummary> _dedupe(List<HadithSummary> items) {
    final seen = <String>{};
    return [
      for (final h in items)
        if (seen.add(h.id)) h,
    ];
  }
}
