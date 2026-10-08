import 'package:mynewapp/features/settings/domain/app_settings.dart';

abstract interface class SettingsRepository {
  /// Never fails: anything unreadable falls back to the defaults.
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}
