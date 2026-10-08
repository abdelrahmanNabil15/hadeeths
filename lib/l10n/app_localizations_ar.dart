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
  String get mainCategories => 'التصنيفات الرئيسية';

  @override
  String get noCategories => 'لا توجد تصنيفات';

  @override
  String get categoryUnavailable => 'هذا التصنيف غير متوفر';

  @override
  String get allHadithsInCategory => 'جميع الأحاديث في هذا التصنيف';

  @override
  String categoryCardSemantics(String title, String count) {
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
  String get hadithLabel => 'الحديث:';

  @override
  String get explanation => 'الشرح';

  @override
  String get explanationTitle => 'الشرح:';

  @override
  String get benefits => 'الفوائد:';

  @override
  String get wordMeanings => 'معاني الكلمات:';

  @override
  String get sources => 'المصادر';

  @override
  String get sourcesTitle => 'المصادر:';

  @override
  String get sourceCredit => 'المصدر: HadeethEnc.com';
}
