import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/features/prayer_times/domain/calculation_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_day.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_times_calculator.dart';

/// Calculates prayer times with the `adhan_dart` package (MIT). Pure computation: no network,
/// no permissions, no clock.
///
/// Rounding: times are rounded to the nearest minute, so what the screen shows is exactly what a
/// reminder fires at.
class AdhanPrayerTimesCalculator implements PrayerTimesCalculator {
  const AdhanPrayerTimesCalculator();

  static const _maxMeetingGap = Duration(minutes: 2);

  @override
  Result<PrayerDay> calculate({
    required GeoPoint location,
    required DateTime date,
    required CalculationSettings settings,
  }) {
    try {
      // The library reads only the year, month and day of the date. A UTC date keeps "the
      // next day" exactly one calendar day away, whatever the device's daylight-saving rules.
      final day = DateTime.utc(date.year, date.month, date.day);
      final parameters = parametersFor(settings);
      final coordinates = adhan.Coordinates(
        location.latitude,
        location.longitude,
      );
      adhan.PrayerTimes on(DateTime d) => adhan.PrayerTimes(
        date: d,
        coordinates: coordinates,
        calculationParameters: parameters,
      );
      final times = on(day);
      // The library also offers `ishaBefore` and `fajrAfter`, but in version 2.0.1 they come
      // from the wrong day whenever the high-latitude rule applies (found by comparing with an
      // independent implementation). So the neighbouring days are calculated in full instead.
      final previous = on(day.subtract(const Duration(days: 1)));
      final next = on(day.add(const Duration(days: 1)));
      // With the "middle of the night" rule Isha and the next Fajr meet at the same moment and,
      // because each night is a slightly different length, can miss each other by a minute. The
      // neighbouring-day values are nudged by that rounding-sized amount (never more) so the two
      // meet exactly. The times shown for each day itself are never touched.
      var previousIsha = previous.isha;
      if (previousIsha.isAfter(times.fajr) &&
          previousIsha.difference(times.fajr) <= _maxMeetingGap) {
        previousIsha = times.fajr;
      }
      var nextFajr = next.fajr;
      if (nextFajr.isBefore(times.isha) &&
          times.isha.difference(nextFajr) <= _maxMeetingGap) {
        nextFajr = times.isha;
      }
      final result = PrayerDay(
        date: day,
        times: {
          Prayer.fajr: times.fajr,
          Prayer.sunrise: times.sunrise,
          Prayer.dhuhr: times.dhuhr,
          Prayer.asr: times.asr,
          Prayer.maghrib: times.maghrib,
          Prayer.isha: times.isha,
        },
        previousIsha: previousIsha,
        nextFajr: nextFajr,
      );
      if (!result.isConsistent) {
        return const Err(
          Failure(
            FailureKind.unexpected,
            debugMessage: 'calculated times are not in a sensible order',
          ),
        );
      }
      return Success(result);
    } catch (error) {
      return Err(Failure(FailureKind.unexpected, debugMessage: '$error'));
    }
  }

  /// The library's parameters for [settings]. Public so tests can compare them with
  /// [methodInfo], the numbers shown to the user.
  static adhan.CalculationParameters parametersFor(
    CalculationSettings settings,
  ) {
    final parameters = switch (settings.method) {
      CalculationMethodId.egyptian =>
        adhan.CalculationMethodParameters.egyptian(),
      CalculationMethodId.ummAlQura =>
        adhan.CalculationMethodParameters.ummAlQura(),
      CalculationMethodId.muslimWorldLeague =>
        adhan.CalculationMethodParameters.muslimWorldLeague(),
      CalculationMethodId.karachi =>
        adhan.CalculationMethodParameters.karachi(),
      CalculationMethodId.northAmerica =>
        adhan.CalculationMethodParameters.northAmerica(),
    };
    parameters.madhab = switch (settings.madhab) {
      Madhab.shafii => adhan.Madhab.shafi,
      Madhab.hanafi => adhan.Madhab.hanafi,
    };
    parameters.highLatitudeRule = switch (settings.highLatitudeRule) {
      HighLatitudeRule.middleOfTheNight =>
        adhan.HighLatitudeRule.middleOfTheNight,
      HighLatitudeRule.seventhOfTheNight =>
        adhan.HighLatitudeRule.seventhOfTheNight,
      HighLatitudeRule.twilightAngle => adhan.HighLatitudeRule.twilightAngle,
    };
    parameters.adjustments = {
      adhan.Prayer.fajr: settings.adjustmentFor(Prayer.fajr),
      adhan.Prayer.sunrise: settings.adjustmentFor(Prayer.sunrise),
      adhan.Prayer.dhuhr: settings.adjustmentFor(Prayer.dhuhr),
      adhan.Prayer.asr: settings.adjustmentFor(Prayer.asr),
      adhan.Prayer.maghrib: settings.adjustmentFor(Prayer.maghrib),
      adhan.Prayer.isha: settings.adjustmentFor(Prayer.isha),
    };
    return parameters;
  }
}
