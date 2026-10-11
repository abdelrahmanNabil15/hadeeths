import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/core/time/zone.dart';
import 'package:mynewapp/features/categories/domain/hadith_category.dart';
import 'package:mynewapp/features/daily_hadith/data/prefs_daily_hadith_store.dart';
import 'package:mynewapp/features/daily_hadith/domain/daily_hadith_service.dart';
import 'package:mynewapp/features/daily_hadith/domain/daily_hadith_store.dart';
import 'package:mynewapp/features/daily_hadith/domain/daily_selection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_backend.dart';
import '../../support/fixtures.dart';
import '../../support/time_support.dart';

const _zone = FixedOffsetZone(Duration(hours: 3));

Future<PrefsDailyHadithStore> _store([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(initial);
  return PrefsDailyHadithStore(await SharedPreferences.getInstance());
}

/// Category 1 (root, 45 hadiths over three pages), category 2 (root, 5 hadiths), category 8 (child
/// of 1, 3 hadiths) and an empty root 3.
FakeBackend _backend() => FakeBackend(
  categories: [
    const HadithCategory(id: '1', title: 'Root one', hadithCount: 45),
    const HadithCategory(id: '2', title: 'Root two', hadithCount: 5),
    const HadithCategory(id: '3', title: 'Empty root', hadithCount: 0),
    const HadithCategory(
      id: '8',
      title: 'Child eight',
      hadithCount: 3,
      parentId: '1',
    ),
  ],
  pages: {
    for (var p = 1; p <= 3; p++)
      '1:$p': samplePage(
        ids: [for (var i = (p - 1) * 20; i < (p * 20).clamp(0, 45); i++) 'a$i'],
        page: p,
        lastPage: 3,
        totalItems: 45,
      ),
    '2:1': samplePage(ids: ['b0', 'b1', 'b2', 'b3', 'b4'], totalItems: 5),
    '8:1': samplePage(ids: ['c0', 'c1', 'c2'], totalItems: 3),
  },
);

DailyHadithService _service(
  FakeBackend api,
  DailyHadithStore store,
  FakeClock clock,
) => DailyHadithService(
  categories: api,
  hadiths: api,
  store: store,
  clock: clock,
  zone: _zone,
);

DailyHadith _value(Result<DailyHadith?> r) =>
    (r as Success<DailyHadith?>).value!;

void main() {
  group('selection rules', () {
    test('day keys and numbers', () {
      expect(dayKey(DateTime.utc(2026, 1, 5)), '2026-01-05');
      expect(dayNumber(DateTime.utc(1970, 1, 2)), 1);
    });

    test('categories rotate by day; yesterday\'s goes last', () {
      expect(categoryOrder(day: 0, pool: ['b', 'a', 'c']), ['a', 'b', 'c']);
      expect(categoryOrder(day: 1, pool: ['b', 'a', 'c']), ['b', 'c', 'a']);
      expect(categoryOrder(day: 1, pool: ['a', 'b', 'c'], yesterday: 'b'), [
        'c',
        'a',
        'b',
      ]);
      expect(categoryOrder(day: 3, pool: ['a'], yesterday: 'a'), ['a']);
      expect(categoryOrder(day: 3, pool: const []), isEmpty);
    });

    test('the position is stable and within range', () {
      int at() => itemIndex(
        day: '2026-10-09',
        language: 'ar',
        categoryId: '1',
        count: 45,
      );
      expect(at(), at());
      expect(at(), inInclusiveRange(0, 44));
    });

    test('hadiths shown recently are skipped, wrapping round', () {
      expect(firstNotShown(['x', 'y', 'z'], 1, {'y'}), 2);
      expect(firstNotShown(['x', 'y', 'z'], 2, {'z'}), 0);
      expect(firstNotShown(['x', 'y'], 1, {'x', 'y'}), 1);
    });
  });

  group('the store', () {
    test(
      'remembers opened categories, newest first, without repeats',
      () async {
        final s = await _store();
        expect(await s.remembersOpened(), isTrue);
        await s.recordOpened('1');
        await s.recordOpened('2');
        await s.recordOpened('1');
        expect(await s.openedCategories(), ['1', '2']);
      },
    );

    test('keeps at most fifty', () async {
      final s = await _store();
      for (var i = 0; i < 60; i++) {
        await s.recordOpened('$i');
      }
      final opened = await s.openedCategories();
      expect(opened, hasLength(DailyHadithStore.maxOpened));
      expect(opened.first, '59');
    });

    test('switching remembering off forgets and stops recording', () async {
      final s = await _store();
      await s.recordOpened('1');
      await s.setRemembersOpened(false);
      expect(await s.openedCategories(), isEmpty);
      await s.recordOpened('2');
      expect(await s.openedCategories(), isEmpty);
      await s.setRemembersOpened(true);
      await s.recordOpened('3');
      expect(await s.openedCategories(), ['3']);
    });

    test('picks are per day and language; old ones are dropped', () async {
      final s = await _store();
      DailyPick pick(String day, String lang, String id) => DailyPick(
        day: day,
        language: lang,
        hadithId: id,
        categoryId: '1',
        page: 1,
        fromOpened: false,
      );
      await s.savePick(pick('2026-10-08', 'ar', 'x'));
      await s.savePick(pick('2026-10-09', 'ar', 'y'));
      await s.savePick(pick('2026-10-09', 'en', 'z'));
      expect((await s.pickFor('2026-10-09', 'ar'))!.hadithId, 'y');
      expect((await s.pickFor('2026-10-09', 'en'))!.hadithId, 'z');
      expect((await s.pickFor('2026-10-08', 'ar'))!.hadithId, 'x');
      await s.savePick(pick('2026-10-11', 'ar', 'w'));
      expect(await s.pickFor('2026-10-08', 'ar'), isNull);
    });

    test('history covers sixty days before the day', () async {
      final s = await _store();
      Future<void> shown(String day, String id) => s.savePick(
        DailyPick(
          day: day,
          language: 'ar',
          hadithId: id,
          categoryId: '1',
          page: 1,
          fromOpened: false,
        ),
      );
      await shown('2026-08-01', 'old');
      await shown('2026-08-15', 'recent');
      await shown('2026-10-09', 'today');
      expect(await s.shownBefore('2026-10-09'), {'recent'});
    });

    test('damaged data is ignored; clear removes everything', () async {
      final s = await _store({PrefsDailyHadithStore.storageKey: '{not json'});
      expect(await s.openedCategories(), isEmpty);
      await s.recordOpened('1');
      await s.clear();
      expect(await s.openedCategories(), isEmpty);
      final damaged = await _store({
        PrefsDailyHadithStore.storageKey: jsonEncode({
          'opened': [1, '2', null],
          'picks': [
            'x',
            {'day': '2026-10-09'},
          ],
        }),
      });
      expect(await damaged.openedCategories(), ['2']);
      expect(await damaged.pickFor('2026-10-09', 'ar'), isNull);
    });
  });

  group('choosing today\'s hadith', () {
    late FakeClock clock;

    setUp(() => clock = FakeClock(DateTime.utc(2026, 10, 9, 10)));

    test('a new user gets one from the top-level categories', () async {
      final api = _backend();
      final store = await _store();
      final today = _value(
        await _service(api, store, clock).today(language: 'ar'),
      );
      expect(today.fromOpened, isFalse);
      expect(['1', '2'], contains(today.categoryId));
      expect(api.pageRequests.length, lessThanOrEqualTo(2));
    });

    test(
      'the same hadith all day, even after opening more categories',
      () async {
        final api = _backend();
        final store = await _store();
        final service = _service(api, store, clock);
        final first = _value(await service.today(language: 'ar'));
        await store.recordOpened('8');
        clock.advance(const Duration(hours: 8));
        expect(_value(await service.today(language: 'ar')), first);
      },
    );

    test('opened categories are used when there are some', () async {
      final api = _backend();
      final store = await _store();
      await store.recordOpened('8');
      final today = _value(
        await _service(api, store, clock).today(language: 'ar'),
      );
      expect(today.categoryId, '8');
      expect(today.categoryTitle, 'Child eight');
      expect(today.fromOpened, isTrue);
    });

    test('the next day moves to another category and another hadith', () async {
      final api = _backend();
      final store = await _store();
      final service = _service(api, store, clock);
      final day1 = _value(await service.today(language: 'ar'));
      clock.advance(const Duration(days: 1));
      final day2 = _value(await service.today(language: 'ar'));
      expect(day2.categoryId, isNot(day1.categoryId));
      expect(day2.id, isNot(day1.id));
    });

    test('a hadith shown in the last sixty days is not shown again', () async {
      final api = _backend();
      final store = await _store();
      await store.recordOpened('8');
      final service = _service(api, store, clock);
      final seen = <String>{};
      for (var d = 0; d < 3; d++) {
        seen.add(_value(await service.today(language: 'ar')).id);
        clock.advance(const Duration(days: 1));
      }
      expect(seen, {
        'c0',
        'c1',
        'c2',
      }, reason: 'three days, three different hadiths');
    });

    test('when everything was shown recently, a repeat is accepted', () async {
      final api = _backend();
      final store = await _store();
      await store.recordOpened('8');
      final service = _service(api, store, clock);
      for (var d = 0; d < 4; d++) {
        expect(
          await service.today(language: 'ar'),
          isA<Success<DailyHadith?>>(),
        );
        clock.advance(const Duration(days: 1));
      }
    });

    test('an empty category is skipped', () async {
      final api = _backend()
        ..categories = [
          const HadithCategory(id: '3', title: 'Empty', hadithCount: 0),
          const HadithCategory(id: '2', title: 'Root two', hadithCount: 5),
        ];
      final store = await _store();
      expect(
        _value(
          await _service(api, store, clock).today(language: 'ar'),
        ).categoryId,
        '2',
      );
    });

    test('nothing to choose from gives no hadith, not an error', () async {
      final api = _backend()..categories = [];
      final store = await _store();
      final r = await _service(api, store, clock).today(language: 'ar');
      expect((r as Success<DailyHadith?>).value, isNull);
    });

    test('a failure to load is reported', () async {
      final api = _backend()
        ..categoriesFailure = const Failure(FailureKind.noConnection);
      final store = await _store();
      final r = await _service(api, store, clock).today(language: 'ar');
      expect(r, isA<Err<DailyHadith?>>());
    });

    test('the day follows the phone\'s calendar', () async {
      final api = _backend();
      final store = await _store();
      // 22:30 UTC on the 9th is 01:30 on the 10th at UTC+3.
      clock.set(DateTime.utc(2026, 10, 9, 22, 30));
      await _service(api, store, clock).today(language: 'ar');
      expect(await store.pickFor('2026-10-10', 'ar'), isNotNull);
    });
  });
}
