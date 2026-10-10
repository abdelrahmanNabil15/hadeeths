# UI revamp audit — every screen, dialog, sheet and state

Audited 2026-10-10 on branch `ui/h-revamp-coverage` = `ui/g-luxury-revamp` (PR #10) + `master` (includes the Quran section from
PR #8). Phase 3 screens that live only on their own PRs (#11–#15) are listed separately.

**Method (code first, then images):**
- Every `Scaffold`, pushed page, private page class, `showDialog`, `showModalBottomSheet`, `showOptionsSheet`, `showTimePicker` and
  `SnackBar` in `lib/` was listed with `grep`.
- Each UI file was scanned for markers of the old design: hand-built decorations (`BoxDecoration`, `Material` with a shape), inline
  styles, theme overrides. Each file was also checked for use of the shared components (`AppCard`, `AppTile`, `OptionGroup`,
  `SwitchRow`, `SectionHeading`, `StateViews`, `StatusBanner`, `showOptionsSheet`, `OrnamentDivider`).
- Every reachable screen, dialog and sheet was rendered with fake data and the real fonts in Arabic and English, light and dark
  (`flutter test test_screens/screens_test.dart --dart-define=SHOTS=audit`, images in `build/screens/audit/`). The main ones were
  also checked on the Android emulator with live data.
- Native launch screens were read from `android/app/src/main/res` and `ios/Runner/Base.lproj`.

Status key: **Revamped** = all visible parts use the new tokens and components and look right in the images; **Partially** = some
parts still old; **Not revamped** = old design; **Needs verification** = built on the new system but not yet seen.

## Summary

| Status | Count |
|---|---|
| Revamped | 39 |
| Partially revamped | 1 |
| Not revamped | 0 |
| Needs verification | 10 |
| **Total** | **50** |

## 1. Full screens

| # | Screen (class) | How it is reached | Module | Status | Still to do | Priority |
|---|---|---|---|---|---|---|
| S1 | Bottom navigation (`AppShell`) | root when any section flag is on | app/shell | Revamped | — | — |
| S2 | Home, released build (`HomePage`, `inShell: false`) | root with all flags off | categories | Revamped | — | — |
| S3 | Home in the shell (`HomePage`, `inShell: true`) | Hadiths tab | categories | Revamped | — | — |
| S4 | Category (`CategoryPage`) | `openCategory` for a category with children | categories | Revamped | — | — |
| S5 | Hadith list (`HadithListPage`) | `openCategory` on a leaf, "All hadiths" | hadiths | Revamped | load-more failure footer is plain text and a text button (could use `StatusBanner`) | Low |
| S6 | Hadith details (`HadithDetailsPage`) | a hadith in a list, search, favourites | hadiths | Revamped | — | — |
| S7 | Share as image (`ShareCardPage`) | details → Share → As image | hadiths | Partially | page chrome is new; **the generated card image keeps the old look** (square frame, accent bar) | Medium — blocked: changing the shared image needs owner approval |
| S8 | Search (`SearchPage`) | home search field | search | Revamped | — | — |
| S9 | Quran index (`QuranPage`) | Quran tab | quran | Revamped | — | — |
| S10 | Sura reader (`SuraReaderPage`) | a sura, continue reading, go to verse, a result | quran | Partially | verse numbers are grey outlined circles from before the revamp; no sura header (editorial title, ornament); bookmark mark is a plain icon | **High** |
| S11 | Quran search (`QuranSearchPage`) | Quran → Search | quran | Partially | result card `VerseResultTile` is a hand-built copy of `AppCard`; the field overrides the theme's border; no prompt before typing (blank page) | **High** |
| S12 | Quran bookmarks (`QuranBookmarksPage`) | Quran → Bookmarks | quran | Partially | same `VerseResultTile` as S11; empty state is new | High |
| S13 | Prayer times (`PrayerPage`) | Prayer tab | prayer_times | Revamped | time rows are a hand-built `AnimatedContainer` card on tokens (consolidation only, looks right) | Low |
| S14 | Prayer setup (`PrayerSetupView`) | Prayer tab with no place | prayer_times | Partially | the location-problem message is a hand-built box, not `StatusBanner` | Low |
| S15 | Change location (`_ChangeLocationPage`) | Prayer → Change location | prayer_times | Partially | same view as S14 | Low |
| S16 | City picker (`CityPickerPage`) | setup → Choose a city | prayer_times | Revamped | field repeats the theme's border in code (no visible difference) | Low |
| S17 | Calculation method (`MethodPage`) | Prayer → method tile | prayer_times | Revamped | — | — |
| S18 | Hijri date (`HijriPage`) | Prayer → Hijri date | prayer_times | Revamped | — | — |
| S19 | Qibla (`QiblaPage`) | Prayer → Qibla | prayer_times | Partially | the compass dial is a plain outlined circle and needle with inline text styles; no gold Kaaba mark or medallion centre | Medium |
| S20 | Reminders (`RemindersPage`) | Prayer → Reminders | prayer_times | Revamped | — | — |
| S21 | More (`MorePage`) | More tab | app/shell | Revamped | — | — |
| S22 | Favourites (`FavoritesPage`) | More → Favourites | favorites | Revamped | — | — |
| S23 | Prayer tracker (`TrackerPage`) | More → Prayer tracker | tracker | Revamped | day chips are a hand-built `AnimatedContainer` on tokens (consolidation only) | Low |
| S24 | Tasbeeh (`TasbeehPage`) | More → Tasbeeh | tasbeeh | Revamped | — | — |
| S25 | Settings (`SettingsPage`) | More → Settings, home gear (released) | settings | Revamped | — | — |
| S26 | Sources and rights (`AboutPage`) | More, Settings, home link (released) | settings | Revamped | — | — |
| S27 | Coming soon (`ComingSoonPage`) | only if a section's services are missing; **not reachable in production builds** | app/shell | Revamped | — | — |
| S28 | Android launch screen (`launch_background.xml`) | every cold start | android | **Not revamped** | plain white (Flutter template), also in dark mode: a white flash before the ivory or charcoal app | Medium |
| S29 | iOS launch screen (`LaunchScreen.storyboard`) | every cold start | ios | **Not revamped** | white with the template image; needs a Mac to verify | Medium — verification needs a Mac |

## 2. Dialogs, sheets, pickers and messages

| # | Element | Where | Status | Still to do | Priority |
|---|---|---|---|---|---|
| D1 | Share choice sheet (`showOptionsSheet`) | hadith details | Revamped | — | — |
| D2 | Text size sheet (`ReadingSizeButton`) | hadith details | Revamped | — | — |
| D3 | Go to a verse dialog (`_GoToVerseDialog`) | Quran index | Revamped | — | — |
| D4 | Verse actions sheet | sura reader, long press | Partially | a bare `ListTile` in a sheet: no title; should be `showOptionsSheet` | **High** (with S10) |
| D5 | "Use your location?" dialog | prayer setup | Revamped | — | — |
| D6 | Reminders permission dialog | Reminders switch | Revamped | — | — |
| D7 | Exact-timing explanation dialog | Reminders, Android only | Needs verification | not captured (same themed `AlertDialog` as D5/D6) | Low |
| D8 | Delete all my data dialog | Settings | Revamped | — | — |
| D9 | Clear favourites dialog | Favourites | Revamped | — | — |
| D10 | Reset counter dialog | Tasbeeh | Revamped | — | — |
| D11 | Delete tracker history dialog | Tracker | Needs verification | not captured (same themed `AlertDialog`) | Low |
| D12 | Time picker | salawat window, quiet hours (PR #12) | Needs verification | system Material picker under the app theme; not captured | Low |
| D13 | Snack bars (refresh failed, copies cleared, data deleted) | several | Revamped | — | — |

## 3. Shared states

| # | Element | Status | Evidence |
|---|---|---|---|
| T1 | Loading skeleton, error, empty and offline views (`StateViews`, `StateMedallion`) used by every screen | Revamped | component tests; seen in Quran bookmarks (empty), prayer setup (medallion), home compact header at 200% text |

## 4. Phase 3 screens (on their own PRs)

| # | Element | PR | Status | Note |
|---|---|---|---|---|
| P1 | Countdown on the next-prayer panel | #11 | Needs verification | widget tests pass; not yet captured in images |
| P2 | Salawat page | #12 | Needs verification | built only from shared components; tests pass |
| P3 | Quiet hours page | #12 | Needs verification | as P2 |
| P4 | "More reminders" rows on Reminders | #12 | Needs verification | `AppTile` with leading icons |
| P5 | Hadith of the day card and its Settings switch | #13 | Needs verification | `AppCard` raised on the reading surface, `OrnamentDivider` |
| P6 | Sura filter field on the Quran index | #15 | Needs verification | themed `TextField` |
| P7 | Android next-prayer widget | #14 | Revamped | hero colours, day and night; seen on the emulator |

## 5. Not fully revamped, in priority order

1. **High:** S10 Sura reader and D4 Verse actions sheet. This is the core Quran reading journey.
2. **High:** S11 Quran search and S12 Quran bookmarks. Both use the shared `VerseResultTile`.
3. **Medium:** S28 Android launch screen and S29 iOS launch screen. The white flash shows on every cold start, and in dark mode.
4. **Medium:** S19 Qibla compass dial.
5. **Medium, blocked:** S7 share-card image (owner approval needed to change the shared image).
6. **Low:** S14 and S15 (location-problem message), S5 (load-more failure footer).
7. **Verification:** D7, D11, D12, P1–P6.

## 6. Shared components to consolidate

- `VerseResultTile` (quran) → build on `AppCard`.
- Verse-number marker in the reader → one shared marker (an eight-pointed star outline in the gold role with the number), drawn by the
  existing `eightPointStar` path.
- Prayer time rows (`_TimeRow`) and tracker day chips → both hand-build a selectable card; candidate for an `AppCard(selected:)`
  variant. Low priority: they already look right.
- Location-problem box in `PrayerSetupView` → `StatusBanner`.
- Text fields that repeat the theme's border (`CityPickerPage`, `QuranSearchPage`) → rely on `inputDecorationTheme`.

## 7. Migration order (least duplicated work, least risk)

1. Quran shared pieces first: `VerseResultTile` on `AppCard`, and a shared verse marker. This fixes S11 and S12 together.
2. Sura reader (S10) with its sheet (D4), reusing the marker from step 1.
3. Launch screens (S28 Android now; S29 iOS prepared, verified on a Mac).
4. Qibla dial (S19), keeping its existing tests.
5. Low items (S14, S15, S5) and the consolidation items in section 6.
6. Capture D7, D11, D12 and P1–P6 in the screenshot harness on their branches.
7. S7 only after the owner approves changing the shared image.

## Progress log

- 2026-10-10: audit written (this file).
- 2026-10-10, same day, on `ui/h-revamp-coverage` (local, not pushed):
  - **Now Revamped:** S10 Sura reader (gold star verse markers, editorial sura header with ornament; fixed: header kept the app's
    text direction); D4 verse sheet (shared options sheet, titled); S11 and S12 (`VerseResultTile` on `AppCard`, field on the theme,
    prompt before typing); S19 Qibla dial; S14 and S15 (`StatusBanner`); S5 footer (`StatusBanner`); S28 Android launch (ivory, or
    charcoal in dark mode, including the Android 12+ splash; seen on the emulator).
  - **S29 iOS launch:** storyboard and a light/dark named colour done; it moves to *Needs verification* (needs a Mac).
  - **Still open:** S7 share-card image (needs owner approval); D7 and D11 (the harness can open the screens but not yet tap these
    two buttons); D12; P1–P6 on their PRs. The Android app icon is not adaptive (the system draws it on a white disc on the
    splash): owner artwork needed.
  - Checks: format, analyze PASS; `flutter test` 1,095 PASS; Qibla tests 35 PASS; harness captures in `build/screens/final/`.
- 2026-10-10, on `ui/i-mushaf-reader` (local, not pushed): the sura reader now looks like a mushaf page. The verses flow as one
  justified paragraph (not one block per verse), each ending with its number in a gold rosette; the page has a broad pale-gold
  frame with corner stars; a framed banner ("Surah ..." / "سورة ...") and the opening line sit at the top. The verse text is
  unchanged: the opening line is split off only when the file's own first verse (1:1) is its exact prefix. New string:
  `quranSuraTitle` (needs the owner's wording review). Not done (needs data the app does not have): mushaf page numbers and
  juz/hizb header strips.
