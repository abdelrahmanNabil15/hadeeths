/// What the underlying audio engine is doing right now. Unlike `AdhanPlayer` (one-shot preview
/// playback), this tracks enough state for a transport bar: pause/resume, not just play/stop.
enum QuranAudioEngineState { idle, loading, playing, paused, completed }

/// Plays one recitation file at a time, for the reader's mini player. Foreground playback only
/// for this version (no lock-screen controls, no background-audio entitlement) -- see
/// `docs/QURAN_API_REFACTOR_PLAN.md` flag D.
abstract interface class QuranAudioPlayer {
  /// Plays the recording at [url] from the start, stopping whatever was already playing.
  Future<void> play(Uri url);

  /// Pauses playback; [resume] continues from the same position.
  Future<void> pause();

  /// Resumes playback paused by [pause].
  Future<void> resume();

  /// Stops playback and resets position to the start.
  Future<void> stop();

  Stream<QuranAudioEngineState> get stateStream;
  Stream<Duration> get positionStream;

  /// Fires once known; `null` until then.
  Stream<Duration?> get durationStream;

  /// Releases the player. Call once, when it is no longer needed.
  Future<void> dispose();
}
