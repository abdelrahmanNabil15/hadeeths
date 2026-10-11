import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/tokens.dart';

/// Named text styles built from the size and line-height tokens, so a screen picks a role
/// ("heading", "number") instead of assembling a style. Sizes scale with the device text setting.
///
/// Hadith text is not here: it has its own scaling (`ReadingText`) and must keep it.
@immutable
class AppTypography {
  const AppTypography._(this._color, this._muted);

  final Color _color;
  final Color _muted;

  static AppTypography of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppTypography._(scheme.onSurface, scheme.onSurfaceVariant);
  }

  TextStyle get display => TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: AppTextSize.display,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: _color,
  );

  TextStyle get title => TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: AppTextSize.title,
    fontWeight: FontWeight.w700,
    height: 1.35,
    color: _color,
  );

  TextStyle get heading => TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: AppTextSize.heading,
    fontWeight: FontWeight.w700,
    height: 1.4,
    color: _color,
  );

  TextStyle get body => TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: AppTextSize.body,
    height: AppLineHeight.body,
    color: _color,
  );

  /// Secondary information: counts, hints, explanations.
  TextStyle get meta => TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: AppTextSize.meta,
    height: AppLineHeight.body,
    color: _muted,
  );

  /// Buttons and small labels.
  TextStyle get label => TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: AppTextSize.meta,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: _color,
  );

  /// Editorial display: the home header and other large titles. Amiri carries both a Naskh Arabic
  /// and a serif Latin, so one role works in both languages.
  TextStyle get editorialTitle => TextStyle(
    fontFamily: AppFonts.editorial,
    fontSize: AppTextSize.display + 2,
    fontWeight: FontWeight.w700,
    height: 1.45,
    color: _color,
  );

  /// A smaller editorial title: a hadith's title, the title of an empty or error state.
  TextStyle get editorial => TextStyle(
    fontFamily: AppFonts.editorial,
    fontSize: AppTextSize.title,
    fontWeight: FontWeight.w700,
    height: 1.6,
    color: _color,
  );

  /// The label above a group of rows. No letter spacing: it would break Arabic joining.
  TextStyle get sectionLabel => TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: AppTextSize.meta + 1,
    fontWeight: FontWeight.w700,
    height: 1.4,
    color: _muted,
  );

  /// Times, counts and countdowns: equal-width digits where the font has them, so a changing
  /// number does not jiggle. (Cairo's support for this has not been checked.)
  TextStyle get number => TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: AppTextSize.heading,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: _color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
