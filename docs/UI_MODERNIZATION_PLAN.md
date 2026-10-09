# Hadeeths — UI/UX Modernization, Design System and Motion: audit and plan

> **Status (2026-10-09): plan approved by the owner. Phase A implemented on branch `ui/a-foundations`; see section 24.**

Date: 2026-10-09. **Status: proposal only. No application code, assets, dependencies or configuration were changed to produce it.**
Evidence: reading the repository (listed per claim), `flutter analyze` / `flutter test` results from the Phase 3C work, and what I saw on a
Samsung phone (Android) during Phase 3B/3C (the prayer, compass and reminders screens). **Not inspected in this audit:** the hadith
screens on a device, dark mode on a device, TalkBack, any iOS device or simulator, text scaling beyond what the existing tests cover,
frame timing. Anything below marked *(unverified)* is a hypothesis to test, not a finding.

> **Revision 2 (2026-10-09):** adds the owner's decisions, the shared-widget consumer audit, migration rules, the consolidated Phase 3 and UI order,
> Apple guidance read from Apple's own documentation, and the proposed Liquid Glass spike (sections 15 to 23). Sections 1 to 14 are the first version;
> where they conflict with sections 15 to 23 (haptics setting, glass wording, global theme changes), the later sections win.

## 1. Executive summary

- The app already has a coherent base from the earlier redesign (`docs/UX_REDESIGN_PROPOSAL.md`, implemented): ivory/emerald and dark
  palettes with WCAG-checked pairs, Cairo for the interface, Amiri for Arabic reading text, spacing/radius/size tokens, a shared widget set,
  skeleton/empty/error views, and accessibility tests. **This plan extends that system; it does not replace it.**
- What is missing is mostly **motion, platform polish and consistency of the newer screens**: there is one motion helper (`ExpandableSection`),
  two motion tokens (150 and 250 ms), no page-transition policy (every route is a plain `MaterialPageRoute`, 13 call sites), a single haptic cue (Qibla alignment),
  and the Phase 3 screens (prayer, Qibla, reminders) were built with the shared widgets but have had no visual design pass of their own.
- Several features named in the brief **do not exist yet** (Quran/Mushaf, adhkar, tasbeeh, salawat, bookmarks, audio, downloads, sharing
  cards). The Quran tab is a "coming soon" placeholder. The plan covers only what exists, and defines the design-system pieces those features
  will reuse.
- Liquid Glass: Flutter does not provide it for Cupertino widgets (third-party reports, see section 7). Native glass needs platform views and
  a Mac to build and verify; neither is available, so **iOS glass is a spike, not a deliverable of this plan**.
- Recommended scope: five small phases, A to E, plus a final review, each a branch with its own checkpoint, zero new packages by default.

## 2. Actual screen inventory (from the repository)

Section flags: the Quran and Prayer sections and the bottom navigation are **off in a normal build** (`lib/app/feature_flags.dart`); a build
without `--dart-define=HADEETHS_PREVIEW_SECTIONS=true` opens straight on the hadith home as released. Any visual change to shared widgets
therefore affects the released app too.

| # | Screen | File | Lines | Notes |
|---|---|---|---|---|
| 1 | Hadith home (categories, search entry, sources link) | `categories/presentation/pages/home_page.dart` | 123 | released |
| 2 | Category page | `categories/.../category_page.dart` | 73 | released |
| 3 | Hadith list | `hadiths/.../hadith_list_page.dart` | 174 | released |
| 4 | Hadith details (reading surface, grade chip, expandable sections, share, text-size) | `hadiths/.../hadith_details_page.dart`, `widgets/reading_surface.dart` | 232 / 87 | released |
| 5 | Search | `search/.../search_page.dart`, `search_entry.dart`, `search_result_tile.dart` | 153 / 59 / 88 | released |
| 6 | Settings (language, appearance, numerals, reading size, offline copies) | `settings/.../settings_page.dart`, `reading_size_control.dart` | 146 / 117 | released |
| 7 | Sources and rights (About) | `settings/.../about_page.dart` | 64 | released |
| 8 | Shell: bottom navigation, per-tab navigators | `app/shell/app_shell.dart` | 181 | flagged off |
| 9 | More page, Coming-soon placeholder (Quran) | `app/shell/more_page.dart`, `coming_soon_page.dart` | 40 / 27 | flagged off |
| 10 | Prayer page (times, next prayer, date line, location) | `prayer_times/.../prayer_page.dart` | 385 | flagged off |
| 11 | Prayer setup (first run, GPS or city) and city picker | `widgets/prayer_setup_view.dart`, `city_picker_page.dart` | 170 / 101 | flagged off |
| 12 | Calculation method page | `method_page.dart` | 56 | flagged off |
| 13 | Hijri page (reference, manual correction) | `hijri_page.dart` | 80 | flagged off |
| 14 | Qibla compass (dial painted with `CustomPaint`) | `qibla_page.dart` | 512 | flagged off |
| 15 | Reminders page | `reminders_page.dart` | 326 | flagged off |
| — | States | `core/widgets/state_views.dart` (loading, static skeleton list, empty, error with retry) | 162 | shared |

