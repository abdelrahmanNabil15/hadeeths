# Adhan sounds for the prayer reminders

The owner asked for the user to be able to download a recording of the adhan and use it as the sound of the prayer
reminders. This changes an earlier decision ("system sound or silent only; the app ships no audio"): the app still ships
no audio, but it can now fetch a recording the user chooses.

## What it does

- **Reminders → Sound → Adhan** (Android 10 and later, and iOS; only with the `adhanSounds` feature flag on) opens a page
  listing the recordings (`lib/features/adhan_sounds/domain/adhan_sound.dart`): five from the original set, plus one
  recording per reciter from assabile.com's Masjid al-Haram, Masjid an-Nabawi, Al-Aqsa, Saudi Arabia and Egypt pages,
  added with the owner's go-ahead (see "Rights" below).
- Each is **downloaded only when the user taps Download** (a plain `GET` of the recording's address; nothing about the user
  is sent), kept in the app's private folder (`adhan/<id>.mp3`), and checked: audio content type, an MP3 start, and a size
  within 25% of the listed size. A page of HTML or a replaced file is refused and nothing is kept.
- **Use this adhan** saves the choice in the reminder settings (`adhan` in the saved reminders). **Delete the file** removes
  it, and the reminders go back to the system sound.
- The adhan plays **only for a prayer reminder at the prayer time**: not for an early ("10 minutes before") reminder, not for
  sunrise, and not for salawat reminders. A prayer reminder delivered silently in quiet hours stays silent.
- "Send a test reminder" plays the chosen adhan, so the user can hear it.

## How it reaches the notification (Android)

A notification channel's sound is fixed when the channel is created, and the system's notification service cannot read a
file in the app's private folder. So each downloaded file is also listed, under the same name, in the phone's shared
`Notifications/Sakina` sounds through the media store (`AdhanSounds.kt`, channel `hadeeths/adhan_sound`); no storage
permission is needed on Android 10+ for entries the app creates. A channel is made per recording
(`prayer_adhan_<id>_<hash of the address>_<vibrate|still>`), so downloading a recording again (a new address) gets a new
channel and the stale one is deleted. If the file or its entry is gone, the reminder falls back to the system sound.

## How it reaches the notification (iOS) — "Adhan sound" and "Full adhan"

iOS caps a notification's own sound at 30 seconds and it must be a bundled file, not an arbitrary one, so the full
recording cannot be the notification's sound there. Instead:

- At **download time**, the same `hadeeths/adhan_sound` channel's `register` call is implemented natively for iOS
  (`AdhanNotificationSounds.swift`): it trims the recording to at most 29 seconds, downmixes to mono 16-bit linear PCM,
  and saves it as `<id>.caf` in `Library/Sounds` (the one runtime-writable place `UNNotificationSound(named:)` resolves,
  besides the app bundle). The full recording is untouched, for the "Full adhan" playback below and the in-app preview.
  If the conversion fails, it is logged and the download still succeeds (unlike Android, where a listing failure fails
  the whole download): the reminder then falls back to the system sound, and preview/full playback still work.
- At **schedule time**, `local_notifications_gateway.dart` checks the `.caf` exists (`AdhanLibrary.iosSoundFileFor`) and
  sets it as `DarwinNotificationDetails.sound`; if it is missing, the system sound is used instead.
- **Full adhan** (Reminders → Sound → Adhan → "Play the full adhan in the app", iOS only): plays the complete recording
  in the app instead of relying on the 30-second clip, when the app is in the foreground as the reminder fires, or when
  the user taps the notification. `AppDelegate.swift`'s `UNUserNotificationCenterDelegate` reads `adhan`/`full` from the
  notification's own payload (`NotificationPayload.encode`, `notification_sync.dart`) and, for a matching prayer-time
  reminder, suppresses the short clip in `willPresent` (so it never overlaps with full playback) and calls Dart over the
  `hadeeths/full_adhan` channel; `FullAdhanCoordinator` resolves the full file through `AdhanLibrary.localPathFor` and
  plays it with `just_audio` (`AVAudioSession` category `.playback`). With the app closed or backgrounded and not
  tapped, only the short clip plays — there is no way to play the full recording in that case; see "Not available"
  below.
- Verified on the simulator: a freshly converted `.caf` (mono 16-bit PCM, trimmed to exactly 29.0s, confirmed with
  `afinfo`) played as a real notification's sound (`AudioServicesCreateSystemSoundIDWithOptions` returned 0); with
  "Full adhan" on, the short clip was suppressed and the full recording played through `AVPlayer` both when the
  notification fired in the foreground and after tapping it while backgrounded. Not verified on a real iPhone.

