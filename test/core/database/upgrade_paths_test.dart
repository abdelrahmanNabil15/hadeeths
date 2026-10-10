import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/database/migration.dart';
import 'package:mynewapp/core/database/schema.dart';
import 'package:sqlite3/sqlite3.dart';

/// One example row for each table, written before the upgrade and expected afterwards.
const _samples = {
  'app_meta': "INSERT INTO app_meta (key, value) VALUES ('k', 'v')",
  'prayer_log':
      "INSERT INTO prayer_log (day, prayer) VALUES ('2026-10-09', 'fajr')",
  'tasbeeh_counter':
      'INSERT INTO tasbeeh_counter (id, count, target) VALUES (1, 12, 33)',
  'favorites': "INSERT INTO favorites (hadith_id, added_at) VALUES ('100', 1)",
  'quran_last_read':
      'INSERT INTO quran_last_read (id, sura, verse, updated_at) VALUES (1, 2, 255, 1)',
  'quran_bookmarks':
      'INSERT INTO quran_bookmarks (sura, verse, added_at) VALUES (36, 1, 1)',
};

Set<String> _tables(Database db) => db
    .select(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
    )
    .map((r) => r['name'] as String)
    .toSet();

int _version(Database db) =>
    db.select('PRAGMA user_version').first.values.first as int;

void main() {
  final latest = userDatabaseMigrations.length;

  test('every table has an example row here', () {
    final db = sqlite3.openInMemory();
    MigrationRunner(userDatabaseMigrations).migrate(db);
    expect(_tables(db), _samples.keys.toSet());
    db.close();
  });

  for (var from = 0; from < latest; from++) {
    test(
      'an install at version $from upgrades to $latest and keeps its data',
      () {
        final db = sqlite3.openInMemory();
        MigrationRunner(userDatabaseMigrations.take(from).toList()).migrate(db);
        expect(_version(db), from);
        final existing = _tables(db);
        for (final table in existing) {
          db.execute(_samples[table]!);
        }

        MigrationRunner(userDatabaseMigrations).migrate(db);

        expect(_version(db), latest);
        expect(_tables(db), _samples.keys.toSet());
        for (final table in existing) {
          expect(
            db.select('SELECT COUNT(*) AS n FROM $table').first['n'],
            1,
            reason: '$table lost its row upgrading from $from',
          );
        }
        db.close();
      },
    );
  }

  test('opening an up-to-date database again changes nothing', () {
    final db = sqlite3.openInMemory();
    MigrationRunner(userDatabaseMigrations).migrate(db);
    for (final sql in _samples.values) {
      db.execute(sql);
    }
    MigrationRunner(userDatabaseMigrations).migrate(db);
    expect(_version(db), latest);
    for (final table in _samples.keys) {
      expect(db.select('SELECT COUNT(*) AS n FROM $table').first['n'], 1);
    }
    db.close();
  });
}
