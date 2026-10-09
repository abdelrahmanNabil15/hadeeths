import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:mynewapp/core/permissions/permission_flow.dart';
import 'package:mynewapp/features/prayer_times/data/adhan_prayer_times_calculator.dart';
import 'package:mynewapp/features/prayer_times/data/geolocator_location_service.dart';
import 'package:mynewapp/features/prayer_times/data/hijri_core_converter.dart';
import 'package:mynewapp/features/prayer_times/data/prayer_preferences_repository_impl.dart';
import 'package:mynewapp/features/prayer_times/data/sensors_plus_compass_source.dart';
import 'package:mynewapp/features/prayer_times/domain/city.dart';
import 'package:mynewapp/features/prayer_times/domain/country_lookup.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_services.dart';
import 'package:mynewapp/features/prayer_times/domain/world_magnetic_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds the real prayer services. The city list and the country borders are read from the
/// app's assets the first time they are needed, then kept.
PrayerServices buildPrayerServices({required SharedPreferences preferences}) {
  Future<Map<String, dynamic>> asset(String path) async =>
      jsonDecode(await rootBundle.loadString(path)) as Map<String, dynamic>;
  Future<CityCatalog>? cities;
  Future<CountryLookup>? countries;
  Future<WorldMagneticModel>? magnetic;
  return PrayerServices(
    preferences: PrayerPreferencesRepositoryImpl(preferences),
    calculator: const AdhanPrayerTimesCalculator(),
    hijri: const HijriCoreConverter(),
    permissions: const PermissionFlow(GeolocatorPermissionGateway()),
    location: const GeolocatorLocationService(),
    loadCities: () =>
        cities ??= asset('assets/data/cities.json').then(CityCatalog.fromJson),
    loadCountries: () => countries ??= asset(
      'assets/data/countries_110m.json',
    ).then(CountryLookup.fromJson),
    compass: const SensorsPlusCompassSource(),
    loadMagneticModel: () => magnetic ??= rootBundle
        .loadString('assets/data/wmm2025.cof')
        .then(WorldMagneticModel.parse),
  );
}
