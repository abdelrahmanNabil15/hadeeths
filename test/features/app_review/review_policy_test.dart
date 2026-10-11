import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/features/app_review/domain/review_policy.dart';
import 'package:mynewapp/features/app_review/domain/review_state.dart';

const _policy = ReviewPolicy();
const _version = '1.1.0+2';
final _start = DateTime.utc(2026, 10, 1, 9);

/// A state that satisfies every rule at `_start + 10 days`: 4 days of use since install, 20
/// actions, and one waiting action.
ReviewState _ready() => ReviewState(
  firstSeen: _start,
  usageDays: const ['2026-10-01', '2026-10-04', '2026-10-08', '2026-10-10'],
  actions: 20,
  pendingAction: true,
);

final _later = _start.add(const Duration(days: 10));

void main() {
  group('the thresholds', () {
    test('a state that meets every rule is eligible', () {
      expect(
        _policy.evaluate(_ready(), _later, _version),
        ReviewDecision.eligible,
      );
    });

    test('the defaults are the agreed ones', () {
      expect(_policy.minUsageDays, 3);
      expect(_policy.minInstallDays, 5);
      expect(_policy.minActions, 15);
      expect(_policy.cooldownDays, 90);
      expect(_policy.maxRequests, 3);
    });

    test('nothing waiting means no', () {
      expect(
        _policy.evaluate(
          _ready().copyWith(pendingAction: false),
          _later,
          _version,
        ),
        ReviewDecision.noPendingAction,
      );
    });

    test('2 days of use is too few, 3 is enough', () {
      final two = _ready().copyWith(usageDays: ['2026-10-01', '2026-10-08']);
      expect(
        _policy.evaluate(two, _later, _version),
        ReviewDecision.tooFewDays,
      );
      final three = _ready().copyWith(
        usageDays: ['2026-10-01', '2026-10-08', '2026-10-10'],
      );
      expect(
        _policy.evaluate(three, _later, _version),
        ReviewDecision.eligible,
      );
    });

    test('4 days since install is too new, exactly 5 is enough', () {
      expect(
        _policy.evaluate(
          _ready().copyWith(
            usageDays: ['2026-10-01', '2026-10-02', '2026-10-05'],
          ),
          _start.add(const Duration(days: 4, hours: 23)),
          _version,
        ),
        ReviewDecision.tooNew,
      );
      expect(
        _policy.evaluate(
          _ready().copyWith(
            usageDays: ['2026-10-01', '2026-10-02', '2026-10-06'],
          ),
          _start.add(const Duration(days: 5)),
          _version,
        ),
        ReviewDecision.eligible,
      );
    });

    test('14 actions is too few, 15 is enough', () {
      expect(
        _policy.evaluate(_ready().copyWith(actions: 14), _later, _version),
        ReviewDecision.tooFewActions,
      );
      expect(
        _policy.evaluate(_ready().copyWith(actions: 15), _later, _version),
        ReviewDecision.eligible,
      );
    });

    test('an unknown version never asks', () {
      expect(
        _policy.evaluate(_ready(), _later, null),
        ReviewDecision.unknownVersion,
      );
      expect(
        _policy.evaluate(_ready(), _later, ''),
        ReviewDecision.unknownVersion,
      );
    });

    test('a first time that was never recorded is too new', () {
      final state = ReviewState(
        usageDays: _ready().usageDays,
        actions: 20,
        pendingAction: true,
      );
      expect(_policy.evaluate(state, _later, _version), ReviewDecision.tooNew);
    });
  });

  group('requests already made', () {
    ReviewState withRequests(List<ReviewRequest> requests) =>
        _ready().copyWith(requests: requests);

    test('89 days since the last is too soon, 90 is enough', () {
      final request = ReviewRequest(at: _later, version: '1.0.0+1');
      final state = withRequests([request]);
      expect(
        _policy.evaluate(
          state,
          _later.add(const Duration(days: 89, hours: 23)),
          _version,
        ),
        ReviewDecision.cooldown,
      );
      expect(
        _policy.evaluate(state, _later.add(const Duration(days: 90)), _version),
        ReviewDecision.eligible,
      );
    });

    test('three counted requests are the lifetime limit', () {
      final state = withRequests([
        ReviewRequest(at: _start, version: '1.0.0+1'),
        ReviewRequest(
          at: _start.add(const Duration(days: 100)),
          version: '1.0.1+2',
        ),
        ReviewRequest(
          at: _start.add(const Duration(days: 200)),
          version: '1.0.2+3',
        ),
      ]);
      expect(
        _policy.evaluate(
          state,
          _start.add(const Duration(days: 400)),
          _version,
        ),
        ReviewDecision.lifetimeLimit,
      );
    });

    test('a request the system could not show does not use up the limit', () {
      final state = withRequests([
        for (var i = 0; i < 5; i++)
          ReviewRequest(
            at: _start.add(Duration(days: i * 100)),
            version: 'v$i',
            counted: false,
          ),
      ]);
      expect(
        _policy.evaluate(
          state,
          _start.add(const Duration(days: 900)),
          _version,
        ),
        ReviewDecision.eligible,
      );
    });

    test('the same app version asks only once, even after the wait', () {
      final state = withRequests([
        ReviewRequest(at: _start, version: _version),
      ]);
      expect(
        _policy.evaluate(
          state,
          _start.add(const Duration(days: 300)),
          _version,
        ),
        ReviewDecision.sameVersion,
      );
    });

    test('a clock that went back keeps waiting, never asks sooner', () {
      final state =
          withRequests([
            ReviewRequest(at: _later, version: '1.0.0+1'),
          ]).copyWith(
            usageDays: ['2026-10-01', '2026-10-02', '2026-10-03', '2026-10-04'],
          );
      // Five days after install, but five days before the recorded request.
      expect(
        _policy.evaluate(state, _start.add(const Duration(days: 5)), _version),
        ReviewDecision.cooldown,
      );
    });

    test('the latest request decides the wait, whatever the list order', () {
      final state = withRequests([
        ReviewRequest(
          at: _later.add(const Duration(days: 10)),
          version: '1.0.1+2',
        ),
        ReviewRequest(at: _start, version: '1.0.0+1'),
      ]);
      expect(
        _policy.evaluate(state, _later.add(const Duration(days: 50)), _version),
        ReviewDecision.cooldown,
      );
    });
  });

  group('recording use', () {
    test('the first launch remembers the time and today', () {
      final state = _policy.recordUse(ReviewState.fresh, _start);
      expect(state.firstSeen, _start);
      expect(state.usageDays, ['2026-10-01']);
    });

    test('the same day twice is one day', () {
      var state = _policy.recordUse(ReviewState.fresh, _start);
      state = _policy.recordUse(state, _start.add(const Duration(hours: 5)));
      expect(state.usageDays, hasLength(1));
      state = _policy.recordUse(state, _start.add(const Duration(days: 1)));
      expect(state.usageDays, ['2026-10-01', '2026-10-02']);
    });

    test('a first time in the future (the clock went back) is repaired', () {
      final state = _policy.recordUse(
        ReviewState(firstSeen: _later, usageDays: const ['2026-10-11']),
        _start,
      );
      expect(state.firstSeen, _start);
      // The day recorded in the "future" is dropped.
      expect(state.usageDays, ['2026-10-01']);
    });

    test('days are kept sorted and capped', () {
      var state = ReviewState.fresh;
      for (var i = 0; i < 450; i++) {
        state = _policy.recordUse(state, _start.add(Duration(days: i)));
      }
      expect(state.usageDays.length, 400);
      expect(state.usageDays, [...state.usageDays]..sort());
      expect(
        state.usageDays.last,
        ReviewPolicy.dayKey(_start.add(const Duration(days: 449))),
      );
    });

    test('lost history becomes a request now, holding automatic ones back', () {
      final lost = ReviewState.fresh.copyWith(lostHistory: true);
      final state = _policy.recordUse(lost, _start);
      expect(state.lostHistory, isFalse);
      expect(state.requests, [
        ReviewRequest(at: _start, version: 'unknown', counted: false),
      ]);
      // Eligible in every other way, but within the wait.
      final ready = state.copyWith(
        actions: 20,
        pendingAction: true,
        usageDays: const ['2026-10-01', '2026-10-02', '2026-10-03'],
        firstSeen: _start.subtract(const Duration(days: 30)),
      );
      expect(
        _policy.evaluate(ready, _start.add(const Duration(days: 30)), _version),
        ReviewDecision.cooldown,
      );
    });
  });

  group('recording actions', () {
    test('an action counts and leaves a request waiting', () {
      final state = _policy.recordAction(ReviewState.fresh, 'hadith:1', _start);
      expect(state.actions, 1);
      expect(state.pendingAction, isTrue);
    });

    test('the same key twice in a day counts once', () {
      var state = _policy.recordAction(ReviewState.fresh, 'hadith:1', _start);
      state = _policy.recordAction(
        state,
        'hadith:1',
        _start.add(const Duration(hours: 3)),
      );
      expect(state.actions, 1);
      state = _policy.recordAction(
        state,
        'hadith:2',
        _start.add(const Duration(hours: 3)),
      );
      expect(state.actions, 2);
    });

    test('the same key on another day counts again', () {
      var state = _policy.recordAction(ReviewState.fresh, 'hadith:1', _start);
      state = _policy.recordAction(
        state,
        'hadith:1',
        _start.add(const Duration(days: 1)),
      );
      expect(state.actions, 2);
      expect(state.actionKeys, ['hadith:1']);
    });

    test('a repeat does not set pending again after a request', () {
      var state = _policy.recordAction(ReviewState.fresh, 'hadith:1', _start);
      state = _policy.recordRequest(state, _start, _version);
      expect(state.pendingAction, isFalse);
      state = _policy.recordAction(state, 'hadith:1', _start);
      expect(state.pendingAction, isFalse);
    });

    test('keys per day are capped without counting beyond the cap', () {
      var state = ReviewState.fresh;
      for (var i = 0; i < 600; i++) {
        state = _policy.recordAction(state, 'k$i', _start);
      }
      expect(state.actionKeys.length, 500);
      expect(state.actions, 500);
    });
  });

  group('recording a request', () {
    test('keeps the version and time, and clears what was waiting', () {
      final state = _policy.recordRequest(_ready(), _later, _version);
      expect(state.pendingAction, isFalse);
      expect(
        state.requests.single,
        ReviewRequest(at: _later, version: _version),
      );
      expect(state.actions, 20);
    });

    test('keeps only the latest 20 requests', () {
      var state = _ready();
      for (var i = 0; i < 25; i++) {
        state = _policy.recordRequest(
          state,
          _start.add(Duration(days: i)),
          'v$i',
          counted: false,
        );
      }
      expect(state.requests.length, 20);
      expect(state.requests.last.version, 'v24');
    });
  });

  test('day keys are zero-padded UTC dates', () {
    expect(ReviewPolicy.dayKey(DateTime.utc(2026, 1, 2, 23, 59)), '2026-01-02');
    expect(
      ReviewPolicy.dayKey(DateTime.utc(2026, 12, 31, 22).toLocal()),
      '2026-12-31',
    );
  });
}
