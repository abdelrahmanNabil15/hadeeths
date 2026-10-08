import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/app/app_dependencies.dart';
import 'package:mynewapp/features/categories/domain/categories_repository.dart';
import 'package:mynewapp/features/categories/presentation/pages/home_page.dart';
import 'package:mynewapp/features/categories/presentation/state/categories_cubit.dart';
import 'package:mynewapp/features/hadiths/domain/hadiths_repository.dart';

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
      // One category tree for the whole app, above the navigator so it survives navigation.
      child: BlocProvider(
        create: (context) =>
            CategoriesCubit(context.read<CategoriesRepository>())..load(),
        child: MaterialApp(
          title: 'My app',
          theme: ThemeData(
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: AppBarTheme(
              titleTextStyle: const TextStyle(
                color: Colors.black,
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: const IconThemeData(color: Colors.black),
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.grey.shade100,
                statusBarBrightness: Brightness.dark,
              ),
              backgroundColor: Colors.white,
              elevation: 2.0,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              selectedItemColor: Colors.cyan,
              elevation: 20.0,
              type: BottomNavigationBarType.fixed,
            ),
          ),
          home: const HomePage(),
        ),
      ),
    );
  }
}
