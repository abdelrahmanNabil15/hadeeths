import 'package:flutter/widgets.dart';
import 'package:mynewapp/l10n/app_localizations.dart';

export 'package:mynewapp/l10n/app_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// API language code for the current UI language (`ar` or `en`).
  String get apiLanguage => Localizations.localeOf(this).languageCode;
}
