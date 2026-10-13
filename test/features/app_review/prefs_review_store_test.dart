import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/features/app_review/data/prefs_review_store.dart';
import 'package:mynewapp/features/app_review/domain/review_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(PrefsReviewStore, SharedPreferences)> _store([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(initial);
  final preferences = await SharedPreferences.getInstance();
  return (PrefsReviewStore(preferences), preferences);
}

final _state = ReviewState(
  firstSeen: DateTime.utc(2026, 10, 1, 9),
  usageDays: const ['2026-10-01', '2026-10-04'],
  actions: 17,
  pendingAction: true,
  actionDay: '2026-10-04',
  actionKeys: const ['hadith:1', 'tasbeeh:round'],
  requests: [
    ReviewRequest(at: DateTime.utc(2026, 10, 5), version: '1.0.0+1'),
    ReviewRequest(
      at: DateTime.utc(2026, 10, 6),
      version: '1.1.0+2',
      counted: false,
    ),
  ],
);

void main() {
  test('nothing saved is an empty memory, not lost history', () async {
    final (store, _) = await _store();
    expect(await store.load(), ReviewState.fresh);
  });

  test('a saved state comes back the same', () async {
    final (store, _) = await _store();
    await store.save(_state);
    expect(await store.load(), _state);
  });

  test('it is one small entry holding no content', () async {
    final (store, preferences) = await _store();
    await store.save(_state);
    final text = preferences.getString(PrefsReviewStore.storageKey)!;
    expect(text.length, lessThan(600));
    expect(jsonDecode(text), isA<Map<String, dynamic>>());
    expect(preferences.getKeys(), {PrefsReviewStore.storageKey});
  });

  test('clearing forgets everything', () async {
    final (store, preferences) = await _store();
    await store.save(_state);
    await store.clear();
    expect(preferences.getKeys(), isEmpty);
    expect(await store.load(), ReviewState.fresh);
  });

  group('damaged entries', () {
    Future<ReviewState> loadFrom(Object? value) async {
      final (store, _) = await _store({
        PrefsReviewStore.storageKey: value is String
            ? value
            : jsonEncode(value),
      });
      return store.load();
    }

    test('text that is not JSON is lost history', () async {
      final state = await loadFrom('{not json');
      expect(state.lostHistory, isTrue);
      expect(state.requests, isEmpty);
      expect(state.actions, 0);
    });

    test('JSON that is not an object is lost history', () async {
      expect((await loadFrom(<Object>[1, 2])).lostHistory, isTrue);
      expect((await loadFrom('"text"')).lostHistory, isTrue);
    });

    test('an unreadable list of requests is lost history, rest kept', () async {
      final state = await loadFrom({
        'firstSeen': '2026-10-01T09:00:00.000Z',
        'days': ['2026-10-01'],
        'actions': 9,
        'requests': 'oops',
      });
      expect(state.lostHistory, isTrue);
      expect(state.actions, 9);
      expect(state.usageDays, ['2026-10-01']);
    });

    test(
      'one broken request makes the whole list lost, not half-trusted',
      () async {
        final state = await loadFrom({
          'requests': [
            {'at': '2026-10-05T00:00:00.000Z', 'version': '1.0.0+1'},
            {'at': 'yesterday', 'version': '1.1.0+2'},
          ],
        });
        expect(state.lostHistory, isTrue);
        expect(state.requests, isEmpty);
      },
    );

    test(
      'a bad field falls back to its own default and the rest stays',
      () async {
        final state = await loadFrom({
          'firstSeen': 12,
          'days': ['2026-10-01', 'tomorrow', 7],
          'actions': -4,
          'pending': 'yes',
          'actionDay': 'today',
          'actionKeys': ['a', 3, 'b'],
          'requests': [
            {'at': '2026-10-05T00:00:00.000Z', 'version': '1.0.0+1'},
          ],
        });
        expect(state.lostHistory, isFalse);
        expect(state.firstSeen, isNull);
        expect(state.usageDays, ['2026-10-01']);
        expect(state.actions, 0);
        expect(state.pendingAction, isFalse);
        expect(state.actionDay, '');
        expect(state.actionKeys, ['a', 'b']);
        expect(state.requests, hasLength(1));
      },
    );

    test('a request without a count flag is counted', () async {
      final state = await loadFrom({
        'requests': [
          {'at': '2026-10-05T00:00:00.000Z', 'version': '1.0.0+1'},
        ],
      });
      expect(state.requests.single.counted, isTrue);
    });

    test('a wrong type under the key does not throw', () async {
      SharedPreferences.setMockInitialValues({PrefsReviewStore.storageKey: 5});
      final preferences = await SharedPreferences.getInstance();
      final state = await PrefsReviewStore(preferences).load();
      expect(state.lostHistory, isTrue);
    });
  });
}