Shared widgets: `AppTile`, `ContentWidth`, `ExpandableSection`, `OptionGroup`, `SectionHeading`, `SwitchRow`, state views.
Dependencies today: bloc, flutter_bloc, dio, intl, sqlite3, shared_preferences, share_plus, geolocator, sensors_plus,
flutter_local_notifications, adhan_dart, hijri_core, timezone, path_provider, equatable. **No animation, icon, blur or UI packages.**
Fonts: Cairo (variable) and Amiri Regular/Bold, both SIL OFL 1.1 (verified earlier from the font files). No `AGENTS.md` or `CLAUDE.md` exists;
the conventions are `docs/ARCHITECTURE.md` and `test/architecture_test.dart` (presentation may not import data layers; core may not import
features).

An untracked skill `.claude/skills/hadeeths-ui-modernization/SKILL.md` (318 lines, created 2026-10-09 14:28) already exists. It was not made
by me in this session. I did not edit it; Phase 11 of the brief should start from it, not overwrite it.

## 3. Screen-by-screen findings

Severity: P1 affects reading or access, P2 consistency or polish, P3 nice to have.

**Cross-cutting (verified in code)**
- **N-1 (P2)** All 13 navigation call sites use `MaterialPageRoute`, so the platform default transition applies everywhere, including
  over the reading position. There is no policy distinguishing drill-down, modal-like pages (city picker, method) and tab switches.
- **N-2 (P2)** Switching bottom tabs is an instant swap (`Offstage`); there is no cross-fade. The per-tab navigator design is good and must stay.
- **M-1 (P2)** Motion tokens are two (`short` 150, `medium` 250), no curves, no reduced-motion switch except inside `ExpandableSection`.
  `app.dart` has one literal 400 ms delay (a save-then-reconcile wait, not an animation; must not be touched).
- **M-2 (P2)** Haptics: the only use is `HapticFeedback.mediumImpact()` when the Qibla compass aligns (`qibla_page.dart:131`). Nothing else vibrates, there is no shared service, and no setting to turn it off.
- **C-1 (P3)** `Colors.*`/`Color(0x…)` literals outside `tokens.dart`: none found except `Colors.transparent`. Good; keep it that way.
- **T-1 (P2)** Page-title text style is set in `AppTheme` (heading+2, w700) but several screens build their own section headers; a header
  component is only partly shared (`SectionHeading`).

**Released hadith flow (1–7)** *(visual findings from the earlier audit, not re-observed on a device this session)*
- Details page already has the right hierarchy: title, reading surface (Amiri 24, line height 2.0), grade chip, collapsed sections.
  Risks to guard when touching it: do not add motion to the text; keep the credit line visible; keep reading-size behaviour.
- Search results and category tiles are plain lists with no press/selection feedback beyond Material ink *(unverified on device)*.
- Settings uses `OptionGroup` and `SwitchRow`; the switches use the stock Material switch.

**Prayer (10–13) and Qibla (14)** *(seen on the Samsung phone)*
- The prayer page is correct and readable but is a stack of standard tiles; the **next prayer** is not visually dominant and the active/next
  change is an instant swap. A countdown is not shown (only times).
- Qibla: the arrow and dial redraw per sensor event with no smoothing of the angle wrap at 0/360 *(unverified: needs a long-run check on
  device; the compass accuracy itself is still unverified because the phone sat near a magnet)*. The interference state replaces the arrow
  rather than fading.

**Reminders (15)** *(seen on the phone)*
- Long page of equal-weight switches; the "exact timing" explanatory text is long. It works and is accessible; hierarchy could be improved
  by grouping (What / When / How it sounds / Reliability).

**States**
- Skeleton is deliberately static (no shimmer), which is calm and correct for this app; keep. Content appearing after loading is an instant
  swap.

## 4. Visual direction

Keep the established identity: ivory canvas, emerald primary, muted gold only for small marks, Amiri for reading, Cairo for UI. The change is
refinement, not a new look:

1. **Hierarchy over decoration.** One focal element per screen (e.g. next prayer on the prayer page; the hadith text on details).
2. **Fewer boxes.** Prefer dividers and spacing to nested cards; one surface level for reading, one for grouped controls.
3. **Consistent controls.** One switch, one segmented control, one tile, one header style, used everywhere.
4. **Quiet depth.** Borders and tonal surfaces, no heavy shadows, no gradients as decoration, no glass on content.
5. **Serenity.** Motion short and rare; nothing moves while someone reads.

## 5. Design-system proposal (extend `lib/core/design_system/` and `lib/core/widgets/`)

