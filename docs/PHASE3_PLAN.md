# Hadeeths — Phase 3 Product Expansion: Audit and Plan (for approval)

Status: **PLAN ONLY. No implementation has started.** Audit date: 2026-10-09 (the date used throughout this repo's docs).
Labels: CONFIRMED (verified directly), ASSUMPTION, PROPOSED, BLOCKED, NOT RUN, NOT APPLICABLE.
Official-source claims were fetched on 2026-10-09; where a page did not load or a source was third-party, it says so.

---

## 1. Executive summary

- The app is a healthy, small, well-tested base: feature-first Clean Architecture, `flutter_bloc`, `Navigator`, a read-through
  file cache, a design system, Arabic/English, CI. Phase 3 can be added as **new feature folders** without rewriting anything.
- Phase 3 adds seven large features. They are **not equally ready**:
  - **Ready to plan and build now:** prayer times, Qibla, reminders, tracker, salawat/tasbeeh, hadith improvements, native share sheet.
  - **Blocked on rights:** Quran Mushaf page layout, KFGQPC fonts, recitation audio, tafsir/translations, offline hadith bulk data.
  - **Blocked on tooling I do not have:** any iOS verification (this machine is Windows, no Xcode/simulator/iPhone), so Liquid Glass can
    only be *built and checked* in CI or by you on a Mac. Only an Android phone is available here.
- Three platform facts shape the design: iOS keeps 64 pending local notifications; Android exact alarms need a permission that is
  user-revocable (or a Play-policy-gated one); and home-screen widgets must be written natively.
- Liquid Glass is achievable on iOS 26+ for **bars and controls** through a small native boundary, with the existing Material/Flutter
  look as the fallback. Reading surfaces stay opaque. No Flutter widget fakes it and calls it native.

## 2. Repository evidence and baseline (CONFIRMED unless marked)

| Item | Evidence |
|---|---|
| Git | branch `master`, 2 commits ahead of `origin/master` (offline feature, **not pushed**); this plan is on the new local branch `docs/phase3-plan` |
| Flutter / Dart | Flutter 3.44.8 stable, Dart 3.12.2 (`flutter --version`); `pubspec.yaml` `sdk: ^3.12.2` |
| Analyzer | `flutter analyze`: "No issues found" (run 2026-10-09) |
| Tests | `flutter test`: 281 passed, exit 0 (run 2026-10-09) |
| CI | `gh run list`: CI on `8dcdfb0` (redesign branch) **success**; includes Android debug+release APK and macOS iOS no-codesign build. CI has **not** run on the unpushed offline commits (NOT RUN) |
| Local iOS build | NOT RUN, impossible here (Windows). No `ios/Podfile` exists (Flutter uses Swift Package Manager for plugins; plugin SwiftPM support is unchecked, ASSUMPTION) |
| Android build | built successfully in earlier phases on a real device; not re-run in this audit |
| Dependencies | `bloc`, `flutter_bloc 8.1.6`, `dio 5.11`, `equatable`, `intl`, `path_provider`, `share_plus 13.3`, `shared_preferences`, `cupertino_icons`; `flutter pub outdated`: 21 transitive/dev packages have newer incompatible versions, 3 direct constraints are older than resolvable (not a blocker) |
| Persistence | **No database.** `shared_preferences` (`lib/features/settings/data/settings_repository_impl.dart`) and a JSON file cache (`lib/core/cache/file_response_cache.dart`, 20 MB LRU) |
| Routing | plain `Navigator.of(context).push` (`lib/features/categories/presentation/category_navigation.dart`, `pages/home_page.dart`); no router package; no deep links; no bottom navigation |
| State / DI | `flutter_bloc` cubits; constructor injection + `RepositoryProvider` (`lib/app/app_dependencies.dart`) |
| Time | **No clock abstraction in feature code.** `CachedFetcher` takes an injectable `now` (`lib/core/cache/cached_fetcher.dart`); that is the only precedent |
| Permissions | Android manifest: only `INTERNET`. No location, notification, alarm, or boot permissions. iOS `Info.plist`: no usage strings, no background modes |
| iOS | deployment target **13.0** (`project.pbxproj`), bundle id **`com.example.mynewapp` (placeholder)**, `CFBundleName` `mynewapp`, no entitlements file, no native code beyond the Flutter `AppDelegate.swift` |
| Android | `applicationId com.hadeeths.eg`, namespace `com.example.mynewapp`, `minSdk = flutter.minSdkVersion` (value not read in this audit), release unsigned unless `android/key.properties` exists, Kotlin 2.3.20 |
| Localization | gen-l10n, `ar` template + `en`; layout directional; 200% text and a11y guideline tests |
| Notifications / location / sensors / audio / widgets | **none in the app today** |
| Docs found | `docs/PHASE0_REVISED_AUDIT.md`, `UX_REDESIGN_PROPOSAL.md`, `ARCHITECTURE.md`, `RELEASE.md`, `README.md`. A HadeethEnc permission-request draft exists only on the local branch `docs/hadeethenc-permission-request` |

### Reusable components (CONFIRMED)
`Result<T>`/`Failure` (`lib/core/result`, `lib/core/errors`), `CachedFetcher`/`FileResponseCache`, `SettingsCubit` + `AppSettings`,
design tokens and `AppTheme`, `AppTile`, `ExpandableSection`, `StateViews` (loading/skeleton/error/empty), `ContentWidth`, reading
text style + size control, `share_text.dart`, architecture-rule test, test support (`fake_backend`, `fake_server`, `test_app`).

### Gaps
No database, no scheduler, no permissions layer, no clock abstraction, no navigation shell (every feature is reached from Home), no
native bridge, no iOS verification, iOS identity unset, `versionCode` of the published app unknown.

## 3. Hadeeths API assessment (CONFIRMED from Phase 0 live checks and code)

Source HadeethEnc (hadeethenc.com). Ids and counts are strings; 493 Arabic categories (452 English); lists 20/page; search ≤100
results, ≥3 chars, no match returns `{"suggestions":…}`; no ETag/version; non-Arabic details lack `reference`/`words_meanings`.
Terms: online display allowed with credit; **caching/bulk copy unaddressed** (offline shipped by owner's decision, documented in
`docs/RELEASE.md`). Grading is shown only if the API supplies it; the app never derives grades. Stable identifier: the numeric `id`.
Daily hadith, favorites (ids only) and search-history features are compatible; **bulk download / bundled snapshot / offline search remain BLOCKED**.

## 4. Confirmed issues and blockers

1. **iOS cannot be verified here.** Needs a Mac, Xcode 26 and an iPhone/simulator (BLOCKED, owner-side).
2. iOS bundle id placeholder; Apple developer team/signing unknown (BLOCKED).
3. Quran font/layout rights unresolved (section 8).
4. HadeethEnc caching terms unresolved (owner accepted risk).
5. Notification, location, alarm and widget features all need new native config and **real-device testing** that CI cannot do.
6. Offline commits are unpushed, so CI has never validated them.

## 5. Proposed architecture and decision records

| ADR | Decision (PROPOSED) | Alternatives | Notes / risk |
|---|---|---|---|
| P3-1 State | keep `flutter_bloc` Cubits | Riverpod | no second framework (ADR-1 stays) |
| P3-2 DI | keep constructor injection; extend `AppDependencies` | get_it | the graph stays small; split into per-feature modules if it exceeds ~15 entries |
| P3-3 Navigation | keep `Navigator`; add a **shell** with 4 destinations: Hadiths, Quran, Prayer, More (settings/tracker/salawat). Add a router package only if deep links from notifications need it | go_router | notification taps need a stable route table; decide at 3A |
| P3-4 Persistence | keep `shared_preferences` for settings; add **one SQLite database** for user data (favorites, bookmarks, last-read, tracker, notification metadata). Quran text ships as a **separate read-only asset DB**. Package choice (drift vs sqflite vs sqlite3) **not yet decided** — pub.dev search tool failed, so no package facts verified (NOT RUN) | Isar/Hive (rejected: extra engines), only prefs (rejected for tracker queries) | migrations are versioned and tested; this is the single new storage dependency |
| P3-5 Time | `Clock` interface injected everywhere (`now()`, local zone); fake in tests. Date logic uses **local calendar dates** plus a stored IANA zone id | `DateTime.now()` | needed for DST/travel tests |
| P3-6 Scheduling | one `NotificationScheduler` in `lib/core/notifications` over `flutter_local_notifications` (22.3.1, BSD-3, needs Flutter ≥3.38.1) with a pure planner (`List<PlannedNotification>`) separate from the plugin; stable ids; rolling window (≤ ~50 on iOS, ~7 days on Android); reconcile on launch, resume, locale/timezone/settings change, boot | per-feature schedulers (rejected) | iOS keeps only 64 pending (plugin docs); Samsung reportedly caps alarms (plugin docs) |
| P3-7 Prayer maths | `adhan_dart` 2.0.1 (MIT, verified publisher farend.net, no runtime deps; methods incl. Umm al-Qura, MWL, Egyptian, Karachi, North America, Moonsighting…; Shafi/Hanafi; high-latitude rules) behind a `PrayerTimesCalculator` interface | own implementation | no Hijri support in it → separate decision; accuracy validated against references (section 9) |
| P3-8 Location | `geolocator` 14.1.1 (MIT, Baseflow) when-in-use only, plus manual city entry that needs no permission | none | store rounded coordinates (2 decimals ≈ 1 km) + zone id |
| P3-9 Qibla | own great-circle bearing function (unit-tested) + compass heading from a sensor package; `flutter_compass` 0.8.1 is **23 months old** (maintenance risk) so choose between it and `sensors_plus` magnetometer at 3B | – | numeric bearing fallback always shown |
| P3-10 Content delivery | Quran text as a bundled read-only DB with checksum and attribution; tafsir/audio **not bundled**, optional user-initiated downloads only after licences | – | – |
| P3-11 iOS native UI | small Swift boundary; **candidate** package `native_liquid_glass` 0.3.1 (MIT, 12 likes, *unverified uploader*, iOS-only, falls back to system styling below iOS 26, each widget is a platform view) vs own thin platform view. **Not accepted** until a spike on a Mac | Cupertino widgets (no official evidence they adopt Liquid Glass) | see section 12 |
| P3-12 Widgets | `home_widget` 0.10.0 (BSD-3, verified publisher) as data bridge; widgets themselves written in Kotlin (Glance/RemoteViews) and Swift (WidgetKit) | – | iOS needs App Group + a second Xcode target (Mac) |

### Update after approval (3A-2)
ADR P3-4 resolved: **`sqlite3` ^3.5.2** (MIT, verified publisher simonbinder.eu; bundles SQLite through build hooks, no
`sqlite3_flutter_libs`, no code generation). Checked: unit tests run in `flutter test`; the release APK contains
`libsqlite3.so` for arm64-v8a, armeabi-v7a and x86_64 (about 1.7 MB each compressed); opened and migrated on a Samsung SM A155F (Android 16).
iOS build NOT RUN here (CI macOS job will exercise it). Permissions facade: interface and flow only; the plugin-backed
implementations arrive with the features that use them, so no permission plugin was added yet.

## 6. Feature dependency map

```text
3A foundations (Clock, permissions, scheduler core, DB, nav shell, tokens)
   ├─> 3B prayer times ─┬─> 3C prayer reminders ─┬─> 3D tracker + salawat
   │                    │                         └─> 3G widgets (needs 3B)
   │                    └─> Qibla (parallel)
   ├─> 3F hadith improvements (needs DB, share) ──> 3G share cards
   └─> 3E Quran (needs DB; blocked on licences, can run in parallel with 3B–3D)
3H hardening last.  Social v2 backend: design document only.
```
Critical path: 3A → 3B → 3C → 3D. Parallel: Quran (once licences settle), hadith improvements, share cards, Liquid Glass spike.

## 7. Offline matrix (summary)

| Feature | Works offline after install | Needs setup/network | Stored locally |
|---|---|---|---|
| Prayer times, Qibla | yes, after a location is set (manual or GPS) | location once | settings, rounded location, zone |
| Reminders / salawat / tracker | yes (OS fires local notifications) | permission grant | settings, records |
| Quran text | yes (bundled) once licensed | none | read-only DB; bookmarks, last-read in user DB |
| Tafsir, audio | no | user-initiated downloads (BLOCKED) | separate files with checksum + resume |
| Hadith | only previously opened content (existing cache) | network | cache + favorite ids |
Corruption: DB open failure → rebuild user DB from backup export if present, else start empty with a visible notice; content DB
failure → checksum mismatch screen, never show unverified text. Downloads: `.part` files, ranged resume, SHA-256 check, cleanup on start.

## 8. Islamic content provenance and licensing matrix

| Asset | Source | Licence found | Redistribute | Offline | Attribution | Status |
|---|---|---|---|---|---|---|
| Quran Arabic text | Tanzil Project | CC BY 3.0; verbatim only, no changes; credit Tanzil; link tanzil.net; keep notice in copies/derived files; no commercial restriction stated (tanzil.net/docs/text_license, fetched 2026-10-09) | yes, verbatim | yes | required | **Usable**; specific edition/variant (Uthmani vs simple, with/without marks) to pick; checksum to record |
| Mushaf page layout / page images | KFGQPC / others | none found | – | – | – | **BLOCKED** |
| KFGQPC Hafs font | King Fahd Complex | conflicting: ScanCode lists proprietary, no reproduction/modification without written approval; marketplaces say non-commercial; no licence on the Complex page excerpt | – | – | – | **BLOCKED** (written permission) |
| Alternative Quran font | e.g. an OFL Naskh/Quran font | **not verified** — PROPOSED to check Amiri Quran (SIL OFL) at its source before use | – | – | – | **NOT RUN** |
| Translations, tafsir | per source; Tanzil translations noted non-commercial in a third-party summary | not verified at source | – | – | – | **BLOCKED** |
| Recitation audio | reciters / EveryAyah etc. | none published | – | – | – | **BLOCKED** |
| Hadith content | HadeethEnc | credit required; no modification; caching unaddressed | online yes | unclear | required (already shown) | **AUDIT REQUIRED / risk accepted by owner** |
| Cairo, Amiri fonts | OFL 1.1 | in repo `assets/licenses/` | yes | yes | OFL text bundled | PASS |
| Share-card imagery | none chosen | – | – | – | – | design with own vector shapes only (no stock) |
| Adhan / notification sounds | none chosen | – | – | – | – | **BLOCKED**: default system sounds only until a licensed/own-recorded sound is supplied |
Integrity tests (PROPOSED): 114 surahs, 6236 ayahs for the chosen edition, no duplicate/missing ids, per-surah ayah counts against a reference, juz/hizb boundary table check, SHA-256 of the asset, text identical to the Tanzil file, search normalization never touches stored text, attribution string present.

## 9. Prayer calculation validation plan

Reference sources must be **official/independent** and recorded with date before use; **I have not collected any expected values and will not invent them.** Plan: (1) pick 8–10 cities (equatorial, mid-latitude, southern hemisphere, a >48° winter and summer case, Makkah, Cairo, one DST city) from an authority per method (e.g. Umm al-Qura calendar for Makkah, Egyptian General Authority for Cairo) — to be sourced; (2) tolerance ±1 minute against the authority table, ±2 against any app; (3) test each method × Shafi/Hanafi; (4) date boundaries: midnight, year end, DST start/end days, user travelling across zones; (5) high-latitude rule outcomes checked for monotonic ordering (Fajr < Sunrise < Dhuhr < Asr < Maghrib < Isha). Hijri: `adhan_dart` does not provide it; PROPOSED to use a tested tabular Umm al-Qura implementation with a user ±2-day offset and a visible "may differ from moon sighting" note (package/algorithm not yet chosen, NOT RUN). Prayer-window **end** times: the calculator gives Sunrise, which is the commonly stated end of Fajr. Ends for the other prayers differ by opinion (for example Asr and Isha), so I will not invent them. **PROPOSED:** the "before the window ends" reminder is offered for Fajr only (until sunrise) and omitted for the others, pending your and a religious reviewer's decision.

## 10. Android / iOS capability matrix

| Capability | Android | iOS | Notes (source) |
|---|---|---|---|
| Local notifications | `POST_NOTIFICATIONS` runtime permission (API 33+) | authorization prompt | `flutter_local_notifications` 22.3.1 |
| Scheduling accuracy | exact via `SCHEDULE_EXACT_ALARM` (user-revocable, not pre-granted on new installs for API 33+) or `USE_EXACT_ALARM` (auto-granted, non-revocable, Play-policy gated; qualification for a prayer app **unverified**). Inexact fallback ± minutes | system-scheduled calendar/time triggers; minute-level | developer.android.com/develop/background-work/services/alarms |
| Pending limits | Samsung reportedly 500 (plugin docs) | **64** most recent (plugin docs) | rolling window |
| Reboot | alarms cleared; need `RECEIVE_BOOT_COMPLETED` receiver (plugin provides); only after first launch | OS keeps scheduled local notifications | AlarmManager docs |
| Timezone/clock change | needs re-plan on `TIMEZONE_CHANGED`/launch | re-plan on launch/resume | PROPOSED |
| Actions when app dead | background isolate handler possible | background isolate handler possible; both need entry-point setup | plugin docs; **device behaviour NOT RUN** → fallback: open tracker screen |
| Custom sound | channel sound (channels immutable after creation) | bundled sound file (length limits — unverified) | no licensed sound yet |
| Location | `ACCESS_COARSE/FINE`; Android 12+ approximate option | `NSLocationWhenInUseUsageDescription`; reduced accuracy since 14 | geolocator 14.1.1 |
| Compass | magnetometer; may be absent | Core Location heading | calibration prompts differ |
| Widgets | Glance/RemoteViews, OS-throttled refresh | WidgetKit timeline, budgeted refresh, App Group | never real-time |
| Share | share_plus (already used) | share_plus | images via temp files |
| Background execution | WorkManager/inexact | BGTaskScheduler best-effort | not relied upon |
| Liquid Glass | not applicable (Material 3) | iOS 26+ only; below: standard styling | section 12 |

## 11. Database and offline strategy (PROPOSED)

User DB tables: `favorites(hadith_id, lang, added_at)`, `quran_bookmarks(surah, ayah, added_at, content_version)`,
`reading_state(key, surah, ayah, content_version)`, `prayer_log(date_local, prayer, marked_at, tz_id)` (unique date+prayer; undo = delete row),
`reminder_plan(id, kind, fire_at_utc, tz_id, signature)` (for idempotent reconcile), `downloads(id, url, bytes, sha256, state)`.
Hadith favourites store **ids only** and re-fetch content (no copy of HadeethEnc text beyond the existing cache). Migrations: `PRAGMA
user_version`, tested upgrade paths from every released schema, nothing destructive. Retention: tracker data stays until the user
deletes it; "Delete all my data" in Settings clears DB, prefs and cache. Sensitive data: prayer log and location are private; no
analytics; excluded from logs; Android `allowBackup` decision at 3A (PROPOSED: exclude prayer log from cloud backup). Expected size: Quran text ≈ a few MB.

## 12. UX specification (summary; full wireframes are produced at 3A review)

**Navigation (PROPOSED):** bottom bar with Hadiths (existing Home), Quran, Prayer, More. Secondary: Search (in Hadiths), Favorites, Tracker, Salawat, Settings (existing), About. Notification taps deep-link to Prayer or Tracker. Back behaviour: standard.
**Screens:** Prayer dashboard (next prayer, countdown, 5 times, Hijri, location chip), Qibla, Location setup (rationale → GPS or manual), Prayer settings, Reminder settings (per prayer), Tracker (today + week), Salawat settings + Tasbeeh, Quran index, Reader (text mode), Quran search, Bookmarks, Downloads (disabled until licensed), Daily hadith card on Home, Favorites, Share-card preview, Social share sheet.
**States:** every screen has loading, empty, error, offline and permission-denied variants using `state_views.dart`.
**Tokens:** reuse `tokens.dart` (ivory/emerald/gold, dark green). New: prayer-state colours (current/next/past) with ≥4.5:1 contrast tests; no new fonts (Amiri/Cairo).
**RTL/a11y:** directional layout only; times shown in the user's digit setting (Western by default; Arabic-Indic digits is a decision); semantic labels with spoken times; tracker toggles with state announced; tasbeeh counter announces count; 200% text tests for every new screen.
**Copy:** neutral, never "you didn't pray". Salawat wording and all religious phrases **need your approved text**; I will not author religious quotations.

### Dedicated iOS Liquid Glass specification
- Verified: Apple's page *Adopting Liquid Glass* did not render through my fetch tool (only its title), so Apple-specific statements below rest on Apple Developer Forum threads and secondary articles and are **to be re-verified on a Mac**. Consistent points: apps built with the iOS 26 SDK get new system bars/tab bars/toolbars automatically; `UIDesignRequiresCompatibility` is a temporary app-wide opt-out that Apple signalled it will remove (reports about iOS 27 beta conflict); Reduce Transparency changes bar appearance; 26.1 added Clear/Tinted setting.
- Flutter: I found **no official statement** that `CupertinoTabBar` etc. adopt Liquid Glass; Flutter draws its own pixels, so native glass requires native views. Community packages wrap UIKit/SwiftUI (candidate: `native_liquid_glass` 0.3.1). Each is a platform view with per-screen cost; its page recommends 1–2 per screen; RTL is not documented.
- Hierarchy applied: (1) native UIKit controls via platform views for **tab bar, navigation/title bar, and one floating action cluster**; (2) Flutter Cupertino/Material for everything else; (3) no pseudo-glass in Flutter. Quran, hadith and prayer-time text stay on opaque theme surfaces. No glass cards, no stacked glass.
- Deployment target: stays **iOS 13.0** (no raise without your approval); Liquid Glass chosen at runtime by `#available(iOS 26)`; below that, the same native bars with system styling or the Flutter Material-adaptive bar. Raising the target (e.g., to 15/16) is a decision for you; it is **not required**.
- Verification (all BLOCKED here): simulator with iOS 26 and an older runtime, a real iPhone, screenshots of nav, sheets, Quran reader, hadith reader, prayer dashboard; Reduce Transparency, Increase Contrast, Dynamic Type max, VoiceOver, Arabic RTL, scroll-under-bar behaviour. Reports will separate simulator from device.
- **Spike first (no production changes):** a throwaway branch with the tab bar only, tested by you on a Mac/iPhone, before any ADR is accepted.

## 13. Privacy and permission flows (PROPOSED)

- Location: asked only when the user taps "Use my location" on the Prayer screen, after a one-screen explanation; when-in-use only; one-shot fix; manual city search needs no permission; denial shows manual entry; coordinates rounded to ~1 km, never logged, never shared.
- Notifications: asked when the user turns on the first reminder, not at launch; denied → settings deep link with explanation; the in-app state shows "reminders are off by the system".
- Exact alarms (Android): used only if you approve; flow explains and opens the system "Alarms & reminders" page; if not granted, fall back to inexact and say so in settings.
- Notification text never contains location or history. Tracker records local only. No analytics. Share cards never include tracker data, location or names. "Delete all my data".

## 14. Feature implementation roadmap

Each feature ends in a review checkpoint; one feature per branch.

| Phase | Scope | Non-goals | Key tests | Acceptance |
|---|---|---|---|---|
| 3A | `Clock`, permissions facade, DB layer + migration harness, scheduler core + planner (no UI), nav shell, new tokens | any feature UI | planner/dedupe/quiet-hours unit tests with fake clock; migration tests | analyze, tests, CI green; no behaviour change for existing screens |
| 3B | calculator wrapper, location (manual + GPS), settings, next-prayer, Qibla, dashboard, Hijri | reminders | reference-case tests (section 9), DST/midnight, bearing tests, permission-denied widget tests | matches references within tolerance; works with no GPS |
| 3C | per-prayer reminders, permission flows, boot/timezone reconcile, test notification | Adhan audio playback, custom sounds | scheduler tests; **device**: reboot, timezone change, exact-alarm off | no duplicates; ≤ platform limits; documented fallbacks |
| 3D | tracker, reminder stages (those validated), salawat intervals, quiet hours across midnight, tasbeeh | gamification, streaks | record/undo/day-boundary tests; action behaviour on device | privacy test: no network calls; copy reviewed |
| 3E | Quran text mode, index, jump, juz/hizb, bookmarks, last-read, search | Mushaf pages, tafsir, audio until licensed | integrity tests (section 8), restore position, search normalization | exact text match; survives restart |
| 3F | daily hadith (deterministic by local date + id list), favourites (ids), search history optional, text share improvements | bulk offline | determinism, favourites persistence, long-text sharing | no fabricated grading |
| 3G | native share sheet templates, share-card image (multi-page for long text), Android widget, iOS widget (needs Mac) | friends/FCM backend | golden tests, widget platform checks | cards legible, attribution present |
| 3H | a11y, RTL, performance, migrations, privacy/licence review, release checklist | – | full device matrix | checklist signed |
Social v2 (friends/FCM): a **separate design document** only, covering invitations, mutual opt-in, blocking, rate limits, deletion, security rules.

## 15. Test strategy and commands

Verified in this repo: `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, `flutter test --coverage`, `dart run tool/check_coverage.dart 80`, `bash tool/check_release_config.sh`, `flutter build apk --debug|--release`, CI `ios` job (`flutter build ios --no-codesign`). **Proposed (not existing):** `integration_test` for the 10 listed flows (needs a device/emulator job), golden tests for share cards, a notification-planner test suite, a migration-test suite. CI can run unit/widget/golden/APK/iOS-compile; **physical devices** are required for notifications, reboot, sound, compass, location, widgets, Liquid Glass, VoiceOver/TalkBack.

## 16. Risk register

| Risk | L | I | Mitigation | Owner |
|---|---|---|---|---|
| No Mac/iPhone for Liquid Glass and iOS notifications | H | H | you test on Mac; CI compile; spike first | product owner |
| Quran font/page rights unresolved | H | H | text mode with a font whose licence is verified; ask KFGQPC; no Mushaf mode until granted | owner / me |
| Play policy for exact alarms | M | H | use inexact + clear UX; ask Play only if exact needed | owner |
| iOS 64 notification limit | H | M | rolling window; planner tests | me |
| OEM battery killers on Android | H | M | in-app guidance, no promise of exact second | me |
| Prayer-time disagreements with local mosque | H | M | visible method/adjustments, disclaimer | me |
| Wrong religious wording | M | H | owner-approved text only, no invented quotes | owner |
| Compass package stale/inaccurate | M | M | numeric fallback, spike two options | me |
| Third-party glass package quality (unverified uploader, platform views) | M | M | spike; own thin native view if needed | me |
| HadeethEnc terms | M | H | already accepted by owner; keep switch/clear; consider sending the permission request | owner |
| DB migration bugs | L | H | versioned migrations + tests | me |
| Schedule slip from licensing waits | H | M | order work so unblocked features go first | me |

## 17. Effort estimates (engineer-days, one engineer, ranges; assume decisions below are answered)

| Phase | Engineering | UI/UX | Licensing / content | QA | Native iOS | Native Android |
|---|---|---|---|---|---|---|
| 3A | 6–10 | 2–3 | – | 2 | 1 | 1 |
| 3B | 8–12 | 3–4 | 1 (references) | 3 | 1 | – |
| 3C | 6–10 | 2 | – | 4 (devices) | 2 | 2–3 |
| 3D | 6–9 | 3 | 1 (wording) | 3 | 1 | 1 |
| 3E | 10–16 | 4–5 | 3–8 (waiting on third parties) | 4 | – | – |
| 3F | 5–8 | 3 | – | 2 | – | – |
| 3G | 6–10 | 3 | 1 | 3 | 3–5 (Mac needed) | 2–3 |
| 3H | 5–8 | 2 | 1 | 6 | 2 | 2 |
Liquid Glass spike + integration: 4–8 extra days (Mac needed). Total roughly **60–100 working days**; not a promise, mostly sensitive to licensing and device testing.

## 18. Definition of Done
As in your brief, section 22, applied per feature: documented scope/non-goals, licences verified, offline behaviour tested, RTL and a11y tested, permission-denied paths, platform limits documented, `format`/`analyze`/tests green, relevant builds, privacy review, migrations validated, no fabricated religious text, honest PASS/FAIL/BLOCKED/NOT RUN report.

## 19. Recommended first task (after approval)
**3A-1: `Clock` abstraction + pure notification-schedule planner (no plugin, no UI, no permissions).** Smallest valuable step: it
contains the riskiest logic (rolling windows, quiet hours across midnight, DST, dedupe ids, 64-limit trimming), is fully testable in
CI, changes no behaviour, and every later feature depends on it. Files (proposed): `lib/core/time/clock.dart`,
`lib/core/notifications/planner.dart` + tests. Acceptance: tests for midnight-crossing quiet hours, DST day, id stability,
idempotent re-plan, window cap; analyzer clean; existing 281 tests still pass.

## 20. Open product-owner decisions
1. Approve the plan and the 3A–3H order, and the branch name scheme `feature/p3a-...`.
2. Push the unpushed offline commits first (CI never ran on them)?
3. iOS: will you ship it, what bundle id, who tests on a Mac/iPhone? Without that, Liquid Glass stays "implemented but unverified".
4. Android exact alarms: accept inexact-by-default (recommended), or pursue exact (permission + Play justification)?
5. Quran: text mode only first (Tanzil, verified) — OK? Which Tanzil edition (Uthmani with full marks)? Will you contact KFGQPC for font/page rights?
6. Approved Arabic wording for salawat and reminder messages (I will not invent religious text), and allowed tone/dialect (Egyptian examples in your brief?).
7. Prayer methods offered, default per region, Hijri adjustment policy, Arabic-Indic digits.
8. Adhan sound: use system sound only, or supply a licensed/own recording?
9. Whether tafsir/audio are in scope at all this phase (currently BLOCKED).
10. Permission to spike a native glass tab bar (new dependency evaluation) once a Mac is available.
11. Published `versionCode`, keystore and secrets (needed for release, unchanged from before).

## 21. Approval checkpoint
No implementation, dependency, native configuration or schema change has been made. Please approve (all, or amend) before
Stage 3 begins. Until then this branch contains only this document.

## Sources (accessed 2026-10-09)
adhan_dart https://pub.dev/packages/adhan_dart · flutter_local_notifications https://pub.dev/packages/flutter_local_notifications ·
geolocator https://pub.dev/packages/geolocator · flutter_compass https://pub.dev/packages/flutter_compass ·
timezone https://pub.dev/packages/timezone · home_widget https://pub.dev/packages/home_widget ·
native_liquid_glass https://pub.dev/packages/native_liquid_glass · Android alarms https://developer.android.com/develop/background-work/services/alarms ·
Tanzil licence https://tanzil.net/docs/text_license · Apple Adopting Liquid Glass https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass (body not retrievable) ·
Apple forum UIDesignRequiresCompatibility https://developer.apple.com/forums/thread/802419 ·
KFGQPC licence listing https://scancode-licensedb.aboutcode.org/kfgqpc-uthmanic-script-hafs.html
