# Asking for a rating

The app can ask the system to show its own rating sheet at a calm moment, and always offers a **Rate Sakina** entry that
opens the store page. Behind the `inAppReview` feature flag (off by default; `HADEETHS_PREVIEW_SECTIONS=true` turns it on
with the other sections).

## What the user sees

- **Rate Sakina / قيّم سكينة:** More, and Sources and rights (About). Opens the app's page in the store. It works whatever
  the automatic rules say. It is not shown where the store page cannot be opened: on iOS it waits for the App Store id
  (`InAppReviewBridge.appStoreId`, not known yet because the iOS app is not published), so today it is Android only.
- **The system's rating sheet,** asked for automatically, only when **all** of these hold at that moment:
  - at least 3 distinct days of use and 5 days since the first launch;
  - at least 15 qualifying completed actions, and at least one since the last request;
  - at least 90 days since the last request, and fewer than 3 automatic requests in the app's life;
  - this app version has not asked before;
  - no prayer is due (from 10 minutes before a prayer until 20 minutes after it began), no adhan download is running, and
    the hadith home screen finished loading without an error.
- The moment is **back on the hadith home screen**: a page above it closed, or its section was selected while it showed
  its first page. Never inside the Quran reader, the counter, Qibla, reminders, or anywhere else.
- The app shows **no dialog of its own,** asks no "do you like the app?" question, offers nothing in return and sends no
  analytics.

## Qualifying completed actions

Each is counted once per key per day (a reopened page or a repeated tap does not count twice):

| Action | Key |
|---|---|
| A hadith read: its details loaded and shown | `hadith:<id>` |
| A prayer marked as prayed in the tracker (not the page loading earlier marks, a new week, or a change taken back) | `prayer:<day>:<prayer>` |
| A counting round finished (the count reaches its target) | `tasbeeh:round` |
| The Quran place saved on another verse | `quran:<sura>` |

## What is remembered (on the phone only)

One entry, `app_review_v1`, in shared preferences: the first launch time, the days of use (`yyyy-mm-dd`, UTC, at most 400),
a counter of actions, whether one is waiting, today's action keys, and the requests made (time, app version, whether
counted; at most 20). No content, no identifiers. **Delete all my data** clears it and starts counting again from that moment.

- A missing entry is a fresh start. An entry that cannot be read as a whole, or a damaged request list, is treated as
  "lost history": the next launch records a request made *now*, which holds automatic requests back for the 90 days
  without using up one of the three.
- A clock that moved backwards can only make the app wait longer: a first launch or a day in the future is corrected, and a
  negative time since the last request counts as inside the waiting time.
- A request is **recorded before it is made.** The app cannot know whether the sheet was shown or the user rated, so a
  request that the system declines (`isAvailable` false) is recorded as a request that does not count towards the
  lifetime limit; it still holds back the next one, and it is not retried.

## How it is built

- `lib/features/app_review/domain/`: `ReviewPolicy` (pure Dart, takes the time it should use), `ReviewState`, `ReviewStore`,
  `ReviewActions` (what screens may call).
- `lib/features/app_review/data/prefs_review_store.dart`: the saved entry.
- `lib/core/platform/review_gateway.dart`: `ReviewGateway` and `InAppReviewBridge`, the only code that uses the
  `in_app_review` package. `lib/core/platform/app_version_source.dart`: the installed version (`1.1.0+2`) through the
  `hadeeths/app_info` channel (`MainActivity.kt`, `AppDelegate.swift`), because the once-per-version rule needs it and no
  other package was wanted for it. A version that cannot be read means no automatic request.
- `lib/app/review_coordinator.dart`: one queue for every change to the memory; `maybeRequest()` reads the rules at the
  moment of asking, after the "calm moment" check. `lib/app/review_wiring.dart`: the calm-moment check and the observer that
  notices the return to the home screen.
- Screens reach it through `ReviewScope` (nothing when the feature is off) and `RateAppTile`.

## Dependency

`in_app_review` 2.0.12 (MIT, verified publisher britannio.dev, last published about four months before this was added,
Android API 21+, iOS 12+; this app's targets are higher). It brings `in_app_review_platform_interface` and, through it,
`url_launcher` with its Android, iOS and macOS packages (six new packages in `pubspec.lock`), and on Android Google's Play
review library (`com.google.android.play:review` 2.0.2) and `play-services-base`. The release APK's permissions did not change.

## Checks

- `dart format`, `flutter analyze` and `flutter test` (policy, store, coordinator, wiring, flows, tracker events, gateway).
- On an Android emulator (debug build): the installed version reaches Dart through the new channel, and the Rate entry is on More
  (`integration_test/app_review_test.dart`).
- **NOT RUN:** the system's rating sheet. It appears only for a build installed from Google Play (for example the internal
  testing track), never on a locally installed build, and it is limited by Google's own quota, so it needs a look on a phone
  after the first Play install. Opening the store page from "Rate Sakina" was not run either (it needs a phone with Google Play).
- **NOT RUN:** everything on iOS. The Swift version channel was written without a Mac and has not been compiled; iOS also
  has no store page to open until the App Store id is known.

## Before turning the flag on for everyone

1. Install an internal-testing build from Play, use the app past the thresholds (or lower them in a test build) and look at
   what the system does; look at "Rate Sakina" there too.
2. Review the wording: `rateApp` (English "Rate Sakina", Arabic "قيّم سكينة", approved by the owner).
3. Play Console: the in-app review API collects nothing on the app's behalf; no change to the Data safety answers is expected,
   but check them against the final build.
