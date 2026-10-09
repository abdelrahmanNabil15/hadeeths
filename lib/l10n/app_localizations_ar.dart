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

  @override
  String get hijriHeading => 'التاريخ الهجري';

  @override
  String get hijriReferenceUmmAlQura => 'أم القرى (السعودية)';

  @override
  String get hijriReferenceUmmAlQuraNote =>
      'التقويم الرسمي في السعودية، من جداول منشورة.';

  @override
  String get hijriReferenceFcna => 'المجلس الفقهي لأمريكا الشمالية (حسابي)';

  @override
  String get hijriReferenceFcnaNote =>
      'محسوب من ولادة الهلال. لم يُتحقق منه بعدُ بجدول رسمي.';

  @override
  String get hijriAdjustHeading => 'التصحيح بالأيام';

  @override
  String get hijriAdjustHint =>
      'استخدمه لمتابعة إعلان بلدك. قد يختلف التقويم المحسوب مسبقًا بيوم عن إعلان رؤية الهلال.';

  @override
  String get hijriAdjustMinus2 => 'قبل بيومين';

  @override
  String get hijriAdjustMinus1 => 'قبل بيوم';

  @override
  String get hijriAdjustNone => 'بلا تصحيح';

  @override
  String get hijriAdjustPlus1 => 'بعد بيوم';

  @override
  String get hijriAdjustPlus2 => 'بعد يومين';

  @override
  String get hijriYearSuffix => 'هـ';

  @override
  String get hijriChangesAtMaghrib => 'يتغير التاريخ الهجري عند المغرب.';

  @override
  String get hijriMonth1 => 'محرم';

  @override
  String get hijriMonth2 => 'صفر';

  @override
  String get hijriMonth3 => 'ربيع الأول';

  @override
  String get hijriMonth4 => 'ربيع الآخر';

  @override
  String get hijriMonth5 => 'جمادى الأولى';

  @override
  String get hijriMonth6 => 'جمادى الآخرة';

  @override
  String get hijriMonth7 => 'رجب';

  @override
  String get hijriMonth8 => 'شعبان';

  @override
  String get hijriMonth9 => 'رمضان';

  @override
  String get hijriMonth10 => 'شوال';

  @override
  String get hijriMonth11 => 'ذو القعدة';

  @override
  String get hijriMonth12 => 'ذو الحجة';

  @override
  String get gregMonth1 => 'يناير';

  @override
  String get gregMonth2 => 'فبراير';

  @override
  String get gregMonth3 => 'مارس';

  @override
  String get gregMonth4 => 'أبريل';

  @override
  String get gregMonth5 => 'مايو';

  @override
  String get gregMonth6 => 'يونيو';

  @override
  String get gregMonth7 => 'يوليو';

  @override
  String get gregMonth8 => 'أغسطس';

  @override
  String get gregMonth9 => 'سبتمبر';

  @override
  String get gregMonth10 => 'أكتوبر';

  @override
  String get gregMonth11 => 'نوفمبر';

  @override
  String get gregMonth12 => 'ديسمبر';

  @override
  String get weekday1 => 'الاثنين';

  @override
  String get weekday2 => 'الثلاثاء';

  @override
  String get weekday3 => 'الأربعاء';

  @override
  String get weekday4 => 'الخميس';

  @override
  String get weekday5 => 'الجمعة';

  @override
  String get weekday6 => 'السبت';

  @override
  String get weekday7 => 'الأحد';

  @override
  String get qiblaHeading => 'القبلة';

  @override
  String qiblaBearing(String degrees) {
    return '$degrees° من الشمال الحقيقي مع عقارب الساعة';
  }

  @override
  String qiblaDistance(String km) {
    return 'نحو $km كم إلى الكعبة';
  }

  @override
  String get qiblaHere => 'أنت عند الكعبة.';

  @override
  String get qiblaNote =>
      'هذا هو الاتجاه على الخريطة (الشمال الحقيقي) وليس قراءة بوصلة. بوصلة الهاتف تشير إلى الشمال المغناطيسي، وقد يختلف عنه بعدة درجات أو أكثر بحسب مكانك.';

  @override
  String get qiblaNeedsPlace => 'حدّد موقعك أولًا لمعرفة اتجاه القبلة.';

  @override
  String get compassN => 'الشمال';

  @override
  String get compassNE => 'الشمال الشرقي';

  @override
  String get compassE => 'الشرق';

  @override
  String get compassSE => 'الجنوب الشرقي';

  @override
  String get compassS => 'الجنوب';

  @override
  String get compassSW => 'الجنوب الغربي';

  @override
  String get compassW => 'الغرب';

  @override
  String get compassNW => 'الشمال الغربي';

  @override
  String get compassUse => 'استخدم البوصلة';

  @override
  String get compassStop => 'إيقاف البوصلة';

  @override
  String get compassStarting => 'جارٍ قراءة البوصلة…';

  @override
  String get compassUnavailable =>
      'لا يتوفر في هذا الهاتف حسّاس بوصلة أو تعذّرت قراءته. يظل الاتجاه المعروض أعلاه صالحًا.';

  @override
  String get compassModelExpired =>
      'بيانات التصحيح المغناطيسي قديمة. حدّث التطبيق لاستخدام البوصلة. يظل الاتجاه المعروض أعلاه صالحًا.';

  @override
  String get compassInterference =>
      'شيء قريب يؤثر في البوصلة (معدن أو مغناطيس أو غطاء للهاتف). ابتعد عنه.';

  @override
  String get compassCalibrate =>
      'إذا اهتز السهم فحرّك الهاتف ببطء على شكل الرقم ٨.';

  @override
  String get compassHoldFlat =>
      'أمسك الهاتف أفقيًا وحافته العلوية للأمام، أو رأسيًا وظهره للأمام.';

  @override
  String compassTurnRight(String degrees) {
    return 'استدر يمينًا $degrees°';
  }

  @override
  String compassTurnLeft(String degrees) {
    return 'استدر يسارًا $degrees°';
  }

  @override
  String get compassAligned => 'أنت متجه نحو القبلة';

  @override
  String compassCorrection(String degrees) {
    return 'التصحيح من الشمال المغناطيسي إلى الحقيقي: $degrees°';
  }

  @override
  String get compassPrivacy =>
      'تستخدم البوصلة حسّاسات الحركة في الهاتف ما دامت قيد التشغيل فقط. لا يُخزَّن شيء ولا يُرسَل.';

  @override
  String get compassUnreliable => 'البوصلة غير موثوقة هنا الآن';

  @override
  String reminderNow(String prayer) {
    return 'حان وقت صلاة $prayer';
  }

  @override
  String get reminderSunriseNow => 'الشروق الآن';

  @override
  String get reminderTestTitle => 'تذكير تجريبي';

  @override
  String get reminderTestBody => 'هكذا ستظهر تذكيرات الصلاة.';

  @override
  String get reminderChannelSoundVibrate => 'تذكيرات الصلاة';

  @override
  String get reminderChannelSound => 'تذكيرات الصلاة (دون اهتزاز)';

  @override
  String get reminderChannelVibrate => 'تذكيرات الصلاة (صامتة مع اهتزاز)';

  @override
  String get reminderChannelSilent => 'تذكيرات الصلاة (صامتة)';

  @override
  String get reminderChannelDescription => 'إشعارات عند أوقات الصلاة';

  @override
  String get remindersHeading => 'التذكيرات';

  @override
  String get remindersSwitch => 'ذكّرني عند أوقات الصلاة';

  @override
  String get remindersOff => 'التذكيرات متوقفة.';

  @override
  String get remindersExplainTitle => 'السماح بالإشعارات؟';

  @override
  String get remindersExplainBody =>
      'لتذكيرك عند أوقات الصلاة يحتاج التطبيق إلى عرض الإشعارات. تُجهَّز التذكيرات على جهازك، ولا يُرسَل شيء إلى أي جهة، ولا تتضمن موقعك أبدًا.';

  @override
  String get remindersDenied =>
      'الإشعارات متوقفة لهذا التطبيق، لذلك لن تظهر التذكيرات. افتح الإعدادات للسماح بها.';

  @override
  String get remindersNeedPlace =>
      'حدّد موقعك أولًا ليعرف التطبيق أوقات الصلاة.';

  @override
  String get remindersWhich => 'أي الأوقات';

  @override
  String get remindersLead => 'قبل الوقت بـ';

  @override
  String get remindersLeadNone => 'عند دخول الوقت';

  @override
  String get remindersSound => 'الصوت';

  @override
  String get remindersSoundSystem => 'صوت إشعارات الهاتف';

  @override
  String get remindersSoundSilent => 'صامت';

  @override
  String get remindersVibrate => 'الاهتزاز';

  @override
  String get remindersTest => 'إرسال تذكير تجريبي';

  @override
  String get remindersTiming =>
      'عند إيقاف التوقيت الدقيق قد يتأخر النظام في إيصال التذكير، وأحيانًا حتى ساعة، عندما يوفّر الهاتف الطاقة.';

  @override
  String get remindersFailed =>
      'تعذّرت جدولة بعض التذكيرات. ستُعاد المحاولة عند فتح التطبيق.';

  @override
  String remindersNext(String prayer, String time) {
    return 'التذكير التالي: $prayer، $time';
  }

  @override
  String reminderSoon(int minutes, String prayer) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'صلاة $prayer بعد $minutes دقيقة',
      many: 'صلاة $prayer بعد $minutes دقيقة',
      few: 'صلاة $prayer بعد $minutes دقائق',
    );
    return '$_temp0';
  }

  @override
  String reminderSunriseSoon(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'الشروق بعد $minutes دقيقة',
      many: 'الشروق بعد $minutes دقيقة',
      few: 'الشروق بعد $minutes دقائق',
    );
    return '$_temp0';
  }

  @override
  String remindersLeadMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'قبل $minutes دقيقة',
      many: 'قبل $minutes دقيقة',
      few: 'قبل $minutes دقائق',
    );
    return '$_temp0';
  }

  @override
  String remindersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تذكير مجدول',
      many: '$count تذكيرًا مجدولًا',
      few: '$count تذكيرات مجدولة',
      two: 'تذكيران مجدولان',
      one: 'تذكير واحد مجدول',
      zero: 'لا توجد تذكيرات مجدولة',
    );
    return '$_temp0';
  }

  @override
  String get remindersExact => 'التوقيت الدقيق';

  @override
  String get remindersExactHint =>
      'يطلب من أندرويد إيصال كل تذكير في وقته. يحتاج هذا إلى إذن «المنبهات والتذكيرات» لهذا التطبيق، ومن دونه قد تتأخر التذكيرات.';

  @override
  String get remindersExactExplainTitle => 'السماح بالتوقيت الدقيق؟';

  @override
  String get remindersExactExplainBody =>
      'من دونه قد يتأخر أندرويد في إيصال التذكير، وأحيانًا حتى ساعة، عندما يوفّر الهاتف الطاقة. معه يستطيع أندرويد إيصال التذكيرات في وقتها. الشاشة التالية هي صفحة إعدادات أندرويد الخاصة بهذا الإذن. إن لم تسمح به تبقى التذكيرات تعمل لكنها قد تتأخر.';

  @override
  String get remindersExactMissing =>
      'التوقيت الدقيق غير مسموح لهذا التطبيق، لذلك قد تتأخر التذكيرات. افتح الإعدادات للسماح بـ«المنبهات والتذكيرات».';

  @override
  String get trackerTitle => 'متابع الصلاة';

  @override
  String get trackerIntro =>
      'علّم على الصلوات التي صلّيتها. يبقى هذا على هاتفك فقط.';

  @override
  String get trackerToday => 'اليوم';

  @override
  String trackerCount(String count, String total) {
    return 'المُعلَّم $count من $total';
  }

  @override
  String get trackerSaveFailed =>
      'تعذّر حفظ هذا التغيير فأُلغي. حاول مرة أخرى.';

  @override
  String get trackerUnavailable =>
      'التخزين غير متاح على هذا الهاتف، لذلك لا يمكن استخدام المتابع.';

  @override
  String get trackerDelete => 'حذف بيانات المتابع';

  @override
  String get trackerDeleteTitle => 'حذف كل بيانات المتابع؟';

  @override
  String get trackerDeleteBody =>
      'يزيل هذا كل صلاة معلَّمة من هذا الهاتف، ولا يمكن التراجع عنه.';

  @override
  String get trackerDeleteConfirm => 'حذف';

  @override
  String trackerDayLabel(String day, String count, String total) {
    return '$day، المُعلَّم $count من $total';
  }

  @override
  String get tasbeehTitle => 'عدّاد التسبيح';

  @override
  String get tasbeehHint => 'المس الدائرة للعدّ. يُحفظ العدد على هذا الهاتف.';

  @override
  String tasbeehCountLabel(Object count) {
    return 'العدد $count';
  }

  @override
  String get tasbeehTapHint => 'المس للعدّ';

  @override
  String get tasbeehTargetHeading => 'الهدف';

  @override
  String get tasbeehNoTarget => 'بلا هدف';

  @override
  String tasbeehRounds(Object rounds) {
    return 'الدورات المكتملة: $rounds';
  }

  @override
  String get tasbeehTargetReached => 'اكتمل الهدف';

  @override
  String get tasbeehUndo => 'تراجع عن الأخيرة';

  @override
  String get tasbeehReset => 'تصفير';

  @override
  String get tasbeehResetTitle => 'تصفير العدّاد؟';

  @override
  String get tasbeehResetBody => 'يعود العدد إلى الصفر.';

  @override
  String get tasbeehSaveFailed =>
      'تعذّر حفظ العدد على هذا الهاتف. يمكنك متابعة العدّ لكنه قد يضيع عند إغلاق التطبيق.';
}
