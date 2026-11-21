# Phase 1: Quran.ws ecosystem audit (no code changes)

Status: **audit only, nothing implemented.** Written 2026-10-19 after reading the live `quran.ws` documentation
(`/docs/start/concepts/`, `/docs/start/choosing-a-block/`, all eight `/docs/reference/*/` pages, `/docs/reference/licensing/`,
`/docs/build/platforms/`, `/docs/build/offline/`) and the current Hadeeths (سكينة) repository. No GitHub repository under
`github.com/quran-ws` was cloned or inspected directly; everything below comes from the documentation site, which itself is
generated from those repositories. Nothing was installed, downloaded, or changed in the app. See also the related, earlier
[`QURANHUB_PLAN.md`](QURANHUB_PLAN.md), which covers a *different* project (Misraj AI's QuranHub API) and reached a
compatible conclusion: keep the bundled, fingerprinted Tanzil text as the only source of verse text.

## 0. Headline finding

**None of the eight Quran.ws blocks is currently an installable package** (no pub.dev, Maven, CocoaPods/SPM, or npm
release that a `pubspec.yaml` dependency could point to). Every block's own docs recommend cloning the repository and
pinning a commit SHA, because most have no release tag at all. Concretely:

| Block | Registry status |
|---|---|
| Quran Text | No pub.dev/PyPI/npm/Maven package; vendor the source |
| Qiraat Ayah Map | v0.1.0, no release tag; `dist/` is generated and git-ignored — must run the `generate` script yourself |
| Quran SVG | No package; static files served directly |
| Quran SVG Elements | v1.0.0 release exists, but **its own `LICENSE` file says "no licence has been chosen" while its JSON files declare CC-BY-4.0** — an unresolved internal contradiction |
| Quran Assets | No package, no release |
| Quran Engine | Page-data release v0.1.0; the Flutter wrapper's pubspec says `publish_to: none` and is **Android-only**; no iOS Flutter path exists at all (see §2) |
| Quran Tajweed | GitHub release v0.4.0 exists; corpus is v0.4.2 |
| QuranTech | No release/tag; ships whatever is on the default branch |

This means "integrate the ecosystem" is not a dependency-management task — it is **vendoring data at a pinned commit and
hand-writing Dart/Flutter adapters for all eight blocks**, maintained by us, against pre-release upstream code. That is a
much bigger and longer-lived commitment than adding a package, and it sits in tension with this repo's own bar for
verified, stable dependencies (the existing `assets/quran/quran-uthmani.txt` is pinned by byte length *and* fingerprint —
see [`app/quran_wiring.dart`](../lib/app/quran_wiring.dart) — specifically so nothing unverified can enter the reader).

## 1. Current Sakina/Hadeeths Quran feature (as it exists today)

- **Text source:** `assets/quran/quran-uthmani.txt` — Tanzil Quran Text (Uthmani, v1.1), CC BY 3.0, loaded by
  [`QuranText.parseTanzil`](../lib/features/quran/domain/quran_text.dart), which refuses anything that isn't exactly
  114 suras / 6,236 verses, and is pinned to one asset by byte length + fingerprint. This is Ḥafṣ-only; there is no
  multi-riwayah support today.
- **Structure:** [`QuranStructure`](../lib/features/quran/domain/quran_structure.dart) — pure-Dart page (1–604), juz (1–30),
  hizb-quarter (1–240) and sajdah lookups, from a small bundled table, no third party.
- **Reader UI:** a continuous text-flow reader (`sura_reader_page.dart`, `verse_flow.dart`, `verse_marker.dart`) — **not**
  a Mushaf page-image renderer. There is no existing SVG/Engine-based page view to extend; this would be new.
- **User data:** [`QuranUserData`](../lib/features/quran/domain/quran_user_data.dart) — last-read position and bookmarks,
  on-device only (SQLite via `core/database`), positions only, never text.
- **Search:** on-device (`quran_search.dart`), no network.
- **Architecture discipline:** strict domain/data/presentation layering enforced by `test/architecture_test.dart`
  (see [`ARCHITECTURE.md`](ARCHITECTURE.md)); feature flags gate anything not finished; no network call exists for Quran
  text today, and `QURANHUB_PLAN.md` explicitly decided against adding one for the verse text itself.
- **Monetization:** no ads or in-app-purchase dependency found in `pubspec.yaml` or `docs/STORE_LISTING.md`. The app
  appears non-commercial today, but this was already an open question in `QURANHUB_PLAN.md` and matters again below
  (§4) — **the owner should confirm it explicitly.**

## 2. Compatibility matrix

| # | Component | Actual functionality | Maturity | Platforms | Dependencies | Integration method | Offline behaviour | Data coverage | Licensing risk | Recommended role in Sakina |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | **Quran Text** | Verified text + word identity, page/juz/sura/word queries, search/normalisation | Pre-release (no tags); "Beta" per choosing-a-block | Dart listed; **no pub.dev package**. Pure Dart/JSON — no native code, so Android+iOS both viable once vendored | None native; optional font as Flutter asset | Vendor source under a pinned commit; write a thin Dart wrapper | Ḥafṣ bundled (~3.1 MB + font); other riwayat downloadable | 7 of 10 riwayat (missing Qunbul, Ibn ʿĀmir, Ḥamzah, al-Kisāʾī) | CC BY 4.0 (data+code); KFGQPC source terms apply | **Do not replace the existing bundled Tanzil text.** Only worth vendoring later if we need its word-identity keys (for Tajweed/word-highlight) or additional riwayat — neither is in scope yet |
| 2 | **Qiraat Ayah Map** | Crosswalk of ayah numbers across the 6 canonical counting systems | v0.1.0, no release tag; known open conflict (Basran count vs. printed al-Sūsī) | Data-only JSON, "anywhere" | None | Vendor `dist/` output, or run `generate` ourselves | `mappings/*.json` cacheable, ~2.3 MB combined | 6 counting systems, by-rawi tables | CC BY 4.0 data / MIT tooling | **Defer.** Sakina is Ḥafṣ/Kufan-only; nothing today needs cross-system mapping. Revisit only if multi-riwayah is ever approved |
| 3 | **Quran SVG** | Full vectorised Mushaf pages, ayah-level hit regions, print-accurate | Stable (archive); 5 editions vectorised | **Documented for the browser only.** The docs themselves call it "heavy on phones" and no Flutter/iOS/Android example exists | None (static files) | Would need `flutter_svg` + custom hit-testing; not demonstrated anywhere upstream | Per page: 196 KB–613 KB SVG / 33–?? KB Brotli | 5 muṣḥafs × 604 pages each; page numbers are **not interchangeable** across editions | CC BY 4.0 (polygons/JSON), MIT tools; KFGQPC artwork free for digital/web/software use | **Not the mobile renderer.** Reference/fallback only; the authors' own guidance is to use Quran Engine on mobile instead |
| 4 | **Quran SVG Elements** | Word/mark-decomposed SVG+JSON, `surah:ayah:word` keys | v1.0.0, but "early-stage"; documented defects list; **license file contradicts itself** | **Web-first, documented as needing no runtime — but no mobile consumption path.** The docs say any mobile adapter "would be something you build yourself" and point to Quran Engine instead | None for web; unknown for a custom Flutter adapter | Would require us to design and build an SVG→Flutter (or SVG→Engine) converter ourselves; not an upstream-supported path | 108 MB full tarball — **must never ship to a device**; split and serve per-page | **Only one edition is split**: Ḥafṣ KFGQPC V4 1441H. Known edition-id mismatch (`hafs-kfqc` vs `hafs-kfgqpc`) | Unresolved (see above) — do not rely on until upstream clarifies | **Defer.** No supported mobile path exists; license is unresolved; revisit once Quran Engine (which this feeds) is mature |
| 5 | **Quran Assets** | Decorative SVG: surah headers, ayah markers, page frames | Unpublished, no releases | Any SVG renderer (`flutter_svg` works) | None | Vendor the 71-asset catalogue at a pinned commit; filter by `license.status` | Tiny — a few dozen small SVGs + one PUA font | 8 scan printings + 20 font-marker designs (40 files after per-family variants) | **Mixed and partly blocking**: only the 40 font-derived ayah markers are **OFL-1.1 "confirmed."** Scan-derived headers/markers/frames are **CC-BY-NC-SA-4.0 "provisional" — permissions are still being negotiated with each publisher**, and 7 font designs are "pending" with no licence at all | **Ship only the 40 OFL-confirmed font ayah markers.** Do not bundle any scan-derived ornament until its status becomes "confirmed" — this is blocking regardless of whether Sakina is commercial, because permission simply hasn't been granted yet |
| 6 | **Quran Engine** | Compact binary (`.qvp`) page format + native renderer: hit-testing, word/mark selection, highlighting, masking, search | v0.1.0; "Beta"; **no package published anywhere** | **Critical gap:** Flutter wrapper `qvp_flutter` is explicitly **Android-only** (`publish_to: none`). The iOS path is a raw Swift package the docs call "not built or run by us" — unsupported, unverified, and not wired to Flutter at all. React Native is Android-only too ("iOS TODO") | Rust toolchain to build `qvp_ffi.wasm`; native libs per platform | Build from source for every target; no binary ships | Default edition's pages ~44 MB tarball (92.5 MB unpacked, 38.9 MB Brotli) — **download on demand, never bundle at install** | Currently covers the editions it has pages for (Ḥafṣ KFGQPC) | MIT (engine code), CC BY 4.0 (docs); page data carries KFGQPC free-use terms | **The only realistic path to an interactive Mushaf page, but Android-only today.** Treat as a capability-gated, Android-first prototype; iOS gets an explicit, honest fallback (not a silent one) until upstream ships iOS support |
| 7 | **Quran Tajweed** | Character-offset tajwīd rule spans over its *own* bundled edition text | Release v0.4.0 / corpus v0.4.2; 162 stable rules, 18 disabled, 2 disputed, 12 "needs review" | "Anywhere" — pure data, consumed as text-position spans | None | Vendor `editions/uthmani-hafs.json` + `annotations/uthmani-hafs.json` + `rules/rules.json` at a pinned commit; verify `editionDigest`/`assertEdition` before use | `annotations` 1.8 MB; the edition text itself is included (contains actual Qur'anic text) | Ḥafṣ ʿan ʿĀṣim **only**; other riwayat are treated as errors | CC BY 4.0 (annotations/corpus), MIT (tooling) | **Must render against its own verified edition text, not ours.** The docs state plainly that joining its offsets to Quran Text's own words only matches in 319 of 6,236 ayahs — joining them to our *different* Tanzil-sourced text has no verified mapping at all. See §4 decision 3 |
| 8 | **QuranTech** | Documentation/skill bundle for AI coding agents (not app software) | "Experimental"; no release/tag | N/A — "ships no code into your application, changes nothing at runtime, and is not in your dependency graph" | None | Install as a Claude Code skill/plugin if desired, entirely outside the app | N/A | N/A | MIT | **Optional dev-tool only.** Zero effect on the app or this compatibility matrix either way |
| — | *Quran PNG (bonus, not in the required 8)* | HTTP service to render a shareable ayah image | — | Web service, **no offline form** | Network | Not applicable to an offline-first app | None — it is a live service | — | MIT (app), CC BY 4.0 (data/design) | Out of scope: conflicts with the app's offline-reading commitment; revisit only if a "share ayah as image" feature is explicitly requested |

## 3. Recommended integration architecture (proposal, not yet approved)

Keep every existing Quran type untouched: `QuranText`, `QuranSource`, `QuranStructure`, `QuranUserData`, and the
text-flow reader stay exactly as they are and remain the one verified source of verse text. Everything below is
**additive**, under a new feature flag (matching `app/feature_flags.dart`'s existing pattern), inside a new
`features/quran_mushaf/` module so the mature, text-flow reader is never put at risk.

New domain interfaces (pure Dart, no Flutter — matching the existing `domain/` rule):

- **`MushafEdition`** — an explicit tag (riwayah + numbering system + source) carried on every text, asset, and
  annotation object. Nothing is ever allowed to default silently to "whatever edition happens to be loaded" — this
  mirrors the project's own existing rule that `QuranText` never changes a byte of source text.
- **`AyahNumberingMap`** — wraps the Qiraat Ayah Map *only if and when* multi-riwayah is approved (§4, decision 4);
  until then, no code depends on it, since Sakina is single-system (Kufan/Ḥafṣ) today.
- **`WordIdentity`** — the `surah:ayah:word` join key, introduced only alongside whichever block first needs
  word-level addressing (Tajweed highlighting or Engine word-tap). Never joined across sources by comparing Arabic
  strings — only by this stable key or by a verified digest check, consistent with how `QuranText.parseTanzil`
  already refuses anything it can't verify byte-for-byte.
- **`MushafPageRenderer`** — an abstraction over "how a page is drawn," with capability flags, not assumptions:
  `EnginePageRenderer` (Android, Quran Engine) is the only renderer actually proposed for v1; a `StaticPageImage`
  fallback (or simply the existing text-flow reader) is what iOS shows instead — chosen explicitly per platform, never
  silently substituted.
- **`TajweedAnnotationSource`** — returns spans tied to one named `MushafEdition` and its `editionDigest`. If the
  digest the app has doesn't match the one the annotations were built for, this throws an explicit, user-visible
  error (parallel to today's `QuranUnavailable`) — it never applies offsets to the wrong text.
- **`MushafAssetSource`** — decorative SVG assets, pre-filtered at build time to `license.status == confirmed` so an
  unlicensed asset can never physically ship, not just "shouldn't."

Data layer: each block becomes its own vendored dataset under a pinned commit, verified the same way
`bundled_quran_source.dart` already verifies the Tanzil file (size + fingerprint check, with a `tool/` script to
regenerate the recorded values on update) — there is no package manager step to lean on, so this verification *is*
the dependency pin.

No existing abstraction is reused improperly: `QuranStructure`'s page/juz/hizb numbers are reused as-is for the new
page renderer (so "page 1" means the same thing it already does in the app); nothing new is invented where today's
types already answer the question.

## 4. Offline storage estimate

Figures below are the Quran.ws docs' own numbers, scoped to a Ḥafṣ-only v1 (no other riwayat, which the current app
doesn't support anyway):

| Item | Size | When |
|---|---|---|
| Existing Tanzil text (already shipped) | 1.4 MB | At install (unchanged) |
| Quran Engine wasm/native runtime | ~280–304 KB | At install, only if the Android Mushaf-page feature ships |
| Quran Engine pages, per juz (≈20 pages) | ~760 KB | On demand, by juz, **not** at install |
| Quran Engine pages, all 604 | 44 MB tarball / 92.5 MB unpacked / 38.9 MB Brotli | Never bundle at install; download-on-demand only |
| Quran Tajweed annotations + its own edition text | 1.8 MB | On demand, once, cached, tied to its edition digest |
| Qiraat Ayah Map (all systems) | ~2.3 MB | Only if multi-riwayah bookmarks are approved — not needed otherwise |
| Quran Assets (40 OFL font markers only) | <1 MB | At install, if the feature ships |
| `word-index.json` | 50 MB | **Never on device** — build-time only |
| Full Quran SVG Elements tarball | 108 MB | **Never on device** — split server-side if ever used |
| Uncompressed SVG pages | 196–613 KB each | Avoid; serve `.br` only if SVG is used at all |

A realistic PoC (§5) that reuses the existing Tanzil text and only adds Engine pages for one juz plus the Tajweed
annotation file stays **under ~3 MB** of new downloaded data, with no change to the app's current install size.

## 5. Licensing and distribution risks

- **KFGQPC source material** (text, page artwork, fonts — used by Quran Text, Quran SVG, Quran SVG Elements, Quran
  Engine, Quran Tajweed, Quran PNG): the Complex's own terms, fetched verbatim in §10.1, allow free personal,
  governmental, institutional, media, web, and software use with **no commercial restriction for any of those** —
  the one actual restriction is printing or importing physical Qur'an copies *into or within Saudi Arabia* for sale,
  under two named royal decrees, which plainly doesn't apply to a mobile app.
- **CC BY 4.0** (most data/docs across all eight blocks) and **MIT** (most tooling/code) are both compatible with a
  commercial or non-commercial app, but CC BY 4.0 requires attribution. The exact required attribution string is in
  the **"Waqf and open licensing" guideline** (`/docs/guidelines/licensing/`), which this audit has not yet fetched in
  full — do that before drafting any credits-page text.
- **Quran Assets scan-derived ornaments are the one hard blocker**, independent of attribution: they're
  CC-BY-NC-SA-4.0 **and** explicitly "provisional" — the publishers haven't actually granted permission yet, for
  non-commercial or commercial use. Only the 40 OFL-1.1 "confirmed" font markers are safe to ship today.
- **Quran SVG Elements' license is internally contradictory** (its `LICENSE` file says none was chosen; its JSON
  metadata claims CC-BY-4.0). Don't rely on either statement; treat this block as unlicensed until upstream resolves it.
- **Nothing is on a package registry**, so there's no registry-level license metadata to audit automatically (e.g. via
  a pub/npm license-checker) — every block's license has to be re-read by a human at the pinned commit each time it's
  updated, since there's no tag to diff against.
- **Open question carried over from `QURANHUB_PLAN.md`:** is Sakina commercial (ads, subscriptions, paid)? Nothing in
  the repo today suggests it is, but the owner should confirm explicitly — it doesn't change the Quran Assets blocker
  above (which is about permission, not commerciality), but it would matter for any future KFGQPC-adjacent commercial
  use.

## 6. Phased implementation roadmap

Following the roadmap already specified, scoped to what this audit found:

1. **Phase 1 — this document.** No code changes. Done.
2. **Phase 2 — architecture and data contracts.** Turn §3 into concrete Dart interfaces and a written data-contract
   doc (edition tagging, word identity, digest verification), reviewed before any implementation starts. Explicitly
   decide the open items in §7 first, since they change the shape of the contracts (e.g., whether Tajweed gets its
   own parallel verified text).
3. **Phase 3 — proof of concept.** Android-only vertical slice: one Quran Engine page, ayah tap → reference →
   existing `QuranText` lookup → existing bookmark store; one ayah Tajweed-highlighted against Quran Tajweed's own
   verified text, clearly labeled as a distinct view. iOS shows the existing text-flow reader with no Engine call
   attempted. See acceptance criteria below.
4. **Phase 4 — complete reader,** gated by what Phase 3 proves actually works: page navigation, bookmarks (reusing
   existing storage), search (existing), word interaction only where Engine supports it, Tajweed, the 40 OFL asset
   markers. Riwayah selection and Qiraat Ayah Map stay out of scope unless separately approved.
5. **Phase 5 — offline and performance.** Per-juz download with SHA-256 verification against `manifest.json` (digest
   mismatch ⇒ discard and refuse to cache, per §4's storage table), cleanup of superseded cached pages, memory/perf
   testing of the Engine on real low-end Android devices (no figures were published upstream — this has to be
   measured ourselves).
6. **Phase 6 — verification and release readiness.** Full test suite incl. `architecture_test.dart`, device builds,
   licence audit re-run against whatever upstream commit is pinned at release time (since nothing is tagged, a
   silent upstream change is a real risk — pin by commit SHA and re-review on every bump), accessibility pass,
   documented limitations (iOS has no interactive Mushaf page; most riwayat are unsupported; Quran Assets ornaments
   are not shipped).

## 7. Acceptance criteria for the Phase 3 proof of concept

1. Renders one authentic Mushaf page via Quran Engine on Android; on iOS the existing text-flow reader opens instead
   with no attempt to call Engine — covered by a widget test that asserts the platform branch, not just manual QA.
2. Tapping an ayah on the rendered page resolves a `surah:ayah` reference via Engine's hit-test, in Sakina's existing
   Kufan/Ḥafṣ numbering — no Qiraat Ayah Map call needed for this slice.
3. That reference is used to fetch the verse text from the **existing** `QuranSource`/`QuranText` (bundled Tanzil) —
   proving the Engine and the existing reader join only by reference, never by comparing Arabic strings.
4. Word tap resolves `surah:ayah:word` where the loaded page's edition supports it; where it doesn't, the UI says so
   explicitly rather than guessing or silently disabling the gesture.
5. One ayah renders with Tajweed colouring sourced from Quran Tajweed's own bundled edition text (shown as a clearly
   labeled, distinct Tajweed view), only after its `editionDigest` is checked against `annotations.edition.sha256`;
   a mismatch must produce a visible error, never silently-plain text.
6. Bookmarking from this new page view reuses the **existing** `QuranUserData.setBookmark`/`isBookmarked` — no second
   bookmark store is created.
7. Engine page data is fetched on demand (one juz, not all 604 pages) and verified by SHA-256 before being cached;
   a corrupted or partial download is discarded, not cached.
8. `test/architecture_test.dart` and the full existing test suite pass unmodified; all new code respects the existing
   domain/data/presentation boundaries.
9. Every vendored file's source, version, licence, and digest is recorded in a new `docs/QURAN_WS_SOURCE_OPTIONS.md`
   (parallel to the existing `QURAN_SOURCE_OPTIONS.md`), reviewed by the owner before merge.
10. No verse, translation, or tajwīd text is typed into source or tests; tests use placeholders, matching existing
    practice.

## 9. Draft attribution text (per `/docs/guidelines/licensing/`, read in full)

The guideline's key point changes the picture in §5: Quran.ws operates a **"Waqf" waiver** on its own CC BY 4.0
attribution requirement for exactly Sakina's situation. Quoting it directly: *"Merely using a resource to provide
functionality to end users does not require displaying our name, logo, or a link."* That waiver covers using the
data inside an app, free or commercial. It does **not** cover republishing the dataset itself as data (a public
mirror, bulk export, etc.), which Sakina wouldn't be doing. So, legally, **no credit is required** for whichever
Quran.ws blocks end up shipping.

Two things the waiver explicitly does **not** touch, though:

- **Third-party material keeps its own licence**, and a resource's own `LICENSE`/`NOTICE` file overrides the Waqf
  policy for that material specifically. That means the **KFGQPC statement** (reproduced in each repo's own
  `LICENSE`) and the **OFL-1.1 font notices** (in `dist/LICENSES.md` for the 40 confirmed ayah-marker fonts) still
  apply on their own terms, independent of Quran.ws's waiver.
- **MIT code's copyright/licence notice must be preserved** wherever the code itself is kept (i.e., in our vendored
  copy under source control) — this is a source-tree requirement, not an app-UI one.

Given that, and matching the app's existing `quranCredit` / `aboutQuranBody` style (short line on the Quran page,
longer paragraph on the "Sources and rights" page, exactly as done today for Tanzil), here is drafted copy for each
block **that might ship**. None of this is wired into the app yet — it's text for `l10n/app_en.arb` /
`app_ar.arb` to add only once the corresponding decision in §11 is approved and the block actually ships, and the
Arabic side needs its own translation pass, not a mechanical mirror of the English.

