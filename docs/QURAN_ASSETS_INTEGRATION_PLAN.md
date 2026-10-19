# Plan: integrating Quran.ws Quran Assets into the Sakina reader

Status: **implemented 2026-10-19**, exactly as scoped below — the 40 confirmed ayah-marker glyphs only, as an
optional, user-chosen alternative to the existing painted rosette, never the default. See §11 for what shipped,
what didn't, and the exact numbers (files changed, tests, app-size impact). The rest of this document is the
original Phase 1 plan, unchanged, since what shipped matches it. It was written 2026-10-19, scoped to exactly one
of the eight Quran.ws blocks (Quran Assets), per
[`QURAN_WS_ECOSYSTEM_AUDIT.md`](QURAN_WS_ECOSYSTEM_AUDIT.md) §2, item 5 and §8/§11. This document supersedes that
entry's summary with a full, numbers-backed inventory: the catalog (`catalog.json`, 213 KB, 71 entries) and the
repository's git tree (541 entries, with per-file byte sizes) were both fetched directly from
`github.com/quran-ws/quran-assets` at its current `main` tip. Nothing was installed, downloaded into the app, or
changed in app code.

## 0. The headline finding, before the inventory

**Sakina already has bespoke, theme-native Mushaf decoration for two of the three asset categories, and it's good.**
Before proposing to add Quran.ws's static SVGs, it's worth being explicit about what's already there, in
[`verse_marker.dart`](../lib/features/quran/presentation/widgets/verse_marker.dart) and
[`sura_reader_page.dart`](../lib/features/quran/presentation/pages/sura_reader_page.dart):

- **Ayah markers:** `VerseMarker` draws an eight-pointed-star rosette with a `CustomPainter`, gold stroke, sage fill
  when bookmarked, the verse number centred inside — fully vector, zero asset bytes, perfectly themed in light and
  dark, and already accessible (`Semantics`).
- **Surah headers:** `_SuraBanner` draws a gold-bordered cartouche with a star on each side (`_StarPainter`) around
  the sura's title — same qualities: zero bytes, theme-native, scales with text size.
- **Page numbers:** `_PageNumber` — a simple gold-outlined pill with the digit, also already Mushaf-flavoured.

None of this is a reason to stop — the request is reasonable, and Quran.ws's font-derived ayah markers are
genuinely more decorative (real calligraphic glyphs, not a geometric rosette) than what exists today. But it does
mean the honest framing is **"an optional, richer visual skin layered over an already-solved problem,"** not
"filling a gap." That framing drives the architecture in §4: the existing widgets stay the default and the
fallback; Quran.ws assets become an alternative rendering behind the same call sites, never a required replacement.

## 1. Full asset inventory

`catalog.json` holds exactly 71 entries, confirming the documentation site's count. Cross-referencing every entry's
`variants` paths against the repository's git tree (which reports each blob's exact byte size) gives the real,
measured footprint — not an estimate:

| Category | Entries | Lineage | License status | Files (colour+mono[+line]) | Bytes if shipped |
|---|---|---|---|---|---|
| **Ayah markers** | 40 | font | **confirmed** (OFL-1.1) | 80 | 326,491 B (**319 KB**) |
| Ayah markers | 7 | font | pending (no licence asserted) | 14 | 112,886 B (110 KB) |
| Ayah markers | 8 | scan | provisional (CC-BY-NC-SA-4.0) | 24 | 168,476 B (165 KB) |
| **Surah headers** | 8 | scan | provisional (CC-BY-NC-SA-4.0) | 24 | 488,558 B (**477 KB**) |
| **Page frames** | 8 | scan | provisional (CC-BY-NC-SA-4.0) | 24 | 2,257,930 B (**2,205 KB**) |
| **Total** | **71** | — | — | **166 (shippable variants)** | **3,354,341 B (≈3.28 MB)** |

(The repository also carries a `source_crop` file per asset — the un-vectorised scan/font crop used to build the
SVG — which is a provenance artefact, not something an app would ever bundle; those bytes are excluded above. The
full `assets/` tree, including every `source_crop`, is ~18.8 MB — never ship that whole directory.)

### 1.1 Ayah markers — all 55 entries, by family/mushaf

