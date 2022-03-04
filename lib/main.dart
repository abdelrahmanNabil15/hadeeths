

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import 'Modules/cubit/cubit.dart';
import 'Shared/Network/DioHelper.dart';
import 'Modules/hadeethsCategory.dart';


import 'Shared/bloc_observer.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DioHelper.init();
  BlocOverrides.runZoned(
    () {
      runApp(const MyApp());
    },
    blocObserver: MyBlocObserver(),
  );

}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (BuildContext context) => AlmunirCubit()
              ..getCategories()
              ..checkConection(),
          ),
        ],
        child: MaterialApp(
          title: 'My app',
          theme: ThemeData(
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: AppBarTheme(

                  // ignore: deprecated_member_use
                  backwardsCompatibility: false,
                  titleTextStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold),
                  iconTheme: const IconThemeData(color: Colors.black),
                  systemOverlayStyle: SystemUiOverlayStyle(
                      statusBarColor: Colors.grey.shade100,
                      statusBarBrightness: Brightness.dark),
                  backgroundColor: Colors.white,
                  elevation: 2.0),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                  selectedItemColor: Colors.cyan,
                  elevation: 20.0,
                  type: BottomNavigationBarType.fixed)),
          home: const HadeethsCategory()
        ));

    /* */
  }
}
