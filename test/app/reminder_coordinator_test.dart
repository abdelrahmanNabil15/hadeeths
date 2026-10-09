import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/reminder_coordinator.dart';
import 'package:mynewapp/core/notifications/notification_gateway.dart';
import 'package:mynewapp/core/notifications/notification_sync.dart';
import 'package:mynewapp/features/prayer_times/data/adhan_prayer_times_calculator.dart';
import 'package:mynewapp/features/prayer_times/domain/calculation_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_location.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';
import 'package:mynewapp/features/prayer_times/domain/reminder_settings.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';

import '../support/prayer_fakes.dart';
import '../support/result_helpers.dart';

final _cairo = realCityCatalog().cities.firstWhere((c) => c.nameEn == 'Cairo');
final _newYork = realCityCatalog().cities.firstWhere(
  (c) => c.nameEn == 'New York',
);

// 9 October 2026, 10:00 UTC: 13:00 in Cairo (summer time), after Dhuhr and before Asr.
final _now = DateTime.utc(2026, 10, 9, 10);

PrayerPreferences _prefs({
  ReminderSettings? reminders,
  bool place = true,
  PrayerPreferences? base,
}) {
  var p = base ?? PrayerPreferences();
  if (place) p = p.withLocation(_cairo.toLocation('ar'));
  return p.withReminders(reminders ?? ReminderSettings(enabled: true));
}

PrayerFixture _fixture({
  ReminderSettings? reminders,
  bool place = true,
  DateTime? now,
  AppSettings appSettings = const AppSettings(),
}) => PrayerFixture(
  saved: _prefs(reminders: reminders, place: place),
  now: now ?? _now,
  appSettings: appSettings,
);