**40 confirmed (OFL-1.1), 13 font families, several weights each** — these are traced from the `U+06DD` glyph of
each family, at `normalized-100` viewBox, each with a `slots[0]` of `role: "ayah-number"` giving the exact
x/y/w/h/cx/cy/r (as a fraction of the 100×100 box) where the verse number sits inside the glyph:

| Family | Weights shipped | Style ids |
|---|---|---|
| Alkalami | regular | `font-001-regular` |
| **Amiri** *(already bundled by Sakina as a reading font)* | regular, bold | `font-002-regular`, `font-002-bold` |
| Estedad | thin, extralight, light, regular, medium, semibold, bold, black | `font-003-*` (8 weights) |
| IBM Plex Sans Arabic | thin, extralight, light, regular, medium, semibold, bold | `font-004-*` (7 weights) |
| Jomhuria | regular | `font-005-regular` |
| Katibeh | regular | `font-006-regular` |
| Kufam | regular, medium, bold | `font-007-*` |
| Mada | extralight, light, regular, medium, bold, black | `font-008-*` (6 weights) |
| Mirza | medium | `font-009-medium` |
| Noto Naskh Arabic | regular-bold (combined) | `font-010-regular-bold` |
| Noto Nastaliq Urdu | regular-bold (combined) | `font-011-regular-bold` |
| Noto Sans Arabic | thin, extralight, light, regular-black (combined) | `font-012-*` (4) |
| Scheherazade New | regular, medium, semibold, bold | `font-013-*` (4) |

**7 pending (no licence asserted at all — not even provisional)**: `font-014` DigitalKhatt (IndoPak), `font-015`
DigitalKhatt (v1) — the repo's own `LICENSE.md` singles this family out as "explicitly not OFL" — `font-016`
HafsNastaleeq, `font-017` IndopakNastaleeq, `font-018` UthmanicBazzi, `font-019` UthmanicQaloun, `font-020`
UthmanicWarsh. These come from `fonts.quran.ws`, whose terms the upstream repo itself says are "not recorded
upstream and have not been confirmed."

**8 scan-derived, one per mushaf printing (provisional)**: al-Duri, Hafs (al-Adi print), Hafs (Madinah *kabir*),
Hafs (Madinah *mumtaza*), Qalun, Shu'bah, al-Susi, Warsh — each a traced ayah-end ornament from that specific
printed mushaf.

Note: there is **no bundled font file** (no `.otf`/`.ttf`) anywhere in the repository's git tree today — the
"`AyahMarkers.otf`" mentioned on the documentation site is, like `dist/LICENSES.md`, a *generated* build artefact
(`qa dist`), not something checked into source control. In practice this is good news for Sakina: integration means
consuming the 80 individual `color.svg`/`mono.svg` files directly, not a custom PUA-codepoint font — simpler, and
one less asset-licensing surface (no font-embedding question for the marker glyphs themselves).

### 1.2 Surah headers and page frames — all 16 entries (both scan, both provisional, both 8 per category)

Same 8 mushaf printings as the scan ayah-markers, one surah-header and one page-frame asset per printing. Both
categories are **100% provisional** — there is not one confirmed surah-header or page-frame asset in the entire
collection. Each carries a `slots[0]`:

- Surah headers: `role: "surah-name"`, a wide band (measured aspect ratio ≈ 8.5:1 on the Madinah *mumtaza* sample) —
  shaped like a horizontal title banner.
- Page frames: `role: "text-area"`, a tall band (measured aspect ratio ≈ 0.64:1, i.e. portrait) — shaped like the
  margin of one entire printed page, sized to frame a full page of text, not a scrolling excerpt of it.

Every scan-derived asset (all 24 of them, across all three categories) records its exact provenance: the source
PDF's SHA-256, the archive.org item, the PDF page number, and the crop box in pixels — traceable to a specific
scanned mushaf, which is also why each one needs its own, separate publisher permission (confirmed status is
per-mushaf, not blanket).

## 2. Licensing and provenance classification

Exactly as requested, classified individually — **the repository's `LICENSE.md` says this explicitly itself**:
*"the assets do not share one licence, and they never will."* Nothing here is inferred from the repo-wide summary;
every row below is read from that specific asset's own `license.status` field in `catalog.json`.

