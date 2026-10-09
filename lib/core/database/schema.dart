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
];