void main() {
  group('what gets scheduled', () {
    test('nothing while reminders are off', () async {
      final f = _fixture(reminders: ReminderSettings());
      final status = await f.services.reminders.reconcile();
      expect(f.notifications.held, isEmpty);
      expect(status.scheduled, 0);
    });

    test(
      'five times a day for a week, all in the future, soonest first',
      () async {
        final f = _fixture();
        final status = await f.services.reminders.reconcile();
        final held = f.notifications.sorted;
        expect(held.length, inInclusiveRange(30, 40));
        expect(status.scheduled, held.length);
        expect(held.first.fireAt.isAfter(_now), isTrue);
        // The first one is today's Asr (Dhuhr has passed): 16:08 in Cairo is 13:08 UTC.
        final first = NotificationPayload.decode(
          PendingEntry(id: held.first.id, payload: held.first.payload),
        )!;
        expect(first.key, 'asr');
        expect(status.next, isNotNull);
        expect(status.next!.key, 'asr');
        expect(
          held.last.fireAt.isBefore(_now.add(const Duration(days: 8))),
          isTrue,
        );
      },
    );

    test('each reminder fires at exactly the calculated time', () async {
      final f = _fixture();
      await f.services.reminders.reconcile();
      const calculator = AdhanPrayerTimesCalculator();
      for (final h in f.notifications.sorted) {
        final n = NotificationPayload.decode(
          PendingEntry(id: h.id, payload: h.payload),
        )!;
        final day = calculator
            .calculate(
              location: _cairo.point.rounded(),
              date: DateTime.utc(h.fireAt.year, h.fireAt.month, h.fireAt.day),
              settings: CalculationSettings(),
            )
            .value;
        // The same calendar day in UTC holds the prayer for Cairo (UTC+2 or +3).
        expect(
          h.fireAt,
          day[Prayer.values.byName(n.key)],
          reason: '${n.key} ${h.fireAt}',
        );
      }
    });

    test('only the chosen prayers', () async {
      final f = _fixture(
        reminders: ReminderSettings(enabled: true, prayers: {Prayer.fajr}),
      );
      await f.services.reminders.reconcile();
      final keys = {
        for (final h in f.notifications.sorted)
          NotificationPayload.decode(
            PendingEntry(id: h.id, payload: h.payload),
          )!.key,
      };
      expect(keys, {'fajr'});
    });

    test('sunrise is only there when asked for', () async {
      final f = _fixture(
        reminders: ReminderSettings(
          enabled: true,
          prayers: {...ReminderSettings.defaultPrayers, Prayer.sunrise},
        ),
      );
      await f.services.reminders.reconcile();
      final titles = {
        for (final h in f.notifications.held.values) h.content.title,
      };
      expect(titles, contains('الشروق الآن'));
    });

    test('a lead time moves the reminder earlier', () async {
      final f0 = _fixture();
      await f0.services.reminders.reconcile();
      final f10 = _fixture(
        reminders: ReminderSettings(enabled: true, leadMinutes: 10),
      );
      await f10.services.reminders.reconcile();
      final at = f0.notifications.sorted.first.fireAt;
      final early = f10.notifications.sorted.first.fireAt;
      expect(at.difference(early), const Duration(minutes: 10));
    });
  });

  group('what it says', () {
    test(
      'at the time: just which prayer, in the language and with no body',
      () async {
        final f = _fixture();
        await f.services.reminders.reconcile();
        final first = f.notifications.sorted.first.content;
        expect(first.title, 'حان وقت صلاة العصر');
        expect(first.body, isNull);
      },
    );

    test('English', () async {
      final f = _fixture(
        appSettings: const AppSettings(language: AppLanguage.english),
      );
      await f.services.reminders.reconcile();
      expect(f.notifications.sorted.first.content.title, 'Time for Asr prayer');
    });

    test(
      'before the time: how long, and when, in Arabic-Indic digits',
      () async {
        final f = _fixture(
          reminders: ReminderSettings(enabled: true, leadMinutes: 10),
        );
        await f.services.reminders.reconcile();
        final first = f.notifications.sorted.first.content;
        expect(first.title, 'صلاة العصر بعد ١٠ دقائق');
        expect(first.body, matches(RegExp(r'^[٠-٩]{1,2}:[٠-٩]{2} م$')));
      },
    );

    test('with Western digits and the 24-hour clock', () async {
      final f = PrayerFixture(
        saved: _prefs(
          reminders: ReminderSettings(enabled: true, leadMinutes: 15),
        ),
        now: _now,
        appSettings: const AppSettings(digits: DigitStyle.western),
        use24Hour: true,
      );
      await f.services.reminders.reconcile();
      final first = f.notifications.sorted.first.content;
      expect(first.title, 'صلاة العصر بعد 15 دقيقة');
      expect(first.body, matches(RegExp(r'^\d{2}:\d{2}$')));
    });

    test('never names the place or carries the position', () async {
      final f = _fixture(
        reminders: ReminderSettings(enabled: true, leadMinutes: 5),
      );
      await f.services.reminders.reconcile();
      for (final h in f.notifications.held.values) {
        final text = '${h.content.title} ${h.content.body} ${h.payload}';
        expect(text, isNot(contains('القاهرة')));
        expect(text, isNot(contains('Cairo')));
        expect(text, isNot(contains('30.0')));
        expect(text, isNot(contains('31.2')));
      }
    });

    test('sound and vibration follow the choice', () async {
      final f = _fixture(
        reminders: ReminderSettings(
          enabled: true,
          sound: NotificationSound.silent,
          vibrate: false,
        ),
      );
      await f.services.reminders.reconcile();
      for (final h in f.notifications.held.values) {
        expect(h.content.sound, NotificationSound.silent);
        expect(h.content.vibrate, isFalse);
      }
    });

    test(
      'the platform gets the words for its own settings screen, in Arabic',
      () async {
        final f = _fixture();
        await f.services.reminders.reconcile();
        expect(f.notifications.labels!.soundAndVibration, 'تذكيرات الصلاة');
        expect(f.notifications.labels!.silent, contains('صامتة'));
      },
    );
  });

  group('staying in line with the settings', () {
    test('running it again changes nothing', () async {
      final f = _fixture();
      await f.services.reminders.reconcile();
      final schedules = f.notifications.schedules;
      final cancels = f.notifications.cancels;
      final status = await f.services.reminders.reconcile();
      expect(f.notifications.schedules, schedules);
      expect(f.notifications.cancels, cancels);
      expect(status.scheduled, f.notifications.held.length);
    });

    test('two runs at once do not duplicate anything', () async {
      final f = _fixture();
      await Future.wait([
        f.services.reminders.reconcile(),
        f.services.reminders.reconcile(),
        f.services.reminders.reconcile(),
      ]);
      expect(f.notifications.schedules, f.notifications.held.length);
    });

    test('switching reminders off removes them all', () async {
      final f = _fixture();
      await f.services.reminders.reconcile();
      expect(f.notifications.held, isNotEmpty);
      await f.preferences.save(
        f.preferences.stored.withReminders(ReminderSettings()),
      );
      await f.services.reminders.reconcile();
      expect(f.notifications.held, isEmpty);
    });

    test('turning a prayer off removes only that prayer', () async {
      final f = _fixture();
      await f.services.reminders.reconcile();
      final before = f.notifications.held.length;
      await f.preferences.save(
        f.preferences.stored.withReminders(
          ReminderSettings(
            enabled: true,
            prayers: {Prayer.fajr, Prayer.dhuhr, Prayer.maghrib, Prayer.isha},
          ),
        ),
      );
      await f.services.reminders.reconcile();
      final keys = {
        for (final h in f.notifications.held.values)
          NotificationPayload.decode(
            PendingEntry(id: h.id, payload: h.payload),
          )!.key,
      };
      expect(keys, isNot(contains('asr')));
      expect(f.notifications.held.length, lessThan(before));
    });

    test('a new calculation method replaces the times', () async {
      final f = _fixture();
      await f.services.reminders.reconcile();
      final before = f.notifications.sorted.map((h) => h.fireAt).toList();
      await f.preferences.save(
        f.preferences.stored.withMethod(CalculationMethodId.northAmerica),
      );
      await f.services.reminders.reconcile();
      final after = f.notifications.sorted.map((h) => h.fireAt).toList();
      expect(after, isNot(before));
      expect(after.length, before.length);
    });

    test('a new place replaces the times', () async {
      final f = _fixture();
      await f.services.reminders.reconcile();
      final before = f.notifications.sorted.first.fireAt;
      await f.preferences.save(
        f.preferences.stored.withLocation(_newYork.toLocation('ar')),
      );
      await f.services.reminders.reconcile();
      expect(f.notifications.sorted.first.fireAt, isNot(before));
    });

    test('a new language rewrites the text under the same ids', () async {
      final f = _fixture();
      await f.services.reminders.reconcile();
      final ids = f.notifications.held.keys.toSet();
      final english = ReminderCoordinator(
        preferences: f.preferences,
        calculator: const AdhanPrayerTimesCalculator(),
        gateway: f.notifications,
        loadAppSettings: () async =>
            const AppSettings(language: AppLanguage.english),
        environment: () => const ReminderEnvironment(
          deviceLanguageCode: 'ar',
          use24Hour: false,
        ),
        clock: f.clock,
      );
      await english.reconcile();
      expect(f.notifications.held.keys.toSet(), ids);
      expect(f.notifications.sorted.first.content.title, 'Time for Asr prayer');
    });

    test(
      'the device language is used when the app follows the device',
      () async {
        final f = _fixture();
        final coordinator = ReminderCoordinator(
          preferences: f.preferences,
          calculator: const AdhanPrayerTimesCalculator(),
          gateway: f.notifications,
          loadAppSettings: () async => const AppSettings(),
          environment: () => const ReminderEnvironment(
            deviceLanguageCode: 'en',
            use24Hour: false,
          ),
          clock: f.clock,
        );
        await coordinator.reconcile();
        expect(
          f.notifications.sorted.first.content.title,
          'Time for Asr prayer',
        );
      },
    );

    test('a day later the passed ones go and the next day is added', () async {
      final f = _fixture();
      await f.services.reminders.reconcile();
      final before = f.notifications.held.length;
      f.clock.advance(const Duration(days: 1));
      await f.services.reminders.reconcile();
      final held = f.notifications.sorted;
      expect(held.every((h) => h.fireAt.isAfter(f.clock.now())), isTrue);
      expect(held.length, inInclusiveRange(before - 2, before + 2));
      // The window moved forward a day, so something beyond the first window is now scheduled.
      expect(
        held.last.fireAt.isAfter(_now.add(const Duration(days: 7))),
        isTrue,
      );
    });

    test(
      'across the end of Egypt\'s summer time every reminder is still at the calculated instant',
      () async {
        // Summer time ends on 29 October 2026, so the clock on the wall moves an hour while the
        // sun does not: the instants must follow the sun.
        final f = _fixture(now: DateTime.utc(2026, 10, 25, 10));
        await f.services.reminders.reconcile();
        const calculator = AdhanPrayerTimesCalculator();
        var checked = 0;
        for (final h in f.notifications.sorted) {
          final n = NotificationPayload.decode(
            PendingEntry(id: h.id, payload: h.payload),
          )!;
          final day = calculator
              .calculate(
                location: _cairo.point.rounded(),
                date: DateTime.utc(h.fireAt.year, h.fireAt.month, h.fireAt.day),
                settings: CalculationSettings(),
              )
              .value;
          expect(h.fireAt, day[Prayer.values.byName(n.key)]);
          checked++;
        }
        expect(checked, greaterThan(30));
      },
    );
  });

  group('exact timing', () {
    test('is off by default: reminders are not exact', () async {
      final f = _fixture();
      await f.services.reminders.reconcile();
      expect(f.notifications.held.values.every((h) => !h.exact), isTrue);
    });

    test('when asked for and allowed, every reminder is exact', () async {
      final f = _fixture(
        reminders: ReminderSettings(enabled: true, exactTiming: true),
      );
      final status = await f.services.reminders.reconcile();
      expect(f.notifications.held.values.every((h) => h.exact), isTrue);
      expect(status.exactDenied, isFalse);
    });

    test('when asked for but not allowed, it falls back and says so', () async {
      final f = _fixture(
        reminders: ReminderSettings(enabled: true, exactTiming: true),
      );
      f.notifications.exactAllowed = false;
      final status = await f.services.reminders.reconcile();
      expect(f.notifications.held, isNotEmpty);
      expect(f.notifications.held.values.every((h) => !h.exact), isTrue);
      expect(status.exactDenied, isTrue);
    });

    test('switching it on or off rewrites the reminders in place', () async {
      final f = _fixture();
      await f.services.reminders.reconcile();
      final ids = f.notifications.held.keys.toSet();
      await f.preferences.save(
        f.preferences.stored.withReminders(
          ReminderSettings(enabled: true, exactTiming: true),
        ),
      );
      await f.services.reminders.reconcile();
      expect(f.notifications.held.keys.toSet(), ids);
      expect(f.notifications.held.values.every((h) => h.exact), isTrue);
    });
  });

  group('when it cannot go ahead', () {
    test('no place yet: nothing to remind about, and it says so', () async {
      final f = _fixture(place: false);
      final status = await f.services.reminders.reconcile();
      expect(status.needsPlace, isTrue);
      expect(f.notifications.held, isEmpty);
    });

    test(
      'notifications turned off in the system: nothing is scheduled, and it says so',
      () async {
        final f = _fixture();
        f.notifications.allowed = false;
        final status = await f.services.reminders.reconcile();
        expect(status.notificationsAllowed, isFalse);
        expect(f.notifications.held, isEmpty);
      },
    );

    test(
      'allowing them later brings the reminders back on the next run',
      () async {
        final f = _fixture();
        f.notifications.allowed = false;
        await f.services.reminders.reconcile();
        f.notifications.allowed = true;
        final status = await f.services.reminders.reconcile();
        expect(status.notificationsAllowed, isTrue);
        expect(f.notifications.held, isNotEmpty);
      },
    );

    test('a platform that fails does not throw', () async {
      final f = _fixture();
      f.notifications.failPending = true;
      final status = await f.services.reminders.reconcile();
      expect(status.failed, greaterThan(0));
      expect((await f.services.reminders.status()).failed, greaterThan(0));
    });

    test('some failures are reported and the rest still go through', () async {
      final f = _fixture();
      await f.services.reminders.reconcile();
      final ids = f.notifications.held.keys.toList();
      f.notifications.held.clear();
      f.notifications.failScheduleFor.add(ids.first);
      final status = await f.services.reminders.reconcile();
      expect(status.failed, 1);
      expect(f.notifications.held.length, ids.length - 1);
    });

    test(
      'a place where nothing can be calculated schedules nothing and does not crash',
      () async {
        final f = PrayerFixture(
          saved: PrayerPreferences()
              .withLocation(_cairo.toLocation('ar'))
              .withReminders(ReminderSettings(enabled: true)),
          now: DateTime.utc(2026, 6, 21, 10),
        );
        await f.preferences.save(
          f.preferences.stored.withLocation(
            PrayerLocation(
              point: GeoPoint(78.22, 15.63),
              source: LocationSource.manual,
              zoneId: 'Europe/Oslo',
            ),
          ),
        );
        final status = await f.services.reminders.reconcile();
        expect(f.notifications.held, isEmpty);
        expect(status.failed, 0);
      },
    );
  });

  group('the test reminder', () {
    test('shows now, with the chosen sound', () async {
      final f = _fixture(
        reminders: ReminderSettings(
          enabled: true,
          sound: NotificationSound.silent,
          vibrate: false,
        ),
      );
      await f.services.reminders.sendTest();
      expect(f.notifications.shown, hasLength(1));
      expect(f.notifications.shown.single.title, 'تذكير تجريبي');
      expect(f.notifications.shown.single.sound, NotificationSound.silent);
      expect(f.notifications.shown.single.vibrate, isFalse);
    });
  });

  group('cancelling', () {
    test('cancelAll removes what the app scheduled and nothing else', () async {
      final f = _fixture();
      f.notifications.foreign.add(const PendingEntry(id: 3, payload: 'x'));
      await f.services.reminders.reconcile();
      await f.services.reminders.cancelAll();
      expect(f.notifications.held, isEmpty);
      expect(f.notifications.foreign, hasLength(1));
    });
  });
}
