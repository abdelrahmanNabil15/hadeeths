import 'package:flutter/services.dart';

/// Tells the app when to play the full adhan recording itself: iOS asks for this when a "Full
/// adhan" prayer reminder fires while the app is in the foreground (its own notification sound is
/// a short clip; see `docs/ADHAN_SOUNDS.md`), or when the user taps the notification. Android never
/// asks: it already plays the full recording as the notification's own sound.
abstract interface class FullAdhanChannel {
  /// Calls [onPlay] with the chosen recording's id each time native code asks for full playback.
  /// Replaces any handler set by an earlier call.
  void listen(void Function(String adhanId) onPlay);
}

/// [FullAdhanChannel] over the `hadeeths/full_adhan` channel (`AppDelegate.swift`, iOS only).
class MethodChannelFullAdhanChannel implements FullAdhanChannel {
  MethodChannelFullAdhanChannel([
    this._channel = const MethodChannel('hadeeths/full_adhan'),
  ]);

  final MethodChannel _channel;

  @override
  void listen(void Function(String adhanId) onPlay) {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'playFullAdhan') return;
      final args = call.arguments;
      final id = args is Map ? args['adhanId'] as String? : null;
      if (id != null) onPlay(id);
    });
  }
}
