import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/features/prayer_times/domain/calculation_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_day.dart';

/// Calculates prayer times on the device. Never needs the network.
abstract interface class PrayerTimesCalculator {
  /// [date] is the local calendar date at [location]: only its year, month and day are used.
  /// Returns an `Err` when the times cannot be calculated sensibly (for example inside the
  /// polar circle), never made-up numbers.
  Result<PrayerDay> calculate({
    required GeoPoint location,
    required DateTime date,
    required CalculationSettings settings,
  });
}
