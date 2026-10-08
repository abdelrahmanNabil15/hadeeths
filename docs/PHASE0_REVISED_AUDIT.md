# Hadeeths — Phase 0 Revised Audit, Decisions and Roadmap

Revision date: 2026-10-09. Supersedes the in-chat Phase 0 audit of 2026-10-08 (original findings are kept in
section 2 with their corrections). Repository state audited: branch `master`, commit `476ac6f`, clean tree.
**No repository source file was modified.** All trial builds ran in a scratch copy (`git archive` of HEAD).

Status legend: PASS / FAIL / BLOCKED / NOT RUN. "Confirmed" = observed in code, a run, or the live API.
"Inferred" = reasoned, not observed.

---

## 1. Executive summary

- **The app does not compile on the installed toolchain (Flutter 3.44.8 / Dart 3.12.2).** One hard error
  (`backwardsCompatibility` was removed from `AppBarTheme`) blocks analyze, test, and every build. After a
  one-line patch in a scratch copy, the web build succeeds and the first screen renders; the Android build still
  fails because the Gradle project predates the declarative plugin system.
- **Correction of my earlier claim:** Dart 3 does *not* reject `sdk: ">=2.12.0 <3.0.0"`. `flutter pub get` succeeded
  unchanged. The SDK constraint is a hygiene item, not a blocker.
- **Product-level data bug (rendered and confirmed):** the "main categories" grid shows the first 20 of 493
  flattened categories (7 roots + 486 descendants, 5 levels deep). Child categories appear among roots.
  The API has a dedicated `categories/roots` endpoint the app does not use.
- **Two earlier findings were overstated or wrong** (details in section 2): the "details never load" bug is
  latent, not live; and the root-level Cubit never issues requests because `BlocProvider` is lazy.
- **Licensing is the main non-code risk.** The bundled background image carries embedded metadata identifying it as
  a Rawpixel Ltd. asset; whether our rights cover embedding it in an app is unverified. HadeethEnc's published
  terms differ between its website (7 conditions) and its API docs (2 conditions) and say nothing explicit about
  caching. Fonts bundled are OFL (verified from embedded metadata).
- **Direction:** stabilize the build, fix correctness bugs on the existing stack, then refactor. **Keep
  `flutter_bloc`** (reversing my earlier Riverpod recommendation, see ADR-1). Defer the database until licensing
  is settled.

---

## 1a. Status update (2026-10-09, after Phases 1, 2, 3, 5 and the redesign)

| Finding | Status |
|---|---|
| F-01 compile error | Fixed (Phase 1) |
| F-02 Android Gradle project | Fixed: Gradle 9.1.0, AGP 9.0.1, Kotlin 2.3.20 (Phase 1) |
| F-03 `INTERNET` in release | Fixed and verified in the release APK (Phase 1) |
| F-04 release signed with debug key | Fixed: unsigned unless `key.properties` exists; checked by `tool/check_release_config.sh` and CI |
| F-05 Rawpixel backdrop | **Resolved by removal** (redesign): the image is no longer bundled; a test guards against stock imagery |
| F-06..F-14 categories, errors, paging, parsing, cubits, timeouts | Fixed with regression tests (Phases 2 and 3) |
| F-15, F-17 hard-coded strings, forced RTL | Fixed: Arabic and English, directional layout (Phase 5) |
| F-16 accessibility | Fixed and tested in both languages and both themes (Phase 5 and redesign) |
| F-18 backdrop memory | Resolved by removing the backdrop |
| F-19 dependencies | Fixed (dio 5, `share_plus`, unused packages removed; no advisories) |
| F-20 tests | Replaced; 200+ tests |
| F-21 identity | Android `com.hadeeths.eg` done; **iOS bundle id still a placeholder** |
| F-22 CI | Written (`.github/workflows`), **not yet run on GitHub** |
| F-23 iOS target | Raised to 13.0, **not built (needs macOS)** |
| F-24 unused font | Removed |
| F-27 unused server features | Search adopted; `hadeeth_intro` deliberately not shown (it repeats the start of the hadith) |
| Phase 4 (offline storage) | **Blocked** on HadeethEnc's written permission to cache |

## 2. Corrections to the original audit

