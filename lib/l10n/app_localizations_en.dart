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
  String get digitsHeading => 'Numerals';

  @override
  String get digitsAutomatic => 'Match the language';

  @override
  String get digitsArabicIndic => 'Arabic-Indic (٠١٢٣)';

  @override
  String get digitsWestern => 'Western (0123)';

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

  @override
  String get prayerTimesTitle => 'Prayer times';

  @override
  String get prayerSetupTitle => 'Set your location';

  @override
  String get prayerSetupBody =>
      'Prayer times depend on where you are. Choose how to set your place.';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get chooseCity => 'Choose a city';

  @override
  String get locationExplainTitle => 'Use your location?';

  @override
  String get locationExplainBody =>
      'The app reads your position once, now, only to calculate prayer times for where you are. It is not tracked or shared, and it is kept only to about a kilometre. You can choose a city instead.';

  @override
  String get continueAction => 'Continue';

  @override
  String get notNow => 'Not now';

  @override
  String get locating => 'Finding your location…';

  @override
  String get locationDenied =>
      'Location permission was not granted. You can try again or choose a city.';

  @override
  String get locationNeedsSettings =>
      'Location permission is turned off for this app. Open the settings to allow it, or choose a city.';

  @override
  String get locationServiceDisabled =>
      'Location is switched off on this device. Switch it on, or choose a city.';

  @override
  String get locationTimeout =>
      'Your position could not be found in time. Try again, or choose a city.';

  @override
  String get locationUnavailable =>
      'Your position is not available right now. Try again, or choose a city.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get cityPickerTitle => 'Choose a city';

  @override
  String get citySearchHint => 'Search cities';

  @override
  String cityNoResults(String query) {
    return 'No city matches “$query”';
  }

  @override
  String get currentLocation => 'Current location';

  @override
  String get changeLocation => 'Change location';

  @override
  String get nextPrayerLabel => 'Next prayer';

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerSunrise => 'Sunrise';

  @override
  String get prayerDhuhr => 'Dhuhr';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get prayerIsha => 'Isha';

  @override
  String get methodHeading => 'Calculation method';

  @override
  String get methodEgyptian => 'Egyptian General Authority of Survey';

  @override
  String get methodUmmAlQura => 'Umm al-Qura University, Makkah';

  @override
  String get methodMuslimWorldLeague => 'Muslim World League';

  @override
  String get methodKarachi => 'University of Islamic Sciences, Karachi';

  @override
  String get methodNorthAmerica => 'Islamic Society of North America';

  @override
  String methodAngles(String fajr, String isha) {
    return 'Fajr $fajr°, Isha $isha°';
  }

  @override
  String methodInterval(String fajr, String minutes) {
    return 'Fajr $fajr°, Isha $minutes minutes after Maghrib';
  }

  @override
  String get methodAutoCountry => 'Chosen automatically for your country';

  @override
  String get methodAutoGeneral =>
      'No method specific to your country is offered yet, so the general one is used';

  @override
  String get methodByYou => 'Chosen by you';

  @override
  String get prayerDisclaimer =>
      'Calculated times can differ by a few minutes from your local mosque or official timetable.';

  @override
  String get calculationFailed =>
      'Prayer times cannot be calculated for this place.';

  @override
  String get aboutPlacesHeading => 'Places';

  @override
  String get aboutPlacesBody =>
      'City names, positions and time zones: GeoNames (geonames.org), licence CC BY 4.0. Country borders: Natural Earth, public domain. Prayer times are calculated on your device with the adhan_dart library (MIT).';

  @override
  String get aboutPrivacyLocation =>
      'If you choose “Use my location”, your position is read once, kept only to about a kilometre on this device, and never sent anywhere. Choosing a city needs no permission.';
}
