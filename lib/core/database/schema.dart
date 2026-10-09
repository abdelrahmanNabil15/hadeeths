import 'package:mynewapp/core/database/migration.dart';

/// Every released version of the user-data schema, oldest first.
///
/// Feature tables are added by the feature that needs them (favourites, tracker,
/// bookmarks, reminder plan, downloads), each as a new numbered migration.
final List<Migration> userDatabaseMigrations = [
  Migration(1, 'key-value metadata', (db) {
    db.execute('''
CREATE TABLE app_meta (
  key TEXT NOT NULL PRIMARY KEY,
  value TEXT NOT NULL
) WITHOUT ROWID''');
  }),
  Migration(2, 'prayer log', (db) {
    // One row per prayer marked as prayed on a calendar day (yyyy-MM-dd). Nothing else is
    // kept: no time, no place. Unmarking deletes the row.
    db.execute('''
CREATE TABLE prayer_log (
  day TEXT NOT NULL,
  prayer TEXT NOT NULL CHECK (prayer IN ('fajr', 'dhuhr', 'asr', 'maghrib', 'isha')),
  PRIMARY KEY (day, prayer)
) WITHOUT ROWID''');
  }),
  Migration(3, 'tasbeeh counter', (db) {
    // A single row: the count the user has reached and the target they chose (none if null).
    db.execute('''
CREATE TABLE tasbeeh_counter (
  id INTEGER NOT NULL PRIMARY KEY CHECK (id = 1),
  count INTEGER NOT NULL CHECK (count >= 0),
  target INTEGER CHECK (target IS NULL OR target IN (33, 99, 100))
) WITHOUT ROWID''');
  }),
  Migration(4, 'favourite hadiths', (db) {
    // Ids only (no text from the source), with when they were added, for the order of the list.
    db.execute('''
CREATE TABLE favorites (
  hadith_id TEXT NOT NULL PRIMARY KEY,
  added_at INTEGER NOT NULL
) WITHOUT ROWID''');
  }),
];
