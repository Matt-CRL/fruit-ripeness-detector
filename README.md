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

Run commands from this `app/` directory.

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

## Model and data notes

The app bundles the current MobileNetV4-based TFLite classifier and the
Upload-only foreground-matting helper under `assets/models/`. The app validates
the model manifest and keeps explanation heatmaps temporary; saved scans keep
their result metadata and private compressed image, not the heatmap.

Model files and research assets may have distribution restrictions. Confirm
permission from the model owner before making this repository public or
redistributing its APK/model assets. If permission is not confirmed, keep the
repository private and share only an authorized test APK.

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
- Release signing currently uses the development/debug key and is not suitable
  for production Play Store distribution.
- Shelf-life guidance is provisional decision support, not a food-safety
  guarantee.
