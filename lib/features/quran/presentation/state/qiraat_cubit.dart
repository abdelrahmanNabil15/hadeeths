import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/features/quran/domain/qiraat.dart';
import 'package:mynewapp/features/quran/domain/quran_content_repository.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';

class QiraatState {
  const QiraatState({this.matrices = const {}, this.failures = const {}});

  /// Fetched comparisons, keyed by `"sura:verse"`. A verse with no approved variations is held
  /// here too, as [QiraatMatrix.empty] -- that is the normal case, not something to re-fetch.
  final Map<String, QiraatMatrix> matrices;

  /// Fetches that failed, keyed the same way, holding the real [Failure] so the sheet can show
  /// the same typed error view the rest of the app uses.
  final Map<String, Failure> failures;
}

/// Qira'at (recitation-variant) comparisons, one verse at a time, opened on demand from the
/// verse long-press menu. Separate from `QuranContentCubit`: there is no "edition" to choose
/// here -- the matrix endpoint always returns every approved reading for the verse -- so this
/// needs none of that cubit's edition-list machinery, only a per-verse fetch-and-cache.
class QiraatCubit extends Cubit<QiraatState> {
  QiraatCubit(this._repository) : super(const QiraatState());

  final QuranContentRepository _repository;

  QiraatMatrix? matrixFor(VerseRef verse) => state.matrices[_key(verse)];

  Failure? failureFor(VerseRef verse) => state.failures[_key(verse)];

  /// Fetches and holds [verse]'s comparison if not already held or already failed. Call again
  /// (the sheet's retry) to try a failed fetch once more.
  Future<void> load(VerseRef verse) async {
    final key = _key(verse);
    if (state.matrices.containsKey(key) || state.failures.containsKey(key)) {
      return;
    }
    final result = await _repository.qiraatMatrix(verse);
    if (isClosed) return;
    switch (result) {
      case Success(:final value):
        emit(
          QiraatState(
            matrices: {...state.matrices, key: value},
            failures: state.failures,
          ),
        );
      case Err(:final failure):
        emit(
          QiraatState(
            matrices: state.matrices,
            failures: {...state.failures, key: failure},
          ),
        );
    }
  }

  /// Clears a failed fetch so [load] will try again.
  void retry(VerseRef verse) {
    final key = _key(verse);
    if (!state.failures.containsKey(key)) return;
    emit(
      QiraatState(
        matrices: state.matrices,
        failures: {...state.failures}..remove(key),
      ),
    );
  }

  static String _key(VerseRef verse) => '${verse.sura}:${verse.verse}';
}
