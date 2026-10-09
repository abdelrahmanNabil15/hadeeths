import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/database/schema.dart';
import 'package:mynewapp/core/database/user_database.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/tracker/data/prayer_log_repository_impl.dart';
import 'package:mynewapp/features/tracker/domain/day_key.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  group('DayKey', () {
    test('reads and writes yyyy-MM-dd', () {
      expect(DayKey(2026, 10, 9).id, '2026-10-09');
      expect(DayKey.parse('2026-10-09'), DayKey(2026, 10, 9));
      expect(DayKey.parse('0999-01-02').year, 999);
    });

    test('refuses days that do not exist', () {
      expect(() => DayKey(2026, 11, 31), throwsArgumentError);
      expect(() => DayKey(2026, 13, 1), throwsArgumentError);
      expect(() => DayKey(2027, 2, 29), throwsArgumentError);
      expect(DayKey(2028, 2, 29).day, 29);
      for (final bad in ['2026-1-9', '26-10-09', 'today', '2026-02-30', '']) {
        expect(() => DayKey.parse(bad), throwsFormatException, reason: bad);
      }
    });

    test('adding days follows the calendar across months and years', () {
      expect(DayKey(2026, 10, 9).addDays(1), DayKey(2026, 10, 10));
      expect(DayKey(2026, 10, 31).addDays(1), DayKey(2026, 11, 1));
      expect(DayKey(2026, 12, 31).addDays(1), DayKey(2027, 1, 1));
      expect(DayKey(2028, 3, 1).addDays(-1), DayKey(2028, 2, 29));
      expect(DayKey(2026, 10, 9).addDays(-6), DayKey(2026, 10, 3));
    });

    test('the length of a daylight-saving day does not matter', () {
      expect(DayKey(2026, 3, 28).addDays(1), DayKey(2026, 3, 29));
      expect(DayKey(2026, 3, 29).addDays(1), DayKey(2026, 3, 30));
      expect(DayKey(2026, 10, 24).addDays(2), DayKey(2026, 10, 26));
    });

    test('orders by date and knows the weekday', () {
      expect(DayKey(2026, 10, 9).isBefore(DayKey(2026, 10, 10)), isTrue);
      expect(DayKey(2026, 10, 10).isAfter(DayKey(2026, 10, 9)), isTrue);
      expect(DayKey(2026, 10, 9).weekday, DateTime.friday);
      final days = [DayKey(2027, 1, 1), DayKey(2026, 10, 9), DayKey(2026, 2, 1)]
        ..sort();
      expect(days.map((d) => d.id), ['2026-02-01', '2026-10-09', '2027-01-01']);
    });

    test('a day read from a wall clock ignores the time and the zone flag', () {
      expect(
        DayKey.fromWallClock(DateTime.utc(2026, 10, 9, 23, 59)),
        DayKey(2026, 10, 9),
      );
      expect(
        DayKey.fromWallClock(DateTime(2026, 10, 10, 0, 1)),
        DayKey(2026, 10, 10),
      );
    });
  });

  group('the prayer log', () {
    late UserDatabase database;
    late SqlitePrayerLogRepository log;

    setUp(() {
      database = UserDatabase.inMemory();
      log = SqlitePrayerLogRepository(database.db);
    });

    tearDown(() => database.db.close());

    final friday = DayKey(2026, 10, 9);

    test('starts empty', () async {
      expect(await log.between(friday.addDays(-6), friday), isEmpty);
    });

    test('marks and unmarks a prayer', () async {
      await log.setDone(friday, Prayer.fajr, done: true);
      expect((await log.between(friday, friday))[friday], {Prayer.fajr});
      await log.setDone(friday, Prayer.fajr, done: false);
      expect(await log.between(friday, friday), isEmpty);
    });

    test('doing the same thing twice is the same as once', () async {
      await log.setDone(friday, Prayer.asr, done: true);
      await log.setDone(friday, Prayer.asr, done: true);
      expect((await log.between(friday, friday))[friday], {Prayer.asr});
      await log.setDone(friday, Prayer.asr, done: false);
      await log.setDone(friday, Prayer.asr, done: false);
      expect(await log.between(friday, friday), isEmpty);
    });

    test('keeps days apart and returns only the range asked for', () async {
      await log.setDone(friday, Prayer.fajr, done: true);
      await log.setDone(friday, Prayer.isha, done: true);
      await log.setDone(friday.addDays(-1), Prayer.dhuhr, done: true);
      await log.setDone(friday.addDays(-10), Prayer.maghrib, done: true);
      final week = await log.between(friday.addDays(-6), friday);
      expect(week.keys.toSet(), {friday, friday.addDays(-1)});
      expect(week[friday], {Prayer.fajr, Prayer.isha});
      expect(week[friday.addDays(-1)], {Prayer.dhuhr});
    });

    test('a range works across a month and a year boundary', () async {
      final newYear = DayKey(2027, 1, 1);
      await log.setDone(DayKey(2026, 12, 30), Prayer.fajr, done: true);
      await log.setDone(newYear, Prayer.fajr, done: true);
      final result = await log.between(
        DayKey(2026, 12, 28),
        DayKey(2027, 1, 3),
      );
      expect(result.keys.toSet(), {DayKey(2026, 12, 30), newYear});
    });

    test('sunrise is refused and nothing is written', () async {
      await expectLater(
        log.setDone(friday, Prayer.sunrise, done: true),
        throwsArgumentError,
      );
      expect(database.db.select('SELECT * FROM prayer_log'), isEmpty);
    });

    test('the table itself only accepts the five prayers', () {
      expect(
        () => database.db.execute(
          "INSERT INTO prayer_log (day, prayer) VALUES ('2026-10-09', 'sunrise')",
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('delete all removes every day', () async {
      await log.setDone(friday, Prayer.fajr, done: true);
      await log.setDone(friday.addDays(-30), Prayer.isha, done: true);
      await log.deleteAll();
      expect(await log.between(friday.addDays(-60), friday), isEmpty);
    });

    test('stores nothing but the day and the prayer', () {
      final columns = database.db
          .select('PRAGMA table_info(prayer_log)')
          .map((r) => r['name'])
          .toList();
      expect(columns, ['day', 'prayer']);
    });
  });

  group('the schema', () {
    test('a version 1 database upgrades and keeps what it had', () {
      final db = sqlite3.openInMemory();
      db.execute(
        'CREATE TABLE app_meta (key TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL) WITHOUT ROWID',
      );
      db.execute("INSERT INTO app_meta (key, value) VALUES ('k', 'v')");
      db.execute('PRAGMA user_version = 1');
      // Run only the steps after version 1, as an upgrade of an existing install does.
      for (final step in userDatabaseMigrations.skip(1)) {
        step.up(db);
      }
      expect(
        db.select("SELECT value FROM app_meta WHERE key = 'k'").first['value'],
        'v',
      );
      expect(
        db.select("SELECT name FROM sqlite_master WHERE name = 'prayer_log'"),
        isNotEmpty,
      );
      db.close();
    });

    test('a new database is at the latest version', () {
      final fresh = UserDatabase.inMemory();
      expect(fresh.migratedFrom, 0);
      expect(
        fresh.db.select('PRAGMA user_version').first.values.first,
        userDatabaseMigrations.length,
      );
      fresh.db.close();
    });
  });
}
