import 'dart:ui';

import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/notifications/notification_gateway.dart';
import 'package:mynewapp/core/notifications/notification_planner.dart';
import 'package:mynewapp/core/notifications/notification_sync.dart';
import 'package:mynewapp/core/notifications/planned_notification.dart';
import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/core/time/clock.dart';
import 'package:mynewapp/core/time/zone.dart';
import 'package:mynewapp/features/prayer_times/domain/place_zone.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_day.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences_repository.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_times_calculator.dart';
import 'package:mynewapp/features/prayer_times/domain/reminder_plan_builder.dart';
import 'package:mynewapp/features/prayer_times/domain/reminder_service.dart';
import 'package:mynewapp/features/prayer_times/presentation/reminder_content.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// What the device says about language and clock style, read when reminders are rebuilt.
class ReminderEnvironment {
  const ReminderEnvironment({
    required this.deviceLanguageCode,
    required this.use24Hour,
  });

  /// The phone's own language code, used when the app follows the device language.
  final String deviceLanguageCode;
  final bool use24Hour;

  /// The live values from the platform.
  factory ReminderEnvironment.current() => ReminderEnvironment(
    deviceLanguageCode: PlatformDispatcher.instance.locale.languageCode,
    use24Hour: PlatformDispatcher.instance.alwaysUse24HourFormat,
  );
}

/// The one place that keeps the system's prayer reminders in line with the saved place, method and
/// reminder choices (the single scheduling path required by the plan).
///
/// It reads everything from storage each time instead of trusting what the screens hold, so it is
/// correct after a restart, a language change or a move to another place, and calling it twice in
/// a row changes nothing the second time.
class ReminderCoordinator implements ReminderService {
  ReminderCoordinator({
    required this._preferences,
    required this._calculator,
    required this._gateway,
    required this._loadAppSettings,
    ReminderEnvironment Function()? environment,
    this._clock = const SystemClock(),
    this._deviceZone = const DeviceTimeZone(),
  }) : _sync = NotificationSync(_gateway),
       _environment = environment ?? ReminderEnvironment.current;

  final PrayerPreferencesRepository _preferences;
  final PrayerTimesCalculator _calculator;
  final NotificationGateway _gateway;
  final NotificationSync _sync;
  final Future<AppSettings> Function() _loadAppSettings;
  final ReminderEnvironment Function() _environment;
  final Clock _clock;

  /// The phone's own zone: salawat times and quiet hours follow it.
  final TimeZoneRules _deviceZone;

  /// Two runs at once would race on the platform's list; the second waits for the first.
  Future<ReminderStatus>? _running;

  static const _testId = 1;

  @override
  Future<ReminderStatus> reconcile() {
    final previous = _running ?? Future.value(const ReminderStatus());
    final next = previous.then((_) => _run());
    _running = next;
    return next;
  }

