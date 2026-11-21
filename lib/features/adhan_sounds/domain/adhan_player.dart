/// Plays a downloaded recording in the app, so the user can hear it before choosing it, and so it
/// can be listened to at all on a phone that cannot use it as a notification sound (iOS: see
/// `docs/ADHAN_SOUNDS.md`).
abstract interface class AdhanPlayer {
  /// Plays the file at [path] from the start, at [volume] (0 silent, 1 full), stopping whatever
  /// this player was already playing.
  Future<void> play(String path, {double volume = 1});

  /// Stops playback, if any.
  Future<void> stop();

  /// Fires once each time playback finishes on its own (not from [stop]).
  Stream<void> get onComplete;

  /// Releases the player. Call once, when it is no longer needed.
  Future<void> dispose();
}
