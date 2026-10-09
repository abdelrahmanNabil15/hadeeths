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