| Area | Today | Proposal |
|---|---|---|
| Colour | Material `ColorScheme` (light/dark), contrast-tested | Keep. Add a small `ThemeExtension` only for roles Material lacks: `reading surface`, `success`, `warning` (no new raw literals elsewhere). Extend the contrast test to the new roles. |
| Typography | Sizes/line heights as constants; `ReadingText` for hadith | Add named styles built from the constants (display, title, heading, body, meta, label, number, readingArabic, readingLatin); tabular figures for times and counters; keep Amiri strictly for reading. |
| Spacing, radius, sizes | `AppSpacing`, `AppRadius`, `AppSizes` | Keep; add icon sizes, border width, elevation levels (0 and 1 only), sheet padding. |
| Motion | `AppMotion.short/medium` | See section 6. |
| Components | `AppTile`, `OptionGroup`, `SwitchRow`, `SectionHeading`, `ExpandableSection`, state views | Add `ScreenHeader` (large-title pattern, optional), `AppSwitch`/segmented wrappers (themed once), `AppSheet` helper, `AnimatedStateSwitcher` (loading → content), `PressableScale` (opt-in), `StatusBanner` (used by reminders and permission messages). Each documented with its accessibility contract. |
| Theme | `AppTheme._build` | Add `PageTransitionsTheme`, `SwitchTheme`, `SegmentedButtonTheme`, `SnackBar`/`Dialog` themes in one place. |

No parallel system: everything stays in these two folders and follows the existing architecture test.

## 6. Motion specification

Starting values, to be validated on the Samsung phone and, later, an iPhone:

| Token | Duration | Curve | Used for |
|---|---|---|---|
| `instant` | 100 ms | `easeOut` | press feedback, ink, check marks |
| `short` | 150 ms (existing) | `easeOutCubic` | switches, chips, selection indicators |
| `medium` | 250 ms (existing) | `easeInOutCubic` | expand/collapse, loading → content, banner appear |
| `page` | 280 ms | platform default on iOS (cupertino slide), fade-through on Android | route transitions |
| `emphasis` | 400 ms, max | `easeOutBack` is **not** used | only first-time reveals (next-prayer change) |

Rules: all durations resolve to `Duration.zero` when `MediaQuery.disableAnimations` is true (the pattern already in `ExpandableSection`
becomes a helper `AppMotion.of(context)`); animation never gates state, saving or navigation; no entrance animation replays on rebuild;
no tickers on inactive tabs (the shell already uses `TickerMode`).

Per area:
- **Routes:** a shared `appRoute()` that wraps pages; Android fade-through/shared-axis via the built-in `PageTransitionsTheme` (no package),
  iOS keeps the Cupertino slide (including swipe-back). Reading pages keep their scroll position (no transform on content).
- **Tabs:** 150 ms cross-fade between tab bodies.
- **Home/lists:** no staggered entrances by default; at most a single 150 ms fade of the first screenful after load.
- **Prayer:** animated emphasis on the next prayer row (colour/weight, 250 ms), live countdown text with tabular figures and no per-second
  animation; angle smoothing for the Qibla arrow (shortest-path interpolation across 0/360), fade for the interference state.
- **Reading:** only sheet opening and expandable sections; no motion on text.
- **Controls:** switch thumb and tab indicator motion from the Material components; `PressableScale` limited to large tappable cards (≤ 0.98).
- **Counters (tasbeeh/salawat, future):** count is updated synchronously; the animation is cosmetic and cannot lose taps (design constraint to
  encode in tests when the feature is built).
- **Haptics:** `HapticFeedback.selectionClick` for toggles, with the existing Qibla alignment cue moved behind one `Haptics` service so a
  setting can switch it off; supplementary only.

## 7. iOS and Liquid Glass (what I could and could not verify)

- Apple guidance as summarised by secondary sources: glass belongs to the **navigation layer** above content (tab/navigation bars, toolbars,
  floating controls), not list cells, reading surfaces or full-screen backgrounds, and it adapts to Reduce Transparency, Increase Contrast and
  Reduce Motion when native. **I could not open Apple's own pages**; the exact HIG wording must be confirmed before any native work. Reports
  of iOS 27 changes to default transparency also came from a secondary source and are unconfirmed.
- Flutter: Cupertino widgets do not adopt Liquid Glass by themselves; the tracking issue is flutter/flutter#170310 (I could not open it, so I
  cannot state its status). Blur-based Flutter imitations are possible but are **approximations, not native glass**. Community packages
  (`liquid_glass_native`, `real_liquid_glass`, `cupertino_native_better`) use platform views; they come from small publishers, need the iOS 26
  SDK to build, and warn against use inside scrolling lists.
- Recommendation: **no glass in this plan's phases.** Phase B improves the bottom bar and headers so they are ready for it, and a separate,
  Mac-based spike evaluates (a) the native `UITabBar` / `UINavigationBar` via a small platform view versus (b) leaving system chrome as is.
  That spike needs a new platform channel or a package, so it needs your approval first. Until then the iOS build uses the Cupertino page
  transition and the existing Material chrome, and CI compiles iOS but nothing has run on an iPhone.
- Other iOS items to evaluate on a device: safe areas and Dynamic Island with the bottom bar, swipe-back with per-tab navigators, native
  share sheet (already via `share_plus`), haptics through `HapticFeedback`.

