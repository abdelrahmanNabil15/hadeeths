# الأحاديث النبوية (Hadeeths)

Flutter app for browsing Prophetic hadiths in Arabic. Content and explanations come from the
[HadeethEnc.com](https://hadeethenc.com) API and are displayed unmodified; HadeethEnc is the source and publisher.

Published Android listing: `com.hadeeths.eg`.

Project documents: [`docs/PHASE0_REVISED_AUDIT.md`](docs/PHASE0_REVISED_AUDIT.md) (audit, decisions, roadmap),
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) (code structure and layering rules) and
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
flutter test
```

Unit tests (DTOs, client, data sources, repositories, cubits), widget tests (the main flows, driven through `MyApp`
with fake repositories) and an architecture test (layering rules) never touch the live API. Debug builds install as `com.hadeeths.eg.debug` so they can sit next to a
release build on the same device.

## Languages

The product is Arabic and English. The data layer already handles both (English responses have no `reference` or
`words_meanings`); the UI is still Arabic-only and right-to-left until the localization phase.

## Known limitations

- Screens are still Arabic-only with hard-coded strings; localization, accessibility and theming are planned work.
- `dart format` has not been applied to the whole project (the first commit to touch a file does not reformat it).
- iOS: deployment target raised to 13.0 but not built here; bundle identifier is still the placeholder `com.example.mynewapp`.
- Web: not a verified target.
