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
  }) {
    if (!intervalOptions.contains(intervalMinutes)) {
      throw ArgumentError.value(intervalMinutes, 'intervalMinutes');
    }
    if (!leadOptions.contains(leadMinutes)) {
      throw ArgumentError.value(leadMinutes, 'leadMinutes');
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

  final bool enabled;
  final int intervalMinutes;

  /// The window, in minutes after local midnight; the first reminder is at the start.
  final int windowStartMinute;
  final int windowEndMinute;
  final int leadMinutes;

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
  }) => SalawatSettings(
    enabled: enabled ?? this.enabled,
    intervalMinutes: intervalMinutes ?? this.intervalMinutes,
    windowStartMinute: windowStartMinute ?? this.windowStartMinute,
    windowEndMinute: windowEndMinute ?? this.windowEndMinute,
    leadMinutes: leadMinutes ?? this.leadMinutes,
  );

  @override
  List<Object?> get props => [
    enabled,
    intervalMinutes,
    windowStartMinute,
    windowEndMinute,
    leadMinutes,
  ];
}
