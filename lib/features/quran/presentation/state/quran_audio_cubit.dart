import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/features/quran/domain/quran_audio_player.dart';
import 'package:mynewapp/features/quran/domain/quran_content_repository.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';

enum AudioPlaybackStatus { idle, loading, playing, paused, failure }

class QuranAudioState {
  const QuranAudioState({
    this.status = AudioPlaybackStatus.idle,
    this.failure,
    this.verse,
    this.position = Duration.zero,
    this.duration,
  });

  final AudioPlaybackStatus status;

  /// Set only when [status] is [AudioPlaybackStatus.failure].
  final Failure? failure;

  /// The verse loading, playing or paused; `null` only in the initial [AudioPlaybackStatus.idle].
  final VerseRef? verse;
  final Duration position;

  /// `null` until the player reports it (shortly after loading starts).
  final Duration? duration;

  QuranAudioState copyWith({Duration? position, Duration? duration}) =>
      QuranAudioState(
        status: status,
        failure: failure,
        verse: verse,
        position: position ?? this.position,
        duration: duration ?? this.duration,
      );
}

/// Plays one reciter's recitation, verse by verse, for the reader's mini player: resolves each
/// verse's audio url through the proxy (`QuranContentRepository.recitationAudioUrl`), then hands
/// it to a [QuranAudioPlayer], auto-advancing to the next verse when one finishes. Built fresh per
/// `SuraReaderPage` (like `QuranContentCubit`), so playback stops when the reader closes --
/// foreground only for this version, see `docs/QURAN_API_REFACTOR_PLAN.md` flag D.
class QuranAudioCubit extends Cubit<QuranAudioState> {
  QuranAudioCubit(this._repository, this._player)
    : super(const QuranAudioState()) {
    _engineSub = _player.stateStream.listen(_onEngineState);
    _positionSub = _player.positionStream.listen(
      (p) => emit(state.copyWith(position: p)),
    );
    _durationSub = _player.durationStream.listen(
      (d) => emit(state.copyWith(duration: d)),
    );
  }

  final QuranContentRepository _repository;
  final QuranAudioPlayer _player;
  late final StreamSubscription<QuranAudioEngineState> _engineSub;
  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<Duration?> _durationSub;

  int? _reciterId;
  int _firstVerse = 1;
  int _lastVerse = 1;

  /// Plays [reciterId]'s recitation of [verse], replacing anything already playing. [firstVerse]/
  /// [lastVerse] bound [next]/[previous] and where auto-advance stops, i.e. the open sura's verse
  /// range.
  Future<void> play({
    required int reciterId,
    required VerseRef verse,
    required int firstVerse,
    required int lastVerse,
  }) async {
    _reciterId = reciterId;
    _firstVerse = firstVerse;
    _lastVerse = lastVerse;
    emit(QuranAudioState(status: AudioPlaybackStatus.loading, verse: verse));
    final result = await _repository.recitationAudioUrl(
      reciterId: reciterId,
      verse: verse,
    );
    if (isClosed) return;
    switch (result) {
      case Success(:final value):
        try {
          await _player.play(value);
        } on Object {
          if (!isClosed) {
            emit(
              QuranAudioState(
                status: AudioPlaybackStatus.failure,
                verse: verse,
                failure: const Failure(FailureKind.unexpected),
              ),
            );
          }
        }
      case Err(:final failure):
        emit(
          QuranAudioState(
            status: AudioPlaybackStatus.failure,
            verse: verse,
            failure: failure,
          ),
        );
    }
  }

  /// Replays the verse that just failed, with the same reciter and sura bounds.
  Future<void> retry() {
    final verse = state.verse;
    if (verse == null || _reciterId == null) return Future.value();
    return play(
      reciterId: _reciterId!,
      verse: verse,
      firstVerse: _firstVerse,
      lastVerse: _lastVerse,
    );
  }

  Future<void> pause() => _player.pause();

  Future<void> resume() => _player.resume();

  Future<void> stop() async {
    await _player.stop();
    if (!isClosed) emit(const QuranAudioState());
  }

  bool get hasPrevious =>
      state.verse != null && state.verse!.verse > _firstVerse;

  bool get hasNext => state.verse != null && state.verse!.verse < _lastVerse;

  Future<void> next() {
    final verse = state.verse;
    if (verse == null || _reciterId == null || !hasNext) {
      return Future.value();
    }
    return play(
      reciterId: _reciterId!,
      verse: VerseRef(verse.sura, verse.verse + 1),
      firstVerse: _firstVerse,
      lastVerse: _lastVerse,
    );
  }

  Future<void> previous() {
    final verse = state.verse;
    if (verse == null || _reciterId == null || !hasPrevious) {
      return Future.value();
    }
    return play(
      reciterId: _reciterId!,
      verse: VerseRef(verse.sura, verse.verse - 1),
      firstVerse: _firstVerse,
      lastVerse: _lastVerse,
    );
  }

  void _onEngineState(QuranAudioEngineState engineState) {
    switch (engineState) {
      case QuranAudioEngineState.playing:
        if (state.status != AudioPlaybackStatus.failure) {
          emit(
            QuranAudioState(
              status: AudioPlaybackStatus.playing,
              verse: state.verse,
              position: state.position,
              duration: state.duration,
            ),
          );
        }
      case QuranAudioEngineState.paused:
        if (state.status != AudioPlaybackStatus.failure) {
          emit(
            QuranAudioState(
              status: AudioPlaybackStatus.paused,
              verse: state.verse,
              position: state.position,
              duration: state.duration,
            ),
          );
        }
      case QuranAudioEngineState.completed:
        unawaited(hasNext ? next() : stop());
      case QuranAudioEngineState.idle:
      case QuranAudioEngineState.loading:
        break; // handled explicitly by play()'s own loading/failure emits
    }
  }

  @override
  Future<void> close() async {
    await _engineSub.cancel();
    await _positionSub.cancel();
    await _durationSub.cancel();
    await _player.dispose();
    return super.close();
  }
}
