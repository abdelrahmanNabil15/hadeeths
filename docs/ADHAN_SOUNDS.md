# Adhan sounds for the prayer reminders

The owner asked for the user to be able to download a recording of the adhan and use it as the sound of the prayer
reminders. This changes an earlier decision ("system sound or silent only; the app ships no audio"): the app still ships
no audio, but it can now fetch a recording the user chooses.

## What it does

- **Reminders → Sound → Adhan** (Android 10 and later only, and only with the `adhanSounds` feature flag on) opens a page
  listing five recordings (`lib/features/adhan_sounds/domain/adhan_sound.dart`).
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
- Android only. **iOS** needs notification sounds in the app bundle, limited to 30 seconds; the five short ones could be
  converted to `.caf` and added in Xcode, the 41-second wake-up recording could not play there as is. Not done: iOS keeps
  the system sound.
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
- Android only, like the other recordings. On an Android 16 emulator the channel `prayer_raw_salawat_1_vibrate` was created with
  sound `android.resource://com.hadeeths.eg/raw/salawat_1`; hearing it is NOT RUN. The channel's name in the phone's
  settings starts with "Prayer reminders", which is not quite right for salawat; not changed.

## Not available, and why

- **iOS:** a notification sound there must be bundled with the app or placed in the app's Library/Sounds folder, and is
  limited to 30 seconds. The listed recordings are longer, and playing one in the app would need an audio player package
  (a new dependency, needing approval). The Adhan choice is not offered on iOS.
- **Android 9 and older:** shared sounds would need a storage permission; the choice is not offered.

## Before it is switched on for everyone — owner decisions

1. **Rights.** The recordings are served from `media.assabile.com`. Their rights belong to their publishers and reciters,
   and I found no terms page that allows an app to fetch or redistribute them. The app links to the files and does not
   host them, but pointing every user at a third party's server is the owner's decision: ask assabile.com (and the
   reciters or their estates) for written permission, or host recordings the owner has the right to use. The flag stays
   **off** in release builds until this is settled; `HADEETHS_PREVIEW_SECTIONS=true` turns it on for previews.
2. **Availability.** The addresses are on a CDN the app does not control; they can change or be blocked. A failed
   download shows a clear message and nothing breaks.
3. **Wording.** All new strings are marked "wording for owner review".
4. **Google Play.** A user-initiated download of a notification sound is ordinary; this has not been checked against any
   store policy, and no compliance claim is made.

## Checks

- Unit and widget tests: `test/features/adhan_sounds/`, `test/app/adhan_flow_test.dart`, and the adhan cases in
  `test/app/reminder_coordinator_test.dart` and `test/features/prayer_times/reminder_settings_test.dart`.
- On an Android emulator: see the pull request for what was exercised. Hearing the sound on a real phone is NOT RUN.
