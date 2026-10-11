import 'package:flutter/material.dart';

/// Colour roles that Material's [ColorScheme] does not have: success and warning, the reading
/// surface, the restrained gold and sage accents, and the midnight-emerald hero. Everything else
/// comes from the scheme.
///
/// Every text-on-background pair here is checked against WCAG AA (4.5:1), and every mark or
/// ornament against 3:1, in `test/core/app_colors_test.dart`. Read them with `AppColors.of(context)`.
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
    required this.gold,
    required this.goldSoft,
    required this.sage,
    required this.onSage,
    required this.hero,
    required this.onHero,
    required this.onHeroMuted,
    required this.heroAccent,
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

  /// Muted gold for thin rules, small ornaments and selected marks. Never body text, never a large
  /// area. At least 3:1 against the canvas and cards.
  final Color gold;

  /// A paler gold for hairline ornaments that must stay quiet.
  final Color goldSoft;

  /// Soft sage: secondary surfaces, count pills.
  final Color sage;
  final Color onSage;

  /// Midnight emerald behind the home header, with its text colours and its gold ornament.
  final Color hero;
  final Color onHero;
  final Color onHeroMuted;
  final Color heroAccent;

  static const light = AppColors(
    readingSurface: Color(0xFFFFFDF8),
    success: Color(0xFF1B6B3A),
    successContainer: Color(0xFFDCEFE0),
    onSuccessContainer: Color(0xFF0F3D22),
    warning: Color(0xFF8A5A00),
    warningContainer: Color(0xFFF6E7C1),
    onWarningContainer: Color(0xFF4A3300),
    gold: Color(0xFFA07C2C),
    goldSoft: Color(0xFFE3D3A6),
    sage: Color(0xFFE4ECE5),
    onSage: Color(0xFF2C463B),
    hero: Color(0xFF0B3F33),
    onHero: Color(0xFFF7F2E6),
    onHeroMuted: Color(0xFFC4D6CC),
    heroAccent: Color(0xFFD6B568),
  );

  static const dark = AppColors(
    readingSurface: Color(0xFF131B18),
    success: Color(0xFF7BD39A),
    successContainer: Color(0xFF1B3D28),
    onSuccessContainer: Color(0xFFCDEBD6),
    warning: Color(0xFFE0B25A),
    warningContainer: Color(0xFF4A3A14),
    onWarningContainer: Color(0xFFF3E3B5),
    gold: Color(0xFFCFAE62),
    goldSoft: Color(0xFF5E4E26),
    sage: Color(0xFF1D2B25),
    onSage: Color(0xFFC6DCCF),
    hero: Color(0xFF0F2E26),
    onHero: Color(0xFFEDE8DA),
    onHeroMuted: Color(0xFFA8C3B6),
    heroAccent: Color(0xFFCFAE62),
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
    Color? gold,
    Color? goldSoft,
    Color? sage,
    Color? onSage,
    Color? hero,
    Color? onHero,
    Color? onHeroMuted,
    Color? heroAccent,
  }) => AppColors(
    readingSurface: readingSurface ?? this.readingSurface,
    success: success ?? this.success,
    successContainer: successContainer ?? this.successContainer,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    warning: warning ?? this.warning,
    warningContainer: warningContainer ?? this.warningContainer,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    gold: gold ?? this.gold,
    goldSoft: goldSoft ?? this.goldSoft,
    sage: sage ?? this.sage,
    onSage: onSage ?? this.onSage,
    hero: hero ?? this.hero,
    onHero: onHero ?? this.onHero,
    onHeroMuted: onHeroMuted ?? this.onHeroMuted,
    heroAccent: heroAccent ?? this.heroAccent,
  );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      readingSurface: mix(readingSurface, other.readingSurface),
      success: mix(success, other.success),
      successContainer: mix(successContainer, other.successContainer),
      onSuccessContainer: mix(onSuccessContainer, other.onSuccessContainer),
      warning: mix(warning, other.warning),
      warningContainer: mix(warningContainer, other.warningContainer),
      onWarningContainer: mix(onWarningContainer, other.onWarningContainer),
      gold: mix(gold, other.gold),
      goldSoft: mix(goldSoft, other.goldSoft),
      sage: mix(sage, other.sage),
      onSage: mix(onSage, other.onSage),
      hero: mix(hero, other.hero),
      onHero: mix(onHero, other.onHero),
      onHeroMuted: mix(onHeroMuted, other.onHeroMuted),
      heroAccent: mix(heroAccent, other.heroAccent),
    );
  }
}