## 8. Android

- Edge-to-edge: Android 15+ enforces it; verify the bottom bar and sheets with 3-button and gesture navigation *(unverified)*.
- Predictive back: the shell uses `PopScope` with custom back handling; whether the predictive-back animation shows is unverified.
- Use Material 3 components as is (NavigationBar, FilledButton, SegmentedButton), themed centrally; keep ink ripples.
- Notification page (reminders) already links to the system pages; the exact-alarm wording was just softened.
- Dynamic colour is **not** proposed: the brand palette is part of the product.

## 9. Arabic, RTL, accessibility findings

Verified by tests or code: contrast checks for all text pairs and 3:1 control borders (`test/app/accessibility_test.dart`), 200% text fit for
the main screens, header and live-region semantics, expandable section semantics, digits option (Arabic-Indic default in Arabic),
RTL-aware expandable chevron. Gaps to close in the plan:
1. Text-scale and RTL tests exist for the hadith screens; **extend them to the prayer, Qibla and reminders pages** (they were tested at 130% and
   200% when built, but not under a shared harness).
2. Qibla dial: confirm semantics describe the state without the drawing; verify numbers on the dial follow the digit preference.
3. Reduced motion: one component honours it today; the plan makes it a token rule plus a test that fails when a new animation ignores it.
4. Focus indicators and keyboard traversal order for tiles and switches *(unverified)*.
5. Mixed Arabic/Latin/numeric strings (e.g. times, `5 دقائق`) rely on `intl` plurals and `Digits`; add golden-style tests for bidi cases.
6. Never apply digit conversion or any transformation to hadith or (later) Quran text; keep the existing test that checks source text is shown as
   received.

## 10. Performance risks

- Blur, shadows and clipping are not used today; the plan keeps it so (no `BackdropFilter` in lists or reading screens).
- `CustomPaint` in the Qibla page repaints on every sensor event: wrap in `RepaintBoundary`, limit repaint rate to the display and to
  meaningful angle changes *(unverified; measure first)*.
- Page transitions and fade-throughs are cheap built-ins; avoid opacity layers over long text (use `FadeTransition` on route level only).
- The tab shell keeps all opened tabs alive (`Offstage` + `TickerMode`); a cross-fade must not rebuild them.
- No frame-rate claims will be made without profile-mode measurement on a device (`flutter run --profile`, DevTools timeline) and I will
  report the device and numbers.

## 11. Files and modules likely to change

- `lib/core/design_system/tokens.dart`, `app_theme.dart` (motion tokens, theme extension, page transitions, component themes).
- New under `lib/core/design_system/`: `motion.dart`, `typography.dart`; under `lib/core/widgets/`: `screen_header.dart`, `status_banner.dart`,
  `animated_state_switcher.dart`, `pressable_scale.dart`, `app_sheet.dart`; `lib/core/haptics/haptics.dart` (service, interface in core).
- `lib/app/shell/app_shell.dart` (tab cross-fade only; navigator design unchanged), a shared `appRoute()` replacing 13 `MaterialPageRoute` sites.
- Presentation files of the screens listed in section 2 (pages and widgets only).
- Tests: `test/app/accessibility_test.dart`, new `test/core/motion_test.dart`, per-screen widget tests; the architecture test stays as is.
- **Not touched:** domain, data, cubits' logic, notification scheduling, prayer calculation, persistence, API, l10n content (except new labels).

## 12. Phased implementation plan

| Phase | Branch | Content | Acceptance |
|---|---|---|---|
| A Foundations | `ui/a-foundations` | motion tokens + reduced-motion helper, typography styles, theme extension, component themes, `appRoute`, haptics service (unused yet), docs | analyze and tests green; contrast tests cover new roles; no screen looks different yet except themed switches |
| B Navigation and home | `ui/b-navigation-home` | route transitions, tab cross-fade, `ScreenHeader`, `AppTile` polish, loading→content switcher, press feedback | back/swipe-back/deep state preserved (shell tests), no extra rebuilds, phone check |
| C Reading | `ui/c-reading` | hadith list/details/search refinements, sheet opening, bookmark-ready action row (no feature), text untouched | reading text byte-identical (tests), scroll position kept, 200% text, dark mode |
| D Worship utilities | `ui/d-worship` | prayer hierarchy and next-prayer emphasis, Qibla smoothing and fade, reminders grouping, status banners | calculations/schedules unchanged (existing tests green), phone check, reduced-motion check |
| E Secondary | `ui/e-secondary` | settings, sources, dialogs, empty/error states | consistency review |
| F Final review | `ui/f-review` | RTL/dark/scale/reduced-motion sweep, profile-mode check, report | acceptance list below; unverified items listed |

Each phase ends with `dart format`, `flutter analyze`, `flutter test --coverage` (gate 80%), a debug build on the phone, and a short report with
PASS / FAIL / NOT RUN. I push nothing without your approval.

## 13. Testing and acceptance criteria