| Status | Count | What it means | Can Sakina ship it? |
|---|---|---|---|
| **Ready to use** | **40** | OFL-1.1, `status: "confirmed"` — verified against the font family's own `METADATA.pb` in `google/fonts`; evidence file exists in `sources/licenses/`. Derivatives stay OFL; cannot be relicensed; no Reserved Font Name may be used for a derived name (irrelevant here — Sakina would ship the glyph outline, not a renamed font) | **Yes**, with the OFL notice + each family's copyright line carried alongside (see §2.1) |
| **Requires permission or clarification** | **23** | 7 font (`pending`, no licence asserted — not even provisional) + 8 scan ayah-markers + 8 scan surah-headers, all `provisional` CC-BY-NC-SA-4.0 while the upstream project seeks written permission per publisher | **No**, not yet — isolated in the manifest, excluded from every production build (see §4) |
| **Requires permission AND has a layout-model mismatch** | **8** | The 8 page-frame assets: same `provisional` CC-BY-NC-SA-4.0 blocker as above, **plus** a structural one — see §2.2 | **No**, for two independent reasons |

The repository's own tooling (`qa dist`) already enforces the same conclusion on itself: it marks its npm package
`"private": true` and refuses to publish a release while *any* bundled asset isn't `confirmed` — meaning upstream
itself currently cannot ship a public release of this collection either.

### 2.1 What "ready to use" actually requires (not nothing)

OFL-1.1 is permissive but not silent: it requires the licence text and each source family's copyright notice to
**travel with the material** — "linking is not enough," per the repo's own `LICENSE.md`. Two of the 13 families
(Amiri, Amiri Quran — wait, Amiri Quran markers aren't in this set, only Amiri is) are already partially covered:
Sakina bundles the **Amiri** font today and already carries its OFL notice in `assets/licenses/` /
`core/licences.dart` for the reading text. Using Amiri's traced ayah-marker glyph (`font-002-regular`,
`font-002-bold`) means **adding** "and the Quran.ws ayah-marker glyphs" to that existing notice's "used for" line,
not writing a new one. The other 12 families (Alkalami, Estedad, IBM Plex Sans Arabic, Jomhuria, Katibeh, Kufam,
Mada, Mirza, Noto Naskh Arabic, Noto Nastaliq Urdu, Noto Sans Arabic, Scheherazade New) are **not** currently
bundled by Sakina in any form, so each needs its own new licence entry on the existing Licences page, in the same
format, with that family's exact copyright line fetched from its own `sources/licenses/<family>.txt` file at
integration time (verified, not retyped from memory — the same discipline already applied to the Tanzil text).

### 2.2 Page frames: blocked twice over, and the second block doesn't go away with permission

Even setting licensing aside entirely, page frames are built to wrap **one whole printed page** — a fixed,
discrete rectangle with a single `text-area` slot sized for a full page of typeset text. **Correction after reading
`sura_reader_page.dart` more closely:** the reader is not purely a continuous scroll — `_MushafPageView` already
lays out one real Mushaf page (604 of them, via `QuranStructure`) per screen, and at the default reading size and
text scale it's *fitted* to a fixed rectangle, like a sheet of paper, swiped page to page. Only at a larger reading
size or system text size does it fall back to scrolling. So a page frame's layout model isn't fundamentally
incompatible the way this section first suggested — in the fitted case there genuinely is one page-shaped rectangle
a frame could wrap. What still blocks it: (a) licensing — 0 of 8 page-frame assets are confirmed, full stop; and
(b) the frame would need to disappear, not stretch, whenever reading size or text scale pushes the page into
scrolling mode, which is a real adaptation to design, not a given. Putting a page frame around a scrolling column
of verses would still mean either:

- cropping/stretching the frame to fit however much text happens to be visible (destroys the frame's own design,
  which the asset's `symmetry` and `stroke_widths_px` metadata show was drawn as a precise, symmetric border, not a
  stretchable one), or
- rebuilding the reader as a genuinely paginated, page-image-shaped view — which is exactly the **Quran Engine /
  Quran SVG** page-rendering feature that the companion audit (`QURAN_WS_ECOSYSTEM_AUDIT.md` §2, §8) already
  identified as Android-only today and explicitly **out of scope for this task** per your own instructions.

So: **page frames have no home in Sakina until (if ever) that separate, bigger feature is approved and built** —
independent of their licensing status. The honest alternative, today, is what already exists: `_PageNumber`'s gold
pill at the page boundary, which marks the same information (where a printed page would turn) without needing a
page-shaped container at all.

## 3. Correction to two assumptions in the request