**Short credit (Quran page, optional — not legally required, offered for consistency with existing practice):**

> Mushaf pages: Quran Engine by Quran.ws, under its own terms. Tajwīd colouring: Quran Tajweed by Quran.ws, under its
> own terms.

**Longer "Sources and rights" entries (one per block, only for blocks actually shipped):**

- **Quran Engine** (if the Android Mushaf-page feature ships):
  > "Mushaf page rendering: Quran Engine by Quran.ws (quran.ws/blocks/quran-engine). Engine code licensed MIT;
  > documentation CC BY 4.0; not required for in-app use, credited here by choice. Page artwork is Mus'haf
  > al-Madinah, published by the King Fahd Glorious Qur'an Printing Complex, used under the Complex's own free-use
  > terms for digital, media, web and software use (full statement quoted at §10.1) — not the Tanzil text already
  > credited elsewhere in the app; this is a separate source and should be labelled as such wherever it appears."

- **Quran Tajweed** (if the Tajwīd view ships):
  > "Tajwīd annotations: Quran Tajweed by Quran.ws (quran.ws/blocks/quran-tajweed), corpus and annotations CC BY 4.0;
  > not required for in-app use, credited here by choice. Rules shown are the project's reviewed, stable rule set;
  > two rules are flagged disputed by the project's own auditors and some are pending specialist review — state this
  > plainly in the UI itself, not only in the credits."

