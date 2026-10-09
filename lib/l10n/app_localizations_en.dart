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

  @override
  String get hijriHeading => 'Hijri date';

  @override
  String get hijriReferenceUmmAlQura => 'Umm al-Qura (Saudi Arabia)';

  @override
  String get hijriReferenceUmmAlQuraNote =>
      'The official calendar of Saudi Arabia, from published tables.';

  @override
  String get hijriReferenceFcna => 'FCNA (calculated)';

  @override
  String get hijriReferenceFcnaNote =>
      'Calculated from the new moon. Not yet checked against an official table.';

  @override
  String get hijriAdjustHeading => 'Correct by days';

  @override
  String get hijriAdjustHint =>
      'Use this to follow your country\'s announcement. A calendar worked out in advance can differ by a day from the moon-sighting announcement.';

  @override
  String get hijriAdjustMinus2 => '2 days earlier';

  @override
  String get hijriAdjustMinus1 => '1 day earlier';

  @override
  String get hijriAdjustNone => 'No correction';

  @override
  String get hijriAdjustPlus1 => '1 day later';

  @override
  String get hijriAdjustPlus2 => '2 days later';

  @override
  String get hijriYearSuffix => 'AH';

  @override
  String get hijriChangesAtMaghrib => 'The Hijri date changes at Maghrib.';

  @override
  String get hijriMonth1 => 'Muharram';

  @override
  String get hijriMonth2 => 'Safar';

  @override
  String get hijriMonth3 => 'Rabi al-Awwal';

  @override
  String get hijriMonth4 => 'Rabi al-Thani';

  @override
  String get hijriMonth5 => 'Jumada al-Ula';

  @override
  String get hijriMonth6 => 'Jumada al-Akhira';

  @override
  String get hijriMonth7 => 'Rajab';

  @override
  String get hijriMonth8 => 'Shaban';

  @override
  String get hijriMonth9 => 'Ramadan';

  @override
  String get hijriMonth10 => 'Shawwal';

  @override
  String get hijriMonth11 => 'Dhu al-Qada';

  @override
  String get hijriMonth12 => 'Dhu al-Hijja';

  @override
  String get gregMonth1 => 'January';

  @override
  String get gregMonth2 => 'February';

  @override
  String get gregMonth3 => 'March';

  @override
  String get gregMonth4 => 'April';

  @override
  String get gregMonth5 => 'May';

  @override
  String get gregMonth6 => 'June';

  @override
  String get gregMonth7 => 'July';

  @override
  String get gregMonth8 => 'August';

  @override
  String get gregMonth9 => 'September';

  @override
  String get gregMonth10 => 'October';

  @override
  String get gregMonth11 => 'November';

  @override
  String get gregMonth12 => 'December';

  @override
  String get weekday1 => 'Monday';

  @override
  String get weekday2 => 'Tuesday';

  @override
  String get weekday3 => 'Wednesday';

  @override
  String get weekday4 => 'Thursday';

  @override
  String get weekday5 => 'Friday';

  @override
  String get weekday6 => 'Saturday';

  @override
  String get weekday7 => 'Sunday';

  @override
  String get qiblaHeading => 'Qibla';

  @override
  String qiblaBearing(String degrees) {
    return '$degrees° from true north, clockwise';
  }

  @override
  String qiblaDistance(String km) {
    return 'About $km km to the Kaaba';
  }

  @override
  String get qiblaHere => 'You are at the Kaaba.';

  @override
  String get qiblaNote =>
      'This is the direction on the map (true north), not a compass reading. A phone compass points to magnetic north, which can differ by several degrees or more depending on where you are.';

  @override
  String get qiblaNeedsPlace => 'Set your location first to find the Qibla.';

  @override
  String get compassN => 'North';

  @override
  String get compassNE => 'North-east';

  @override
  String get compassE => 'East';

  @override
  String get compassSE => 'South-east';

  @override
  String get compassS => 'South';

  @override
  String get compassSW => 'South-west';

  @override
  String get compassW => 'West';

  @override
  String get compassNW => 'North-west';

  @override
  String get compassUse => 'Use the compass';

  @override
  String get compassStop => 'Stop the compass';

  @override
  String get compassStarting => 'Reading the compass…';

  @override
  String get compassUnavailable =>
      'This phone has no compass sensor, or it could not be read. The direction above still works.';

  @override
  String get compassModelExpired =>
      'The magnetic correction data is out of date. Update the app to use the compass. The direction above still works.';

  @override
  String get compassInterference =>
      'Something nearby is disturbing the compass (metal, a magnet or a phone case). Move away from it.';

  @override
  String get compassCalibrate =>
      'If the arrow jumps, move the phone slowly in a figure 8.';

  @override
  String get compassHoldFlat =>
      'Hold the phone flat with its top edge pointing ahead, or upright with its back pointing ahead.';

  @override
  String compassTurnRight(String degrees) {
    return 'Turn right $degrees°';
  }

  @override
  String compassTurnLeft(String degrees) {
    return 'Turn left $degrees°';
  }

  @override
  String get compassAligned => 'You are facing the Qibla';

  @override
  String compassCorrection(String degrees) {
    return 'Correction from magnetic to true north: $degrees°';
  }

  @override
  String get compassPrivacy =>
      'The compass uses the phone\'s motion sensors only while it is on. Nothing is stored or sent.';

  @override
  String get compassUnreliable => 'The compass is not reliable here right now';

  @override
  String reminderNow(String prayer) {
    return 'Time for $prayer prayer';
  }

  @override
  String get reminderSunriseNow => 'Sunrise now';

  @override
  String get reminderTestTitle => 'Test reminder';

  @override
  String get reminderTestBody => 'This is how prayer reminders will appear.';

  @override
  String get reminderChannelSoundVibrate => 'Prayer reminders';

  @override
  String get reminderChannelSound => 'Prayer reminders (no vibration)';

  @override
  String get reminderChannelVibrate => 'Prayer reminders (silent, vibrating)';

  @override
  String get reminderChannelSilent => 'Prayer reminders (silent)';

  @override
  String get reminderChannelDescription => 'Notifications at prayer times';

  @override
  String get remindersHeading => 'Reminders';

  @override
  String get remindersSwitch => 'Remind me at prayer times';

  @override
  String get remindersOff => 'Reminders are off.';

  @override
  String get remindersExplainTitle => 'Allow notifications?';

  @override
  String get remindersExplainBody =>
      'To remind you at prayer times, the app needs to show notifications. The reminders are made on your device, nothing is sent anywhere, and they never contain your location.';

  @override
  String get remindersDenied =>
      'Notifications are turned off for this app, so reminders cannot appear. Open the settings to allow them.';

  @override
  String get remindersNeedPlace =>
      'Set your location first, so the app knows the prayer times.';

  @override
  String get remindersWhich => 'Which times';

  @override
  String get remindersLead => 'How long before';

  @override
  String get remindersLeadNone => 'At the time';

  @override
  String get remindersSound => 'Sound';

  @override
  String get remindersSoundSystem => 'The phone\'s notification sound';

  @override
  String get remindersSoundSilent => 'Silent';

  @override
  String get remindersVibrate => 'Vibrate';

  @override
  String get remindersTest => 'Send a test reminder';

  @override
  String get remindersTiming =>
      'With exact timing off, the system can deliver a reminder late, sometimes by up to an hour, when the phone is saving power.';

  @override
  String get remindersFailed =>
      'Some reminders could not be scheduled. They will be tried again when the app is opened.';

  @override
  String remindersNext(String prayer, String time) {
    return 'Next reminder: $prayer, $time';
  }

  @override
  String reminderSoon(int minutes, String prayer) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$prayer prayer in $minutes minutes',
      one: '$prayer prayer in 1 minute',
    );
    return '$_temp0';
  }

  @override
  String reminderSunriseSoon(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Sunrise in $minutes minutes',
      one: 'Sunrise in 1 minute',
    );
    return '$_temp0';
  }

  @override
  String remindersLeadMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes before',
      one: '1 minute before',
    );
    return '$_temp0';
  }

  @override
  String remindersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders scheduled',
      one: '1 reminder scheduled',
      zero: 'No reminders scheduled',
    );
    return '$_temp0';
  }

  @override
  String get remindersExact => 'Exact timing';

  @override
  String get remindersExactHint =>
      'Asks Android to deliver each reminder at its time. This needs “Alarms & reminders” access for this app; without it, reminders may arrive late.';

  @override
  String get remindersExactExplainTitle => 'Allow exact timing?';

  @override
  String get remindersExactExplainBody =>
      'Without it, Android may deliver a reminder late, sometimes by up to an hour, when the phone is saving power. With it, Android can deliver reminders at their time. The next screen is Android\'s own settings page for this permission. If you do not allow it, reminders still work but may be late.';

  @override
  String get remindersExactMissing =>
      'Exact timing is not allowed for this app, so reminders may arrive late. Open the settings to allow “Alarms & reminders”.';

  @override
  String get trackerTitle => 'Prayer tracker';

  @override
  String get trackerIntro =>
      'Mark the prayers you have prayed. This stays on your phone only.';

  @override
  String get trackerToday => 'Today';

  @override
  String trackerCount(String count, String total) {
    return '$count of $total marked';
  }

  @override
  String get trackerSaveFailed =>
      'Could not save that change, so it was taken back. Try again.';

  @override
  String get trackerUnavailable =>
      'Storage is not available on this phone, so the tracker cannot be used.';

  @override
  String get trackerDelete => 'Delete tracker data';

  @override
  String get trackerDeleteTitle => 'Delete all tracker data?';

  @override
  String get trackerDeleteBody =>
      'This removes every marked prayer from this phone. It cannot be undone.';

  @override
  String get trackerDeleteConfirm => 'Delete';

  @override
  String trackerDayLabel(String day, String count, String total) {
    return '$day, $count of $total marked';
  }

  @override
  String get tasbeehTitle => 'Tasbeeh counter';

  @override
  String get tasbeehHint =>
      'Tap the circle to count. The count is kept on this phone.';

  @override
  String tasbeehCountLabel(Object count) {
    return 'Count $count';
  }

  @override
  String get tasbeehTapHint => 'Tap to count';

  @override
  String get tasbeehTargetHeading => 'Target';

  @override
  String get tasbeehNoTarget => 'No target';

  @override
  String tasbeehRounds(Object rounds) {
    return 'Rounds completed: $rounds';
  }

  @override
  String get tasbeehTargetReached => 'Target reached';

  @override
  String get tasbeehUndo => 'Undo last';

  @override
  String get tasbeehReset => 'Reset';

  @override
  String get tasbeehResetTitle => 'Reset the counter?';

  @override
  String get tasbeehResetBody => 'The count goes back to zero.';

  @override
  String get tasbeehSaveFailed =>
      'The count could not be saved on this phone. You can keep counting, but it may be lost when the app closes.';
}
