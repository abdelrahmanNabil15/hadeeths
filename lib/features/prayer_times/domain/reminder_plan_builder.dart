import 'package:mynewapp/core/notifications/planned_notification.dart';
import 'package:mynewapp/core/time/zone.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_day.dart';
import 'package:mynewapp/features/prayer_times/domain/reminder_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/salawat_settings.dart';

/// Turns calculated days and the user's reminder choices into notification candidates for the
/// shared planner.
abstract final class ReminderPlanBuilder {
  /// How many days ahead are scheduled. Seven days of six reminders is far below the 64
  /// notifications iOS will hold; the rest is added the next time the app is opened.
  static const horizon = Duration(days: 7);

  /// Salawat reminders are planned this many days ahead (today included), so that with prayer
  /// reminders they stay under the iOS limit; the rest is added each time the app is opened.
  static const salawatDays = 2;

  /// Priority of prayer reminders: kept first when the platform limit forces a choice.
  static const prayerPriority = 10;

  /// Priority of salawat reminders: below prayers, so they can never push a prayer reminder out.
  static const salawatPriority = 5;

  /// Key of a salawat reminder at its time, and of the optional one before it.
  static const salawatKey = 'salawat';
  static const salawatSoonKey = 'salawat_soon';

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
            priority: prayerPriority,
            respectsQuietHours: false,
            signature: contentSignature,
          ),
    ];
  }

  /// Salawat reminders for today and the next day, at the chosen times on the phone's clock ([zone]),
  /// each with its optional earlier reminder. They respect quiet hours. Times already passed are
  /// left to the planner, which drops them.
  static List<NotificationCandidate> salawatCandidates({
    required SalawatSettings settings,
    required TimeZoneRules zone,
    required DateTime now,
    required String signature,
  }) {
    if (!settings.enabled) return const [];
    final today = zone.localDateAt(now);
    final lead = Duration(minutes: settings.leadMinutes);
    return [
      for (var day = 0; day < salawatDays; day++)
        for (final minute in settings.minutesOfDay) ...[
          ..._salawatAt(
            zone.utcFromWallClock(
              today.add(Duration(days: day, minutes: minute)),
            ),
            lead,
            signature,
          ),
        ],
    ];
  }

  static List<NotificationCandidate> _salawatAt(
    DateTime at,
    Duration lead,
    String signature,
  ) => [
    NotificationCandidate(
      kind: NotificationKind.salawat,
      key: salawatKey,
      fireAt: at,
      priority: salawatPriority,
      signature: signature,
    ),
    if (lead > Duration.zero)
      NotificationCandidate(
        kind: NotificationKind.salawat,
        key: salawatSoonKey,
        fireAt: at.subtract(lead),
        priority: salawatPriority,
        signature: signature,
      ),
  ];
}
