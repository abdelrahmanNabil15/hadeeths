import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/database/user_database.dart';
import 'package:mynewapp/features/favorites/data/favorites_repository_impl.dart';

import '../../support/time_support.dart';

void main() {
  late UserDatabase database;
  late FakeClock clock;
  late SqliteFavoritesRepository favorites;

  setUp(() {
    database = UserDatabase.inMemory();
    clock = FakeClock(DateTime.utc(2026, 10, 9, 10));
    favorites = SqliteFavoritesRepository(database.db, clock: clock);
  });

  tearDown(() => database.db.close());

  test('starts empty', () async {
    expect(await favorites.all(), isEmpty);
    expect(await favorites.contains('100'), isFalse);
  });

  test('adds and removes, and doing it twice is the same as once', () async {
    await favorites.setFavorite('100', favorite: true);
    await favorites.setFavorite('100', favorite: true);
    expect(await favorites.contains('100'), isTrue);
    expect(await favorites.all(), ['100']);
    await favorites.setFavorite('100', favorite: false);
    await favorites.setFavorite('100', favorite: false);
    expect(await favorites.contains('100'), isFalse);
    expect(await favorites.all(), isEmpty);
  });

  test('lists the most recently added first', () async {
    await favorites.setFavorite('100', favorite: true);
    clock.advance(const Duration(minutes: 1));
    await favorites.setFavorite('2962', favorite: true);
    clock.advance(const Duration(minutes: 1));
    await favorites.setFavorite('5', favorite: true);
    expect(await favorites.all(), ['5', '2962', '100']);
  });

  test('adding again does not move a favourite to the top', () async {
    await favorites.setFavorite('100', favorite: true);
    clock.advance(const Duration(minutes: 1));
    await favorites.setFavorite('200', favorite: true);
    clock.advance(const Duration(minutes: 1));
    await favorites.setFavorite('100', favorite: true);
    expect(await favorites.all(), ['200', '100']);
  });

  test('refuses anything that is not a hadith id', () async {
    for (final bad in ['', 'abc', '12a', "1' OR '1'='1", '1234567890123']) {
      await expectLater(
        favorites.setFavorite(bad, favorite: true),
        throwsArgumentError,
        reason: bad,
      );
    }
    expect(await favorites.all(), isEmpty);
  });

  test('clear removes everything', () async {
    await favorites.setFavorite('1', favorite: true);
    await favorites.setFavorite('2', favorite: true);
    await favorites.clear();
    expect(await favorites.all(), isEmpty);
  });

  test('stores the id and when it was added, and no text', () {
    final columns = database.db
        .select('PRAGMA table_info(favorites)')
        .map((r) => r['name'])
        .toList();
    expect(columns, ['hadith_id', 'added_at']);
  });
}
