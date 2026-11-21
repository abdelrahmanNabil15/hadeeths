# Plan: refactor the Quran section onto the Quran Foundation Content API, with new features and a new reading layout

Status: **the backend proxy (§2) is deployed; Phase A (§4.1/§8) is built and tested; §5's domain/data layer is built
and tested; flags B and C (translations and tafsir, §3/§8) are built and tested end to end.** Owner decision (§7.4):
every edition stays selectable, nothing curated. Flags D–F (audio, search, qira'at) are not started. Written
2026-10-17, after reading the current
`lib/features/quran/**` code, `docs/QURAN_SOURCE_OPTIONS.md`, `docs/QURANHUB_PLAN.md`, `docs/UI_MODERNIZATION_PLAN.md`,
`docs/ARCHITECTURE.md`, and, in full, the Quran Foundation documentation portal (`api-docs.quran.foundation`:
Manual Authentication, Token Management, First API Call, and the Content API reference) — the auth flow, headers and
URLs in §2 are **confirmed from those pages**, not inferred, and the proxy built from them is live and has been
exercised end to end against the real API.

**Owner's two live decisions on record, both already acted on:** (1) the proxy host is **Cloudflare Workers**, not
Firebase Cloud Functions — Firebase's free Spark plan blocks outbound calls to third-party APIs (would need the paid
Blaze plan; the owner said no paid plan), while Workers' free tier allows them with no card on file. (2) the owner
supplied real prelive and production Quran Foundation client id/secret pairs in chat; both secrets were pushed
straight into Cloudflare's secret store and never written to any file in this repository (verified: `git status`
shows no secret material tracked or staged). If this conversation's transcript is ever stored or shared somewhere
the owner isn't fully comfortable with, rotating both secrets in the Quran Foundation Developer Console is cheap
insurance, independent of anything above.

## 0. What exists today (so this plan only describes the delta)

- **Text:** `assets/quran/quran-uthmani.txt`, Tanzil Uthmani (CC BY 3.0), bundled, checked byte-for-byte, parsed
  strictly (114 suras, 6,236 verses). This is the only source of verse text (`docs/ARCHITECTURE.md`, "Quran (Phase 3E)").
- **Structure:** `QuranStructure.madinah` (page/juz, pure Dart, no network).
- **Reader:** `SuraReaderPage` — a Mushaf, page by page, swipe to turn, verses run on as one justified RTL paragraph,
  sura banners, page-number pill. Fitted to the screen at the default size; scrolls at larger text sizes.
- **Other screens:** index (`QuranPage`: continue reading, search, bookmarks, go-to-verse, sura list), search
  (`QuranSearchPage`, on-device, Arabic-normalised), bookmarks (`QuranBookmarksPage`).
- **User data:** positions only (`quran_last_read`, `quran_bookmarks`, migration 5 of the user database) — **no Quran
  text or metadata is ever stored in the user's data**; that rule is load-bearing for the privacy position and must
  survive this refactor.
- **Two prior decisions already on record, which this plan keeps:**
  1. *(`QURAN_SOURCE_OPTIONS.md`)* the bundled Tanzil text is the one and only source of verse text; nothing online
     replaces it.
  2. *(`QURANHUB_PLAN.md`, §2)* "do not replace the bundled text with live API calls" — offline guarantee, no
     per-reader network dependency, no sending readers' IPs to a third party at run time just to show the Quran.
  This plan does not reopen either decision. The Quran Foundation API is additive: translations, tafsir, audio,
  search and qira'at variants, never the Arabic verse text itself.

## 1. What the new API actually is, and the one hard architectural problem it creates

`https://api-docs.quran.foundation` is **Quran Foundation's (quran.com) Content API v4**, `/content/api/v4/...`,
already evaluated once before as "Option B" in `docs/QURAN_SOURCE_OPTIONS.md` and flagged there as "better kept for
later extras (translations, tafsir), each with its own permission" — that later point is now.

What it adds over what we have: translations (dozens of editions, many languages), tafsir editions, audio
recitation files per reciter, chapter/verse metadata, qira'at (recitation-variant) text, and server-side search —
all of it content we do not have today and cannot license-check or host ourselves at the scale of "dozens of
editions."

**The hard problem:** authentication is **OAuth 2.0, `client_credentials` grant**, with a client id and a **client
secret**, exchanged for a bearer token that then rides as `x-auth-token` / `x-client-id` headers on every content
call. A client secret embedded in a Flutter app (Android or iOS) can be extracted from the compiled binary;
`client_credentials` is designed for server-to-server calls, not for shipping inside an app — the documentation
says this explicitly ("Server-Only Rule": do not call the token endpoint from browser or mobile code). **This app
must not call `/content/api/v4/...` directly from the device.** It needs a small backend in front of it that holds
the secret and that the app calls instead.

This is a real, new piece of infrastructure, not a library choice, so it was the first owner decision (§7.1) — now
resolved and built (§2).

## 2. The proxy: built and deployed on Cloudflare Workers

