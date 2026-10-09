# Prayer times: calculation and validation (Phase 3B-1)

Status: calculation core only (no screen, no location permission, no reminders yet).
Date of checks: 2026-10-09. Library: `adhan_dart` 2.0.1 (MIT).

## What exists

| Piece | File |
|---|---|
| Settings (method, Asr school, high-latitude rule, manual minute corrections up to 30) | `lib/features/prayer_times/domain/calculation_settings.dart` |
| Calculator interface and the `adhan_dart` implementation | `domain/prayer_times_calculator.dart`, `data/adhan_prayer_times_calculator.dart` |
| One day of times, current and next prayer | `domain/prayer_day.dart`, `domain/prayer_moment.dart` |
| Qibla bearing, distance, turn-to-face maths | `domain/qibla.dart` |

Methods offered: Egyptian General Authority (Fajr 19.5, Isha 17.5), Umm al-Qura (Fajr 18.5, Isha 90 min after Maghrib),
Muslim World League (18 / 17), Karachi (18 / 18), North America (15 / 15). The library adds one minute to Dhuhr for every method
except Umm al-Qura. A test fails if the numbers shown to the user (`methodInfo`) ever differ from what the library uses.
Moonsighting Committee was left out on purpose: the library derives a day-of-year from a mix of UTC and local time for it,
which could be a day off.

**Default method: Egyptian** is a placeholder for a product decision (see "Open decisions"). It is applied only on first run and
never changes afterwards without the user choosing.

## How it was checked

1. **Cross-check with an independent implementation.** 11 cases (Cairo, Makkah, Karachi Hanafi, London including both
   clock-change days, New York, Auckland, Oslo with two high-latitude rules) compared with the Aladhan public API
   (`api.aladhan.com`, retrieved 2026-10-09; fixture `test/features/prayer_times/fixtures/reference_prayer_times.json` keeps the
   exact request URLs). Result: **every time within 2 minutes**; Fajr, Sunrise, Maghrib and Isha matched to the minute in most
   cases, Dhuhr is consistently 1 minute later in the app (the library's margin). Aladhan is another program, **not an official
   authority**. These tests show the wrapper is correct and two independent programs agree; they do not prove agreement with a
   given mosque or country.
2. **Third calculation for the two outliers.** On the London clock-change days Aladhan's Asr differs from the library by +2 and
   -4 minutes. A separate calculation written for this check (Meeus low-precision solar position, accurate to about 1 minute)
   agrees with the library to within 2 minutes (library +0.8 / -1.6; Aladhan -1.2 / +2.4), so Asr is checked against that value for
   those two cases (the fixture says so).
3. **Qibla.** 10 places compared with the Aladhan Qibla API (within 0.05 degrees) and with the library's own Qibla (within 0.5
   degrees), plus geometric checks (due north/south of Makkah, equator, date line, poles, at the Kaaba).
4. **Year sweeps.** 366 days for Cairo, Jakarta, London and Auckland: every day consistent, day-to-day movement of each time under
   12 minutes (Fajr and Isha excluded at high latitude, see below).

## Defect found in the library and how the app avoids it

`adhan_dart` 2.0.1 returns `ishaBefore` and `fajrAfter` computed from the wrong day whenever the high-latitude rule applies. At
Oslo on 21 June "next Fajr" came back as the same day's Fajr, and "previous Isha" as the same day's Isha. The app does not use
those two values: it calculates the previous and next day in full. A regression test (`library bug that the app avoids`) covers it.
Consider reporting it upstream.

## Known behaviour to explain in the UI

- **High latitudes (London, Oslo in summer):** Fajr and Isha can jump by 10 to 20 minutes from one day to the next, on the day the
  twilight angle stops being reachable and the high-latitude rule takes over. With "middle of the night" Isha and the following
  Fajr meet at the same minute for weeks. The app keeps both displayed times as calculated and nudges only the hidden neighbour
  fields by at most 2 minutes so they meet exactly. A gap larger than that is reported as an error.
- **Inside the polar circle** no times can be calculated; the calculator returns an error, never made-up times.
- **Rounding:** times are rounded to the nearest minute, so what the screen shows is exactly what a reminder will fire at.

## Not done in this step

Location (GPS, manual city with its time zone), saving settings, the dashboard, Hijri date, compass, widgets, reminders. Not yet
validated: Umm al-Qura during Ramadan (some sources describe a longer Isha interval in Ramadan for that method; this was not
verified here and the library does not apply it, so the app must not claim to follow such a rule until it is checked against the
official source and added), and times against any official national timetable (needs a
source you trust; none was invented).

## Location and place (3B-3)

