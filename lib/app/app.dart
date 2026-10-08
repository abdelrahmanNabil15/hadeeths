import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mynewapp/app/app_dependencies.dart';
import 'package:mynewapp/core/design_system/app_theme.dart';
import 'package:mynewapp/features/categories/domain/categories_repository.dart';
import 'package:mynewapp/features/categories/presentation/pages/home_page.dart';
import 'package:mynewapp/features/categories/presentation/state/categories_cubit.dart';
import 'package:mynewapp/features/hadiths/domain/hadiths_repository.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// Debug-only way to preview the other language without changing the device language:
/// `flutter run --dart-define=FORCE_LOCALE=en` (or `ar`). Ignored in release builds.
const _forcedLocale = String.fromEnvironment('FORCE_LOCALE');

class MyApp extends StatefulWidget {
  /// [dependencies] lets tests and previews supply fakes; production uses
  /// [AppDependencies.live].
  const MyApp({super.key, this.dependencies});

  final AppDependencies? dependencies;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Created once, so a rebuild never swaps the repositories under live cubits.
  late final AppDependencies deps =
      widget.dependencies ?? AppDependencies.live();

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<CategoriesRepository>.value(value: deps.categories),
        RepositoryProvider<HadithsRepository>.value(value: deps.hadiths),
      ],
      child: MaterialApp(
        onGenerateTitle: (context) => context.l10n.appTitle,
        theme: AppTheme.light(),
        locale: kDebugMode && _forcedLocale.isNotEmpty
            ? Locale(_forcedLocale)
            : null,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // Arabic is listed first and is the fallback for any other device language.
        supportedLocales: AppLocalizations.supportedLocales,
        // One category tree for the whole app, above the navigator so it survives navigation.
        // It is keyed by language: a language change reloads the tree in the new language.
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
      ),
    );
  }
}