## The spoken early reminders and the wake-up alarm (recordings supplied by the owner)

Six short recordings ship with the app, in `android/app/src/main/res/raw/` (the owner's files, renamed to letters and digits
only: Android raw resource names cannot contain Arabic). **I have not listened to them**: each is used according to the
name the owner gave it, and the owner should check that every file says what its name says.

| File | Used for | Length |
|---|---|---|
| `near_fajr.mp3`, `near_dhuhr.mp3`, `near_asr.mp3`, `near_maghrib.mp3`, `near_isha.mp3` | an **early reminder** ("how long before" 5 to 30 minutes) for that prayer: the prayer is near | about 3 seconds each |
| `wake_fajr.mp3` | the **wake-up alarm before Fajr** | about 41 seconds |

- **Early reminders** play the recording for their own prayer instead of the system sound. Reminders at the prayer time are
  unchanged (the system sound, or the downloaded adhan). Not used for sunrise, and not when the reminders' sound is Silent
  (or a prayer reminder is delivered silently in quiet hours).
- **Wake-up before Fajr** (Reminders → Wake-up before Fajr): off by default; the user picks 15, 30, 45 or 60 minutes before
  Fajr. It plays `wake_fajr.mp3` through an **alarm-type channel** (importance maximum, played as an alarm, not as a
  notification). It is its own choice: it plays even when the reminders are Silent and in quiet hours, and it works with
  the five prayer reminders off (it needs the master switch and a place). Turn on "Exact timing" for it to arrive on the
  minute.
- The five short recordings also play on **iOS**: each is bundled as `<name>.caf` (`ios/Runner/Resources/Sounds/`, added to
  the Runner target) and named as the notification's own sound (`DarwinNotificationDetails.sound`). iOS has no channels, so
  there is nothing to create ahead of time; the file name is simply reused each time. The 41-second wake-up recording is
  over iOS's 30-second notification-sound limit and is not bundled: that reminder keeps the system sound there.
- Existing scheduled reminders are replaced the next time the app plans them (the saved signature changed to `v2`).
- On an Android 16 emulator the channels were created with the expected sounds (`android.resource://…/raw/near_*`,
  `raw/wake_fajr`), the wake-up channel as `USAGE_ALARM`; actually hearing them on a phone is NOT RUN.

## The salawat recordings (supplied by the owner)

