import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mynewapp/app/app_dependencies.dart';
import 'package:mynewapp/core/cache/response_cache.dart';
import 'package:mynewapp/core/design_system/app_theme.dart';
import 'package:mynewapp/features/categories/domain/categories_repository.dart';
import 'package:mynewapp/features/categories/presentation/pages/home_page.dart';
import 'package:mynewapp/features/categories/presentation/state/categories_cubit.dart';
import 'package:mynewapp/features/hadiths/domain/hadiths_repository.dart';
import 'package:mynewapp/features/search/domain/search_repository.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';
import 'package:mynewapp/features/settings/presentation/state/settings_cubit.dart';
import 'package:mynewapp/l10n/l10n.dart';

class MyApp extends StatefulWidget {
  /// [dependencies] lets tests and previews supply fakes; production passes
  /// [AppDependencies.live]. [initialSettings] are the saved preferences, loaded before the
  /// first frame so the app never flashes the wrong language or theme.
  const MyApp({
    super.key,
    required this.dependencies,
    this.initialSettings = const AppSettings(),
  });

  final AppDependencies dependencies;
  final AppSettings initialSettings;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // The saved choice is applied before anything is fetched.
    widget.dependencies.cache.enabled = widget.initialSettings.offlineCopies;
  }

  @override
  Widget build(BuildContext context) {
    final deps = widget.dependencies;
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<CategoriesRepository>.value(value: deps.categories),
        RepositoryProvider<HadithsRepository>.value(value: deps.hadiths),
        RepositoryProvider<SearchRepository>.value(value: deps.search),
        RepositoryProvider<ResponseCache>.value(value: deps.cache),
      ],
      child: BlocProvider(
        create: (_) => SettingsCubit(deps.settings, widget.initialSettings),
        child: BlocListener<SettingsCubit, AppSettings>(
          listenWhen: (previous, current) =>
              previous.offlineCopies != current.offlineCopies,
          listener: (context, settings) {
            deps.cache.enabled = settings.offlineCopies;
            // Turning saved copies off also removes what is already on the device.
            if (!settings.offlineCopies) deps.cache.clear();
          },
          child: BlocBuilder<SettingsCubit, AppSettings>(
            builder: (context, settings) {
              final languageCode = settings.language.code;
              return MaterialApp(
                onGenerateTitle: (context) => context.l10n.appTitle,
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: switch (settings.theme) {
                  ThemePreference.system => ThemeMode.system,
                  ThemePreference.light => ThemeMode.light,
                  ThemePreference.dark => ThemeMode.dark,
                },
                locale: languageCode == null ? null : Locale(languageCode),
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                // Arabic is listed first and is the fallback for any other device language.
                supportedLocales: AppLocalizations.supportedLocales,
                // One category tree for the whole app, above the navigator so it survives
                // navigation. It is keyed by language: a language change reloads the tree.
                builder: (context, child) {
                  final language = context.apiLanguage;
                  return BlocProvider(
                    key: ValueKey(language),
                    create: (context) => CategoriesCubit(
                      context.read<CategoriesRepository>(),
                      language: language,
                    )..load(),
                    child: child!,
                  );
                },
                home: const HomePage(),
              );
            },
          ),
        ),
      ),
    );
  }
}
