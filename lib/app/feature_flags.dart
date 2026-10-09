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
  });

  /// Everything on (previews and tests).
  const FeatureFlags.all() : quran = true, prayer = true, favorites = true;

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

  /// The bottom navigation appears once there is more than the hadith home to switch to.
  bool get usesShell => quran || prayer;
}
