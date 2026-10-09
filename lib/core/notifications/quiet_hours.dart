import 'package:equatable/equatable.dart';

/// A daily period, in local minutes since midnight, during which optional reminders
/// must not fire. It may cross midnight (for example 22:00 to 07:00).
///
/// The start is inclusive and the end exclusive. When start equals end the period is
/// empty (no quiet time), never "all day".
class QuietHours extends Equatable {
  const QuietHours({required this.startMinute, required this.endMinute})
    : assert(startMinute >= 0 && startMinute < 1440),
      assert(endMinute >= 0 && endMinute < 1440);

  final int startMinute;
  final int endMinute;

  bool get isEmpty => startMinute == endMinute;

  bool get crossesMidnight => startMinute > endMinute;

  /// Whether [minuteOfDay] (0 to 1439, local) falls inside the quiet period.
  bool contains(int minuteOfDay) {
    if (isEmpty) return false;
    return crossesMidnight
        ? minuteOfDay >= startMinute || minuteOfDay < endMinute
        : minuteOfDay >= startMinute && minuteOfDay < endMinute;
  }

  @override
  List<Object?> get props => [startMinute, endMinute];
}
