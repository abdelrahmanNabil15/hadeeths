import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/core/state/load_status.dart';
import 'package:mynewapp/features/categories/domain/categories_repository.dart';
import 'package:mynewapp/features/categories/domain/hadith_category.dart';

class CategoriesState extends Equatable {
  CategoriesState({
    this.status = LoadStatus.initial,
    this.categories = const [],
    this.failure,
    this.refreshFailure,
  }) : _children = _groupByParent(categories),
       _byId = {for (final c in categories) c.id: c};

  final LoadStatus status;

  /// Every category (roots and descendants).
  final List<HadithCategory> categories;

  /// Set when there is no data to show because loading failed.
  final Failure? failure;

  /// Set when a refresh failed but older data is still shown.
  final Failure? refreshFailure;

  final Map<String?, List<HadithCategory>> _children;
  final Map<String, HadithCategory> _byId;

  static Map<String?, List<HadithCategory>> _groupByParent(
    List<HadithCategory> all,
  ) {
    final map = <String?, List<HadithCategory>>{};
    for (final c in all) {
      (map[c.parentId] ??= []).add(c);
    }
    return map;
  }

  List<HadithCategory> get roots => _children[null] ?? const [];

  List<HadithCategory> childrenOf(String id) => _children[id] ?? const [];

  bool hasChildren(String id) => (_children[id] ?? const []).isNotEmpty;

  HadithCategory? byId(String id) => _byId[id];

  CategoriesState copyWith({
    LoadStatus? status,
    List<HadithCategory>? categories,
    Failure? failure,
    Failure? refreshFailure,
  }) => CategoriesState(
    status: status ?? this.status,
    categories: categories ?? this.categories,
    failure: failure,
    refreshFailure: refreshFailure,
  );

  @override
  List<Object?> get props => [status, categories, failure, refreshFailure];
}

/// Holds the category tree for the whole app. One instance lives above the navigator, so
/// the tree is fetched once and survives navigation.
class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit(this._repository) : super(CategoriesState());

  final CategoriesRepository _repository;
  bool _inFlight = false;

  /// Loads the tree unless it is already loaded or loading. Use [retry] after a failure.
  Future<void> load() async {
    if (_inFlight || state.status == LoadStatus.success) return;
    await _fetch();
  }

  Future<void> retry() async {
    if (_inFlight) return;
    await _fetch();
  }

  /// Pull-to-refresh: keeps showing the current tree while loading, and keeps it if
  /// the refresh fails.
  Future<void> refresh() => retry();

  Future<void> _fetch() async {
    _inFlight = true;
    final hadData = state.categories.isNotEmpty;
    // With data on screen, only clear an old refresh error so that a repeated failure
    // is a distinct state change the UI can react to again.
    emit(
      hadData ? state.copyWith() : state.copyWith(status: LoadStatus.loading),
    );
    try {
      final result = await _repository.getCategories();
      if (isClosed) return;
      switch (result) {
        case Success(:final value):
          emit(CategoriesState(status: LoadStatus.success, categories: value));
        case Err(:final failure):
          emit(
            hadData
                ? state.copyWith(
                    status: LoadStatus.success,
                    categories: state.categories,
                    refreshFailure: failure,
                  )
                : state.copyWith(status: LoadStatus.failure, failure: failure),
          );
      }
    } finally {
      _inFlight = false;
    }
  }
}
