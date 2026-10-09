import 'package:equatable/equatable.dart';
import 'package:mynewapp/features/prayer_times/domain/calculation_settings.dart';

/// The method the app proposes for a country the first time prayer times are set up.
///
/// It is the app's own convention over the five methods it offers, not a ruling: the method each
/// country's authority uses may differ in details, and a local mosque may follow another timetable.
/// The user is always told which method was chosen and can change it.
class MethodSuggestion extends Equatable {
  const MethodSuggestion({
    required this.method,
    required this.countryCode,
    required this.isCountrySpecific,
  });

  final CalculationMethodId method;

  /// ISO 3166-1 alpha-2 code the suggestion is based on, or null when the country is unknown.
  final String? countryCode;

  /// False when there is no method specific to the country among those offered and the general
  /// one (Muslim World League) was used. The screen should say so.
  final bool isCountrySpecific;

  /// Country to method. Countries not listed use the Muslim World League method.
  static const Map<String, CalculationMethodId> byCountry = {
    'EG': CalculationMethodId.egyptian,
    'SA': CalculationMethodId.ummAlQura,
    'PK': CalculationMethodId.karachi,
    'BD': CalculationMethodId.karachi,
    'IN': CalculationMethodId.karachi,
    'AF': CalculationMethodId.karachi,
    'US': CalculationMethodId.northAmerica,
    'CA': CalculationMethodId.northAmerica,
  };

  static const fallback = CalculationMethodId.muslimWorldLeague;

  factory MethodSuggestion.forCountry(String? countryCode) {
    final code = countryCode?.toUpperCase();
    final method = code == null ? null : byCountry[code];
    return MethodSuggestion(
      method: method ?? fallback,
      countryCode: code,
      isCountrySpecific: method != null,
    );
  }

  @override
  List<Object?> get props => [method, countryCode, isCountrySpecific];
}
