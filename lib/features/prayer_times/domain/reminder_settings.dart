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
    this.vibrate = true,
    this.exactTiming = false,
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
  final bool vibrate;

  /// Android only: deliver each reminder on the minute, which needs the user to allow "Alarms &
  /// reminders" for the app. Off by default, because without it the system may deliver a reminder
  /// late (by up to an hour in the worst case).
  final bool exactTiming;

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
    bool? vibrate,
    bool? exactTiming,
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
    vibrate: vibrate ?? this.vibrate,
    exactTiming: exactTiming ?? this.exactTiming,
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
    vibrate,
    exactTiming,
    quietEnabled,
    quietStartMinute,
    quietEndMinute,
    quietForPrayers,
    salawat,
  ];
}
