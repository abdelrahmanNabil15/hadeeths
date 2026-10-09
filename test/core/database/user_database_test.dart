import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/database/migration.dart';
import 'package:mynewapp/core/database/schema.dart';
import 'package:mynewapp/core/database/user_database.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../support/time_support.dart';

Migration _m(int v, void Function(Database) up) => Migration(v, 'v$v', up);

List<String> _tables(Database db) => [
  for (final row in db.select(
    "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
  ))
    row['name'] as String,
];

void main() {
  group('migration runner', () {
    late Database db;
    setUp(() => db = sqlite3.openInMemory());
    tearDown(() => db.close());

    test('a new database is brought to the latest version', () {
      final runner = MigrationRunner([
        _m(1, (d) => d.execute('CREATE TABLE a (x INTEGER)')),
        _m(2, (d) => d.execute('CREATE TABLE b (y INTEGER)')),
      ]);
      expect(runner.migrate(db), 0);
      expect(db.userVersion, 2);
      expect(_tables(db), ['a', 'b']);
    });

    test('running again does nothing', () {
      final runner = MigrationRunner([
        _m(1, (d) => d.execute('CREATE TABLE a (x INTEGER)')),
      ]);
      runner.migrate(db);
      expect(runner.migrate(db), 1);
      expect(db.userVersion, 1);
    });

    test('only the missing steps run when upgrading', () {
      final ran = <int>[];
      List<Migration> steps(int upTo) => [
        for (var v = 1; v <= upTo; v++)
          _m(v, (d) {
            ran.add(v);
            d.execute('CREATE TABLE t$v (x INTEGER)');
          }),
      ];
      MigrationRunner(steps(2)).migrate(db);
      ran.clear();
      expect(MigrationRunner(steps(4)).migrate(db), 2);
      expect(ran, [3, 4]);
      expect(db.userVersion, 4);
    });

    test('existing rows survive an upgrade', () {
      MigrationRunner([
        _m(1, (d) {
          d.execute('CREATE TABLE notes (id INTEGER PRIMARY KEY, body TEXT)');
        }),
      ]).migrate(db);
      db.execute("INSERT INTO notes (body) VALUES ('keep me')");
      MigrationRunner([
        _m(1, (d) {
          d.execute('CREATE TABLE notes (id INTEGER PRIMARY KEY, body TEXT)');
        }),
        _m(
          2,
          (d) => d.execute(
            'ALTER TABLE notes ADD COLUMN pinned INTEGER NOT NULL DEFAULT 0',
          ),
        ),
      ]).migrate(db);
      final row = db.select('SELECT body, pinned FROM notes').single;
      expect(row['body'], 'keep me');
      expect(row['pinned'], 0);
    });

    test('a failing migration changes nothing, not even half of it', () {
      final good = _m(1, (d) => d.execute('CREATE TABLE a (x INTEGER)'));
      MigrationRunner([good]).migrate(db);
      final broken = _m(2, (d) {
        d.execute('CREATE TABLE b (y INTEGER)');
        d.execute('INSERT INTO missing_table VALUES (1)');
      });
      expect(
        () => MigrationRunner([good, broken]).migrate(db),
        throwsA(
          isA<MigrationFailedException>()
              .having((e) => e.fromVersion, 'from', 1)
              .having((e) => e.toVersion, 'to', 2),
        ),
      );
      expect(db.userVersion, 1);
      expect(_tables(db), ['a']);
      expect(db.autocommit, isTrue);
    });

    test('earlier steps stay applied when a later one fails', () {
      final runner = MigrationRunner([
        _m(1, (d) => d.execute('CREATE TABLE a (x INTEGER)')),
        _m(2, (d) => throw StateError('boom')),
      ]);
      expect(
        () => runner.migrate(db),
        throwsA(isA<MigrationFailedException>()),
      );
      expect(db.userVersion, 1);
      expect(_tables(db), ['a']);
    });

    test('a database from a newer app is refused and left alone', () {
      db.userVersion = 7;
      final runner = MigrationRunner([
        _m(1, (d) => d.execute('CREATE TABLE a (x INTEGER)')),
      ]);
      expect(
        () => runner.migrate(db),
        throwsA(
          isA<DatabaseTooNewException>()
              .having((e) => e.found, 'found', 7)
              .having((e) => e.supported, 'supported', 1),
        ),
      );
      expect(db.userVersion, 7);
      expect(_tables(db), isEmpty);
    });

    test('numbering must be 1..n without gaps', () {
      expect(() => MigrationRunner([_m(2, (_) {})]), throwsArgumentError);
      expect(
        () => MigrationRunner([_m(1, (_) {}), _m(3, (_) {})]),
        throwsArgumentError,
      );
    });
  });

  group('released schema', () {
    test('version 1 creates the metadata table', () {
      final database = UserDatabase.inMemory();
      expect(database.db.userVersion, userDatabaseMigrations.length);
      expect(_tables(database.db), contains('app_meta'));
      database.close();
    });

    test(
      'migrations are numbered 1..n (so adding one cannot skip a version)',
      () {
        MigrationRunner(userDatabaseMigrations); // throws if numbering is wrong
        expect(
          [for (final m in userDatabaseMigrations) m.version],
          [for (var i = 1; i <= userDatabaseMigrations.length; i++) i],
        );
      },
    );

    test('foreign keys are enforced', () {
      final database = UserDatabase.inMemory(
        migrations: [
          _m(1, (d) {
            d.execute('CREATE TABLE p (id INTEGER PRIMARY KEY)');
            d.execute(
              'CREATE TABLE c (id INTEGER PRIMARY KEY, p INTEGER REFERENCES p(id))',
            );
          }),
        ],
      );
      expect(
        () => database.db.execute('INSERT INTO c (p) VALUES (99)'),
        throwsA(isA<SqliteException>()),
      );
      database.close();
    });
  });

  group('on disk', () {
    late Directory dir;
    late File file;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('user_database_test');
      file = File('${dir.path}/data/user_data.db');
    });
    tearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    test('creates the folder and the file', () {
      final database = UserDatabase.openFile(file);
      expect(file.existsSync(), isTrue);
      expect(database.migratedFrom, 0);
      expect(database.recoveredFrom, isNull);
      database.close();
    });

    test('data survives closing and reopening', () {
      final first = UserDatabase.openFile(file);
      first.db.execute("INSERT INTO app_meta VALUES ('k', 'v')");
      first.close();
      final second = UserDatabase.openFile(file);
      expect(second.migratedFrom, userDatabaseMigrations.length);
      expect(
        second.db.select('SELECT value FROM app_meta').single['value'],
        'v',
      );
      second.close();
    });

    test('a file that is not a database is set aside, not deleted', () {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('this is definitely not a sqlite file' * 20);
      final clock = FakeClock(DateTime.utc(2026, 10, 9, 12));
      final database = UserDatabase.openFile(file, clock: clock);
      expect(database.recoveredFrom, isNotNull);
      expect(database.recoveredFrom!.existsSync(), isTrue);
      expect(
        database.recoveredFrom!.path,
        endsWith('.corrupt-${clock.now().millisecondsSinceEpoch}'),
      );
      expect(
        database.recoveredFrom!.readAsStringSync(),
        startsWith('this is definitely'),
      );
      expect(_tables(database.db), contains('app_meta'));
      database.close();
    });

    test('a database from a newer app is not touched or moved', () {
      file.parent.createSync(recursive: true);
      final newer = sqlite3.open(file.path);
      newer.userVersion = 99;
      newer.close();
      final before = file.lengthSync();
      expect(
        () => UserDatabase.openFile(file),
        throwsA(isA<DatabaseTooNewException>()),
      );
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), before);
      expect(
        dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.contains('.corrupt-')),
        isEmpty,
      );
    });

    test('a failing migration is not mistaken for corruption', () {
      final ok = UserDatabase.openFile(file);
      ok.close();
      expect(
        () => UserDatabase.openFile(
          file,
          migrations: [
            ...userDatabaseMigrations,
            _m(
              userDatabaseMigrations.length + 1,
              (d) => d.execute('INSERT INTO nope VALUES (1)'),
            ),
          ],
        ),
        throwsA(isA<MigrationFailedException>()),
      );
      expect(
        dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.contains('.corrupt-')),
        isEmpty,
      );
      final again = UserDatabase.openFile(file);
      expect(again.recoveredFrom, isNull);
      again.close();
    });
  });
}