- **Two ways to set the place:** "Use my location" (an explanation first, then the system prompt only if the user agrees, then one
  low-accuracy read, no tracking) or a city picked by name (no permission). The place is stored rounded to about 1 km. A device
  position keeps the zone of the device; a city keeps its IANA zone.
- **Android permissions added:** `ACCESS_COARSE_LOCATION` and `ACCESS_FINE_LOCATION` only (verified in the release APK with
  `aapt dump permissions`: INTERNET plus these two). No background location, no foreground service.
- **iOS:** `NSLocationWhenInUseUsageDescription` added to `Info.plist` (Arabic and English in one string). Not run on an iPhone; CI
  only compiles it. Localised `InfoPlist.strings` need the Xcode project and are left for a Mac session.
- **City list:** 119 cities chosen by hand (27 in Egypt, the main ones in the Gulf, the Levant, North Africa, South and South-East
  Asia, Europe, the Americas, Oceania and Africa). Names, coordinates, zones and country codes come from GeoNames `cities15000`
  (CC BY 4.0, credited on the About page); the Arabic names were written for this app and should be reviewed by an Arabic speaker.
  Search ignores diacritics and common spelling variants (`normalizeForSearch`).
- **Time zone data:** the compact database in `timezone` lacks 14 zone names that GeoNames uses (aliases such as `Europe/Oslo` and
  `Asia/Kuwait`), found by a test, so the full database is bundled (about 190 KB more).
- **Contested places:** القدس and غزة use the names and zones GeoNames gives (Jerusalem: `Asia/Jerusalem`; Gaza: `Asia/Gaza`). Their
  country codes are never shown and only influence the proposed method (which is the general one for both). The owner should decide
  whether to keep, rename or drop them.
- **Not on a device yet:** the real GPS read and permission prompt on the Android phone (the phone was locked during the session).
  Covered by tests with fakes only.

## Hijri date and Qibla screen (3B-4)

- **Engine:** `hijri_core` 1.1.0 (MIT, zero dependencies; table-driven Umm al-Qura for Hijri years 1318 to 1500, that is 1900-04-30 to the end
  of 2077, and a calculated FCNA criterion). Dates outside the Umm al-Qura tables are reported as unknown, never guessed.
- **Umm al-Qura check:** 80 Gregorian dates between 2025 and 2027 (two per month, plus the days around 1 Muharram 1448, 1 Ramadan and 1
  Shawwal 1447) compared with Aladhan's `calendarMethod=UAQ`: all 80 match exactly (fixture `reference_hijri_uaq.json`). Aladhan is an
  independent program, not an official authority; the package says its table comes from KACST data.
- **FCNA:** only checked for internal consistency (months of 29 or 30 days that follow each other from 2025 to 2030) and that it stays
  within about two days of Umm al-Qura. It has **not** been compared with an official FCNA calendar, so the screen says so and it is
  never the default. To validate it, the owner needs to supply the Fiqh Council's published calendar.
- **Policy implemented:** the default reference is Umm al-Qura for every country, with a manual correction of up to two days either way
  (this is how a country that announces months after moon sighting, such as Egypt, can be followed). The app does not propose a
  reference by country: no second reference is validated yet, so there is nothing safe to propose. The Hijri date changes at Maghrib,
  not at midnight (a test checks the minute of the change); the screen says so. The Gregorian date shown is the calendar day at the place.
- **Qibla screen:** the bearing in degrees from **true** north, the nearest of eight compass words, the distance, and a map-style dial
  with north at the top. It does not read the phone's compass, so it needs no sensor and never shows a noisy value. The note on the
  screen says that a phone compass points to magnetic north.
- **Live compass (3B-5, below)** replaces the earlier plan. The paragraph that follows is kept for the reasoning only:
- ~~Not done yet (needs the phone and one more decision): a live compass arrow.~~ A compass gives a magnetic heading; the Qibla bearing
  is relative to true north, so a live arrow needs the local magnetic declination (the World Magnetic Model, public domain, needs
  its coefficients and the official test values to be checked), and a sensor package that works with the project's current Android
  build tools (`flutter_compass` 0.8.1 is 23 months old and was not tried).

## Live compass (3B-5)

- **Magnetic declination:** the World Magnetic Model 2025 (NOAA/NCEI and the British Geological Survey), implemented from the technical
  report in `world_magnetic_model.dart` with the official coefficients (`assets/data/wmm2025.cof`, 93 lines). **All 100 official test points
  in NOAA's `WMM2025_TestValues.txt` match** for north, east and down components (within 0.01 nT) and for declination and inclination
  (within 0.01 degree). Valid from 2025.0 for five years: after that the compass is switched off with a message to update the app,
  rather than showing a heading that may be wrong. The licence of the coefficient file is not stated on the NOAA page; it is a US
  government publication and the model is widely redistributed, but this should be confirmed (see decisions).
