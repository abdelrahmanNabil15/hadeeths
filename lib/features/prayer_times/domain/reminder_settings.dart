import 'package:equatable/equatable.dart';
import 'package:mynewapp/core/notifications/notification_gateway.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';

/// What the user chose about prayer reminders. Off until the user switches it on.
class ReminderSettings extends Equatable {
  ReminderSettings({
    this.enabled = false,
    Set<Prayer>? prayers,
    this.leadMinutes = 0,
    this.sound = NotificationSound.system,
    this.vibrate = true,
    this.exactTiming = false,
  }) : prayers = Set.unmodifiable(prayers ?? defaultPrayers) {
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
  }) => ReminderSettings(
    enabled: enabled ?? this.enabled,
    prayers: prayers ?? this.prayers,
    leadMinutes: leadMinutes ?? this.leadMinutes,
    sound: sound ?? this.sound,
    vibrate: vibrate ?? this.vibrate,
    exactTiming: exactTiming ?? this.exactTiming,
  );

  @override
  List<Object?> get props => [
    enabled,
    [for (final p in Prayer.values) prayers.contains(p)],
    leadMinutes,
    sound,
    vibrate,
    exactTiming,
  ];
}
