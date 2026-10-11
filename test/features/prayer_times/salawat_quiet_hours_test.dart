import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/notifications/notification_gateway.dart';
import 'package:mynewapp/core/notifications/notification_planner.dart';
import 'package:mynewapp/core/notifications/notification_sync.dart';
import 'package:mynewapp/core/notifications/planned_notification.dart';
import 'package:mynewapp/core/notifications/quiet_hours.dart';
import 'package:mynewapp/core/time/zone.dart';
import 'package:mynewapp/features/prayer_times/data/prayer_preferences_repository_impl.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';
import 'package:mynewapp/features/prayer_times/domain/reminder_plan_builder.dart';
import 'package:mynewapp/features/prayer_times/domain/reminder_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/salawat_settings.dart';
import 'package:mynewapp/features/prayer_times/presentation/salawat_wording.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/notification_fakes.dart';
import '../../support/prayer_fakes.dart';
import '../../support/time_support.dart';

const _cairoTime = FixedOffsetZone(Duration(hours: 3));

// 9 October 2026, 10:00 UTC: 13:00 on a phone set to UTC+3.
final _now = DateTime.utc(2026, 10, 9, 10);

DateTime _local(int day, int hour, [int minute = 0]) => DateTime.utc(
  2026,
  10,
  day,
  hour,
  minute,
).subtract(const Duration(hours: 3));

PlannedNotification _decode(FakeScheduled s) =>
    NotificationPayload.decode(PendingEntry(id: s.id, payload: s.payload))!;

