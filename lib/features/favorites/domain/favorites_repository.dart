/// The hadiths the user kept, by id only: no text, title or grade is stored, so nothing from the
/// source is copied into the user's data. The same id is the same hadith in every language, so a
/// favourite shows in whichever language the app is using. Stored on the device only.
abstract interface class FavoritesRepository {
  Future<bool> contains(String hadithId);

  /// Adds or removes [hadithId]. Doing it twice has the same effect as once.
  Future<void> setFavorite(String hadithId, {required bool favorite});

  /// The kept ids, most recently added first.
  Future<List<String>> all();

  /// Removes every favourite.
  Future<void> clear();
}
