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

## Open decisions for the owner

1. Default method (placeholder: Egyptian) and whether to choose it from the country of the location.
2. Which official timetable(s) to use as the authority for further validation (for example the Egyptian General Authority of
   Survey, Umm al-Qura calendar for Makkah).
3. Whether to add Moonsighting Committee, Kuwait, Qatar, Dubai, Turkey after the extra checks they need.
4. Ramadan handling for Umm al-Qura.
5. Hijri date policy and Arabic or Western digits (needed for the dashboard step).