- **Quran Assets — the 40 OFL font ayah markers** (if they ship): this one is **not optional**. It belongs in the
  existing Licences page next to Amiri/Cairo, in the same per-family format already used there — **but the actual
  copyright line for each of the font families must be copied verbatim from the upstream `dist/LICENSES.md`**, the
  same way the app already copies the Tanzil notice verbatim rather than writing its own summary. I have not fetched
  that file's contents, so I'm not drafting placeholder copyright lines here — doing so would risk shipping invented
  legal text, which is exactly what this project's own `QuranText.parseTanzil` discipline is designed to prevent for
  Qur'anic text, and should hold just as firmly for font notices.

## 10. Verbatim text fetched from GitHub (`github.com/quran-ws`)

The organization has 14 repositories; the two relevant ones were `quran-engine` and `quran-assets` (there's also a
separate, dedicated `kfgqpc-resources` repo, not yet inspected further). This section quotes what was actually
fetched, not a paraphrase — because that distinction is the whole point of this exercise.

### 10.1 `quran-engine/LICENSE` — the King Fahd Complex statement, in full

This **corrects §5 above**: the restriction is narrower and more specific than "printing physical muṣḥafs for
commercial sale" — it's about printing or importing *into Saudi Arabia*, under two named royal decrees, and nothing
else. Everywhere else, for every digital/software use, the terms are explicitly unrestricted, commercial included:

