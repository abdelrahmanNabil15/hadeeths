import 'package:mynewapp/core/permissions/permission_flow.dart';
import 'package:mynewapp/core/time/clock.dart';
import 'package:mynewapp/features/prayer_times/domain/city.dart';
import 'package:mynewapp/features/prayer_times/domain/compass_source.dart';
import 'package:mynewapp/features/prayer_times/domain/country_lookup.dart';
import 'package:mynewapp/features/prayer_times/domain/hijri_converter.dart';
import 'package:mynewapp/features/prayer_times/domain/location_service.dart';
import 'package:mynewapp/features/prayer_times/domain/location_setup.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences_repository.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_times_calculator.dart';
import 'package:mynewapp/features/prayer_times/domain/reminder_service.dart';
import 'package:mynewapp/features/prayer_times/domain/world_magnetic_model.dart';

/// Everything the prayer screens need, built once by the app and handed to them. Tests give
/// fakes. The two data sets are loaded on first use, because most launches never need them.
class PrayerServices {
  PrayerServices({
    required this.preferences,
    required this.calculator,
    required this.hijri,
    required this.permissions,
    required this.location,
    required this.loadCities,
    required this.loadCountries,
    required this.compass,
    required this.loadMagneticModel,
    required this.reminders,
    this.clock = const SystemClock(),
  }) : locationSetup = LocationSetup(permissions, location);

  final PrayerPreferencesRepository preferences;
  final PrayerTimesCalculator calculator;
  final HijriConverter hijri;
  final PermissionFlow permissions;
  final LocationService location;
  final LocationSetup locationSetup;
  final Clock clock;

  final Future<CityCatalog> Function() loadCities;
  final Future<CountryLookup> Function() loadCountries;

  /// The motion sensors, for the live compass (only listened to while the compass is on).
  final CompassSource compass;

  /// The World Magnetic Model, read on first use.
  final Future<WorldMagneticModel> Function() loadMagneticModel;

  /// Keeps the system's prayer reminders in line with everything saved.
  final ReminderService reminders;
}
