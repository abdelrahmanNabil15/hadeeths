import 'package:mynewapp/core/format/clock_format.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/core/time/zone.dart';
import 'package:mynewapp/features/prayer_times/domain/place_zone.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_day.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_times_calculator.dart';
import 'package:mynewapp/features/prayer_times/presentation/prayer_labels.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// First line of every snapshot; the widget ignores anything else.
const widgetSnapshotHeader = 'hadeeths-widget 1';

/// How many days of times the widget gets: it stays right this long without the app being opened.
const widgetSnapshotDays = 7;

/// What the Android widget shows, as plain lines (the Kotlin side has no locale logic and no JSON):
///
/// ```text
/// hadeeths-widget 1
/// <heading, for example "Next prayer">
/// <label before the following one, for example "Then">
/// <UTC milliseconds>\t<name>\t<time as shown in the app>   (one line per time, oldest first)
/// ```
///
/// Names and times are in the app's language, digits and clock style. No place name and no
/// coordinates: a home screen can be seen by others. Null when no place is set.
String? buildWidgetSnapshot({
  required PrayerPreferences preferences,
  required PrayerTimesCalculator calculator,
  required AppLocalizations l10n,
  required Digits digits,
  required bool use24Hour,
  required DateTime now,
}) {
  final place = preferences.location;
  if (place == null) return null;
  final zone = zoneForPlace(place);
  final today = zone.localDateAt(now);
  final arabic = l10n.localeName.startsWith('ar');
  String clean(String s) => s.replaceAll(RegExp(r'[\t\r\n]'), ' ');
  final lines = <String>[
    widgetSnapshotHeader,
    clean(l10n.nextPrayerLabel),
    clean(l10n.widgetThen),
  ];
  for (var i = 0; i < widgetSnapshotDays; i++) {
    final result = calculator.calculate(
      location: place.point,
      date: today.add(Duration(days: i)),
      settings: preferences.settings,
    );
    if (result is! Success<PrayerDay>) continue;
    final day = result.value;
    for (final prayer in Prayer.values) {
      final at = day[prayer];
      final time = formatClock(
        zone.wallClockAt(at),
        arabic: arabic,
        use24Hour: use24Hour,
        digits: digits,
      );
      lines.add(
        '${at.millisecondsSinceEpoch}\t${clean(prayerName(l10n, prayer))}\t${clean(time)}',
      );
    }
  }
  return lines.join('\n');
}
