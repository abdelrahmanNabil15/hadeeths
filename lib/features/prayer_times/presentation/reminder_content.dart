import 'package:mynewapp/core/format/clock_format.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/notifications/notification_gateway.dart';
import 'package:mynewapp/core/notifications/planned_notification.dart';
import 'package:mynewapp/core/time/zone.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/prayer_times/domain/reminder_plan_builder.dart';
import 'package:mynewapp/features/prayer_times/domain/reminder_settings.dart';
import 'package:mynewapp/features/prayer_times/presentation/prayer_labels.dart';
import 'package:mynewapp/features/prayer_times/presentation/salawat_wording.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// The words of a prayer reminder.
///
/// A reminder says only what a prayer time is: which one, and when. It does not say anything
/// about the user, never names the place, and makes no religious claim; it can be read on a
/// locked screen. Wording beyond this is for the owner and a religious reviewer to decide.
NotificationContent reminderContent({
  required AppLocalizations l10n,
  required PlannedNotification notification,
  required ReminderSettings settings,
  required Digits digits,
  required bool use24Hour,
  required TimeZoneRules zone,
  bool silent = false,
}) {
  if (notification.kind == NotificationKind.salawat) {
    return salawatContent(
      notification: notification,
      settings: settings,
      digits: digits,
    );
  }
  final prayer = Prayer.values.byName(notification.key);
  final lead = settings.leadMinutes;
  final isSunrise = prayer == Prayer.sunrise;
  final String title;
  String? body;
  if (lead == 0) {
    title = isSunrise
        ? l10n.reminderSunriseNow
        : l10n.reminderNow(prayerName(l10n, prayer));
  } else {
    title = digits.localize(
      isSunrise
          ? l10n.reminderSunriseSoon(lead)
          : l10n.reminderSoon(lead, prayerName(l10n, prayer)),
    );
    body = formatClock(
      zone.wallClockAt(notification.fireAt.add(Duration(minutes: lead))),
      arabic: _isArabic(l10n),
      use24Hour: use24Hour,
      digits: digits,
    );
  }
  // A prayer reminder in quiet hours, with "deliver silently" on: shown, but without sound or
  // vibration. It is never dropped or moved.
  return NotificationContent(
    title: title,
    body: body,
    sound: silent ? NotificationSound.silent : settings.sound,
    vibrate: !silent && settings.vibrate,
  );
}

/// The words of a salawat reminder: the owner-approved Arabic, in both interface languages.
NotificationContent salawatContent({
  required PlannedNotification notification,
  required ReminderSettings settings,
  required Digits digits,
}) => NotificationContent(
  title: notification.key == ReminderPlanBuilder.salawatSoonKey
      ? salawatSoonText(settings.salawat.leadMinutes, digits)
      : salawatNowText,
  sound: settings.sound,
  vibrate: settings.vibrate,
);

/// The words for the platform's own notification settings.
ChannelLabels channelLabels(AppLocalizations l10n) => ChannelLabels(
  soundAndVibration: l10n.reminderChannelSoundVibrate,
  soundOnly: l10n.reminderChannelSound,
  vibrationOnly: l10n.reminderChannelVibrate,
  silent: l10n.reminderChannelSilent,
  description: l10n.reminderChannelDescription,
);

bool _isArabic(AppLocalizations l10n) => l10n.localeName.startsWith('ar');
