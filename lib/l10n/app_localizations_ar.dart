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
      'لا يجمع التطبيق أي بيانات شخصية. يحتاج إلى الإنترنت لتحميل المحتوى.';

  @override
  String get openSourceLicences => 'تراخيص البرمجيات مفتوحة المصدر';
}
