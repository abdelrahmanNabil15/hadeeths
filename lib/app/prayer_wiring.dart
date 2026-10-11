import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:mynewapp/app/composite_permission_gateway.dart';
import 'package:mynewapp/app/reminder_coordinator.dart';
import 'package:mynewapp/app/widget_snapshot.dart';
import 'package:mynewapp/app/widget_updating_reminders.dart';
import 'package:mynewapp/core/notifications/local_notifications_gateway.dart';
import 'package:mynewapp/core/permissions/permission_flow.dart';
import 'package:mynewapp/core/permissions/permission_gateway.dart';
import 'package:mynewapp/core/platform/home_widget_bridge.dart';
import 'package:mynewapp/core/time/clock.dart';
import 'package:mynewapp/features/prayer_times/data/adhan_prayer_times_calculator.dart';
import 'package:mynewapp/features/prayer_times/data/geolocator_location_service.dart';
import 'package:mynewapp/features/prayer_times/data/hijri_core_converter.dart';
import 'package:mynewapp/features/prayer_times/data/prayer_preferences_repository_impl.dart';
import 'package:mynewapp/features/prayer_times/data/sensors_plus_compass_source.dart';
import 'package:mynewapp/features/prayer_times/domain/city.dart';
import 'package:mynewapp/features/prayer_times/domain/country_lookup.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_services.dart';
import 'package:mynewapp/features/prayer_times/domain/world_magnetic_model.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';
import 'package:mynewapp/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds the real prayer services. The city list and the country borders are read from the
/// app's assets the first time they are needed, then kept.
PrayerServices buildPrayerServices({
  required SharedPreferences preferences,
  required Future<AppSettings> Function() loadAppSettings,
  HomeWidgetBridge? homeWidget,
}) {
  Future<Map<String, dynamic>> asset(String path) async =>
      jsonDecode(await rootBundle.loadString(path)) as Map<String, dynamic>;
  Future<CityCatalog>? cities;
  Future<CountryLookup>? countries;
  Future<WorldMagneticModel>? magnetic;
  final notifications = LocalNotificationsGateway();
  final prayerPreferences = PrayerPreferencesRepositoryImpl(preferences);
  const calculator = AdhanPrayerTimesCalculator();
  final coordinator = ReminderCoordinator(
    preferences: prayerPreferences,
    calculator: calculator,
    gateway: notifications,
    loadAppSettings: loadAppSettings,
  );
  return PrayerServices(
    preferences: prayerPreferences,
    calculator: calculator,
    reminders: homeWidget == null
        ? coordinator
        : WidgetUpdatingReminderService(
            inner: coordinator,
            bridge: homeWidget,
            snapshot: () async {
              final app = await loadAppSettings();
              final env = ReminderEnvironment.current();
              final language = ReminderCoordinator.languageFor(app, env);
              return buildWidgetSnapshot(
                preferences: await prayerPreferences.load(),
                calculator: calculator,
                l10n: lookupAppLocalizations(Locale(language)),
                digits: ReminderCoordinator.digitsFor(app, language),
                use24Hour: env.use24Hour,
                now: const SystemClock().now(),
              );
            },
          ),
    hijri: const HijriCoreConverter(),
    permissions: PermissionFlow(
      buildPermissionGateway(notifications: notifications),
    ),
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

/// Sends each permission to the plugin that can ask for it, and opens the app's page in the system
/// settings. Every [AppPermission] must have a route: one without it would silently report
/// "unavailable" (a test checks this).
CompositePermissionGateway buildPermissionGateway({
  required LocalNotificationsGateway notifications,
}) {
  const location = GeolocatorPermissionGateway();
  final notificationPermissions = NotificationPermissionGateway(notifications);
  return CompositePermissionGateway(
    byPermission: {
      AppPermission.location: location,
      AppPermission.notifications: notificationPermissions,
      AppPermission.exactAlarms: notificationPermissions,
    },
    settingsOpener: location,
  );
}
