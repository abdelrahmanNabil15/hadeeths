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

  /// No description provided for @homeIntro.
  ///
  /// In ar, this message translates to:
  /// **'تصفّح الأحاديث حسب التصنيف، أو ابحث بكلمة.'**
  String get homeIntro;

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

  /// Screen-reader label of a tile: the title and the number of hadiths.
  ///
  /// In ar, this message translates to:
  /// **'{title}، {count}'**
  String tileSemantics(String title, String count);

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

  /// No description provided for @explanation.
  ///
  /// In ar, this message translates to:
  /// **'الشرح'**
  String get explanation;

  /// No description provided for @benefits.
  ///
  /// In ar, this message translates to:
  /// **'الفوائد'**
  String get benefits;

  /// No description provided for @wordMeanings.
  ///
  /// In ar, this message translates to:
  /// **'معاني الكلمات'**
  String get wordMeanings;

  /// No description provided for @sources.
  ///
  /// In ar, this message translates to:
  /// **'المصادر'**
  String get sources;

  /// Credit line the HadeethEnc terms require next to its content. Keep the site name unchanged.
  ///
  /// In ar, this message translates to:
  /// **'المصدر: HadeethEnc.com'**
  String get sourceCredit;

  /// No description provided for @searchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في الأحاديث'**
  String get searchHint;

  /// No description provided for @searchClear.
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get searchClear;

  /// No description provided for @searchPrompt.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كلمة أو عبارة للبحث في نصوص الأحاديث.'**
  String get searchPrompt;

  /// No description provided for @searchTooShort.
  ///
  /// In ar, this message translates to:
  /// **'اكتب {min} أحرف على الأقل.'**
  String searchTooShort(int min);

  /// No description provided for @searchNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج لـ «{query}»'**
  String searchNoResults(String query);

  /// No description provided for @searchTruncated.
  ///
  /// In ar, this message translates to:
  /// **'تُعرض أول {count} نتيجة فقط. حدّد بحثك للحصول على نتائج أدق.'**
  String searchTruncated(int count);

  /// No description provided for @searchResultCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} نتيجة'**
  String searchResultCount(int count);

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In ar, this message translates to:
  /// **'لغة الجهاز'**
  String get languageSystem;

  /// No description provided for @languageArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @theme.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In ar, this message translates to:
  /// **'حسب الجهاز'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get themeDark;

  /// No description provided for @textSize.
  ///
  /// In ar, this message translates to:
  /// **'حجم النص'**
  String get textSize;

  /// No description provided for @textSizeSmaller.
  ///
  /// In ar, this message translates to:
  /// **'تصغير النص'**
  String get textSizeSmaller;

  /// No description provided for @textSizeLarger.
  ///
  /// In ar, this message translates to:
  /// **'تكبير النص'**
  String get textSizeLarger;

  /// No description provided for @textSizeSample.
  ///
  /// In ar, this message translates to:
  /// **'عَنْ أَبِي هُرَيْرَةَ رَضِيَ اللهُ عَنْهُ'**
  String get textSizeSample;

  /// No description provided for @aboutTitle.
  ///
  /// In ar, this message translates to:
  /// **'المصادر والحقوق'**
  String get aboutTitle;

  /// No description provided for @aboutContentHeading.
  ///
  /// In ar, this message translates to:
  /// **'المحتوى'**
  String get aboutContentHeading;

  /// No description provided for @aboutContentBody.
  ///
  /// In ar, this message translates to:
  /// **'الأحاديث وشروحها وترجماتها من موقع HadeethEnc.com، وتُعرض كما نُشرت دون تعديل.'**
  String get aboutContentBody;

  /// No description provided for @aboutFontsHeading.
  ///
  /// In ar, this message translates to:
  /// **'الخطوط'**
  String get aboutFontsHeading;

  /// No description provided for @aboutFontsBody.
  ///
  /// In ar, this message translates to:
  /// **'خط Cairo وخط Amiri، برخصة SIL Open Font License 1.1.'**
  String get aboutFontsBody;

  /// No description provided for @aboutPrivacyHeading.
  ///
  /// In ar, this message translates to:
  /// **'الخصوصية'**
  String get aboutPrivacyHeading;

  /// No description provided for @aboutPrivacyBody.
  ///
  /// In ar, this message translates to:
  /// **'لا يجمع التطبيق أي بيانات شخصية. يحتاج إلى الإنترنت لتحميل المحتوى، ويحفظ على جهازك نسخًا مما فتحته لتقرأه دون اتصال، ويمكنك إيقاف ذلك أو مسحه من الإعدادات.'**
  String get aboutPrivacyBody;

  /// No description provided for @openSourceLicences.
  ///
  /// In ar, this message translates to:
  /// **'تراخيص البرمجيات مفتوحة المصدر'**
  String get openSourceLicences;

  /// No description provided for @offlineCopies.
  ///
  /// In ar, this message translates to:
  /// **'القراءة دون اتصال'**
  String get offlineCopies;

  /// No description provided for @offlineCopiesHint.
  ///
  /// In ar, this message translates to:
  /// **'احتفظ على هذا الجهاز بالأحاديث التي فتحتها لتقرأها دون إنترنت.'**
  String get offlineCopiesHint;

  /// No description provided for @clearSavedCopies.
  ///
  /// In ar, this message translates to:
  /// **'مسح النسخ المحفوظة'**
  String get clearSavedCopies;

  /// No description provided for @savedCopiesCleared.
  ///
  /// In ar, this message translates to:
  /// **'تم مسح النسخ المحفوظة'**
  String get savedCopiesCleared;

  /// No description provided for @digitsHeading.
  ///
  /// In ar, this message translates to:
  /// **'الأرقام'**
  String get digitsHeading;

  /// No description provided for @digitsAutomatic.
  ///
  /// In ar, this message translates to:
  /// **'حسب اللغة'**
  String get digitsAutomatic;

  /// No description provided for @digitsArabicIndic.
  ///
  /// In ar, this message translates to:
  /// **'الأرقام العربية الهندية (٠١٢٣)'**
  String get digitsArabicIndic;

  /// No description provided for @digitsWestern.
  ///
  /// In ar, this message translates to:
  /// **'الأرقام الغربية (0123)'**
  String get digitsWestern;

  /// No description provided for @navHadiths.
  ///
  /// In ar, this message translates to:
  /// **'الأحاديث'**
  String get navHadiths;

  /// No description provided for @navQuran.
  ///
  /// In ar, this message translates to:
  /// **'المصحف'**
  String get navQuran;

  /// No description provided for @navPrayer.
  ///
  /// In ar, this message translates to:
  /// **'الصلاة'**
  String get navPrayer;

  /// No description provided for @navMore.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get navMore;

  /// No description provided for @navigationLabel.
  ///
  /// In ar, this message translates to:
  /// **'الأقسام الرئيسية'**
  String get navigationLabel;

  /// No description provided for @comingSoon.
  ///
  /// In ar, this message translates to:
  /// **'قريبًا'**
  String get comingSoon;

  /// No description provided for @comingSoonBody.
  ///
  /// In ar, this message translates to:
  /// **'هذا القسم قيد الإعداد وليس متاحًا بعد.'**
  String get comingSoonBody;

  /// No description provided for @prayerTimesTitle.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت الصلاة'**
  String get prayerTimesTitle;

  /// No description provided for @prayerSetupTitle.
  ///
  /// In ar, this message translates to:
  /// **'حدّد موقعك'**
  String get prayerSetupTitle;

  /// No description provided for @prayerSetupBody.
  ///
  /// In ar, this message translates to:
  /// **'تعتمد مواقيت الصلاة على مكانك. اختر طريقة تحديده.'**
  String get prayerSetupBody;

  /// No description provided for @useMyLocation.
  ///
  /// In ar, this message translates to:
  /// **'استخدم موقعي'**
  String get useMyLocation;

  /// No description provided for @chooseCity.
  ///
  /// In ar, this message translates to:
  /// **'اختر مدينة'**
  String get chooseCity;

  /// No description provided for @locationExplainTitle.
  ///
  /// In ar, this message translates to:
  /// **'استخدام موقعك؟'**
  String get locationExplainTitle;

  /// No description provided for @locationExplainBody.
  ///
  /// In ar, this message translates to:
  /// **'يقرأ التطبيق موقعك مرة واحدة الآن، لحساب مواقيت الصلاة في مكانك فقط. لا يُتتبَّع ولا يُشارك، ويُحفظ تقريبًا إلى نحو كيلومتر. يمكنك اختيار مدينة بدلًا من ذلك.'**
  String get locationExplainBody;

  /// No description provided for @continueAction.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get continueAction;

  /// No description provided for @notNow.
  ///
  /// In ar, this message translates to:
  /// **'ليس الآن'**
  String get notNow;

  /// No description provided for @locating.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحديد موقعك…'**
  String get locating;

  /// No description provided for @locationDenied.
  ///
  /// In ar, this message translates to:
  /// **'لم يُمنح إذن الموقع. يمكنك المحاولة مرة أخرى أو اختيار مدينة.'**
  String get locationDenied;

  /// No description provided for @locationNeedsSettings.
  ///
  /// In ar, this message translates to:
  /// **'إذن الموقع متوقف لهذا التطبيق. افتح الإعدادات للسماح به، أو اختر مدينة.'**
  String get locationNeedsSettings;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In ar, this message translates to:
  /// **'خدمة الموقع متوقفة على هذا الجهاز. شغّلها أو اختر مدينة.'**
  String get locationServiceDisabled;

  /// No description provided for @locationTimeout.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحديد موقعك في الوقت المناسب. حاول مرة أخرى أو اختر مدينة.'**
  String get locationTimeout;

  /// No description provided for @locationUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'موقعك غير متاح الآن. حاول مرة أخرى أو اختر مدينة.'**
  String get locationUnavailable;

  /// No description provided for @openSettings.
  ///
  /// In ar, this message translates to:
  /// **'فتح الإعدادات'**
  String get openSettings;

  /// No description provided for @cityPickerTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر مدينة'**
  String get cityPickerTitle;

  /// No description provided for @citySearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن مدينة'**
  String get citySearchHint;

  /// No description provided for @cityNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مدينة تطابق «{query}»'**
  String cityNoResults(String query);

  /// No description provided for @currentLocation.
  ///
  /// In ar, this message translates to:
  /// **'الموقع الحالي'**
  String get currentLocation;

  /// No description provided for @changeLocation.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الموقع'**
  String get changeLocation;

  /// No description provided for @nextPrayerLabel.
  ///
  /// In ar, this message translates to:
  /// **'الصلاة التالية'**
  String get nextPrayerLabel;

  /// No description provided for @prayerFajr.
  ///
  /// In ar, this message translates to:
  /// **'الفجر'**
  String get prayerFajr;

  /// No description provided for @prayerSunrise.
  ///
  /// In ar, this message translates to:
  /// **'الشروق'**
  String get prayerSunrise;

  /// No description provided for @prayerDhuhr.
  ///
  /// In ar, this message translates to:
  /// **'الظهر'**
  String get prayerDhuhr;

  /// No description provided for @prayerAsr.
  ///
  /// In ar, this message translates to:
  /// **'العصر'**
  String get prayerAsr;

  /// No description provided for @prayerMaghrib.
  ///
  /// In ar, this message translates to:
  /// **'المغرب'**
  String get prayerMaghrib;

  /// No description provided for @prayerIsha.
  ///
  /// In ar, this message translates to:
  /// **'العشاء'**
  String get prayerIsha;

  /// No description provided for @methodHeading.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الحساب'**
  String get methodHeading;

  /// No description provided for @methodEgyptian.
  ///
  /// In ar, this message translates to:
  /// **'الهيئة المصرية العامة للمساحة'**
  String get methodEgyptian;

  /// No description provided for @methodUmmAlQura.
  ///
  /// In ar, this message translates to:
  /// **'جامعة أم القرى، مكة المكرمة'**
  String get methodUmmAlQura;

  /// No description provided for @methodMuslimWorldLeague.
  ///
  /// In ar, this message translates to:
  /// **'رابطة العالم الإسلامي'**
  String get methodMuslimWorldLeague;

  /// No description provided for @methodKarachi.
  ///
  /// In ar, this message translates to:
  /// **'جامعة العلوم الإسلامية، كراتشي'**
  String get methodKarachi;

  /// No description provided for @methodNorthAmerica.
  ///
  /// In ar, this message translates to:
  /// **'الجمعية الإسلامية لأمريكا الشمالية'**
  String get methodNorthAmerica;

  /// No description provided for @methodAngles.
  ///
  /// In ar, this message translates to:
  /// **'الفجر {fajr}°، العشاء {isha}°'**
  String methodAngles(String fajr, String isha);

  /// No description provided for @methodInterval.
  ///
  /// In ar, this message translates to:
  /// **'الفجر {fajr}°، العشاء بعد المغرب بـ {minutes} دقيقة'**
  String methodInterval(String fajr, String minutes);

  /// No description provided for @methodAutoCountry.
  ///
  /// In ar, this message translates to:
  /// **'اختيرت تلقائيًا لبلدك'**
  String get methodAutoCountry;

  /// No description provided for @methodAutoGeneral.
  ///
  /// In ar, this message translates to:
  /// **'لا تتوفر بعدُ طريقة خاصة ببلدك، لذلك استُخدمت الطريقة العامة'**
  String get methodAutoGeneral;

  /// No description provided for @methodByYou.
  ///
  /// In ar, this message translates to:
  /// **'اخترتَها أنت'**
  String get methodByYou;

  /// No description provided for @prayerDisclaimer.
  ///
  /// In ar, this message translates to:
  /// **'المواقيت محسوبة وقد تختلف بضع دقائق عن مسجدك أو الجهة الرسمية في بلدك.'**
  String get prayerDisclaimer;

  /// No description provided for @calculationFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حساب المواقيت لهذا المكان.'**
  String get calculationFailed;

  /// No description provided for @aboutPlacesHeading.
  ///
  /// In ar, this message translates to:
  /// **'الأماكن'**
  String get aboutPlacesHeading;

  /// No description provided for @aboutPlacesBody.
  ///
  /// In ar, this message translates to:
  /// **'أسماء المدن ومواقعها ومناطقها الزمنية: GeoNames (geonames.org) برخصة CC BY 4.0. حدود الدول: Natural Earth (ملكية عامة). تُحسب مواقيت الصلاة على جهازك بمكتبة adhan_dart (رخصة MIT).'**
  String get aboutPlacesBody;

  /// No description provided for @aboutPrivacyLocation.
  ///
  /// In ar, this message translates to:
  /// **'إذا اخترت «استخدم موقعي» يُقرأ موقعك مرة واحدة ويُحفظ على هذا الجهاز تقريبًا إلى نحو كيلومتر ولا يُرسَل إلى أي جهة. واختيار مدينة لا يحتاج إلى أي إذن.'**
  String get aboutPrivacyLocation;

  /// No description provided for @hijriHeading.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ الهجري'**
  String get hijriHeading;

  /// No description provided for @hijriReferenceUmmAlQura.
  ///
  /// In ar, this message translates to:
  /// **'أم القرى (السعودية)'**
  String get hijriReferenceUmmAlQura;

  /// No description provided for @hijriReferenceUmmAlQuraNote.
  ///
  /// In ar, this message translates to:
  /// **'التقويم الرسمي في السعودية، من جداول منشورة.'**
  String get hijriReferenceUmmAlQuraNote;

  /// No description provided for @hijriReferenceFcna.
  ///
  /// In ar, this message translates to:
  /// **'المجلس الفقهي لأمريكا الشمالية (حسابي)'**
  String get hijriReferenceFcna;

  /// No description provided for @hijriReferenceFcnaNote.
  ///
  /// In ar, this message translates to:
  /// **'محسوب من ولادة الهلال. لم يُتحقق منه بعدُ بجدول رسمي.'**
  String get hijriReferenceFcnaNote;

  /// No description provided for @hijriAdjustHeading.
  ///
  /// In ar, this message translates to:
  /// **'التصحيح بالأيام'**
  String get hijriAdjustHeading;

  /// No description provided for @hijriAdjustHint.
  ///
  /// In ar, this message translates to:
  /// **'استخدمه لمتابعة إعلان بلدك. قد يختلف التقويم المحسوب مسبقًا بيوم عن إعلان رؤية الهلال.'**
  String get hijriAdjustHint;

  /// No description provided for @hijriAdjustMinus2.
  ///
  /// In ar, this message translates to:
  /// **'قبل بيومين'**
  String get hijriAdjustMinus2;

  /// No description provided for @hijriAdjustMinus1.
  ///
  /// In ar, this message translates to:
  /// **'قبل بيوم'**
  String get hijriAdjustMinus1;

  /// No description provided for @hijriAdjustNone.
  ///
  /// In ar, this message translates to:
  /// **'بلا تصحيح'**
  String get hijriAdjustNone;

  /// No description provided for @hijriAdjustPlus1.
  ///
  /// In ar, this message translates to:
  /// **'بعد بيوم'**
  String get hijriAdjustPlus1;

  /// No description provided for @hijriAdjustPlus2.
  ///
  /// In ar, this message translates to:
  /// **'بعد يومين'**
  String get hijriAdjustPlus2;

  /// No description provided for @hijriYearSuffix.
  ///
  /// In ar, this message translates to:
  /// **'هـ'**
  String get hijriYearSuffix;

  /// No description provided for @hijriChangesAtMaghrib.
  ///
  /// In ar, this message translates to:
  /// **'يتغير التاريخ الهجري عند المغرب.'**
  String get hijriChangesAtMaghrib;

  /// No description provided for @hijriMonth1.
  ///
  /// In ar, this message translates to:
  /// **'محرم'**
  String get hijriMonth1;

  /// No description provided for @hijriMonth2.
  ///
  /// In ar, this message translates to:
  /// **'صفر'**
  String get hijriMonth2;

  /// No description provided for @hijriMonth3.
  ///
  /// In ar, this message translates to:
  /// **'ربيع الأول'**
  String get hijriMonth3;

  /// No description provided for @hijriMonth4.
  ///
  /// In ar, this message translates to:
  /// **'ربيع الآخر'**
  String get hijriMonth4;

  /// No description provided for @hijriMonth5.
  ///
  /// In ar, this message translates to:
  /// **'جمادى الأولى'**
  String get hijriMonth5;

  /// No description provided for @hijriMonth6.
  ///
  /// In ar, this message translates to:
  /// **'جمادى الآخرة'**
  String get hijriMonth6;

  /// No description provided for @hijriMonth7.
  ///
  /// In ar, this message translates to:
  /// **'رجب'**
  String get hijriMonth7;

  /// No description provided for @hijriMonth8.
  ///
  /// In ar, this message translates to:
  /// **'شعبان'**
  String get hijriMonth8;

  /// No description provided for @hijriMonth9.
  ///
  /// In ar, this message translates to:
  /// **'رمضان'**
  String get hijriMonth9;

  /// No description provided for @hijriMonth10.
  ///
  /// In ar, this message translates to:
  /// **'شوال'**
  String get hijriMonth10;

  /// No description provided for @hijriMonth11.
  ///
  /// In ar, this message translates to:
  /// **'ذو القعدة'**
  String get hijriMonth11;

  /// No description provided for @hijriMonth12.
  ///
  /// In ar, this message translates to:
  /// **'ذو الحجة'**
  String get hijriMonth12;

  /// No description provided for @gregMonth1.
  ///
  /// In ar, this message translates to:
  /// **'يناير'**
  String get gregMonth1;

  /// No description provided for @gregMonth2.
  ///
  /// In ar, this message translates to:
  /// **'فبراير'**
  String get gregMonth2;

  /// No description provided for @gregMonth3.
  ///
  /// In ar, this message translates to:
  /// **'مارس'**
  String get gregMonth3;

  /// No description provided for @gregMonth4.
  ///
  /// In ar, this message translates to:
  /// **'أبريل'**
  String get gregMonth4;

  /// No description provided for @gregMonth5.
  ///
  /// In ar, this message translates to:
  /// **'مايو'**
  String get gregMonth5;

  /// No description provided for @gregMonth6.
  ///
  /// In ar, this message translates to:
  /// **'يونيو'**
  String get gregMonth6;

  /// No description provided for @gregMonth7.
  ///
  /// In ar, this message translates to:
  /// **'يوليو'**
  String get gregMonth7;

  /// No description provided for @gregMonth8.
  ///
  /// In ar, this message translates to:
  /// **'أغسطس'**
  String get gregMonth8;

  /// No description provided for @gregMonth9.
  ///
  /// In ar, this message translates to:
  /// **'سبتمبر'**
  String get gregMonth9;

  /// No description provided for @gregMonth10.
  ///
  /// In ar, this message translates to:
  /// **'أكتوبر'**
  String get gregMonth10;

  /// No description provided for @gregMonth11.
  ///
  /// In ar, this message translates to:
  /// **'نوفمبر'**
  String get gregMonth11;

  /// No description provided for @gregMonth12.
  ///
  /// In ar, this message translates to:
  /// **'ديسمبر'**
  String get gregMonth12;

  /// No description provided for @weekday1.
  ///
  /// In ar, this message translates to:
  /// **'الاثنين'**
  String get weekday1;

  /// No description provided for @weekday2.
  ///
  /// In ar, this message translates to:
  /// **'الثلاثاء'**
  String get weekday2;

  /// No description provided for @weekday3.
  ///
  /// In ar, this message translates to:
  /// **'الأربعاء'**
  String get weekday3;

  /// No description provided for @weekday4.
  ///
  /// In ar, this message translates to:
  /// **'الخميس'**
  String get weekday4;

  /// No description provided for @weekday5.
  ///
  /// In ar, this message translates to:
  /// **'الجمعة'**
  String get weekday5;

  /// No description provided for @weekday6.
  ///
  /// In ar, this message translates to:
  /// **'السبت'**
  String get weekday6;

  /// No description provided for @weekday7.
  ///
  /// In ar, this message translates to:
  /// **'الأحد'**
  String get weekday7;

  /// No description provided for @qiblaHeading.
  ///
  /// In ar, this message translates to:
  /// **'القبلة'**
  String get qiblaHeading;

  /// No description provided for @qiblaBearing.
  ///
  /// In ar, this message translates to:
  /// **'{degrees}° من الشمال الحقيقي مع عقارب الساعة'**
  String qiblaBearing(String degrees);

  /// No description provided for @qiblaDistance.
  ///
  /// In ar, this message translates to:
  /// **'نحو {km} كم إلى الكعبة'**
  String qiblaDistance(String km);

  /// No description provided for @qiblaHere.
  ///
  /// In ar, this message translates to:
  /// **'أنت عند الكعبة.'**
  String get qiblaHere;

  /// No description provided for @qiblaNote.
  ///
  /// In ar, this message translates to:
  /// **'هذا هو الاتجاه على الخريطة (الشمال الحقيقي) وليس قراءة بوصلة. بوصلة الهاتف تشير إلى الشمال المغناطيسي، وقد يختلف عنه بعدة درجات أو أكثر بحسب مكانك.'**
  String get qiblaNote;

  /// No description provided for @qiblaNeedsPlace.
  ///
  /// In ar, this message translates to:
  /// **'حدّد موقعك أولًا لمعرفة اتجاه القبلة.'**
  String get qiblaNeedsPlace;

  /// No description provided for @compassN.
  ///
  /// In ar, this message translates to:
  /// **'الشمال'**
  String get compassN;

  /// No description provided for @compassNE.
  ///
  /// In ar, this message translates to:
  /// **'الشمال الشرقي'**
  String get compassNE;

  /// No description provided for @compassE.
  ///
  /// In ar, this message translates to:
  /// **'الشرق'**
  String get compassE;

  /// No description provided for @compassSE.
  ///
  /// In ar, this message translates to:
  /// **'الجنوب الشرقي'**
  String get compassSE;

  /// No description provided for @compassS.
  ///
  /// In ar, this message translates to:
  /// **'الجنوب'**
  String get compassS;

  /// No description provided for @compassSW.
  ///
  /// In ar, this message translates to:
  /// **'الجنوب الغربي'**
  String get compassSW;

  /// No description provided for @compassW.
  ///
  /// In ar, this message translates to:
  /// **'الغرب'**
  String get compassW;

  /// No description provided for @compassNW.
  ///
  /// In ar, this message translates to:
  /// **'الشمال الغربي'**
  String get compassNW;
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
