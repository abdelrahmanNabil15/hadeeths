# Hadeeths — UX Audit and Redesign Proposal (for approval; nothing implemented)

Date: 2026-10-09. Builds on `docs/PHASE0_REVISED_AUDIT.md` (finding IDs F-xx refer to it).
Evidence sources: repository code; three committed 2022 device screenshots; a scratch web build rendered at
375×812 (after a one-line patch to compile — categories screen only); live HadeethEnc API probes.
**Not tested:** list and details screens in the current build (a tap in my browser session did not navigate; the 2022
screenshot is the only list/detail evidence), any Android/iOS device, text scaling, dark mode, TalkBack.

> ## Status (implemented on branch `redesign/ui-refresh`)
>
> **Applied as proposed:** ivory/emerald light palette and dark palette (all pairs at least 4.5:1, control borders at least 3:1,
> checked in tests); Cairo for the interface and Amiri for Arabic reading text (compared on a real device; licence verified
> as SIL OFL 1.1 from the font files); home with intro, search entry, root categories and a sources link; category page with
> an emphasised "all hadiths" entry; hadith list; details with title, reading surface, grade chip, narrator, expandable
> sections and the HadeethEnc credit; search; settings (language, appearance, reading size); sources and rights screen;
> skeleton, empty and error states; accessibility checks; 200% text on a 360x640 phone.
>
> **Deviations, with reasons:**
> - `hadeeth_intro` is **not** displayed: it is the opening words of `hadeeth` (the narrator chain), so showing both would
>   repeat text.
> - Details sections start collapsed so the hadith stays the focus; explanation and sources can still be shared.
> - No bottom navigation and no onboarding screen (one browse path plus search did not justify them).
> - No offline banner: errors are reported by the request itself; offline reading is blocked on HadeethEnc permission.
> - The photographic backdrop was removed (it removed the unresolved Rawpixel licence question and 36 MB of decoded memory).
> - Digits stay Western in both languages (decision not given).
>
> **Not built:** bookmarks, recents and continue-reading (they need local storage of content or ids and a decision on
> HadeethEnc permission), share-as-image, daily hadith.

---

## 1. UX audit

### 1.1 Screen inventory

| # | Screen / surface | File | Purpose today | State handling |
|---|---|---|---|---|
| 1 | Categories ("التصنيفات الرئيسية") | `hadeethsCategory.dart`, `Widget.dart:17-145` | 2-column grid over a full-bleed background; tap → list | Spinner only; "disconnected" text in English; no error state |
| 2 | Hadith list | `hadeeths.dart`, `Widget.dart:146-217` | Cards with title and back-chevron; tap → details | Spinner only; fake load-more; list length from metadata |
| 3 | Hadith details | `hadeethsdetails.dart`, `Widget.dart:218-566` | Text, grade, narrator line, share; rows that open sheets | Spinner only; "not data" placeholders |
| 4 | Sheet: explanation / sources | `DraggableScrollableSheet.dart` | Long text + share | none |
| 5 | Sheet: benefits (الفوائد) | inline in `Widget.dart:342-439` | Numbered hints | none |
| — | Navigation | `Navigator.push` ×3 | Linear drill-down: categories → list → details | no tree, no search, no history |

Routes: 3. State controllers: 1 (`AlmunirCubit`, one instance per screen). API calls used: `categories/list`,
`hadeeths/list`, `hadeeths/one`. Assets: `Cairo.ttf` (used as family "Schyler"), `subfont.ttf` (unused),
`backgruond.jpg` (6.2 MB; licence unverified, F-05), no icon set beyond Material/Cupertino.

### 1.2 What works and should be preserved
- Arabic-first, calm tone; the warm parchment backdrop idea reads well and fits the content.
- Cairo is legible for headings; the sheet pattern for secondary material (explanation, sources) is sensible.
- Existing share action (text + grade + attribution).
- Simple, shallow structure: three levels are easy to understand.

### 1.3 Problems (evidence in parentheses)