Per screen: hierarchy review against section 4; only shared components and tokens; RTL and LTR; light/dark; 130% and 200% text; reduced motion
(a test sets `disableAnimations` and checks no pending timers/animations); semantics (labels, headers, live regions); text content unchanged
(existing source-text tests); loading, empty, error and offline states; animation never blocks a tap (test taps mid-transition); phone check on
Android; iOS compile via CI only (NOT RUN on a device until a Mac is available).

## 14. Risks and decisions needed (first version; answered in section 15)

1. **Released-app impact:** shared widgets and theme changes alter the released hadith app. Approve that, or limit Phase A/B changes to the flagged
   sections first.
2. **Liquid Glass:** approve a separate Mac-based spike (needs a Mac, possibly a package or platform view), or defer. Nothing in A–F depends on it.
3. **Packages:** none planned. Lottie/Rive/animations/blur packages are not justified by any requirement found.
4. **Haptics:** approve adding a "vibration feedback" setting (new saved preference) or keep haptics system-default only.
5. **Quran/tasbeeh/salawat/bookmarks/audio/downloads** do not exist; this plan only prepares components for them. Their design comes with their phases.
6. **Existing skill file:** keep and extend `.claude/skills/hadeeths-ui-modernization/SKILL.md` after approval, or treat it as already final.
7. **Scope check with Phase 3:** this competes with the 3D–3H roadmap for time; say whether UI phases run before, after, or alongside 3D.
8. Unverified items above (predictive back, edge-to-edge, focus order, Qibla repaint cost, dark mode on device) are checked in the phases, not assumed.

## 15. Owner decisions (2026-10-09) and what they change

| # | Decision | Effect on this plan |
|---|---|---|
| 1 | Shared widgets and theme change the released hadith app too, **incrementally and backward-compatibly**; no automatic redesign of every released screen; audit consumers first; migrate screens deliberately; flagged sections stay isolated where appropriate | Sections 16 and 17 |
| 2 | Liquid Glass spike deferred until the plan is approved; verify current Apple guidance first; propose a small isolated spike only if it has real value; never blocks the UI work | Sections 18 and 19 |
| 3 | Haptics stay system-default; no new setting unless a concrete user need appears | The `Haptics` service stays internal and has no preference; the "vibration feedback" setting is removed from the plan. It routes the existing Qibla cue (and any later cue) through one place and follows the system setting |
| 4 | UI phases A to F run **before** 3D (tracker, salawat); never run both at once when they touch shared widgets or theme | Section 20 |
| 5 | Extend the existing skill file only **after** the complete plan is approved, keeping its conventions and adding the phased workflow, compatibility rules, platform guidance, verification and approval gates | Section 21; the file stays untouched until then |

Note on the push instruction: the message said "Do push feature/p3c-reminders or master". I read it as **do not push**, which matches the standing
rule, and I have pushed nothing. Please say so if the opposite was meant.

## 16. Shared-widget consumer audit (from the code, 2026-10-09)

"Released" = reachable in a normal build with all section flags off (home, category, hadith list, details, search, settings, sources).
"Flagged" = only reachable with `HADEETHS_PREVIEW_SECTIONS` (shell, prayer, Qibla, reminders, more, coming soon).

| Shared item | Released consumers | Flagged-only consumers | Tests that use it |
|---|---|---|---|
| `AppTile` | home, category, hadith list, settings | more page, prayer page, city picker | `prayer_flow_test`, and the flow tests through the pages |
| `ContentWidth` | home, category, list, details | more, coming soon, prayer, city picker, Hijri, method, Qibla, reminders | indirect |
| `SectionHeading` | home, settings, about | prayer, Hijri, reminders | `accessibility_test` (headers) |
| `OptionGroup` | settings | Hijri, method, reminders | settings and prayer flow tests |
| `ExpandableSection` | details | none | `expandable_section_test`, `accessibility_test` |
| `SwitchRow` | none | reminders | `reminders_flow_test` |
| `LoadingView`, `SkeletonList`, `EmptyView`, `ErrorView` | home, category, list, details, search | prayer, city picker, Qibla | `app_flow_test`, `search_flow_test`, `localization_test`, `accessibility_test` |
| `ReadingSurface` | details only | none | hadith presentation tests |
| `AppTheme` (light and dark) | **everything**, globally | everything | every widget test that builds the app |
| `AppMotion` | `ExpandableSection` only | none | indirect |

Not checked: whether released screens use stock `Switch`, `SegmentedButton` or dialogs that a theme change would restyle (to be listed at the start of Phase A).

Consequences:

1. `SwitchRow` and the page-level work on prayer, Qibla, reminders, Hijri, method, more and coming-soon are **flagged-only**, so they can be
   redesigned without changing the released app.
2. **`AppTheme` is the one place where a change is automatically global.** Any edit to its defaults (switch, segmented button, dialog, page
   transitions, snack bar) alters released screens. So appearance-changing theme work is done through named styles or new components, and
   global defaults change only when the owner approves that specific change.
