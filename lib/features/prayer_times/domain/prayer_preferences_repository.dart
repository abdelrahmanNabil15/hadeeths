import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';

/// Saves the place and calculation choices on the device. Nothing leaves the device.
abstract interface class PrayerPreferencesRepository {
  /// What was saved, or a fresh [PrayerPreferences] when nothing was saved or the saved data is
  /// unreadable (never throws).
  Future<PrayerPreferences> load();

  Future<void> save(PrayerPreferences preferences);

  /// Forgets the place and every choice ("Delete my data").
  Future<void> clear();
}