**Status: live.** `https://hadeeths-quran-proxy.naabdo198.workers.dev` — deployed 2026-10-17, verified end to end
(`GET /prelive/chapters` returns real chapter data from Quran Foundation's prelive environment). Code lives in
`cloudflare-worker/` at the repo root (sibling to the Flutter app, not inside `lib/`, since it is a separate
deployable with its own `package.json`/`wrangler.toml`).

**Why Cloudflare Workers and not Firebase Cloud Functions**, despite `firebase_core` already being a dependency:
Firebase's free (Spark) plan only allows Cloud Functions to call Google's own APIs; calling a third-party API like
Quran Foundation's needs the paid Blaze plan. The owner asked for a free option, so the proxy runs on Cloudflare
Workers instead — free tier, 100,000 requests/day, no card on file, and outbound `fetch()` to any host is allowed
from the start. If a future load is bigger than the free tier allows, migrating this same logic to Firebase
Functions (Blaze) or elsewhere is a small, isolated change — nothing in the app talks to Cloudflare specifically,
only to "the proxy's base URL."

**Confirmed from `api-docs.quran.foundation`, read in full this session (not inferred):**

| | prelive | production |
|---|---|---|
| Auth base URL | `https://prelive-oauth2.quran.foundation` | `https://oauth2.quran.foundation` |
| API base URL | `https://apis-prelive.quran.foundation/content/api/v4` | `https://apis.quran.foundation/content/api/v4` |
| Content | Al-Fatihah and Al-Baqarah only (testing) | full Quran |

- **Token request:** `POST {authBaseUrl}/oauth2/token`, HTTP Basic auth (`client_id:client_secret`),
  `Content-Type: application/x-www-form-urlencoded`, body `grant_type=client_credentials&scope=content`. Response:
  `access_token`, `token_type`, `expires_in` (3600 seconds); **no `refresh_token`** for this grant — a new token is
  requested the same way each time one is needed.
- **Content requests:** every call needs both `x-auth-token` (the bearer token) and `x-client-id` headers.
- **A custom `User-Agent` header is required** — the API 403s a request with Python's default urllib User-Agent
  (and likely other default agents) as an anti-bot measure ("error code: 1010"); the proxy sends its own.
- **Token lifecycle, exactly as documented:** cache the token and reuse it until ~30 seconds before `expires_in`
  elapses; on a 401, clear the cache, fetch once more, retry the failed call once, never loop; never mix the
  prelive and production token caches; one in-flight token request at a time (stampede prevention) so concurrent
  calls don't all re-fetch together. `cloudflare-worker/src/index.ts` implements all of this.

**What the proxy actually exposes** (allow-listed, not an open relay): `GET /healthz`; then, under `/prelive/...` or
`/production/...`: `chapters`, `chapters/:id`, `editions/translations`, `editions/tafsirs`, `editions/recitations`,
`translations/:resourceId/ayah/:verseKey`, `tafsirs/:resourceId/ayah/:verseKey`,
`recitations/:recitationId/ayah/:verseKey`. It adds nothing of its own (no user accounts, no analytics, no logging
of what a reader looked up beyond an error message on failure).

- **The app's `dio` client** (already a dependency) will call this proxy over HTTPS, the same shape as the existing
  `HadeethClient` (`core/network/`): timeouts, limited retries, `Failure`/`Result` mapping. No OAuth code, no secret,
  ever ships in the Flutter binary. **This part is not built yet** — see §5.
- **Caching reuses what exists.** `core/cache/` (`ResponseCache`, `CachedFetcher`) already implements exactly the
  "read-through, fall back to an older copy offline" policy the hadith side uses. The Quran Foundation developer
  terms (as summarised on the page the owner linked — **re-confirm the exact wording in the Developer Console before
  shipping**) limit storing their content to about a week unless using their Content Sync API with a sync at least
  every 7 days. So: cache translations/tafsir/audio metadata with a **freshness policy capped at 7 days**, same
  mechanism as `CachedFetcher.fresh`, no exception. Audio files themselves are *streamed*, not stored (no
  download/offline-audio feature in this plan — that would be a further, separate decision).

**Not yet done to the proxy itself, worth closing before real app traffic hits it at scale:** it currently has no
check that the caller is the real app (anyone who finds the URL can call it and spend the free-tier quota) — a
shared-secret header or similar is a cheap follow-up, noted in the code as a `TODO`. Wrangler itself is on an
outdated major version (3.x; 4.x is current) — works today, flagged for a routine upgrade later, not urgent.
- **New domain contracts**, kept pure per `docs/ARCHITECTURE.md`'s layering (`domain` knows no Dio, no Flutter):
  `TranslationEdition`, `TafsirEdition`, `Reciter`, `QuranContentApi` (interface: `editions()`, `translation(edition,
  verse)`, `tafsir(edition, verse)`, `audioUrl(reciter, verse-or-sura)`, `search(query, editions)`), implemented in
  `features/quran/data/` against the proxy, behind the existing `QuranSource`-style error handling
  (`QuranUnavailable`-shaped failures, not a crash, not a silent empty screen).

## 3. New features this unlocks, in the order I'd build and ship them

Each one is its own flag (`FeatureFlags`-style, off until reviewed — same convention as `adhanSounds` and
`inAppReview` today), so partial progress never reaches a release half-done.

| # | Feature | What it needs | Risk / owner decision |
|---|---|---|---|
| A | **Reading-mode layout** (see §4) — verse-by-verse view beside the existing Mushaf view | Nothing new: uses only the bundled text and structure already in the app | Lowest risk; no network, no licence question; can ship **before** the API work starts |
| B | **Translations** | The proxy (§2); one edition shown under the verse, off by default; edition picker in reader settings | Owner approves the proxy + picks which edition(s) to launch with (I will not choose a translation for the owner, per the existing house rule in `QURANHUB_PLAN.md` §6.4) |
| C | **Tafsir** | Same proxy, a `TafsirEdition`; shown as a bottom sheet per verse, with author/edition credited, and an explicit note that it is a scholar's interpretation, not scripture | Same approval pattern as B |
| D | **Audio recitation** | Same proxy for the file URL; `just_audio` (already a dependency, used today for adhan sounds) for playback; a mini player docked above the page-number pill | Reciter licence/attribution check per reciter; background-audio entitlement on iOS; Play/App Store background-audio rules; **bigger scope — do this last** |
| E | **Server-side search across translations** | Same proxy's `search` | On-device Arabic search already exists for the verse text; this is additive (search *inside* a chosen translation), not a replacement |
| F | **Qira'at (recitation-variant) text** | Same proxy | Niche; only after B–D are live and reviewed; needs its own licence/credit line per variant, same as every other edition |

Not proposed: anything that invents content (a "verse of the day" pick, a recommendation engine, user-visible
"popularity") — consistent with the existing house rule against fabricated curation (`UX_REDESIGN_PROPOSAL.md` §5).

## 4. New style and layout for the reader

**Reference check (2026-10-17):** at the owner's pointer, I opened `quran.com/al-baqarah?startingVerse=36` itself (read-only,
in the sandboxed browser) to see how the site this API belongs to actually lays its own reader out, rather than guess. What
it does, concretely:

