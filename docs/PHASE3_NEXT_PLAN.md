# Hadeeths — Phase 3 Next Steps: Consolidated Plan (for approval)

Status: **PLAN ONLY. Nothing in this plan has been implemented.** No application code, asset, dependency, configuration or skill file
has been changed. This document is the only change, on the local branch `docs/phase3-next-plan` (not pushed).
Date: 2026-10-10. Labels: CONFIRMED (checked directly), PROPOSED, ASSUMPTION, NOT VERIFIED, NOT RUN.

Inputs: the owner's "Phase 3 Decisions" message of 2026-10-10 (seven numbered decisions), the current code on `origin/master`
(0decdf7, which already contains PRs #6, #7 and #9), and two official pages fetched on 2026-10-10 (section 8).

## 1. Decisions register

| # | Owner decision | Where it lands in this plan |
|---|---|---|
| 1 | Plan (do not build) the prayer countdown, the Android next-prayer widget, and more Quran tests | Sections 4, 6, 7 |
| 2 | Salawat reminders with the approved Arabic wording; quiet hours that cross midnight and never silently delete or shift prayer reminders | Section 5 |
| 3 | Daily hadith rotates through categories the user has opened; deterministic per day; no needless repeats; shows source; fallback for new users | Section 8a |
| 4 | Google Play exact alarm: research only, no compliance claim until verified | Section 9 |
| 5 | Adhan: device notification sound or silent; no custom recordings until rights are verified | Section 10 |
| 6 | Liquid Glass: confirm Mac availability and whether native would materially help, before any spike | Section 11 |
| 7 | Approval gates: no code, assets, dependencies, configuration or skill changes before explicit approval; do not push `feature/p3c-reminders` or `master` | Section 14 |

Approved wording (stored verbatim, not edited by me):

- At the scheduled time: `حان وقت الصلاة على النبي ﷺ`
- Optional lead reminder: `الصلاة على النبي ﷺ بعد {عدد الدقائق} دقيقة`

## 2. Where the code stands (CONFIRMED)

- Prayer page: `lib/features/prayer_times/presentation/pages/prayer_page.dart` shows a static "next prayer" banner. `PrayerMoment`
  (`domain/prayer_moment.dart`) already has `next`, `nextAt` (UTC) and `remaining(now)`. `PrayerCubit` builds the moment once per load or
  refresh with the injected clock. Nothing ticks.
- Reminders: `NotificationPlanner` (pure) already has quiet hours (`QuietHours`, crossing midnight, start inclusive, end exclusive),
  per-candidate `respectsQuietHours`, priorities, a 60-item cap and `NotificationKind.salawat`. `ReminderPlanBuilder` marks prayer
  candidates `respectsQuietHours: false`. There is no UI or storage for quiet hours or salawat yet.
- Wording: prayer reminders already use ICU plurals in Arabic (`few` gives دقائق, `many` and `other` give دقيقة).
- Android: no widget code. One Kotlin file (`MainActivity.kt`), launch mode `singleTop`. Manifest has `SCHEDULE_EXACT_ALARM` and
  `RECEIVE_BOOT_COMPLETED` (merged debug manifest checked; the merged release manifest was not inspected: NOT RUN).
- Quran: the sura list offers verse search and go to verse. **It has no filter by sura name**, so "sura-list search" is either tests for
  what exists or a small new feature (decision D7).
- Hadiths: nothing records which categories a user has opened. Daily hadith needs a small new table.
- Schema is at version 5.

## 3. Order, branches and shared rules

Order (smallest and most independent first): **Step 1** Quran tests, **Step 2** countdown, **Step 3** salawat and quiet hours,
**Step 4** daily hadith, **Step 5** Android widget. Research items (Play exact alarm, Adhan, Liquid Glass) need no code.

| Step | Branch (PROPOSED) | Flag |
|---|---|---|
| 1 Quran tests | `feature/p3e-quran-tests` | `quran` |
| 2 Countdown | `feature/p3b-countdown` | `prayer` |
| 3 Salawat + quiet hours | `feature/p3d-salawat-quiet-hours` | `prayer` |
| 4 Daily hadith | `feature/p3f-daily-hadith` | new `dailyHadith` |
| 5 Android widget | `feature/p3g-android-widget` | `prayer` (receiver disabled until the flag is on) |

Shared rules: one branch per step, small commits, no co-author trailer, CI green before any pull request, no push or merge without
your explicit approval, released build unchanged while flags are off, copy and religious wording written only from owner-approved text,
every step reports PASS, FAIL, NOT RUN and NOT VERIFIED separately, Delete-all-my-data extended wherever a step stores something,
`docs/ARCHITECTURE.md` and `docs/RELEASE.md` updated per step.

## 4. Step 2 — Live countdown to the next prayer

**Scope.** On the Prayer page, the next-prayer banner shows time left (hours, minutes, seconds), updating every second while the
screen is visible. After Isha it counts down to tomorrow's Fajr.

**Design.**
- The value is always `nextAt - clock.now()` from the injected `Clock`; a counter is never decremented, so it cannot drift.
- A small countdown widget owns the timer. It ticks on the next whole second of the clock, only while the page is visible and the app
  is resumed (lifecycle observer plus route visibility). It stops when the app is paused or the page is covered.
- On resume it recomputes at once and asks `PrayerCubit` to refresh, which covers a changed phone clock, a long background period and
  the local date having changed.
- At zero it asks the cubit to refresh exactly once (guarded against a refresh loop). The new `PrayerMoment` then supplies the next
  target. At local midnight the cubit already recomputes the day; this is tested.
- When the user changes method, adjustments, location or Hijri settings, the cubit emits a new moment and the countdown retargets
  without restarting the page.
- Display: `H:MM:SS`, digits follow the user's digit setting, equal-width digits (`AppTypography.number`). No animated digits, so reduced
  motion needs nothing special.
- Accessibility: the spoken label is updated once a minute ("time left" and the next prayer), not every second, and it is not a live
  region, so TalkBack does not read every tick. Layout holds at 200% text.
- New strings (for your wording review): "time left" label only. No religious wording.

**Non-goals.** Countdown inside notifications, animated rings, "time since last prayer".

**Tests.** Unit: formatter (digits, hours, minutes, seconds, zero). Widget with fake time: ticks each second, stops while paused,
resumes with a jump, reaches zero and shows the next prayer, after Isha shows tomorrow's Fajr, local midnight, method change
retargets, DST days of 23 and 25 hours at the place, 200% text, label not updated every second. Device (NOT RUN until a phone is
available): frame timing in profile mode, TalkBack reading, background and foreground cycles over an hour.

**Effort.** 1.5 to 2.5 days. **Risk.** Low.

## 5. Step 3 — Salawat reminders and quiet hours

**Wording (approved).** Stored as constants in the localisation files exactly as above. A test compares them with the approved strings
so an accidental edit fails CI. English wording was not supplied (decision D3); until it is, the Arabic text is shown in both
interface languages and I will not translate it.

**Lead reminder grammar.** The approved template ends `دقيقة` for every number. Arabic grammar uses `دقائق` for 3 to 10. The existing
prayer reminders already do this through ICU plurals. Proposal: use the same plural rule here, otherwise the template verbatim. This
is yours to decide (D3).

**Schedule shape (PROPOSED, off by default).** Interval within a daily window (every 1, 2, 3, 4 or 6 hours between a start and an
end time you choose), optional lead reminder from the existing options (5, 10, 15, 30). Fixed times of day are an alternative (D4).

**Limits.** iOS holds 64 pending notifications; the planner keeps 60. Prayer reminders (5 per day, 7 days = 35, 42 with sunrise)
keep priority 10, so salawat can never displace them. That leaves 18 to 25 slots, so the planner gets a per-kind horizon (salawat
planned about 2 days ahead, extended each time the app opens) with tests. The Reminders page shows "planned through <date>" so the
limit is visible.

**Quiet hours.** User-set start and end (24 hour clock), may cross midnight, none by default. The rule I propose, because you asked
for an explicit product rule:

1. Quiet hours **suppress salawat reminders**. They are not shifted to a later time.
2. **Prayer reminders are not affected by default.**
3. An optional switch "Apply quiet hours to prayer reminders", off by default. If on, a prayer reminder inside quiet hours is
   **delivered silently** (shown, no sound, no vibration), never deleted and never moved (option A). The alternative is not
   delivering it and listing it (option B) (D1).
4. The Reminders page always says what quiet hours are holding back ("3 salawat reminders in the next 2 days"), using the planner's
   existing `dropped` list. Nothing is held back silently.
5. Quiet hours are judged on the **device's local time** (D2). The prayer place can be another city, and sleep follows the phone.

Edge cases tested: start inclusive and end exclusive, start equals end means none, window across midnight, window across a DST
change, a reminder exactly at the start or end, travel (device zone change), planner order independent of input order.

**Tests.** Wording constants; plural and digits; planner per-kind horizon and priority; quiet hours matrix above; reconcile on
settings change, boot, time zone change; permission denied; UI flows; 200% text; TalkBack reading of the ﷺ sign (NOT VERIFIED today,
test on device). Device checks (NOT RUN until a phone is available): delivery timing, reboot, Doze, time zone change.

**Storage.** `shared_preferences` like the existing reminder settings. No new table.

**Effort.** 6 to 9 days. **Risk.** Medium (platform notification limits, the per-kind horizon change in the planner).

## 6. Step 5 — Android home-screen widget (next prayer)

**Scope.** One widget (2×1, resizable) showing the next prayer, its time and a live countdown. Android only. An iOS widget needs
WidgetKit, an App Group and a Mac, so it is NOT APPLICABLE until Mac access (section 11).

**Design.**
- Native Kotlin `AppWidgetProvider` with `RemoteViews`. No Glance or Compose is added.
- Data bridge (D6): a thin own `MethodChannel` that writes a small snapshot into a private `SharedPreferences` file. Recommended over
  adding `home_widget` (a new dependency with background-callback machinery we do not need).
- Snapshot content: schema version, written-at, valid-until, and for the next 7 days each prayer's instant (UTC) with already
  localised name and time label (the app formats these in the user's language, digits and clock style, so the native side has no locale
  logic). No coordinates. Place name off by default because a home screen is visible to others.
- Rewritten on: app launch and resume, any reminder reconcile, change of method, place, language, digits or clock style, Delete-all.
- Native triggers that re-render from the stored snapshot (no Dart needed): `BOOT_COMPLETED`, `TIMEZONE_CHANGED`, `TIME_SET`,
  `DATE_CHANGED`, `MY_PACKAGE_REPLACED`, and an inexact alarm at each prayer boundary (no exact-alarm permission).
- Countdown: a `Chronometer` in count-down mode, which the system keeps ticking without waking the app. **NOT VERIFIED:** how it behaves
  after reaching zero, and its digits follow the system locale, not the app's digit setting. First task is a spike on the emulator and
  a phone. Fallback: the widget shows the prayer time only, and the live countdown stays on the Prayer page.
- Stale data: if the snapshot is missing, from an unknown schema, or has no future instant, the widget shows "Open Hadeeths to update"
  without times; it never shows an old prayer as upcoming. Boundary updates delayed by Doze can leave the label late by minutes; the
  time shown is still right.
- Tap: `PendingIntent` (immutable) opens `MainActivity` with a route extra; Flutter selects the Prayer tab (small channel call plus
  `onNewIntent`, launch mode is already `singleTop`).
- No place set: the widget says to open the app and choose a place.
- Release safety: the receiver is declared with `android:enabled="false"` and switched on at runtime only when the `prayer` flag is on,
  so the current released build gains no widget.
- Visuals: day and night resources, contrast at least 4.5:1, Arabic and English strings, RTL start and end attributes, large font scale.
- Permissions: none new.

**Tests.** Kotlin unit tests for the pure selection logic (next prayer at boundaries, stale, schema, DST), added to CI as a Gradle test
step (a CI configuration change, part of this plan's approval). Dart tests for the snapshot builder (7 days, formatting, no
coordinates, rewritten on each trigger, cleared by Delete-all). Device (NOT RUN until a phone is available): add and remove the
widget, reboot, time zone change, Doze, battery saver, tap target, Samsung One UI and a second launcher.

**Effort.** 5 to 8 days (3 to 4 native). **Risk.** Medium (OEM behaviour, countdown spike).

## 7. Step 1 — More Quran tests

**What exists** (`test/features/quran/*`, `test/app/quran_flow_test.dart`): verse search with marks ignored, go to verse with number
checks, real-file byte comparison, bookmarks, last read, 200% text.

**Gaps to cover.**
- Normalisation (`core/text/arabic_search.dart`): every rule in its documented policy, one test each (marks, Quranic annotation marks,
  tatweel, alef forms, alef maqsura, ta marbuta, Latin lower-casing, space collapsing); marks-only and one-letter queries; Arabic-Indic
  digits in queries; very long queries; results unchanged byte for byte.
- Search behaviour: every word must match, result limit and Mushaf order, same result for diacritised and plain queries, searching a
  phrase from the first and last verse of the Quran, performance budget for 6,236 verses measured (changing anything is a separate
  decision).
- Go to verse: exhaustive loop over all 114 suras with the real data (first verse valid, last verse valid, last plus one refused, zero
  refused); empty, whitespace, negative, non-numeric, huge numbers, Arabic-Indic digits typed by the user; keyboard type and submit;
  closing the dialog without leaks; the reader opens at the verse and it is visible; 200% text; English and Arabic interface.
- Sura list: if the filter feature is approved (D7), tests for Arabic and English names, by number (Western and Arabic-Indic digits),
  spelling variants, no match, clearing the filter, state kept after returning from the reader.
- Device level: `integration_test` flows run locally on the emulator or phone (search, go to verse, bookmark, restart keeps last
  read). The package is a dev dependency (D7). A CI emulator job is possible but slow; recommended only if you want it.

**Effort.** 2 to 4 days, plus 1 to 2 days if the sura filter is approved. **Risk.** Low.

## 8a. Step 4 — Daily hadith

**Behaviour (PROPOSED).**
- A card on the hadith home screen (behind the new `dailyHadith` flag) shows one hadith, its category name, its reference when the API
  supplies one, the HadeethEnc credit, and grading only if the API supplies it (the app never derives grades). Share and favourite
  reuse the existing buttons.
- Category choice: the categories the user has opened, sorted by id, picked by `day number % count`, skipping yesterday's category when
  there is more than one.
- Hadith choice inside the category: a deterministic sequence from a stable hash (FNV-1a, the same hash family the planner uses) of the
  local date and the category id, skipping any id shown in the last 60 days. If everything is exhausted, a repeat is accepted.
- The chosen id is stored for the day (`daily_hadith(day, hadith_id, category_id)`), so opening more categories later in the day does
  not change today's hadith, and the same day always shows the same hadith.
- New users and a user with no opened categories: rotate over the top-level categories the API already returns. No editorial list is
  written by me. If you prefer a curated list, you supply the ids (D5). With no network and nothing cached, the card shows a prompt to
  browse categories, never invented content.
- The card never says that opening categories is the only way to discover content. It names the category it came from, and a setting
  lets the user choose "categories I have opened" or "all categories", and turn off remembering opened categories.

**Storage (migration 6).** `opened_categories(category_id, last_opened_at)` (newest 50 kept), `daily_hadith(day PK, hadith_id,
category_id)`, `daily_hadith_history(day, hadith_id)` (last 60 days). Ids and dates only, no HadeethEnc text. Cleared by Delete-all.
Upgrade-path test from version 5 added to the existing suite.

**Network.** At most two requests a day (a list page of the chosen category, then the hadith), made when the card is shown, never in
the background. HadeethEnc caching terms are still unaddressed (your accepted risk); this adds no bulk copying.

**Tests.** Determinism with a fake clock; rotation over days; stable when the opened set changes mid-day; no repeat within 60 days and
the exhausted case; fallback; category with no hadiths skipped; offline with and without cache; local midnight and DST; migration;
Delete-all; source line present; 200% text; request count with the fake server.

**Effort.** 5 to 8 days. **Risk.** Medium (category sizes and list paging come from the API; to be confirmed against live responses
in the first task).

## 9. Google Play exact alarm — research findings (no compliance claim)

Sources fetched 2026-10-10. The fetch tool summarises pages with a small model, so exact quotations should be re-read on the live pages
before being relied on.

- **Play Console Help, "Permissions and APIs that Access Sensitive Information"** — https://support.google.com/googleplay/android-developer/answer/9888170
  - `USE_EXACT_ALARM` is a restricted permission. The acceptable uses listed are an alarm or timer app, and a calendar app that shows
    event notifications. It must serve core, user-facing functionality. Apps that do not qualify "will be disallowed from publishing".
  - For other exact-alarm needs it points to `SCHEDULE_EXACT_ALARM`, which "provides the same functionality but access must be granted
    by the user", and asks for a Play Console declaration (form link on that page). No deadline is given on that page.
- **Android developers, "Schedule alarms"** — https://developer.android.com/develop/background-work/services/alarms/schedule
  - `SCHEDULE_EXACT_ALARM` is not pre-granted to new installs targeting Android 13 or later; the user or system can revoke it; on
    revocation the app is stopped and its exact alarms are cancelled; `canScheduleExactAlarms()`,
    `ACTION_REQUEST_SCHEDULE_EXACT_ALARM` and the permission-state-changed broadcast exist for the flow. "Most apps should use inexact
    alarms."

**What this means here.**
- Prayer reminders are not an alarm app or a calendar app, so **`USE_EXACT_ALARM` is not appropriate** and will not be used.
- **`SCHEDULE_EXACT_ALARM` stays optional** (as approved on 2026-10-09): off by default, the user switches it on, the app opens the
  system "Alarms & reminders" page, and the Reminders page says plainly when it is off and that reminders may then arrive late.
- Fallback when it is off or revoked: inexact delivery, shown in settings. Re-check on resume and on the permission-state broadcast.

**NOT VERIFIED (cannot be settled from the pages above).**
1. Whether the Play declaration form is also required for `SCHEDULE_EXACT_ALARM`, and what Google will accept as its justification.
   Play Console's own prompts at upload are the authority. Please check it there before the first release.
2. Whether Google considers prayer reminders a qualifying use. The decision is Google's.
3. Any policy change after 2026-10-10.

**Release implications and proposed safeguards.** If Play rejects the permission, the fix must be small. Proposal (needs approval, a
tiny code change): a single build-time switch that removes the manifest line and hides the "exact timing" control. Checking the merged
release manifest for permissions added by plugins is a task in Step 3 (NOT RUN). I will prepare a short declaration text and a screen
recording of the permission flow for you to submit; I will not submit anything.

## 10. Adhan audio

Unchanged: the device's default notification sound, or silent. No recordings are bundled. Before any recording is added, the written
licence must cover the recording itself (reciter and producer), embedding and redistribution in the app, commercial use, attribution,
and platform formats. Technical notes to verify then: Android channel sound is fixed when a channel is created (a new sound needs a new
channel id); iOS limits notification sound length (believed 30 seconds, NOT VERIFIED). Nothing to build now.

## 11. Liquid Glass

Preconditions from your decision: the UI audit and modernization plan are complete (A to F merged). Before any spike:
1. **Confirm Mac availability** and whether iOS will ship soon (D9). Without a Mac and an iPhone nothing can be built or checked.
2. **Decide whether native would materially improve** the iOS experience, by a short spike (tab bar only, throwaway branch) judged on:
   legibility, scroll-under behaviour, Arabic RTL, Reduce Transparency, Increase Contrast, Dynamic Type, VoiceOver, and frame timing,
   against the current Material bars. Proceed only if the gain is visible and nothing in RTL or accessibility gets worse.
Status: NOT RUN, deferred. The iOS widget (section 6) waits on the same Mac decision.

## 12. Cross-cutting changes the steps will need (all subject to approval)

| Area | Change | Step |
|---|---|---|
| Schema | migration 6 and upgrade test | 4 |
| Delete-all | clear daily-hadith tables, widget snapshot, new preferences | 3, 4, 5 |
| Android | widget receivers, XML, resources, Kotlin, intent route, Gradle unit-test setup | 5 |
| CI | Gradle unit-test step | 5 |
| Dev dependency | `integration_test` (SDK package), only if D7 is approved | 1 |
| Localisation | new Arabic and English strings, each listed for your wording review | 2, 3, 4, 5 |
| Docs | ARCHITECTURE, RELEASE, privacy text in About | each step |
| Skill file | extend `.claude/skills/hadeeths-ui-modernization/SKILL.md` with countdown, widget and quiet-hours conventions | only after approval |

No new runtime dependency is planned.

## 13. Effort, risks and device checks

| Step | Engineering days | Main risk |
|---|---|---|
| 1 Quran tests | 2 to 4 (+1 to 2 with sura filter) | low |
| 2 Countdown | 1.5 to 2.5 | low |
| 3 Salawat + quiet hours | 6 to 9 | planner limits |
| 4 Daily hadith | 5 to 8 | API paging, offline |
| 5 Android widget | 5 to 8 | OEM behaviour, countdown spike |
| Total | about 20 to 32 | |

Device checks stay NOT RUN until a phone is connected: reminder timing, reboot, Doze, time zone change, widget behaviour, TalkBack,
frame timing. iPhone and VoiceOver checks stay NOT RUN until an iPhone is available.

## 14. Approval gates

- Implementation starts only after you approve this plan (all of it, or with amendments).
- Until then: no code, asset, dependency, configuration or skill-file change.
- I will not push `feature/p3c-reminders` or `master`. Everything else is pushed only when you say so.

## 15. Decisions needed from you (defaults apply if you approve without answering)

| ID | Question | My recommended default |
|---|---|---|
| D1 | Quiet hours and prayer reminders | Not affected by default; optional switch delivers them silently (option A) |
| D2 | Quiet hours time basis | The device's local time |
| D3 | English wording for the salawat reminders, and the minute plural | Arabic text shown in both languages until you supply English; use the ICU plural for minutes |
| D4 | Salawat schedule | Interval within a window, off by default |
| D5 | Daily hadith fallback | Rotate over the top-level categories; no curated list unless you supply ids |
| D6 | Widget bridge, place name, countdown | Own thin channel; no place name; live countdown only if the spike passes |
| D7 | Sura list filter and device tests | Add the filter; `integration_test` run locally, no CI emulator job |
| D8 | Exact alarm | Keep optional; add the build-time switch; you check the Play Console declaration |
| D9 | Liquid Glass | Stay deferred until you confirm a Mac and iPhone |
| D10 | Housekeeping | Retarget PR #8 to `master` and update it (see below); decide whether `.claude/` is committed |

Housekeeping noticed while planning: PR #8 (Quran) still has `feature/p3h-hardening` as its base, which has now been merged through
PR #7. It needs its base changed to `master` and master merged into it. I have not done this.
