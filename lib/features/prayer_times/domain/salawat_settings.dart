import 'package:equatable/equatable.dart';

/// Reminders to send salawat on the Prophet ﷺ: at a fixed interval inside a daily window, on the
/// phone's own clock. Off until the user switches them on.
class SalawatSettings extends Equatable {
  SalawatSettings({
    this.enabled = false,
    this.intervalMinutes = 120,
    this.windowStartMinute = 9 * 60,
    this.windowEndMinute = 21 * 60,
    this.leadMinutes = 0,
    this.tone = defaultTone,
  }) {
    if (!intervalOptions.contains(intervalMinutes)) {
      throw ArgumentError.value(intervalMinutes, 'intervalMinutes');
    }
    if (!leadOptions.contains(leadMinutes)) {
      throw ArgumentError.value(leadMinutes, 'leadMinutes');
    }
    if (tone != null && !toneOptions.contains(tone)) {
      throw ArgumentError.value(tone, 'tone');
    }
    if (windowStartMinute < 0 ||
        windowEndMinute >= 1440 ||
        windowEndMinute <= windowStartMinute) {
      throw ArgumentError(
        'the window must start before it ends, within one day '
        '($windowStartMinute to $windowEndMinute)',
      );
    }
  }

  /// Every 1, 2, 3, 4 or 6 hours.
  static const intervalOptions = [60, 120, 180, 240, 360];

  /// An optional reminder this many minutes before (0 means none).
  static const leadOptions = [0, 5, 10, 15];

  /// The recordings that ship with the app (`salawat_1` and `salawat_2`, in the Android raw resources).
  static const toneOptions = ['salawat_1', 'salawat_2'];
  static const defaultTone = 'salawat_1';

  final bool enabled;
  final int intervalMinutes;

  /// The window, in minutes after local midnight; the first reminder is at the start.
  final int windowStartMinute;
  final int windowEndMinute;
  final int leadMinutes;

  /// The recording a reminder plays, or null for the phone's own notification sound. A silent
  /// reminder setting wins over it.
  final String? tone;

  /// The reminder times of a day, in minutes after local midnight: the start, then every interval up
  /// to and including the end.
  List<int> get minutesOfDay => [
    for (var m = windowStartMinute; m <= windowEndMinute; m += intervalMinutes)
      m,
  ];

  SalawatSettings copyWith({
    bool? enabled,
    int? intervalMinutes,
    int? windowStartMinute,
    int? windowEndMinute,
    int? leadMinutes,
    String? tone,
    bool clearTone = false,
  }) => SalawatSettings(
    enabled: enabled ?? this.enabled,
    intervalMinutes: intervalMinutes ?? this.intervalMinutes,
    windowStartMinute: windowStartMinute ?? this.windowStartMinute,
    windowEndMinute: windowEndMinute ?? this.windowEndMinute,
    leadMinutes: leadMinutes ?? this.leadMinutes,
    tone: clearTone ? null : tone ?? this.tone,
  );

  @override
  List<Object?> get props => [
    enabled,
    intervalMinutes,
    windowStartMinute,
    windowEndMinute,
    leadMinutes,
    tone,
  ];
}
