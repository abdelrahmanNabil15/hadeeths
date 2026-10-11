import 'package:mynewapp/core/format/clock_format.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/notifications/notification_gateway.dart';
import 'package:mynewapp/core/notifications/planned_notification.dart';
import 'package:mynewapp/core/time/zone.dart';
import 'package:mynewapp/features/adhan_sounds/domain/adhan_sound.dart';
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
      silent: silent,
    );
  }
  if (notification.kind == NotificationKind.wakeUp) {
    return wakeUpContent(
      l10n: l10n,
      notification: notification,
      settings: settings,
      digits: digits,
      use24Hour: use24Hour,
      zone: zone,
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
    // The adhan plays only for a reminder at the prayer time: not for an early reminder, and not for
    // sunrise, which is not a prayer.
    customSound: !silent && lead == 0 && !isSunrise
        ? adhanSoundFor(settings, arabic: _isArabic(l10n))
        : null,
    // An early reminder says that the prayer is near, in a short recording that ships with the app
    // (one for each of the five prayers), unless the reminders are silent.
    bundledSound:
        !silent &&
            lead > 0 &&
            !isSunrise &&
            settings.sound == NotificationSound.system
        ? BundledSound(
            resource: 'near_${prayer.name}',
            label: prayerName(l10n, prayer),
          )
        : null,
  );
}

/// The wake-up alarm before Fajr: the time left, and the time of Fajr. It plays its own recording
/// as an alarm, whatever the sound of the other reminders is, and quiet hours do not silence it.
NotificationContent wakeUpContent({
  required AppLocalizations l10n,
  required PlannedNotification notification,
  required ReminderSettings settings,
  required Digits digits,
  required bool use24Hour,
  required TimeZoneRules zone,
}) => NotificationContent(
  title: digits.localize(
    l10n.reminderSoon(settings.wakeUpMinutes, prayerName(l10n, Prayer.fajr)),
  ),
  body: formatClock(
    zone.wallClockAt(
      notification.fireAt.add(Duration(minutes: settings.wakeUpMinutes)),
    ),
    arabic: _isArabic(l10n),
    use24Hour: use24Hour,
    digits: digits,
  ),
  vibrate: settings.vibrate,
  bundledSound: BundledSound(
    resource: 'wake_fajr',
    label: l10n.wakeUpChannel,
    alarm: true,
  ),
);

/// The downloaded adhan chosen in [settings], named in the user's language, or null (system sound).
CustomSound? adhanSoundFor(ReminderSettings settings, {required bool arabic}) {
  final chosen = adhanById(settings.adhanId);
  if (chosen == null || settings.sound != NotificationSound.system) return null;
  return CustomSound(id: chosen.id, label: chosen.name(arabic));
}

/// The words of a salawat reminder: the owner-approved Arabic, in both interface languages. It plays
/// the recording chosen for salawat (one of two that ship with the app) unless the reminders are
/// silent or the phone's own sound is chosen.
NotificationContent salawatContent({
  required PlannedNotification notification,
  required ReminderSettings settings,
  required Digits digits,
  bool silent = false,
}) {
  final tone = settings.salawat.tone;
  return NotificationContent(
    title: notification.key == ReminderPlanBuilder.salawatSoonKey
        ? salawatSoonText(settings.salawat.leadMinutes, digits)
        : salawatNowText,
    sound: silent ? NotificationSound.silent : settings.sound,
    vibrate: !silent && settings.vibrate,
    bundledSound:
        !silent && tone != null && settings.sound == NotificationSound.system
        ? BundledSound(resource: tone, label: salawatToneLabel(tone))
        : null,
  );
}

/// The words for the platform's own notification settings.
ChannelLabels channelLabels(AppLocalizations l10n) => ChannelLabels(
  soundAndVibration: l10n.reminderChannelSoundVibrate,
  soundOnly: l10n.reminderChannelSound,
  vibrationOnly: l10n.reminderChannelVibrate,
  silent: l10n.reminderChannelSilent,
  description: l10n.reminderChannelDescription,
);

bool _isArabic(AppLocalizations l10n) => l10n.localeName.startsWith('ar');
