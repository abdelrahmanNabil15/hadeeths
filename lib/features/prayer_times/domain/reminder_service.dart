import 'package:mynewapp/core/notifications/planned_notification.dart';

/// What is scheduled right now.
class ReminderStatus {
  const ReminderStatus({
    this.scheduled = 0,
    this.next,
    this.notificationsAllowed = true,
    this.failed = 0,
    this.needsPlace = false,
    this.exactDenied = false,
    this.heldBackByQuietHours = 0,
    this.scheduledPrayers = 0,
    this.nextPrayer,
  });

  /// How many reminders the platform is holding for the app.
  final int scheduled;

  /// The nearest one, if any (a prayer or a salawat reminder).
  final PlannedNotification? next;

  /// How many of them are prayer reminders, and the nearest of those.
  final int scheduledPrayers;
  final PlannedNotification? nextPrayer;

  /// Whether the system lets the app show notifications at all.
  final bool notificationsAllowed;

  /// Operations that failed in the last synchronisation.
  final int failed;

  /// Reminders are on but there is no place yet, so there are no times to remind about.
  final bool needsPlace;

  /// Exact timing is switched on but the system does not allow it, so reminders are scheduled
  /// inexactly and may arrive late.
  final bool exactDenied;

  /// Salawat reminders in the planned period that quiet hours kept from being sent. Shown to the
  /// user, so nothing is held back silently.
  final int heldBackByQuietHours;
}

/// Keeps the platform's reminders in line with the saved place, calculation settings and reminder
/// choices. One service for every kind of reminder times; nothing else schedules notifications.
abstract interface class ReminderService {
  /// Recomputes the reminders from what is saved and makes the platform match. Safe to call as
  /// often as wanted; when nothing changed it changes nothing. Never throws.
  Future<ReminderStatus> reconcile();

  /// What is scheduled, without changing anything.
  Future<ReminderStatus> status();

  /// Shows a notification now, in the user's chosen sound, so they can check it works.
  Future<void> sendTest();

  /// Removes every reminder the app scheduled.
  Future<void> cancelAll();
}
