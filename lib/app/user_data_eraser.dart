import 'package:mynewapp/core/cache/response_cache.dart';
import 'package:mynewapp/core/database/user_database.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_services.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';
import 'package:mynewapp/features/settings/domain/settings_repository.dart';

/// "Delete all my data": everything the app keeps on the phone about the user.
///
/// In order: scheduled reminders are cancelled first (so nothing fires for a place that is about
/// to be forgotten), then the saved place and prayer choices, the user's own database (tracker,
/// counter, favourites), the saved copies of opened content, and finally the app settings. Every
/// step is tried even if an earlier one fails, and the result says whether all of them worked.
class UserDataEraser {
  UserDataEraser({
    required this.settings,
    required this.cache,
    this.userData,
    this.prayer,
  });

  final SettingsRepository settings;
  final ResponseCache cache;
  final UserDatabase? userData;
  final PrayerServices? prayer;

  /// True when every step succeeded.
  Future<bool> eraseAll() async {
    var ok = true;
    Future<void> step(Future<void> Function() run) async {
      try {
        await run();
      } on Object {
        ok = false;
      }
    }

    final prayer = this.prayer;
    if (prayer != null) {
      await step(prayer.reminders.cancelAll);
      await step(prayer.preferences.clear);
    }
    final userData = this.userData;
    if (userData != null) await step(() async => userData.clearUserTables());
    await step(cache.clear);
    await step(() => settings.save(const AppSettings()));
    return ok;
  }
}
