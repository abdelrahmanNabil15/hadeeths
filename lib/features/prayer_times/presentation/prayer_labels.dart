import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/features/prayer_times/domain/calculation_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/location_setup.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// User-facing words for the prayer feature. Kept in one place so every screen says the same
/// thing.
String prayerName(AppLocalizations l10n, Prayer prayer) => switch (prayer) {
  Prayer.fajr => l10n.prayerFajr,
  Prayer.sunrise => l10n.prayerSunrise,
  Prayer.dhuhr => l10n.prayerDhuhr,
  Prayer.asr => l10n.prayerAsr,
  Prayer.maghrib => l10n.prayerMaghrib,
  Prayer.isha => l10n.prayerIsha,
};

String methodName(AppLocalizations l10n, CalculationMethodId id) =>
    switch (id) {
      CalculationMethodId.egyptian => l10n.methodEgyptian,
      CalculationMethodId.ummAlQura => l10n.methodUmmAlQura,
      CalculationMethodId.muslimWorldLeague => l10n.methodMuslimWorldLeague,
      CalculationMethodId.karachi => l10n.methodKarachi,
      CalculationMethodId.northAmerica => l10n.methodNorthAmerica,
    };

/// The numbers behind a method (angles or interval), so the user can see exactly what is used.
String methodDetail(
  AppLocalizations l10n,
  Digits digits,
  CalculationMethodId id,
) {
  final info = methodInfo[id]!;
  final fajr = _number(digits, info.fajrAngle);
  final interval = info.ishaIntervalMinutes;
  if (interval != null) {
    return l10n.methodInterval(fajr, digits.format(interval));
  }
  return l10n.methodAngles(fajr, _number(digits, info.ishaAngle!));
}

/// 19.5 stays "19.5" (or "١٩٫٥"), 18.0 becomes "18".
String _number(Digits digits, double value) {
  final text = value == value.roundToDouble()
      ? value.round().toString()
      : value.toString();
  final localized = digits.localize(text);
  return digits.arabicIndic ? localized.replaceAll('.', '٫') : localized;
}

/// The message for a "use my location" attempt that did not give a place; null when there is
/// nothing to say (it worked, or the user simply closed the explanation).
String? locationProblemMessage(
  AppLocalizations l10n,
  LocationSetupStatus status,
) => switch (status) {
  LocationSetupStatus.found => null,
  LocationSetupStatus.declinedExplanation => null,
  LocationSetupStatus.denied => l10n.locationDenied,
  LocationSetupStatus.needsSettings => l10n.locationNeedsSettings,
  LocationSetupStatus.permissionUnavailable => l10n.locationUnavailable,
  LocationSetupStatus.serviceDisabled => l10n.locationServiceDisabled,
  LocationSetupStatus.timeout => l10n.locationTimeout,
  LocationSetupStatus.unavailable => l10n.locationUnavailable,
};
