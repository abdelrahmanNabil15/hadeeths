# الأحاديث النبوية (Hadeeths)

Flutter app for browsing Prophetic hadiths in Arabic. Content and explanations come from the
[HadeethEnc.com](https://hadeethenc.com) API and are displayed unmodified; HadeethEnc is the source and publisher.

Published Android listing: `com.hadeeths.eg`.

Project documents: [`docs/PHASE0_REVISED_AUDIT.md`](docs/PHASE0_REVISED_AUDIT.md) (audit, decisions, roadmap) and
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

## Known limitations

- `test/widget_test.dart` is the leftover Flutter counter template and fails; it is replaced in Phase 2.
- `flutter analyze` reports a handful of info-level lints that are cleaned up with the lint upgrade in Phase 2.
- iOS: deployment target raised to 13.0 but not built here; bundle identifier is still the placeholder `com.example.mynewapp`.
- Web: not a verified target.
