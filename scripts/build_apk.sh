#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLUTTER_BIN="${ROOT_DIR}/.tooling/flutter/bin/flutter"
ANDROID_SDK_ROOT_DEFAULT="${ROOT_DIR}/.tooling/android-sdk"
JAVA_HOME_DEFAULT="/usr/local/sdkman/candidates/java/21.0.10-ms"

if [[ -x "${FLUTTER_BIN}" ]]; then
  export PATH="${ROOT_DIR}/.tooling/flutter/bin:${PATH}"
fi

if [[ -d "${ANDROID_SDK_ROOT_DEFAULT}" ]]; then
  export ANDROID_HOME="${ANDROID_SDK_ROOT_DEFAULT}"
  export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT_DEFAULT}"
fi

if [[ -d "${JAVA_HOME_DEFAULT}" ]]; then
  export JAVA_HOME="${JAVA_HOME_DEFAULT}"
  export PATH="${JAVA_HOME}/bin:${PATH}"
fi

flutter pub get
flutter build apk --release
