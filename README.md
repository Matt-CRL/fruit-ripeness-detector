# Chami — Fruit Ripeness Detector

Chami is an Android Flutter application that helps users identify the ripeness
of one supported fruit at a time:

- Carabao mango
- Lakatan banana
- Red papaya

The app works offline first. Users can upload a photo or use Live Scan, review
the fruit and ripeness result, see shelf-life guidance, save accepted results,
and organize them into batches and local orders. Optional Supabase features
provide account sign-in, synchronization, and private photo backup.

## Main features

- Guest mode with local scans, History, batches, and orders
- Upload Image and Live Scan workflows
- Clear assessment result with ripeness and shelf-life guidance
- Available shelf-life guidance starts collapsed behind **Read more** and
  expands with **Read less**, without showing a summary in the collapsed state
- Human ripeness adjustment before or after saving, with the adjusted stage
  persisted to History and used for shelf-life guidance
- Saved real assessments can update ripeness manually or through same-fruit
  Upload/Live rescans without changing their Fruit ID or History record;
  completed-order batches and Demo records are read-only for this action
- The saved-detail update action lives in the Saved assessment card. Its
  chooser presents side-by-side primary Upload and Live Scan actions with a
  secondary manual update action; batch management keeps only batch controls,
  and Delete saved scan is styled as a destructive action
- Permanent workspace-scoped physical-fruit IDs (`CH-000001`), with IDs
  allocated to Upload, Live, and Demo saves
- Upload-only label suggestion and sticker-style Fruit ID card; Live and Demo
  save surfaces remain unchanged
- History and Batch Details partial Fruit ID search, with clearable empty states
- History cards and Batch Details previews organized around Fruit ID and
  fruit/ripeness metadata
- History filters, sorting, paging, and scan deletion rules
- Batches with same-fruit scan assignment, removal, and moving
- Local order details, pending/completed status, and completed-order protection
- Light and dark appearance modes
- Optional account linking, synchronization, and cross-device photo retrieval
- Account recovery, unlinking, and isolated temporary sessions

## Technology

- Flutter and Dart
- Material 3, Riverpod, and go_router
- Drift/SQLite for local persistence
- TensorFlow Lite for on-device classification
- Flutter CameraX and Android Photo Picker
- Supabase Auth, PostgreSQL, and Storage for optional online features
- Android minimum API 24; compile/target API 36; Java 17

## Getting started

Run commands from the Flutter app directory (`app/` in this project workspace;
the root of the cloned GitHub repository).

Install dependencies:

```powershell
flutter pub get
npm install
```

For online-mode development, copy the example configuration and fill in only
the Supabase project URL and publishable/anon key:

```powershell
Copy-Item config/example.json config/dev.json
```

Run with optional online configuration:

```powershell
flutter run --dart-define-from-file=config/dev.json
```

Without `config/dev.json`, the app remains usable in offline Guest mode.

Never commit `config/dev.json`, service-role keys, database passwords, access
tokens, signing keys, or other secrets.

## Testing and builds

Run formatting, analysis, and tests:

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub -r compact
```

Build a smaller APK for Android testing:

```powershell
flutter build apk --release --split-per-abi --dart-define-from-file=config/dev.json
```

The output is in `build/app/outputs/flutter-apk/`:

- `app-arm64-v8a-release.apk` — most modern Android phones
- `app-armeabi-v7a-release.apk` — older 32-bit Android phones
- `app-x86_64-release.apk` — Android emulators

For a quick local debug build:

```powershell
flutter build apk --debug --dart-define-from-file=config/dev.json
```

The debug APK is universal and much larger. Use a split release APK when
sharing with testers.

## Build a Chami debug APK with Docker

The Docker image is a **build environment**; it does not run the Android app
and does not include Chami's source code or Android SDK. The published image
provides Flutter 3.44.7 and Java 17. Get the source from [GitHub](https://github.com/Matt-CRL/fruit-ripeness-detector)
and the build environment from [Docker Hub](https://hub.docker.com/r/mattctrl/chami-apk-builder).

### Use the published image

You need Docker Desktop running, internet access for the first build, and
several gigabytes of free disk space. In PowerShell, clone the repository and
pull the image:

```powershell
git clone https://github.com/Matt-CRL/fruit-ripeness-detector.git
Set-Location .\fruit-ripeness-detector
docker pull mattctrl/chami-apk-builder:3.44.7-clean-checkout
```

The Flutter app is at the root of the GitHub repository. Create persistent
volumes for the Android SDK and build caches, then run the builder from that
repository directory:

```powershell
docker volume create chami-android-sdk
docker volume create chami-pub-cache
docker volume create chami-gradle-cache
$appPath = (Get-Location).Path
docker run --rm -it `
  --mount "type=bind,source=$appPath,target=/workspace" `
  --mount type=volume,source=chami-android-sdk,target=/opt/android-sdk `
  --mount type=volume,source=chami-pub-cache,target=/root/.pub-cache `
  --mount type=volume,source=chami-gradle-cache,target=/root/.gradle `
  mattctrl/chami-apk-builder:3.44.7-clean-checkout
```

