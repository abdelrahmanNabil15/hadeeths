import 'package:equatable/equatable.dart';
import 'package:mynewapp/features/prayer_times/domain/calculation_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/hijri_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/method_suggestion.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_location.dart';

/// Who decided the calculation method.
enum MethodOrigin {
  /// Nothing decided yet: the first-run default is showing and no place has been set.
  notSet,

  /// Proposed from the country of the first place the user set up, then kept.
  suggested,

  /// Chosen by the user.
  user,
}

/// Everything saved about prayer times: the place and how to calculate.
///
/// The method follows one rule: it is **proposed once**, from the country of the first place the
/// user sets, and from then on it never changes unless the user changes it. Moving to another
/// country or picking another city does not alter it.
class PrayerPreferences extends Equatable {
  PrayerPreferences({
    this.location,
    CalculationSettings? settings,
    this.methodOrigin = MethodOrigin.notSet,
    HijriSettings? hijri,
  }) : settings = settings ?? CalculationSettings(),
       hijri = hijri ?? HijriSettings();

  final PrayerLocation? location;
  final CalculationSettings settings;
  final MethodOrigin methodOrigin;

  /// Which Hijri reference to use and the manual day correction. Unlike the method it is never
  /// proposed by the app: it starts as Umm al-Qura with no correction and only the user changes it.
  final HijriSettings hijri;

  bool get isSetUp => location != null;

  /// Sets the place. The first time (method not yet decided) the method is proposed from the
  /// country: [countryCode] if given, else the place's own. Afterwards only the place changes.
  PrayerPreferences withLocation(PrayerLocation place, {String? countryCode}) {
    if (methodOrigin != MethodOrigin.notSet) {
      return PrayerPreferences(
        location: place,
        settings: settings,
        methodOrigin: methodOrigin,
        hijri: hijri,
      );
    }
    final suggestion = MethodSuggestion.forCountry(
      countryCode ?? place.countryCode,
    );
    return PrayerPreferences(
      location: place,
      settings: settings.copyWith(method: suggestion.method),
      methodOrigin: MethodOrigin.suggested,
      hijri: hijri,
    );
  }

  /// The user picked a method. From now on it is theirs.
  PrayerPreferences withMethod(CalculationMethodId method) => PrayerPreferences(
    location: location,
    settings: settings.copyWith(method: method),
    methodOrigin: MethodOrigin.user,
    hijri: hijri,
  );

  /// Any other calculation choice (Asr school, high-latitude rule, adjustments). Never touches
  /// the method.
  PrayerPreferences withSettings(CalculationSettings changed) =>
      PrayerPreferences(
        location: location,
        settings: changed.copyWith(method: settings.method),
        methodOrigin: methodOrigin,
        hijri: hijri,
      );

  /// The user changed the Hijri reference or the day correction.
  PrayerPreferences withHijri(HijriSettings changed) => PrayerPreferences(
    location: location,
    settings: settings,
    methodOrigin: methodOrigin,
    hijri: changed,
  );

  @override
  List<Object?> get props => [location, settings, methodOrigin, hijri];
}
