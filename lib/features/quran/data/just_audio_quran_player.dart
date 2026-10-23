import 'package:just_audio/just_audio.dart';
import 'package:mynewapp/features/quran/domain/quran_audio_player.dart';

QuranAudioEngineState _engineStateOf(PlayerState state) {
  switch (state.processingState) {
    case ProcessingState.idle:
      return QuranAudioEngineState.idle;
    case ProcessingState.loading:
    case ProcessingState.buffering:
      return QuranAudioEngineState.loading;
    case ProcessingState.completed:
      return QuranAudioEngineState.completed;
    case ProcessingState.ready:
      return state.playing
          ? QuranAudioEngineState.playing
          : QuranAudioEngineState.paused;
  }
}

/// [QuranAudioPlayer] over `just_audio` (MIT), the same package already used for adhan preview
/// playback (`JustAudioAdhanPlayer`). Separate class: that one plays a local file once; this one
/// streams a remote url and supports pause/resume for a transport bar.
class JustAudioQuranPlayer implements QuranAudioPlayer {
  JustAudioQuranPlayer([AudioPlayer? player])
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> play(Uri url) async {
    await _player.setUrl(url.toString());
    await _player.play();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.play();

  @override
  Future<void> stop() => _player.stop();

  @override
  Stream<QuranAudioEngineState> get stateStream =>
      _player.playerStateStream.map(_engineStateOf);

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Future<void> dispose() => _player.dispose();
}
