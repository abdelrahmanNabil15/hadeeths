import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/database/user_database.dart';
import 'package:mynewapp/core/haptics/haptics.dart';
import 'package:mynewapp/features/tasbeeh/data/tasbeeh_repository_impl.dart';
import 'package:mynewapp/features/tasbeeh/domain/tasbeeh_counter.dart';
import 'package:mynewapp/features/tasbeeh/domain/tasbeeh_repository.dart';
import 'package:mynewapp/features/tasbeeh/presentation/state/tasbeeh_cubit.dart';
import 'package:sqlite3/sqlite3.dart';

class _Haptics implements Haptics {
  int selections = 0;
  int alignments = 0;

  @override
  void selection() => selections++;

  @override
  void alignment() => alignments++;
}

class _MemoryRepository implements TasbeehRepository {
  TasbeehCounter stored = const TasbeehCounter();
  int saves = 0;
  Object? failLoad;
  Object? failSave;
  Completer<void>? gate;

  @override
  Future<TasbeehCounter> load() async {
    if (failLoad != null) throw failLoad!;
    return stored;
  }

  @override
  Future<void> save(TasbeehCounter counter) async {
    saves++;
    if (gate != null) await gate!.future;
    if (failSave != null) throw failSave!;
    stored = counter;
  }
}

