# Sakina app icon

Flat vector icon: an open Quran on a crossed stand (a rehal). Emerald cover and stand, ivory pages with soft lines of
text and a small gold eight-pointed star at the head of each page, on a warm gold background. No lettering: the lines are
strokes, not words or verses.

Colours: gold `#D6B568` (background and stars), midnight emerald `#0B3F33` (cover, stand, text strokes),
warm ivory `#FAF6EC` (pages), near-black `#0D1311` (the themed layer).

## Sources (edit these)
| File | What it is |
|---|---|
| `app_icon_master.svg` | Full icon with `background` and `foreground` groups (full-bleed composition, as used on iOS and Play). |
| `app_icon_foreground.svg` | The art only, transparent, scaled so the whole of it sits inside the central 61% circle: the Android adaptive foreground. |
| `app_icon_monochrome.svg` | One flat colour, simplified (cover with the pages cut out, and the stand), for Android 13 themed icons. |
| `notification_icon.svg` | The same simplified silhouette, white, for the notification bar. |

The geometry lives in `tools/geometry.py`; every SVG is plain `<path>` elements (no embedded bitmaps).

## Exports
`app_icon_foreground.png`, `app_icon_background.png` (1024), `app_icon_ios.png` (1024, opaque, no alpha),
`app_icon_play_store.png` (512), `app_icon_monochrome.png` (1024), `notification_icon.png` (96).

The same art is drawn at each exact size into:
- `android/app/src/main/res/mipmap-*/ic_launcher.png` (legacy, Android 7 and below), `ic_launcher_foreground.png`,
  `ic_launcher_monochrome.png`, `mipmap-anydpi-v26/ic_launcher.xml` (adaptive) and `values/ic_launcher_background.xml`;
- `android/app/src/main/res/drawable-*/ic_notification.png` (used by the local notifications) and `raw/keep.xml`;
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (every size the project's iOS 13 target needs, plus the 1024 marketing icon).

## Regenerate
From the project root:

    python branding/app_icon/tools/build.py spec
    flutter test branding/app_icon/tools/render_icons_test.dart
    python branding/app_icon/tools/build.py png
    python branding/app_icon/tools/build.py validate

`validate` reads every PNG back and checks its size, colour type, transparency, the 61% safe area and the colours. The renders
in `build/` are not committed.

Not included: iOS 18 dark and tinted variants (they need the newer asset-catalog format and an Xcode 16 build, which has not been
verified here).
