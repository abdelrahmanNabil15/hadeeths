import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/features/adhan_sounds/domain/adhan_library.dart';
import 'package:mynewapp/features/adhan_sounds/domain/adhan_player.dart';
import 'package:mynewapp/features/adhan_sounds/domain/adhan_sound.dart';

enum AdhanStatus { missing, downloading, ready }

/// One recording on the page: whether it is on the phone, how far its download is, and why the
/// last download failed, if it did.
class AdhanItem extends Equatable {
  const AdhanItem({
    required this.sound,
    this.status = AdhanStatus.missing,
    this.progress = 0,
    this.failure,
  });

  final AdhanSound sound;
  final AdhanStatus status;
  final double progress;
  final AdhanDownloadFailure? failure;

  AdhanItem copyWith({
    AdhanStatus? status,
    double? progress,
    AdhanDownloadFailure? failure,
    bool clearFailure = false,
  }) => AdhanItem(
    sound: sound,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => [sound, status, progress, failure];
}

class AdhanSoundsState extends Equatable {
  const AdhanSoundsState({
    this.loaded = false,
    this.supported = false,
    this.items = const [],
    this.playingId,
  });

  /// False until the phone has been asked what it supports and what it already has.
  final bool loaded;

  /// Whether this phone can use a downloaded recording as a notification sound. When false, a
  /// downloaded recording can still be played in the app, but not used for the reminder.
  final bool supported;
  final List<AdhanItem> items;

  /// The id of the recording playing in the app right now, or null.
  final String? playingId;

  AdhanSoundsState copyWith({
    bool? loaded,
    bool? supported,
    List<AdhanItem>? items,
    String? playingId,
    bool clearPlaying = false,
  }) => AdhanSoundsState(
    loaded: loaded ?? this.loaded,
    supported: supported ?? this.supported,
    items: items ?? this.items,
    playingId: clearPlaying ? null : (playingId ?? this.playingId),
  );

  @override
  List<Object?> get props => [loaded, supported, items, playingId];
}

/// Downloads and removes the adhan recordings, and plays one in the app (a preview, and the only
/// way to hear a downloaded recording at all on a phone that cannot use it as a notification
/// sound). Which one plays for the reminder is chosen in the reminder settings
/// (`RemindersCubit.setAdhan`), not here.
class AdhanSoundsCubit extends Cubit<AdhanSoundsState> {
  AdhanSoundsCubit(this._library, [AdhanPlayer? player])
    : _player = player ?? const _NoopAdhanPlayer(),
      super(
        AdhanSoundsState(
          items: [for (final s in adhanCatalogue) AdhanItem(sound: s)],
        ),
      ) {
    _completionSub = _player.onComplete.listen((_) {
      if (!isClosed) emit(state.copyWith(clearPlaying: true));
    });
  }

  final AdhanLibrary _library;
  final AdhanPlayer _player;
  StreamSubscription<void>? _completionSub;

  Future<void> load() async {
    final supported = await _library.isSupported();
    final have = await _library.downloaded();
    if (isClosed) return;
    emit(
      state.copyWith(
        loaded: true,
        supported: supported,
        items: [
          for (final item in state.items)
            item.copyWith(
              status: have.contains(item.sound.id)
                  ? AdhanStatus.ready
                  : AdhanStatus.missing,
            ),
        ],
      ),
    );
  }

  void _update(String id, AdhanItem Function(AdhanItem) change) {
    if (isClosed) return;
    emit(
      state.copyWith(
        items: [
          for (final item in state.items)
            item.sound.id == id ? change(item) : item,
        ],
      ),
    );
  }

  Future<void> download(AdhanSound sound) async {
    final current = state.items.firstWhere((i) => i.sound.id == sound.id);
    if (current.status == AdhanStatus.downloading) return;
    _update(
      sound.id,
      (i) => i.copyWith(
        status: AdhanStatus.downloading,
        progress: 0,
        clearFailure: true,
      ),
    );
    try {
      await _library.download(
        sound,
        onProgress: (fraction) =>
            _update(sound.id, (i) => i.copyWith(progress: fraction)),
      );
      _update(
        sound.id,
        (i) => i.copyWith(status: AdhanStatus.ready, progress: 1),
      );
    } on AdhanDownloadException catch (error) {
      _update(
        sound.id,
        (i) => i.copyWith(status: AdhanStatus.missing, failure: error.failure),
      );
    }
  }

  Future<void> delete(String id) async {
    if (state.playingId == id) await _stopPreview();
    await _library.delete(id);
    _update(
      id,
      (i) => i.copyWith(
        status: AdhanStatus.missing,
        progress: 0,
        clearFailure: true,
      ),
    );
  }

  /// Plays [id] in the app at [volume] (0 silent, 1 full), or stops it if it is already playing.
  /// Does nothing if [id] is not downloaded.
  Future<void> preview(String id, {double volume = 1}) async {
    if (state.playingId == id) {
      await _stopPreview();
      return;
    }
    final path = await _library.localPathFor(id);
    if (path == null || isClosed) return;
    await _player.play(path, volume: volume);
    if (!isClosed) emit(state.copyWith(playingId: id));
  }

  Future<void> _stopPreview() async {
    await _player.stop();
    if (!isClosed) emit(state.copyWith(clearPlaying: true));
  }

  @override
  Future<void> close() async {
    await _completionSub?.cancel();
    await _player.dispose();
    return super.close();
  }
}

/// Used when the cubit is built without a real player (existing call sites and tests that do not
/// exercise preview playback). [AdhanSoundsCubit.preview] still updates [AdhanSoundsState.playingId]
/// with this in place, but nothing actually plays.
class _NoopAdhanPlayer implements AdhanPlayer {
  const _NoopAdhanPlayer();

  @override
  Future<void> play(String path, {double volume = 1}) async {}

  @override
  Future<void> stop() async {}

  @override
  Stream<void> get onComplete => const Stream.empty();

  @override
  Future<void> dispose() async {}
}
