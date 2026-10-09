import 'dart:io';

import 'package:mynewapp/core/database/migration.dart';
import 'package:mynewapp/core/database/schema.dart';
import 'package:mynewapp/core/time/clock.dart';
import 'package:sqlite3/sqlite3.dart';

/// The on-device database for the user's own data (favourites, bookmarks, prayer
/// tracker, reminder plan). Nothing here is uploaded anywhere.
///
/// Content that ships with the app (such as Quran text) belongs in a separate read-only
/// database, never in this file, so a user's data can be backed up, exported or deleted
/// on its own.
class UserDatabase {
  UserDatabase._(this.db, {this.recoveredFrom, required this.migratedFrom});

  /// The open connection. Only `data` layers should use it.
  final Database db;

  /// Set when the previous file was unreadable and was set aside; the data in it is not
  /// lost, it is in this file (kept next to the new database).
  final File? recoveredFrom;

  /// The schema version found when opening (0 for a new database).
  final int migratedFrom;

  /// A private, temporary database (tests and previews).
  factory UserDatabase.inMemory({List<Migration>? migrations}) {
    final db = sqlite3.openInMemory();
    final from = _prepare(db, migrations ?? userDatabaseMigrations);
    return UserDatabase._(db, migratedFrom: from);
  }

  /// Opens (or creates) the database at [file] and migrates it.
  ///
  /// If SQLite reports that the file is corrupt or is not a database, the file is
  /// renamed to `<name>.corrupt-<timestamp>` and a fresh database is created, so the
  /// app keeps working and nothing is deleted. Any other problem (a failing migration,
  /// a database from a newer app) is thrown unchanged and the file is not touched.
  static UserDatabase openFile(
    File file, {
    Clock clock = const SystemClock(),
    List<Migration>? migrations,
  }) {
    final steps = migrations ?? userDatabaseMigrations;
    file.parent.createSync(recursive: true);
    try {
      return _openAndMigrate(file, steps);
    } on SqliteException catch (e) {
      if (!_isUnreadable(e)) rethrow;
      final aside = File(
        '${file.path}.corrupt-${clock.now().millisecondsSinceEpoch}',
      );
      file.renameSync(aside.path);
      for (final suffix in const ['-wal', '-shm', '-journal']) {
        final extra = File('${file.path}$suffix');
        if (extra.existsSync()) extra.deleteSync();
      }
      final fresh = _openAndMigrate(file, steps);
      return UserDatabase._(
        fresh.db,
        recoveredFrom: aside,
        migratedFrom: fresh.migratedFrom,
      );
    }
  }

  static UserDatabase _openAndMigrate(File file, List<Migration> steps) {
    final db = sqlite3.open(file.path);
    try {
      return UserDatabase._(db, migratedFrom: _prepare(db, steps));
    } catch (_) {
      db.close();
      rethrow;
    }
  }

  static int _prepare(Database db, List<Migration> steps) {
    db.execute('PRAGMA foreign_keys = ON');
    return MigrationRunner(steps).migrate(db);
  }

  // SQLITE_CORRUPT (11) and SQLITE_NOTADB (26).
  static bool _isUnreadable(SqliteException e) =>
      e.resultCode == 11 || e.resultCode == 26;

  /// Empties every table that holds the user's own data, in one transaction ("Delete all my
  /// data"). The schema and its version stay, and so does `app_meta`, which only describes the
  /// database itself. Tables added by later migrations are included without changes here.
  void clearUserTables() {
    final tables = [
      for (final row in db.select(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' AND name != 'app_meta'",
      ))
        row['name'] as String,
    ];
    db.execute('BEGIN');
    try {
      for (final table in tables) {
        db.execute('DELETE FROM "$table"');
      }
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  void close() => db.close();
}
