import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/tracker/domain/day_key.dart';
import 'package:mynewapp/features/tracker/presentation/state/tracker_cubit.dart';
import 'package:mynewapp/features/tracker/presentation/state/tracker_review_events.dart';

final _today = DayKey(2026, 10, 9);
final _yesterday = DayKey(2026, 10, 8);
final _days = [_today, _yesterday];

TrackerState _state({
  TrackerStatus status = TrackerStatus.ready,
  List<DayKey>? days,
  Map<DayKey, Set<Prayer>> done = const {},
  bool saveFailed = false,
}) => TrackerState(
  status: status,
  days: days ?? _days,
  selected: _today,
  done: done,
  saveFailed: saveFailed,
);

void main() {
  test('a prayer marked between two loaded states is reported once', () {
    final before = _state();
    final after = _state(
      done: {
        _today: {Prayer.fajr},
      },
    );
    expect(newlyMarked(before, after), ['prayer:${_today.id}:fajr']);
  });

  test('several newly marked prayers are all reported', () {
    final before = _state(
      done: {
        _today: {Prayer.fajr},
      },
    );
    final after = _state(
      done: {
        _today: {Prayer.fajr, Prayer.dhuhr},
        _yesterday: {Prayer.isha},
      },
    );
    expect(
      newlyMarked(before, after),
      unorderedEquals([
        'prayer:${_today.id}:dhuhr',
        'prayer:${_yesterday.id}:isha',
      ]),
    );
  });

  test('unmarking or no change reports nothing', () {
    final marked = _state(
      done: {
        _today: {Prayer.fajr},
      },
    );
    expect(newlyMarked(marked, _state()), isEmpty);
    expect(newlyMarked(marked, marked), isEmpty);
  });

  test('the first load is not the user marking anything', () {
    final loaded = _state(
      done: {
        _today: {Prayer.fajr, Prayer.dhuhr},
      },
    );
    expect(
      newlyMarked(_state(status: TrackerStatus.loading, days: []), loaded),
      isEmpty,
    );
  });

  test('a week that moved on (after midnight) is not the user marking', () {
    final before = _state();
    final after = _state(
      days: [DayKey(2026, 10, 10), _today],
      done: {
        _today: {Prayer.fajr},
      },
    );
    expect(newlyMarked(before, after), isEmpty);
  });

  test('a change taken back after a failed save is not reported', () {
    final before = _state();
    final after = _state(
      saveFailed: true,
      done: {
        _today: {Prayer.fajr},
      },
    );
    expect(newlyMarked(before, after), isEmpty);
  });

  test('an unavailable tracker reports nothing', () {
    expect(
      newlyMarked(_state(), _state(status: TrackerStatus.unavailable)),
      isEmpty,
    );
  });
}
