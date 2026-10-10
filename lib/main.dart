import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mynewapp/app/app.dart';
import 'package:mynewapp/app/app_dependencies.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/app/prayer_wiring.dart';
import 'package:mynewapp/app/quran_wiring.dart';
import 'package:mynewapp/core/cache/file_response_cache.dart';
import 'package:mynewapp/core/cache/response_cache.dart';
import 'package:mynewapp/core/database/user_database.dart';
import 'package:mynewapp/core/licences.dart';
import 'package:mynewapp/core/logging/app_bloc_observer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) Bloc.observer = AppBlocObserver();
  registerFontLicences();

  // Saved copies live in the app's private storage (not the OS-clearable cache folder), so
  // opened hadiths stay readable offline. Only this app can read them.
  final support = await getApplicationSupportDirectory();
  final cache = SwitchableResponseCache(
    FileResponseCache(
      Directory('${support.path}${Platform.pathSeparator}saved_copies'),
    ),
  );

  // The user's own data. If it cannot be opened the app still works; features that need it
  // report that storage is unavailable.
  UserDatabase? userData;
  try {
    userData = UserDatabase.openFile(
      File(
        '${support.path}${Platform.pathSeparator}user_data${Platform.pathSeparator}user_data.db',
      ),
    );
    if (kDebugMode) {
      debugPrint(
        'user database ready (opened at schema v${userData.migratedFrom}, '
        'recovered: ${userData.recoveredFrom != null})',
      );
    }
  } on Object catch (error) {
    if (kDebugMode) debugPrint('user database unavailable: $error');
  }

  final preferences = await SharedPreferences.getInstance();
  // The reminders read the saved language and numerals through the app's own settings
  // repository, which exists once the dependencies are built; they only look when asked, later.
  late final AppDependencies dependencies;
  dependencies = AppDependencies.live(
    preferences: preferences,
    prayer: buildPrayerServices(
      preferences: preferences,
      loadAppSettings: () => dependencies.settings.load(),
    ),
    cache: cache,
    userData: userData,
    features: FeatureFlags.fromEnvironment(),
    quran: buildQuranSource(),
  );
  // Saved language, theme and the offline setting are known before the first frame.
  final settings = await dependencies.settings.load();
  runApp(MyApp(dependencies: dependencies, initialSettings: settings));
}