void main() {
  group('approved wording', () {
    test('the text at the scheduled time is exactly the approved one', () {
      expect(salawatNowText, 'حان وقت الصلاة على النبي ﷺ');
    });

    test('the earlier reminder follows the approved template', () {
      const ar = Digits(arabicIndic: true);
      const west = Digits(arabicIndic: false);
      expect(salawatSoonText(5, ar), 'الصلاة على النبي ﷺ بعد ٥ دقائق');
      expect(salawatSoonText(10, west), 'الصلاة على النبي ﷺ بعد 10 دقائق');
      expect(salawatSoonText(15, west), 'الصلاة على النبي ﷺ بعد 15 دقيقة');
    });
  });

  group('salawat settings', () {
    test('off by default, every two hours from 9:00 to 21:00', () {
      final s = SalawatSettings();
      expect(s.enabled, isFalse);
      expect(s.minutesOfDay, [540, 660, 780, 900, 1020, 1140, 1260]);
    });

    test('the window includes its end when the interval lands on it', () {
      final s = SalawatSettings(
        intervalMinutes: 360,
        windowStartMinute: 6 * 60,
        windowEndMinute: 18 * 60,
      );
      expect(s.minutesOfDay, [360, 720, 1080]);
    });

    test('values outside the options are refused', () {
      expect(() => SalawatSettings(intervalMinutes: 45), throwsArgumentError);
      expect(() => SalawatSettings(leadMinutes: 7), throwsArgumentError);
      expect(
        () => SalawatSettings(windowStartMinute: 600, windowEndMinute: 600),
        throwsArgumentError,
      );
      expect(
        () => SalawatSettings(windowStartMinute: 600, windowEndMinute: 1440),
        throwsArgumentError,
      );
    });
  });

  group('quiet hours setting', () {
    test('off, or start equal to end, means no quiet period', () {
      expect(ReminderSettings().quietHours, isNull);
      expect(
        ReminderSettings(
          quietEnabled: true,
          quietStartMinute: 600,
          quietEndMinute: 600,
        ).quietHours,
        isNull,
      );
    });

    test('on, it can cross midnight', () {
      final q = ReminderSettings(quietEnabled: true).quietHours!;
      expect(q.crossesMidnight, isTrue);
      expect(q.contains(23 * 60), isTrue);
      expect(q.contains(5 * 60 + 59), isTrue);
      expect(q.contains(6 * 60), isFalse, reason: 'the end is not quiet');
      expect(q.contains(22 * 60), isTrue, reason: 'the start is quiet');
    });

    test('times outside the day are refused', () {
      expect(
        () => ReminderSettings(quietStartMinute: 1440),
        throwsArgumentError,
      );
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

    test('salawat and quiet hours round-trip', () async {
      final r = await repo();
      final saved = PrayerPreferences().withReminders(
        ReminderSettings(
          quietEnabled: true,
          quietStartMinute: 23 * 60,
          quietEndMinute: 5 * 60 + 30,
          quietForPrayers: true,
          salawat: SalawatSettings(
            enabled: true,
            intervalMinutes: 180,
            windowStartMinute: 8 * 60,
            windowEndMinute: 20 * 60,
            leadMinutes: 10,
          ),
        ),
      );
      await r.save(saved);
      expect((await r.load()).reminders, saved.reminders);
    });

    test('settings saved before this version load as off', () async {
      final r = await repo({
        PrayerPreferencesRepositoryImpl.storageKey:
            '{"version":1,"reminders":{"enabled":true,"prayers":["fajr"]}}',
      });
      final loaded = (await r.load()).reminders;
      expect(loaded.salawat, SalawatSettings());
      expect(loaded.quietEnabled, isFalse);
      expect(loaded.quietForPrayers, isFalse);
    });

    test('a damaged salawat entry falls back to the defaults', () async {
      final r = await repo({
        PrayerPreferencesRepositoryImpl.storageKey:
            '{"version":1,"reminders":{"salawat":{"enabled":true,"interval":7,'
            '"start":900,"end":100,"lead":"x"}}}',
      });
      expect((await r.load()).reminders.salawat, SalawatSettings());
    });
  });

  group('planning salawat', () {
    test('two days of reminders on the phone\'s clock, below prayers', () {
      final c = ReminderPlanBuilder.salawatCandidates(
        settings: SalawatSettings(enabled: true),
        zone: _cairoTime,
        now: _now,
        signature: 's',
      );
      expect(c, hasLength(14));
      expect(c.first.fireAt, _local(9, 9));
      expect(c.last.fireAt, _local(10, 21));
      expect(
        c.every(
          (x) =>
              x.kind == NotificationKind.salawat &&
              x.respectsQuietHours &&
              x.priority < ReminderPlanBuilder.prayerPriority,
        ),
        isTrue,
      );
    });

    test('the optional earlier reminder comes before each one', () {
      final c = ReminderPlanBuilder.salawatCandidates(
        settings: SalawatSettings(enabled: true, leadMinutes: 10),
        zone: _cairoTime,
        now: _now,
        signature: 's',
      );
      expect(c, hasLength(28));
      final soon = c.where((x) => x.key == ReminderPlanBuilder.salawatSoonKey);
      expect(soon.first.fireAt, _local(9, 8, 50));
    });

    test('nothing when off', () {
      expect(
        ReminderPlanBuilder.salawatCandidates(
          settings: SalawatSettings(),
          zone: _cairoTime,
          now: _now,
          signature: 's',
        ),
        isEmpty,
      );
    });

    test('on a daylight-saving day the times stay on the wall clock', () {
      // Clocks go forward at 00:00 UTC on 10 October in this scripted zone (+2 to +3).
      final zone = ScriptedZone(const Duration(hours: 2), [
        (DateTime.utc(2026, 10, 10), const Duration(hours: 3)),
      ]);
      final c = ReminderPlanBuilder.salawatCandidates(
        settings: SalawatSettings(enabled: true, intervalMinutes: 360),
        zone: zone,
        now: DateTime.utc(2026, 10, 9, 0),
        signature: 's',
      );
      for (final x in c) {
        expect(zone.minuteOfDayAt(x.fireAt) % 60, 0);
        expect([540, 900, 1260], contains(zone.minuteOfDayAt(x.fireAt)));
      }
    });
  });

  group('quiet hours in the planner', () {
    NotificationCandidate candidate(
      NotificationKind kind,
      DateTime at, {
      bool quiet = true,
    }) => NotificationCandidate(
      kind: kind,
      key: kind.name,
      fireAt: at,
      respectsQuietHours: quiet,
    );

    test('read on the phone\'s clock, not the prayer place\'s', () {
      // The prayer place is in UTC+0, the phone in UTC+3: 20:00 UTC is 23:00 on the phone.
      final plan =
          NotificationPlanner(
            zone: const FixedOffsetZone(Duration.zero),
            quietZone: _cairoTime,
            quietHours: const QuietHours(
              startMinute: 22 * 60,
              endMinute: 6 * 60,
            ),
          ).plan([
            candidate(NotificationKind.salawat, DateTime.utc(2026, 10, 9, 20)),
          ], now: _now);
      expect(plan.items, isEmpty);
      expect(plan.dropped.single.reason, DropReason.quietHours);
    });

    test('prayer reminders are never dropped by quiet hours', () {
      final plan =
          NotificationPlanner(
            zone: _cairoTime,
            quietZone: _cairoTime,
            quietHours: const QuietHours(startMinute: 0, endMinute: 23 * 60),
          ).plan([
            candidate(NotificationKind.prayer, _local(9, 18), quiet: false),
            candidate(NotificationKind.salawat, _local(9, 18)),
          ], now: _now);
      expect(plan.items.single.kind, NotificationKind.prayer);
    });
  });

  group('the coordinator', () {
    PrayerFixture fixture(ReminderSettings reminders, {bool place = true}) {
      final cairo = realCityCatalog().cities.firstWhere(
        (c) => c.nameEn == 'Cairo',
      );
      var prefs = PrayerPreferences();
      if (place) prefs = prefs.withLocation(cairo.toLocation('ar'));
      final f = PrayerFixture(saved: prefs.withReminders(reminders), now: _now);
      return f;
    }

    List<PlannedNotification> salawat(PrayerFixture f) => [
      for (final s in f.notifications.sorted)
        if (_decode(s).kind == NotificationKind.salawat) _decode(s),
    ];

    test('salawat alone needs no place and uses the approved text', () async {
      final f = fixture(
        ReminderSettings(salawat: SalawatSettings(enabled: true)),
        place: false,
      );
      final status = await f.services.reminders.reconcile();
      final held = f.notifications.sorted;
      expect(held, isNotEmpty);
      expect(status.needsPlace, isFalse);
      expect(held.every((s) => s.content.title == salawatNowText), isTrue);
      // Today's 13:00 has started (it is 13:00 exactly), so the first is at 15:00 on the phone.
      expect(held.first.fireAt, _local(9, 15));
    });

    test('prayers and salawat together; prayers keep their place', () async {
      final f = fixture(
        ReminderSettings(
          enabled: true,
          salawat: SalawatSettings(
            enabled: true,
            intervalMinutes: 60,
            leadMinutes: 5,
          ),
        ),
      );
      await f.services.reminders.reconcile();
      final all = [for (final s in f.notifications.sorted) _decode(s)];
      expect(all.length, lessThanOrEqualTo(60));
      final prayers = all.where((n) => n.kind == NotificationKind.prayer);
      expect(
        prayers.length,
        greaterThanOrEqualTo(30),
        reason: 'a week of prayers',
      );
      expect(salawat(f), isNotEmpty);
    });

    test('quiet hours hold salawat back and say how many', () async {
      final f = fixture(
        ReminderSettings(
          quietEnabled: true,
          quietStartMinute: 14 * 60,
          quietEndMinute: 20 * 60,
          salawat: SalawatSettings(enabled: true),
        ),
        place: false,
      );
      final status = await f.services.reminders.reconcile();
      final times = [
        for (final n in salawat(f)) _cairoTime.minuteOfDayAt(n.fireAt),
      ];
      expect(times.where((m) => m >= 14 * 60 && m < 20 * 60), isEmpty);
      // Held back: 15, 17 and 19 today, and the same tomorrow.
      expect(status.heldBackByQuietHours, 6);
    });

    test(
      'with the switch on, prayer reminders in quiet hours arrive silently',
      () async {
        final f = fixture(
          ReminderSettings(
            enabled: true,
            quietEnabled: true,
            quietStartMinute: 16 * 60,
            quietEndMinute: 17 * 60,
            quietForPrayers: true,
          ),
        );
        await f.services.reminders.reconcile();
        final asr = f.notifications.sorted.firstWhere(
          (s) => _decode(s).key == 'asr',
        );
        // Asr in Cairo on 9 October is just after 16:00: inside the quiet hour.
        expect(
          _cairoTime.minuteOfDayAt(asr.fireAt),
          inInclusiveRange(960, 1019),
        );
        expect(asr.content.sound, NotificationSound.silent);
        expect(asr.content.vibrate, isFalse);
        final maghrib = f.notifications.sorted.firstWhere(
          (s) => _decode(s).key == 'maghrib',
        );
        expect(maghrib.content.sound, NotificationSound.system);
      },
    );

    test(
      'without the switch, quiet hours leave prayer reminders as they are',
      () async {
        final f = fixture(
          ReminderSettings(
            enabled: true,
            quietEnabled: true,
            quietStartMinute: 0,
            quietEndMinute: 23 * 60 + 59,
          ),
        );
        final status = await f.services.reminders.reconcile();
        expect(status.heldBackByQuietHours, 0);
        expect(
          f.notifications.sorted.every(
            (s) => s.content.sound == NotificationSound.system,
          ),
          isTrue,
        );
      },
    );

    test('switching everything off removes salawat too', () async {
      final f = fixture(
        ReminderSettings(salawat: SalawatSettings(enabled: true)),
        place: false,
      );
      await f.services.reminders.reconcile();
      expect(f.notifications.held, isNotEmpty);
      await f.preferences.save(
        PrayerPreferences().withReminders(ReminderSettings()),
      );
      await f.services.reminders.reconcile();
      expect(f.notifications.held, isEmpty);
    });
  });
}
