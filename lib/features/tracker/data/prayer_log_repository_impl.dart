import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/tracker/domain/day_key.dart';
import 'package:mynewapp/features/tracker/domain/prayer_log_repository.dart';
import 'package:sqlite3/sqlite3.dart';

/// The prayer log in the user's own database (table `prayer_log`).
class SqlitePrayerLogRepository implements PrayerLogRepository {
  SqlitePrayerLogRepository(this._db);

  final Database _db;

  @override
  Future<Map<DayKey, Set<Prayer>>> between(DayKey from, DayKey to) async {
    final rows = _db.select(
      'SELECT day, prayer FROM prayer_log WHERE day BETWEEN ? AND ?',
      [from.id, to.id],
    );
    final result = <DayKey, Set<Prayer>>{};
    for (final row in rows) {
      final prayer = Prayer.values.asNameMap()[row['prayer'] as String];
      if (prayer == null || !prayer.isPrayer) continue;
      final day = DayKey.parse(row['day'] as String);
      (result[day] ??= {}).add(prayer);
    }
    return result;
  }

  @override
  Future<void> setDone(DayKey day, Prayer prayer, {required bool done}) async {
    if (!prayer.isPrayer) {
      throw ArgumentError.value(prayer, 'prayer', 'sunrise is not a prayer');
    }
    if (done) {
      _db.execute(
        'INSERT OR IGNORE INTO prayer_log (day, prayer) VALUES (?, ?)',
        [day.id, prayer.name],
      );
    } else {
      _db.execute('DELETE FROM prayer_log WHERE day = ? AND prayer = ?', [
        day.id,
        prayer.name,
      ]);
    }
  }

  @override
  Future<void> deleteAll() async {
    _db.execute('DELETE FROM prayer_log');
  }
}
