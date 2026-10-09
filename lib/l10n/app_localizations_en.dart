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
  String get homeIntro => 'Browse hadiths by topic, or search by a word.';

  @override
  String get mainCategories => 'Main categories';

  @override
  String get noCategories => 'No categories';

  @override
  String get categoryUnavailable => 'This category is unavailable';

  @override
  String get allHadithsInCategory => 'All hadiths in this category';

  @override
  String tileSemantics(String title, String count) {
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
  String get explanation => 'Explanation';

  @override
  String get benefits => 'Benefits';

  @override
  String get wordMeanings => 'Word meanings';

  @override
  String get sources => 'Sources';

  @override
  String get sourceCredit => 'Source: HadeethEnc.com';

  @override
  String get searchHint => 'Search hadiths';

  @override
  String get searchClear => 'Clear';

  @override
  String get searchPrompt =>
      'Type a word or phrase to search the text of the hadiths.';

  @override
  String searchTooShort(int min) {
    return 'Type at least $min characters.';
  }

  @override
  String searchNoResults(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String searchTruncated(int count) {
    return 'Showing the first $count results only. Refine your search for better matches.';
  }

  @override
  String searchResultCount(int count) {
    return '$count results';
  }

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Device language';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get theme => 'Appearance';

  @override
  String get themeSystem => 'Match device';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get textSize => 'Text size';

  @override
  String get textSizeSmaller => 'Smaller text';

  @override
  String get textSizeLarger => 'Larger text';

  @override
  String get textSizeSample =>
      'Narrated Abu Hurayrah (may Allah be pleased with him)';

  @override
  String get aboutTitle => 'Sources and rights';

  @override
  String get aboutContentHeading => 'Content';

  @override
  String get aboutContentBody =>
      'Hadiths, explanations and translations come from HadeethEnc.com and are shown exactly as published.';

  @override
  String get aboutFontsHeading => 'Fonts';

  @override
  String get aboutFontsBody =>
      'Cairo and Amiri, under the SIL Open Font License 1.1.';

  @override
  String get aboutPrivacyHeading => 'Privacy';

  @override
  String get aboutPrivacyBody =>
      'The app collects no personal data. It needs the internet to load content, keeps copies of what you open on your device for offline reading, and you can turn that off or clear it in Settings.';

  @override
  String get openSourceLicences => 'Open-source licences';

  @override
  String get offlineCopies => 'Offline reading';

  @override
  String get offlineCopiesHint =>
      'Keep the hadiths you open on this device so you can read them without internet.';

  @override
  String get clearSavedCopies => 'Clear saved copies';

  @override
  String get savedCopiesCleared => 'Saved copies cleared';

  @override
  String get navHadiths => 'Hadiths';

  @override
  String get navQuran => 'Quran';

  @override
  String get navPrayer => 'Prayer';

  @override
  String get navMore => 'More';

  @override
  String get navigationLabel => 'Main sections';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get comingSoonBody =>
      'This section is being prepared and is not available yet.';
}
