# Phase 3 next steps: checklist (approved 2026-10-10)

Source: `docs/PHASE3_NEXT_PLAN.md`. The owner approved the plan without answering D1–D10, so the plan's defaults apply:

| ID | Decision in force |
|---|---|
| D1 | Quiet hours do not affect prayer reminders by default; an optional switch delivers prayer reminders silently in quiet hours (never deleted, never moved) |
| D2 | Quiet hours follow the device's local time |
| D3 | Salawat text is the approved Arabic in both interface languages until English is supplied; minutes use the ICU plural (دقائق for 3–10) |
| D4 | Salawat: interval within a daily window, off by default |
| D5 | Daily hadith fallback: rotate over the top-level categories; no curated list unless the owner supplies ids |
| D6 | Widget: own thin channel, no place name, live countdown only if the spike passes |
| D7 | Add the sura-name filter; `integration_test` runs locally, no CI emulator job |
| D8 | Keep exact alarms optional; add the build-time switch; the owner checks the Play Console declaration |
| D9 | Liquid Glass stays deferred |
| D10 | PR #8 retargeted to `master` (done 2026-10-10) |

Branches stack on `ui/g-luxury-revamp` (PR #10) so they get the new design system; Quran tests stack on `feature/p3e-quran-core`
(PR #8). One branch per step, one pull request per step, never merged without approval.

Status key: `[ ]` pending, `[~]` in progress, `[x]` done and verified.

## Step 1 — Live countdown (`feature/p3b-countdown`) — DONE
- [x] Pure helpers (`presentation/countdown_text.dart`): `H:MM:SS` in the user digits, rounded up so zero shows only at the time;
      words to the minute for screen readers; time to the next tick.
- [x] `PrayerCountdown` widget: value is always `nextAt - clock.now()`; ticks when the shown second changes; stops while the app is
      in the background, its section is hidden, or another page covers it; recomputes at once when seen again.
- [x] At zero the page recalculates once (guarded per prayer); when seen again it recalculates (covers midnight and clock changes).
- [x] Screen-reader label includes the time left in words, changing once a minute; not a live region; 200% text holds.
- [x] Tests: `test/features/prayer_times/countdown_test.dart` (helpers, ticking, clock change, zero once, hidden, background,
      covered page) and `test/app/countdown_flow_test.dart` (on the Prayer page, rollover from Asr to Maghrib, spoken label, 200%).

New strings for wording review: `countdownIn` ("in {time}" / "بعد {time}"), `durationHours`, `durationMinutes`, `durationJoin`,
`durationUnderAMinute` (Arabic uses the genitive after بعد: ساعة، ساعتين، ٣ ساعات، ١١ ساعة).

## Step 2 — Salawat reminders and quiet hours (`feature/p3d-salawat-quiet-hours`)
- [ ] Settings model for quiet hours (start, end, "apply to prayer reminders") and salawat (enabled, interval, window, lead).
- [ ] Planner: salawat candidates (priority below prayers, own horizon); quiet hours on device time; prayer reminders inside quiet
      hours delivered silently when the switch is on.
- [ ] Approved wording exactly; ICU plural for minutes; a test pins the approved strings.
- [ ] Reminders page: quiet-hours and salawat sections; "held back by quiet hours" summary.
- [ ] Tests: quiet-hours matrix (midnight, boundaries, empty window, DST), priorities, iOS cap, wording.

**Acceptance:** nothing deleted or moved silently; prayers never displaced by salawat; all checks green.

## Step 3 — Daily hadith (`feature/p3f-daily-hadith`)
- [ ] Migration 6: `opened_categories`, `daily_hadith`, `daily_hadith_history` (ids and dates only); upgrade test; Delete-all.
- [ ] Record opened categories (with a switch to stop remembering).
- [ ] Deterministic selector (day, opened set, history) with fallback to top-level categories.
- [ ] Home card behind the `dailyHadith` flag: category, reference when given, HadeethEnc credit; offline and empty states.
- [ ] Tests: determinism, stability within a day, no repeat in 60 days, fallback, offline, request count.

**Acceptance:** same hadith all day; no invented content; at most two requests a day; all checks green.

## Step 4 — Android home-screen widget (`feature/p3g-android-widget`)
- [ ] Spike: `Chronometer` count-down behaviour and digits on the emulator.
- [ ] Snapshot builder (Dart) and thin channel; Kotlin provider, layouts, receivers; receiver disabled unless the flag is on.
- [ ] Stale, no-place and tap-to-open states; Delete-all clears the snapshot.
- [ ] Kotlin unit tests plus a Gradle test step in CI; Dart snapshot tests.

**Acceptance:** widget shows the next prayer from the snapshot without the app running; never shows a passed prayer as next; no new
permission; all checks green.

## Step 5 — Quran tests and sura filter (`feature/p3e-quran-tests`, on PR #8)
- [ ] Normalisation rule tests, search behaviour tests, go-to-verse matrix over all 114 suras.
- [ ] Sura-name filter on the list (Arabic, English, number in either digit style) with tests.
- [ ] `integration_test` flows for local runs.

**Acceptance:** every documented rule has a test; filter works in both languages; all checks green.

## Research items (no code)
- Play exact alarm: findings in `docs/PHASE3_NEXT_PLAN.md` section 9; the owner checks Play Console.
- Adhan audio: unchanged (system sound or silent).
- Liquid Glass: deferred.
