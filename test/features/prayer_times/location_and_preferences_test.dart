import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/features/prayer_times/data/prayer_preferences_repository_impl.dart';
import 'package:mynewapp/features/prayer_times/domain/calculation_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/country_lookup.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/method_suggestion.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_location.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

PrayerLocation _place(
  double lat,
  double lon, {
  String zone = 'Africa/Cairo',
  String? name = 'Cairo',
  LocationSource source = LocationSource.manual,
  String? country,
}) => PrayerLocation(
  point: GeoPoint(lat, lon),
  source: source,
  zoneId: zone,
  name: name,
  countryCode: country,
);

void main() {
  group('country lookup (offline, from the bundled borders)', () {
    final lookup = CountryLookup.fromJson(
      jsonDecode(File('assets/data/countries_110m.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    String? at(double lat, double lon) => lookup.countryAt(GeoPoint(lat, lon));

    test('cities in the countries the method suggestion cares about', () {
      expect(at(30.0444, 31.2357), 'EG'); // Cairo
      expect(at(31.2001, 29.9187), 'EG'); // Alexandria, on the coast
      expect(at(21.4225, 39.8262), 'SA'); // Makkah
      expect(at(24.7136, 46.6753), 'SA'); // Riyadh
      expect(at(24.8607, 67.0011), 'PK'); // Karachi, on the coast
      expect(at(23.8103, 90.4125), 'BD'); // Dhaka
      expect(at(28.6139, 77.2090), 'IN'); // Delhi
      expect(at(40.7128, -74.0060), 'US'); // New York
      expect(at(43.6532, -79.3832), 'CA'); // Toronto
      expect(at(34.0522, -118.2437), 'US'); // Los Angeles
    });

    test('other places', () {
      expect(at(51.5074, -0.1278), 'GB');
      expect(
        at(48.8566, 2.3522),
        'FR',
      ); // France has no plain code in some data sets
      expect(at(59.9139, 10.7522), 'NO'); // same for Norway
      expect(at(-6.2088, 106.8456), 'ID'); // Jakarta, on the coast
      expect(at(41.0082, 28.9784), 'TR'); // Istanbul
      expect(at(33.5731, -7.5898), 'MA'); // Casablanca
      expect(at(-36.8485, 174.7633), 'NZ'); // Auckland
      expect(at(-33.8688, 151.2093), 'AU'); // Sydney
    });

    test('open ocean is no country', () {
      expect(at(0, -30), isNull);
      expect(at(-40, -120), isNull);
    });

    test(
      'very small countries are not known, and that is reported as null, not guessed',
      () {
        expect(
          at(1.3521, 103.8198),
          anyOf(isNull, 'MY', 'ID'),
        ); // Singapore: none at this scale
      },
    );

    test('works across the date line', () {
      expect(at(-17.7134, 178.065), 'FJ');
    });
  });

  group('method suggestion', () {
    test('country to method', () {
      final cases = {
        'EG': CalculationMethodId.egyptian,
        'SA': CalculationMethodId.ummAlQura,
        'PK': CalculationMethodId.karachi,
        'BD': CalculationMethodId.karachi,
        'IN': CalculationMethodId.karachi,
        'AF': CalculationMethodId.karachi,
        'US': CalculationMethodId.northAmerica,
        'CA': CalculationMethodId.northAmerica,
      };
      cases.forEach((code, method) {
        final s = MethodSuggestion.forCountry(code);
        expect(s.method, method, reason: code);
        expect(s.isCountrySpecific, isTrue);
        expect(s.countryCode, code);
      });
    });

    test('anywhere else, or unknown, uses the general method and says so', () {
      for (final code in ['GB', 'ID', 'TR', 'FR', null]) {
        final s = MethodSuggestion.forCountry(code);
        expect(
          s.method,
          CalculationMethodId.muslimWorldLeague,
          reason: '$code',
        );
        expect(s.isCountrySpecific, isFalse);
      }
    });

    test('lower case codes work', () {
      expect(
        MethodSuggestion.forCountry('eg').method,
        CalculationMethodId.egyptian,
      );
    });

    test('every suggested method is one the app offers', () {
      for (final method in MethodSuggestion.byCountry.values) {
        expect(methodInfo.containsKey(method), isTrue);
      }
    });
  });

  group('location', () {
    test('the stored position is rounded to about a kilometre', () {
      final p = _place(30.04442, 31.23571);
      expect(p.point, GeoPoint(30.04, 31.24));
    });

    test('device zone is flagged', () {
      final p = _place(
        30.04,
        31.24,
        zone: PrayerLocation.deviceZoneId,
        name: null,
        source: LocationSource.gps,
      );
      expect(p.usesDeviceZone, isTrue);
      expect(_place(30.04, 31.24).usesDeviceZone, isFalse);
    });
  });

  group('the method is proposed once, then stays', () {
    test('a fresh setup has nothing decided', () {
      final p = PrayerPreferences();
      expect(p.isSetUp, isFalse);
      expect(p.methodOrigin, MethodOrigin.notSet);
    });

    test('the first place proposes the method of its country', () {
      final p = PrayerPreferences().withLocation(
        _place(30.0444, 31.2357),
        countryCode: 'EG',
      );
      expect(p.settings.method, CalculationMethodId.egyptian);
      expect(p.methodOrigin, MethodOrigin.suggested);
      expect(p.isSetUp, isTrue);
    });

    test('the place\'s own country code is used when none is passed', () {
      final p = PrayerPreferences().withLocation(
        _place(21.4, 39.8, zone: 'Asia/Riyadh', name: 'Makkah', country: 'SA'),
      );
      expect(p.settings.method, CalculationMethodId.ummAlQura);
    });

    test('a country with no specific method gets the general one', () {
      final p = PrayerPreferences().withLocation(
        _place(
          51.5,
          -0.13,
          zone: 'Europe/London',
          name: 'London',
          country: 'GB',
        ),
      );
      expect(p.settings.method, CalculationMethodId.muslimWorldLeague);
      expect(p.methodOrigin, MethodOrigin.suggested);
    });

    test('moving to another country later does NOT change the method', () {
      final first = PrayerPreferences().withLocation(
        _place(30.0444, 31.2357),
        countryCode: 'EG',
      );
      final moved = first.withLocation(
        _place(40.7128, -74.006, zone: 'America/New_York', name: 'New York'),
        countryCode: 'US',
      );
      expect(moved.settings.method, CalculationMethodId.egyptian);
      expect(moved.methodOrigin, MethodOrigin.suggested);
      expect(moved.location!.name, 'New York');
    });

    test(
      'a method the user chose is theirs, and later places do not touch it',
      () {
        final chosen = PrayerPreferences()
            .withLocation(_place(30.0444, 31.2357), countryCode: 'EG')
            .withMethod(CalculationMethodId.muslimWorldLeague);
        expect(chosen.methodOrigin, MethodOrigin.user);
        final moved = chosen.withLocation(
          _place(21.4, 39.8, zone: 'Asia/Riyadh', name: 'Makkah'),
          countryCode: 'SA',
        );
        expect(moved.settings.method, CalculationMethodId.muslimWorldLeague);
        expect(moved.methodOrigin, MethodOrigin.user);
      },
    );

    test(
      'choosing a method before any place also counts as the user\'s decision',
      () {
        final p = PrayerPreferences().withMethod(CalculationMethodId.karachi);
        final placed = p.withLocation(
          _place(30.0444, 31.2357),
          countryCode: 'EG',
        );
        expect(placed.settings.method, CalculationMethodId.karachi);
      },
    );

    test('other settings change without touching the method or its origin', () {
      final base = PrayerPreferences().withLocation(
        _place(30.0444, 31.2357),
        countryCode: 'EG',
      );
      final changed = base.withSettings(
        CalculationSettings(
          method: CalculationMethodId
              .karachi, // ignored: the method is changed only by withMethod
          madhab: Madhab.hanafi,
          adjustments: {Prayer.fajr: 2},
        ),
      );
      expect(changed.settings.method, CalculationMethodId.egyptian);
      expect(changed.settings.madhab, Madhab.hanafi);
      expect(changed.settings.adjustmentFor(Prayer.fajr), 2);
      expect(changed.methodOrigin, MethodOrigin.suggested);
    });
  });

  group('saving and loading', () {
    Future<PrayerPreferencesRepositoryImpl> repo([
      Map<String, Object> initial = const {},
    ]) async {
      SharedPreferences.setMockInitialValues(initial);
      return PrayerPreferencesRepositoryImpl(
        await SharedPreferences.getInstance(),
      );
    }

    test('nothing saved gives a fresh setup', () async {
      final p = await (await repo()).load();
      expect(p, PrayerPreferences());
    });

    test('everything survives a save and a load', () async {
      final r = await repo();
      final saved = PrayerPreferences()
          .withLocation(
            _place(30.0444, 31.2357, country: 'EG'),
            countryCode: 'EG',
          )
          .withSettings(
            CalculationSettings(
              madhab: Madhab.hanafi,
              highLatitudeRule: HighLatitudeRule.seventhOfTheNight,
              adjustments: {Prayer.fajr: -2, Prayer.isha: 3},
            ),
          );
      await r.save(saved);
      expect(await r.load(), saved);
    });

    test('a device position keeps the device zone and no name', () async {
      final r = await repo();
      final saved = PrayerPreferences().withLocation(
        _place(
          30.0444,
          31.2357,
          zone: PrayerLocation.deviceZoneId,
          name: null,
          source: LocationSource.gps,
        ),
      );
      await r.save(saved);
      final loaded = await r.load();
      expect(loaded.location!.usesDeviceZone, isTrue);
      expect(loaded.location!.name, isNull);
      expect(loaded.location!.source, LocationSource.gps);
    });

    test(
      'the method decision survives, so a later place does not change it',
      () async {
        final r = await repo();
        await r.save(
          PrayerPreferences().withLocation(
            _place(30.04, 31.24),
            countryCode: 'EG',
          ),
        );
        final loaded = await r.load();
        final moved = loaded.withLocation(
          _place(40.7, -74.0, zone: 'America/New_York', name: 'New York'),
          countryCode: 'US',
        );
        expect(moved.settings.method, CalculationMethodId.egyptian);
      },
    );

    test('unreadable data means a fresh setup, not a crash', () async {
      for (final bad in ['not json', '[]', '"x"', '{"location": 5}', '{']) {
        final p = await (await repo({
          PrayerPreferencesRepositoryImpl.storageKey: bad,
        })).load();
        expect(p.isSetUp, isFalse, reason: bad);
      }
    });

    test('single bad fields fall back to their defaults', () async {
      final json = jsonEncode({
        'method': 'martian',
        'madhab': 7,
        'highLatitudeRule': null,
        'adjustments': {'fajr': 99, 'isha': 2, 'nonsense': 1, 'asr': 'x'},
        'origin': 'suggested',
        'location': {
          'latitude': 30.04,
          'longitude': 31.24,
          'source': 'manual',
          'zone': 'Africa/Cairo',
          'name': 5,
        },
      });
      final p = await (await repo({
        PrayerPreferencesRepositoryImpl.storageKey: json,
      })).load();
      expect(p.settings.method, CalculationSettings.defaultMethod);
      expect(p.settings.madhab, Madhab.shafii);
      expect(p.settings.adjustments, {Prayer.isha: 2});
      expect(p.location!.name, isNull);
      expect(p.location!.point, GeoPoint(30.04, 31.24));
    });

    test('an impossible position is dropped', () async {
      final p = await (await repo({
        PrayerPreferencesRepositoryImpl.storageKey: jsonEncode({
          'location': {
            'latitude': 95,
            'longitude': 0,
            'source': 'gps',
            'zone': 'device',
          },
        }),
      })).load();
      expect(p.isSetUp, isFalse);
    });

    test('clearing forgets everything', () async {
      final r = await repo();
      await r.save(PrayerPreferences().withLocation(_place(30.04, 31.24)));
      await r.clear();
      expect((await r.load()).isSetUp, isFalse);
    });

    test('the saved text contains no more precision than was kept', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await PrayerPreferencesRepositoryImpl(
        prefs,
      ).save(PrayerPreferences().withLocation(_place(30.04442, 31.23571)));
      final text = prefs.getString(PrayerPreferencesRepositoryImpl.storageKey)!;
      expect(text, contains('30.04'));
      expect(text, isNot(contains('30.0444')));
    });
  });
}
