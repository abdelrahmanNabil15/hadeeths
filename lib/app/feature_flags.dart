/// Which Phase 3 sections are switched on in this build.
///
/// Sections stay off until they are finished and reviewed, so a build made from this code
/// looks exactly like the released app. While every flag is off the app opens straight on
/// the hadith home screen with no bottom navigation, as before.
///
/// To preview the navigation on a device or emulator:
/// `flutter run --dart-define=HADEETHS_PREVIEW_SECTIONS=true`.
class FeatureFlags {
  const FeatureFlags({
    this.quran = false,
    this.prayer = false,
    this.favorites = false,
    this.shareCards = false,
    this.dailyHadith = false,
    this.adhanSounds = false,
    this.inAppReview = false,
    this.quranTranslations = false,
    this.quranTafsir = false,
    this.quranTranslationSearch = false,
    this.quranAudio = false,
  });

  /// Everything on (previews and tests).
  const FeatureFlags.all()
    : quran = true,
      prayer = true,
      favorites = true,
      shareCards = true,
      dailyHadith = true,
      adhanSounds = true,
      inAppReview = true,
      quranTranslations = true,
      quranTafsir = true,
      quranTranslationSearch = true,
      quranAudio = true;

  /// Reads the preview switch given at build time; off by default.
  factory FeatureFlags.fromEnvironment() =>
      const bool.fromEnvironment('HADEETHS_PREVIEW_SECTIONS')
      ? const FeatureFlags.all()
      : const FeatureFlags();

  final bool quran;
  final bool prayer;

  /// Favourite hadiths: the bookmark on a hadith and the list under More. The list lives under
  /// More, so favourites are only offered together with the bottom navigation.
  final bool favorites;

  /// Sharing a hadith as an image. Off in the released app, where sharing stays text only.
  final bool shareCards;

  /// The hadith of the day on the home screen, with its setting.
  final bool dailyHadith;

  /// Downloadable adhan recordings as the sound of the prayer reminders (Android 10 and later).
  /// Off until the owner has confirmed the right to offer the recordings (`docs/ADHAN_SOUNDS.md`).
  final bool adhanSounds;

  /// Asking the system to show its rating sheet at the right moment, and a "Rate" entry that opens the
  /// store page. Off until the implementation has been reviewed (`docs/IN_APP_REVIEW.md`).
  final bool inAppReview;

  /// Translations under each verse in the Quran reader's verse-by-verse layout, fetched through
  /// hadeeths' own proxy (`docs/QURAN_API_REFACTOR_PLAN.md`). Off until reviewed on a device.
  final bool quranTranslations;

  /// Tafsir (scholarly commentary) reachable per verse in verse-by-verse mode, fetched through
  /// the same proxy. Independent of [quranTranslations]: either can be on without the other.
  /// Off until reviewed on a device.
  final bool quranTafsir;

  /// Searching inside the reader's chosen translation edition (the Quran Foundation Search API,
  /// additive to the always-on on-device Arabic search). Only meaningful together with
  /// [quranTranslations], since there is no translation to search without it. Off until reviewed
  /// on a device.
  final bool quranTranslationSearch;

  /// A per-verse "Listen" action and a persistent mini player, playing a chosen reciter's
  /// recitation through the same proxy. Foreground playback only for this version -- no
  /// lock-screen controls or background-audio entitlement yet (deliberately deferred, see
  /// `docs/QURAN_API_REFACTOR_PLAN.md` flag D). Off until reviewed on a device.
  final bool quranAudio;

  /// The bottom navigation appears once there is more than the hadith home to switch to.
  bool get usesShell => quran || prayer;
}
