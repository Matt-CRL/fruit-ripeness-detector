#!/usr/bin/env bash
set -Eeuo pipefail

readonly COMMAND_LINE_TOOLS_VERSION=15859902
readonly COMMAND_LINE_TOOLS_SHA256=4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583
readonly COMMAND_LINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-${COMMAND_LINE_TOOLS_VERSION}_latest.zip"
readonly REQUIRED_ANDROID_PACKAGES=(
  "platform-tools"
  "platforms;android-36"
  "build-tools;36.0.0"
  "ndk;28.2.13676358"
)

workspace_dir=${CHAMI_WORKSPACE_DIR:-/workspace}
android_home=${ANDROID_HOME:-${ANDROID_SDK_ROOT:-/opt/android-sdk}}
export ANDROID_HOME="$android_home"
export ANDROID_SDK_ROOT="$android_home"

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

[[ -f "$workspace_dir/pubspec.yaml" && -f "$workspace_dir/android/gradlew" ]] \
  || fail "Expected a Chami checkout mounted at ${workspace_dir} (it must contain pubspec.yaml and android/gradlew). Clone the GitHub repository, then mount its repository root there."

command -v mountpoint >/dev/null 2>&1 \
  || fail 'The mountpoint utility is unavailable; use the published Chami APK builder image.'
mountpoint --quiet "$android_home" \
  || fail "${android_home} is not a mounted persistent Docker volume. Create and mount one at /opt/android-sdk so Android SDK downloads and accepted licenses persist."

sdkmanager="$android_home/cmdline-tools/latest/bin/sdkmanager"
if [[ ! -x "$sdkmanager" ]]; then
  printf '%s\n' \
    'Android command-line tools are not installed in the SDK volume.' \
    'Review the Android SDK terms at https://developer.android.com/studio/terms' \
    'before continuing. Chami will not download the tools until you confirm.'
  read -r -p 'Have you reviewed and agreed to the Android SDK terms? Type YES to continue: ' terms_answer \
    || fail 'No confirmation received; no Android SDK tools were downloaded.'
  [[ "$terms_answer" == YES ]] \
    || fail 'Android SDK terms were not confirmed; no Android SDK tools were downloaded.'

  for utility in curl sha256sum unzip; do
    command -v "$utility" >/dev/null 2>&1 \
      || fail "Required download utility is missing: ${utility}."
  done

  download_dir=$(mktemp -d)
  trap 'rm -rf "$download_dir"' EXIT
  archive="$download_dir/commandlinetools-linux-${COMMAND_LINE_TOOLS_VERSION}_latest.zip"
  curl --fail --location --retry 3 "$COMMAND_LINE_TOOLS_URL" --output "$archive" \
    || fail 'Android command-line-tools download failed.'
  printf '%s  %s\n' "$COMMAND_LINE_TOOLS_SHA256" "$archive" \
    | sha256sum --check --strict - \
    || fail 'Android command-line-tools SHA-256 verification failed; refusing to install the archive.'

  staging_dir="$download_dir/unpacked"
  mkdir -p "$staging_dir" "$android_home/cmdline-tools"
  unzip --quiet "$archive" -d "$staging_dir" \
    || fail 'Android command-line-tools archive could not be unpacked.'
  [[ -x "$staging_dir/cmdline-tools/bin/sdkmanager" ]] \
    || fail 'The verified Android command-line-tools archive did not contain sdkmanager at the expected path.'
  [[ ! -e "$android_home/cmdline-tools/latest" ]] \
    || fail 'A partial command-line-tools installation already exists. Inspect the SDK volume and repair it before retrying.'
  mv "$staging_dir/cmdline-tools" "$android_home/cmdline-tools/latest"
  sdkmanager="$android_home/cmdline-tools/latest/bin/sdkmanager"
fi

[[ -x "$sdkmanager" ]] || fail "sdkmanager is missing or not executable: ${sdkmanager}"
"$sdkmanager" --sdk_root="$android_home" --licenses \
  || fail 'Android SDK licenses were not accepted; refusing to build.'
"$sdkmanager" --sdk_root="$android_home" --install "${REQUIRED_ANDROID_PACKAGES[@]}" \
  || fail 'Required Android SDK packages could not be installed.'

cd "$workspace_dir"
flutter pub get --enforce-lockfile
flutter build apk --debug --no-pub

printf '\nDebug APK ready at %s/build/app/outputs/flutter-apk/app-debug.apk\n' "$workspace_dir"