On the first run, review Google's [Android SDK terms](https://developer.android.com/studio/terms).
The builder asks for confirmation before downloading Google's command-line
tools, then installs only Chami's required SDK packages: `platform-tools`,
Android API 36, Build Tools 36.0.0, and NDK 28.2.13676358. Any license prompt
is limited to those packages; unrelated emulator/system-image licenses such
as MIPS are not needed. Declining a required license stops the build. The
Android SDK, accepted licenses, and dependency caches persist in the named
volumes. The GitHub repository must be public or you must have permission to
clone it.

When the build finishes, the debug APK is in the cloned repository at
`build/app/outputs/flutter-apk/app-debug.apk`. No `config/dev.json` is needed;
the debug build uses Chami's offline Guest path.

### Build or publish the image yourself

To build the image locally, run this from the Flutter project root (the
repository root on GitHub):

```powershell
docker build --platform linux/amd64 -t chami-apk-builder:3.44.7-clean-checkout .
```

To publish that local image from the Docker Hub owner account:

```powershell
docker login
docker image tag chami-apk-builder:3.44.7-clean-checkout mattctrl/chami-apk-builder:3.44.7-clean-checkout
docker push mattctrl/chami-apk-builder:3.44.7-clean-checkout
```

Never put a Docker password or access token in project files or chat.

## Model and data notes

The app bundles the current MobileNetV4-based TFLite classifier and the
Upload-only foreground-matting helper under `assets/models/`. The app validates
the model manifest and keeps explanation heatmaps temporary; saved scans keep
their result metadata and private compressed image, not the heatmap.

Model files and research assets may have distribution restrictions. Confirm
permission from the model owner before making this repository public or
redistributing its APK/model assets. If permission is not confirmed, keep the
repository private and share only an authorized test APK.

The active v6 `heatmap_map` output is the shipped legacy channel-average
activation map. Upload and Live Scan render it through the existing Grad-CAM
viewer with green as the highest relative activation and the same model-input
crop used for inference. It remains a visual activation preview rather than a
validated predicted-class Grad-CAM. The corrected export notebook is preserved
at `../experiments/chami_verified_gradcam_export.ipynb` for a future, separately
validated replacement; it is not bundled in the active app.

## Physical-fruit IDs and label guidance

Every successful Upload, Live, and Demo save receives a permanent
workspace-scoped ID such as `CH-000001`. The counter is shared across fruit
types, never reuses a value, survives deletion and workspace transitions, and
continues past six digits. Reservation happens transactionally before image
retention; an interrupted reservation may leave a gap.

Only a successful real Upload save shows the **Suggested next step / Label this
fruit** card. Its short instruction is **Write this ID on a tag and attach it to
the fruit.** The sticker-style panel contains the Chami wordmark, **FRUIT ID**,
the code, a dashed tear line, and outlined semicircle punch holes. It has no
**Saved offline** row, **Copy ID** action, verification disclaimer, barcode, QR
code, printing action, or marked-as-labeled state. Chami cannot verify that a
user attached a physical label, so the tag is a suggested user action rather
than an enforced identity link.

Saved details show **Fruit ID** for real records and **Demo record ID** for Demo
records. History cards show fruit type, ripeness/confidence, batch and Fruit ID,
then a muted date/time. Batch Details previews show Fruit ID, ripeness, then
date/time. General free-text search and reusable-fruit association are not part
of this version.

## Project layout

```text
lib/                 Flutter application code
assets/              Branding, model, and application assets
android/             Android project and launch resources
supabase/            Optional migrations, policies, and Edge Functions
test/                Unit, repository, and widget tests
config/example.json  Safe configuration template
```

The package/application ID is intentionally retained as
`ph.fruitripeness.kami` so existing Android installs, local data, and online
sessions can be upgraded safely. The user-facing application name is Chami.

## Current limitations

- Online behavior still requires hosted Supabase validation across multiple
  devices.
- Independently offline workspaces can issue the same sequential Fruit ID; the
  first version assumes one device per user and does not coordinate counters
  over the network.
- The app does not verify that a physical tag was attached to the fruit.
- Release signing currently uses the development/debug key and is not suitable
  for production Play Store distribution.
- Shelf-life guidance is provisional decision support, not a food-safety
  guarantee.
