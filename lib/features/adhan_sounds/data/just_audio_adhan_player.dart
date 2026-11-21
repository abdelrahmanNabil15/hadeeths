import 'package:just_audio/just_audio.dart';
import 'package:mynewapp/features/adhan_sounds/domain/adhan_player.dart';

/// [AdhanPlayer] over `just_audio` (MIT).
class JustAudioAdhanPlayer implements AdhanPlayer {
  JustAudioAdhanPlayer([AudioPlayer? player])
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> play(String path, {double volume = 1}) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
    await _player.setFilePath(path);
    await _player.play();
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Stream<void> get onComplete => _player.playerStateStream
      .where((state) => state.processingState == ProcessingState.completed)
      .map((_) {});

  @override
  Future<void> dispose() => _player.dispose();
}
