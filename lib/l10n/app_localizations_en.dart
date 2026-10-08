// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Prophetic Hadiths';

  @override
  String get mainCategories => 'Main categories';

  @override
  String get noCategories => 'No categories';

  @override
  String get categoryUnavailable => 'This category is unavailable';

  @override
  String get allHadithsInCategory => 'All hadiths in this category';

  @override
  String categoryCardSemantics(String title, String count) {
    return '$title, $count';
  }

  @override
  String get noHadithsInCategory => 'No hadiths in this category';

  @override
  String get errorNoConnection => 'No internet connection';

  @override
  String get errorTimeout => 'The connection timed out';

  @override
  String get errorServer => 'Server error. Please try again later';

  @override
  String get errorNotFound => 'This content isn\'t available';

  @override
  String get errorParse => 'The data received couldn\'t be read';

  @override
  String get errorUnexpected => 'Something went wrong';

  @override
  String get retry => 'Try again';

  @override
  String get loading => 'Loading';

  @override
  String get shareHadith => 'Share hadith';

  @override
  String get share => 'Share';

  @override
  String get hadithLabel => 'Hadith:';

  @override
  String get explanation => 'Explanation';

  @override
  String get explanationTitle => 'Explanation:';

  @override
  String get benefits => 'Benefits:';

  @override
  String get wordMeanings => 'Word meanings:';

  @override
  String get sources => 'Sources';

  @override
  String get sourcesTitle => 'Sources:';

  @override
  String get sourceCredit => 'Source: HadeethEnc.com';
}