- **Two top-level modes**, a segmented control in the app bar: **Verse by Verse** and **Reading**. Confirms this plan's own
  split (§4.1) is the right shape, not a novel idea.
- **Verse by Verse**: each verse is a light block, *not* a bordered card — verse number, a play icon and a bookmark icon on
  one line; the Arabic line; the translation paragraph under it with superscript footnote markers; then a thin row of
  **per-verse secondary actions** (their site: Tafsirs / Lessons / Reflections / Answers, each a small icon + label) before a
  plain divider to the next verse. This settles the "full `AppCard` per verse vs a flowing block" question left open in the
  first draft of this section: **a flowing block with a thin action row, not a full card per verse** — lighter over a
  286-verse sura, and it gives tafsir (flag C) a natural, proven home (one small icon per verse, not a new motif). Lessons,
  Reflections and Answers are quran.com's own curated/community content; nothing in this plan proposes building those.
- **Reading mode**: a sura-info header card first (name, English name, verse count, revelation place, a short description,
  **Listen** and **Info** buttons, an Arabic/Translation toggle), then the continuous justified Arabic paragraph, small
  circled verse numbers inline, a centred page number at each page break, "Next Surah" and "Tafsir of Surah X" links at the
  end. This is, in shape, what `SuraReaderPage`/`_MushafPageView` already does; it mainly confirms §4.5 (sura header
  enrichment) directly rather than changing it. One nuance worth recording: the site has a *second*, visually distinct
  reading mode behind the query param `readingMode=arabic`, which renders with a Mushaf **page-image glyph font** (each line
  its own pre-shaped glyph run, matching a printed Mushaf pixel-for-pixel) rather than ordinary shaped Arabic text — this is
  the King Fahd Complex (KFGQPC) font style already evaluated and **rejected** in `docs/QURAN_SOURCE_OPTIONS.md` ("not usable
  without written permission"). The plain justified mode (Amiri-style, ordinary Unicode text) is the one this app already
  uses and the one this plan continues to use; the glyph-exact mode is noted here only so it is not mistaken for "what
  quran.com does" wholesale and accidentally re-proposed later.
- **Audio**: tapping Listen docks a persistent bottom bar — play/pause, previous/next verse, a repeat control, elapsed and
  remaining time, an overflow ("…") menu, and a close button. This matches §4.3's mini-player and fills in its detail: the
  transport controls to include are play/pause, prev/next **verse** (not just prev/next sura), and an explicit close, so the
  player never lingers once the reader is done with it.
- **Settings panel**: three tabs — **Arabic** (script variant, font style, font size stepper, selected reciter), **Translation**
  (a "Selected Translations" picker that opens a searchable, checkbox, language-grouped list — **multiple translations at
  once is a supported, real pattern**, not just one edition at a time), **Word by Word**. Confirms §4.2's reader-settings
  sheet; refine it to **tabbed sections with independent font-size steppers** per content type (Arabic size and translation
  size are genuinely different reading needs) rather than one flat list, and allow more than one translation edition to be
  selected at once if the owner approves more than one launch edition (§7.4).

None of the above changes the plan's substance (§§1–3, 5–8 stand); it sharpens §4's open questions with a working precedent
instead of leaving them as "tested both ways on a device."

### 4a. The Mushaf page itself, not only verse-by-verse (research via the connected quran.ai tool)

The owner's follow-up was specific: the above covers the *new* verse-by-verse mode well, but what does "best layout" mean
for the **existing Mushaf page view**, which this plan must not regress? A `quran.ai` MCP tool happens to be connected to
this coding session (separate from the app — it is a Claude-side research aid, not something `hadeeths` calls at runtime).
Its `interactive_study` reader-opening call was used once, read-only, to inspect the *data shape* behind a real Mushaf-page
renderer (opened at Al-Baqarah 1–5; no verse text is reproduced here, per this repo's standing rule). What it returned:

- A Mushaf page is not "verses reflowed into a paragraph." It is **lines**, each a fixed, numbered sequence of **words**,
  each word carrying `line_number`, `position_in_line`, `position_in_verse`, and a `verse_key` back-reference. A sura
  banner is positioned by `appears_before_line`, not just "at the top of a verse." This is the actual data model a
  print-identical Mushaf needs: **where every word sits is baked into the data, not computed by the text engine at
  runtime.**
- The word glyphs themselves come from **QCF V2** (Quran Complex Font v2) — the same King Fahd Complex font family this
  repo already evaluated and **rejected without written permission** (`docs/QURAN_SOURCE_OPTIONS.md`, option C). So the
  exact rendering quran.ai's and quran.com's `readingMode=arabic` both use is reached the same way: licensed glyphs keyed
  to a pre-computed line layout. That half (the font) stays blocked, unchanged from the earlier decision.
- **What is genuinely new here is the other half: the line-layout data (which word sits on which line of which of the 604
  pages) is, in principle, separable from the glyph font.** If the Quran Foundation API exposes that layout as plain
  coordinates (word → page/line/position) rather than as rendered glyphs — this needs verification in the Developer
  Console, it was not confirmed in this pass — it could be paired with the **already-licensed Amiri Quran text and font**
  this app already bundles, to lay out *our* Arabic text on the *same* line breaks as a real printed Mushaf, without ever
  touching the King Fahd Complex font. That would be a genuine upgrade over today's reflowed paragraph (whose line breaks
  shift with screen width and font size, and never match a specific print edition). **This is a research item, not a
  decision**: it needs (a) confirming the layout coordinates and the glyph font are licensed separately by Quran
  Foundation, and (b) confirming Amiri Quran's own letter widths/kerning can be coaxed onto someone else's precomputed
  line breaks without ugly justification artifacts — a real typographic risk, worth a short spike before committing to it.

**What this means concretely for `SuraReaderPage` today:**

| Option | What it is | Status |
|---|---|---|
| **Current (shipped)** | Verses reflow into a justified RTL paragraph at the chosen text size; "page" means "however many verses fit," not a specific print edition's page | Keeps working as is; this plan's flags A–F do not touch it |
| **True line-exact Mushaf, licensed glyphs** | QCF V2 (or KFGQPC) font, pixel-identical to a printed Mushaf | **Blocked**, same as `QURAN_SOURCE_OPTIONS.md` option C; not proposed |
| **Line-exact layout, our own font** | Amiri Quran text, reflowed to match a real Mushaf edition's line breaks using the API's layout coordinates (if licensed separately) | **New idea from this research — investigate, do not build yet.** Would be its own flag and its own licence check, after B–D land, since it changes the one screen (`SuraReaderPage`) every existing Quran test already covers and must not regress |

Until that investigation is done, the honest, shippable position is: the current reflowed Mushaf view stays the default
and is not claimed to be page-identical to any specific print edition (it already does not claim this); the verse-by-verse
mode (§4.1–§4.3) is the new layout this plan actually delivers; "true" page-for-page fidelity is logged here as a
researched-but-gated idea for a later, separate decision, not folded into flags A–F.

The rest of the app already has a settled visual system (`docs/ARCHITECTURE.md`, "Luxury revamp"): warm ivory /
midnight-emerald / charcoal / sage / muted-gold, `AppCard`, `GeometricPattern`, `OrnamentDivider`, `showOptionsSheet`,
editorial Amiri titles. The Quran reader already uses pieces of it (gold-edged page-number pill, star-flanked sura
banner, `ContentWidth`, `AppColors.readingSurface`). **This plan extends that system to the reader; it does not
invent a second one.**

1. **Reading-mode toggle** (new, flag A above, no API dependency): keep the current Mushaf page view as the default
   (it is the thing that currently makes the reader feel like a printed Quran, and nothing here should regress
   that). Add a second mode, **verse-by-verse**, for readers who want to study rather than page through:
   - A flowing block per verse (not a full `AppCard` each — settled by the reference check above), separated by a
     thin `OrnamentDivider`, with a small per-verse action row for tafsir (flag C) once it exists.
   - Arabic in Amiri Quran at the reading size, right-to-left, exactly as the Mushaf view (same `quranTextStyle`,
     same "never transform the source text" rule).
   - When a translation/tafsir edition is chosen (flags B/C), it appears directly under the verse in the UI
     language's own font (Cairo), in `AppColors.readingSurface`-toned secondary text, clearly separated (never
     interleaved with or styled to look like the Arabic).
   - Verse number stays the existing gold rosette marker (`verse_marker.dart`), not a new motif.
   - The toggle itself lives in the reader's app bar, next to the juz indicator already there, and is a saved
     preference (`SettingsCubit`-style, not the user database — it is a display preference, not content).