| # | Original claim | Verdict | Evidence |
|---|---|---|---|
| C1 | Dart 3 rejects the `<3.0.0` SDK constraint, so the project cannot resolve | **Wrong.** `pub get` succeeded unchanged | `flutter pub get` in scratch copy: exit 0, 19 dependencies changed |
| C2 | (not reported) | **New P0:** compile error blocks all builds | `lib/main.dart:49`; `flutter analyze` = 1 error; `flutter test` fails at compile |
| C3 | "AGP 4.1.0 + Gradle 6.7 can't run on JDK 17" | **Confirmed and refined.** The Flutter tool auto-bumped Gradle 6.7→7.6.1, then failed on the imperative plugin loader | scratch `flutter build apk --debug`: `app_plugin_loader` "not possible anymore" |
| C4 | Release build lacks `INTERNET` | **Confirmed by reading.** Present only in debug/profile manifests. Release build NOT RUN | `android/app/src/main/AndroidManifest.xml` has no `uses-permission`; `debug/` and `profile/` have it |
| C5 | Grid has hard-coded `itemCount: 20`; API returns more | **Confirmed and sharpened:** 493 categories, 7 roots, depth 5, `parent_id` present; the grid mixes roots and children under a "main categories" heading | live API probe 2026-10-09; rendered web screenshot |
| C6 | "`getdetails` only fetches when `category == null`, so details may never load" | **Overstated.** Each screen creates a fresh `AlmunirCubit`, so `category` is always null there. The bug becomes live only if cubits are shared (which a naive fix of the duplicate-cubit issue would do) | `cubit.dart:94`, `hadeethsdetails.dart:24` |
| C7 | "Pagination is fake; `itemCount` can exceed `data.length`" | **Partly right.** The API does paginate correctly (`page`, `per_page` default 20, `last_page`) and accepts `per_page` up to at least 100000. The largest category (1,820 items) fits under 2000, so no mismatch reproduces today. The code still assumes `total_items == data.length`, and the 2022 screenshot shows `RangeError (index): Invalid value: Not in inclusive range 0..449: 450`, so it did fail in practice | `Widget.dart:157,162`; `Screenshot_20220228_163757.png`; API probe |
| C8 | "Model fallback types are wrong, parsing fails" | **Refined.** Real types match the models (`current_page`/`per_page` strings, `last_page`/`total_items` ints, ids strings). Only the fallbacks are mistyped, so they are dead code on the happy path | `categoryModel.dart:33,50-53`; live types |
| C9 | "Root cubit and screen cubit both fetch, duplicating requests" | **Wrong for the root.** `BlocProvider` is lazy and nothing reads the root cubit, so it is never created (single `onCreate` in console, single categories request). `Hadeeths` does issue a needless `getCategories()` | `main.dart:36-41`; `hadeeths.dart:21`; browser console/Performance entries |
| C10 | "Fonts and background of unknown provenance" | **Resolved.** `Cairo.ttf` = OFL 1.1 (variable font). `subfont.ttf` = SIL Lateef, OFL with Reserved Font Names. Background = Rawpixel Ltd. asset "Golden glittery Eid Mubarak border" | name tables parsed from the font files; JPEG EXIF/XMP |
| C11 | Tanzil terms (third-party summaries) | **Now primary-source verified** at tanzil.net/docs/text_license on 2026-10-09 | see licensing matrix |
| C12 | "Recommend Riverpod" | **Reversed.** See ADR-1 | — |
| C13 | "Web build is broken by `dart:io`" | **Softened.** A patched web build runs and renders; `InternetConnectionChecker` raised an uncaught `Error` in the console | scratch web run |
| C14 | `gradlew`/wrapper jar missing from the repo | **Downgraded to P3.** They are gitignored by Flutter's template and regenerated by the tool | `android/.gitignore`; scratch build output |
| C15 | Non-Arabic detail responses (not examined) | **New P1 for any English support:** `hadeeths/one?language=en` returns no `reference` and no `words_meanings`, so `reference = json['reference']` (`detailsModel.dart:35`) would throw | live API probe |

---

## 3. Findings register

Severity per the brief. "Reg." = regression risk of the fix.

