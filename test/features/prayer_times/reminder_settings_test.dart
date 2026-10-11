import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/notifications/notification_gateway.dart';
import 'package:mynewapp/features/prayer_times/data/adhan_prayer_times_calculator.dart';
import 'package:mynewapp/features/prayer_times/data/prayer_preferences_repository_impl.dart';
import 'package:mynewapp/features/prayer_times/domain/calculation_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_location.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';
import 'package:mynewapp/features/prayer_times/domain/reminder_plan_builder.dart';
import 'package:mynewapp/features/prayer_times/domain/reminder_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/salawat_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/result_helpers.dart';

void main() {
  group('ReminderSettings', () {
    test(
      'start off, with the five prayers, at the time, system sound, vibrating, inexact',
      () {
        final s = ReminderSettings();
        expect(s.enabled, isFalse);
        expect(s.prayers, ReminderSettings.defaultPrayers);
        expect(s.prayers, isNot(contains(Prayer.sunrise)));
        expect(s.leadMinutes, 0);
        expect(s.sound, NotificationSound.system);
        expect(s.vibrate, isTrue);
        expect(s.exactTiming, isFalse);
      },
    );

    test(
      'nothing is active while off, and the active ones come in daily order',
      () {
        expect(ReminderSettings(prayers: {Prayer.isha}).active, isEmpty);
        expect(
          ReminderSettings(
            enabled: true,
            prayers: {Prayer.isha, Prayer.fajr, Prayer.sunrise},
          ).active,
          [Prayer.fajr, Prayer.sunrise, Prayer.isha],
        );
      },
    );

    test('only the offered lead times are accepted', () {
      for (final ok in ReminderSettings.leadOptions) {
        expect(ReminderSettings(leadMinutes: ok).leadMinutes, ok);
      }
      for (final bad in [-5, 1, 7, 45, 60]) {
        expect(() => ReminderSettings(leadMinutes: bad), throwsArgumentError);
      }
    });

    test('copyWith keeps the adhan, sets it, and can clear it', () {
      final s = ReminderSettings(adhanId: 'rifaat');
      expect(s.copyWith(vibrate: false).adhanId, 'rifaat');
      expect(s.copyWith(adhanId: 'mulla').adhanId, 'mulla');
      expect(s.copyWith(clearAdhan: true).adhanId, isNull);
      expect(ReminderSettings().adhanId, isNull);
    });

    test(
      'the wake-up alarm starts off, 30 minutes before, and accepts only the offered times',
      () {
        final s = ReminderSettings();
        expect(s.wakeUp, isFalse);
        expect(s.wakeUpMinutes, 30);
        for (final ok in ReminderSettings.wakeUpOptions) {
          expect(ReminderSettings(wakeUpMinutes: ok).wakeUpMinutes, ok);
        }
        for (final bad in [0, 10, 20, 90]) {
          expect(
            () => ReminderSettings(wakeUpMinutes: bad),
            throwsArgumentError,
          );
        }
        expect(s.copyWith(wakeUp: true, wakeUpMinutes: 15).wakeUp, isTrue);
      },
    );

    test(
      'the salawat recording defaults to the first and accepts only the two',
      () {
        expect(SalawatSettings().tone, 'salawat_1');
        for (final ok in SalawatSettings.toneOptions) {
          expect(SalawatSettings(tone: ok).tone, ok);
        }
        expect(() => SalawatSettings(tone: 'other'), throwsArgumentError);
        expect(SalawatSettings(tone: null).tone, isNull);
        expect(SalawatSettings().copyWith(clearTone: true).tone, isNull);
        expect(SalawatSettings().copyWith(tone: 'salawat_2').tone, 'salawat_2');
      },
    );

    test('the chosen prayers cannot be changed from outside', () {
      final s = ReminderSettings();
      expect(() => s.prayers.add(Prayer.sunrise), throwsUnsupportedError);
    });

    test(
      'equal settings are equal, whatever order the prayers were given in',
      () {
        expect(
          ReminderSettings(prayers: {Prayer.fajr, Prayer.asr}),
          ReminderSettings(prayers: {Prayer.asr, Prayer.fajr}),
        );
        expect(ReminderSettings(exactTiming: true), isNot(ReminderSettings()));
      },
    );

    test('copyWith changes only what is asked', () {
      final s = ReminderSettings(
        enabled: true,
        leadMinutes: 10,
      ).copyWith(exactTiming: true);
      expect(s.enabled, isTrue);
      expect(s.leadMinutes, 10);
      expect(s.exactTiming, isTrue);
    });
  });

  group('the preferences keep them', () {
    PrayerLocation place() => PrayerLocation(
      point: GeoPoint(30.06, 31.25),
      source: LocationSource.manual,
      zoneId: 'Africa/Cairo',
    );

    test('through every other change', () {
      final p = PrayerPreferences()
          .withReminders(ReminderSettings(enabled: true, leadMinutes: 15))
          .withLocation(place());
      expect(p.reminders.enabled, isTrue);
      expect(p.reminders.leadMinutes, 15);
      expect(p.withMethod(p.settings.method).reminders, p.reminders);
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

    test('everything round-trips', () async {
      final r = await repo();
      final saved = PrayerPreferences().withReminders(
        ReminderSettings(
          enabled: true,
          prayers: {Prayer.fajr, Prayer.sunrise, Prayer.isha},
          leadMinutes: 30,
          sound: NotificationSound.silent,
          vibrate: false,
          exactTiming: true,
        ),
      );
      await r.save(saved);
      expect((await r.load()).reminders, saved.reminders);
    });

    test('the chosen adhan round-trips, and bad values mean none', () async {
      final r = await repo();
      final saved = PrayerPreferences().withReminders(
        ReminderSettings(enabled: true, adhanId: 'rifaat'),
      );
      await r.save(saved);
      expect((await r.load()).reminders.adhanId, 'rifaat');
      for (final bad in [5, '', null, true]) {
        final p = await (await repo({
          PrayerPreferencesRepositoryImpl.storageKey: jsonEncode({
            'reminders': {'adhan': bad},
          }),
        })).load();
        expect(p.reminders.adhanId, isNull, reason: '$bad');
      }
    });

    test('older data has no adhan', () async {
      final p = await (await repo({
        PrayerPreferencesRepositoryImpl.storageKey: jsonEncode({
          'reminders': {'enabled': true},
        }),
      })).load();
      expect(p.reminders.adhanId, isNull);
    });

    test(
      'the wake-up alarm round-trips, and bad values mean the default',
      () async {
        final r = await repo();
        await r.save(
          PrayerPreferences().withReminders(
            ReminderSettings(enabled: true, wakeUp: true, wakeUpMinutes: 45),
          ),
        );
        final back = (await r.load()).reminders;
        expect(back.wakeUp, isTrue);
        expect(back.wakeUpMinutes, 45);
        for (final bad in <Object?>[
          {'enabled': 'yes', 'minutes': 7},
          {'enabled': true, 'minutes': 'soon'},
          'text',
          null,
        ]) {
          final p = await (await repo({
            PrayerPreferencesRepositoryImpl.storageKey: jsonEncode({
              'reminders': {'wakeUp': bad},
            }),
          })).load();
          expect(p.reminders.wakeUpMinutes, 30, reason: '$bad');
          expect(
            p.reminders.wakeUp,
            bad is Map && bad['enabled'] == true,
            reason: '$bad',
          );
        }
      },
    );

    test(
      'the salawat recording round-trips; old or bad data means the default',
      () async {
        final r = await repo();
        for (final tone in <String?>['salawat_2', null]) {
          await r.save(
            PrayerPreferences().withReminders(
              ReminderSettings(
                enabled: true,
                salawat: SalawatSettings(enabled: true, tone: tone),
              ),
            ),
          );
          expect((await r.load()).reminders.salawat.tone, tone);
        }
        for (final saved in <Map<String, Object?>>[
          {'enabled': true},
          {'enabled': true, 'tone': 'salawat_9'},
          {'enabled': true, 'tone': 3},
        ]) {
          final p = await (await repo({
            PrayerPreferencesRepositoryImpl.storageKey: jsonEncode({
              'reminders': {'salawat': saved},
            }),
          })).load();
          expect(p.reminders.salawat.tone, 'salawat_1', reason: '$saved');
        }
      },
    );

    test('older data without reminders means reminders off', () async {
      final json = jsonEncode({'method': 'egyptian'});
      final p = await (await repo({
        PrayerPreferencesRepositoryImpl.storageKey: json,
      })).load();
      expect(p.reminders, ReminderSettings());
    });

    test('bad values fall back to the defaults', () async {
      final cases = <Map<String, Object?>>[
        {'enabled': 'yes', 'leadMinutes': 7, 'sound': 'loud', 'prayers': 'all'},
        {
          'prayers': ['fajr', 'nonsense', 5],
          'leadMinutes': 'soon',
        },
        {'exactTiming': 'true'},
      ];
      for (final reminders in cases) {
        final p = await (await repo({
          PrayerPreferencesRepositoryImpl.storageKey: jsonEncode({
            'reminders': reminders,
          }),
        })).load();
        expect(p.reminders.enabled, isFalse, reason: '$reminders');
        expect(p.reminders.leadMinutes, 0, reason: '$reminders');
        expect(p.reminders.sound, NotificationSound.system);
        expect(p.reminders.exactTiming, isFalse, reason: '$reminders');
      }
    });

    test('unknown prayer names are dropped and the rest kept', () async {
      final p = await (await repo({
        PrayerPreferencesRepositoryImpl.storageKey: jsonEncode({
          'reminders': {
            'enabled': true,
            'prayers': ['fajr', 'nonsense', 'asr'],
          },
        }),
      })).load();
      expect(p.reminders.prayers, {Prayer.fajr, Prayer.asr});
    });
  });

  group('the plan builder', () {
    final days = [
      for (final d in [DateTime.utc(2026, 10, 9), DateTime.utc(2026, 10, 10)])
        const AdhanPrayerTimesCalculator()
            .calculate(
              location: GeoPoint(30.06, 31.25),
              date: d,
              settings: CalculationSettings(),
            )
            .value,
    ];

    test('builds nothing while reminders are off', () {
      expect(
        ReminderPlanBuilder.candidates(
          days: days,
          settings: ReminderSettings(),
          contentSignature: 'x',
        ),
        isEmpty,
      );
    });

    test('one candidate per chosen time per day, at the time', () {
      final c = ReminderPlanBuilder.candidates(
        days: days,
        settings: ReminderSettings(enabled: true),
        contentSignature: 'sig',
      );
      expect(c, hasLength(10));
      expect(c.first.key, 'fajr');
      expect(c.first.fireAt, days.first[Prayer.fajr]);
      expect(c.every((x) => x.signature == 'sig'), isTrue);
    });

    test('a lead time moves each one earlier by exactly that much', () {
      final c = ReminderPlanBuilder.candidates(
        days: days,
        settings: ReminderSettings(enabled: true, leadMinutes: 15),
        contentSignature: 'x',
      );
      expect(
        days.first[Prayer.fajr].difference(c.first.fireAt),
        const Duration(minutes: 15),
      );
    });

    test('prayer reminders outrank optional ones and ignore quiet hours', () {
      final c = ReminderPlanBuilder.candidates(
        days: days,
        settings: ReminderSettings(enabled: true),
        contentSignature: 'x',
      );
      expect(c.every((x) => x.priority > 0), isTrue);
      expect(c.every((x) => !x.respectsQuietHours), isTrue);
    });
  });
}
