/// What the screens can do about rating, without knowing how it works.
abstract interface class ReviewActions {
  /// A qualifying action was completed (a hadith read, a prayer marked, a counting round
  /// finished, a Quran place saved). [key] identifies it, so repeats on the same day count once.
  /// Never throws and never waits.
  void recordAction(String key);

  /// Whether the manual "Rate" entry can open the store page here.
  bool get manualAvailable;

  /// Opens the app's page in the store, where the user can rate it. Always possible, whatever
  /// the automatic rules say.
  Future<void> rateNow();
}
