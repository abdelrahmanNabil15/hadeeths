import 'dart:convert';
import 'dart:io';

import 'package:mynewapp/core/permissions/permission_flow.dart';
import 'package:mynewapp/core/permissions/permission_gateway.dart';
import 'package:mynewapp/features/prayer_times/data/adhan_prayer_times_calculator.dart';
import 'package:mynewapp/features/prayer_times/data/hijri_core_converter.dart';
import 'package:mynewapp/features/prayer_times/domain/city.dart';
import 'package:mynewapp/features/prayer_times/domain/country_lookup.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/location_service.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences_repository.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_services.dart';

import 'fake_permissions.dart';
import 'time_support.dart';

/// Preferences kept in memory; counts saves and can be told to fail.
class InMemoryPrayerPreferences implements PrayerPreferencesRepository {
  InMemoryPrayerPreferences([PrayerPreferences? initial])
    : stored = initial ?? PrayerPreferences();

  PrayerPreferences stored;
  int saves = 0;
  bool failSaving = false;
  bool cleared = false;

  @override
  Future<PrayerPreferences> load() async => stored;

  @override
  Future<void> save(PrayerPreferences preferences) async {
    if (failSaving) throw StateError('disk full');
    saves++;
    stored = preferences;
  }

  @override
  Future<void> clear() async {
    cleared = true;
    stored = PrayerPreferences();
  }
}

/// A device position the test decides.
class FakeLocationService implements LocationService {
  FakeLocationService([LocationResult? result])
    : result = result ?? LocationFound(GeoPoint(30.0444, 31.2357));

  LocationResult result;
  int reads = 0;
  int locationSettingsOpened = 0;

  @override
  Future<LocationResult> currentPosition() async {
    reads++;
    return result;
  }

  @override
  Future<bool> openLocationSettings() async {
    locationSettingsOpened++;
    return true;
  }
}

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

CityCatalog realCityCatalog() =>
    CityCatalog.fromJson(_json('assets/data/cities.json'));

CountryLookup realCountryLookup() =>
    CountryLookup.fromJson(_json('assets/data/countries_110m.json'));

/// Prayer services with the real calculator and the real bundled data, but a controllable clock,
/// permission gateway, location and storage.
class PrayerFixture {
  PrayerFixture({
    DateTime? now,
    PrayerPreferences? saved,
    LocationResult? position,
    Map<AppPermission, PermissionState>? permissions,
  }) : clock = FakeClock(now ?? DateTime.utc(2026, 4, 1, 10)),
       preferences = InMemoryPrayerPreferences(saved),
       location = FakeLocationService(position),
       gateway = FakePermissionGateway(permissions) {
    services = PrayerServices(
      preferences: preferences,
      calculator: const AdhanPrayerTimesCalculator(),
      hijri: const HijriCoreConverter(),
      permissions: PermissionFlow(gateway),
      location: location,
      loadCities: () async => realCityCatalog(),
      loadCountries: () async => realCountryLookup(),
      clock: clock,
    );
  }

  final FakeClock clock;
  final InMemoryPrayerPreferences preferences;
  final FakeLocationService location;
  final FakePermissionGateway gateway;
  late final PrayerServices services;
}
