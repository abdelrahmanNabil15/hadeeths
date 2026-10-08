import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'Modules/categories/categories_cubit.dart';
import 'Modules/home_page.dart';
import 'Shared/Network/hadeeth_api.dart';
import 'Shared/bloc_observer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) Bloc.observer = MyBlocObserver();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  /// [api] lets tests and previews supply a fake; production uses [HttpHadeethApi].
  const MyApp({super.key, this.api});

  final HadeethApi? api;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<HadeethApi>(
      create: (_) => api ?? HttpHadeethApi(),
      // One category tree for the whole app, above the navigator so it survives navigation.
      child: BlocProvider(
        create: (context) =>
            CategoriesCubit(context.read<HadeethApi>())..load(),
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
