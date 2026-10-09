# Release guide

Nothing here publishes to a store. Uploading to Google Play or App Store Connect is always a manual step by someone
who owns the account.

## Identity

| Platform | Identifier | Status |
|---|---|---|
| Android | `com.hadeeths.eg` (the existing Google Play listing) | confirmed by the owner |
| iOS | `com.example.mynewapp` (placeholder) | **not confirmed; set before any iOS release** |

Debug builds install as `com.hadeeths.eg.debug`, so they never replace or clash with the release app.

## Versioning

`pubspec.yaml` has `version: x.y.z+N`. `x.y.z` is the version name; `N` becomes Android's `versionCode` and iOS's build
number. **`N` must be higher than the one already published.** The published value is not recorded in this repository;
check Play Console > App bundle explorer before the first release from this codebase, then set `N` above it.

## Local release build (Android)

```bash
flutter pub get
flutter analyze && flutter test
flutter build appbundle --release   # Play uploads
flutter build apk --release         # sideloading/testing
```

Without `android/key.properties` the artifact is left **unsigned** (the build never falls back to the debug key). To
sign, create `android/key.properties` (git-ignored) pointing at the upload keystore:

```properties
storeFile=C:/secure/path/upload-keystore.jks
storePassword=...
keyAlias=...
keyPassword=...
```

The listing already exists, so updates must be signed with the original upload key (or the key registered with Play App
Signing). Keep the keystore and passwords outside the repository and back them up; losing the key blocks future updates.

## CI

`.github/workflows/ci.yml` runs on every pull request and branch push:

1. `flutter pub get`, then `flutter gen-l10n` and a `git diff --exit-code lib/l10n` freshness check
2. `dart format --set-exit-if-changed .`
3. `flutter analyze` (strict casts/inference/raw types plus extra lints)
4. `flutter test --coverage`, then `dart run tool/check_coverage.dart 80` (line coverage of domain, data, state and core
   logic must stay at or above 80%)
5. `tool/check_release_config.sh` (no debug-key release signing, `INTERNET` declared, no keystore or `key.properties`
   committed)
6. debug and unsigned release APK builds; a separate macOS job builds iOS without code signing

Pull requests need no secrets.

`.github/workflows/release.yml` (manual) builds a signed `.aab` and stores it as a workflow artifact. Add these secrets,
preferably to an environment named `production` with required reviewers: `ANDROID_KEYSTORE_BASE64`,
`ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`. They are written to a temporary
`key.properties` that is removed at the end of the job and are never echoed.

> Status: these workflows were validated as YAML and every step that can run on a developer machine was run locally,
> but they have **not** been executed on GitHub yet. Watch the first run and fix anything runner-specific.

## Pre-release checklist

- [ ] `versionCode` is higher than the published one
- [ ] CI green on the release branch
- [ ] Android: installed the release APK on a real device; categories load, a hadith opens, share works
- [ ] Both languages and both themes checked (Settings > Language / Appearance)
- [ ] No stock imagery is bundled (guarded by `test/architecture_test.dart`; the Rawpixel backdrop was removed)
- [ ] HadeethEnc terms still say what the audit recorded; credit line is visible on every hadith
- [ ] Location (prayer times): declare it in Google Play's Data safety form (approximate and precise location, used on the device only, not
  collected or shared) and in Apple's privacy answers; keep the privacy text on the About page in step; the Prayer section flag
  stays off until the owner approves the release
- [ ] Offline reading was shipped **without** HadeethEnc's written permission (owner's decision): re-read their terms before release and keep the Settings switch and clear button
- [ ] Reminders: `POST_NOTIFICATIONS` and `SCHEDULE_EXACT_ALARM` are in the manifest; confirm Google Play accepts the exact-alarm permission (declaration form) or remove it, and note that without it reminders can be an hour late; reboot, timezone change and an actual reminder arriving were not run on a device yet; wording needs owner review
- [ ] iOS only: bundle ID confirmed, signing set up in Xcode, privacy strings reviewed
- [ ] Play Console data-safety answers match the app (no data collected; network use only)
