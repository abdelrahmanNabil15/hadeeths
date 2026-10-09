import 'package:sqlite3/sqlite3.dart';

/// One step of the user-data schema. Version numbers start at 1 and have no gaps.
///
/// Rules for writing one (they protect existing users' data):
/// - never edit a migration that has shipped; add a new one;
/// - never drop or rewrite a user's rows unless the new shape keeps their information;
/// - every statement runs inside one transaction, so a failure changes nothing.
class Migration {
  const Migration(this.version, this.description, this.up);

  final int version;
  final String description;
  final void Function(Database db) up;
}

/// The database was written by a newer version of the app than the one running now
/// (the user installed an older build). It is left untouched.
class DatabaseTooNewException implements Exception {
  const DatabaseTooNewException({required this.found, required this.supported});

  final int found;
  final int supported;

  @override
  String toString() =>
      'DatabaseTooNewException(found schema $found, this app supports up to $supported)';
}

/// A migration threw. The database stays at [fromVersion]; nothing was changed.
class MigrationFailedException implements Exception {
  const MigrationFailedException({
    required this.fromVersion,
    required this.toVersion,
    required this.cause,
  });

  final int fromVersion;
  final int toVersion;
  final Object cause;

  @override
  String toString() =>
      'MigrationFailedException($fromVersion -> $toVersion: $cause)';
}

/// Brings a database up to the latest schema, one transaction per version.
class MigrationRunner {
  MigrationRunner(List<Migration> migrations)
    : _migrations = List.unmodifiable(migrations) {
    for (var i = 0; i < _migrations.length; i++) {
      if (_migrations[i].version != i + 1) {
        throw ArgumentError(
          'migrations must be numbered 1..n without gaps; position ${i + 1} has '
          'version ${_migrations[i].version}',
        );
      }
    }
  }

  final List<Migration> _migrations;

  int get latestVersion => _migrations.length;

  /// Returns the version the database had before this call.
  int migrate(Database db) {
    final current = db.userVersion;
    if (current > latestVersion) {
      throw DatabaseTooNewException(found: current, supported: latestVersion);
    }
    for (final migration in _migrations.skip(current)) {
      db.execute('BEGIN IMMEDIATE');
      try {
        migration.up(db);
        db.userVersion = migration.version;
        db.execute('COMMIT');
      } catch (error) {
        if (!db.autocommit) db.execute('ROLLBACK');
        throw MigrationFailedException(
          fromVersion: migration.version - 1,
          toVersion: migration.version,
          cause: error,
        );
      }
    }
    return current;
  }
}
