import 'package:mynewapp/core/platform/full_adhan_channel.dart';
import 'package:mynewapp/features/adhan_sounds/domain/adhan_library.dart';
import 'package:mynewapp/features/adhan_sounds/domain/adhan_player.dart';

/// Plays the full adhan recording in the app when native code asks for it, through [channel]: the
/// app was in the foreground when a "Full adhan" prayer reminder fired, or the user tapped it.
/// iOS only (see `docs/ADHAN_SOUNDS.md`); wired once at startup, never built for Android.
class FullAdhanCoordinator {
  FullAdhanCoordinator({
    required FullAdhanChannel channel,
    required this._library,
    required this._player,
    Future<double> Function()? volume,
  }) : _volume = volume ?? (() async => 1) {
    channel.listen(_play);
  }

  final AdhanLibrary _library;
  final AdhanPlayer _player;

  /// Reads the user's current chosen volume (see `ReminderSettings.adhanVolume`) each time, so a
  /// change takes effect on the next reminder without restarting the app.
  final Future<double> Function() _volume;

  Future<void> _play(String adhanId) async {
    final path = await _library.localPathFor(adhanId);
    if (path == null) return;
    await _player.play(path, volume: await _volume());
  }
}
