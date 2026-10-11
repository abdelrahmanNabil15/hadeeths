import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/database/user_database.dart';
import 'package:mynewapp/features/quran/data/quran_user_data_impl.dart';
import 'package:mynewapp/features/quran/domain/quran_search.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';
import 'package:mynewapp/features/quran/domain/sura_names.dart';
import 'package:mynewapp/features/quran/presentation/state/quran_cubit.dart';

import '../../support/quran_fakes.dart';

void main() {
  group('sura names', () {
    test('there are 114 of each, all different', () {
      expect(SuraNames.allArabic, hasLength(114));
      expect(SuraNames.allLatin, hasLength(114));
      expect(SuraNames.allArabic.toSet(), hasLength(114));
      expect(SuraNames.allLatin.toSet(), hasLength(114));
    });

    test('a few fixed points', () {
      expect(SuraNames.arabic(1), 'الفاتحة');
      expect(SuraNames.arabic(2), 'البقرة');
      expect(SuraNames.arabic(36), 'يس');
      expect(SuraNames.arabic(112), 'الإخلاص');
      expect(SuraNames.arabic(114), 'الناس');
      expect(SuraNames.latin(1), 'Al-Fatihah');
      expect(SuraNames.latin(114), 'An-Nas');
    });

    test('numbers outside 1 to 114 are refused', () {
      expect(() => SuraNames.arabic(0), throwsRangeError);
      expect(() => SuraNames.latin(115), throwsRangeError);
    });
  });

  group('search', () {
    final search = QuranSearch(placeholderQuran());

    test('ignores marks when matching and returns the verse unchanged', () {
      final found = search.search('كلمة مشكلة');
      expect(found.map((v) => '${v.sura}:${v.number}'), ['2:3', '3:2']);
      expect(found.first.text, placeholderVerse(2, 3));
    });

    test('every word must be present', () {
      expect(search.search('كلمة أخرى').map((v) => '${v.sura}:${v.number}'), [
        '3:2',
      ]);
    });

    test('too short or empty queries return nothing', () {
      expect(search.search(''), isEmpty);
      expect(search.search('ك'), isEmpty);
      expect(search.search('   '), isEmpty);
    });

    test('results stop at the limit, in Mushaf order', () {
      final found = search.search('سطر', limit: 4);
      expect(found, hasLength(4));
      expect(found.first.sura, 1);
    });
  });

  group('stored reading places', () {
    late UserDatabase database;
    late SqliteQuranUserData data;

    setUp(() {
      database = UserDatabase.inMemory();
      data = SqliteQuranUserData(database.db);
    });

    tearDown(() => database.close());

    test('remembers the last place, replacing the one before', () async {
      expect(await data.lastRead(), isNull);
      await data.setLastRead(const VerseRef(2, 255));
      await data.setLastRead(const VerseRef(18, 10));
      expect(await data.lastRead(), const VerseRef(18, 10));
    });

    test(
      'bookmarks are added once, removed, and listed in Mushaf order',
      () async {
        await data.setBookmark(const VerseRef(36, 1), on: true);
        await data.setBookmark(const VerseRef(2, 255), on: true);
        await data.setBookmark(const VerseRef(2, 255), on: true);
        await data.setBookmark(const VerseRef(2, 3), on: true);
        expect(await data.bookmarks(), const [
          VerseRef(2, 3),
          VerseRef(2, 255),
          VerseRef(36, 1),
        ]);
        expect(await data.isBookmarked(const VerseRef(36, 1)), isTrue);
        await data.setBookmark(const VerseRef(36, 1), on: false);
        expect(await data.isBookmarked(const VerseRef(36, 1)), isFalse);
      },
    );

    test('places that cannot exist are refused', () async {
      expect(() => data.setLastRead(const VerseRef(0, 1)), throwsRangeError);
      expect(
        () => data.setBookmark(const VerseRef(115, 1), on: true),
        throwsRangeError,
      );
      expect(
        () => data.setBookmark(const VerseRef(2, 287), on: true),
        throwsRangeError,
      );
    });

    test('only positions are stored, never text', () {
      List<Object?> columns(String table) => database.db
          .select('PRAGMA table_info($table)')
          .map((r) => r['name'])
          .toList();
      expect(columns('quran_last_read'), ['id', 'sura', 'verse', 'updated_at']);
      expect(columns('quran_bookmarks'), ['sura', 'verse', 'added_at']);
    });
  });

  group('QuranCubit', () {
    test('ready with the text, the last place and the bookmarks', () async {
      final data = InMemoryQuranUserData()
        ..last = const VerseRef(2, 5)
        ..marks.add(const VerseRef(3, 1));
      final cubit = QuranCubit(source: FakeQuranSource(), userData: data);
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.status, QuranStatus.ready);
      expect(cubit.state.lastRead, const VerseRef(2, 5));
      expect(cubit.state.bookmarks, const [VerseRef(3, 1)]);
    });

    test(
      'a text that cannot be verified leaves the section unavailable',
      () async {
        final cubit = QuranCubit(source: FakeQuranSource(fail: true));
        addTearDown(cubit.close);
        await cubit.load();
        expect(cubit.state.status, QuranStatus.unavailable);
        expect(cubit.state.text, isNull);
      },
    );

    test('reading works without storage', () async {
      final cubit = QuranCubit(source: FakeQuranSource());
      addTearDown(cubit.close);
      await cubit.load();
      await cubit.setLastRead(const VerseRef(1, 2));
      await cubit.toggleBookmark(const VerseRef(1, 2));
      expect(cubit.state.lastRead, const VerseRef(1, 2));
      expect(cubit.state.bookmarks, const [VerseRef(1, 2)]);
    });

    test('a failed bookmark save is taken back', () async {
      final data = InMemoryQuranUserData()..failWrites = StateError('disk');
      final cubit = QuranCubit(source: FakeQuranSource(), userData: data);
      addTearDown(cubit.close);
      await cubit.load();
      await cubit.toggleBookmark(const VerseRef(2, 1));
      expect(cubit.state.bookmarks, isEmpty);
    });
  });
}
