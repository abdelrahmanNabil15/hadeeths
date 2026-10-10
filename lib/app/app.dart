import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mynewapp/app/app_dependencies.dart';
import 'package:mynewapp/app/shell/app_shell.dart';
import 'package:mynewapp/core/cache/response_cache.dart';
import 'package:mynewapp/core/design_system/app_theme.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/navigation/app_route.dart';
import 'package:mynewapp/core/share/image_sharer.dart';
import 'package:mynewapp/features/categories/domain/categories_repository.dart';
import 'package:mynewapp/features/categories/presentation/pages/home_page.dart';
import 'package:mynewapp/features/categories/presentation/state/categories_cubit.dart';
import 'package:mynewapp/features/favorites/domain/favorites_repository.dart';
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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Built once: a new ThemeData on every rebuild never compares equal to the last, which made the
  // theme animate on each settings change.
  final _lightTheme = AppTheme.light();
  final _darkTheme = AppTheme.dark();

  /// Changed after "Delete all my data": a new key gives the app a fresh navigator and fresh
  /// screens, so nothing still on screen shows data that no longer exists.
  int _generation = 0;
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  /// Kept here (not only in the tree) so that deleting all data can reset it.
  late final SettingsCubit _settings = SettingsCubit(
    widget.dependencies.settings,
    widget.initialSettings,
  );

  Future<bool> _eraseAll() async {
    final ok = await widget.dependencies.eraser.eraseAll();
    if (!ok || !mounted) return ok;
    await _settings.resetToDefaults();
    setState(() => _generation++);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messengerContext = _messenger.currentContext;
      if (messengerContext == null) return;
      _messenger.currentState?.showSnackBar(
        SnackBar(content: Text(messengerContext.l10n.deleteAllDone)),
      );
    });
    return true;
  }

  /// Prayer reminders are rebuilt from what is saved whenever the app starts or comes back, so they
  /// are right after a restart, a new day, or a change of clock, time zone or language.
  void _reconcileReminders() {
    final prayer = widget.dependencies.prayer;
    if (prayer != null && widget.dependencies.features.prayer) {
      unawaited(prayer.reminders.reconcile());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reconcileReminders();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settings.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reconcileReminders();
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
        // Nullable on purpose: screens show the bookmark only when favourites are available.
        RepositoryProvider<FavoritesRepository?>.value(
          value: deps.favoritesIfEnabled,
        ),
        // Nullable on purpose: without it a hadith is shared as text only, as in the released app.
        RepositoryProvider<ImageSharer?>.value(
          value: deps.imageSharerIfEnabled,
        ),
      ],
      child: BlocProvider.value(
        value: _settings,
        child: BlocListener<SettingsCubit, AppSettings>(
          listenWhen: (previous, current) =>
              previous.offlineCopies != current.offlineCopies,
          listener: (context, settings) {
            deps.cache.enabled = settings.offlineCopies;
            // Turning saved copies off also removes what is already on the device.
            if (!settings.offlineCopies) deps.cache.clear();
          },
          child: BlocListener<SettingsCubit, AppSettings>(
            // The words and numerals of a reminder follow the language and numeral settings. The
            // settings are saved a moment after they change, so wait for that before rebuilding.
            listenWhen: (previous, current) =>
                previous.language != current.language ||
                previous.digits != current.digits,
            listener: (context, settings) => Future<void>.delayed(
              const Duration(milliseconds: 400),
              _reconcileReminders,
            ),
            child: BlocBuilder<SettingsCubit, AppSettings>(
              builder: (context, settings) {
                final languageCode = settings.language.code;
                return MaterialApp(
                  key: ValueKey(_generation),
                  scaffoldMessengerKey: _messenger,
                  onGenerateTitle: (context) => context.l10n.appTitle,
                  theme: _lightTheme,
                  darkTheme: _darkTheme,
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
                    final arabicIndic = switch (settings.digits) {
                      DigitStyle.automatic => language == 'ar',
                      DigitStyle.arabicIndic => true,
                      DigitStyle.western => false,
                    };
                    return DigitScope(
                      digits: Digits(arabicIndic: arabicIndic),
                      child: BlocProvider(
                        key: ValueKey(language),
                        create: (context) => CategoriesCubit(
                          context.read<CategoriesRepository>(),
                          language: language,
                        )..load(),
                        child: child!,
                      ),
                    );
                  },
                  // The first page is an app route too, so the page under a pushed one is not
                  // moved by a different transition.
                  onGenerateRoute: (settings) => appRoute<void>(
                    settings: settings,
                    builder: (_) => deps.features.usesShell
                        ? AppShell(
                            features: deps.features,
                            prayer: deps.prayer,
                            prayerLog: deps.prayerLog,
                            tasbeeh: deps.tasbeeh,
                            favorites: deps.favoritesIfEnabled,
                            onDeleteAll: _eraseAll,
                            quran: deps.quran,
                            quranUserData: deps.quranUserData,
                          )
                        : const HomePage(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
