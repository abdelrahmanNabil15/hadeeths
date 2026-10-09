import 'package:mynewapp/core/format/digits.dart';

/// Writes a time of day for the screen.
///
/// [wallClock] carries the local hour and minute (a UTC-flagged `DateTime` whose fields are the
/// local ones; see `ZoneConversions` in `core/time/zone.dart`). The 12-hour form uses ص and م in
/// Arabic and AM and PM in English; the 24-hour form is `HH:mm`. Digits follow the user's
/// numeral setting.
String formatClock(
  DateTime wallClock, {
  required bool arabic,
  required bool use24Hour,
  required Digits digits,
}) {
  final minute = wallClock.minute.toString().padLeft(2, '0');
  if (use24Hour) {
    final hour = wallClock.hour.toString().padLeft(2, '0');
    return digits.localize('$hour:$minute');
  }
  final hour12 = wallClock.hour % 12 == 0 ? 12 : wallClock.hour % 12;
  final isMorning = wallClock.hour < 12;
  final suffix = arabic ? (isMorning ? 'ص' : 'م') : (isMorning ? 'AM' : 'PM');
  return '${digits.localize('$hour12:$minute')} $suffix';
}