| ID | Sev | Problem | Evidence |
|---|---|---|---|
| U-01 | P1 | "Main categories" mixes roots with sub-categories; 473 of 493 categories are unreachable; hierarchy (5 levels) invisible | rendered screenshot: "نزول القرآن وجمعه", "تفسير القرآن", "القراءات والتجويد" are children of category 1 shown beside roots |
| U-02 | P1 | No error, empty or offline design; failure = endless spinner | `Widget.dart:128-144,209-213,560-564` |
| U-03 | P1 | Crash on lists whose count mismatches metadata | `Screenshot_20220228_163757.png` (`RangeError 450`) |
| U-04 | P1 | English placeholders ("not data") and English offline text inside an Arabic app; empty sections shown as "not data" instead of being omitted | `Widget.dart:241,261,289…`; `hadeethsCategory.dart:44` |
| U-05 | P1 | No attribution of the source (HadeethEnc requires crediting publisher and source) | code: no occurrence of "HadeethEnc" in `lib/` |
| U-06 | P2 | Contrast: white title on pale beige measures **1.11:1**; WCAG AA needs 4.5:1 | computed from `hadeethsCategory.dart:32-38` |
| U-07 | P2 | No semantics, tooltips or labels anywhere; share is an unlabelled icon | grep: zero `Semantics`/`tooltip`/`semanticLabel` |
| U-08 | P2 | Text and tap targets: gesture rows have no minimum size; fixed-aspect grid cells will clip at large text scales | `Widget.dart:44-48,299-337` |
| U-09 | P2 | No search, though the API provides server-side search | F-27 |
| U-10 | P2 | Details screen is a single long column with equal-weight 24 px headings; no distinction between the hadith (primary) and everything else | `Widget.dart:226-555` |
| U-11 | P2 | Back chevrons: `arrow_back_ios` used as a forward indicator; direction logic is manual | `Widget.dart:191,325,444` |
| U-12 | P2 | Backdrop image behind controls reduces legibility and costs memory | rendered screenshot; asset 2250×4000 |
| U-13 | P3 | No app bar title on details; no sense of location in the category tree | `hadeethsdetails.dart:30-32` |

### 1.4 Functional constraints (from the API; do not design beyond these)

- **Categories:** `id`, `title`, `hadeeths_count`, `parent_id` (all strings; counts string). 493 total, 7 roots, depth 5. A parent
  category lists its own hadiths (root 1: 197 items; its five children sum 209, so membership overlaps — do not
  present parent counts as sums of children).
- **List item:** `id`, `title` (up to 182 chars in a sample), `translations` (language codes). **No text preview exists**; do not design one.
- **Detail (ar):** `title`, `hadeeth_intro` (non-empty in 15 of 60 sampled), `hadeeth` (101–1,374 chars, median 204, fully diacritized),
  `attribution`, `grade`, `explanation` (up to 1,868 chars), `hints[]`, `words_meanings[]` (non-empty 41/60), `reference`,
  `categories`, `translations`. In the 60-hadith sample from one category, grade/attribution/reference/explanation/hints were always present
  and grade took the values «صحيح» and «حسن». That sample is one category only — design for any field being empty.
- **Non-Arabic detail:** no `reference`, no `words_meanings`; extra `*_ar` fields.
- **Search:** `id`, `title`, `hadith_text`, `hadith_text_highlights` (with `<mark>` tags); phrase ≥ 3 chars (2 chars → HTTP 400); max 100 results; no pagination.
- **No** ratings, popularity, authenticity scores beyond `grade`, images, audio or user data. None will be invented.

### 1.5 Prioritized improvements
1. Correct the data model of browsing (U-01), states (U-02), and the crash (U-03) — these are Phase 2 fixes, specified here for design.
2. Reading experience of the details screen (U-10, U-06, U-08).
3. Attribution and "About & sources" (U-05) — compliance, not decoration.
4. Search (U-09) using the existing endpoint.
5. Accessibility pass (U-07, U-08, U-11).
6. Visual system (U-12) after the licence decision on the backdrop.

---

## 2. Design direction

**Principle: the text is the interface.** Everything else recedes. A user arrives to find a hadith, reads it
with its source and grading, and leaves, or continues. The design must feel like a well-set book, not a dashboard.

**Why this fits an Arabic-first knowledge app:** the content is long-form, diacritized Arabic where legibility and
trust are paramount; a warm paper surface lowers glare during long reads; one restrained accent signals care
without ornament; and a single clear hierarchy (title → hadith → source/grade → explanation) mirrors how the
material is traditionally presented.

Treated as hypotheses to confirm with device screenshots (Step 1 of implementation), not final:

### 2.1 Colour tokens (contrast computed with the WCAG 2.x formula; ratios against the stated background)