| ID | Sev | Finding | Evidence | Impact | Fix | Deps | Reg. | Verification |
|---|---|---|---|---|---|---|---|---|
| F-01 | P0 | App fails to compile on current Flutter | `lib/main.dart:49` | No build, analyze, or test is possible | Remove `backwardsCompatibility` (and its ignore comment) | none | Low | `flutter analyze` 0 errors |
| F-02 | P0 | Android Gradle project cannot build on JDK 17 / current Flutter | `android/build.gradle:2,9`; `android/app/build.gradle:24-26`; `android/settings.gradle:11`; wrapper 6.7 | No Android artefact | Regenerate Android embedding, keep app id; adopt declarative plugins | F-01, approved app id | Med | `flutter build apk --debug` PASS |
| F-03 | P0 | Release build has no `INTERNET` permission | `AndroidManifest.xml` (main) | Release APK cannot reach the API (code-verified; not built) | Add permission to main manifest | F-02 | Low | Install a release build, observe categories load |
| F-04 | P0 | Release signed with debug key | `android/app/build.gradle:57` | Cannot publish; insecure | Separate signing configs read from untracked `key.properties` / CI secrets | keystore owner | Low | Release build fails without secrets, succeeds with |
| F-05 | P0 (licensing) | Bundled background has third-party rights | `assets/backgruond.jpg` XMP: © Rawpixel Ltd., license page rawpixel.com/services/licenses | Possible infringement; Rawpixel personal and free licences forbid redistributing images (clause 3.3/3.6 of its personal licence) | Prove an adequate licence, or replace the image | owner input | Low | Licence receipt on file, or asset replaced |
| F-06 | P1 | "Main categories" shows 20 of 493 flattened nodes | `Widget.dart:122`; API; rendered screenshot | Wrong content, subcategories under the wrong heading, 473 categories unreachable | Use `categories/roots` for the home grid; build the tree from `parent_id` | product decision on UI | Med | Widget test with fixture of mixed roots and children |
| F-07 | P1 | No error UI anywhere; permanent spinner on failure | `hadeethsCategory.dart:27` (empty listener), `Widget.dart:128-144,209-213,560-564`; `cubit.dart:42-45,66-69,106-114` | Failure is invisible; the spinner never ends (code-verified; offline run NOT RUN) | Explicit Loading/Success/Empty/Error states with retry | F-09 | Low | Widget tests per state |
| F-08 | P1 | List assumes `meta.totalItems == data.length` | `Widget.dart:162,164-198`; 2022 crash screenshot | `RangeError` whenever the server returns fewer items | Use `data.length`; implement real paging with `page`/`last_page` | none | Low | Unit test with `total_items > data.length` |
| F-09 | P1 | Monolithic cubit, one instance per screen, mixed concerns | `cubit.dart:18-200` | Duplicate fetches, stale state, untestable | Split per feature (ADR-1) | F-01 | Med | Cubit unit tests |
| F-10 | P1 | `reference` / `words_meanings` crash for non-Arabic or null fields | `detailsModel.dart:29-35` (`late` fields, non-null assignment) | Crash on English or sparse records | Nullable fields, defensive parsing | none | Low | Parsing tests with `ar`, `en` fixtures |
| F-11 | P1 | Fake pagination: `isFinish` always true; `loadMore` re-fetches after a 2 s delay | `Widget.dart:157`; `cubit.dart:74-82` | Dead UI, wasted request | Delete `loadMore` or implement paging | F-08 | Low | Manual + unit |
| F-12 | P1 | No network timeouts; static singleton | `DioHelper.dart:14-34` | Hangs on poor networks; untestable | Configured client with timeouts and error mapping | none | Low | Fake-adapter tests |
| F-13 | P2 | `getdetails` guarded by `category == null` (latent) | `cubit.dart:94` | Becomes a live P1 once cubits are shared | Remove the guard when splitting the cubit | F-09 | Low | Test shared-instance case |
| F-14 | P2 | Connectivity logic broken and duplicated | `cubit.dart:126-191` (30 s listener; `InternetAddress.lookup` result discarded) | Offline banner works for 30 s only; uncaught error on web | One connectivity source; drop 3 unused packages | F-09 | Low | Unit test with fake stream |
| F-15 | P2 | Hard-coded strings and colors; no localization | `lib/` (29 lines containing Arabic or English UI literals across 3 files), `constant.dart:3-5`, `Widget.dart:60,69,197`, `hadeethsCategory.dart:32` | No i18n, inconsistent theme | gen-l10n + tokens | later phase | Low | Lint + review |
| F-16 | P2 | No accessibility semantics; low-contrast title | zero `Semantics`/`tooltip`/`semanticLabel` in `lib/`; white title on beige (`hadeethsCategory.dart:32-38`) | Screen readers get no labels; title contrast poor | See UX proposal | UX approval | Low | Contrast checker, TalkBack run |
| F-17 | P2 | `Customtext` forces `TextDirection.rtl` per widget and no app locale | `CustomText.dart:37` | Mixed text and Material widgets render LTR/English | Set locale and `Directionality` at the app level | l10n | Med | RTL widget tests |
| F-18 | P2 | 6.2 MB 2250×4000 JPEG used as full-screen backdrop | `assets/backgruond.jpg` | Memory and APK size | Replace with a small asset (see F-05) | F-05 | Low | DevTools memory |
| F-19 | P2 | Discontinued/stale/unused dependencies | `pubspec.yaml:38-49`; `pub get` reports 1 discontinued, 2 advisories (dio 4.0.4 flagged) | Security and maintenance | Remove unused; upgrade; `share`→`share_plus` | F-01 | Med | `pub get`, analyzer |
| F-20 | P2 | Only test is the template counter test (fails to compile) | `test/widget_test.dart:14-30` | No safety net | Replace | F-01 | Low | CI |
| F-21 | P2 | Placeholder identity | `applicationId` `android/app/build.gradle:46`; iOS `PRODUCT_BUNDLE_IDENTIFIER`; Android label hard-coded; `CFBundleName` | Cannot ship | Set after the owner confirms ids | approval | Low | Release build |
| F-22 | P2 | No CI; `.github` absent | repo root | No regression gate | GitHub Actions plan (section 10) | F-01 | Low | Green run |
| F-23 | P2 | iOS deployment target 9.0 | `project.pbxproj:275,349,398`; Flutter 3.44 template uses 13.0 | Cannot build for modern Xcode | Raise to Flutter default | macOS runner (BLOCKED here) | Low | iOS build on macOS |
| F-24 | P3 | `subfont.ttf` registered but unused | `pubspec.yaml:94-96`; no usage in `lib/` | 219 KB dead weight; OFL requires the licence text if kept | Remove after confirming | owner | Low | grep |
| F-25 | P3 | Screenshots (5.8 MB) in repo root; empty README | repo root | Hygiene | Move into `docs/` | none | None | — |
| F-26 | P3 | Dead code (`DioHelper.onError`, no-op `Category;`, `.then((print))`, unused `RefreshController`) | `DioHelper.dart:29`; `cubit.dart:86,114,21` | Noise | Delete during refactor | none | None | Analyzer |
| F-27 | P3 | App does not use available server features: `categories/roots`, `hadeeths/search` (returns max 100 results, no pagination, phrase ≥ 3 chars, server-side `<mark>` highlights, handles diacritics), `hadeeths/multiple`, `hadeeth_intro` field | Postman docs; live responses 2026-10-09 | Missed capability | Adopt as approved | product | Low | — |

