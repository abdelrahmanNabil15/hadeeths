# PROGRESS — Luxury UI/UX revamp

Branch: `ui/g-luxury-revamp` (local only, from `origin/master` 0decdf7). **Not pushed.** No merge, no release.
Approved plan: owner version of 2026-10-10 (copy in `C:\Users\EXPRESS\.claude\plans\proud-mixing-sedgewick.md`).
Owner rules: no co-author trailer; no push or merge without approval; never push `master` or `feature/p3c-reminders`; no new
dependency or font file; no change to religious text, business logic, APIs, persistence, flags or navigation behaviour.

## Objective
A "quiet luxury" revamp of the single Flutter app: midnight emerald, warm ivory, charcoal, muted gold (sparingly) and soft sage;
editorial Arabic and Latin type (Amiri display, Cairo UI); subtle eight-fold star geometry; one cohesive design system; light and
dark both designed; accessibility, RTL and 200% text preserved.

## Status: all planned stages done; waiting for owner review
| Stage | Status | Main commits |
|---|---|---|
| 0 Baseline | DONE: format, analyze PASS; 1,011 tests PASS; coverage 90.8%; release config OK; before screenshots | 0ee4bed, 5bdc4b4 |
| 1 Foundation (palette, roles, tokens, type, component themes) | DONE | 451f363 |
| 2 Shared components (AppCard, pattern, ornament, options sheet, icons, medallion) and refactors | DONE | 0918418 |
| 3 Core: home header, nav bar, hadith page, search | DONE | d525a6b, c7edcef, 7a09a86 |
| 4 Coverage: prayer panel, More, tasbeeh token, location setup; all other screens via shared components and themes | DONE | e8580ac, 2a314b2 |
| 5 Polish: slider theme, tablet check, released-mode check, press-feedback decision kept | DONE | 57dfaf4, 3ac8c87, 4fb99d2, 5826d23 |
| 6 Validation | DONE (see below) | |
| 7 Docs and report | DONE: `docs/ARCHITECTURE.md` ("Luxury revamp"), `docs/UI_MODERNIZATION_PLAN.md` section 30 | 30747d0 |

Full commit list: `git log --oneline origin/master..ui/g-luxury-revamp`.

## Verification (last run 2026-10-10, all on this branch)
| Check | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed .` | PASS |
| `flutter analyze` | PASS, no issues |
| `flutter test --coverage` | PASS, 1,042 tests |
| `dart run tool/check_coverage.dart 80` | PASS, 90.8% |
| `bash tool/check_release_config.sh` | PASS |
| `flutter build apk --debug --dart-define=HADEETHS_PREVIEW_SECTIONS=true` | PASS |
| `flutter build apk --release` | PASS (62.1 MB, unsigned) |
| Emulator (emulator-5554, live API): home, category, hadith page, Settings, More; English light and Arabic dark | PASS (screenshots reviewed; the emulator was restored to light mode and device language) |
| iOS build or run, VoiceOver, TalkBack, profile frame timing, Samsung phone | NOT RUN (no Mac or phone; CI not triggered because nothing is pushed) |

Screenshots: `flutter test test_screens/screens_test.dart --dart-define=SHOTS=<name>` writes to `build/screens/<name>/`.
Sets on disk: `before`, `final` (plus intermediate stages). Before/after page: `build/revamp_review.html` (the `before` search
shot shows the loading state because the old harness did not wait; fixed since).

## Decisions taken
- Flutter only: the brief's SwiftUI, Compose and KMP parts do not apply (none exist). The design system in
  `lib/core/design_system` was evolved, not replaced.
- Amiri is the editorial face (already bundled). Its Latin glyphs render well on the emulator. Hadith titles use the regular weight,
  because they can be a whole sentence.
- Icons that tests find by glyph (search, share, check, status) were kept. Only the chevron changed, to `chevron_right_rounded`,
  which mirrors in RTL; `test/app/localization_test.dart` was updated for it.
- The navigation bar now sits on the card colour with a brand-coloured selected label; the accessibility contrast pair was updated
  to match (still 4.5:1).
- Home loading, error and empty states use a compact header, so the message and retry stay visible at 200% text on 360x640. The
  empty state scrolls when space is short.
- Press feedback stays off on the released home tiles (owner decision from UI Phase F). More already had it, behind the flag.
- Skeletons stay static; no repeating animations.
- No new user-facing strings.

## Remaining / next steps (need the owner)
1. Review the look (`build/revamp_review.html`, or run the app with `--dart-define=HADEETHS_PREVIEW_SECTIONS=true`).
2. Approve a push of `ui/g-luxury-revamp` so CI runs (including the macOS iOS compile) and a pull request can be opened.
3. After approval, extend `.claude/skills/hadeeths-ui-modernization/SKILL.md` with the new tokens and components (not done:
   it needs approval).
4. Quran screens (PR #8) inherit the shared components; review them once PR #8 is merged. PR #8's base branch also needs to be
   changed to `master` (PR #7 was merged).
5. Device checks: Samsung phone (TalkBack, frame timing), iPhone (VoiceOver, platform transitions).
6. Separate, still waiting for approval: `docs/PHASE3_NEXT_PLAN.md` on the local branch `docs/phase3-next-plan` (countdown, salawat
   and quiet hours, daily hadith, Android widget, Quran tests).

## Known issues
- In the test renderer `BoxShadow` blur draws as a hard band; on a device it is soft (checked). Screenshots from the harness
  therefore show a heavier shadow than the app does.
- On the emulator the preview build's More page showed only Settings and About. Cause (confirmed in logcat): the emulator's user
  database is at schema 5 from an earlier Quran-branch build, and this branch supports schema 4, so it refuses the database
  (`DatabaseTooNewException`) and the tracker, counter and favourites stay hidden. This is the designed safe behaviour and an emulator
  state, not a revamp issue. To see those pages here, clear the app's data on the emulator (that deletes its local data).
