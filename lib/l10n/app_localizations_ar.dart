// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'الأحاديث النبوية';

  @override
  String get homeIntro => 'تصفّح الأحاديث حسب التصنيف، أو ابحث بكلمة.';

  @override
  String get mainCategories => 'التصنيفات الرئيسية';

  @override
  String get noCategories => 'لا توجد تصنيفات';

  @override
  String get categoryUnavailable => 'هذا التصنيف غير متوفر';

  @override
  String get allHadithsInCategory => 'جميع الأحاديث في هذا التصنيف';

  @override
  String tileSemantics(String title, String count) {
    return '$title، $count';
  }

  @override
  String get noHadithsInCategory => 'لا توجد أحاديث في هذا التصنيف';

  @override
  String get errorNoConnection => 'لا يوجد اتصال بالإنترنت';

  @override
  String get errorTimeout => 'انتهت مهلة الاتصال بالخادم';

  @override
  String get errorServer => 'حدث خطأ في الخادم، حاول مرة أخرى لاحقًا';

  @override
  String get errorNotFound => 'هذا المحتوى غير متوفر';

  @override
  String get errorParse => 'تعذّر قراءة البيانات المستلمة';

  @override
  String get errorUnexpected => 'حدث خطأ غير متوقع';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get loading => 'جارٍ التحميل';

  @override
  String get shareHadith => 'مشاركة الحديث';

  @override
  String get share => 'مشاركة';

  @override
  String get explanation => 'الشرح';

  @override
  String get benefits => 'الفوائد';

  @override
  String get wordMeanings => 'معاني الكلمات';

  @override
  String get sources => 'المصادر';

  @override
  String get sourceCredit => 'المصدر: HadeethEnc.com';

  @override
  String get searchHint => 'ابحث في الأحاديث';

  @override
  String get searchClear => 'مسح';

  @override
  String get searchPrompt => 'اكتب كلمة أو عبارة للبحث في نصوص الأحاديث.';

  @override
  String searchTooShort(int min) {
    return 'اكتب $min أحرف على الأقل.';
  }

  @override
  String searchNoResults(String query) {
    return 'لا توجد نتائج لـ «$query»';
  }

  @override
  String searchTruncated(int count) {
    return 'تُعرض أول $count نتيجة فقط. حدّد بحثك للحصول على نتائج أدق.';
  }

  @override
  String searchResultCount(int count) {
    return '$count نتيجة';
  }

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get languageSystem => 'لغة الجهاز';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get theme => 'المظهر';

  @override
  String get themeSystem => 'حسب الجهاز';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get textSize => 'حجم النص';

  @override
  String get textSizeSmaller => 'تصغير النص';

  @override
  String get textSizeLarger => 'تكبير النص';

  @override
  String get textSizeSample => 'عَنْ أَبِي هُرَيْرَةَ رَضِيَ اللهُ عَنْهُ';

  @override
  String get aboutTitle => 'المصادر والحقوق';

  @override
  String get aboutContentHeading => 'المحتوى';

  @override
  String get aboutContentBody =>
      'الأحاديث وشروحها وترجماتها من موقع HadeethEnc.com، وتُعرض كما نُشرت دون تعديل.';

  @override
  String get aboutFontsHeading => 'الخطوط';

  @override
  String get aboutFontsBody =>
      'خط Cairo وخط Amiri، برخصة SIL Open Font License 1.1.';

  @override
  String get aboutPrivacyHeading => 'الخصوصية';

  @override
  String get aboutPrivacyBody =>
      'لا يجمع التطبيق أي بيانات شخصية. يحتاج إلى الإنترنت لتحميل المحتوى، ويحفظ على جهازك نسخًا مما فتحته لتقرأه دون اتصال، ويمكنك إيقاف ذلك أو مسحه من الإعدادات.';

  @override
  String get openSourceLicences => 'تراخيص البرمجيات مفتوحة المصدر';

  @override
  String get offlineCopies => 'القراءة دون اتصال';

  @override
  String get offlineCopiesHint =>
      'احتفظ على هذا الجهاز بالأحاديث التي فتحتها لتقرأها دون إنترنت.';

  @override
  String get clearSavedCopies => 'مسح النسخ المحفوظة';

  @override
  String get savedCopiesCleared => 'تم مسح النسخ المحفوظة';

  @override
  String get digitsHeading => 'الأرقام';

  @override
  String get digitsAutomatic => 'حسب اللغة';

  @override
  String get digitsArabicIndic => 'الأرقام العربية الهندية (٠١٢٣)';

  @override
  String get digitsWestern => 'الأرقام الغربية (0123)';

  @override
  String get navHadiths => 'الأحاديث';

  @override
  String get navQuran => 'المصحف';

  @override
  String get navPrayer => 'الصلاة';

  @override
  String get navMore => 'المزيد';

  @override
  String get navigationLabel => 'الأقسام الرئيسية';

  @override
  String get comingSoon => 'قريبًا';

  @override
  String get comingSoonBody => 'هذا القسم قيد الإعداد وليس متاحًا بعد.';

  @override
  String get prayerTimesTitle => 'مواقيت الصلاة';

  @override
  String get prayerSetupTitle => 'حدّد موقعك';

  @override
  String get prayerSetupBody =>
      'تعتمد مواقيت الصلاة على مكانك. اختر طريقة تحديده.';

  @override
  String get useMyLocation => 'استخدم موقعي';

  @override
  String get chooseCity => 'اختر مدينة';

  @override
  String get locationExplainTitle => 'استخدام موقعك؟';

  @override
  String get locationExplainBody =>
      'يقرأ التطبيق موقعك مرة واحدة الآن، لحساب مواقيت الصلاة في مكانك فقط. لا يُتتبَّع ولا يُشارك، ويُحفظ تقريبًا إلى نحو كيلومتر. يمكنك اختيار مدينة بدلًا من ذلك.';

  @override
  String get continueAction => 'متابعة';

  @override
  String get notNow => 'ليس الآن';

  @override
  String get locating => 'جارٍ تحديد موقعك…';

  @override
  String get locationDenied =>
      'لم يُمنح إذن الموقع. يمكنك المحاولة مرة أخرى أو اختيار مدينة.';

  @override
  String get locationNeedsSettings =>
      'إذن الموقع متوقف لهذا التطبيق. افتح الإعدادات للسماح به، أو اختر مدينة.';

  @override
  String get locationServiceDisabled =>
      'خدمة الموقع متوقفة على هذا الجهاز. شغّلها أو اختر مدينة.';

  @override
  String get locationTimeout =>
      'تعذّر تحديد موقعك في الوقت المناسب. حاول مرة أخرى أو اختر مدينة.';

  @override
  String get locationUnavailable =>
      'موقعك غير متاح الآن. حاول مرة أخرى أو اختر مدينة.';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get cityPickerTitle => 'اختر مدينة';

  @override
  String get citySearchHint => 'ابحث عن مدينة';

  @override
  String cityNoResults(String query) {
    return 'لا توجد مدينة تطابق «$query»';
  }

  @override
  String get currentLocation => 'الموقع الحالي';

  @override
  String get changeLocation => 'تغيير الموقع';

  @override
  String get nextPrayerLabel => 'الصلاة التالية';

  @override
  String get prayerFajr => 'الفجر';

  @override
  String get prayerSunrise => 'الشروق';

  @override
  String get prayerDhuhr => 'الظهر';

  @override
  String get prayerAsr => 'العصر';

  @override
  String get prayerMaghrib => 'المغرب';

  @override
  String get prayerIsha => 'العشاء';

  @override
  String get methodHeading => 'طريقة الحساب';

  @override
  String get methodEgyptian => 'الهيئة المصرية العامة للمساحة';

  @override
  String get methodUmmAlQura => 'جامعة أم القرى، مكة المكرمة';

  @override
  String get methodMuslimWorldLeague => 'رابطة العالم الإسلامي';

  @override
  String get methodKarachi => 'جامعة العلوم الإسلامية، كراتشي';

  @override
  String get methodNorthAmerica => 'الجمعية الإسلامية لأمريكا الشمالية';

  @override
  String methodAngles(String fajr, String isha) {
    return 'الفجر $fajr°، العشاء $isha°';
  }

  @override
  String methodInterval(String fajr, String minutes) {
    return 'الفجر $fajr°، العشاء بعد المغرب بـ $minutes دقيقة';
  }

  @override
  String get methodAutoCountry => 'اختيرت تلقائيًا لبلدك';

  @override
  String get methodAutoGeneral =>
      'لا تتوفر بعدُ طريقة خاصة ببلدك، لذلك استُخدمت الطريقة العامة';

  @override
  String get methodByYou => 'اخترتَها أنت';

  @override
  String get prayerDisclaimer =>
      'المواقيت محسوبة وقد تختلف بضع دقائق عن مسجدك أو الجهة الرسمية في بلدك.';

  @override
  String get calculationFailed => 'تعذّر حساب المواقيت لهذا المكان.';

  @override
  String get aboutPlacesHeading => 'الأماكن';

  @override
  String get aboutPlacesBody =>
      'أسماء المدن ومواقعها ومناطقها الزمنية: GeoNames (geonames.org) برخصة CC BY 4.0. حدود الدول: Natural Earth (ملكية عامة). تُحسب مواقيت الصلاة على جهازك بمكتبة adhan_dart (رخصة MIT).';

  @override
  String get aboutPrivacyLocation =>
      'إذا اخترت «استخدم موقعي» يُقرأ موقعك مرة واحدة ويُحفظ على هذا الجهاز تقريبًا إلى نحو كيلومتر ولا يُرسَل إلى أي جهة. واختيار مدينة لا يحتاج إلى أي إذن.';
}
