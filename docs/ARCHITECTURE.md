# Architecture

Implements ADR-1 to ADR-5 of [`PHASE0_REVISED_AUDIT.md`](PHASE0_REVISED_AUDIT.md). Phase 3 changed the structure, not
the behaviour: every user-visible flow works as at the end of Phase 2.

## Layout

```text
lib/
  main.dart                      entry point (debug-only Bloc observer)
  app/
    app.dart                     MyApp: providers, theme, home
    app_dependencies.dart        builds the repositories once (live) or takes fakes (tests)
    feature_flags.dart           which Phase 3 sections are on (all off in a normal build; preview with
                                 --dart-define=HADEETHS_PREVIEW_SECTIONS=true)
    shell/                       AppShell (bottom navigation, one Navigator per section, back handling), MorePage,
                                 ComingSoonPage. Used only when a section flag is on; otherwise the app opens on HomePage as before
  core/                          shared infrastructure; knows nothing about features
    errors/failure.dart          Failure + FailureKind (what went wrong, no raw exceptions)
    result/result.dart           Result<T> = Success | Err, Result.guard(...)
    network/                     HadeethClient (timeouts, retries, error mapping), endpoints
    json/json_helpers.dart       defensive JSON readers
    state/load_status.dart       LoadStatus shared by all cubits
    cache/                       ResponseCache (file, in-memory, switchable) and CachedFetcher (read-through policy)
    format/                      Digits (Western or Arabic-Indic for the app's own numbers; never applied to source text)
    time/                        Clock (always UTC), TimeZoneRules (offset at an instant; DST-aware wall-clock helpers), IanaTimeZone (IANA database, offline)
    notifications/               NotificationPlanner: pure, deterministic plan of what to keep pending (window, quiet hours,
                                 dedupe, platform limit, stable ids) and a diff against what is pending. No plugin, no UI yet
    database/                    UserDatabase over sqlite3 (user's own data, on-device only), MigrationRunner (one transaction per
                                 version, refuses a newer schema, corrupt file is set aside not deleted), schema.dart (released migrations)
    permissions/                 PermissionGateway (platform wrapper, implemented per feature) and PermissionFlow (explain first,
                                 then the system prompt; denial is an outcome, never an error)
    design_system/               tokens.dart (light and dark palettes, spacing, radii, sizes, motion) and AppTheme
    widgets/                     AppTile, ExpandableSection, state views (loading, skeleton, error, empty), ...
    licences.dart                font licence texts for the licences page
    logging/
  features/prayer_times/         (Phase 3B; behind the Prayer section flag) domain: CalculationSettings, PrayerDay, PrayerMoment, Qibla,
                                 PrayerPreferences (method proposed once), CityCatalog, CountryLookup, LocationSetup, PrayerServices;
                                 data: AdhanPrayerTimesCalculator, GeolocatorLocationService + permission gateway, preferences repository;
                                 Hijri (HijriConverter, HijriCoreConverter); live compass (WorldMagneticModel, HeadingCalculator,
                                 CompassSource over sensors_plus); presentation: PrayerCubit, PrayerPage, city picker, method,
                                 Hijri and Qibla pages (see PRAYER_TIMES_VALIDATION.md)
  core/text/                     normalizeForSearch (Arabic spelling variants for matching only; shown text is never changed)
  l10n/                          ARB files and generated AppLocalizations (+ context.l10n helper)
  features/
    categories/
      domain/                    HadithCategory, CategoriesRepository (interface)
      data/                      CategoryDto, remote data source, CategoriesRepositoryImpl
      presentation/              CategoriesCubit, HomePage, CategoryPage, widgets
    hadiths/
      domain/                    HadithSummary, HadithPage, HadithDetails, HadithsRepository
      data/                      DTOs, remote data source, HadithsRepositoryImpl
      presentation/              HadithListCubit, HadithDetailCubit, pages, widgets, share text
    search/
      domain/                    HadithSearchResult (+ highlight parsing, excerpt), SearchRepository
      data/                      search DTO ("no match" is an object, not a list), data source, repository
      presentation/              SearchCubit (debounce, minimum length, stale-answer guard), SearchPage
    settings/
      domain/                    AppSettings (language, theme, reading size), SettingsRepository
      data/                      SettingsRepositoryImpl over shared_preferences (corrupt values fall back)
      presentation/              SettingsCubit, SettingsPage, AboutPage, reading-size control
```

