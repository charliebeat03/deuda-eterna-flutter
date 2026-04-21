#!/usr/bin/env bash
set -euo pipefail

flutter config --android-sdk "${ANDROID_SDK_ROOT}"
flutter doctor -v
flutter pub get