2. **Reader settings sheet** (`showOptionsSheet`, the same component every other options sheet in the app already
   uses): translation edition, tafsir edition, reciter, reading mode, Arabic script variant if ever offered
   (Uthmani only for now — no new script without its own licence check, per `QURAN_SOURCE_OPTIONS.md`). One sheet,
   reached from a settings icon in the reader's app bar; nothing changes until the reader opens it, matching the
   house rule that a settings panel never silently changes state on its own (the connected Quran MCP tool used
   while writing this plan documents the same rule for its own `reader_settings` call — not something this app
   calls at runtime, but a convention worth keeping either way).
3. **Audio mini-player** (flag D, later): a slim bar above the page-number pill, play/pause, reciter name, a close
   control; disappears completely when no reciter is selected; never autoplays on opening a sura.
4. **Tafsir sheet** (flag C): long-press or a small "ت" / commentary icon beside the verse marker opens a bottom
   sheet (`AppSheet`) with the tafsir text, author, and edition name — same credit pattern as the hadith
   "Sources and rights" screen.
5. **Sura header enrichment**: the existing `_SuraBanner` gains, when metadata is available (from the proxy's
   chapter endpoint, cached under the same 7-day policy — this is metadata, not the verse text, so it is not bound
   by the "never replace the bundled text" rule), the Makki/Madani badge and verse count already shown elsewhere in
   the index, now also at the point of reading. Nothing about the banner's current look changes beyond that.

Everything above is additive to `SuraReaderPage`/`_MushafPageView`; the Mushaf view's current behaviour (fit to
screen at default size, scroll at larger sizes, bookmarks by long-press, basmala handling, RTL-always-for-Quran-text)
is not touched by flags B–F and must still pass the existing tests (`quran_structure_test.dart`,
`verse_flow_test.dart`, `quran_font_test.dart`, etc.) unchanged.

## 5. Domain/data/presentation split (keeps `test/architecture_test.dart` green)