| Token | Light | Dark | Use | Contrast (light / dark) |
|---|---|---|---|---|
| `background` | `#FAF6EC` | `#0F1512` | app canvas | — |
| `surface` | `#FFFDF8` | `#161F1A` | reading surface, cards | — |
| `ink` | `#1C1B17` | `#ECE6D6` | body, hadith text | 15.97 / 14.83 on background |
| `inkMuted` | `#5B5446` | `#B3AC9B` | metadata, hints | 6.95 / 8.18 |
| `primary` (emerald) | `#0E5A47` | `#6FCBAA` | actions, selected state, links | 7.57 / 9.50 |
| `onPrimary` | `#FFFFFF` | `#06231B` | text on primary | 8.16 / 8.54 |
| `accent` (muted gold) | `#8A6A1F` | `#D9B35B` | grade chip, small marks only | 4.68 / 9.28 |
| `error` | `#A12A2A` | `#F29A9A` | error text/icons | 6.76 / 8.68 |
| `divider` | `#E4DCC8` | to define | decorative rules only | 1.27 (not for control boundaries) |
| `outline` | to define | to define | input/button borders; must reach 3:1 | validate in step 1 |

Rules: at most one accent per screen; colour never alone conveys state (grade chip carries the word; errors carry an icon and text); no gradients; no shadows except one low elevation level.

### 2.2 Typography (candidates; selection requires on-device Arabic shaping and diacritics checks)

| Role | Proposal | Notes |
|---|---|---|
| UI (titles, buttons, metadata) | **Cairo** (already bundled, OFL 1.1 verified) | keep, drop the misleading family name "Schyler" |
| Hadith / explanation reading text | Naskh-style face with strong diacritics support, e.g. **Amiri** or **Noto Naskh Arabic** | licence (OFL expected) **not yet verified**; compare against Cairo at 18–22 sp with full tashkeel before choosing |
| Quran text | out of scope here | blocked by licensing (audit §7) |

Type scale (sp, scales with user setting; no hard caps): `display` 28, `title` 22, `heading` 18 (w600), `body` 16, `reading` 20 (line-height ≥ 1.9 for diacritized text; user-adjustable 16–28), `meta` 14, `label` 14 (w600). Minimum text 12 sp only for non-essential captions.

### 2.3 Space, shape, motion, icons
- Spacing 4-pt scale: 4, 8, 12, 16, 24, 32, 48. Page gutters 16 (phones), content max width ~640 on larger screens, centred.
- Radii: 8 (controls), 12 (cards), 16 (sheets). Elevation: 0 and 1 only.
- Touch target ≥ 48×48 dp; row min height 56.
- Motion: 150–250 ms ease-out for press, expand, and route fade-through; none for decoration; honour reduced-motion (`MediaQuery.disableAnimations`).
- Icons: Material Symbols Rounded outlined, one weight; directional icons use `Icons.*` that respect `Directionality` (or `matchTextDirection`), never hand-flipped.
- Islamic geometry: a single small ornament on the empty/onboarding/About surfaces only. **No pattern behind Arabic text.**
  The existing backdrop is **not** carried over (F-05, U-12).

### 2.4 RTL rules
`MaterialApp.locale = ar` (with `en` available), directionality from the locale, `EdgeInsetsDirectional`/`AlignmentDirectional`
everywhere, no `TextDirection.rtl` literals in widgets (removes `CustomText.dart:37`), no string reversal, numerals
presentation configurable (Arabic-Indic vs Western) pending your choice, parentheses and references verified in mixed text.

---

## 3. Design system specification

Location proposal: `lib/core/design_system/` — `tokens.dart` (colours, spacing, radii, durations), `theme.dart`
(light/dark `ThemeData`, Material 3), `typography.dart`. Components only where reused on ≥ 2 screens:

| Component | Used by | Replaces |
|---|---|---|
| `AppScaffold` (app bar + safe areas + max-width body) | all screens | per-screen `Scaffold` |
| `SearchEntry` (tap-through field) / `SearchField` | home, search | none |
| `CategoryTile` (title + count + chevron, min 56 dp) | roots, children | grid cards (`Widget.dart:53-120`) |
| `HadithListTile` (title ≤ 3 lines, chevron) | list, search | `Widget.dart:164-203` |
| `ReadingSurface` (hadith text block, size control applied) | details, search | inline `Customtext` |
| `SourceBlock` (attribution, grade chip, reference) | details | inline rows |
| `ExpandableSection` (explanation, benefits, word meanings, sources) | details | `Widget.dart:299-553` and both sheet implementations |
| `StateView` — loading skeleton / empty / error+retry / offline | all lists | spinners and "not data" |
| `OfflineBanner` | app shell | `hadeethsCategory.dart:40-49` |
| `AppButton` (primary/secondary), `AppBottomSheet` | share, retry | ad-hoc |

Not built unless needed: bottom navigation, a theme-switch screen, onboarding.

---

## 4. Screen specifications

