import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/review_coordinator.dart';
import 'package:mynewapp/features/app_review/domain/review_policy.dart';
import 'package:mynewapp/features/app_review/domain/review_state.dart';

import '../support/review_fakes.dart';
import '../support/time_support.dart';

final _start = DateTime.utc(2026, 10, 1, 9);

/// A memory that only waits for one more qualifying moment.
ReviewState _ready() => ReviewState(
  firstSeen: _start,
  usageDays: const ['2026-10-01', '2026-10-04', '2026-10-08', '2026-10-10'],
  actions: 20,
  pendingAction: true,
);

class _Setup {
  _Setup({
    ReviewState? state,
    bool automatic = true,
    Future<bool> Function()? canInterrupt,
    String? version = '1.1.0+2',
  }) : store = InMemoryReviewStore(state ?? _ready()),
       gateway = FakeReviewGateway(),
       clock = FakeClock(_start.add(const Duration(days: 10))) {
    coordinator = ReviewCoordinator(
      store: store,
      gateway: gateway,
      versions: FakeAppVersion(version),
      clock: clock,
      automatic: automatic,
      canInterrupt: canInterrupt,
    );
  }

  final InMemoryReviewStore store;
  final FakeReviewGateway gateway;
  final FakeClock clock;
  late final ReviewCoordinator coordinator;
}