Two more recordings ship in `android/app/src/main/res/raw/`: `salawat_1.mp3` (the owner's "نغمة صلي على محمد ﷺ", about 13 seconds)
and `salawat_2.mp3` ("اللهم صل على محمد وعلى آل محمد", about 7 seconds; lengths estimated from the MP3 headers). As with the other
recordings, **I have not listened to them**.

- **Salawat reminders → Sound** offers the two recordings and "The phone's notification sound". The first is the default, so a
  user who switches salawat reminders on hears it without choosing; the choice is saved (`tone` in the saved salawat
  settings; older saved data gets the default).
- It plays for the salawat reminder at its time and for the optional earlier one. It does not play when the reminders' sound
  is Silent, and the prayer reminders never use it.
- The option names are the owner's file names, in Arabic in both interface languages, like the salawat reminder text. They are
  marked for the owner's review.
- Also plays on iOS, bundled the same way as the five short recordings above (`salawat_1.caf`, `salawat_2.caf`). On an
  Android 16 emulator the channel `prayer_raw_salawat_1_vibrate` was created with sound
  `android.resource://com.hadeeths.eg/raw/salawat_1`; hearing it is NOT RUN. The channel's name in the phone's settings
  starts with "Prayer reminders", which is not quite right for salawat; not changed.

## Not available, and why

- **The full recording as the notification's own sound, on iOS, with the app closed or backgrounded and not tapped:**
  not possible at all — iOS cannot play a notification sound longer than 30 seconds or one that is not a bundled file,
  and there is no delegate callback for a notification delivered while the app is not running or not foregrounded.
  "Full adhan" plays the complete recording only when the app is in the foreground as the reminder fires, or once the
  user taps the notification; otherwise the 30-second clip is what plays.
- **Android 9 and older:** shared sounds would need a storage permission; the Adhan choice is not offered.

## Before it is switched on for everyone — owner decisions

1. **Rights.** The recordings are served from `media.assabile.com`. Their rights belong to their publishers and reciters,
   and I found no terms page that allows an app to fetch or redistribute them (checked again when the catalogue grew
   past the original five: no Terms of Use, API terms or redistribution notice anywhere on the site, including its
   `/about` page). The app links to the files and does not host them, but pointing every user at a third party's server
   was the owner's decision to make. **The owner has told me permission was obtained** for assabile.com's recordings,
   which is why the catalogue now also includes one recording per reciter from the Masjid al-Haram, Masjid an-Nabawi,
   Al-Aqsa, Saudi Arabia and Egypt pages — I have not seen the permission itself (an email or other written record of
   it is worth keeping on file). The flag still stays **off** in release builds until the owner turns it on;
   `HADEETHS_PREVIEW_SECTIONS=true` turns it on for previews.
2. **Availability.** The addresses are on a CDN the app does not control; they can change or be blocked. A failed
   download shows a clear message and nothing breaks.
3. **Wording.** All new strings are marked "wording for owner review".
4. **Google Play.** A user-initiated download of a notification sound is ordinary; this has not been checked against any
   store policy, and no compliance claim is made.

## Checks

- Unit and widget tests: `test/features/adhan_sounds/`, `test/app/adhan_flow_test.dart`, and the adhan cases in
  `test/app/reminder_coordinator_test.dart` and `test/features/prayer_times/reminder_settings_test.dart`.
- On an Android emulator: see the pull request for what was exercised. Hearing the sound on a real phone is NOT RUN.
- The seven `.caf` files (early reminders and salawat) were converted with `afconvert -f caff -d LEI16 -c 1` and
  confirmed under 30 seconds with `afinfo`. On the simulator, both played as a local notification's sound. Hearing
  them on a real phone is NOT RUN.
- The iOS Adhan sound / Full adhan path (native `.caf` conversion, the notification's sound, the foreground suppression
  and tap hand-off, full playback through `just_audio`) was exercised end to end on the simulator: see "How it reaches
  the notification (iOS)" above. Hearing it on a real phone is NOT RUN.
- The 26 recordings added from assabile.com beyond the original five: their URL and exact byte size were read straight
  from the site (`curl -IL` on each `/download/adhan/<id>` link, which 302s to the real `media.assabile.com` address),
  so a real download of each would pass the existing size/content-type check — but none of the 26 was actually
  downloaded or played during this change. **I have not listened to any of them** to confirm they are what their
  names say, or that the place given (read from the site, occasionally odd — e.g. one Egypt-categorised reciter's
  recording is titled for a mosque in Colombia) is accurate; the owner should spot-check them.

## Real-iPhone checklist for Adhan sound / Full adhan (not yet run)

Everything above was verified on the iOS Simulator, which cannot play audio through real hardware the same way and
has no lock screen to test against. Before relying on this feature, run through the cases below on an actual iPhone,
with a muezzin downloaded and "Full adhan" turned on in Reminders. For each case, note what you actually heard/saw
versus what's expected.

1. **App closed (swiped away), screen locked.** Wait for a prayer reminder to fire (or push a test local notification
   a minute out). Expected: the lock screen shows the notification and you hear the ~29s clip play as the
   notification's own sound, at the phone's ringer/notification volume — not the in-app slider, since the OS plays it,
   not the app.
2. **App backgrounded (not closed), screen locked or on another app.** Same as above: expected is the short clip only,
   because Full adhan requires the app to be in the foreground or for you to tap the notification.
3. **App in the foreground when the reminder fires.** Expected: the short clip is suppressed (no double playback) and
   the full recording starts playing in-app automatically, at the volume set on the Adhan Sounds page slider.
4. **Tapping the notification (from locked screen or background) after the short clip has already played.** Expected:
   the app opens and the full recording starts playing in-app, at the slider's volume, even though the short clip
   already played as the notification sound — this is expected double playback by design (OS clip, then full
   recording on tap), not a bug.
5. **Changing the volume slider, then repeating case 3 or 4.** Expected: the full-adhan in-app playback respects the
   new slider value; the short clip's loudness (case 1/2) should NOT change, since that one plays at the phone's own
   notification volume, outside the app's control.
6. **Silent switch / Focus modes.** Not covered by this feature's own logic — worth confirming the short clip still
   behaves like any other notification sound under Do Not Disturb / Focus, since the app does not override those.

None of this has been run on a real device as part of this change; the simulator evidence (see "Checks" above) is the
only verification so far.
