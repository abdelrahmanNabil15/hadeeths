# Phase 3E — Quran: text source and font options (for the owner's decision)

Date: 2026-10-09. **Proposal only; no Quran code or data has been added.** The plan (`docs/PHASE3_PLAN.md`, 3E) requires the text source and its
licence to be settled before anything is built: Quran text must ship as a separate read-only asset, match its source exactly, and never be altered.

## What was checked

| Source | What I read | Verified from the source itself? |
|---|---|---|
| Tanzil Quran text | tanzil.net/docs/text_license | **Yes** (fetched the page) |
| Quran Foundation (quran.com) APIs | Developer terms, and the "Mushaf fonts and images" legal page | Partly: the fonts page was fetched; the developer terms only as search excerpts (dated 2026-08-10) |
| King Fahd Complex (KFGQPC) Uthmanic fonts | A third-party licence database entry and the Complex's own "producing fonts" page in search results | **No**: the Complex's own licence text was not found |
| Amiri Quran font | Not re-checked in this pass; Amiri (already bundled) is SIL OFL 1.1, and Amiri Quran is published in the same family | Needs the file's own licence checked before bundling, as was done for Amiri |

## Options

### A. Tanzil Uthmani text, bundled offline (recommended)
- **Licence (verified):** Creative Commons Attribution 3.0, "Tanzil Quran Text, Copyright (C) 2007-2021 Tanzil Project". Verbatim copies may be
  distributed and used in any application; **changing the text is not allowed**; the source must be clearly credited with **a link to tanzil.net**;
  the copyright notice must be kept with the copy.
- **Fits the plan:** a read-only asset database built from the downloaded file, unchanged; works fully offline; no API account or sync duty.
- **Integrity:** a build-time check that the bundled text is byte-identical to the downloaded file (stored checksum), plus tests for 114 suras and
  6,236 verses, verse order, and that display code never transforms the text (the same rule as hadith text today).
- **Credit:** the notice and the tanzil.net link in About and in the Quran section.
- **Owner decision needed:** which Tanzil edition (Uthmani or Simple; with or without pause marks) and which recitation script (Hafs is Tanzil's).

### B. Quran Foundation APIs (quran.com)
- Online content through an API account. The developer terms (as excerpted) limit storing content to **one week** unless it comes through their
  Content Sync APIs, which then require a sync **at least every 7 days**; security requirements apply; the licence is revocable.
- Their Mushaf font files may be bundled if the developer has an active Developer Console account and credits Quran Foundation.
- **Downside for this app:** an offline-first reader would depend on an account, regular syncing and revocable terms. Better kept for later extras
  (translations, tafsir), each with its own permission.

### C. King Fahd Complex Uthmanic (Mushaf) fonts or page images
- The Complex says it made its fonts for software and websites, but the only licence text found (a third-party record) says the font may not be
  reproduced or modified without the Complex's written approval. **Not usable without written permission**; I did not find the official terms.

## Font for the text

- **Recommended:** Amiri Quran (same family as the Amiri already used for hadith text; SIL OFL 1.1 for the family — the specific file's licence
  must be confirmed before bundling). It is designed for Quran text with full marks.
- KFGQPC fonts only with the Complex's written permission (option C).

## What I recommend

Option A with Amiri Quran: Tanzil Uthmani (Hafs) text, bundled read-only, verified byte-for-byte, credited with the required notice and link;
text mode first (index, sura reader, jump to verse, bookmarks and last-read in the user database, search with Arabic normalisation used only for
matching, never for display). Mushaf page images, audio and tafsir stay out until each has its own licence.

## Decisions needed from the owner

1. Approve option A (or choose B or C).
2. Tanzil edition: Uthmani or Simple; pause marks on or off.
3. Confirm the Amiri Quran font (I will check its licence file before adding it).
4. Where the Quran section's credit appears (About only, or also at the top of the reader).

Sources: [Tanzil text licence](https://tanzil.net/docs/text_license),
[Quran Foundation developer terms](https://api-docs.quran.foundation/legal/developer-terms/),
[Quran Foundation: Mushaf fonts and images](https://api-docs.quran.foundation/legal/mushaf-fonts-and-images/),
[ScanCode record of the KFGQPC Uthmanic Script licence](https://scancode-licensedb.aboutcode.org/kfgqpc-uthmanic-script-hafs.html),
[King Fahd Complex: producing fonts](https://qurancomplex.gov.sa/en/?p=421).
