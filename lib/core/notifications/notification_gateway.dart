/// How a notification sounds. Only the system's own notification sound or silence: the app ships
/// no audio of its own.
enum NotificationSound { system, silent }

/// What the user reads. Built by the feature when a notification is scheduled; never contains a
/// place name or any private data, because it can be read on a locked screen.
class NotificationContent {
  const NotificationContent({
    required this.title,
    this.body,
    this.sound = NotificationSound.system,
    this.vibrate = true,
  });

  final String title;
  final String? body;
  final NotificationSound sound;
  final bool vibrate;
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