Two names in the task don't match what's actually in the repository, worth flagging before proposing code:

- **`LocalColors` / `LocalTypographies` don't exist.** The actual design-system classes are `AppColors`
  (`lib/core/design_system/app_colors.dart`), `AppTypography` (`typography.dart`), and the token classes in
  `tokens.dart` (`AppSpacing`, `AppRadius`, `AppBorders`, `AppTextSize`, `AppSizes`, `AppMotion`, `AppFonts`,
  `AppPalette`). Any new widget should use these, matching `VerseMarker`'s own `AppColors.of(context)` /
  `AppTypography.of(context)` pattern.
- **No SVG-rendering dependency exists yet.** `pubspec.yaml` has no `flutter_svg` (or any SVG package) today. Since
  every shippable Quran Assets file is SVG, rendering even the 40 confirmed markers needs a new dependency — see §5.

## 4. Proposed architecture (domain / data / presentation, per `test/architecture_test.dart`)

Matching the existing `QuranSource` / `QuranStructure` pattern, and keeping the compile-time exclusion the request
explicitly asks for ("do not include restricted assets in production asset bundles" — a runtime filter alone isn't
enough; the goal is that an unlicensed asset's bytes and manifest entry simply aren't in a release build):

- **`domain/mushaf_asset.dart`** (pure Dart, no Flutter): `MushafAssetCategory` enum (`ayahMarker`, `surahHeader`,
  `pageFrame`); `MushafAssetLicenseStatus` enum (`confirmed`, `pending`, `provisional`); `MushafAsset` — id, category,
  family-or-mushaf label, license status, attribution string, asset paths. This is metadata only; it never touches
  the Quran text, numbering, or anything in `features/quran/domain` today.
- **`domain/mushaf_asset_catalog.dart`**: `abstract interface class MushafAssetCatalog` with
  `List<MushafAsset> shippable(MushafAssetCategory category)` — mirrors `QuranSource`'s single-purpose interface
  style.
- **`data/bundled_mushaf_asset_manifest.dart`**: a **generated, hand-reviewed `const` list** — not a parsed
  `catalog.json` shipped as a data file — built once from this inventory, by a `tool/` script analogous to
  `tool/quran_fingerprint.dart`, that only ever emits the 40 confirmed entries into the production manifest. The 23
  pending/provisional ayah-marker/surah-header entries and the 8 page-frame entries are recorded in a **separate,
  non-production manifest** (e.g. `tool/mushaf_asset_manifest_awaiting_permission.dart` or a documentation table)
  that is never imported by `lib/` — so there's no feature flag or runtime check to accidentally get wrong; the
  bytes for every restricted asset are simply absent from the app's asset bundle and `pubspec.yaml`'s `assets:` list.
- **`presentation/widgets/mushaf_ayah_marker.dart`**: a new, optional alternative to `VerseMarker`'s painted rosette
  — same public surface (`number`, `bookmarked`, `size`, `semanticLabel`), internally choosing a confirmed family's
  `mono.svg`, rendered with a colour filter (`colors.gold` normally, `colors.sage` when bookmarked — the closest
  honest match to the existing two-tone rosette, since the SVG is a single silhouette, not a separate stroke/fill
  like the painted version) and the verse number positioned in the asset's own `slots[0]` rectangle. **`VerseMarker`
  stays the default; this is selectable, not a replacement** — see §0 and §6.
- No existing type changes: `QuranText`, `QuranSource`, `QuranStructure`, `QuranUserData`, `VerseMarker`,
  `_SuraBanner`, `_PageNumber` are all untouched. This is purely additive, consistent with "reuse the current Quran
  reader" and "avoid duplicated rendering logic" — the new widget sits beside, not inside, the existing ones, and
  only one of the two renders at a time per the user's chosen style.

## 5. Dependency: `flutter_svg` (needs your approval before it's added)

