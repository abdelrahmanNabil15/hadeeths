/// The five daily prayers and sunrise (the end of the Fajr period), in the order they occur.
enum Prayer {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha;

  /// Sunrise is a time of day, not a prayer.
  bool get isPrayer => this != sunrise;
}
