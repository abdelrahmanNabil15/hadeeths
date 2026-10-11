import 'package:mynewapp/core/notifications/notification_gateway.dart';
import 'package:mynewapp/features/adhan_sounds/domain/adhan_sound.dart';

/// Why a download did not produce a usable recording.
enum AdhanDownloadFailure {
  /// No connection, a timeout, or the server refused.
  network,

  /// The answer was not an audio file of about the expected size (a web page, a replaced file).
  notAudio,

  /// This phone cannot use a downloaded recording as a notification sound.
  unsupported,
}

class AdhanDownloadException implements Exception {
  const AdhanDownloadException(this.failure);

  final AdhanDownloadFailure failure;

  @override
  String toString() => 'AdhanDownloadException(${failure.name})';
}

/// The recordings kept on this phone. The platform plays one as a notification sound through
/// [uriFor].
abstract interface class AdhanLibrary implements NotificationSoundResolver {
  /// Whether this phone can use a downloaded recording as a notification sound (Android 10 and
  /// later). When false the adhan choice is not offered.
  Future<bool> isSupported();

  /// Whether a download is under way (the rating prompt never interrupts one).
  bool get downloading;

  /// The ids of the recordings that are on the phone.
  Future<Set<String>> downloaded();

  /// Downloads [sound] and makes it usable as a notification sound. [onProgress] gets 0 to 1.
  /// Throws [AdhanDownloadException]; nothing is left behind when it does.
  Future<void> download(
    AdhanSound sound, {
    void Function(double fraction)? onProgress,
  });

  /// Removes the recording from the phone.
  Future<void> delete(String id);
}
