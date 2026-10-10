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

## Step 2 — Salawat reminders and quiet hours (`feature/p3d-salawat-quiet-hours`) — DONE
- [x] Settings: `SalawatSettings` (interval 1/2/3/4/6 h, window, optional earlier reminder 5/10/15 min, off by default) and quiet
      hours (on/off, start, end, "prayer reminders arrive silently") inside `ReminderSettings`; saved with the reminders; older saved
      data and damaged entries load as off.
- [x] Planner: salawat candidates for today and tomorrow on the phone's clock (priority 5, below prayers at 10; DST-safe);
      quiet hours judged on the phone's clock (`quietZone`); prayer reminders never dropped or moved; with the switch on, a prayer
      reminder in quiet hours is delivered without sound or vibration.
- [x] Wording: the approved Arabic exactly (`presentation/salawat_wording.dart`, pinned by a test), in both interface languages;
      دقائق after 3 to 10 (D3).
- [x] Coordinator: salawat needs no place; everything off cancels everything; the status counts reminders held back by quiet
      hours, and the prayer summary counts prayer reminders only.
- [x] Screens: "More reminders" on the Reminders page with Salawat and Quiet hours rows (on/off shown); Salawat page (switch with the
      notification-permission flow, approved-text preview, interval, window with a start-before-end check, earlier reminder);
      Quiet hours page (switch, window, held-back count, silent-prayers switch).
- [x] Tests: `test/features/prayer_times/salawat_quiet_hours_test.dart` (wording, settings, saving, planning, DST, quiet hours on the
      phone clock, coordinator) and `test/app/salawat_quiet_flow_test.dart` (pages, scheduling, time picker, held-back count,
      200% text and tap-target/label guidelines in both languages).
- [x] Fix found on the way: the reminders screen state ignored some status fields when comparing, so a change in exact-alarm
      permission alone did not redraw the warning; those fields are now compared.

New strings for wording review: `remindersMore`, `statusOn`, `statusOff`, `salawatTitle` (تذكيرات الصلاة على النبي ﷺ), `salawatSwitch`,
`salawatIntro`, `salawatPreview`, `salawatInterval`, `salawatEveryHours`, `salawatWindow`, `timeFrom`, `timeTo`, `salawatLeadNone`,
`windowInvalid`, `quietTitle`, `quietSwitch`, `quietIntro`, `quietPrayersSilent`, `quietHeldBack`.
Device checks NOT RUN: delivery timing, silent delivery on Android channels, reboot, Doze, time-zone change.

## Step 3 — Daily hadith (`feature/p3f-daily-hadith`) — DONE
- [x] Storage: **deviation from the plan.** Shared preferences (`PrefsDailyHadithStore`, one JSON entry) instead of migration 6.
      The data is tiny (50 category ids, two days of picks, 60 days of ids), and a migration here would collide with the Quran
      section's migration 5 on the unmerged PR #8. Ids, page numbers and dates only, no source text. Delete-all clears it.
- [x] Opened categories recorded when a category's hadith list opens (only with the section on and remembering on); Settings switch
      "Choose from the categories I open" (off also forgets).
- [x] Deterministic selection (`domain/daily_selection.dart`, `DailyHadithService`): phone's local date; categories rotate by day,
      yesterday's not repeated; position by a stable hash; last 60 days skipped (neighbours on the same page first); the day's pick
      saved, so it does not change during the day; fallback to the top-level categories; empty categories skipped; at most two list
      requests, both through the existing cache.
- [x] Home section behind the new `dailyHadith` flag: title as given, "From: category", HadeethEnc credit; tap opens the hadith
      page with its text and reference; loading placeholder; "cannot be shown right now" with Retry; hidden when there is nothing to
      choose from.
- [x] Tests: `test/features/daily_hadith/daily_hadith_test.dart` (rules, store, service) and `test/app/daily_hadith_flow_test.dart`
      (home, open, remember, flag off, failure and retry, empty, settings switch, Delete-all, 200% text and guidelines in both
      languages).

New strings for wording review: `dailyHadithHeading` (حديث اليوم), `dailyHadithFrom`, `dailyHadithUnavailable`,
`dailyHadithRemember`, `dailyHadithRememberHint`.

## Step 4 — Android home-screen widget (`feature/p3g-android-widget`)
- [ ] Spike: `Chronometer` count-down behaviour and digits on the emulator.
- [ ] Snapshot builder (Dart) and thin channel; Kotlin provider, layouts, receivers; receiver disabled unless the flag is on.
- [ ] Stale, no-place and tap-to-open states; Delete-all clears the snapshot.
- [ ] Kotlin unit tests plus a Gradle test step in CI; Dart snapshot tests.

**Acceptance:** widget shows the next prayer from the snapshot without the app running; never shows a passed prayer as next; no new
permission; all checks green.

## Step 5 — Quran tests and sura filter (`feature/p3e-quran-tests`, stacked on PR #8) — DONE
- [x] Normalisation: one test per documented rule (marks, dagger alef, Quranic marks, tatweel, alef forms, alef maqsura, ta marbuta,
      hamza kept, Latin case and spaces, marks-only query).
- [x] Search over the real file: first and last verse found by their own text, plain and marked forms agree, Mushaf order and limit,
      verses returned unchanged, short queries refused, a time bound for regressions.
- [x] Go to a verse: `checkGoTo` checked over all 114 suras with the real data (first, last, last + 1, zero, empty verse), suras
      outside 1–114 refused. **Bug fixed:** digits typed on an Arabic or Persian keyboard were rejected; they are accepted now.
- [x] Sura filter on the list (`filterSuras`): number in either digit style, Arabic name without marks or the article, English name
      ignoring case, article, apostrophes and hyphens; every sura is found by its own names; "No sura matches."; clear button.
- [x] Widget tests (`test/app/quran_lookup_flow_test.dart`) and an on-device flow (`integration_test/quran_test.dart`, dev
      dependency `integration_test` from the SDK): PASS on the Android emulator (emulator-5554). Not in CI (D7).

New strings for wording review: `quranFilterHint`, `quranFilterNone`.

## Research items (no code)
- Play exact alarm: findings in `docs/PHASE3_NEXT_PLAN.md` section 9; the owner checks Play Console.
- Adhan audio: unchanged (system sound or silent).
- Liquid Glass: deferred.
