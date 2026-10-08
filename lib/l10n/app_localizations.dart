import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// App name shown in the home app bar and the task switcher.
  ///
  /// In ar, this message translates to:
  /// **'الأحاديث النبوية'**
  String get appTitle;

  /// No description provided for @mainCategories.
  ///
  /// In ar, this message translates to:
  /// **'التصنيفات الرئيسية'**
  String get mainCategories;

  /// No description provided for @noCategories.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تصنيفات'**
  String get noCategories;

  /// No description provided for @categoryUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'هذا التصنيف غير متوفر'**
  String get categoryUnavailable;

  /// No description provided for @allHadithsInCategory.
  ///
  /// In ar, this message translates to:
  /// **'جميع الأحاديث في هذا التصنيف'**
  String get allHadithsInCategory;

  /// Screen-reader label of a category card: the title and the number of hadiths.
  ///
  /// In ar, this message translates to:
  /// **'{title}، {count}'**
  String categoryCardSemantics(String title, String count);

  /// No description provided for @noHadithsInCategory.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أحاديث في هذا التصنيف'**
  String get noHadithsInCategory;

  /// No description provided for @errorNoConnection.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت'**
  String get errorNoConnection;

  /// No description provided for @errorTimeout.
  ///
  /// In ar, this message translates to:
  /// **'انتهت مهلة الاتصال بالخادم'**
  String get errorTimeout;

  /// No description provided for @errorServer.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ في الخادم، حاول مرة أخرى لاحقًا'**
  String get errorServer;

  /// No description provided for @errorNotFound.
  ///
  /// In ar, this message translates to:
  /// **'هذا المحتوى غير متوفر'**
  String get errorNotFound;

  /// No description provided for @errorParse.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر قراءة البيانات المستلمة'**
  String get errorParse;

  /// No description provided for @errorUnexpected.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع'**
  String get errorUnexpected;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل'**
  String get loading;

  /// No description provided for @shareHadith.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة الحديث'**
  String get shareHadith;

  /// No description provided for @share.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get share;

  /// No description provided for @hadithLabel.
  ///
  /// In ar, this message translates to:
  /// **'الحديث:'**
  String get hadithLabel;

  /// No description provided for @explanation.
  ///
  /// In ar, this message translates to:
  /// **'الشرح'**
  String get explanation;

  /// No description provided for @explanationTitle.
  ///
  /// In ar, this message translates to:
  /// **'الشرح:'**
  String get explanationTitle;

  /// No description provided for @benefits.
  ///
  /// In ar, this message translates to:
  /// **'الفوائد:'**
  String get benefits;

  /// No description provided for @wordMeanings.
  ///
  /// In ar, this message translates to:
  /// **'معاني الكلمات:'**
  String get wordMeanings;

  /// No description provided for @sources.
  ///
  /// In ar, this message translates to:
  /// **'المصادر'**
  String get sources;

  /// No description provided for @sourcesTitle.
  ///
  /// In ar, this message translates to:
  /// **'المصادر:'**
  String get sourcesTitle;

  /// Credit line the HadeethEnc terms require next to its content. Keep the site name unchanged.
  ///
  /// In ar, this message translates to:
  /// **'المصدر: HadeethEnc.com'**
  String get sourceCredit;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
