/// How a notification sounds: the system's own notification sound, or silence. The app ships no
/// audio of its own; a [CustomSound] is a recording the user chose to download.
enum NotificationSound { system, silent }

/// A recording the user downloaded, to play instead of the system's notification sound (Android
/// 10 and later). [id] names it in the app's library; [label] is its name in the user's language,
/// shown in the phone's own notification settings.
class CustomSound {
  const CustomSound({required this.id, required this.label});

  final String id;
  final String label;
}

/// A short recording that ships with the app (an Android raw resource called [resource], without
/// its extension). [label] names it in the phone's own notification settings. With [alarm] it
/// plays as an alarm does, not as a notification: it is not muted with the notification volume.
class BundledSound {
  const BundledSound({
    required this.resource,
    required this.label,
    this.alarm = false,
  });

  final String resource;
  final String label;
  final bool alarm;
}

/// Finds where the platform can read a downloaded recording from. Null when it is gone or not
/// supported, in which case the notification uses the system sound.
abstract interface class NotificationSoundResolver {
  Future<String?> uriFor(String id);
}

/// What the user reads. Built by the feature when a notification is scheduled; never contains a
/// place name or any private data, because it can be read on a locked screen.
class NotificationContent {
  const NotificationContent({
    required this.title,
    this.body,
    this.sound = NotificationSound.system,
    this.vibrate = true,
    this.customSound,
    this.bundledSound,
  });

  final String title;
  final String? body;
  final NotificationSound sound;
  final bool vibrate;

  /// Used only with [NotificationSound.system]: a downloaded recording in place of the system sound.
  final CustomSound? customSound;

  /// A sound that ships with the app, in place of the system sound (Android; elsewhere the system
  /// sound is used). Ignored when [customSound] is set or the sound is silent.
  final BundledSound? bundledSound;
}

/// A notification the platform is holding for later, with the text the app attached to it
/// (`payload`) so the app can tell its own notifications apart and recognise them again.
class PendingEntry {
  const PendingEntry({required this.id, this.payload});

  final int id;
  final String? payload;
}

/// Words the platform shows in its own notification settings (Android lists the channels there).
class ChannelLabels {
  const ChannelLabels({
    required this.soundAndVibration,
    required this.soundOnly,
    required this.vibrationOnly,
    required this.silent,
    required this.description,
  });

  final String soundAndVibration;
  final String soundOnly;
  final String vibrationOnly;
  final String silent;
  final String description;
}

/// The platform's local notifications, behind a small interface so the scheduling logic can be
/// tested without a phone. The real one wraps `flutter_local_notifications`.
abstract interface class NotificationGateway {
  /// Gives the platform the words for its settings screen (in the user's language). Safe to call
  /// again when the language changes.
  Future<void> prepare(ChannelLabels labels);

  /// Everything currently waiting to fire.
  Future<List<PendingEntry>> pending();

  /// Asks the platform to show [content] at [fireAt] (UTC), replacing any pending notification
  /// with the same [id]. With [exact] it is delivered on the minute when the system allows exact
  /// alarms; otherwise (or without that permission) the system may deliver it late.
  Future<void> schedule({
    required int id,
    required DateTime fireAt,
    required String payload,
    required NotificationContent content,
    bool exact = false,
  });

  Future<void> cancel(int id);

  /// Shows a notification right now (the "test" button).
  Future<void> showNow({required int id, required NotificationContent content});

  /// Whether the system currently lets the app show notifications.
  Future<bool> notificationsAllowed();

  /// Whether the system lets the app schedule exact alarms (Android only; elsewhere true).
  Future<bool> exactAlarmsAllowed();
}
