import 'package:mynewapp/features/prayer_times/domain/hijri_date.dart';
import 'package:mynewapp/features/prayer_times/domain/hijri_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_day.dart';

/// Converts a calendar date to the Hijri calendar, offline.
abstract interface class HijriConverter {
  /// [gregorian] is a calendar date (only year, month and day are used). Returns null when the
  /// chosen reference does not cover that date; never a guess.
  HijriDate? convert(DateTime gregorian, HijriSettings settings);
}

/// The Hijri date to show at [now] for a place whose day is [day].
///
/// The Hijri day begins at sunset, so from Maghrib the date shown is the next one. Before Maghrib
/// it is the date of the calendar day at the place.
HijriDate? hijriDateAt({
  required HijriConverter converter,
  required HijriSettings settings,
  required PrayerDay day,
  required DateTime now,
}) {
  final afterSunset = !now.toUtc().isBefore(day[Prayer.maghrib]);
  final date = afterSunset ? day.date.add(const Duration(days: 1)) : day.date;
  return converter.convert(date, settings);
}
