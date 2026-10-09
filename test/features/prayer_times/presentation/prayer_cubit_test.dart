import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/permissions/permission_gateway.dart';
import 'package:mynewapp/core/time/zone.dart';
import 'package:mynewapp/features/prayer_times/domain/calculation_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/location_service.dart';
import 'package:mynewapp/features/prayer_times/domain/location_setup.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_location.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';
import 'package:mynewapp/features/prayer_times/presentation/state/prayer_cubit.dart';

import '../../../support/prayer_fakes.dart';

void main() {
  final catalog = realCityCatalog();
  final cairo = catalog.cities.firstWhere((c) => c.nameEn == 'Cairo');
  final newYork = catalog.cities.firstWhere((c) => c.nameEn == 'New York');
  final london = catalog.cities.firstWhere((c) => c.nameEn == 'London');

  Future<bool> agree() async => true;

  test('nothing saved: the screen asks for a place', () async {
    final f = PrayerFixture();
    final cubit = PrayerCubit(f.services);
    await cubit.load();
    expect(cubit.state.status, PrayerStatus.needsSetup);
    expect(cubit.state.today, isNull);
  });

  group('choosing a city', () {
    test(
      'gives today\'s times in the city\'s own clock and proposes its country\'s method',
      () async {
        final f = PrayerFixture(now: DateTime.utc(2026, 4, 1, 10));
        final cubit = PrayerCubit(f.services);
        await cubit.load();
        await cubit.selectCity(cairo, languageCode: 'ar');

        final s = cubit.state;
        expect(s.status, PrayerStatus.ready);
        expect(s.preferences.settings.method, CalculationMethodId.egyptian);
        expect(s.preferences.methodOrigin, MethodOrigin.suggested);
        expect(s.preferences.location!.name, 'القاهرة');
        expect(s.zone!.id, 'Africa/Cairo');
        expect(s.today, isNotNull);
        expect(s.calculationFailed, isFalse);
        // 1 April 2026: Cairo is on winter time (+2); Fajr about 04:17 local, as published.
        final fajr = s.zone!.wallClockAt(s.today![Prayer.fajr]);
        expect(fajr.hour, 4);
        expect(
          fajr.minute,
          inInclusiveRange(16, 18),
        ); // published: 04:17 (the city centre differs by a km)
      },
    );

    test('it is saved', () async {
      final f = PrayerFixture();
      final cubit = PrayerCubit(f.services);
      await cubit.load();
      await cubit.selectCity(cairo, languageCode: 'en');
      expect(f.preferences.saves, 1);
      expect(f.preferences.stored.location!.name, 'Cairo');
    });

    test('saved places are restored when the screen opens again', () async {
      final f = PrayerFixture();
      final first = PrayerCubit(f.services);
      await first.load();
      await first.selectCity(cairo, languageCode: 'en');
      final second = PrayerCubit(f.services);
      await second.load();
      expect(second.state.status, PrayerStatus.ready);
      expect(second.state.preferences.location!.name, 'Cairo');
    });

    test('the date is the date at the place, not on the device', () async {
      // 21:30 UTC on 1 April is already 2 April in Auckland (+13 in April); NY is still 1 April.
      final auckland = catalog.cities.firstWhere((c) => c.nameEn == 'Auckland');
      final f = PrayerFixture(now: DateTime.utc(2026, 4, 1, 21, 30));
      final nz = PrayerCubit(f.services);
      await nz.load();
      await nz.selectCity(auckland, languageCode: 'en');
      expect(nz.state.today!.date, DateTime.utc(2026, 4, 2));

      final f2 = PrayerFixture(now: DateTime.utc(2026, 4, 1, 21, 30));
      final ny = PrayerCubit(f2.services);
      await ny.load();
      await ny.selectCity(newYork, languageCode: 'en');
      expect(ny.state.today!.date, DateTime.utc(2026, 4, 1));
    });

    test('a failed save does not block the screen', () async {
      final f = PrayerFixture()..preferences.failSaving = true;
      final cubit = PrayerCubit(f.services);
      await cubit.load();
      await cubit.selectCity(cairo, languageCode: 'en');
      expect(cubit.state.status, PrayerStatus.ready);
      expect(cubit.state.today, isNotNull);
    });
  });

  group('the method is proposed once', () {
    test('a later city in another country does not change it', () async {
      final f = PrayerFixture();
      final cubit = PrayerCubit(f.services);
      await cubit.load();
      await cubit.selectCity(cairo, languageCode: 'en');
      await cubit.selectCity(newYork, languageCode: 'en');
      expect(
        cubit.state.preferences.settings.method,
        CalculationMethodId.egyptian,
      );
      expect(cubit.state.preferences.location!.name, 'New York');
    });

    test('a country without its own method gets the general one', () async {
      final f = PrayerFixture();
      final cubit = PrayerCubit(f.services);
      await cubit.load();
      await cubit.selectCity(london, languageCode: 'en');
      expect(
        cubit.state.preferences.settings.method,
        CalculationMethodId.muslimWorldLeague,
      );
    });

    test(
      'the user\'s own choice recalculates, is saved and then sticks',
      () async {
        final f = PrayerFixture();
        final cubit = PrayerCubit(f.services);
        await cubit.load();
        await cubit.selectCity(cairo, languageCode: 'en');
        final before = cubit.state.today![Prayer.fajr];
        await cubit.chooseMethod(CalculationMethodId.northAmerica);
        expect(cubit.state.preferences.methodOrigin, MethodOrigin.user);
        expect(
          cubit.state.today![Prayer.fajr].isAfter(before),
          isTrue,
        ); // 15 degrees is later than 19.5
        expect(
          f.preferences.stored.settings.method,
          CalculationMethodId.northAmerica,
        );
        await cubit.selectCity(newYork, languageCode: 'en');
        expect(
          cubit.state.preferences.settings.method,
          CalculationMethodId.northAmerica,
        );
      },
    );
  });

  group('use my location', () {
    test(
      'explained, allowed, read: the place is the device position in the device zone',
      () async {
        final f = PrayerFixture();
        final cubit = PrayerCubit(f.services);
        await cubit.load();
        await cubit.useMyLocation(explain: agree);
        final place = cubit.state.preferences.location!;
        expect(place.source, LocationSource.gps);
        expect(place.usesDeviceZone, isTrue);
        expect(place.name, isNull);
        expect(place.countryCode, 'EG'); // found offline from the borders
        expect(
          cubit.state.preferences.settings.method,
          CalculationMethodId.egyptian,
        );
        expect(cubit.state.locating, isFalse);
        expect(f.location.reads, 1);
      },
    );

    test('the saved position is the rounded one', () async {
      final f = PrayerFixture();
      final cubit = PrayerCubit(f.services);
      await cubit.load();
      await cubit.useMyLocation(explain: agree);
      expect(f.preferences.stored.location!.point.latitude, 30.04);
      expect(f.preferences.stored.location!.point.longitude, 31.24);
    });

    test('closing the explanation changes nothing and asks nothing', () async {
      final f = PrayerFixture();
      final cubit = PrayerCubit(f.services);
      await cubit.load();
      await cubit.useMyLocation(explain: () async => false);
      expect(cubit.state.status, PrayerStatus.needsSetup);
      expect(cubit.state.setupProblem, LocationSetupStatus.declinedExplanation);
      expect(f.gateway.requested, isEmpty);
      expect(f.location.reads, 0);
      expect(cubit.state.locating, isFalse);
    });

    test('each problem is reported and no place is saved', () async {
      final cases = <(void Function(PrayerFixture), LocationSetupStatus)>[
        (
          (f) => f.gateway.onRequest[AppPermission.location] =
              PermissionState.denied,
          LocationSetupStatus.denied,
        ),
        (
          (f) => f.gateway.states[AppPermission.location] =
              PermissionState.permanentlyDenied,
          LocationSetupStatus.needsSettings,
        ),
        (
          (f) {
            f.gateway.states[AppPermission.location] = PermissionState.granted;
            f.location.result = const LocationFailed(
              LocationProblem.serviceDisabled,
            );
          },
          LocationSetupStatus.serviceDisabled,
        ),
        (
          (f) {
            f.gateway.states[AppPermission.location] = PermissionState.granted;
            f.location.result = const LocationFailed(LocationProblem.timeout);
          },
          LocationSetupStatus.timeout,
        ),
      ];
      for (final (arrange, expected) in cases) {
        final f = PrayerFixture();
        arrange(f);
        final cubit = PrayerCubit(f.services);
        await cubit.load();
        await cubit.useMyLocation(explain: agree);
        expect(
          cubit.state.status,
          PrayerStatus.needsSetup,
          reason: '$expected',
        );
        expect(cubit.state.setupProblem, expected);
        expect(f.preferences.saves, 0, reason: '$expected');
        expect(cubit.state.locating, isFalse);
      }
    });

    test('a city can still be chosen after a failure', () async {
      final f = PrayerFixture();
      f.gateway.states[AppPermission.location] =
          PermissionState.permanentlyDenied;
      final cubit = PrayerCubit(f.services);
      await cubit.load();
      await cubit.useMyLocation(explain: agree);
      await cubit.selectCity(cairo, languageCode: 'en');
      expect(cubit.state.status, PrayerStatus.ready);
      expect(cubit.state.setupProblem, isNull);
    });

    test('the settings pages are reachable from the cubit', () async {
      final f = PrayerFixture();
      final cubit = PrayerCubit(f.services);
      await cubit.openAppSettings();
      await cubit.openLocationSettings();
      expect(f.gateway.settingsOpened, 1);
      expect(f.location.locationSettingsOpened, 1);
    });
  });

  group('current and next prayer', () {
    test('follows the clock', () async {
      // 12:30 UTC on 1 April = 14:30 in Cairo: after Dhuhr (12:00), before Asr (15:31).
      final f = PrayerFixture(now: DateTime.utc(2026, 4, 1, 12, 30));
      final cubit = PrayerCubit(f.services);
      await cubit.load();
      await cubit.selectCity(cairo, languageCode: 'en');
      expect(cubit.state.moment!.current, Prayer.dhuhr);
      expect(cubit.state.moment!.next, Prayer.asr);
    });

    test('refresh moves on when time passes', () async {
      final f = PrayerFixture(now: DateTime.utc(2026, 4, 1, 12, 30));
      final cubit = PrayerCubit(f.services);
      await cubit.load();
      await cubit.selectCity(cairo, languageCode: 'en');
      f.clock.set(DateTime.utc(2026, 4, 1, 14, 0)); // 16:00 in Cairo, after Asr
      cubit.refresh();
      expect(cubit.state.moment!.current, Prayer.asr);
      expect(cubit.state.moment!.next, Prayer.maghrib);
    });

    test('refresh after midnight at the place uses the new date', () async {
      final f = PrayerFixture(now: DateTime.utc(2026, 4, 1, 12, 0));
      final cubit = PrayerCubit(f.services);
      await cubit.load();
      await cubit.selectCity(cairo, languageCode: 'en');
      expect(cubit.state.today!.date, DateTime.utc(2026, 4, 1));
      f.clock.set(
        DateTime.utc(2026, 4, 1, 22, 30),
      ); // 00:30 on 2 April in Cairo
      cubit.refresh();
      expect(cubit.state.today!.date, DateTime.utc(2026, 4, 2));
      expect(
        cubit.state.moment!.current,
        Prayer.isha,
      ); // still last night's Isha
      expect(cubit.state.moment!.next, Prayer.fajr);
    });
  });

  test(
    'a place where nothing can be calculated is reported, not guessed',
    () async {
      final f = PrayerFixture(
        saved: PrayerPreferences().withLocation(
          PrayerLocation(
            point: GeoPoint(78.22, 15.63),
            source: LocationSource.manual,
            zoneId: 'Europe/Oslo',
            name: 'Arctic',
            countryCode: 'NO',
          ),
        ),
        now: DateTime.utc(2026, 6, 21, 10),
      );
      final cubit = PrayerCubit(f.services);
      await cubit.load();
      expect(cubit.state.status, PrayerStatus.ready);
      expect(cubit.state.calculationFailed, isTrue);
      expect(cubit.state.today, isNull);
      expect(cubit.state.moment, isNull);
    },
  );
}
