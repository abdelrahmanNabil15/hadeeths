import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../Model/category_node.dart';
import '../../Shared/errors/failure.dart';
import '../../Shared/Network/hadeeth_api.dart';

enum LoadStatus { initial, loading, success, failure }

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
  final List<CategoryNode> categories;

  /// Set when there is no data to show because loading failed.
  final Failure? failure;

  /// Set when a refresh failed but older data is still shown.
  final Failure? refreshFailure;

  final Map<String?, List<CategoryNode>> _children;
  final Map<String, CategoryNode> _byId;

  static Map<String?, List<CategoryNode>> _groupByParent(
    List<CategoryNode> all,
  ) {
    final map = <String?, List<CategoryNode>>{};
    for (final c in all) {
      (map[c.parentId] ??= []).add(c);
    }
    return map;
  }

  List<CategoryNode> get roots => _children[null] ?? const [];

  List<CategoryNode> childrenOf(String id) => _children[id] ?? const [];

  bool hasChildren(String id) => (_children[id] ?? const []).isNotEmpty;

  CategoryNode? byId(String id) => _byId[id];

  CategoriesState copyWith({
    LoadStatus? status,
    List<CategoryNode>? categories,
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
  CategoriesCubit(this._api) : super(CategoriesState());

  final HadeethApi _api;
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
      final all = await _api.getCategories();
      if (isClosed) return;
      emit(CategoriesState(status: LoadStatus.success, categories: all));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(
        hadData
            ? state.copyWith(
                status: LoadStatus.success,
                categories: state.categories,
                refreshFailure: f,
              )
            : state.copyWith(status: LoadStatus.failure, failure: f),
      );
    } finally {
      _inFlight = false;
    }
  }
}