3. `AppTile`, `SectionHeading`, `OptionGroup`, the state views and `ContentWidth` are shared with released screens: new looks arrive as **optional
   parameters whose default is today's behaviour**, or as new widgets used by flagged screens first.
4. `ExpandableSection` and `ReadingSurface` (the reading experience) are not touched in Phases A and B.

## 17. Compatibility and migration rules

1. **Additive first.** Phase A adds tokens, styles and components; it does not change any existing widget's constructor, default look or
   behaviour. After Phase A the released app must be visually identical (test suite plus a phone check).
2. **No global default changes without approval.** Page transitions, switch, segmented-button, dialog and sheet styling and text styles are
   introduced as named styles or components. The released flow adopts them one screen at a time; each is listed in the phase report as a
   "released-app visible change" and approved at the checkpoint.
3. **Routes:** `appRoute()` is opt-in per call site. Flagged sections adopt it first; released call sites (home, category, list, details,
   search, settings, about) keep `MaterialPageRoute` until the result is shown and you approve each.
4. **Per-screen checklist:** list consumers, add or update tests first, change, run the suite, check on the phone in light and dark, 130% and
   200% text, Arabic and English, report differences. A screen's reading text must stay byte-identical (existing source-text tests plus a new
   check on the details page).
5. **Flag isolation:** released screens do not import flagged-only code; the architecture test stays; a test builds the app with all flags off
   and asserts the same top-level structure as today.
6. **Rollback:** each phase is its own branch with small commits, so one revert undoes one screen's migration.
7. **No new packages.** Any proposal for one comes with a licence check and a reason, and waits for approval.

### Migration risks

| Risk | Where | Mitigation |
|---|---|---|
| A theme tweak silently restyles released screens | `app_theme.dart` | rule 2; before/after widget tests of released screens; phone check |
| Changing `AppTile` height or padding breaks 200% text layout or lists | released lists | keep defaults; run existing text-scale tests; add one per migrated screen |
| New transitions disturb the shell's per-tab navigators or back handling | `app_shell.dart` | navigator structure unchanged; `shell_test` must pass unchanged; tab cross-fade only |
| A new animation ignores reduced motion | everywhere | one helper, plus a test that fails if a duration literal appears outside `AppMotion` |
| Qibla redraw cost grows with smoothing | `qibla_page.dart` | measure in profile mode before and after; `RepaintBoundary` |
| Flagged and released code drift apart | shared widgets | review every shared-widget change against both consumer lists |
| Scope competition with 3D | roadmap | section 20 |

## 18. Apple guidance, read from Apple's own documentation

The human-facing Apple pages render with JavaScript and returned nothing, but Apple serves the same documentation as JSON, which I fetched:
`developer.apple.com/tutorials/data/design/human-interface-guidelines/materials.json` (HIG, Materials) and
`developer.apple.com/tutorials/data/documentation/technologyoverviews/adopting-liquid-glass.json` (Adopting Liquid Glass; I read the first
100,000 of about 151,800 characters). Summary:

- Liquid Glass is **a functional layer for controls and navigation that floats above the content layer**. **Do not use it in the content layer**
  (use standard materials for content elements such as backgrounds). Exception: transient interactive controls (sliders, toggles) take the glass
  look while activated.
- **Use it sparingly** on custom controls, only on the most important functional elements; avoid stacking or crowding glass; avoid custom
  backgrounds behind tab bars and toolbars; do not override standard spacing metrics.
- Two variants, regular and clear. **Clear only over visually rich media**; regular for text-heavy components.
- Standard system bars, sheets, popovers and controls **adopt it automatically** when built with the latest SDK. Custom use is `glassEffect` and
  `GlassEffectContainer` (SwiftUI) or `UIGlassEffect` and glass button configurations (UIKit).
- Accessibility: people can choose a preferred glass look and enable reduced transparency, increased contrast and reduced motion; standard
  components adapt automatically; custom colours need light, dark and increased-contrast variants; every toolbar icon needs an accessibility label.
- `UIDesignRequiresCompatibility` (Info.plist) keeps the earlier look for an app built with the latest SDK. The page I read does **not** state a
  minimum OS version or an availability-check pattern, so "iOS 26 and later" is general knowledge here, not confirmed from what I read.

