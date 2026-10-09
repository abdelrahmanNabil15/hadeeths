import 'package:mynewapp/core/time/clock.dart';
import 'package:mynewapp/features/favorites/domain/favorites_repository.dart';
import 'package:sqlite3/sqlite3.dart';

/// Favourites in the user's own database (table `favorites`).
class SqliteFavoritesRepository implements FavoritesRepository {
  SqliteFavoritesRepository(this._db, {this._clock = const SystemClock()});

  final Database _db;
  final Clock _clock;

  /// The API's ids are digits; anything else is refused rather than stored.
  static final _validId = RegExp(r'^[0-9]{1,12}$');

  @override
  Future<bool> contains(String hadithId) async => _db.select(
    'SELECT 1 FROM favorites WHERE hadith_id = ?',
    [hadithId],
  ).isNotEmpty;

  @override
  Future<void> setFavorite(String hadithId, {required bool favorite}) async {
    if (!_validId.hasMatch(hadithId)) {
      throw ArgumentError.value(hadithId, 'hadithId', 'not a hadith id');
    }
    if (favorite) {
      _db.execute(
        'INSERT OR IGNORE INTO favorites (hadith_id, added_at) VALUES (?, ?)',
        [hadithId, _clock.now().toUtc().millisecondsSinceEpoch],
      );
    } else {
      _db.execute('DELETE FROM favorites WHERE hadith_id = ?', [hadithId]);
    }
  }

  @override
  Future<List<String>> all() async => [
    for (final row in _db.select(
      'SELECT hadith_id FROM favorites ORDER BY added_at DESC, hadith_id DESC',
    ))
      row['hadith_id'] as String,
  ];

  @override
  Future<void> clear() async => _db.execute('DELETE FROM favorites');
}