---

## 4. Baseline results (2026-10-09, scratch copy of HEAD)

| Check | Result | Detail |
|---|---|---|
| `flutter pub get` (unchanged `pubspec.yaml`) | **PASS** | Lockfile re-resolved; 42 packages have newer incompatible versions; 1 discontinued; 2 advisory notices |
| `flutter analyze` | **FAIL** | 1 error (`main.dart:49`), 5 infos (unnecessary imports, `prefer_const_constructors`) |
| `flutter test` (template test) | **FAIL** | Compile error from `main.dart:49`; the test itself is also obsolete |
| Patched scratch copy: `flutter analyze` | **PASS** (0 errors; 5 infos) | patch = delete the two lines in `main.dart` |
| Patched scratch copy: `flutter build web --release` | **PASS** | renders; categories load |
| `flutter build apk --debug` (unpatched project files, scratch) | **FAIL** | Gradle migration notice, then plugin-loader failure |
| Release Android build / signing | NOT RUN | |
| iOS build | BLOCKED | needs macOS |
| Offline-state run | NOT RUN | |
| `flutter doctor` | Android SDK 36 present; **licences status unknown** (will block CI-like local builds until accepted); JDK 17; Chrome OK | |

Not done: running on an Android emulator/device (none attached); device-size tests.