void main() {
  group('asking at the home screen', () {
    test('asks the system once, recording it first', () async {
      final s = _Setup();
      expect(await s.coordinator.maybeRequest(), ReviewDecision.eligible);
      expect(s.gateway.requests, 1);
      final saved = s.store.saved!;
      expect(saved.pendingAction, isFalse);
      expect(saved.requests.single.version, '1.1.0+2');
      expect(saved.requests.single.at, s.clock.now());
      expect(saved.requests.single.counted, isTrue);
    });

    test('asking again right away does nothing more', () async {
      final s = _Setup();
      await s.coordinator.maybeRequest();
      expect(
        await s.coordinator.maybeRequest(),
        ReviewDecision.noPendingAction,
      );
      expect(s.gateway.requests, 1);
    });

    test('two asks at the same moment make one request', () async {
      final s = _Setup();
      final results = await Future.wait([
        s.coordinator.maybeRequest(),
        s.coordinator.maybeRequest(),
      ]);
      expect(results.whereType<ReviewDecision>(), [ReviewDecision.eligible]);
      expect(s.gateway.requests, 1);
    });

    test(
      'a system that declines is not retried and not a counted request',
      () async {
        final s = _Setup()..gateway.available = false;
        expect(await s.coordinator.maybeRequest(), ReviewDecision.eligible);
        expect(s.gateway.requests, 0);
        final saved = s.store.saved!;
        expect(saved.requests.single.counted, isFalse);
        expect(saved.pendingAction, isFalse);
        // Another qualifying action later does not bring it straight back.
        s.coordinator.recordAction('hadith:99');
        await s.coordinator.state;
        expect(await s.coordinator.maybeRequest(), ReviewDecision.sameVersion);
        expect(s.gateway.requests, 0);
        expect(s.gateway.availabilityChecks, 1);
      },
    );

    test('rules are read when asking, not when the action happened', () async {
      final s = _Setup(
        state: _ready().copyWith(
          requests: [
            ReviewRequest(
              at: _start.add(const Duration(days: 9)),
              version: '1.0.0+1',
            ),
          ],
        ),
      );
      expect(await s.coordinator.maybeRequest(), ReviewDecision.cooldown);
      // Time passes; the same pending action is now allowed.
      s.clock.set(_start.add(const Duration(days: 9 + 90)));
      expect(await s.coordinator.maybeRequest(), ReviewDecision.eligible);
      expect(s.gateway.requests, 1);
    });

    test(
      'automatic requests off: nothing is asked, nothing recorded',
      () async {
        final s = _Setup(automatic: false);
        expect(await s.coordinator.maybeRequest(), isNull);
        expect(s.gateway.requests, 0);
        expect(s.gateway.availabilityChecks, 0);
        expect(s.store.saves, 0);
      },
    );

    test(
      'something to leave alone: nothing is asked, nothing recorded',
      () async {
        final s = _Setup(canInterrupt: () async => false);
        expect(await s.coordinator.maybeRequest(), isNull);
        expect(s.gateway.requests, 0);
        expect(s.store.saves, 0);
        // The waiting action is kept for a calmer moment.
        expect((await s.coordinator.state).pendingAction, isTrue);
      },
    );

    test('a calm moment later asks after all', () async {
      var calm = false;
      final s = _Setup(canInterrupt: () async => calm);
      expect(await s.coordinator.maybeRequest(), isNull);
      calm = true;
      expect(await s.coordinator.maybeRequest(), ReviewDecision.eligible);
      expect(s.gateway.requests, 1);
    });

    test('a version that cannot be read never asks', () async {
      final s = _Setup(version: null);
      expect(await s.coordinator.maybeRequest(), ReviewDecision.unknownVersion);
      expect(s.gateway.requests, 0);
    });

    test('a failing save does not stop the request or throw', () async {
      final s = _Setup()..store.failSave = true;
      expect(await s.coordinator.maybeRequest(), ReviewDecision.eligible);
      expect(s.gateway.requests, 1);
      // Remembered in memory for this run, so it does not ask twice.
      expect(
        await s.coordinator.maybeRequest(),
        ReviewDecision.noPendingAction,
      );
    });

    test('too few actions: no request, the memory is untouched', () async {
      final s = _Setup(state: _ready().copyWith(actions: 3));
      expect(await s.coordinator.maybeRequest(), ReviewDecision.tooFewActions);
      expect(s.gateway.requests, 0);
      expect(s.store.saves, 0);
    });
  });

  group('recording', () {
    test('starting records the first time and today', () async {
      final s = _Setup(state: ReviewState.fresh);
      await s.coordinator.start();
      final saved = s.store.saved!;
      expect(saved.firstSeen, s.clock.now());
      expect(saved.usageDays, ['2026-10-11']);
    });

    test('many quick actions are all kept, in order, none lost', () async {
      final s = _Setup(state: ReviewState.fresh);
      await s.coordinator.start();
      for (var i = 0; i < 30; i++) {
        s.coordinator.recordAction('hadith:$i');
      }
      final state = await s.coordinator.state;
      expect(state.actions, 30);
      expect(s.store.saved!.actions, 30);
    });

    test('the same action twice in a day counts once', () async {
      final s = _Setup(state: ReviewState.fresh);
      s.coordinator
        ..recordAction('hadith:1')
        ..recordAction('hadith:1')
        ..recordAction('tasbeeh:round')
        ..recordAction('tasbeeh:round');
      expect((await s.coordinator.state).actions, 2);
    });

    test('an action never throws, even when saving fails', () async {
      final s = _Setup(state: ReviewState.fresh)..store.failSave = true;
      s.coordinator.recordAction('hadith:1');
      expect((await s.coordinator.state).actions, 1);
    });

    test('a damaged memory waits instead of asking', () async {
      final s = _Setup(state: ReviewState.fresh.copyWith(lostHistory: true));
      await s.coordinator.start();
      for (var i = 0; i < 20; i++) {
        s.coordinator.recordAction('k$i');
      }
      // Three days of use over twelve days, plenty of actions: every other rule is met.
      s.clock.advance(const Duration(days: 6));
      await s.coordinator.start();
      s.clock.advance(const Duration(days: 6));
      await s.coordinator.start();
      expect(await s.coordinator.maybeRequest(), ReviewDecision.cooldown);
      expect(s.gateway.requests, 0);
    });
  });

  group('delete all my data', () {
    test('forgets everything and starts counting from now', () async {
      final s = _Setup();
      await s.coordinator.maybeRequest();
      await s.coordinator.forget();
      expect(s.store.clears, 1);
      final state = await s.coordinator.state;
      expect(state.requests, isEmpty);
      expect(state.actions, 0);
      expect(state.pendingAction, isFalse);
      expect(state.firstSeen, s.clock.now());
      // The cached memory did not write the old data back.
      expect(s.store.saved!.actions, 0);
    });

    test('a later action starts from zero', () async {
      final s = _Setup();
      await s.coordinator.forget();
      s.coordinator.recordAction('hadith:1');
      expect((await s.coordinator.state).actions, 1);
    });
  });

  group('manual rating', () {
    test('opens the store page whatever the automatic rules say', () async {
      final s = _Setup(
        automatic: false,
        state: _ready().copyWith(
          requests: [ReviewRequest(at: _requestedAt, version: '1.1.0+2')],
        ),
      );
      expect(s.coordinator.manualAvailable, isTrue);
      await s.coordinator.rateNow();
      await s.coordinator.rateNow();
      expect(s.gateway.storeOpens, 2);
      expect(s.gateway.requests, 0);
    });

    test('is not offered where there is no store page to open', () {
      final s = _Setup()..gateway.canOpen = false;
      expect(s.coordinator.manualAvailable, isFalse);
    });

    test('does not change the automatic memory', () async {
      final s = _Setup();
      await s.coordinator.rateNow();
      expect(s.store.saves, 0);
      expect(await s.coordinator.maybeRequest(), ReviewDecision.eligible);
    });
  });
}

final _requestedAt = DateTime.utc(2026, 10, 5);
