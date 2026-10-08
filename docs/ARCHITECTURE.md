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
    widgets/, constants/, logging/
  features/
    categories/
      domain/                    HadithCategory, CategoriesRepository (interface)
      data/                      CategoryDto, remote data source, CategoriesRepositoryImpl
      presentation/              CategoriesCubit, HomePage, CategoryPage, widgets
    hadiths/
      domain/                    HadithSummary, HadithPage, HadithDetails, HadithsRepository
      data/                      DTOs, remote data source, HadithsRepositoryImpl
      presentation/              HadithListCubit, HadithDetailCubit, pages, widgets, share text
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

## Dependency injection

Constructor injection plus `RepositoryProvider`. `AppDependencies.live()` builds one `HadeethClient` and both
repositories; `MyApp(dependencies: ...)` accepts fakes. `CategoriesCubit` lives above the `Navigator`; list and details
cubits are created per screen with `BlocProvider`.

## Decisions kept

- State management: `flutter_bloc` (ADR-1). DI: no second container (ADR-2). Routing: `Navigator` (ADR-3).
- Language: the data layer takes a `language` parameter (default `ar`); wiring it to the app locale belongs to the
  localization phase.
- Phase 4 will add a local data source next to the remote one inside each repository implementation; the domain
  entities and cubits should not need to change.

## Testing map

`test/` mirrors `lib/`: DTO parsing, data sources and repositories (fake Dio adapter), cubits (fake repositories),
widget flows through `MyApp` with fake repositories, and the architecture rules. Nothing touches the live API.
