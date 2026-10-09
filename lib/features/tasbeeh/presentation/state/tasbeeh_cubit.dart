import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/haptics/haptics.dart';
import 'package:mynewapp/features/tasbeeh/domain/tasbeeh_counter.dart';
import 'package:mynewapp/features/tasbeeh/domain/tasbeeh_repository.dart';

class TasbeehState {
  const TasbeehState({
    this.counter = const TasbeehCounter(),
    this.loaded = false,
    this.saveFailed = false,
  });

  final TasbeehCounter counter;

  /// The saved counter has been read; taps before that would be overwritten by it.
  final bool loaded;

  /// The last save failed (the count on screen is still right; it was not stored).
  final bool saveFailed;

  TasbeehState copyWith({
    TasbeehCounter? counter,
    bool? loaded,
    bool? saveFailed,
  }) => TasbeehState(
    counter: counter ?? this.counter,
    loaded: loaded ?? this.loaded,
    saveFailed: saveFailed ?? this.saveFailed,
  );

  @override
  bool operator ==(Object other) =>
      other is TasbeehState &&
      other.counter == counter &&
      other.loaded == loaded &&
      other.saveFailed == saveFailed;

  @override
  int get hashCode => Object.hash(counter, loaded, saveFailed);
}

/// The counter's logic. The count changes in memory at the instant of the tap and never waits for
/// anything (not for saving, not for a vibration, not for an animation), so quick taps cannot be
/// lost. Saves run one after another and each writes whatever the count is by then, so the last
/// save always holds the final count.
class TasbeehCubit extends Cubit<TasbeehState> {
  TasbeehCubit({required this.repository, required this.haptics})
    : super(const TasbeehState());

  final TasbeehRepository repository;
  final Haptics haptics;

  Future<void> _saves = Future.value();

  Future<void> load() async {
    try {
      final saved = await repository.load();
      if (isClosed) return;
      emit(state.copyWith(counter: saved, loaded: true));
    } on Object {
      if (isClosed) return;
      // Counting still works; it just will not be remembered.
      emit(state.copyWith(loaded: true, saveFailed: true));
    }
  }

  /// One more. A light tick for the tap, and a firmer one when the count lands on the target.
  Future<void> tap() {
    if (!state.loaded) return Future.value();
    final next = state.counter.increment();
    if (next == state.counter) return Future.value();
    _set(next);
    next.onTarget ? haptics.alignment() : haptics.selection();
    return _save();
  }

  Future<void> undo() => _change(state.counter.decrement());

  Future<void> reset() => _change(state.counter.reset());

  Future<void> setTarget(int? target) =>
      _change(state.counter.withTarget(target));

  Future<void> _change(TasbeehCounter next) {
    if (next == state.counter) return Future.value();
    _set(next);
    return _save();
  }

  void _set(TasbeehCounter next) => emit(state.copyWith(counter: next));

  Future<void> _save() {
    final save = _saves.then((_) async {
      try {
        await repository.save(state.counter);
        if (!isClosed && state.saveFailed) {
          emit(state.copyWith(saveFailed: false));
        }
      } on Object {
        if (!isClosed) emit(state.copyWith(saveFailed: true));
      }
    });
    _saves = save;
    return save;
  }
}