void main() {
  group('TasbeehCounter', () {
    test('starts at zero with no target', () {
      const c = TasbeehCounter();
      expect(c.count, 0);
      expect(c.target, isNull);
      expect(c.progress, 0);
      expect(c.rounds, 0);
      expect(c.onTarget, isFalse);
    });

    test('counts up and down, never below zero', () {
      var c = const TasbeehCounter();
      c = c.increment().increment().increment();
      expect(c.count, 3);
      c = c.decrement();
      expect(c.count, 2);
      expect(const TasbeehCounter().decrement().count, 0);
    });

    test('stops at the largest count instead of growing past it', () {
      const full = TasbeehCounter(count: TasbeehCounter.maxCount);
      expect(full.isFull, isTrue);
      expect(full.increment(), full);
    });

    test('progress runs round by round, with a full ring on each multiple', () {
      expect(
        const TasbeehCounter(count: 1, target: 33).progress,
        closeTo(1 / 33, 1e-9),
      );
      expect(const TasbeehCounter(count: 33, target: 33).progress, 1);
      expect(
        const TasbeehCounter(count: 34, target: 33).progress,
        closeTo(1 / 33, 1e-9),
      );
      expect(const TasbeehCounter(count: 66, target: 33).progress, 1);
      expect(const TasbeehCounter(count: 40).progress, 0);
    });

    test('rounds and the target moment', () {
      expect(const TasbeehCounter(count: 98, target: 99).onTarget, isFalse);
      expect(const TasbeehCounter(count: 99, target: 99).onTarget, isTrue);
      expect(const TasbeehCounter(count: 198, target: 99).onTarget, isTrue);
      expect(const TasbeehCounter(count: 250, target: 100).rounds, 2);
      expect(const TasbeehCounter(count: 33).onTarget, isFalse);
    });

    test('reset keeps the target; a new target keeps the count', () {
      const c = TasbeehCounter(count: 50, target: 99);
      expect(c.reset(), const TasbeehCounter(target: 99));
      expect(c.withTarget(33), const TasbeehCounter(count: 50, target: 33));
      expect(c.withTarget(null), const TasbeehCounter(count: 50));
    });

    test('only the offered targets are accepted', () {
      for (final t in TasbeehCounter.targets) {
        expect(const TasbeehCounter().withTarget(t).target, t);
      }
      expect(() => const TasbeehCounter().withTarget(7), throwsArgumentError);
      expect(() => const TasbeehCounter().withTarget(0), throwsArgumentError);
    });
  });

  group('the stored counter', () {
    late UserDatabase database;
    late SqliteTasbeehRepository repository;

    setUp(() {
      database = UserDatabase.inMemory();
      repository = SqliteTasbeehRepository(database.db);
    });

    tearDown(() => database.db.close());

    test('is empty at first', () async {
      expect(await repository.load(), const TasbeehCounter());
    });

    test('keeps the count and the target', () async {
      await repository.save(const TasbeehCounter(count: 57, target: 99));
      expect(
        await repository.load(),
        const TasbeehCounter(count: 57, target: 99),
      );
      await repository.save(const TasbeehCounter(count: 58));
      expect(await repository.load(), const TasbeehCounter(count: 58));
    });

    test('there is only ever one row', () async {
      await repository.save(const TasbeehCounter(count: 1));
      await repository.save(const TasbeehCounter(count: 2));
      expect(database.db.select('SELECT * FROM tasbeeh_counter'), hasLength(1));
    });

    test('the table refuses values the counter cannot have', () {
      expect(
        () => database.db.execute(
          'INSERT INTO tasbeeh_counter (id, count, target) VALUES (1, -1, NULL)',
        ),
        throwsA(isA<SqliteException>()),
      );
      expect(
        () => database.db.execute(
          'INSERT INTO tasbeeh_counter (id, count, target) VALUES (1, 5, 7)',
        ),
        throwsA(isA<SqliteException>()),
      );
      expect(
        () => database.db.execute(
          'INSERT INTO tasbeeh_counter (id, count, target) VALUES (2, 5, NULL)',
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('stores nothing but the count and the target', () {
      final columns = database.db
          .select('PRAGMA table_info(tasbeeh_counter)')
          .map((r) => r['name'])
          .toList();
      expect(columns, ['id', 'count', 'target']);
    });
  });

  group('TasbeehCubit', () {
    late _MemoryRepository repository;
    late _Haptics haptics;
    late TasbeehCubit cubit;

    Future<void> open([TasbeehCounter? saved]) async {
      repository = _MemoryRepository();
      if (saved != null) repository.stored = saved;
      haptics = _Haptics();
      cubit = TasbeehCubit(repository: repository, haptics: haptics);
      addTearDown(cubit.close);
      await cubit.load();
    }

    test('continues from the saved count', () async {
      await open(const TasbeehCounter(count: 12, target: 33));
      expect(cubit.state.loaded, isTrue);
      expect(cubit.state.counter, const TasbeehCounter(count: 12, target: 33));
    });

    test(
      'taps before the saved count is read are ignored, not overwritten',
      () async {
        repository = _MemoryRepository()
          ..stored = const TasbeehCounter(count: 20);
        cubit = TasbeehCubit(repository: repository, haptics: _Haptics());
        addTearDown(cubit.close);
        await cubit.tap();
        expect(repository.saves, 0);
        await cubit.load();
        expect(cubit.state.counter.count, 20);
      },
    );

    test('a tap counts at once, before anything has been saved', () async {
      await open();
      repository.gate = Completer<void>();
      final saved = cubit.tap();
      expect(cubit.state.counter.count, 1);
      expect(repository.stored.count, 0);
      repository.gate!.complete();
      await saved;
      expect(repository.stored.count, 1);
    });

    test(
      'a hundred quick taps lose nothing, and the last save holds the total',
      () async {
        await open();
        repository.gate = Completer<void>();
        final saves = [for (var i = 0; i < 100; i++) cubit.tap()];
        expect(cubit.state.counter.count, 100);
        repository.gate!.complete();
        await Future.wait(saves);
        expect(repository.stored.count, 100);
      },
    );

    test('a tick for each tap, and a firmer one on the target', () async {
      await open(const TasbeehCounter(count: 31, target: 33));
      await cubit.tap();
      expect((haptics.selections, haptics.alignments), (1, 0));
      await cubit.tap();
      expect((haptics.selections, haptics.alignments), (1, 1));
      await cubit.tap();
      expect((haptics.selections, haptics.alignments), (2, 1));
    });

    test('no vibration when nothing changed', () async {
      await open(const TasbeehCounter(count: TasbeehCounter.maxCount));
      await cubit.tap();
      expect((haptics.selections, haptics.alignments), (0, 0));
      expect(repository.saves, 0);
    });

    test('undo, reset and target are saved', () async {
      await open();
      for (var i = 0; i < 5; i++) {
        await cubit.tap();
      }
      await cubit.undo();
      expect(repository.stored.count, 4);
      await cubit.setTarget(99);
      expect(repository.stored, const TasbeehCounter(count: 4, target: 99));
      await cubit.reset();
      expect(repository.stored, const TasbeehCounter(target: 99));
    });

    test('a failed save keeps the count on screen and says so', () async {
      await open();
      repository.failSave = StateError('disk');
      await cubit.tap();
      expect(cubit.state.counter.count, 1);
      expect(cubit.state.saveFailed, isTrue);
      repository.failSave = null;
      await cubit.tap();
      expect(cubit.state.saveFailed, isFalse);
      expect(repository.stored.count, 2);
    });

    test('a failed load still lets the user count, with a warning', () async {
      repository = _MemoryRepository()..failLoad = StateError('disk');
      cubit = TasbeehCubit(repository: repository, haptics: _Haptics());
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.loaded, isTrue);
      expect(cubit.state.saveFailed, isTrue);
      await cubit.tap();
      expect(cubit.state.counter.count, 1);
    });
  });
}
