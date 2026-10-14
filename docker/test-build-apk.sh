#!/usr/bin/env bash
set -euo pipefail

builder=${1:-docker/build-apk.sh}
tmp_root=$(mktemp -d "${TMPDIR:-/tmp}/chami-build-apk-test.XXXXXX")
trap 'rm -rf "$tmp_root"' EXIT
stub_bin="$tmp_root/stub-bin"
mkdir -p "$stub_bin"
real_sha256sum=$(command -v sha256sum)

cat >"$stub_bin/mountpoint" <<'STUB'
#!/usr/bin/env bash
[[ "${TEST_MOUNTPOINT_MODE:-no}" == yes ]]
STUB
cat >"$stub_bin/curl" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$TEST_CURL_LOG"
[[ "${TEST_CURL_MODE:-ok}" == ok ]] || exit 22
while (($#)); do
  if [[ $1 == --output || $1 == -o ]]; then
    printf 'intentionally-invalid-archive' >"$2"
    exit 0
  fi
  shift
done
exit 2
STUB
cat >"$stub_bin/sha256sum" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${TEST_CHECKSUM_MODE:-real}" == ok ]]; then
  read -r expected archive
  [[ "$expected" == 4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583 ]]
  [[ -f "$archive" ]]
  printf '%s: OK\n' "$archive"
  exit 0
fi
exec "$TEST_SYSTEM_SHA256SUM" "$@"
STUB
cat >"$stub_bin/unzip" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
[[ "${TEST_UNZIP_MODE:-ok}" == ok ]] || exit 1
[[ "${1:-}" == -q ]] \
  || { printf 'unzip requires the Info-ZIP quiet flag -q\n' >&2; exit 2; }
shift
archive=$1
shift
[[ -f "$archive" && "$1" == -d ]]
destination=$2
mkdir -p "$destination/cmdline-tools/bin"
cp "$TEST_SDKMANAGER_STUB" "$destination/cmdline-tools/bin/sdkmanager"
chmod +x "$destination/cmdline-tools/bin/sdkmanager"
STUB
cat >"$stub_bin/sdkmanager" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$TEST_SDKMANAGER_LOG"
if [[ " $* " == *' --licenses '* && "${TEST_LICENSE_MODE:-accept}" != accept ]]; then
  exit 1
fi
if [[ " $* " == *' --install '* && "${TEST_LICENSE_MODE:-accept}" != accept ]]; then
  printf 'Required SDK package licenses were not accepted.\n' >&2
  exit 1
fi
STUB
cat >"$stub_bin/flutter" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$TEST_FLUTTER_LOG"
STUB
chmod +x "$stub_bin"/*

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
assert_contains() {
  local file=$1 text=$2
  grep -Fq -- "$text" "$file" || { sed -n '1,160p' "$file" >&2; fail "expected output to include: $text"; }
}
run_builder() {
  local workspace=$1 sdk=$2 mount_mode=$3 license_mode=$4 input=$5 output=$6 curl_mode=${7:-ok} checksum_mode=${8:-real}
  printf '%s' "$input" | env \
    PATH="$stub_bin:$PATH" \
    CHAMI_WORKSPACE_DIR="$workspace" ANDROID_HOME="$sdk" ANDROID_SDK_ROOT="$sdk" \
    TEST_MOUNTPOINT_MODE="$mount_mode" TEST_LICENSE_MODE="$license_mode" TEST_CURL_MODE="$curl_mode" \
    TEST_CHECKSUM_MODE="$checksum_mode" TEST_SYSTEM_SHA256SUM="$real_sha256sum" \
    TEST_SDKMANAGER_STUB="$stub_bin/sdkmanager" \
    TEST_CURL_LOG="$tmp_root/curl.log" TEST_SDKMANAGER_LOG="$tmp_root/sdkmanager.log" \
    TEST_FLUTTER_LOG="$tmp_root/flutter.log" \
    bash "$builder" >"$output" 2>&1
}
prepare_project() {
  local workspace=$1
  mkdir -p "$workspace/android/gradle/wrapper"
  : >"$workspace/pubspec.yaml"
  : >"$workspace/android/gradlew"
  : >"$workspace/android/gradlew.bat"
  : >"$workspace/android/gradle/wrapper/gradle-wrapper.jar"
  : >"$workspace/android/gradle/wrapper/gradle-wrapper.properties"
}
prepare_sdkmanager() {
  local sdk=$1
  mkdir -p "$sdk/cmdline-tools/latest/bin"
  cp "$stub_bin/sdkmanager" "$sdk/cmdline-tools/latest/bin/sdkmanager"
}

# Missing checkout must fail before doing any SDK setup.
out="$tmp_root/missing-checkout.out"
if run_builder "$tmp_root/no-project" "$tmp_root/sdk-missing-checkout" no accept '' "$out"; then
  fail 'missing project unexpectedly succeeded'
fi
assert_contains "$out" 'Expected a Chami checkout'
assert_contains "$out" 'mount its repository root there'
[[ ! -e "$tmp_root/flutter.log" ]] || fail 'Flutter ran without a mounted Chami checkout'

# A checkout with the launcher but without the wrapper JAR is incomplete and
# must fail before SDK setup or Flutter starts.
project="$tmp_root/project-missing-wrapper-jar"
sdk="$tmp_root/sdk-missing-wrapper-jar"
prepare_project "$project"
prepare_sdkmanager "$sdk"
rm "$project/android/gradle/wrapper/gradle-wrapper.jar"
out="$tmp_root/missing-wrapper-jar.out"
if run_builder "$project" "$sdk" yes accept '' "$out"; then
  fail 'a checkout without the Gradle wrapper JAR unexpectedly succeeded'
fi
assert_contains "$out" 'complete Gradle wrapper'
[[ ! -e "$tmp_root/flutter.log" ]] || fail 'Flutter ran without a complete Gradle wrapper'

# A plain directory must not be mistaken for the required persistent SDK volume.
project="$tmp_root/project-no-volume"
prepare_project "$project"
out="$tmp_root/missing-volume.out"
if run_builder "$project" "$tmp_root/sdk-not-mounted" no accept '' "$out"; then
  fail 'missing SDK volume unexpectedly succeeded'
fi
assert_contains "$out" 'persistent Docker volume'
[[ ! -e "$tmp_root/flutter.log" ]] || fail 'Flutter ran without the persistent SDK volume'

# A runner who has not reviewed/accepted Google's terms must not download tools.
project="$tmp_root/project-declined-terms"
sdk="$tmp_root/sdk-declined-terms"
prepare_project "$project"
mkdir -p "$sdk"
: >"$tmp_root/curl.log"
out="$tmp_root/declined-terms.out"
if run_builder "$project" "$sdk" yes accept $'no\n' "$out"; then
  fail 'declined Android SDK terms unexpectedly succeeded'
fi
assert_contains "$out" 'Android SDK terms'
[[ ! -s "$tmp_root/curl.log" ]] || fail 'download ran after terms were declined'

# A failed command-line-tools download must stop before checksum/install/build.
project="$tmp_root/project-download-failure"
sdk="$tmp_root/sdk-download-failure"
prepare_project "$project"
mkdir -p "$sdk"
: >"$tmp_root/curl.log"
out="$tmp_root/download-failure.out"
if run_builder "$project" "$sdk" yes accept $'YES\n' "$out" fail; then
  fail 'failed Android command-line-tools download unexpectedly succeeded'
fi
assert_contains "$out" 'download failed'
[[ ! -e "$tmp_root/flutter.log" ]] || fail 'Flutter ran after download failure'

# A bad command-line-tools archive checksum must stop before sdkmanager/build.
project="$tmp_root/project-bad-checksum"
sdk="$tmp_root/sdk-bad-checksum"
prepare_project "$project"
mkdir -p "$sdk"
: >"$tmp_root/curl.log"
out="$tmp_root/bad-checksum.out"
if run_builder "$project" "$sdk" yes accept $'YES\n' "$out"; then
  fail 'invalid Android command-line-tools archive unexpectedly succeeded'
fi
assert_contains "$out" 'SHA-256'
[[ ! -e "$tmp_root/flutter.log" ]] || fail 'Flutter ran after checksum failure'

# Rejected sdkmanager licenses must stop before dependency resolution/build.
project="$tmp_root/project-declined-license"
sdk="$tmp_root/sdk-declined-license"
prepare_project "$project"
prepare_sdkmanager "$sdk"
out="$tmp_root/declined-license.out"
if run_builder "$project" "$sdk" yes decline '' "$out"; then
  fail 'declined sdkmanager license unexpectedly succeeded'
fi
assert_contains "$out" 'licenses were not accepted'
[[ ! -e "$tmp_root/flutter.log" ]] || fail 'Flutter ran after sdkmanager license rejection'

# A previously installed toolchain should build from the mount and call Flutter
# with the locked dependency and debug APK commands.
project="$tmp_root/project-success"
sdk="$tmp_root/sdk-success"
prepare_project "$project"
prepare_sdkmanager "$sdk"
: >"$tmp_root/sdkmanager.log"
: >"$tmp_root/flutter.log"
out="$tmp_root/success.out"
run_builder "$project" "$sdk" yes accept '' "$out" || { sed -n '1,160p' "$out" >&2; fail 'mock successful build failed'; }
assert_contains "$tmp_root/sdkmanager.log" 'platforms;android-36'
assert_contains "$tmp_root/sdkmanager.log" 'ndk;28.2.13676358'
assert_contains "$tmp_root/sdkmanager.log" '--install platform-tools platforms;android-36 build-tools;36.0.0 ndk;28.2.13676358'
if grep -Fq -- ' --licenses' "$tmp_root/sdkmanager.log"; then
  fail 'builder must not request unrelated SDK licenses beyond the required package install'
fi
assert_contains "$tmp_root/flutter.log" 'pub get --enforce-lockfile'
assert_contains "$tmp_root/flutter.log" 'build apk --debug --no-pub'

# A fresh SDK volume must download, verify, and extract the tools after explicit
# terms confirmation, then continue through sdkmanager and the APK build.
project="$tmp_root/project-first-install"
sdk="$tmp_root/sdk-first-install"
prepare_project "$project"
mkdir -p "$sdk"
: >"$tmp_root/curl.log"
: >"$tmp_root/sdkmanager.log"
: >"$tmp_root/flutter.log"
out="$tmp_root/first-install.out"
run_builder "$project" "$sdk" yes accept $'YES\n' "$out" ok ok \
  || { sed -n '1,160p' "$out" >&2; fail 'mock first-time SDK install failed'; }
[[ -x "$sdk/cmdline-tools/latest/bin/sdkmanager" ]] \
  || fail 'first-time SDK tools were not installed into the persistent volume'
assert_contains "$tmp_root/curl.log" 'commandlinetools-linux-15859902_latest.zip'
assert_contains "$tmp_root/sdkmanager.log" '--install platform-tools platforms;android-36 build-tools;36.0.0 ndk;28.2.13676358'
if grep -Fq -- ' --licenses' "$tmp_root/sdkmanager.log"; then
  fail 'first-time setup must not request unrelated SDK licenses'
fi
assert_contains "$tmp_root/flutter.log" 'build apk --debug --no-pub'

# Keep only the bootstrap script from the docker/ directory in the image context.
if ! awk '
  /^\*\*$/ { blanket = NR }
  /^!Dockerfile$/ { dockerfile = NR }
  /^!\.dockerignore$/ { ignorefile = NR }
  /^!docker\/$/ { directory = NR }
  /^docker\/\*$/ { children = NR }
  /^!docker\/build-apk\.sh$/ { bootstrap = NR }
  END { exit !(blanket && dockerfile && ignorefile && directory && children && bootstrap && blanket < dockerfile && dockerfile < ignorefile && ignorefile < directory && directory < children && children < bootstrap) }
' .dockerignore; then
  fail '.dockerignore must re-exclude docker/ children before allowing only docker/build-apk.sh'
fi

# Keep the wrapper launchers and JAR in the GitHub source so a fresh clone can
# use Flutter's Android build without relying on ignored local files.
for wrapper_file in \
  android/gradlew \
  android/gradlew.bat \
  android/gradle/wrapper/gradle-wrapper.jar \
  android/gradle/wrapper/gradle-wrapper.properties; do
  [[ -f "$wrapper_file" ]] || fail "GitHub source checkout is missing $wrapper_file"
  if git check-ignore -q "$wrapper_file"; then
    fail "GitHub source checkout still ignores $wrapper_file"
  fi
done

# Git for Windows must check out Linux shell scripts with LF even when the
# global core.autocrlf setting is true, or Docker may receive invalid scripts.
for unix_script in docker/build-apk.sh docker/test-build-apk.sh android/gradlew; do
  actual_eol=$(git check-attr eol -- "$unix_script" | awk -F ': ' '{print $3}')
  [[ "$actual_eol" == lf ]] \
    || fail "Git must preserve LF line endings for $unix_script"
done
actual_eol=$(git check-attr eol -- android/gradlew.bat | awk -F ': ' '{print $3}')
[[ "$actual_eol" == crlf ]] \
  || fail 'Git must preserve CRLF line endings for android/gradlew.bat'

printf 'PASS: eleven build-apk bootstrap, wrapper, line-ending, and context scenarios\n'
