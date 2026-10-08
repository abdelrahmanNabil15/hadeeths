import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mynewapp/app/app.dart';
import 'package:mynewapp/core/logging/app_bloc_observer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) Bloc.observer = AppBlocObserver();
  runApp(const MyApp());
}