Not verified: minimum OS versions from Apple's text; the status of Flutter's own support (flutter/flutter#170310 could not be opened); anything
about third-party packages beyond their own pub.dev descriptions.

Implication for Hadeeths: the app draws its own widgets rather than UIKit bars, so **nothing adopts glass automatically**. Hadith and prayer
content are content layer and stay on ordinary surfaces. The only candidate is the bottom navigation bar, possibly a floating action row.

## 19. Proposed Liquid Glass spike (not approved, not started)

Worth doing only if the native iOS look of the **bottom navigation bar** (and nothing else) matters to you. Otherwise skip it.

- **Question:** can the bottom bar be a real native tab bar (a platform view, or one reviewed package wrapping `UITabBar` or SwiftUI `TabView`)
  while the per-tab Flutter navigators, back handling, RTL and VoiceOver keep working?
- **Needs:** a Mac with Xcode; an iPhone or simulator running an OS that has glass; your approval for a new platform integration (a platform view
  or a package, after a licence, publisher and recency check).
- **Isolation:** branch `spike/ios-glass-tabbar`; a small Dart interface `NavigationChrome` in core whose default and only shipped
  implementation is today's `NavigationBar`; the spike adds an iOS-only alternative behind a build flag. No change to content screens.
- **Time box:** 1 to 2 days of Mac time.
- **Exit criteria (all required to adopt):** RTL order correct; VoiceOver labels and selected state correct; back and per-tab stacks unchanged
  (the shell tests pass unchanged); behaves under Reduce Transparency, Increase Contrast and Reduce Motion; no scroll jank in a profile-mode
  timeline on a device; builds in CI; older iOS falls back to today's bar.
- **Fail result:** keep the Material bar on iOS and document why.
- Starts only after you approve the plan **and** a Mac is available. Nothing in phases A to F waits for it.

## 20. Consolidated order of work (Phase 3 and UI)

Done and committed locally: 3A, 3B, 3C. Not pushed: `feature/p3c-reminders` and master.

1. **UI phases A to F** (section 12), in order, each on its own branch with a checkpoint for you. No 3D code starts meanwhile.
2. **Liquid Glass spike**, only if approved and a Mac exists; independent of step 1.
3. **3D** (tracker, salawat, quiet hours, tasbeeh), built on the approved foundation (counter-animation rules, haptics service, status banner, headers).
4. Then 3E (Quran), 3F (hadith improvements), 3G (sharing), 3H (hardening) as in `docs/PHASE3_PLAN.md`, using the A to F components.
5. `docs/PHASE3_PLAN.md` gets a note about this ordering once you approve.

Dependencies: no new packages. The open 3C items (Play Console exact-alarm declaration, sunrise and test-reminder wording, adhan audio licence) do
not block UI work.

## 21. Skill file (not modified)

`.claude/skills/hadeeths-ui-modernization/SKILL.md` stays exactly as it is. After approval I will read it fully, then add a section with the
phased workflow, the compatibility rules of section 17, the Apple guidance of section 18, per-platform guidance, the PASS / FAIL / NOT RUN
verification checklist and the approval gates, keeping its existing structure and wording.

## 22. Testing strategy (consolidated)

- Baseline before Phase A: 805 tests pass, analyzer clean, logic coverage 90.5% (gate 80%). None of these may regress at any phase.
- New tests per phase: motion helper and reduced motion; a scan that fails on duration literals outside `AppMotion`; contrast for any new colour
  roles; per-screen text-scale (130%, 200%), RTL and dark checks; the "all flags off" structure; hadith text unchanged; a tap during a transition
  works. Rapid-tap counter tests belong to 3D.
- Manual on the Samsung phone per phase: light and dark, Arabic and English, large text, a basic TalkBack pass, the back gesture. Performance only
  in profile mode, naming the device in the report.
- iOS: CI compile only until a Mac exists; reported as NOT RUN on a device.
- Every phase report lists PASS / FAIL / NOT RUN and the released-app visible changes for your approval.

## 23. Approval requested

Please approve or amend sections 15 to 22 and the six phases of section 12. On approval I start **Phase A on a new branch**. You said the skill
file is extended after the complete plan is approved, so I will treat approval of this plan as that approval unless you say otherwise. I push nothing.

## 24. Phase A report (branch `ui/a-foundations`)

**Added (all additive; no existing widget, route or theme default changed):** motion tokens and `context.motion`/`reduceMotion`; `AppColors`
theme extension (success, warning, reading surface); `AppTypography`; `appRoute()`; `Haptics` service; `StatusBanner`, `AnimatedStateSwitcher`,
`PressableScale`; `AppSizes.iconSmall`. **Deferred to the phases that have a consumer:** `ScreenHeader` (B), `AppSheet` (D).

**Verified:**

| Check | Result |
|---|---|
| `dart format --set-exit-if-changed .` | PASS |
| `flutter analyze` | PASS (0 issues) |
| `flutter test` | PASS, 846 tests (805 before; 41 new) |
| Logic coverage gate 80% | PASS, 90.5% |
| Release config check | PASS |
| New contrast pairs (success, warning, containers; light and dark) | PASS, all at least 4.5:1 |
| No `Duration` literal in screens, shell or shared widgets | PASS (test) |
| Released app unchanged | PASS by suite (shell tests with flags off, flow tests); debug build launches on the Android emulator showing the unchanged hadith home with no bottom bar |
| Debug build on the Samsung phone | NOT RUN: the phone was not connected |
| Release APK build | NOT RUN in this phase (no native or dependency change) |
| iOS | NOT RUN (CI compile only) |
| `appRoute` on a real device, `Haptics` on a device | NOT RUN |

**Released-app visible changes in Phase A:** none intended. Registering `AppColors` adds a theme extension that no released screen reads.

**Notes for Phase B:** adopt `appRoute()` per whole flow (see section 17 and `ARCHITECTURE.md`); decide what to do about the theme being rebuilt
on every settings change; cross-fade for tabs.

## 25. Phase B report (branch `ui/b-navigation-home`, from `ui/a-foundations`)

**Rule applied:** released hadith screens were not restyled and keep the platform transition (a test lists them). Everything below touches
flagged sections, shared widgets with an off-by-default switch, or has no visible effect.

**Changed:**
- **Tab cross-fade** (`TabFade` in the shell): a section fades in over 150 ms when selected; usable at once; nothing with animations removed.
  The shell structure, per-tab navigators and back handling are unchanged. Flagged (the shell only exists with sections on).
- **App transition for the whole prayer and More flows**: the Prayer, Quran-placeholder and More tab root routes, the four pushes in the prayer
  pages, the city picker and the More page pushes use `appRoute()`. The Hadiths tab root and all hadith/search/settings/about routes stay on
  `MaterialPageRoute`. Pages opened from More (Settings, Sources) are released pages: they open with the new transition but their own inner pushes
  are unchanged. Flagged.
- **`AppTile(pressFeedback: true)`** (new, default false): used by the prayer, city picker and More tiles; every released use is unchanged.
- **Prayer page** loading, setup and times states fade between each other (`AnimatedStateSwitcher`). Flagged.
- **Theme object built once** (`app.dart`): the theme no longer animates for about 200 ms on every settings change (language, digits, offline copies)
  because a new, never-equal theme was handed to `MaterialApp` each time. **This is the only change that reaches the released app**: a language
  change now swaps without that extra animation. It changes no look. One existing test relied on that animation to outlast a 400 ms reminder wait; it
  now waits explicitly.

**Not done, with reasons:**
- `ScreenHeader`: no concrete problem found that it solves, and adding it without a consumer would be dead code. Dropped unless a later phase needs it.
- Loading-to-content fade on the released home, list and details screens, tile press feedback on released tiles, and platform transitions for the
  hadith flow: **proposed, not applied** (released-app visible changes; they need your approval, shown on the emulator first).

| Check | Result |
|---|---|
| `dart format`, `flutter analyze` | PASS |
| `flutter test` | PASS, 857 (846 before; 11 new, 1 adjusted) |
| Logic coverage (gate 80%) | PASS, 90.5% |
| Release config check | PASS |
| Debug run on the Android emulator with sections on: Prayer tab, city picker via the new route | PASS (no exceptions in the log; screens render) |
| The fade itself seen in motion, back gesture feel, TalkBack, dark mode on device | NOT RUN (screenshots are single frames; tests check the animation values) |
| Samsung phone | NOT RUN (disconnected) |
| iOS (the platform slide and swipe-back through `appRoute`) | NOT RUN |

## 26. Phase C report (branch `ui/c-reading`, from `ui/b-navigation-home`)

**Finding: the reading screens did not need a visual change.** I looked at the released hadith flow on the Android emulator (English, light):
the category page, the hadith list, and a hadith with its title, reading surface, grade chip, narrator line, collapsed Explanation and Benefits
sections and the source credit; then the same hadith in **dark mode at 200% system text**. Text is large, readable and unclipped in both; the hierarchy
is clear (one reading card, secondary material collapsed, credit visible). I did not find a reading problem that a restyle would fix, and the plan's
priority for these screens is legibility and stability, so **no reading screen was changed**.

**Added (tests only):** `test/features/hadiths/presentation/reading_surface_test.dart` (8 tests): the source text, with vowels and the honorific mark,
reaches the screen exactly (light and dark); no ellipsis or line limit on it; Arabic uses Amiri at the token size and line height, English the UI font;
the reading-size setting scales it; it fits a 360x640 phone at 200% text in both themes and stays selectable; nothing inside it animates, blurs or
fades, with or without reduced motion. The existing `accessibility_test` already walks every screen in both languages and themes at 200% text.

**Noted, not changed:** hadith titles in the list are cut after four lines with an ellipsis (`maxTitleLines`); that is a title preview and the full text is
on the details page, but if you want the full title always shown, say so.

**Still waiting for your decision (released-app visible, unchanged):**
1. A fade from loading to content on the home, list and details screens (the state views swap instantly today).
2. Press feedback on the category and list tiles.
3. The app page transition for the hadith flow, for every route of that flow at once.
Reading text itself is excluded from all three.

| Check | Result |
|---|---|
| `dart format`, `flutter analyze` | PASS |
| `flutter test` | PASS, 865 (857 before; 8 new) |
| Logic coverage (gate 80%) | PASS, 90.5% |
| Release config check | PASS |
| Emulator, English: category, list, details, light; details dark at 200% text | PASS (looked at screenshots) |
| Arabic/RTL on a device this phase | NOT RUN (covered by the existing widget tests only) |
| Explanation and Benefits sections opened, search screen, text-size sheet, TalkBack on a device | NOT RUN |
| Samsung phone, iOS | NOT RUN |
