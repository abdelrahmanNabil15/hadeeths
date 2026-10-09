import 'package:mynewapp/core/notifications/planned_notification.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_day.dart';
import 'package:mynewapp/features/prayer_times/domain/reminder_settings.dart';

/// Turns calculated days and the user's reminder choices into notification candidates for the
/// shared planner.
abstract final class ReminderPlanBuilder {
  /// How many days ahead are scheduled. Seven days of six reminders is far below the 64
  /// notifications iOS will hold; the rest is added the next time the app is opened.
  static const horizon = Duration(days: 7);

  /// One candidate per chosen time per day, [ReminderSettings.leadMinutes] before it.
  ///
  /// [contentSignature] describes everything that decides what the notification says (language,
  /// numerals, clock style, place zone, sound, vibration, lead); when it changes the notification is
  /// replaced in place.
  static List<NotificationCandidate> candidates({
    required Iterable<PrayerDay> days,
    required ReminderSettings settings,
    required String contentSignature,
  }) {
    final lead = Duration(minutes: settings.leadMinutes);
    return [
      for (final day in days)
        for (final prayer in settings.active)
          NotificationCandidate(
            kind: NotificationKind.prayer,
            key: prayer.name,
            fireAt: day[prayer].subtract(lead),
            priority: 10,
            respectsQuietHours: false,
            signature: contentSignature,
          ),
    ];
  }
}