## Rules (enforced by `test/architecture_test.dart`)

| Layer | May depend on | Must not depend on |
|---|---|---|
| `domain` | Dart, `equatable`, `core/result`, `core/errors` | Flutter, Dio, `data`, `presentation` |
| `data` | `domain`, `core` | `presentation`, Flutter widgets |
| `presentation` | `domain`, `core`, Bloc, Flutter | Dio, any `data` file, DTOs |
| `core` | itself | `features` |

Only `lib/app/` (and each feature's `data/`) may reference a `*_repository_impl.dart`.

## Data flow

```text
Widget -> Cubit -> Repository (interface, domain)
                      `-> RepositoryImpl (data) -> RemoteDataSource -> HadeethClient (Dio)
```

- `HadeethClient` returns decoded JSON or throws a `Failure` (timeouts 10 s connect / 20 s receive; retries only for
  timeouts and 502/503/504, at most twice).
- The remote data source parses JSON into DTOs (`parseResponse` turns parsing problems into `FailureKind.parse`).
- The repository maps DTOs to domain entities and returns a `Result` (`Result.guard` catches `Failure` and also turns any
  unexpected exception into `FailureKind.unexpected`).
- Cubits switch on the `Result` and expose explicit states (`LoadStatus` plus data and failures).

## Saved copies (offline reading of opened content)

`CachedFetcher` sits between the data sources and `HadeethClient`:

1. a saved copy younger than the policy's `fresh` age is returned without a request (categories and lists 1 day, a hadith 7 days);
2. otherwise the server is asked, the answer is parsed first and saved only if it parses (a bad answer never replaces a good copy);
3. if the server cannot be reached (no connection, timeout, 5xx) an older copy is used, up to 60 days;
4. "not found" deletes the copy; pull-to-refresh (`refresh: true`) skips step 1.

Copies are the decoded JSON exactly as received, one small file each in the app's private storage (`FileResponseCache`:
atomic writes, each file records its own key, least-recently-used eviction above 20 MB, any I/O problem behaves like a miss).
Search is never cached. The user's "Offline reading" setting switches the cache (`SwitchableResponseCache`) and clearing
it removes the files. Repositories, cubits and screens are unaware of the cache apart from the `refresh` flag.

## Navigation shell (Phase 3A-3)

With every section flag off the app is unchanged: `HomePage` is the home and there is no bottom bar. When a section is on,
`AppShell` shows a Material 3 `NavigationBar` (Hadiths, Quran, Prayer, More; only the sections that are on) and keeps one
`Navigator` per section, so pages opened inside a section keep the bar visible and a section keeps its place when you leave it.
System back closes the open page, then returns to Hadiths, then leaves the app (`PopScope.canPop` is true only at the very first
page, so Android's back-to-home animation still works). Settings and "Sources and rights" move to More while the bar is showing.
The navigation bar colours come from the existing palette and are covered by the contrast tests. Prayer-state colours are not
added yet: they will be designed with the prayer dashboard in 3B, where they can be judged in context.

## Dependency injection

Constructor injection plus `RepositoryProvider`. `AppDependencies.live()` builds one `HadeethClient` and both
repositories; `MyApp(dependencies: ...)` accepts fakes. `CategoriesCubit` lives above the `Navigator`; list and details
cubits are created per screen with `BlocProvider`.

## Localization, direction, accessibility and design

- gen-l10n with `app_ar.arb` as the template and `app_en.arb`. `MaterialApp` supports `ar` and `en`; anything else
  falls back to Arabic. `context.apiLanguage` is the API language code and flows through the cubits to the repositories.
- A `CategoriesCubit` keyed by language sits above the navigator: a language change reloads the tree.
- Layout uses `AlignmentDirectional` / `EdgeInsetsDirectional` and Material icons that mirror on their own; nothing forces
  a text direction.
- Category cards sit in rows that are as tall as their tallest card (no fixed heights), with fewer columns as text grows.
- Screen readers: headings are marked, tiles announce title and count, expandable sections announce expanded/collapsed,
  errors are live regions, icon buttons have tooltips.
- Settings are loaded before the first frame (`main` awaits them), so the saved language and theme apply immediately.
  `MyApp` rebuilds `MaterialApp` from `SettingsCubit`; the language-keyed `CategoriesCubit` reloads on a language change.
- Reading text: Amiri for Arabic (line height 2.0), Cairo for English (1.7), scaled by the reading-size setting on top of
  the device text size. Cards and tiles use theme colours only; no widget hard-codes a colour.
- Motion: sections animate for 250 ms; with the system's "remove animations" setting nothing animates (and no
  `AnimatedSize` is built, which would assert with a zero duration).

### Design foundations (UI Phase A, additive)

- `AppMotion` (tokens): `instant` 100, `short` 150, `medium` 250, `page` 280 (`pageReverse` 220), `emphasis` 400 ms, and the curves
  `standard`, `enter`, `exit`. Read them as `context.motion(AppMotion.medium)` (`design_system/motion.dart`), which returns zero when the
  system removes animations. `test/core/motion_test.dart` fails if a screen, shell file or shared widget contains a `Duration(...)` literal.
- `AppColors` (theme extension): success, warning and the reading surface, with contrast-checked pairs; `AppColors.of(context)`.
- `AppTypography.of(context)`: named styles (display, title, heading, body, meta, label, number). Hadith text keeps `ReadingText`.
- `appRoute()` (`core/navigation`): opt-in page route per call site. iOS keeps the platform slide; elsewhere a short fade with a 2%
  vertical move; nothing moves with animations removed. No existing route uses it yet. When a flow adopts it, adopt it for the whole
  flow including its first route: the page underneath is moved by its own route's transition, so a mixed stack would fade one page
  while the default transition still slides the other.
- `Haptics` (`core/haptics`): `selection()` and `alignment()` through the system; no in-app setting. Not yet used (the Qibla cue still
  calls `HapticFeedback` directly until UI Phase D).
- Shared widgets added: `StatusBanner`, `AnimatedStateSwitcher`, `PressableScale`. No existing widget changed.
- Finding: `MaterialApp` is given a new `AppTheme.light()` on every settings rebuild, and the theme contains closures that never compare equal,
  so the theme animates (about 200 ms) on each settings change. Left as is; to be looked at in UI Phase B.
- UI Phases B and E: `TabFade` fades a section in on selection. **Every route in the app is an `appRoute()`** (the first page, the shell's
  section roots and every push); no code builds a `MaterialPageRoute` by hand (`test/app/phase_e_test.dart` fails if one appears). iOS keeps the
  platform slide inside `AppPageRoute`. `AppTile.pressFeedback` is opt-in and is still off on every released tile. The `MaterialApp` themes are built
  once in `_MyAppState`. Home and the hadith list fade between loading, error, empty and loaded (`AnimatedStateSwitcher`, one key per state, so
  loading more pages never fades); the hadith details page fades only between loading and error, never the hadith itself.

### Luxury revamp (branch `ui/g-luxury-revamp`)

The same design system, refined; no competing system and no new dependency or font file.

- **Palette** (`tokens.dart`): light is warm ivory canvas, midnight-emerald primary (`0B4A3B`), charcoal text, sage containers,
  muted gold secondary. Dark is a charcoal canvas whose container steps add emerald, not an inverted light theme.
- **`AppColors` roles added**: `gold`, `goldSoft` (ornaments and thin rules only, never text or large areas), `sage`/`onSage` (count
  pills, secondary surfaces), `hero`/`onHero`/`onHeroMuted`/`heroAccent` (the midnight-emerald panels). Text pairs are tested at 4.5:1,
  marks at 3:1 (`test/core/app_colors_test.dart`).
- **Shape and depth**: `AppRadius` control 12, card 16, sheet and dialog 24, pill; `AppBorders.hairline`/`emphasis`;
  `AppShadows.soft` is the only shadow, used for raised cards (reading surface, home search). Surfaces are flat by default.
- **Type**: `AppFonts.editorial` is Amiri (Naskh Arabic plus serif Latin, already bundled); `AppTypography.editorialTitle`,
  `editorial` and `sectionLabel` (no letter spacing, which would break Arabic joining). Cairo stays the UI face; reading text keeps
  `ReadingText`. Hadith titles use the editorial face at regular weight, because titles can be a whole sentence.
- **Theme** (`app_theme.dart`): component themes for inputs (rounded, 3:1 edge, brand focus), dialogs, sheets (drag handle, 24 corners),
  switches, sliders, chips, progress, segmented buttons, tooltips, popup menus, cards, icon and outlined buttons, the navigation bar
  (card colour, sage pill, brand label) and a calm `InkRipple`.
- **Shared components** (`core/widgets`): `AppCard` is the one card (tiles, option groups, search entry, reading surface, expandable
  sections, result cards and settings groups all use it). `GeometricPattern` is an eight-fold star lattice drawn in code at 4 to 8%
  opacity: no semantics, its own layer, no animation, never behind reading text. `OrnamentDivider` is a fine rule with a small gold
  star. `showOptionsSheet` and `SheetOption` give every options sheet the same look. `AppIcons` holds shared glyphs; the chevron is
  `chevron_right_rounded`, which mirrors in RTL. `StateMedallion` is the empty and error emblem.
- **Screens**: home has a `HomeHero` (emerald panel, date from an injected `Clock`, gold ornament, editorial title, raised search).
  Loading, error and empty states use a compact header so the message stays visible at 200% text. The prayer page's next prayer uses
  the same emerald panel. The hadith page has an editorial title, ornament, raised reading surface and a quiet credit footer. Search has
  a rounded field with the search icon in the brand colour. More has leading icons, with the personal pages grouped apart from Settings
  and About. Location setup uses the medallion. Skeletons are hairline cards with faint text bars, and stay static.
- **Screenshots**: `flutter test test_screens/screens_test.dart --dart-define=SHOTS=<name>` renders the main screens with fake data
  and the real fonts into `build/screens/<name>/`. It covers Arabic and English, light and dark, 200% text and a tablet width. It is
  not part of `flutter test` (only `test/` runs there). The test renderer draws `BoxShadow` blur as a hard band; on a device the
  shadow is soft (checked on the emulator).


## Decisions kept

- State management: `flutter_bloc` (ADR-1). DI: no second container (ADR-2). Routing: `Navigator` (ADR-3).
- Phase 4 will add a local data source next to the remote one inside each repository implementation; the domain
  entities and cubits should not need to change.

## Testing map

`test/` mirrors `lib/`: DTO parsing, data sources and repositories (fake Dio adapter), cubits (fake repositories),
widget flows through `MyApp` with fake repositories (both languages), accessibility, text-scale and contrast checks across both languages and both themes, search and settings flows,
translation parity, and the architecture rules. Nothing touches the live API.

## Prayer tracker (Phase 3D-1)

- `lib/features/tracker/`: `DayKey` (a calendar day with no zone, `yyyy-MM-dd`), `PrayerLogRepository` (interface), `SqlitePrayerLogRepository`
  (data), `TrackerCubit`, `TrackerPage`. Table `prayer_log(day, prayer)` was added as migration 2 of the user database: one row per prayer marked as
  prayed, nothing else (no time, place or note); unmarking deletes the row; only the five prayers are accepted (a CHECK in the table and a guard in the code).
- "Today" is the date on the clock in the zone of the saved place (the phone's zone if there is none), so the day changes at that place's midnight;
  it is read again when the app comes back to the front. The screen shows today and the six days before it; any of them can be marked.
- A mark shows at once and is saved after it; saves run in the order of the taps; a failed save is taken back and explained.
- Reached from More ("Prayer tracker") when the prayer section is on and the user database opened. No streaks, scores, notifications or "missed" wording.
  "Delete tracker data" (with confirmation) removes everything.
- Privacy: the tracker code imports no network, location or sharing package (a test scans it); no share card includes it.

## Tasbeeh counter (Phase 3D-2)

- `lib/features/tasbeeh/`: `TasbeehCounter` (count, optional target of 33, 99 or 100, progress per round), `TasbeehRepository`, `SqliteTasbeehRepository`
  (table `tasbeeh_counter`, a single row, migration 3), `TasbeehCubit`, `TasbeehPage`. Reached from More ("Tasbeeh counter").
- It is a plain counter with **no words of its own**: the user decides what they are counting, and a test fails if the feature's code contains any Arabic text.
- The count goes up the moment a finger touches the circle (pointer down), in memory, before anything is saved, so quick taps are never merged or lost
  (tests: 100 taps in the cubit, 60 in the widget flow). Saves run in order and each writes the count as it is by then, so the last one holds the total.
  A failed save leaves the count on screen and shows a warning. Taps before the saved count has been read are ignored so they cannot be overwritten by it.
- Feedback: a light system tick per tap and a firmer one when the count lands on a multiple of the target (through the `Haptics` service; no setting). The
  ring beside the count is a plain determinate indicator: nothing animates, so nothing waits for an animation.
- Undo takes one off, reset (with confirmation) zeroes the count and keeps the target; screen readers hear "Count N" as a live region and can activate the circle.
- Privacy: no network, location or sharing code (tested); nothing is shared.

## Favourite hadiths (Phase 3F-1)

- `lib/features/favorites/`: `FavoritesRepository` (interface), `SqliteFavoritesRepository` (table `favorites(hadith_id, added_at)`, migration 4),
  `FavoriteButton` (the bookmark in a hadith's app bar) and `FavoritesPage` (the list under More).
- **Ids only.** No text, title or grade from HadeethEnc is stored in the user's data (that would be keeping content, which the source's terms and the
  plan do not allow without permission). The list reads each title the same way as opening the hadith, so saved copies make it work offline for hadiths
  already read; if a title cannot be read the row says "Hadith N" and still opens it. The same id is the same hadith in both languages.
- Only digits are accepted as an id (anything else is refused before it reaches the database).
- **Released app unchanged:** a new flag `FeatureFlags.favorites` (on with the preview sections) and `AppDependencies.favoritesIfEnabled` decide whether
  the bookmark exists at all; the repository is provided as a nullable `RepositoryProvider<FavoritesRepository?>` and the button renders nothing when it
  is null. A test checks that a normal build shows no bookmark.
- The bookmark is one screen-reader node with a toggled state and a tooltip that says what tapping will do; a light tick accompanies it; the icon change
  is a short scale that disappears with "remove animations".

## Quran (Phase 3E)

- **Text:** `assets/quran/quran-uthmani.txt`, the Tanzil Quran Text (Uthmani, Version 1.1, CC BY 3.0), downloaded by the owner and bundled
  **unchanged**, with its copyright notice. `lib/app/quran_wiring.dart` records its size and fingerprint; `BundledQuranSource` refuses any other
  file, and `QuranText.parseTanzil` refuses any missing, repeated or out-of-order verse and any total other than 114 suras and 6236 verses. A test
  reads the real file and checks every verse byte for byte against what the app shows. To update the text, replace the file and record the new
  values (`dart run tool/quran_fingerprint.dart assets/quran/quran-uthmani.txt`).
- **Line endings:** `.gitattributes` marks the file `-text`, so Git never converts its line endings (this repository uses `core.autocrlf`, which
  would otherwise change the bytes on a Windows checkout and the app would refuse the file).
- **Basmala:** the file already starts verse 1 of every sura except al-Fatihah, where it is verse 1, and at-Tawbah, which has none, with the basmala;
  in suras 95 and 97 it has a shadda on the ba, as published. The reader adds nothing above the verses.
- **Font:** Amiri Quran 1.003 (`AppFonts.quran`, SIL OFL 1.1).
- **Screens:** list of suras (names written for owner review), reader (each verse unchanged, right to left in both interface languages, number drawn
  beside it), go to a verse, bookmarks (long press), continue reading, search (marks ignored for matching only). Positions only are stored
  (migration 5). Credit in the section and in About.

## Share as image (Phase 3G-1)

- With the `shareCards` flag on (preview sections), a hadith's share button asks "Share as text" or "Share as image"; the released app still shares
  text straight away (a test checks it).
- `ShareCardPage` lays the hadith out on 360 x 450 cards (saved as 1080 x 1350 PNGs), always in the light palette and without the phone's text
  scaling. Each card has the app's name, a piece of the hadith, and the HadeethEnc credit; the grade and narrator are on the last card; cards are
  numbered when there is more than one.
- `splitIntoPages` breaks the text only at spaces and never changes it: the pieces joined with single spaces equal the original with its spaces
  collapsed (tested); a word longer than a card gets a card of its own, uncut.
- `ImageSharer` (core) writes the PNGs to the app's temporary folder and opens the system share sheet; nothing is uploaded by the app. Every card is
  built (not only those on screen) so each one can be captured; the share button stays at the bottom of the screen.
