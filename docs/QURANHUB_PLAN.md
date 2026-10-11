# Plan: using QuranHub (Misraj AI) for the Quran section

Status: **plan only, nothing implemented.** Written 2026-10-10 after reading
<https://github.com/misraj-ai/quranhub>, its README and LICENSE, and making read-only requests to the public API.

## 1. Can we use it?

**Technically, yes.** `https://api.quranhub.com/v1/...` is a public JSON REST API. A request to `/v1/surah/112/quran-uthmani`
returned 200 with no key, served through Cloudflare with `Cache-Control: public, max-age=2592000` (30 days). Each verse carries
`juz`, `page` (1–604), `ruku`, `hizbQuarter`, `manzil` and `sajda`; the README lists 433 editions (text, 157 tafsir, 167
translations, 88 audio) in 50+ languages, search, themes, similar verses and morphology.

**Legally, not yet.** Three things block a decision:

| Point | What we found | What it means |
|---|---|---|
| Licence | The repository is under the **Non-Commercial Licence (NCL)**: "commercial use … or using the software as part of a commercial product or service is strictly prohibited without explicit written permission from Misraj AI" (contact hello@misraj.ai). | This covers the software. The README does not say whether the *hosted API* may be used by a commercial app. **Is hadeeths commercial (ads, in-app purchases, paid)? The owner decides; if yes, we need written permission first.** |
| Terms, rate limits | The docs site (qurani.ai) lists "Rate Limits" and "Authentication" pages, but they did not load for us (rendered by script). "Advanced tools" need a paid API key; "Basic tools" are called free. | Unknown limits and no stated uptime promise. Do not depend on it at run time until we have read them. |
| Text provenance | The `quran-uthmani` text matches our Tanzil file for the verses we compared (sura 112, verses 2–4; verse 1 differs only because Tanzil keeps the opening line inside verse 1). Other editions come from many sources, each with its own licence. | We must check the licence and credit of **each edition** before using it, and show it in Sources and rights. |

## 2. What we should *not* do: replace the bundled text with the live API

The bundled Tanzil file is the app's guarantee: it works offline, is checked by size and fingerprint, and is parsed strictly
(114 suras, 6236 verses). Replacing it with live calls would lose all three, make the reader depend on someone else's server and
licence, and send every reader's IP address to a third party (against the app's privacy position: privacy manifest,
"Delete all my data"). **Keep `assets/quran/quran-uthmani.txt` as the only source of the verse text.**

## 3. Where it can help (in this order)

| # | Feature | Source | Needs |
|---|---|---|---|
| A | **Mushaf structure**: page numbers (1–604), juz and hizb strips, sajdah marks, "go to page / juz" | The same fields as above, exported **once** at build time into a small bundled file (about 6236 rows, under 100 KB), checked by a test against the Tanzil file | Permission if commercial. **Alternative with no new party:** Tanzil's own `quran-data` metadata (same site and licence as our text). Owner downloads it, as with the text. |
| B | **Translations** (English first) | Downloaded per edition, stored in the local database, shown under the verse, off by default | Edition licence and credit checked one by one; owner reviews every shown edition; one new flag |
| C | **Tafsir** | Same as B, per edition | Same as B; plus a note in the UI that tafsir is a scholar's commentary, with author and edition shown |
| D | **Audio recitation** | Streamed from the edition's audio URL | New audio dependency (needs approval), reciter licence, Play and App Store background-audio rules |
| E | Search, similar verses, themes | Not needed: search already runs on the device | — |

Recommendation: do **A** first, from Tanzil's metadata if QuranHub's licence is a problem. It gives the reader what the owner's
page screenshot has and the app lacks (page number at the foot, juz strip at the head), with no network at run time.

## 4. Design (when approved)

- **Domain:** `QuranStructure` (verse → page, juz, hizb quarter, sajdah) and `QuranEditionSource` (list, fetch one sura). Pure Dart,
  no Flutter. `QuranText` and `QuranSource` stay untouched.
- **Data:** `BundledQuranStructure` reads the exported asset; a test fails if any verse is missing, out of order or maps to a
  page outside 1–604, or if the counts differ from the Tanzil file. Editions (B, C) use `dio` (already a dependency) behind a
  repository, cached in the existing SQLite database, with timeouts, no retries on 4xx, and a clear offline state.
- **Presentation:** the reader reads page and juz from `QuranStructure`; the page footer shows the number; the header strip shows
  the juz. Translation and tafsir appear only when the reader chooses an edition, under a `quranEditions` flag that is off in
  releases until reviewed.
- **Privacy and store:** any network call needs a line in the privacy policy, the Play Data safety form and the iOS privacy
  manifest; edition downloads send no user identifier; one-time export (A) sends nothing at all.
- **Sources and rights page:** a credit line per edition shown, from the edition's own metadata, reviewed by the owner.

## 5. Steps and checks

1. **Owner decisions** (see §6). Nothing else starts before these.
2. **A1** export or download the structure data; **A2** parse and validate (tests as above); **A3** page footer and juz strip in the
   reader (`ui/i-mushaf-reader` already frames the page and leaves room for both); **A4** "go to page / juz".
3. **B** one translation end to end behind the flag, then more only on the owner's approval of each.
4. **C**, **D** only after B proves the pattern and the owner asks for them.

Every step: format, analyze, full test suite, screenshots in Arabic and English, light and dark, 200% text. Device checks and store
forms are reported as NOT RUN until done. No push, merge or release without approval. No verse, translation or tafsir text is
ever typed into the code or the tests; tests use placeholders.

## 6. Questions for the owner

1. Is hadeeths (or will it be) commercial: ads, subscriptions, paid? This decides whether QuranHub needs written permission.
2. Which do you want first: page numbers and juz strips (A), translations (B), tafsir (C) or audio (D)?
3. For A, may I use Tanzil's metadata (you download it) instead of QuranHub, to avoid a new party?
4. Which languages and which named translations (and tafsir) do you approve? I will not choose them for you.
5. Do you want me to write to Misraj AI (hello@misraj.ai) for permission and the terms? I will not send anything without your approval.
