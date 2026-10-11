import 'package:equatable/equatable.dart';
import 'package:mynewapp/core/notifications/notification_gateway.dart';
import 'package:mynewapp/core/notifications/quiet_hours.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/prayer_times/domain/salawat_settings.dart';

/// What the user chose about reminders: prayer times, salawat and quiet hours. Each is off until the
/// user switches it on.
class ReminderSettings extends Equatable {
  ReminderSettings({
    this.enabled = false,
    Set<Prayer>? prayers,
    this.leadMinutes = 0,
    this.sound = NotificationSound.system,
    this.adhanId,
    this.vibrate = true,
    this.exactTiming = false,
    this.wakeUp = false,
    this.wakeUpMinutes = 30,
    this.quietEnabled = false,
    this.quietStartMinute = 22 * 60,
    this.quietEndMinute = 6 * 60,
    this.quietForPrayers = false,
    SalawatSettings? salawat,
  }) : prayers = Set.unmodifiable(prayers ?? defaultPrayers),
       salawat = salawat ?? SalawatSettings() {
    for (final m in [quietStartMinute, quietEndMinute]) {
      if (m < 0 || m >= 1440) throw ArgumentError.value(m, 'quiet hours');
    }
    if (!wakeUpOptions.contains(wakeUpMinutes)) {
      throw ArgumentError.value(
        wakeUpMinutes,
        'wakeUpMinutes',
        'must be one of $wakeUpOptions',
      );
    }
    if (!leadOptions.contains(leadMinutes)) {
      throw ArgumentError.value(
        leadMinutes,
        'leadMinutes',
        'must be one of $leadOptions',
      );
    }
  }

  /// Minutes before the prayer time that a reminder can be set for (0 means at the time).
  static const leadOptions = [0, 5, 10, 15, 30];

  /// Minutes before Fajr that the wake-up alarm can be set for.
  static const wakeUpOptions = [15, 30, 45, 60];

  /// The five prayers. Sunrise can be added by the user; it is not a prayer.
  static const defaultPrayers = {
    Prayer.fajr,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  };

  /// The master switch. When off, nothing is scheduled.
  final bool enabled;

  /// Which times get a reminder.
  final Set<Prayer> prayers;

  final int leadMinutes;
  final NotificationSound sound;

  /// A downloaded adhan recording to play, instead of the system sound, for the reminders that arrive
  /// at a prayer time. Null means the system sound. Ignored when [sound] is silent.
  final String? adhanId;
  final bool vibrate;

  /// Android only: deliver each reminder on the minute, which needs the user to allow "Alarms &
  /// reminders" for the app. Off by default, because without it the system may deliver a reminder
  /// late (by up to an hour in the worst case).
  final bool exactTiming;

  /// The wake-up alarm before Fajr: a recording that plays [wakeUpMinutes] before Fajr, for a person
  /// who wants to be awake before the adhan. Off until the user switches it on. It is its own choice:
  /// it plays even when the reminders are silent or in quiet hours, because that is its purpose.
  final bool wakeUp;
  final int wakeUpMinutes;

  /// Quiet hours: a daily period, on the phone's own clock, in which optional reminders (salawat)
  /// are not sent. It may cross midnight. The times are kept while it is off.
  final bool quietEnabled;
  final int quietStartMinute;
  final int quietEndMinute;

  /// Owner rule: prayer reminders are never dropped or moved by quiet hours. With this on, a
  /// prayer reminder that falls in quiet hours is still delivered, but silently.
  final bool quietForPrayers;

  final SalawatSettings salawat;

  /// The quiet period in force, or null when quiet hours are off (or start equals end).
  QuietHours? get quietHours {
    if (!quietEnabled) return null;
    final hours = QuietHours(
      startMinute: quietStartMinute,
      endMinute: quietEndMinute,
    );
    return hours.isEmpty ? null : hours;
  }

  /// The times to remind about, in their daily order, or none when reminders are off.
  List<Prayer> get active => enabled
      ? [
          for (final p in Prayer.values)
            if (prayers.contains(p)) p,
        ]
      : const [];

  ReminderSettings copyWith({
    bool? enabled,
    Set<Prayer>? prayers,
    int? leadMinutes,
    NotificationSound? sound,
    String? adhanId,
    bool clearAdhan = false,
    bool? vibrate,
    bool? exactTiming,
    bool? wakeUp,
    int? wakeUpMinutes,
    bool? quietEnabled,
    int? quietStartMinute,
    int? quietEndMinute,
    bool? quietForPrayers,
    SalawatSettings? salawat,
  }) => ReminderSettings(
    enabled: enabled ?? this.enabled,
    prayers: prayers ?? this.prayers,
    leadMinutes: leadMinutes ?? this.leadMinutes,
    sound: sound ?? this.sound,
    adhanId: clearAdhan ? null : (adhanId ?? this.adhanId),
    vibrate: vibrate ?? this.vibrate,
    exactTiming: exactTiming ?? this.exactTiming,
    wakeUp: wakeUp ?? this.wakeUp,
    wakeUpMinutes: wakeUpMinutes ?? this.wakeUpMinutes,
    quietEnabled: quietEnabled ?? this.quietEnabled,
    quietStartMinute: quietStartMinute ?? this.quietStartMinute,
    quietEndMinute: quietEndMinute ?? this.quietEndMinute,
    quietForPrayers: quietForPrayers ?? this.quietForPrayers,
    salawat: salawat ?? this.salawat,
  );

  @override
  List<Object?> get props => [
    enabled,
    [for (final p in Prayer.values) prayers.contains(p)],
    leadMinutes,
    sound,
    adhanId,
    vibrate,
    exactTiming,
    wakeUp,
    wakeUpMinutes,
    quietEnabled,
    quietStartMinute,
    quietEndMinute,
    quietForPrayers,
    salawat,
  ];
}
