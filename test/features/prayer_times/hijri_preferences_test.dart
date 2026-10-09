import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/features/prayer_times/data/prayer_preferences_repository_impl.dart';
import 'package:mynewapp/features/prayer_times/domain/calculation_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/hijri_date.dart';
import 'package:mynewapp/features/prayer_times/domain/hijri_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_location.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';
import 'package:mynewapp/features/prayer_times/presentation/state/prayer_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/prayer_fakes.dart';

PrayerLocation _cairo() => PrayerLocation(
  point: GeoPoint(30.06, 31.25),
  source: LocationSource.manual,
  zoneId: 'Africa/Cairo',
  name: 'Cairo',
  countryCode: 'EG',
);

void main() {
  group('preferences', () {
    test(
      'start with Umm al-Qura and no correction, and nothing proposes otherwise',
      () {
        final p = PrayerPreferences().withLocation(_cairo());
        expect(p.hijri.reference, HijriReference.ummAlQura);
        expect(p.hijri.adjustmentDays, 0);
      },
    );

    test('the Hijri choice survives every other change', () {
      final chosen = PrayerPreferences().withHijri(
        HijriSettings(reference: HijriReference.fcna, adjustmentDays: -1),
      );
      final changed = chosen
          .withLocation(_cairo())
          .withMethod(CalculationMethodId.karachi)
          .withSettings(CalculationSettings(madhab: Madhab.hanafi));
      expect(changed.hijri.reference, HijriReference.fcna);
      expect(changed.hijri.adjustmentDays, -1);
    });

    test('changing the Hijri choice leaves the calculation method alone', () {
      final p = PrayerPreferences()
          .withLocation(_cairo())
          .withHijri(HijriSettings(adjustmentDays: 1));
      expect(p.settings.method, CalculationMethodId.egyptian);
      expect(p.methodOrigin, MethodOrigin.suggested);
    });
  });

  group('saving', () {
    Future<PrayerPreferencesRepositoryImpl> repo([
      Map<String, Object> initial = const {},
    ]) async {
      SharedPreferences.setMockInitialValues(initial);
      return PrayerPreferencesRepositoryImpl(
        await SharedPreferences.getInstance(),
      );
    }

    test('the reference and the correction round-trip', () async {
      final r = await repo();
      final saved = PrayerPreferences()
          .withLocation(_cairo())
          .withHijri(
            HijriSettings(reference: HijriReference.fcna, adjustmentDays: 2),
          );
      await r.save(saved);
      expect(await r.load(), saved);
    });

    test(
      'older saved data without the Hijri fields gets the defaults',
      () async {
        final json = jsonEncode({
          'method': 'egyptian',
          'origin': 'suggested',
          'location': {
            'latitude': 30.06,
            'longitude': 31.25,
            'source': 'manual',
            'zone': 'Africa/Cairo',
          },
        });
        final p = await (await repo({
          PrayerPreferencesRepositoryImpl.storageKey: json,
        })).load();
        expect(p.hijri, HijriSettings());
      },
    );

    test('bad Hijri values fall back to the defaults', () async {
      final cases = <(Object?, Object?, HijriReference, int)>[
        ('martian', 1, HijriReference.ummAlQura, 1),
        ('fcna', 9, HijriReference.fcna, 0),
        ('fcna', 'x', HijriReference.fcna, 0),
        (null, -7, HijriReference.ummAlQura, 0),
      ];
      for (final (reference, adjustment, wantReference, wantDays) in cases) {
        final json = jsonEncode({
          'hijriReference': reference,
          'hijriAdjustment': adjustment,
        });
        final p = await (await repo({
          PrayerPreferencesRepositoryImpl.storageKey: json,
        })).load();
        expect(
          p.hijri.reference,
          wantReference,
          reason: '$reference $adjustment',
        );
        expect(
          p.hijri.adjustmentDays,
          wantDays,
          reason: '$reference $adjustment',
        );
      }
    });
  });

  group('the cubit', () {
    final cairoCity = realCityCatalog().cities.firstWhere(
      (c) => c.nameEn == 'Cairo',
    );

    test('shows the Hijri date of the place, switching at Maghrib', () async {
      // 21 June 2026 in Cairo: Maghrib is about 17:00 UTC (19:59 local summer time).
      final morning = PrayerFixture(now: DateTime.utc(2026, 6, 21, 8));
      final a = PrayerCubit(morning.services);
      await a.load();
      await a.selectCity(cairoCity, languageCode: 'en');
      expect(a.state.hijriDate, const HijriDate(year: 1448, month: 1, day: 6));

      final night = PrayerFixture(now: DateTime.utc(2026, 6, 21, 19));
      final b = PrayerCubit(night.services);
      await b.load();
      await b.selectCity(cairoCity, languageCode: 'en');
      expect(b.state.hijriDate, const HijriDate(year: 1448, month: 1, day: 7));
    });

    test('a correction recalculates and is saved', () async {
      final f = PrayerFixture(now: DateTime.utc(2026, 6, 21, 8));
      final cubit = PrayerCubit(f.services);
      await cubit.load();
      await cubit.selectCity(cairoCity, languageCode: 'en');
      await cubit.setHijri(HijriSettings(adjustmentDays: -1));
      expect(
        cubit.state.hijriDate,
        const HijriDate(year: 1448, month: 1, day: 5),
      );
      expect(f.preferences.stored.hijri.adjustmentDays, -1);
    });

    test('a different reference is applied and saved', () async {
      final f = PrayerFixture(now: DateTime.utc(2026, 6, 21, 8));
      final cubit = PrayerCubit(f.services);
      await cubit.load();
      await cubit.selectCity(cairoCity, languageCode: 'en');
      await cubit.setHijri(HijriSettings(reference: HijriReference.fcna));
      expect(cubit.state.hijriDate, isNotNull);
      expect(f.preferences.stored.hijri.reference, HijriReference.fcna);
    });

    test('no Hijri date when no times could be calculated', () async {
      final f = PrayerFixture(
        saved: PrayerPreferences().withLocation(
          PrayerLocation(
            point: GeoPoint(78.22, 15.63),
            source: LocationSource.manual,
            zoneId: 'Europe/Oslo',
          ),
        ),
        now: DateTime.utc(2026, 6, 21, 10),
      );
      final cubit = PrayerCubit(f.services);
      await cubit.load();
      expect(cubit.state.hijriDate, isNull);
    });
  });
}