> Based on the approval of His Excellency the Minister of Islamic Affairs, Endowments, Da'wah and Guidance, General
> Supervisor of the King Fahd Qur'an Printing Complex.
>
> The Qur'an Printing Complex is honored to present to the Muslim public a complete free digital copy of Mus'haf
> al-Madinah published by the Complex, in the following formats: Adobe Illustrator files; PDF files; High quality
> images; True Type Font.
>
> Mus'haf al-Madinah in these previous formats can be used for free in all personal, individual businesses, in works
> of governmental departments & agencies, in the publications of both private and national institutions, also
> suitable for Qur'an printing,\* digital publishing, & for media use, can be used also in websites, software, and
> other similar intermediates.
>
> We ask Allah that He renders this blessed project beneficial to all Muslims.
>
> \* Printing of Qur'anic copies in the Kingdom, and their import from outside for sale are subject to the Royal
> Decree No 136/8 dated 1/2/1406 AH which has been reiterated by the Royal Decree No 9/B/46356 dated 28/9/1424 AH
> which prohibit printing of Qur'anic copies in the Kingdom except in the Complex, likewise their import from
> outside for sale.

The repository's `LICENSE` states the Arabic text governs where the two differ (both are reproduced there; only the
English is quoted here for brevity). **None of this restriction applies to Sakina**, a mobile app, in any scenario
this audit can see.

