import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/notifications/notification_planner.dart';
import 'package:mynewapp/core/notifications/planned_notification.dart';
import 'package:mynewapp/core/notifications/quiet_hours.dart';
import 'package:mynewapp/core/time/zone.dart';

import '../../support/time_support.dart';

final _now = DateTime.utc(2026, 5, 10, 12);

NotificationCandidate _c(
  String key,
  Duration after, {
  NotificationKind kind = NotificationKind.prayer,
  int priority = 0,
  bool respectsQuietHours = true,
  String signature = '',
}) => NotificationCandidate(
  kind: kind,
  key: key,
  fireAt: _now.add(after),
  priority: priority,
  respectsQuietHours: respectsQuietHours,
  signature: signature,
);

NotificationPlanner _planner({
  TimeZoneRules zone = const FixedOffsetZone(Duration.zero),
  QuietHours? quietHours,
  int maxPending = 60,
  Duration horizon = const Duration(days: 7),
  int Function(String)? hash,
}) => NotificationPlanner(
  zone: zone,
  quietHours: quietHours,
  maxPending: maxPending,
  horizon: horizon,
  hash: hash ?? fnv1a31,
);

List<DropReason> _reasons(NotificationPlan plan) => [
  for (final d in plan.dropped) d.reason,
];

void main() {
  group('window', () {
    test('keeps future notifications, sorted by time', () {
      final plan = _planner().plan([
        _c('isha', const Duration(hours: 9)),
        _c('asr', const Duration(hours: 3)),
        _c('maghrib', const Duration(hours: 6)),
      ], now: _now);
      expect([for (final i in plan.items) i.key], ['asr', 'maghrib', 'isha']);
      expect(plan.dropped, isEmpty);
    });

    test('drops the past and the present instant', () {
      final plan = _planner().plan([
        _c('past', const Duration(minutes: -1)),
        _c('now', Duration.zero),
        _c('soon', const Duration(minutes: 1)),
      ], now: _now);
      expect([for (final i in plan.items) i.key], ['soon']);
      expect(_reasons(plan), [DropReason.notInFuture, DropReason.notInFuture]);
    });

    test('drops what is beyond the horizon and keeps the boundary', () {
      final plan = _planner(horizon: const Duration(days: 2)).plan([
        _c('edge', const Duration(days: 2)),
        _c('far', const Duration(days: 2, minutes: 1)),
      ], now: _now);
      expect([for (final i in plan.items) i.key], ['edge']);
      expect(_reasons(plan), [DropReason.beyondHorizon]);
    });

    test('now may be given in local time', () {
      final local = _now.toLocal();
      final plan = _planner().plan([
        _c('x', const Duration(hours: 1)),
      ], now: local);
      expect(plan.items, hasLength(1));
    });

    test('a non-UTC fire time is rejected', () {
      expect(
        () => NotificationCandidate(
          kind: NotificationKind.prayer,
          key: 'x',
          fireAt: DateTime(2026, 5, 10, 15),
        ),
        throwsArgumentError,
      );
    });
  });

  group('quiet hours', () {
    final night = QuietHours(startMinute: 22 * 60, endMinute: 7 * 60);

    test('suppress optional notifications at night, across midnight', () {
      final planner = _planner(quietHours: night);
      // _now is 12:00 UTC; with offset 0 the fire times below are 22:30, 02:00, 06:59, 07:00.
      final plan = planner.plan([
        _c('a', const Duration(hours: 10, minutes: 30)),
        _c('b', const Duration(hours: 14)),
        _c('c', const Duration(hours: 18, minutes: 59)),
        _c('d', const Duration(hours: 19)),
      ], now: _now);
      expect([for (final i in plan.items) i.key], ['d']);
      expect(_reasons(plan), everyElement(DropReason.quietHours));
      expect(plan.dropped, hasLength(3));
    });

    test('are judged on local time, not UTC', () {
      // 20:00 UTC is 23:00 in UTC+3: quiet there, not in UTC.
      final c = _c('x', const Duration(hours: 8));
      expect(
        _planner(
          quietHours: night,
          zone: const FixedOffsetZone(Duration(hours: 3)),
        ).plan([c], now: _now).items,
        isEmpty,
      );
      expect(
        _planner(quietHours: night).plan([c], now: _now).items,
        hasLength(1),
      );
    });

    test('do not touch notifications that opt out', () {
      final plan = _planner(quietHours: night).plan([
        _c('fajr', const Duration(hours: 14), respectsQuietHours: false),
      ], now: _now);
      expect(plan.items, hasLength(1));
    });

    test('an empty quiet period suppresses nothing', () {
      final plan = _planner(
        quietHours: QuietHours(startMinute: 60, endMinute: 60),
      ).plan([_c('x', const Duration(hours: 13))], now: _now);
      expect(plan.items, hasLength(1));
    });

    test('follow the clock change: the same wall time before and after', () {
      final zone = europeLikeZone();
      final quiet = QuietHours(
        startMinute: 0,
        endMinute: 6 * 60,
      ); // 00:00-06:00 local
      final planner = _planner(quietHours: quiet, zone: zone);
      final before = DateTime.utc(2026, 3, 27);
      // 05:30 local on 28 March is 05:30 UTC (winter); on 30 March it is 04:30 UTC (summer).
      final plan = planner.plan([
        NotificationCandidate(
          kind: NotificationKind.salawat,
          key: 'winter',
          fireAt: DateTime.utc(2026, 3, 28, 5, 30),
        ),
        NotificationCandidate(
          kind: NotificationKind.salawat,
          key: 'summer',
          fireAt: DateTime.utc(2026, 3, 30, 4, 30),
        ),
        NotificationCandidate(
          kind: NotificationKind.salawat,
          key: 'summer-awake',
          fireAt: DateTime.utc(2026, 3, 30, 5, 30), // 06:30 local
        ),
      ], now: before);
      expect([for (final i in plan.items) i.key], ['summer-awake']);
    });
  });

  group('duplicates', () {
    test('the same notification asked for twice is planned once', () {
      final plan = _planner().plan([
        _c('asr', const Duration(hours: 3)),
        _c('asr', const Duration(hours: 3)),
      ], now: _now);
      expect(plan.items, hasLength(1));
      expect(_reasons(plan), [DropReason.duplicate]);
    });

    test(
      'same key and minute but a different second is the same notification',
      () {
        final plan = _planner().plan([
          _c('asr', const Duration(hours: 3)),
          _c('asr', const Duration(hours: 3, seconds: 20)),
        ], now: _now);
        expect(plan.items, hasLength(1));
      },
    );

    test('different kinds with the same key do not collide', () {
      final plan = _planner().plan([
        _c('x', const Duration(hours: 3)),
        _c('x', const Duration(hours: 3), kind: NotificationKind.tracker),
      ], now: _now);
      expect(plan.items, hasLength(2));
      expect(plan.items[0].id, isNot(plan.items[1].id));
    });
  });

  group('platform limit', () {
    test('never exceeds the limit', () {
      final plan = _planner(maxPending: 5).plan([
        for (var i = 1; i <= 20; i++) _c('k$i', Duration(minutes: i)),
      ], now: _now);
      expect(plan.items, hasLength(5));
      expect(plan.dropped, hasLength(15));
      expect(_reasons(plan), everyElement(DropReason.overLimit));
    });

    test('keeps the earliest when priorities are equal', () {
      final plan = _planner(maxPending: 3).plan([
        for (var i = 1; i <= 6; i++) _c('k$i', Duration(minutes: i)),
      ], now: _now);
      expect([for (final i in plan.items) i.key], ['k1', 'k2', 'k3']);
    });

    test('higher priority wins over earlier time', () {
      final plan = _planner(maxPending: 3).plan([
        for (var i = 1; i <= 5; i++)
          _c('salawat$i', Duration(minutes: i), kind: NotificationKind.salawat),
        _c('fajr', const Duration(days: 3), priority: 10),
        _c('dhuhr', const Duration(days: 3, hours: 6), priority: 10),
      ], now: _now);
      expect(
        [for (final i in plan.items) i.key],
        ['salawat1', 'fajr', 'dhuhr'],
      );
    });

    test('a thousand candidates give at most the limit', () {
      final plan = _planner().plan([
        for (var i = 1; i <= 1000; i++) _c('k$i', Duration(minutes: i)),
      ], now: _now);
      expect(plan.items.length, lessThanOrEqualTo(60));
    });
  });

  group('ids', () {
    test('are positive 31-bit numbers', () {
      final plan = _planner().plan([
        for (var i = 1; i <= 50; i++) _c('k$i', Duration(minutes: i)),
      ], now: _now);
      for (final item in plan.items) {
        expect(item.id, inInclusiveRange(1, 0x7fffffff));
      }
      expect({for (final i in plan.items) i.id}, hasLength(50));
    });

    test('are the same on every run and in any input order', () {
      final candidates = [
        for (var i = 1; i <= 30; i++) _c('k$i', Duration(minutes: i * 7)),
      ];
      final a = _planner().plan(candidates, now: _now);
      final b = _planner().plan(candidates.reversed, now: _now);
      expect(a.items, b.items);
    });

    test('the hash is pinned so ids never change between releases', () {
      // Published FNV-1a 32-bit test vectors, with the top bit removed.
      expect(fnv1a31(''), 0x811c9dc5 & 0x7fffffff);
      expect(fnv1a31('a'), 0xe40c292c & 0x7fffffff);
      expect(fnv1a31('foobar'), 0xbf9cf968 & 0x7fffffff);
    });

    test('a collision is resolved without losing or sharing ids', () {
      final plan = _planner(hash: (_) => 42).plan([
        for (var i = 1; i <= 5; i++) _c('k$i', Duration(minutes: i)),
      ], now: _now);
      expect({for (final i in plan.items) i.id}, {42, 43, 44, 45, 46});
    });

    test('a collision resolves the same way in any input order', () {
      final candidates = [
        for (var i = 1; i <= 5; i++) _c('k$i', Duration(minutes: i)),
      ];
      final planner = _planner(hash: (_) => 42);
      expect(
        planner.plan(candidates, now: _now).items,
        planner.plan(candidates.reversed, now: _now).items,
      );
    });

    test('the largest id wraps around to 1', () {
      final plan = _planner(hash: (_) => 0x7fffffff).plan([
        _c('a', const Duration(minutes: 1)),
        _c('b', const Duration(minutes: 2)),
      ], now: _now);
      expect({for (final i in plan.items) i.id}, {0x7fffffff, 1});
    });

    test('a hash of zero is never used', () {
      final plan = _planner(
        hash: (_) => 0,
      ).plan([_c('a', const Duration(minutes: 1))], now: _now);
      expect(plan.items.single.id, 1);
    });
  });

  group('reconciling with what is pending', () {
    final planner = _planner();
    List<NotificationCandidate> wanted() => [
      _c('asr', const Duration(hours: 3)),
      _c('maghrib', const Duration(hours: 6)),
    ];

    test('a first run schedules everything and cancels nothing', () {
      final diff = NotificationPlanner.diff(
        pending: const [],
        plan: planner.plan(wanted(), now: _now),
      );
      expect(diff.cancel, isEmpty);
      expect(diff.schedule, hasLength(2));
    });

    test('planning again changes nothing (idempotent)', () {
      final plan = planner.plan(wanted(), now: _now);
      final diff = NotificationPlanner.diff(pending: plan.items, plan: plan);
      expect(diff.isEmpty, isTrue);
    });

    test('re-planning later with the same inputs changes nothing', () {
      final first = planner.plan(wanted(), now: _now);
      final second = planner.plan(
        wanted(),
        now: _now.add(const Duration(minutes: 30)),
      );
      expect(
        NotificationPlanner.diff(pending: first.items, plan: second).isEmpty,
        isTrue,
      );
    });

    test('a turned-off prayer is cancelled', () {
      final before = planner.plan(wanted(), now: _now);
      final after = planner.plan([
        _c('asr', const Duration(hours: 3)),
      ], now: _now);
      final diff = NotificationPlanner.diff(pending: before.items, plan: after);
      expect(diff.schedule, isEmpty);
      expect(diff.cancel, [before.items.last.id]);
    });

    test('a moved time cancels the old one and schedules the new one', () {
      final before = planner.plan(wanted(), now: _now);
      final after = planner.plan([
        _c('asr', const Duration(hours: 3, minutes: 4)),
        _c('maghrib', const Duration(hours: 6)),
      ], now: _now);
      final diff = NotificationPlanner.diff(pending: before.items, plan: after);
      expect(diff.cancel, [before.items.first.id]);
      expect([for (final s in diff.schedule) s.key], ['asr']);
    });

    test('a changed sound replaces in place under the same id', () {
      final before = planner.plan([
        _c('asr', const Duration(hours: 3), signature: 'sound:a'),
      ], now: _now);
      final after = planner.plan([
        _c('asr', const Duration(hours: 3), signature: 'sound:b'),
      ], now: _now);
      final diff = NotificationPlanner.diff(pending: before.items, plan: after);
      expect(diff.cancel, isEmpty);
      expect(diff.schedule.single.id, before.items.single.id);
    });

    test('one that already fired is not rescheduled and is cleared', () {
      final before = planner.plan(wanted(), now: _now);
      final later = planner.plan(
        wanted(),
        now: _now.add(const Duration(hours: 4)),
      );
      final diff = NotificationPlanner.diff(pending: before.items, plan: later);
      expect(diff.cancel, [before.items.first.id]);
      expect(diff.schedule, isEmpty);
    });

    test('moving the reminder window forward brings new ones in', () {
      final p = _planner(horizon: const Duration(hours: 5));
      final all = [
        _c('asr', const Duration(hours: 3)),
        _c('maghrib', const Duration(hours: 6)),
      ];
      final first = p.plan(all, now: _now);
      expect(first.items, hasLength(1));
      final second = p.plan(all, now: _now.add(const Duration(hours: 2)));
      final diff = NotificationPlanner.diff(pending: first.items, plan: second);
      expect([for (final s in diff.schedule) s.key], ['maghrib']);
      expect(diff.cancel, isEmpty);
    });
  });

  test('a salawat reminder every 30 minutes across a spring-forward night', () {
    final zone = europeLikeZone();
    final planner = _planner(
      zone: zone,
      maxPending: 100,
      horizon: const Duration(days: 1),
      quietHours: QuietHours(startMinute: 22 * 60, endMinute: 7 * 60),
    );
    // Day of the change: 2026-03-29. Start at 08:00 local the day before.
    final start = zone.utcFromWallClock(DateTime.utc(2026, 3, 28, 8));
    final candidates = [
      for (var i = 1; i <= 48; i++)
        NotificationCandidate(
          kind: NotificationKind.salawat,
          key: 'interval',
          fireAt: start.add(Duration(minutes: 30 * i)),
        ),
    ];
    final plan = planner.plan(candidates, now: start);
    for (final item in plan.items) {
      final minute = zone.minuteOfDayAt(item.fireAt);
      expect(
        minute >= 7 * 60 && minute < 22 * 60,
        isTrue,
        reason: '${item.fireAt}',
      );
    }
    expect(plan.items, isNotEmpty);
  });
}
