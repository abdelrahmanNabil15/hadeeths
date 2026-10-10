import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// Whole seconds left, rounded up, so the display reaches zero exactly at the prayer time and
/// never shows zero while time remains. Never negative.
int secondsLeft(Duration remaining) => remaining <= Duration.zero
    ? 0
    : (remaining.inMilliseconds + Duration.millisecondsPerSecond - 1) ~/
          Duration.millisecondsPerSecond;

/// How long until the rounded-up value shown by [countdownClock] changes: the time to the next whole
/// second of [remaining] (a full second when it is exactly on one).
Duration untilNextTick(Duration remaining) {
  final rest = remaining.inMilliseconds % Duration.millisecondsPerSecond;
  return Duration(
    milliseconds: rest == 0 ? Duration.millisecondsPerSecond : rest,
  );
}

/// The countdown as a clock face, `H:MM:SS`, in the user's digits (`1:05:09`).
String countdownClock(Duration remaining, Digits digits) {
  final total = secondsLeft(remaining);
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = total % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return digits.localize('$hours:${two(minutes)}:${two(seconds)}');
}

/// The countdown in words, to the minute, for screen readers ("in 1 hour and 5 minutes"). It changes
/// once a minute, so a screen reader is never fed a new value every second.
String countdownSpoken(
  AppLocalizations l10n,
  Duration remaining,
  Digits digits,
) {
  final seconds = secondsLeft(remaining);
  if (seconds < 60) return l10n.countdownIn(l10n.durationUnderAMinute);
  final totalMinutes = (seconds + 59) ~/ 60;
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  final String duration;
  if (hours == 0) {
    duration = l10n.durationMinutes(minutes);
  } else if (minutes == 0) {
    duration = l10n.durationHours(hours);
  } else {
    duration = l10n.durationJoin(
      l10n.durationHours(hours),
      l10n.durationMinutes(minutes),
    );
  }
  return digits.localize(l10n.countdownIn(duration));
}