The same file also confirms the Waqf waiver is written as a formal grant, not just guidance: *"a permanent,
worldwide, royalty-free, irrevocable waiver of the attribution requirement of CC BY 4.0 (Section 3(a))"* for use
inside a product. And it gives the suggested attribution template verbatim: `Data from [resource] by Quran.ws,
licensed under CC BY 4.0. Source: [canonical URL]. Version: [version]. Modified: [yes/no].` — for if we choose to
credit it anyway.

### 10.2 Quran Assets — the OFL evidence is per-family, not one generated file

`dist/LICENSES.md` doesn't exist in the repository — it's a **generated** file (`qa dist` builds it from
`sources/licenses/*.txt`), so it isn't something to fetch from GitHub directly; it has to be produced by running
that tool, or assembled from its 14 source files, one per font family. Two are already relevant to Sakina because
**the app already bundles these exact two font families** for the reading text (`assets/fonts/Amiri.ttf`,
`assets/fonts/AmiriQuran.ttf`, per `pubspec.yaml`):

> **Amiri** — Copyright 2010-2022 The Amiri Project Authors (<https://github.com/aliftype/amiri>). No Reserved Font
> Names. SIL Open Font License, Version 1.1.
>
> **Amiri Quran** — Copyright 2010-2022 The Amiri Quran Project Authors (<https://github.com/aliftype/amiri>). No
> Reserved Font Names. SIL Open Font License, Version 1.1.

Both carry the full standard OFL 1.1 text (same as the other 12 families' evidence files) — which the app's own
`core/licences.dart` / `assets/licenses/` already has to reproduce for the app's *existing* Amiri/AmiriQuran use, so
if any Quran Assets ayah-marker derived from these two families ships, **the existing licence entry likely just
needs the marker asset added to its "used for," not a new licence block.** The other 12 families (Alkalami, Estedad,
IBM Plex Sans Arabic, Jomhuria, Katibeh, Kufam, Mada, Mirza, Noto Naskh Arabic, Noto Nastaliq Urdu, Noto Sans Arabic,
Scheherazade New) are not currently bundled by the app; each would need its own new licence entry, in the same
format, fetched from its own `sources/licenses/<family>.txt` file at integration time, if any marker from that
family is actually chosen.

The repository's own `LICENSE.md` also confirms, in its own words, that this is held to deliberately: the project's
build marks its own npm package `"private": true` and **refuses to publish a release** while any bundled asset's
licence status isn't `confirmed` — which today means the scan-derived ornaments alone are enough to keep the whole
package unpublished. That's a stronger, upstream-enforced version of the same conclusion already reached in §2 and
§5: only the 40 OFL-confirmed font markers are usable; the scan-derived ornaments are not.

## 11. Decisions that need the owner's approval before Phase 2 starts

1. **Scope reality check:** proceed knowing that cross-platform (iOS **and** Android) interactive Mushaf-page
   rendering is **not available today** — Quran Engine's Flutter wrapper is Android-only and the iOS path is
   unsupported upstream. Ship Android-only for v1 with an explicit, honest iOS fallback, or hold the whole
   page-rendering feature until upstream ships iOS support?
2. **Tajweed's text problem:** accept maintaining a second, separately-verified edition of the Quran text (Quran
   Tajweed's own Ḥafṣ text) specifically for the Tajweed view, clearly labeled as a distinct edition — or wait until
   a verified, tested alignment to the existing bundled Tanzil text exists (which upstream itself says doesn't exist
   today, even for Quran Text's own words)?
3. **Riwayah scope:** stay Ḥafṣ-only, as today, and defer Qiraat Ayah Map / multi-riwayah entirely? (Recommended:
   yes — nothing in Sakina needs it right now, and the Map itself has an unresolved internal counting conflict.)
4. **Quran Assets:** ship only the 40 OFL-confirmed font-based ayah markers, and explicitly exclude every scan-derived
   ornament until its licence status changes from "provisional" to "confirmed"?
5. **QuranTech:** install it as a dev-only Claude Code skill (zero runtime/app impact, MIT) for future Quran-feature
   development sessions — separate decision from everything else, since it never touches the shipped app?
6. **Attribution text:** should I next fetch `/docs/guidelines/licensing/` ("Waqf and open licensing") in full and
   draft the exact credit-page wording for whichever blocks get approved?
7. **Commercial status:** confirm explicitly whether Sakina is or will be commercial (ads/subscriptions/paid) — carried
   over from `QURANHUB_PLAN.md`, still unanswered, and relevant to any future KFGQPC-adjacent commercial question.
8. **Vendoring commitment:** given that none of the eight blocks is an installable, versioned package, and every one
   requires us to vendor pre-release upstream data/code at a pinned commit and maintain our own Dart/Flutter adapters
   indefinitely — proceed into Phase 2 now, or treat this as "re-evaluate in 6–12 months once something upstream
   actually reaches a tagged release," and in the meantime scope a narrower, lower-risk feature (e.g. the 40 OFL
   ayah-marker assets and nothing else)?
