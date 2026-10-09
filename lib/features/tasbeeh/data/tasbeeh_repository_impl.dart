import 'package:mynewapp/features/tasbeeh/domain/tasbeeh_counter.dart';
import 'package:mynewapp/features/tasbeeh/domain/tasbeeh_repository.dart';
import 'package:sqlite3/sqlite3.dart';

/// The counter in the user's own database (table `tasbeeh_counter`, a single row).
class SqliteTasbeehRepository implements TasbeehRepository {
  SqliteTasbeehRepository(this._db);

  final Database _db;

  @override
  Future<TasbeehCounter> load() async {
    final rows = _db.select(
      'SELECT count, target FROM tasbeeh_counter WHERE id = 1',
    );
    if (rows.isEmpty) return const TasbeehCounter();
    final count = rows.first['count'] as int;
    final target = rows.first['target'] as int?;
    return TasbeehCounter(
      count: count.clamp(0, TasbeehCounter.maxCount),
      target: TasbeehCounter.targets.contains(target) ? target : null,
    );
  }

  @override
  Future<void> save(TasbeehCounter counter) async {
    _db.execute(
      'INSERT INTO tasbeeh_counter (id, count, target) VALUES (1, ?, ?) '
      'ON CONFLICT(id) DO UPDATE SET count = excluded.count, target = excluded.target',
      [counter.count, counter.target],
    );
  }
}
