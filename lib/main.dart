import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mynewapp/app/app.dart';
import 'package:mynewapp/app/app_dependencies.dart';
import 'package:mynewapp/core/cache/file_response_cache.dart';
import 'package:mynewapp/core/cache/response_cache.dart';
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

  final dependencies = AppDependencies.live(
    preferences: await SharedPreferences.getInstance(),
    cache: cache,
  );
  // Saved language, theme and the offline setting are known before the first frame.
  final settings = await dependencies.settings.load();
  runApp(MyApp(dependencies: dependencies, initialSettings: settings));
}
