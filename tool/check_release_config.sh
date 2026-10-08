#!/usr/bin/env bash
# Fails if the Android release configuration regresses (see docs/RELEASE.md).
set -eu
cd "$(dirname "$0")/.."
status=0

gradle=android/app/build.gradle.kts
manifest=android/app/src/main/AndroidManifest.xml

if grep -nE 'signingConfigs\.(getByName\("debug"\)|debug)' "$gradle"; then
  echo "ERROR: the release build must not be signed with the debug key." >&2
  status=1
fi
if ! grep -q 'android.permission.INTERNET' "$manifest"; then
  echo "ERROR: the main manifest must declare INTERNET (release builds read everything from the API)." >&2
  status=1
fi
if git ls-files --error-unmatch android/key.properties >/dev/null 2>&1; then
  echo "ERROR: android/key.properties must never be committed." >&2
  status=1
fi
if git ls-files | grep -E '\.(jks|keystore)$'; then
  echo "ERROR: keystore files must never be committed." >&2
  status=1
fi
[ "$status" -eq 0 ] && echo "Release configuration OK."
exit "$status"