---

## 5. Buildable-baseline path (staged)

Verified from a generated template with the installed Flutter 3.44.8: Gradle **9.1.0**, Android Gradle
Plugin **9.0.1**, Kotlin **2.3.20**, Java **17**, iOS deployment target **13.0**; plugins are applied declaratively.

Recommended stages (each a commit on the branch `phase-1/build-stabilization`):

1. Remove the compile error (F-01). Gate: analyze 0 errors, web build PASS.
2. Regenerate the Android and iOS runners with `flutter create --platforms=android,ios .` **after the owner confirms
   the production application id and platform scope**, then port the app id, label, permissions and signing.
   Do not upgrade AGP/Gradle by hand; take the template's versions together.
3. Add `INTERNET`; separate debug/release signing (`key.properties` ignored by git).
4. Dependency pass: remove `data_connection_checker_tv`, `flutter_offline`, `modal_bottom_sheet` (no imports found);
   replace `share`; update `dio`, `flutter_bloc`, `internet_connection_checker`; resolve one package at a time.
5. Accept Android SDK licences locally (the owner's machine action, not performed).

I did **not** verify Flutter's published minimum-version policy beyond what the installed template shows, and did not
check iOS/Xcode requirements (no macOS).

---

## 6. Architecture decision record

**ADR-1 State management — keep `flutter_bloc`; split the monolith.**
Context: one 200-line cubit used by three screens; no feature needs cross-provider async graphs today.
Options: (a) Riverpod; (b) keep Bloc/Cubit.
Decision: (b). The team already uses Bloc, the redesign brief forbids switching frameworks for UI work, and the
defects are structural (instance-per-screen, mixed concerns), not caused by the library. Riverpod's strengths
(composed async providers) only matter for Phase 6 (location → prayer times → scheduled notifications); revisit then.
Consequences: `CategoriesCubit`, `HadithListCubit`, `HadithDetailCubit`, one app-level `ConnectivityCubit`,
provided above the `Navigator` so they survive navigation.

**ADR-2 Dependency injection — constructor injection + `RepositoryProvider`. No `get_it`/`injectable`.**
Three repositories do not justify a second container; tests inject fakes via constructors.

**ADR-3 Routing — stay on `Navigator`/`MaterialPageRoute` until deep links are required.**
Three routes. Adopt `go_router` only with an approved deep-link or share-link feature.

**ADR-4 Layers — pragmatic feature folders.**
`features/{categories,hadiths,search}/{data,domain,presentation}` only where a layer holds real code. Entities exist
only where API models would otherwise leak into widgets (for example `Hadith` vs `HadithDto`). No use-case classes
that merely forward a call.

**ADR-5 Errors — sealed `Failure` + `Result<T>`.**
`Failure`: `NoConnection`, `Timeout`, `Server(status)`, `NotFound`, `Parse`, `Storage`, `Unexpected`.
Observed server behaviour to map: unknown category id → **HTTP 500** with JSON `{"status":false,"error":...}`;
unknown hadith id → **404 with empty body**; page beyond the last → **200 with empty `data`**. Never surface raw
exception text in the UI.

**ADR-6 Local database — Drift is the preferred candidate; decision deferred to Phase 4.**
Not verified: current Drift version compatibility with this Dart/Flutter, its web support, FTS5 availability on all
targets. Search normalization must live in separate columns, never replacing source text. **BLOCKED on licensing**
(section 7). The online `hadeeths/search` endpoint covers search until then.

**ADR-7 Networking.**
One `Dio` instance in a `HadeethApi` class: connect/receive timeouts (proposed 10 s / 20 s), response validation,
retries only for idempotent GETs on timeout/5xx (max 2, exponential backoff, no retry on 4xx), request
cancellation via `CancelToken` on cubit close. Observed: no `Cache-Control`, `ETag`, rate-limit or version fields in
responses, so there is no conditional-request or version-sync mechanism to rely on. Note that Cloudflare returned 403 to a
default Python `urllib` user agent but not to `curl` or Dio, so keep a descriptive `User-Agent`.

---

## 7. Licensing matrix

Verified on 2026-10-09 from the owners' own pages where reachable. Not legal advice.

| Source | Rights holder | Terms found | Online display | Offline cache | Bundle/redistribute | Modify/normalize | Attribution | Status |
|---|---|---|---|---|---|---|---|---|
| **HadeethEnc content/API** | Unnamed on site (footer "HadeethEnc.com © 2026") | Website lists 7 conditions: no changes, credit publisher+source, state version, keep transcript info, notify them of notes, update to latest version, no inappropriate ads. **API docs (Postman) list only 2:** no modification/addition/deletion; refer to publisher and source. No licence named. No explicit statement on caching | Allowed under the conditions | **Unclear**: caching is "downloading" under the website terms (version + update duties) | Unclear | Not allowed; keep a separate normalized index | **Required, currently missing in the app** | **BLOCKED for Phase 4 bulk caching until written permission.** Online display with attribution is OK to build |
| **Quran text (Tanzil)** | Tanzil Project | CC BY 3.0; verbatim copies only; text may not be changed; source clearly indicated; link to tanzil.net; copyright notice kept in all copies and derived files (tanzil.net/docs/text_license) | Yes | Yes (verbatim) | Yes (verbatim) | **No** | Required + link | Usable; not yet adopted |
| **Tanzil translations** | various | Non-commercial only per third-party summary (not re-verified at source) | ? | ? | ? | ? | ? | UNVERIFIED |
| **KFGQPC fonts (Mushaf)** | King Fahd Glorious Quran Printing Complex | Sources conflict (Complex says free for software; others list proprietary-free, no modification) | ? | ? | ? | No | ? | **BLOCKED**: obtain written confirmation |
| **Quran.Foundation API** | Quran Foundation | OAuth client credentials; text may not be modified; no resale/redistribution except integral to the experience. Full terms not read | Yes with credentials | Unknown | Unknown | No | Unknown | UNVERIFIED; server-side secrets conflict with a no-backend app |
| **Madinah mushaf layout/page images** | KFGQPC / third parties | Public Quran.com thread asking about permission is unanswered | ? | ? | ? | ? | ? | **BLOCKED** |
| **Recitation audio (EveryAyah etc.)** | Reciters/publishers | No published licence found; only a link-back request | ? | **No download feature until written permission** | ? | ? | link-back | **BLOCKED** |
| **Tafsir/translation texts** | per source | Not investigated | ? | ? | ? | ? | ? | NOT RUN |
| **`Cairo.ttf`** | Mohamed Gaber, Accademia di Belle Arti di Urbino / Kief Type Foundry | SIL OFL 1.1 (name table of the bundled file) | Yes | Yes | Yes, with licence text | Yes (renaming constraints per OFL) | Include OFL text | PASS (confirm file matches Google Fonts source) |
| **`subfont.ttf` (Lateef)** | SIL International | OFL 1.1, Reserved Font Names "Lateef" and "SIL" | Yes | Yes | Yes, with licence text | Reserved names | Include OFL text | Unused; remove or document |
| **`backgruond.jpg`** | Rawpixel Ltd. (creator "rawpixel.com / katie") | Rawpixel licences: free-collection users get a *personal* licence (no commercial use, no redistribution of images); a Business licence needs a paid plan, one user, no re-distribution; public-domain items are CC0. Which licence applies to this file is unknown | ? | ? | ? | ? | Not mandatory | **P0: prove licence or replace** |
| **`adhan_dart` (future)** | package authors | MIT (listing, not re-verified at source) | — | — | — | — | Include licence | Verify at adoption |

Permission request to draft (needs the owner's go-ahead before sending anything): HadeethEnc — ask in writing whether
the app may cache responses locally for offline use, whether a bundled snapshot is allowed, how to track "version", and
the preferred attribution text.

---

## 8. Migration roadmap (effort assumes one engineer, existing app, no store submission)

| Phase | Scope | Effort | Depends on | Risk |
|---|---|---|---|---|
| 0 | This document; owner decisions | done / 0.5 d review | — | — |
| 1 Build stabilization | F-01…F-04, F-19, F-21 (after ids confirmed), F-23 (macOS) | 2-4 d | app id, platform scope, keystore owner | Med |
| 2 Core correctness | F-06…F-08, F-10…F-14, F-20, regression tests | 3-5 d | Phase 1 | Med |
| 3 Architecture foundation | split cubits, repositories, Result/Failure, states | 4-6 d | Phase 2 | Med |
| 4 Offline-first data | DB, sync, migrations | 5-8 d | **HadeethEnc written permission** | High |
| 5 Product quality | l10n, RTL, a11y, design system, perf, CI enforcement | 5-8 d | UX approval (see `UX_REDESIGN_PROPOSAL.md`) | Med |
| 6 New Islamic features | Quran, prayer times, notifications | per feature, separately scoped | per-source licences | High |

Ranges are estimates, not commitments; Phase 6 is deliberately not estimated as a whole. Notification work
(exact alarms on Android 13/14+, OEM battery limits, reboot rescheduling, iOS 64-pending cap) needs its own design
review first.

---

## 9. Definition of done and testing

Each phase closes only with a recorded table of PASS/FAIL/BLOCKED/NOT RUN for: dependency resolution, `dart format
--set-exit-if-changed`, `flutter analyze`, unit, widget, integration (where applicable), and platform builds, plus
licensing decisions, a rollback note (revert the phase branch), and the list of changed files with reasons.

| Phase | Acceptance (objective) |
|---|---|
| 1 | `analyze` 0 errors; `build apk --debug` and `--release` (with CI test keystore) PASS; manifest has `INTERNET`; release config does not reference the debug key; app id confirmed |
| 2 | Home grid shows exactly the `categories/roots` result; child navigation works; list never indexes past `data.length`; failure shows a retryable error; regression tests for each fixed finding |
| 3 | No widget imports Dio or DTOs; one cubit per concern; no duplicate request on navigation (fake-adapter call counts) |
| 4 | Content survives airplane mode; refresh does not duplicate rows; migrations tested up and down; blocked unless permission is on file |
| 5 | Localized strings only; RTL widget tests; contrast ≥ 4.5:1 for body text; text scale 2.0 without overflow; CI green |

Testing strategy: unit tests for parsing (`ar` and `en` fixtures), repositories, `Failure` mapping, paging math, tree
building, cubit transitions (`bloc_test`); widget tests with a fake repository for each state and RTL; an integration
test against a local fake HTTP adapter for the main flow; offline test = fetch → persist → fail network → reopen →
assert content; no test uses the live API.

---

## 10. CI/CD plan

GitHub Actions on pull requests: `pub get` → `dart format --set-exit-if-changed` → `flutter analyze` →
`flutter test --coverage` → `flutter build apk --debug` (Ubuntu; JDK 17). A separate macOS job builds iOS with
`--no-codesign`. Release workflow is manual (`workflow_dispatch`), reads the keystore from encrypted secrets, never
echoes them, and does **not** publish to any store. PRs from forks receive no secrets. Coverage target proposed: 80%
on domain/data/state code, no percentage gate on widgets.

---

## 11. Open questions (only owner decisions)

1. Final production application id / bundle id, and who owns the Play and Apple developer accounts?
2. Platforms: Android only, or Android + iOS? Is web a product target (it currently runs)?
3. Hadith languages: Arabic only, or Arabic + English (needs F-10 and a bilingual display decision)?
4. Background image: do you hold a Rawpixel licence covering app distribution? If not, may I replace it?
5. May I draft the HadeethEnc permission request for you to send?
6. Where is the signing keystore, and is it acceptable that CI never sees it until you add secrets?

## 12. Recommended next action

Create `phase-1/build-stabilization` and make the single commit that deletes the two lines at `lib/main.dart:48-49`
(F-01), then record `analyze`, `build web`, and the Android failure state on that branch. It is reversible, needs no
decision from you, and turns every later check from "cannot run" into a measurable baseline.
