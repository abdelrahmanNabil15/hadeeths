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
  core/                          shared infrastructure; knows nothing about features
    errors/failure.dart          Failure + FailureKind (what went wrong, no raw exceptions)
    result/result.dart           Result<T> = Success | Err, Result.guard(...)
    network/                     HadeethClient (timeouts, retries, error mapping), endpoints
    json/json_helpers.dart       defensive JSON readers
    state/load_status.dart       LoadStatus shared by all cubits
    cache/                       ResponseCache (file, in-memory, switchable) and CachedFetcher (read-through policy)
    design_system/               tokens.dart (light and dark palettes, spacing, radii, sizes, motion) and AppTheme
    widgets/                     AppTile, ExpandableSection, state views (loading, skeleton, error, empty), ...
    licences.dart                font licence texts for the licences page
    logging/
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

## Decisions kept

- State management: `flutter_bloc` (ADR-1). DI: no second container (ADR-2). Routing: `Navigator` (ADR-3).
- Phase 4 will add a local data source next to the remote one inside each repository implementation; the domain
  entities and cubits should not need to change.

## Testing map

`test/` mirrors `lib/`: DTO parsing, data sources and repositories (fake Dio adapter), cubits (fake repositories),
widget flows through `MyApp` with fake repositories (both languages), accessibility, text-scale and contrast checks across both languages and both themes, search and settings flows,
translation parity, and the architecture rules. Nothing touches the live API.