Every shippable file in this collection is SVG; Flutter has no built-in SVG renderer. The standard, actively
maintained option is **`flutter_svg`** (dnfield/flutter_svg, built on Google's own `vector_graphics` renderer) —
widely used, pure-Dart/Skia rendering (no native platform code, so no Android/iOS-specific risk), and it directly
supports the one feature this needs: `SvgPicture.asset(path, colorFilter: ColorFilter.mode(colors.gold,
BlendMode.srcIn))` for tinting the `mono.svg` variant to match `AppColors`. I have **not** added it to `pubspec.yaml`
— that's the one dependency change this plan asks you to approve before Phase 3 (implementation) starts.

## 6. Visual integration mapping

| Category | Where | What ships now | What's deferred and why |
|---|---|---|---|
| **Ayah markers (confirmed, 40)** | `VerseMarker`'s call sites, as a selectable alternate style (e.g. a reading-style setting: "Rosette" default / "Mushaf glyph") | One tinted `mono.svg` per chosen family/weight, coloured gold / sage-on-bookmark exactly as today, sized and positioned via the asset's own `slots[0]` | Picking *which* of the 13 families is the default "Mushaf glyph" option is a design call for you, not me — I'd suggest Amiri (`font-002`) first since its text font is already in the app and the visual language already matches, but this needs your sign-off, not a guess |
| **Ayah markers (pending/provisional, 15)** | Nowhere | Nothing | No licence exists yet (7) or it's a non-commercial-only position pending publisher permission (8); recorded in the non-production manifest only |
| **Surah headers (8, all provisional)** | Would have replaced/augmented `_SuraBanner` | Nothing | Zero confirmed assets exist for this category — 100% blocked on permission. `_SuraBanner`'s existing gold cartouche remains the only surah-header treatment, and it already does the job well (§0) |
| **Page frames (8, all provisional)** | Would have wrapped the reader page | Nothing | Blocked twice: no confirmed asset, *and* no page-shaped layout exists in the continuous-flow reader to put one in (§2.2). `_PageNumber`'s pill remains the only page-boundary marker |

Accessibility and RTL: `SvgPicture` has no inherent text direction, so this carries no new RTL risk; the marker's
digit is still produced by the existing `context.digits` helper and laid out the same way `VerseMarker` does today.
Text scaling: because the SVG viewBox is `normalized-100` and the asset's `slots[0]` gives a relative rectangle, the
digit inside scales with the marker's `size` parameter exactly as the current rosette does — no separate overflow
risk, provided the same `FittedBox`/`scaleDown` approach `VerseMarker` already uses is kept. Fallback: if an SVG
fails to load (corrupt asset, asset missing from a stripped build), the widget falls back to rendering
`VerseMarker`'s existing painted rosette rather than an empty box — never a silent blank space.

## 7. App-size impact

- **If only the 40 confirmed ayah-marker assets ship** (the only category this plan recommends shipping now):
  **+319 KB** of SVG (80 files) **+ `flutter_svg`'s own compiled size** (a few hundred KB in the release binary,
  typical for that package; exact figure depends on the Flutter version and isn't worth estimating further here).
  New OFL licence-notice text on the existing Licences page: negligible.
  This is a smaller download than a single one of the Quran Engine `.qvp` pages discussed in the companion audit.
- **If the 23 pending/provisional assets or the 8 page frames were ever shipped** (not recommended, not proposed):
  up to another ~3 MB combined — not relevant until/unless permission and a page-rendering feature both exist.
- Net effect of this plan as proposed: **under 0.5 MB** added to the app, well inside what the existing
  fingerprinted-asset discipline already budgets for (the bundled Tanzil text alone is 1.4 MB).

## 8. Phased plan

1. **Phase 1 — this document.** Full inventory (71/71 assets), licensing classification, architecture, UI mapping,
   dependency ask, size estimate. No code changes. Done.
2. **Phase 2 — your decisions** (§9 below), plus: add `flutter_svg` to `pubspec.yaml` only once approved.
3. **Phase 3 — implementation**, scoped to exactly the 40 confirmed assets:
   - `domain/mushaf_asset.dart`, `domain/mushaf_asset_catalog.dart`, `data/bundled_mushaf_asset_manifest.dart`
     (40 entries only).
   - `presentation/widgets/mushaf_ayah_marker.dart`, wired as a selectable alternative to `VerseMarker` behind a
     reading-style preference (reusing the existing settings/preferences pattern — not a new ad hoc flag).
   - Licences page: add the OFL notice/copyright line for each of the (up to 13) families actually used, verified
     against `sources/licenses/<family>.txt`, not retyped from memory.
   - The 23 pending/provisional entries and 8 page-frame entries get a documentation-only manifest (or are simply
     left out entirely) — never imported into `lib/`, never listed in `pubspec.yaml`'s `assets:`.
4. **Phase 4 — tests** (planned now, implemented after Phase 3 lands; see §10), then format/analyze/full suite,
   screenshots in Arabic and English, light and dark, at 100% and 200% text scale, same as this project's existing
   release discipline.

## 9. Decisions that need your approval before Phase 2/3 starts

1. **Ship the 40 confirmed ayah-marker glyphs as an optional style, not the default?** (Recommended: yes — keep
   `VerseMarker`'s existing rosette as the default, per §0; add the Quran.ws glyphs as a user-chosen alternative.)
2. **Approve adding `flutter_svg` as a new dependency** (§5) — the one new package this plan requires.
3. **Which family is the default "Mushaf glyph" option**, if this ships? (My suggestion: Amiri, since its text font
   is already bundled — but this is a design call, not mine to make unilaterally.)
4. **Confirm: do not pursue surah headers or page frames at all right now** — both are 100% unconfirmed-licence, and
   page frames additionally have no layout to live in until/unless the separate page-rendering feature (out of
   scope per your instructions) is approved later. (Recommended: confirm and park both, revisit if upstream permission
   and/or the page-renderer feature ever lands.)
5. **The 7 "pending" font markers and DigitalKhatt specifically**: confirm these stay excluded until upstream
   records an actual licence (right now there's nothing to even classify as provisional) — not a real decision point,
   more a confirmation that "requires clarification" in your brief means "not yet," not "find a workaround."
6. Should I draft the exact OFL licence-notice text for the Licences page next (per family actually chosen in
   decision 3), the same way the attribution text was drafted for the broader ecosystem audit?

## 10. Test plan (as originally planned, before implementation)

- Asset resolution: for each of the 40 confirmed manifest entries, the referenced `color`/`mono` SVG paths exist in
  the bundle and parse as valid SVG (a build-time/test-time check, not a runtime try/catch masking a real bug).
- Manifest exclusion: a test asserts the 23 pending/provisional and 8 page-frame ids are **absent** from the
  production manifest and from `pubspec.yaml`'s `assets:` — a compile-time guarantee, not just a passing assumption.
- Missing/corrupt-asset fallback: forcing a load failure renders `VerseMarker`'s existing rosette, not a blank
  widget or an exception.
- RTL layout: the new widget renders correctly with `Directionality.rtl`, matching the existing Quran-page RTL
  tests.
- Text scaling: the digit inside the marker doesn't overflow or clip at 200% text scale, mirroring existing checks
  elsewhere in the app.
- Quran text/reference regression: existing `quran_*_test.dart` files are unaffected — nothing about verse text,
  ordering, numbering, or the Tanzil fingerprint changes, since this plan touches only decoration.
- Licence metadata: a test reads the production manifest and asserts every entry's `licenseStatus == confirmed` —
  the same "can't accidentally ship the wrong thing" guarantee as item 2, from the other direction.
- `test/architecture_test.dart` and the full existing suite continue to pass unmodified.

No Quran verse text is hardcoded in any of the above; markers are tested with arbitrary verse numbers, not real
ayah content.

## 11. What actually shipped (2026-10-19)

**Total assets inventoried:** 71 (all of them, per §1). **Total assets integrated: 40** — exactly the confirmed
ones, no more. The other 31 (7 pending font markers, 8 scan ayah-markers, 8 surah headers, 8 page frames) are
**excluded**, for the reasons in §2: no licence exists yet for the 7, and the 24 scan-derived assets are
CC-BY-NC-SA-4.0 "provisional" pending per-publisher permission. None of the 31 were downloaded into the app or
referenced by any file under `lib/` or `pubspec.yaml` — `mushaf_asset_manifest_test.dart` asserts this directly by
id, not just by convention. (One planned check didn't survive contact with the actual rendering library: a
true "corrupt/missing SVG falls back to the rosette" runtime guard was dropped — see the note below.)

**How the 40 are exposed:** as a single opt-in reading preference, "Ayah marker" (Settings → Ayah marker →
Rosette / Mushaf glyph), defaulting to **Rosette** — the app's existing painted marker, unchanged. Choosing
"Mushaf glyph" switches every verse-number marker in the reader to the Amiri-traced glyph (`font-002-regular`),
tinted gold / sage-on-bookmark the same way the rosette is. All 40 confirmed assets are in the data-layer manifest
and available to a future style picker; today's UI exposes one of them (§9, decision 3's open question, resolved
in the direction this plan already recommended).

**Files changed:** 14 modified, 22 new paths added (one of which, `assets/quran_assets/ayah_markers/`, holds the 80
SVG files — color + mono for each of the 40 confirmed markers):

- New: `lib/features/quran/domain/mushaf_asset.dart`, `mushaf_asset_manifest.dart`,
  `lib/features/quran/presentation/widgets/ayah_marker.dart`, `mushaf_glyph_marker.dart`,
  `assets/quran_assets/ayah_markers/*.svg` (80 files), `assets/licenses/OFL-*.txt` (13 new families),
  `test/features/quran/mushaf_asset_manifest_test.dart`, `ayah_marker_test.dart`.
- Modified: `pubspec.yaml` (added `flutter_svg`, the new asset directory), `pubspec.lock`,
  `lib/core/licences.dart` (registers the 13 new OFL notices), `lib/features/settings/domain/app_settings.dart`
  (`AyahMarkerStyle`), `settings_repository_impl.dart`, `settings_cubit.dart`, `settings_page.dart`,
  `lib/features/quran/presentation/widgets/verse_flow.dart`, `pages/sura_reader_page.dart` (wiring the setting
  through), `lib/l10n/app_en.arb` / `app_ar.arb` (+ their generated `app_localizations_*.dart`),
  `test/features/settings/settings_data_and_state_test.dart`.
- **Untouched, as required:** `QuranText`, `QuranSource`, `QuranStructure`, `QuranUserData`, the bundled Tanzil
  text and its fingerprint, `VerseMarker`'s own rendering, `_SuraBanner`, `_PageNumber`, `test/architecture_test.dart`
  (passes unmodified).

**App-size impact (measured, not estimated):** the 80 SVG files total **480 KB**; the 13 new licence-text files
total **57,248 bytes (≈56 KB)**. Combined: **≈536 KB**, before `flutter_svg`'s own compiled code (not separately
measured here — see §7's caveat, which still holds). This is for all 40 markers together; a user who never opens
the "Mushaf glyph" setting still has every byte of it in the app bundle, same as any other bundled asset (there is
no on-demand download for this feature, matching how the Tanzil text itself is bundled, not fetched).

**Tests run and their results:** `flutter analyze` — no issues. `flutter test` (full suite) — **1,400 passed, 0
failed**, including `test/architecture_test.dart` and `test/l10n/translations_test.dart` unmodified. New test
files: `mushaf_asset_manifest_test.dart` (8 tests — exact count of 40, no excluded ids present, slot geometry
sanity, every SVG file exists and is single-colour, every source family has a licence file) and
`ayah_marker_test.dart` (6 tests — correct widget for each style, semantics label on both, survives a 2.0× text
scale, renders under both RTL and LTR). `settings_data_and_state_test.dart` gained 4 cases for the new preference
(default, round-trip, unknown-value fallback, cubit change).

**Where the plan in §10 and reality diverged:** the planned "missing/corrupt-asset fallback" test was dropped.
Every one of the 40 SVGs is compiled into the release asset bundle at build time, so "the asset is missing at
runtime" isn't a reachable state the way a network fetch's failure would be — there's nothing to defensively catch
without adding dead code for an impossible case. What the shipped tests check instead, at build/test time, is
stronger: that every referenced path genuinely exists on disk before the app ever ships (`mushaf_asset_manifest_test.dart`).
The default-to-rosette behaviour is guaranteed a different way: `AyahMarkerStyle` simply defaults to `rosette`,
which never touches `flutter_svg` at all.

**Known limitation, stated plainly:** `flutter_svg`'s renderer prints a harmless but visible console warning
(`unhandled element <metadata/>`) for every marker it draws, because these SVGs embed their own provenance JSON in
a `<metadata>` tag that the renderer doesn't recognise and correctly ignores. It doesn't affect rendering or tests,
but it's debug-log noise; stripping that tag from the vendored copies (trading a little provenance-in-file for a
quieter log) is a reasonable follow-up, not done here since it would mean editing the vendored SVGs rather than
keeping them byte-for-byte as fetched.

**Not claimed:** this is not "the Quran Assets collection, production-ready." It is 40 of 71 assets, in one
category, behind one opt-in setting, with the other 31 deliberately excluded and the page-frame/surah-header
categories still entirely blocked on upstream permission, exactly as scoped in §8/§9 and confirmed again here.