  Future<ReminderStatus> _run() async {
    try {
      final prefs = await _preferences.load();
      final app = await _loadAppSettings();
      final env = _environment();
      final language = languageFor(app, env);
      final l10n = lookupAppLocalizations(Locale(language));
      await _gateway.prepare(channelLabels(l10n));

      final settings = prefs.reminders;
      final place = prefs.location;
      final prayersOn = settings.enabled && settings.active.isNotEmpty;
      final salawatOn = settings.salawat.enabled;
      if (!prayersOn && !salawatOn) {
        await _sync.cancelAll();
        return status();
      }
      // Salawat needs no place (it follows the phone's clock), so a missing place only stops prayer
      // reminders.
      if (prayersOn && place == null && !salawatOn) {
        await _sync.cancelAll();
        return const ReminderStatus(needsPlace: true);
      }
      if (!await _gateway.notificationsAllowed()) {
        await _sync.cancelAll();
        return const ReminderStatus(notificationsAllowed: false);
      }

      final now = _clock.now();
      final digits = Digits(
        arabicIndic: switch (app.digits) {
          DigitStyle.automatic => language == 'ar',
          DigitStyle.arabicIndic => true,
          DigitStyle.western => false,
        },
      );
      final quiet = settings.quietHours;
      final candidates = <NotificationCandidate>[];
      TimeZoneRules? placeZone;
      if (prayersOn && place != null) {
        final zone = zoneForPlace(place);
        placeZone = zone;
        final today = zone.localDateAt(now);
        final days = <PrayerDay>[];
        for (var i = 0; i <= ReminderPlanBuilder.horizon.inDays; i++) {
          final result = _calculator.calculate(
            location: place.point,
            date: today.add(Duration(days: i)),
            settings: prefs.settings,
          );
          if (result is Success<PrayerDay>) days.add(result.value);
        }
        final signature = [
          language,
          settings.leadMinutes,
          settings.sound.name,
          settings.vibrate,
          digits.arabicIndic,
          env.use24Hour,
          settings.exactTiming,
          // Whether a reminder is delivered silently depends on these.
          settings.quietForPrayers && quiet != null
              ? '${quiet.startMinute}-${quiet.endMinute}'
              : '-',
          // Not the zone name itself: this text is stored with the notification, and the name hints
          // at the country.
          fnv1a31(zone.id).toRadixString(16),
        ].join('|');
        candidates.addAll(
          ReminderPlanBuilder.candidates(
            days: days,
            settings: settings,
            contentSignature: signature,
          ),
        );
      }
      if (salawatOn) {
        candidates.addAll(
          ReminderPlanBuilder.salawatCandidates(
            settings: settings.salawat,
            zone: _deviceZone,
            now: now,
            signature: [
              settings.salawat.leadMinutes,
              settings.sound.name,
              settings.vibrate,
              digits.arabicIndic,
              settings.exactTiming,
            ].join('|'),
          ),
        );
      }
      final contentZone = placeZone ?? _deviceZone;
      final plan = NotificationPlanner(
        zone: contentZone,
        quietHours: quiet,
        // Quiet hours follow the phone's own clock, wherever the prayer place is (decision D2).
        quietZone: _deviceZone,
        maxPending: 60,
        horizon: ReminderPlanBuilder.horizon,
      ).plan(candidates, now: now);
      bool inQuietHours(DateTime at) =>
          quiet?.contains(_deviceZone.minuteOfDayAt(at)) ?? false;
      final report = await _sync.apply(
        plan,
        contentFor: (n) => reminderContent(
          l10n: l10n,
          notification: n,
          settings: settings,
          digits: digits,
          use24Hour: env.use24Hour,
          zone: contentZone,
          silent:
              n.kind == NotificationKind.prayer &&
              settings.quietForPrayers &&
              inQuietHours(n.fireAt),
        ),
        exact: settings.exactTiming,
      );
      final current = await status();
      return ReminderStatus(
        scheduled: current.scheduled,
        next: current.next,
        scheduledPrayers: current.scheduledPrayers,
        nextPrayer: current.nextPrayer,
        notificationsAllowed: true,
        failed: report.failed,
        exactDenied: current.exactDenied,
        needsPlace: prayersOn && place == null,
        heldBackByQuietHours: plan.dropped
            .where((d) => d.reason == DropReason.quietHours)
            .length,
      );
    } on Object {
      return const ReminderStatus(failed: 1);
    }
  }

  @override
  Future<ReminderStatus> status() async {
    try {
      final ours = <PlannedNotification>[
        for (final entry in await _gateway.pending())
          ?NotificationPayload.decode(entry),
      ]..sort((a, b) => a.fireAt.compareTo(b.fireAt));
      final settings = (await _preferences.load()).reminders;
      final prayers = [
        for (final n in ours)
          if (n.kind == NotificationKind.prayer) n,
      ];
      return ReminderStatus(
        scheduled: ours.length,
        next: ours.isEmpty ? null : ours.first,
        scheduledPrayers: prayers.length,
        nextPrayer: prayers.isEmpty ? null : prayers.first,
        notificationsAllowed: await _gateway.notificationsAllowed(),
        exactDenied:
            settings.enabled &&
            settings.exactTiming &&
            !await _gateway.exactAlarmsAllowed(),
      );
    } on Object {
      return const ReminderStatus(failed: 1);
    }
  }

  @override
  Future<void> sendTest() async {
    final prefs = await _preferences.load();
    final app = await _loadAppSettings();
    final l10n = lookupAppLocalizations(
      Locale(languageFor(app, _environment())),
    );
    await _gateway.prepare(channelLabels(l10n));
    await _gateway.showNow(
      id: _testId,
      content: NotificationContent(
        title: l10n.reminderTestTitle,
        body: l10n.reminderTestBody,
        sound: prefs.reminders.sound,
        vibrate: prefs.reminders.vibrate,
      ),
    );
  }

  @override
  Future<void> cancelAll() async {
    await _sync.cancelAll();
  }

  /// The app's language: the user's choice, else the device's if Arabic or English, else Arabic.
  static String languageFor(AppSettings app, ReminderEnvironment env) =>
      app.language.code ?? (env.deviceLanguageCode == 'en' ? 'en' : 'ar');

  /// The numerals the user sees: their choice, else Arabic-Indic for Arabic.
  static Digits digitsFor(AppSettings app, String language) => Digits(
    arabicIndic: switch (app.digits) {
      DigitStyle.automatic => language == 'ar',
      DigitStyle.arabicIndic => true,
      DigitStyle.western => false,
    },
  );
}
