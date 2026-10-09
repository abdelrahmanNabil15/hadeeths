import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/notifications/notification_gateway.dart';
import 'package:mynewapp/core/notifications/notification_planner.dart';
import 'package:mynewapp/core/notifications/notification_sync.dart';
import 'package:mynewapp/core/notifications/planned_notification.dart';
import 'package:mynewapp/core/time/zone.dart';

import '../../support/notification_fakes.dart';

final _now = DateTime.utc(2026, 5, 10, 12);

NotificationCandidate _c(String key, Duration after, {String signature = ''}) =>
    NotificationCandidate(
      kind: NotificationKind.prayer,
      key: key,
      fireAt: _now.add(after),
      signature: signature,
    );

NotificationPlan _plan(List<NotificationCandidate> candidates) =>
    NotificationPlanner(
      zone: const FixedOffsetZone(Duration.zero),
    ).plan(candidates, now: _now);

NotificationContent _content(PlannedNotification n) =>
    NotificationContent(title: 'to ${n.key}');

void main() {
  late FakeNotificationGateway gateway;
  late NotificationSync sync;

  setUp(() {
    gateway = FakeNotificationGateway();
    sync = NotificationSync(gateway);
  });

  group('payload', () {
    test('round-trips what the platform will hand back', () {
      final item = _plan([
        _c('asr', const Duration(hours: 3), signature: 'a|b'),
      ]).items.single;
      final decoded = NotificationPayload.decode(
        PendingEntry(id: item.id, payload: NotificationPayload.encode(item)),
      );
      expect(decoded, item);
    });

    test(
      'anything that is not ours or is damaged is ignored, never thrown',
      () {
        for (final bad in [
          null,
          '',
          'hello',
          '[]',
          '{}',
          '{"v":2,"k":"prayer","key":"x","at":1,"sig":""}',
          '{"v":1,"k":"alien","key":"x","at":1,"sig":""}',
          '{"v":1,"k":"prayer","key":5,"at":1,"sig":""}',
          '{"v":1,"k":"prayer","key":"x","at":"soon","sig":""}',
        ]) {
          expect(
            NotificationPayload.decode(PendingEntry(id: 1, payload: bad)),
            isNull,
            reason: '$bad',
          );
        }
      },
    );
  });

  group('synchronising', () {
    test('a first run schedules everything', () async {
      final plan = _plan([
        _c('asr', const Duration(hours: 3)),
        _c('maghrib', const Duration(hours: 6)),
      ]);
      final report = await sync.apply(plan, contentFor: _content);
      expect(report.scheduled, 2);
      expect(report.cancelled, 0);
      expect(report.kept, 0);
      expect(gateway.held, hasLength(2));
      expect(gateway.sorted.first.content.title, 'to asr');
    });

    test('running it again changes nothing (idempotent)', () async {
      final plan = _plan([
        _c('asr', const Duration(hours: 3)),
        _c('maghrib', const Duration(hours: 6)),
      ]);
      await sync.apply(plan, contentFor: _content);
      final schedules = gateway.schedules;
      final cancels = gateway.cancels;
      final report = await sync.apply(plan, contentFor: _content);
      expect(report.scheduled, 0);
      expect(report.cancelled, 0);
      expect(report.kept, 2);
      expect(report.pendingNow, 2);
      expect(gateway.schedules, schedules);
      expect(gateway.cancels, cancels);
    });

    test('what is no longer wanted is cancelled, the rest is kept', () async {
      await sync.apply(
        _plan([
          _c('asr', const Duration(hours: 3)),
          _c('maghrib', const Duration(hours: 6)),
        ]),
        contentFor: _content,
      );
      final report = await sync.apply(
        _plan([_c('asr', const Duration(hours: 3))]),
        contentFor: _content,
      );
      expect(report.cancelled, 1);
      expect(report.kept, 1);
      expect(gateway.held, hasLength(1));
    });

    test('a moved time replaces the old one', () async {
      await sync.apply(
        _plan([_c('asr', const Duration(hours: 3))]),
        contentFor: _content,
      );
      final report = await sync.apply(
        _plan([_c('asr', const Duration(hours: 3, minutes: 5))]),
        contentFor: _content,
      );
      expect(report.cancelled, 1);
      expect(report.scheduled, 1);
      expect(gateway.held, hasLength(1));
      expect(
        gateway.sorted.single.fireAt,
        _now.add(const Duration(hours: 3, minutes: 5)),
      );
    });

    test('a changed wording is replaced in place, without a cancel', () async {
      await sync.apply(
        _plan([_c('asr', const Duration(hours: 3), signature: 'ar')]),
        contentFor: _content,
      );
      final cancels = gateway.cancels;
      final report = await sync.apply(
        _plan([_c('asr', const Duration(hours: 3), signature: 'en')]),
        contentFor: (n) => const NotificationContent(title: 'Asr'),
      );
      expect(report.scheduled, 1);
      expect(report.cancelled, 0);
      expect(gateway.cancels, cancels);
      expect(gateway.held, hasLength(1));
      expect(gateway.sorted.single.content.title, 'Asr');
    });

    test(
      'notifications that are not the app\'s own are never touched',
      () async {
        gateway.foreign.addAll(const [
          PendingEntry(id: 7, payload: 'someone else'),
          PendingEntry(id: 8),
        ]);
        await sync.apply(
          _plan([_c('asr', const Duration(hours: 3))]),
          contentFor: _content,
        );
        await sync.apply(_plan(const []), contentFor: _content);
        expect(gateway.held, isEmpty);
        expect(gateway.foreign, hasLength(2));
        expect(await sync.cancelAll(), 0);
      },
    );

    test(
      'one failure does not stop the others, and it is tried again next time',
      () async {
        final plan = _plan([
          _c('asr', const Duration(hours: 3)),
          _c('maghrib', const Duration(hours: 6)),
        ]);
        gateway.failScheduleFor.add(plan.items.first.id);
        final report = await sync.apply(plan, contentFor: _content);
        expect(report.failed, 1);
        expect(report.scheduled, 1);
        expect(gateway.held, hasLength(1));
        gateway.failScheduleFor.clear();
        final again = await sync.apply(plan, contentFor: _content);
        expect(again.failed, 0);
        expect(again.scheduled, 1);
        expect(again.kept, 1);
        expect(gateway.held, hasLength(2));
      },
    );

    test('a refused cancel is counted and the rest still happen', () async {
      final both = _plan([
        _c('asr', const Duration(hours: 3)),
        _c('maghrib', const Duration(hours: 6)),
      ]);
      await sync.apply(both, contentFor: _content);
      gateway.failCancelFor.add(both.items.first.id);
      final report = await sync.apply(_plan(const []), contentFor: _content);
      expect(report.failed, 1);
      expect(report.cancelled, 1);
    });

    test('cancelAll removes only the app\'s notifications', () async {
      gateway.foreign.add(const PendingEntry(id: 9, payload: 'x'));
      await sync.apply(
        _plan([
          _c('asr', const Duration(hours: 3)),
          _c('maghrib', const Duration(hours: 6)),
        ]),
        contentFor: _content,
      );
      expect(await sync.cancelAll(), 2);
      expect(gateway.held, isEmpty);
      expect(gateway.foreign, hasLength(1));
    });

    test(
      'the text is built only for notifications that are handed over',
      () async {
        final plan = _plan([
          _c('asr', const Duration(hours: 3)),
          _c('maghrib', const Duration(hours: 6)),
        ]);
        await sync.apply(plan, contentFor: _content);
        var built = 0;
        await sync.apply(
          plan,
          contentFor: (n) {
            built++;
            return _content(n);
          },
        );
        expect(built, 0);
      },
    );
  });
}
