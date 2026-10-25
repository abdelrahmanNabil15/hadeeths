import 'package:mynewapp/core/notifications/notification_gateway.dart';
import 'package:mynewapp/features/adhan_sounds/domain/adhan_sound.dart';

/// Why a download did not produce a usable recording.
enum AdhanDownloadFailure {
  /// No connection, a timeout, or the server refused.
  network,

  /// The answer was not an audio file of about the expected size (a web page, a replaced file).
  notAudio,

  /// The recording downloaded, but this phone could not list it as a notification sound (a
  /// phone that cannot do that at all skips the attempt instead; see [AdhanLibrary.isSupported]).
  unsupported,
}

class AdhanDownloadException implements Exception {
  const AdhanDownloadException(this.failure);

  final AdhanDownloadFailure failure;

  @override
  String toString() => 'AdhanDownloadException(${failure.name})';
}

/// The recordings kept on this phone. The platform plays one as a notification sound through
/// [uriFor]; [localPathFor] plays one in the app, regardless of platform.
abstract interface class AdhanLibrary implements NotificationSoundResolver {
  /// Whether this phone can use a downloaded recording as a notification sound: Android 10 and
  /// later (the full recording), or iOS (a short clip prepared from it at download time, capped
  /// at 30 seconds by the system; see `docs/ADHAN_SOUNDS.md`). When false (older Android), the
  /// recording can still be downloaded and played in the app through [localPathFor], but "Use
  /// this adhan" (for the prayer-time reminder) is not offered.
  Future<bool> isSupported();

  /// Whether a download is under way (the rating prompt never interrupts one).
  bool get downloading;

  /// The ids of the recordings that are on the phone.
  Future<Set<String>> downloaded();

  /// Downloads [sound] and, where the phone can do so, makes it usable as a notification sound.
  /// [onProgress] gets 0 to 1. Throws [AdhanDownloadException]; nothing is left behind when it
  /// does. The recording is kept even on a phone that cannot use it as a notification sound at
  /// all (iOS), so it can still be played in the app through [localPathFor].
  Future<void> download(
    AdhanSound sound, {
    void Function(double fraction)? onProgress,
  });

  /// Removes the recording from the phone.
  Future<void> delete(String id);

  /// The local file for a downloaded recording, to play in the app. Null when it is not
  /// downloaded.
  Future<String?> localPathFor(String id);
}
