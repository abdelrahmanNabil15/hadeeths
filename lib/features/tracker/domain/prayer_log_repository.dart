import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/tracker/domain/day_key.dart';

/// Which of the five prayers the user has marked as prayed, per day. Only that: no times, no
/// place, nothing about missed prayers. It is stored on the device and never sent anywhere.
abstract interface class PrayerLogRepository {
  /// What is marked on each day from [from] to [to], both included. Days with nothing marked
  /// are absent from the result.
  Future<Map<DayKey, Set<Prayer>>> between(DayKey from, DayKey to);

  /// Marks or unmarks [prayer] on [day]. Doing it twice has the same effect as once.
  /// Sunrise is not a prayer and is refused with an [ArgumentError].
  Future<void> setDone(DayKey day, Prayer prayer, {required bool done});

  /// Removes everything recorded.
  Future<void> deleteAll();
}
