# الأحاديث النبوية (Hadeeths)

Flutter app for browsing Prophetic hadiths in Arabic. Content and explanations come from the
[HadeethEnc.com](https://hadeethenc.com) API and are displayed unmodified; HadeethEnc is the source and publisher.

Published Android listing: `com.hadeeths.eg`.

Project documents: [`docs/PHASE0_REVISED_AUDIT.md`](docs/PHASE0_REVISED_AUDIT.md) (audit, decisions, roadmap),
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) (code structure and layering rules),
[`docs/RELEASE.md`](docs/RELEASE.md) (versioning, signing, CI, checklist) and
[`docs/UX_REDESIGN_PROPOSAL.md`](docs/UX_REDESIGN_PROPOSAL.md).

## Toolchain (verified on 2026-10-09)

| Tool | Version |
|---|---|
| Flutter / Dart | 3.44.8 (stable) / 3.12.2 |
| JDK | 17 (Temurin 17.0.20) |
| Gradle (wrapper) | 9.1.0 |
| Android Gradle Plugin | 9.0.1 |
| Kotlin | 2.3.20 |
| Android SDK | platform and build-tools installed via Android Studio; licences must be accepted (`flutter doctor --android-licenses`) |

iOS builds require macOS and Xcode; they have **not** been verified (see Known limitations).

## Build commands

```bash
flutter pub get
flutter analyze
flutter test                      # see Known limitations
flutter build apk --debug
flutter build apk --release       # unsigned unless android/key.properties exists
flutter build appbundle --release # for Play uploads; requires signing (below)
```

## Release signing

Release builds never use the debug key. Without `android/key.properties` the release artifact is left unsigned.
To sign, create `android/key.properties` (git-ignored; never commit it or the keystore):

```properties
storeFile=C:/path/to/upload-keystore.jks
storePassword=...
keyAlias=...
keyPassword=...
```

The listing `com.hadeeths.eg` already exists on Google Play, so updates must use the original upload key (or the key
registered with Play App Signing) and a `versionCode` higher than the published one. Set the version in `pubspec.yaml`
(`version: x.y.z+build`); `+build` becomes `versionCode`.

## Tests

```bash
flutter test --coverage
dart run tool/check_coverage.dart 80   # logic layers must stay at or above 80%
```

Unit tests (DTOs, client, data sources, repositories, cubits), widget tests (the main flows, driven through `MyApp`
with fake repositories) and an architecture test (layering rules) never touch the live API. Debug builds install as `com.hadeeths.eg.debug` so they can sit next to a
release build on the same device.

## Features

- Browse hadiths by category (roots and sub-categories), read them with their grade, narrator, explanation, benefits,
  word meanings and sources, and share them with the HadeethEnc credit.
- Search the text of the hadiths (server-side; Arabic diacritics are handled by the server, matches are highlighted in an
  unmodified excerpt).
- Offline reading of what you have opened: categories, hadith lists and hadiths are kept on the device, unmodified, and used when
  there is no connection (a recent copy is used without asking the server; pull-to-refresh asks it). Copies are capped at 20 MB,
  expire after 60 days when stale, and can be turned off or cleared in Settings. Search always needs a connection.
- Settings: language (device, Arabic, English), appearance (device, light, dark), reading text size and the offline switch,
  all saved on the device.
- Sources and rights screen with credits, font licences and the privacy position.

## Languages

Arabic and English. The UI follows the saved choice or, by default, the device language (Arabic is the fallback for any other
language). The layout flips between right-to-left and left-to-right, and the hadith content is requested from the API in the
same language. Strings live in `lib/l10n/app_ar.arb` (template) and `app_en.arb`; run `flutter gen-l10n` after editing them
and commit the generated files. English content is smaller than Arabic: only translated hadiths are listed.

## Design

Ivory and deep emerald (light), dark green (dark); Cairo for the interface and Amiri (Naskh, full diacritics) for Arabic
reading text. Tokens live in `lib/core/design_system`; every text/background pair is checked against WCAG AA in the tests.

## Known limitations

- Offline reading covers only what was opened. There is no "download everything", no bundled starter set, no offline search and
  no bookmarks: those would store or ship much more of HadeethEnc's content, and the project owner has not obtained their
  written permission (see `docs/PHASE0_REVISED_AUDIT.md`, section 7). Search returns at most 100 results (a server limit).
- Numbers always use Western digits in both languages.
- iOS: deployment target raised to 13.0 but not built here; bundle identifier is still the placeholder `com.example.mynewapp`;
  the iOS display name is not localized yet.
- Web: not a verified target.
