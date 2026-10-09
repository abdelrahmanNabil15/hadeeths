import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mynewapp/app/reminder_coordinator.dart';
import 'package:mynewapp/core/permissions/permission_flow.dart';
import 'package:mynewapp/core/permissions/permission_gateway.dart';
import 'package:mynewapp/features/prayer_times/data/adhan_prayer_times_calculator.dart';
import 'package:mynewapp/features/prayer_times/data/hijri_core_converter.dart';
import 'package:mynewapp/features/prayer_times/domain/city.dart';
import 'package:mynewapp/features/prayer_times/domain/compass_source.dart';
import 'package:mynewapp/features/prayer_times/domain/country_lookup.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/heading_calculator.dart';
import 'package:mynewapp/features/prayer_times/domain/location_service.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences_repository.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_services.dart';
import 'package:mynewapp/features/prayer_times/domain/world_magnetic_model.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';

import 'fake_permissions.dart';
import 'notification_fakes.dart';
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

/// Motion sensors the test drives by hand. Counts how many times they were started and stopped.
class FakeCompassSource implements CompassSource {
  StreamController<CompassSample>? _controller;
  int starts = 0;
  int stops = 0;

  /// When set, listening fails with this error as soon as it starts (no sensor).
  Object? failWith;

  bool get running => _controller != null;

  @override
  Stream<CompassSample> samples() {
    // ignore: close_sinks
    late StreamController<CompassSample> c;
    c = StreamController<CompassSample>(
      onListen: () {
        starts++;
        _controller = c;
        if (failWith != null) c.addError(failWith!);
      },
      onCancel: () {
        stops++;
        _controller = null;
      },
    );
    return c.stream;
  }

  void emit(CompassSample sample) => _controller?.add(sample);

  /// Ends the stream, as a closed sensor would.
  Future<void> dispose() async => _controller?.close();
}

WorldMagneticModel realMagneticModel() => WorldMagneticModel.parse(
  File('assets/data/wmm2025.cof').readAsStringSync(),
);

/// Prayer services with the real calculator and the real bundled data, but a controllable clock,
/// permission gateway, location and storage.
class PrayerFixture {
  PrayerFixture({
    DateTime? now,
    PrayerPreferences? saved,
    LocationResult? position,
    Map<AppPermission, PermissionState>? permissions,
    this.appSettings = const AppSettings(),
    bool use24Hour = false,
  }) : clock = FakeClock(now ?? DateTime.utc(2026, 4, 1, 10)),
       preferences = InMemoryPrayerPreferences(saved),
       location = FakeLocationService(position),
       gateway = FakePermissionGateway(permissions),
       compass = FakeCompassSource(),
       notifications = FakeNotificationGateway() {
    services = PrayerServices(
      preferences: preferences,
      calculator: const AdhanPrayerTimesCalculator(),
      hijri: const HijriCoreConverter(),
      permissions: PermissionFlow(gateway),
      location: location,
      loadCities: () async => realCityCatalog(),
      loadCountries: () async => realCountryLookup(),
      compass: compass,
      loadMagneticModel: () async => realMagneticModel(),
      reminders: ReminderCoordinator(
        preferences: preferences,
        calculator: const AdhanPrayerTimesCalculator(),
        gateway: notifications,
        loadAppSettings: () async => appSettings,
        environment: () =>
            ReminderEnvironment(deviceLanguageCode: 'ar', use24Hour: use24Hour),
        clock: clock,
      ),
      clock: clock,
    );
  }

  final FakeClock clock;
  final InMemoryPrayerPreferences preferences;
  final FakeLocationService location;
  final FakePermissionGateway gateway;
  final FakeCompassSource compass;
  final FakeNotificationGateway notifications;
  final AppSettings appSettings;
  late final PrayerServices services;
}