Navigation decision: **no bottom navigation in the first redesign.** The app has one browse path and one search
entry; a tab bar for a single destination is decoration. Revisit only if Saved/Recents (new features, §5) are approved —
then `Browse | Search | Saved` becomes justified. Browse depth uses a breadcrumb/title trail, not tabs.

### 4.1 Home / Browse (replaces Categories)
- **Purpose:** find a topic or search. **Primary task:** choose a root category or open search.
- **Hierarchy:** app title + short description (static text, no claims) → `SearchEntry` → list of the 7 roots from `categories/roots` (title + `hadeeths_count`) → footer link "المصادر والحقوق".
- **Interaction:** tap tile → Category screen. Pull to refresh.
- **Loading:** skeleton tiles. **Empty:** "تعذّر العثور على تصنيفات" + retry (should not occur; roots=7). **Error:** icon + plain message by `Failure` type + "إعادة المحاولة". **Offline:** banner "أنت غير متصل" and, only if cached data exists (Phase 4), "عرض المحتوى المحفوظ"; before Phase 4 the offline state says content needs a connection and offers retry.
- **A11y:** each tile one semantic node ("التصنيف: …، عدد الأحاديث …"); search entry announced as a button.

### 4.2 Category (new level; makes hierarchy reachable)
- **Purpose:** drill into sub-categories or read this category's hadiths. Built from `parent_id` (client-side tree from `categories/list`, fetched once).
- **Hierarchy:** title trail (back = parent) → "كل أحاديث هذا التصنيف (N)" primary row → child tiles (if any).
- **Edge:** leaf categories skip straight to the list. Parent counts shown as the API's own number.
- States as 4.1.

### 4.3 Hadith list
- **Purpose:** scan titles quickly. Item = title only (≤ 3 lines, ellipsis after, full title on details), chevron that follows text direction. **No preview, no grade** (not in the list payload).
- **Paging:** `page`/`per_page=20`, load next page when within 5 items of the end; footer states: loading, "تعذّر تحميل المزيد — إعادة المحاولة", end-of-list. List length is always `items.length`.
- States: skeleton, empty ("لا توجد أحاديث"), error+retry, offline as 4.1; refresh keeps existing items visible on failure.
- **A11y:** whole row focusable, min 56 dp, semantics "حديث: {title}".

### 4.4 Hadith details (reading)
- **Purpose:** read comfortably, see source and grade, optionally read the explanation. Order: title → `hadeeth_intro` (if present) → **hadith text** (reading surface, largest) → source row (attribution, grade chip with the word, **no colour-only meaning**) → expandable sections in order: explanation, benefits, word meanings, reference → attribution footer "المصدر: HadeethEnc.com" (+ API version note when available).
- **Rules:** sections with no data are **omitted** (no "not data"); source text rendered exactly as received; selectable text; no truncation of hadith text.
- **Controls:** share (existing feature; adds the attribution line); text-size control (A− / A+) is a **small new feature** needing approval (stored in `shared_preferences`).
- **States:** skeleton, error+retry, not-found (404 body empty → "لم يعد هذا الحديث متاحًا"), offline as above.
- **A11y:** headings marked as headers; expandable sections announce expanded/collapsed; text scales to 200% without clipping; grade chip has a semantic label «الدرجة: صحيح».