**Status: domain and data built and tested, 2026-10-17 (presentation — the cubit and the new widgets — is not; that
lands with flags B/C/D, which need the owner's edition choices from §7.4 first).** Built, against the shapes
confirmed live from the deployed proxy (§2):

```text
core/network/
  quran_content_endpoints.dart    the proxy's base URL and paths (editions, per-ayah content)
  quran_content_client.dart       QuranContentClient: same timeout/retry/Failure-mapping shape as HadeethClient,
                                   its own base URL (the Cloudflare Worker, not Quran Foundation directly)
features/quran/
  domain/
    quran_editions.dart           TranslationEdition, TafsirEdition, Reciter (plain data, no Flutter/Dio)
    quran_content_repository.dart QuranContentRepository: translationEditions(), tafsirEditions(), reciters(),
                                   translation(), tafsir(), recitationAudioUrl() -- all Future<Result<T>>,
                                   VerseRef reused from quran_user_data.dart rather than inventing a second type
  data/
    quran_content_dtos.dart              DTOs + parsers for both the edition lists and the per-ayah content
    quran_content_remote_data_source.dart HTTP source, one CachedFetcher policy per content type (30-day fresh;
                                          translations/tafsir/audio-url mappings don't change once published)
    quran_content_repository_impl.dart    maps DTOs to domain entities, wraps in Result.guard
```

Wired into `AppDependencies.live()` next to the existing `HadeethClient`/hadith wiring, sharing the same
`CachedFetcher`/cache instance (the two proxies' paths never collide) — `AppDependencies.quranContent`, `null`-able
like the other repositories tests don't exercise. No feature flag yet: nothing in the presentation layer calls it,
so there is nothing to gate.

**Not done (deliberately, per §7.4):** no UI reads from this yet, and no edition is picked as a default — that
needs the owner's choice of which translations/tafsir/reciters to launch with, same rule as every other edition
decision in this repo. What *is* usable today, read-only: fetching the live lists themselves (`translationEditions()`,
`tafsirEditions()`, `reciters()`) to present to the owner for that choice.

**Tests:** `test/core/network/quran_content_client_test.dart` (error mapping, retries — mirrors
`hadeeth_client_test.dart`) and `test/features/quran/quran_content_data_test.dart` (DTO parsing against structural
fixtures, protocol-relative audio URLs normalised to `https`, repository Result mapping). Fixtures use placeholder
text only, never real translation/tafsir content, per the standing rule. Full suite: 1,430 tests pass;
`test/architecture_test.dart` passes unchanged, confirming the new files respect the domain/data/presentation
layering. `flutter analyze` clean.

## 6. Testing and verification (same bar as every other phase in this repo)

- `dart format`, `flutter analyze`, full `flutter test` suite green at every step; nothing above touches the
  Mushaf-view-unchanged tests.
- New tests: DTO parsing for each new edition type (fixtures only — **no real translation, tafsir or verse text is
  ever typed into code or tests**, same rule as the hadith and existing Quran tests); cubit tests with a fake
  `QuranContentApi`; a test that the Arabic verse text rendered in verse-by-verse mode is byte-identical to Mushaf
  mode (same source, two layouts); RTL/LTR, light/dark, 130%/200% text, both languages, for every new widget; a test
  that the audio mini-player never calls `play()` on building; a test that the 7-day cache cap is enforced.
- Screenshots: the reader in both new modes, with and without a translation/tafsir chosen, light and dark, Arabic
  and English UI.
- Device checks and the proxy's real network behaviour are reported as **NOT RUN** until actually done, same honesty
  convention as every other doc in this folder.
- No push, merge or release without the owner's approval, per the standing rule.

## 7. Owner decisions needed before any of this starts

1. ~~**Approve standing up a backend proxy**~~ **Done (2026-10-17).** Host is Cloudflare Workers, free tier (owner
   declined a paid plan); see §2 for the live URL and what it does.
2. ~~**Apply for a Quran Foundation developer/API account**~~ **Done.** The owner already holds prelive and
   production credentials and supplied them directly; both are now in Cloudflare's secret store, never in this repo.
3. **Commercial status** — the same question as `QURANHUB_PLAN.md` §6.1 (is hadeeths commercial: ads, subscriptions,
   paid?) applies again here; it decides which parts of Quran Foundation's terms govern us. Re-read their developer
   terms in full (the OAuth2 sub-page did not load in this pass) before committing to the proxy design.
4. ~~**Which translations, tafsir editions and reciters** to launch with~~ **Decided, 2026-10-17: all of them.**
   The owner chose not to curate: every edition and reciter the live API returns stays selectable, nothing excluded.
   Fetched and shown to the owner for this decision (production, 2026-10-17): 8 English translations (Saheeh
   International, Pickthall, Yusuf Ali, Abdel Haleem, Al-Hilali & Khan, Taqi Usmani, Maududi's Tafhim, a
   transliteration) of 145 across all languages; 3 English + 9 Arabic tafsirs of 23 total; all 12 reciters. Because
   nothing is curated, the UI needs a searchable picker (145 translations is too many for a plain list), not a short
   fixed menu — see §8.
5. **Order of features**: this plan's default order is A (layout) → B (translations) → C (tafsir) → E (search) → D
   (audio) → F (qira'at), because A ships with zero legal/infra risk and D is the largest scope. Confirm or reorder.
6. **Audio download/offline** is explicitly out of scope for this plan (streaming only); say if offline audio is
   wanted, since it is a materially different (and larger) feature with its own storage and licensing questions.
7. **The line-exact Mushaf layout research item (§4a)** — say whether it is worth a short spike (confirm with Quran
   Foundation whether line-layout coordinates are licensed separately from their glyph font, then a quick visual test
   of Amiri Quran reflowed onto those coordinates) once B–D are stable, or whether the current reflowed Mushaf view is
   good enough and this should simply be dropped. Either answer is fine; it is not required for anything else in this
   plan to proceed.

## 8. What's next

The proxy (§2) is live. **Phase A (reading-mode layout, §4.1) is also done, 2026-10-17:**

- `AppSettings.quranReadingMode` (`QuranReadingMode.mushaf` | `.verseByVerse`), persisted via
  `SettingsRepositoryImpl`/`SettingsCubit.setQuranReadingMode`, same pattern as `readingScale`.
- `SuraReaderPage` now branches on it: the existing Mushaf `PageView` is unchanged (every pre-existing Quran test
  still passes, unmodified); a new `_VerseByVerseView` shows the open sura's verses as flowing blocks separated by
  `OrnamentDivider`, each block reusing `VerseFlow` one verse at a time — same font, same bookmark/long-press
  behaviour, same "never transform the source text" rule as the mushaf view, per §4.1's design.
- A `SegmentedButton<QuranReadingMode>` in the reader's app bar (next to the juz indicator, as the plan specified)
  switches modes; switching is bidirectional and keeps position: verse-by-verse always opens at the sura's current
  `lastRead` verse, and switching back to mushaf jumps the page view to match via the same path a swipe already uses
  and already has tests for.
- Verse-by-verse tracks reading position by finding the verse nearest the top of the viewport on scroll-end and
  calling the same `QuranCubit.setLastRead` the mushaf view uses, so "continue reading" works from either mode.
- New tests: `test/app/quran_reading_mode_test.dart` (7 tests — default mode, switching both directions, persistence,
  RTL, bookmarking, 200% text). Full suite: 1,413 tests pass; `flutter analyze` clean (one pre-existing, unrelated
  warning in `reminder_coordinator.dart`); `dart format` clean on every file this session touched.
- **Known, deliberate scope limit:** verse-by-verse shows only the sura the reader was opened on — no scrolling into
  the next sura. Matches §4.1's description; extending it is a follow-up, not a bug.
- Not yet connected to flags B/C (translations/tafsir would appear under each verse block and in a per-verse action
  row): both are explicitly deferred in §4.1 until those flags exist.

**§5's domain/data layer is also done, 2026-10-17** (see §5 for the full file list and test report):
`QuranContentClient`, `QuranContentRepository`/`Impl`, DTOs and a remote data source for translation/tafsir/reciter
editions and per-ayah content, wired into `AppDependencies.live()`. All field shapes were confirmed live against the
deployed proxy, not guessed. 17 new tests, full suite 1,430 passing, `flutter analyze` clean.

**Flag B (translations) is also done, 2026-10-17.** The owner's §7.4 decision was "all" -- no curation -- so the
design had to support picking from the full live catalogue (145 translations across every language), not a short
fixed menu:

- New flag `FeatureFlags.quranTranslations` (off by default, same convention as `adhanSounds`/`inAppReview`): nothing
  changes for a user until this is turned on. `AppDependencies.quranContentIfEnabled` gates the repository by it, the
  same pattern as `favoritesIfEnabled`/`dailyHadithIfEnabled`.
- `quranContent` (the `QuranContentRepository`) is threaded the same explicit-constructor-parameter way `quran`/
  `quranUserData` already were: `AppDependencies` → `app.dart` → `AppShell` → `QuranPage` → `QuranCubit`
  (`QuranCubit.content`) → `SuraReaderPage` (reads `context.read<QuranCubit>().content` to decide whether to build a
  local `QuranContentCubit` at all). No global `RepositoryProvider`; nothing reaches the reader when the flag is off.
- `QuranContentCubit` (new): loads the edition list on demand (opening the picker), and fetches+caches per-verse
  translation text, keyed by `"editionId:sura:verse"` so switching editions never shows the wrong text while the new
  one loads. A verse's fetch failure is silent (the block stays empty) -- a supplement to reading, not something an
  error banner should interrupt it for; the edition-list fetch, which the owner is actively looking at, does get a
  real `ErrorView` with retry.
- `TranslationEditionPickerPage` (new): a searchable list (145 entries is too many to show unfiltered), defaulting to
  the interface's own language (English or Arabic) before anything is typed, matching by name/author/language once
  something is. A "No translation" row clears the choice.
- `TranslationBlock` (new): shown under each verse in verse-by-verse mode only (not Mushaf, which stays a pure
  printed page, matching the plan's own §4.1 wording of "an edition is chosen", singular -- this ships the simplest
  version; several translations shown at once, as quran.com's own picker supports, is a documented follow-up, not
  done here). Every shown translation carries its edition's name as a credit line underneath -- the same
  "every shown edition is credited" rule the hadith and font sources already follow in this app.
- The choice persists (`AppSettings.quranTranslationEditionId` + `quranTranslationEditionName`, the name saved
  alongside the id so the credit line never needs the edition list reloaded just to display it) and survives
  switching reading modes and reopening the reader, the same way `quranReadingMode` does.
- New tests: `test/features/quran/quran_content_cubit_test.dart` (8 — edition loading, failure/retry, per-verse
  caching, edition-vs-edition isolation, silent fetch failure) and `test/app/quran_translations_test.dart` (6 — flag
  off, flag on with no repository, full choose-and-display flow with credit lines, clearing the choice, search
  filtering, error-and-retry). Full suite: **1,444 tests pass**; `flutter analyze` clean; `dart format` clean.

**Flag C (tafsir) is also done, 2026-10-17.** Deliberately shaped differently from translations, not copy-pasted:
tafsir is commentary, often thousands of words per verse (al-Tabari averages ~2,800 tokens an entry) — showing it
inline under every verse the way a ~30-word translation is shown would be unreadable. Instead:

- `FeatureFlags.quranTafsir`, independent of `quranTranslations` (either can be on without the other; confirmed by
  test). `AppDependencies.quranContentIfEnabled` now gates the repository's availability on *either* flag, and
  `FeatureFlags` itself is threaded down to `SuraReaderPage` (via `QuranCubit.features`, reusing `AppShell`'s own
  already-in-scope `features`) so the reader can gate each entry point separately.
- Reachable from **both** layouts, not just verse-by-verse: an app-bar "Tafsir" button (present in Mushaf too, since
  an on-demand sheet doesn't disturb the printed-page purity translations respect) opens the same kind of searchable
  picker as translations (`TafsirEditionPickerPage`; the near-duplicate tile UI was factored out into a shared
  `EditionTile` widget rather than copy-pasted). Once an edition is chosen, every verse's existing long-press menu
  (until now bookmark-only) gains a "Read the tafsir" option.
- Tapping it opens a resizable, scrollable bottom sheet (`showTafsirSheet`/`DraggableScrollableSheet`, since tafsir
  text can be very long) showing the commentary, a disclaimer that it is "a scholar's interpretation, not the Quran
  itself" (the explicit requirement from `docs/QURANHUB_PLAN.md`'s item C), and the edition's credit line.
- Unlike a translation (ambient, silent on failure), the sheet is open because the reader explicitly asked for it,
  so a fetch failure shows the same typed `ErrorView`/retry the rest of the app uses, not silence —
  `QuranContentCubit` tracks the real `Failure` per verse (`tafsirFailureFor`/`retryTafsir`), not just a flag.
- The choice persists the same way (`AppSettings.quranTafsirEditionId`/`Name`).
- New tests: 7 more cubit tests (edition loading/failure, per-verse fetch/cache, failure-not-silent, explicit retry)
  and `test/app/quran_tafsir_test.dart` (8 — flag gating independent of translations, works in both layouts, no
  action without a chosen edition, full read-and-display flow with disclaimer and credit, sheet error/retry, edition
  list error/retry). Full suite: **1,459 tests pass**; `flutter analyze` clean; `dart format` clean.

**Flag E (search) is built but blocked on an account-level step, 2026-10-17.** The Quran Foundation Search API
(`api-docs.quran.foundation`, Search APIs section) is a separate product from the Content API used by A/B/C: its
own base URL (`https://apis-prelive.quran.foundation/search` / `https://apis.quran.foundation/search`) and its own
OAuth scope (`search`, not `content`). Per §3's framing ("search *inside* a chosen translation", additive to the
always-on on-device Arabic search, not a replacement):

- The Cloudflare Worker (§2) now caches OAuth tokens per `(environment, scope)` pair, not just per environment, and
  adds `GET /:env/search?query=&translation_ids=&page=`, fixed server-side to the Search API's advanced mode with
  `get_text=1`/`highlight=0` (the app never sees `mode` or raw highlight markup — this route only ever does the one
  kind of search).
- **Blocked:** live-testing the deployed route (`curl .../production/search?query=mercy&translation_ids=131`) gets
  `HTTP 502` from the proxy; `wrangler tail` shows the real cause is the *token* request failing with `HTTP 400` for
  `scope=search`. The existing client credentials (§7.2) were registered for the Content API only; the Search API
  needs to be added to the same client in the Quran Foundation Developer Console
  (`https://dev-console.quran.foundation`), for **both** prelive and production credentials, before this route can
  work. This is an account action only the owner can take (not a code or infra fix) — **owner action needed**: open
  the Developer Console, find the existing app/client, and add/request the `search` scope for prelive and
  production. Once granted, re-run the curl above (or ask for it to be re-run) to confirm before switching the flag
  on for real use.
- The Flutter side was built and tested against the Search API's documented response schema (the OpenAPI example on
  its docs page — `pagination.current_page`/`total_pages`, `result.verses[].key`/`name`), not a guess, but is not
  yet confirmed against a real response since the scope above blocks that: `QuranContentRepository.searchTranslation()`,
  `QuranContentCubit.searchTranslation()`/`loadMoreSearchResults()`/`clearSearch()`, and `QuranSearchPage` gained a
  mode switch between the existing on-device search and a new "search inside the chosen translation" mode (its own
  text field, submitted explicitly rather than live-as-you-type, to not spend the free-tier quota on every
  keystroke; paginated with a "Load more" button; a failed "load more" keeps the results already shown, with its
  own inline retry, rather than wiping the list).
- New flag `FeatureFlags.quranTranslationSearch` (off by default), meaningful only together with
  `quranTranslations` (there is no translation to search without it) — the mode switch in `QuranSearchPage` is
  gated on both.
- New tests: 4 more data-layer tests (`quran_content_data_test.dart` — request shape, pagination/field parsing, a
  malformed verse key is a parse failure, repository mapping) and `test/app/quran_translation_search_test.dart`
  (7 — both gating flags independently, the no-edition prompt, a full search-and-paginate flow with credit lines,
  no-match, search failure/retry, load-more failure/retry). Full suite passing; `flutter analyze` clean; `dart
  format` clean; the Worker's `tsc --noEmit` is clean and it is deployed.

**Flag D (audio recitation) is also done, 2026-10-22, scoped to foreground playback only** (owner's explicit
choice when asked: lock-screen controls and background playback are a deliberate v1 cut, not an oversight, to avoid
the iOS `UIBackgroundModes`/Android foreground-service entitlements and the App Store/Play background-audio review
question §3 flagged as this flag's risk, until that is reviewed on its own):

- `QuranAudioPlayer` (new domain interface: `play(Uri)`/`pause`/`resume`/`stop`, state/position/duration streams) and
  `JustAudioQuranPlayer` (new data impl, same `just_audio` package `JustAudioAdhanPlayer` already uses for adhan
  preview playback, kept separate since this one streams a remote url and supports pause/resume for a transport bar
  rather than one local file played once).
- `QuranAudioCubit` (new, separate from `QuranContentCubit`): resolves each verse's audio url through
  `QuranContentRepository.recitationAudioUrl` (already existed, unused until now), hands it to the player, and
  auto-advances to the next verse when one finishes -- stopping instead at the open sura's last verse (the same
  "this sura only" scope limit §8's Phase A note already established for verse-by-verse). Built and disposed per
  `SuraReaderPage` instance, like `QuranContentCubit`, so playback always stops when the reader closes.
- The player itself is built by a factory (`QuranAudioPlayer Function()`), not a shared instance: `AppDependencies`
  threads `quranAudioPlayerFactory`/`quranAudioPlayerFactoryIfEnabled` the same explicit-constructor-parameter way as
  `quranContent`, through `app.dart` → `AppShell` → `QuranPage` → `QuranCubit` → `SuraReaderPage`, which calls it
  once in `initState` so each reader session gets its own player to own and dispose. `JustAudioQuranPlayer` itself
  is only ever constructed in `app_dependencies.dart` (the composition root); `SuraReaderPage` never imports the
  data layer directly (`test/architecture_test.dart` forbids it).
- New flag `FeatureFlags.quranAudio` (off by default). `AppDependencies.quranContentIfEnabled` now gates the
  repository on any of `quranTranslations`/`quranTafsir`/`quranAudio`.
- Reachable from **both** layouts (a headphones app-bar button, same "always offered, independent of the other two
  flags" pattern as the tafsir button): it opens `ReciterPickerPage` (new -- a plain list, not a searchable one like
  the translation/tafsir pickers, since the owner's "all of them" decision (§7.4) is only a dozen reciters here, not
  145). Once a reciter is chosen, the verse long-press menu gains a "Listen" option, same precedent as tafsir's
  "Read the tafsir" (no option offered without a chosen reciter).
- A mini player (`AudioMiniPlayer`, new) docks at the bottom of the reader once something has played: play/pause,
  previous/next verse (bounded to the open sura), elapsed and remaining time, and a close button that stops
  playback and hides the bar -- matching §4's "Audio" bullet. A failed fetch or playback shows the typed error and a
  retry inside the bar itself (not a full-screen `ErrorView`, since the reader is still underneath), the same
  "an explicit action gets a visible error, not silence" rule tafsir already established.
- The reciter choice persists the same way as the other editions (`AppSettings.quranReciterId`/`Name`).
- New tests: `test/features/quran/quran_audio_cubit_test.dart` (15 -- resolve-and-play, repository/player failure
  mapping, pause/resume/stop, next/previous bounds, auto-advance on completion including stopping at the sura's
  last verse, retry replays the same verse/reciter/bounds, position/duration ticks, dispose), 3 more
  `loadReciters` cubit tests (mirroring `loadTafsirEditions`), and `test/app/quran_audio_test.dart` (9 -- flag
  gating independent of tafsir, works in both layouts, no action without a chosen reciter, full choose-and-play
  flow, full transport bar, auto-advance in the running app, failure/retry). Full suite passing; `flutter analyze`
  clean; `dart format` clean.
- **Known, deliberate scope limits**, same spirit as Phase A's: no lock-screen controls or background playback
  (see above); no download/offline audio (§7.6, already out of scope for this whole plan); no scrolling into the
  next sura's audio once the open sura ends (matches verse-by-verse's existing same limit).

**Flag F (qira'at) is also done, 2026-10-22, and turned out to need an owner decision §3's one-line description didn't
anticipate.** The plan read it as parity with B/C ("pick an edition, see the verse's text in it"); the real API is a
different shape entirely:

- Qira'at content (`api-docs.quran.foundation`, read 2026-10-22) is a scholarly comparison, not alternate editions:
  **readers** (the canonical reciters) → **transmitters** (e.g. Hafs/Shu'bah for 'Asim) → **junctures** (specific
  points where readings diverge within a verse, categorized A/meaning, B/wording or C/pronunciation) → **readings**
  at that point, tied together by a **matrix** endpoint. Coverage is sparse by design -- most verses have *no*
  approved junctures at all (confirmed by the docs' own count/matrix descriptions, and by the OAuth2 Scopes page
  flagging it production-only, no prelive data). There is no "whole alternate verse text" to show; only the exact
  words that differ, when a verse happens to have any.
  Given this mismatch, the owner was asked how to proceed (build a variants viewer to match the real data, or
  defer); the answer was to build it.
- Same blocker pattern as flag E, found the same way (live `curl` + `wrangler tail` against the deployed proxy, not
  guessed): the token request for `scope=qiraat` returns HTTP 400. Qira'at needs its own OAuth scope (`qiraat` or
  the narrower `qiraat.read`; the Worker requests the parent `qiraat`, per the OAuth2 Scopes page's own guidance to
  request a parent scope when approved for it), separate from both `content` and `search`. **Owner action needed**,
  same place as flag E's: grant the `qiraat` scope for the existing client in the Developer Console
  (`https://dev-console.quran.foundation`) -- production only, since Qira'at has no prelive data to test against
  even once granted.
- The Worker (§2) gained a third scope to its per-`(environment, scope)` token cache, and one new route,
  `GET /:env/qiraat/matrix/ayah/:verseKey`, forwarding to the Content API's own base url (same as B/C) but with a
  `qiraat`-scoped token. A 404 from upstream ("no approved variations for this verse") is forwarded through
  as-is -- the Flutter side treats that as the normal empty result, not an error.
- Scope was deliberately kept to a *viewer*, not an *edition*: the matrix endpoint has no "filter by reader"
  parameter -- it always returns every approved reading for a verse -- so there is nothing to "choose" the way a
  translation or tafsir edition is chosen. No new `AppSettings` field, no picker page. New flag
  `FeatureFlags.quranQiraat` (off by default) simply gates a "Qira'at variations" option in the verse long-press
  menu (same precedent as tafsir's "Read the tafsir"), always offered when the flag and repository are on --
  unlike tafsir/translations, nothing needs to be "chosen" first, since whether a verse has variations is itself
  not something a reader could know in advance.
- Tapping it opens a bottom sheet (`showQiraatSheet`, same `DraggableScrollableSheet` shape as `showTafsirSheet`)
  that fetches and shows, per approved juncture: its category, the base and alternate wording, each reading's
  translation (when the API has one) and who holds it (reader, or reader-with-transmitter when a specific
  transmitter's reading differs from their reader's others), a scholarly commentary when present, and a closing
  disclaimer that these are **all authentic, transmitted readings, not alternate interpretations** (the opposite
  emphasis from tafsir's disclaimer, and intentionally so) plus a Quran Foundation credit line. A verse with no
  approved junctures says so explicitly rather than showing nothing, since silence here would look like a bug, not
  an absence of data.
- New domain type `QiraatCubit`, kept separate from `QuranContentCubit` on purpose: with no edition dimension and
  no edition-list to load, its state is a plain per-verse `Map<String, QiraatMatrix>` cache, far simpler than
  `QuranContentCubit`'s machinery -- adding two more fields to that already-large shared state (and re-touching
  every one of its existing full-rebuild call sites again) would have cost more than it was worth for a
  self-contained concern.
- New tests: 4 more data-layer tests (`quran_content_data_test.dart` -- reader/transmitter attribution, the 404-to-
  empty mapping at both the remote-data-source and repository layers, a real 500 still surfacing as a failure),
  `test/features/quran/qiraat_cubit_test.dart` (7 -- per-verse caching including the "no variations" case, failure
  held not silent, no retry-on-its-own, explicit retry), and `test/app/quran_qiraat_test.dart` (6 -- flag gating
  independent of tafsir, the full view-a-comparison flow with credit, the explicit "no variations" state, fetch
  failure/retry). Full suite passing; `flutter analyze` clean; `dart format` clean; the Worker's `tsc --noEmit` is
  clean and it is deployed.

**What's left is granting the account-level scopes flags E and F are both blocked on** (`search` and `qiraat`, same
Developer Console, same client, both production only for the scope itself -- E's Search API works in prelive too,
once granted). Every flag this plan proposed (A-F) now has its Flutter-side code built and tested; E and F additionally
need that one owner action each before their live behaviour can be reviewed on a device.