- **Heading:** `HeadingCalculator` combines the accelerometer and the magnetometer with tilt compensation. Tested with simulated phone
  orientations (every heading in 10 degree steps, pitch and roll up to 30 degrees, five magnetic dips, the upright pose with the back
  pointing ahead, the 45 degree switch-over): exact to 1e-6 degrees. Smoothing averages the sensor vectors, so there is no jump at north.
- **Sensors:** `sensors_plus` 7.1.1 (BSD-3, Flutter Community; needs AGP 8.12.1+, which this project meets). Started only when the
  user taps "Use the compass", stopped when they tap stop, leave the screen or send the app to the background; never restarted by
  itself. No Android permission is needed (the release APK still declares only INTERNET and the two location permissions). iOS
  needs `NSMotionUsageDescription` (added; its own text says the sensors are used only while the compass is on).
- **Honesty rules:** if the measured field differs from the expected one by more than 40 percent (metal, a magnet, a case), the screen
  says the compass is unreliable, hides the arrow and never says "you are facing the Qibla". No sensor, or no reading within four
  seconds, gives a clear message and the numeric direction stays. Instructions are rounded to 5 degrees so a screen reader is not
  interrupted constantly; a short vibration marks the moment of alignment (within 5 degrees).
- **On the Samsung phone:** the sensor stream works and the interference rule fired correctly: the phone, lying on the desk, measured
  about 760 microtesla where the Earth alone gives about 44 here, so something next to it (a magnet, stand or charger) dominates. The
  absolute accuracy of the heading therefore **has not been verified on the device**; it needs the phone held away from metal and
  compared with a known direction (see decisions).

## Owner decisions (2026-10-09) and where they stand

| # | Decision | Status |
|---|---|---|
| 1 | Method chosen **by country at first setup only**, then fixed | Built (3B-2): `MethodSuggestion` maps Egypt to Egyptian, Saudi Arabia to Umm al-Qura, Pakistan, Bangladesh, India and Afghanistan to Karachi, the US and Canada to North America; any other country gets Muslim World League and the screen must say no country-specific method exists. `PrayerPreferences` proposes once from the first place set and never again; only the user can change it. The mapping is the app's own convention over the five methods offered; countries whose authorities use other methods (Kuwait, Qatar, UAE, Turkey, Morocco, Indonesia, Malaysia...) are not covered until those methods are added and validated. Country comes from the place, or offline from simplified borders (Natural Earth 1:110m, public domain). |
| 2 | Validation authority: Egyptian General Authority of Survey, for Egypt | **Partly done.** The authority's own timetable was not reachable (egsa.gov.eg is the Egyptian Space Agency, a different body). Three Cairo days that Egyptian newspapers attribute to the authority (22 Feb, 1 Apr, 6 Aug 2026; fixture `egsa_press_reports.json`) match the Egyptian method within 2 minutes (Fajr, Maghrib and Isha mostly to the minute; Dhuhr 1 to 2 minutes later in the app because of the library's 1-minute margin). This is a secondary source. **Needed from the owner:** the authority's official timetable (PDF or table) or its web address, to replace the press reports. |
| 3 | Hijri date: calendar suited to the country, with a changeable reference and manual adjustment | **Built (3B-4)**: Umm al-Qura and FCNA references, manual correction of up to two days, date changes at Maghrib; see the section above. No reference is proposed by country, because only Umm al-Qura is validated. Egypt's official months follow moon-sighting announcements that cannot be computed offline, so for Egypt the manual correction is the way to follow them and the screen says the calendar may differ from the announcement. The package `hijri_core` was chosen and its Umm al-Qura output checked (80 of 80 dates). |
| 4 | Digits: Arabic-Indic by default in the Arabic interface, with an option to change | Built (3B-2): Settings has "Numerals" (match the language, Arabic-Indic, Western). It applies to the app's own numbers only (category counts, search messages, hint numbering, text-size percentage) and never to text from sources, which is shown exactly as received (a test checks this). Times and dates will use it when the dashboard is built. |

## Open decisions for the owner

1. The authority's official Egyptian timetable (see decision 2 above).
2. Official timetable for Makkah (Umm al-Qura calendar) to validate that method the same way.
3. Whether to add Moonsighting Committee, Kuwait, Qatar, Dubai, Turkey, Morocco, Indonesia and Malaysia methods (each needs its own
   validation), so that more countries get a specific method.
4. Ramadan handling for Umm al-Qura.
5. Which Hijri reference is the default for Egypt (see decision 3).
