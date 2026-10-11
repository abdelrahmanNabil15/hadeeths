import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/features/adhan_sounds/domain/adhan_library.dart';
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
  });

  /// False until the phone has been asked what it supports and what it already has.
  final bool loaded;
  final bool supported;
  final List<AdhanItem> items;

  AdhanSoundsState copyWith({
    bool? loaded,
    bool? supported,
    List<AdhanItem>? items,
  }) => AdhanSoundsState(
    loaded: loaded ?? this.loaded,
    supported: supported ?? this.supported,
    items: items ?? this.items,
  );

  @override
  List<Object?> get props => [loaded, supported, items];
}

/// Downloads and removes the adhan recordings. Which one plays is chosen in the reminder settings
/// (`RemindersCubit.setAdhan`), not here.
class AdhanSoundsCubit extends Cubit<AdhanSoundsState> {
  AdhanSoundsCubit(this._library)
    : super(
        AdhanSoundsState(
          items: [for (final s in adhanCatalogue) AdhanItem(sound: s)],
        ),
      );

  final AdhanLibrary _library;

  Future<void> load() async {
    final supported = await _library.isSupported();
    final have = supported ? await _library.downloaded() : const <String>{};
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
}
