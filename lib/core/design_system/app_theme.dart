import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mynewapp/core/design_system/tokens.dart';

abstract final class AppTheme {
  static ThemeData light() {
    return ThemeData(
      fontFamily: AppFonts.family,
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: AppBarTheme(
        titleTextStyle: const TextStyle(
          color: AppColors.onAppBar,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          fontFamily: AppFonts.family,
        ),
        iconTheme: const IconThemeData(color: AppColors.onAppBar),
        actionsIconTheme: const IconThemeData(color: AppColors.onAppBar),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.grey.shade100,
          statusBarBrightness: Brightness.dark,
        ),
        backgroundColor: AppColors.surface,
        elevation: 2.0,
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
