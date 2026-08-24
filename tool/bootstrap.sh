#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is required: https://docs.flutter.dev/get-started/install" >&2
  exit 1
fi

if [[ ! -d android ]]; then
  flutter create --platforms=android --org io.github.nyaacat --project-name fxf .
fi

manifest="android/app/src/main/AndroidManifest.xml"
if ! grep -q 'android.permission.INTERNET' "$manifest"; then
  sed -i '/<manifest/a\    <uses-permission android:name="android.permission.INTERNET" />' "$manifest"
fi
sed -i 's/android:label="fxf"/android:label="FxF"/' "$manifest"

flutter pub get