### 4.5 Search (new surface for an existing, unused API feature — **needs approval**)
- **Purpose:** find a hadith by word. Field with clear (✕) button; hint "اكتب ٣ أحرف أو أكثر".
- **Behaviour:** debounce 400 ms, minimum 3 characters (API returns 400 below that — show guidance, don't call), cancel in-flight requests, show up to 100 results with an honest note when 100 are returned ("عرض أول ١٠٠ نتيجة، حدّد بحثك"), no paging.
- **Result item:** title + snippet from `hadith_text_highlights` rendered as styled spans for `<mark>` (parsed, never HTML-injected; underlying text untouched).
- **States:** idle guidance, loading, no results ("لا نتائج لـ «…»"), error+retry, offline ("البحث يحتاج اتصالًا بالإنترنت"). Arabic normalization is done by the server (verified: «النية» matched «بِالنِّيَّةِ»); **no local index** in this stage.

### 4.6 About & sources (compliance screen)
Lists HadeethEnc credit and terms link, fonts with OFL notice, and (when adopted) Tanzil notice + link. Reached from the Home footer. Classified as a **compliance requirement**.

### 4.7 Cross-cutting
Light theme first; dark theme tokens above are proposed and require approval before implementation. English locale supported by the same components; detail parsing must handle missing `reference`/`words_meanings` (F-10).

---

## 5. Feature classification

| Item | Class | Needs approval |
|---|---|---|
| Roots/children browsing, states, paging, attribution, a11y, RTL, theming | Redesign / fix of existing | No (sequenced in Phase 2 and 5) |
| Share with attribution line | Redesign of existing | No |
| Search screen | New feature (existing API) | **Yes** |
| Text-size control | New small feature | **Yes** |
| Bookmarks / Recents / Continue reading | New features | **Yes**. Note: storing only IDs locally is not "caching content"; storing titles or text locally is, and is **blocked** until HadeethEnc permission. Offline-readable bookmarks are blocked likewise |
| Dark theme | New | **Yes** |
| Share-as-image | New | **Yes**; must carry attribution; needs a text-fidelity check |
| Reminders / notifications | New, Phase 6 | **Yes**, and a design review of platform limits |
| Fabricated recommendations, streaks, counters, "hadith of the day" | **Not proposed** (no API support; a "daily" pick would be our own curation → needs sign-off by a qualified reviewer if ever added) | — |

---

## 6. Implementation plan (visual vs functional separated)

Prerequisites: Phase 1 (build) and Phase 2 (correctness) must land first; otherwise the UI work cannot run or sits on wrong data.

| Step | Type | Files | Notes |
|---|---|---|---|
| D1 | Visual | new `core/design_system/{tokens,theme,typography}.dart`, `main.dart` theme block (`main.dart:44-63`), fonts in `pubspec.yaml` | Tokens + Material 3 theme + locale; no screen changes yet. Validate contrast on device |
| D2 | Visual + small functional | replace `Customtext`, `constant.dart` usage; `StateView`, `AppScaffold` | One representative flow only: Home → Category → List |
| D3 | Functional (Phase 2 dependency) | cubit/repository for roots, tree, paging | Not part of the redesign commit |
| D4 | Visual | `ReadingSurface`, `SourceBlock`, `ExpandableSection`, details screen | Replaces `Widget.dart:218-566` and `DraggableScrollableSheet.dart` |
| D5 | Compliance | About & sources, attribution footer | After D4 |
| D6 | New (approved only) | search, text-size, dark theme | Each separately |
| D7 | Visual | remove backdrop usage; delete only after F-05 resolved | Do not delete assets before provenance is settled |

Files expected to stay unchanged in the redesign: `endpoint.dart`, `DioHelper.dart` (until Phase 3), models (until F-10).
Dependencies: none new for D1–D5 beyond fonts; `shared_preferences` only if text-size is approved; `flutter_localizations` + `intl` for gen-l10n.
Risks: font choice may not shape diacritics well (mitigate with a side-by-side device test before commit); `ExpandableSection` a11y
semantics (test with TalkBack); long titles/references overflow (golden tests with 182-char and 1,400-char fixtures).

---

## 7. Acceptance criteria and test plan

| Area | Criterion | How verified |
|---|---|---|
| Contrast | Body ≥ 4.5:1, large text/controls ≥ 3:1 in light and dark | computed token test + manual check on device screenshots |
| Text scale | 100%, 150%, 200% without clipping/overflow on 360×640 and 412×915 | widget tests with `textScaler`; device run |
| RTL | No LTR artefacts; chevrons follow direction; mixed-script strings render correctly | widget tests under `Directionality.rtl` and `ltr`; manual |
| States | Loading/empty/error/offline exist for every list/detail screen; no endless spinner | widget tests per state with fake repository |
| Data fidelity | Rendered hadith text equals the API string byte-for-byte | unit test comparing rendered `Text` to fixture |
| Long content | 182-char title and 1,374-char hadith display fully | golden tests |
| Attribution | HadeethEnc credit visible on details and share output | widget + share-text test |
| Semantics | Every interactive element has a label; headers marked | `meetsGuideline(labeledTapTargetGuideline, androidTapTargetGuideline, textContrastGuideline)` tests; TalkBack run |
| Reduced motion | Animations disabled when the platform requests it | widget test |
| Builds | `analyze`, `test`, `build apk` PASS | recorded as PASS/FAIL/BLOCKED/NOT RUN per phase |
| Devices | Report only configurations actually run (emulators/phones) | explicit list in the final report |

---

## 8. Decisions needed from you

1. Approve the direction in §2 (ivory/emerald/ink, Cairo + a Naskh reading face), or name your existing brand colours.
2. Approve search (§4.5), text-size control, dark theme — each independently.
3. Do you want bookmarks/recents? If yes, are IDs-only (online re-fetch) acceptable until HadeethEnc permission?
4. Which layer first: confirm that Phase 1 and 2 come before any UI work (recommended).
5. Numerals: Arabic-Indic or Western digits?
