import 'package:flutter/material.dart';

/// Colour roles that Material's [ColorScheme] does not have: success and warning, and the reading
/// surface. Everything else comes from the scheme.
///
/// Every text-on-background pair here is checked against WCAG AA (4.5:1) in
/// `test/core/app_colors_test.dart`. Read them with `AppColors.of(context)`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.readingSurface,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
  });

  /// Where hadith text is read (same as cards, named for what it is for).
  final Color readingSurface;

  /// Text or icon in the success colour, on the canvas or the reading surface.
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;

  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;

  static const light = AppColors(
    readingSurface: Color(0xFFFFFDF8),
    success: Color(0xFF1B6B3A),
    successContainer: Color(0xFFDCEFE0),
    onSuccessContainer: Color(0xFF0F3D22),
    warning: Color(0xFF8A5A00),
    warningContainer: Color(0xFFF6E7C1),
    onWarningContainer: Color(0xFF4A3300),
  );

  static const dark = AppColors(
    readingSurface: Color(0xFF161F1A),
    success: Color(0xFF7BD39A),
    successContainer: Color(0xFF1B3D28),
    onSuccessContainer: Color(0xFFCDEBD6),
    warning: Color(0xFFE0B25A),
    warningContainer: Color(0xFF4A3A14),
    onWarningContainer: Color(0xFFF3E3B5),
  );

  /// The roles of the current theme; the light ones if the theme was built without them.
  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? light;

  @override
  AppColors copyWith({
    Color? readingSurface,
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
  }) => AppColors(
    readingSurface: readingSurface ?? this.readingSurface,
    success: success ?? this.success,
    successContainer: successContainer ?? this.successContainer,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    warning: warning ?? this.warning,
    warningContainer: warningContainer ?? this.warningContainer,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
  );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      readingSurface: Color.lerp(readingSurface, other.readingSurface, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
    );
  }
}
