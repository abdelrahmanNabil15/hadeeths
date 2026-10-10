import 'package:mynewapp/core/time/clock.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';
import 'package:sqlite3/sqlite3.dart';

/// Last-read place and bookmarks in the user's own database (tables `quran_last_read` and
/// `quran_bookmarks`).
class SqliteQuranUserData implements QuranUserData {
  SqliteQuranUserData(this._db, {this._clock = const SystemClock()});

  final Database _db;
  final Clock _clock;

  int get _now => _clock.now().toUtc().millisecondsSinceEpoch;

  static void _check(VerseRef place) {
    RangeError.checkValueInInterval(place.sura, 1, 114, 'sura');
    RangeError.checkValueInInterval(place.verse, 1, 286, 'verse');
  }

  @override
  Future<VerseRef?> lastRead() async {
    final rows = _db.select(
      'SELECT sura, verse FROM quran_last_read WHERE id = 1',
    );
    if (rows.isEmpty) return null;
    return VerseRef(rows.first['sura'] as int, rows.first['verse'] as int);
  }

  @override
  Future<void> setLastRead(VerseRef place) async {
    _check(place);
    _db.execute(
      'INSERT INTO quran_last_read (id, sura, verse, updated_at) VALUES (1, ?, ?, ?) '
      'ON CONFLICT(id) DO UPDATE SET sura = excluded.sura, verse = excluded.verse, '
      'updated_at = excluded.updated_at',
      [place.sura, place.verse, _now],
    );
  }

  @override
  Future<List<VerseRef>> bookmarks() async => [
    for (final row in _db.select(
      'SELECT sura, verse FROM quran_bookmarks ORDER BY sura, verse',
    ))
      VerseRef(row['sura'] as int, row['verse'] as int),
  ];

  @override
  Future<bool> isBookmarked(VerseRef place) async => _db.select(
    'SELECT 1 FROM quran_bookmarks WHERE sura = ? AND verse = ?',
    [place.sura, place.verse],
  ).isNotEmpty;

  @override
  Future<void> setBookmark(VerseRef place, {required bool on}) async {
    _check(place);
    if (on) {
      _db.execute(
        'INSERT OR IGNORE INTO quran_bookmarks (sura, verse, added_at) VALUES (?, ?, ?)',
        [place.sura, place.verse, _now],
      );
    } else {
      _db.execute('DELETE FROM quran_bookmarks WHERE sura = ? AND verse = ?', [
        place.sura,
        place.verse,
      ]);
    }
  }
}
