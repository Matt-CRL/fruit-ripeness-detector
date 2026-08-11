# Kami Android application

Kami is an Android-only Flutter application for offline image-based ripeness
assessment of Carabao mango, Lakatan banana, and red papaya. It classifies one
fruit image into Unripe, Ripe, or Overripe and supports local History, batches,
orders, appearance preferences, and provisional shelf-life guidance.

This private repository contains the application source, automated tests,
Android configuration, icons, and the deployment model required by authorized
research-team members. Project-management records, manuscript material,
research memory, credentials, signing material, and local runtime data are not
part of this repository.

## Technology

- Flutter 3.44.7 and Dart 3.12.2
- Material 3, Riverpod, and go_router
- Drift with SQLite for offline persistence
- Supabase Auth, PostgreSQL, and private Storage for optional online accounts
- encrypted Android session persistence through `flutter_secure_storage`
- TensorFlow Lite through `tflite_flutter`
- Flutter CameraX and Android Photo Picker
- Android minimum API 24; compile and target API 36
- Java 17 Android build target

## Implemented

- Material 3, Riverpod, go_router, the accessible green/yellow/orange theme,
  and the custom transparent Kami launcher icon
- a full-width anchored, selection-only Create batch fruit-type dropdown with a
  themed, bounded popup that stays below the field when changing fruit
- floating bottom pill navigation with transparent surrounding space so content
  remains visible while scrolling; its theme-aware outline and shadow preserve
  a clear edge in both appearance modes, and shared shell clearance keeps the
  final content above the pill
- persistent local Guest selection and three onboarding slides
- onboarding explains scan/upload, assessment certainty, shelf-life guidance,
  and same-fruit batches; slides use one action, swipe-back, viewport-fitted
  cards, and a transparent progress/action area
- Home, Batches, History, and Profile shell destinations with a central Scan
  action
- Android Photo Picker upload through `image_picker`, selected-image preview,
  cancellation/replacement, and lost-result recovery
- pinned offline FLOAT32 TFLite upload-image inference using
  `tflite_flutter`, checksum/tensor manifest validation, orientation-aware
  center-crop/ImageNet preprocessing, stable Softmax, and nine ordered labels
- rear-camera Live Scan using Flutter CameraX, on-demand camera permission,
  direct YUV420-to-RGB frame preprocessing, single-flight throttled inference,
  updating model results, pause/resume, exact frame/result saving to History,
  direct post-save Add to Batch action, lifecycle cleanup, and recoverable
  failure states
- deterministic fake classifier/advisor test boundaries with explicit Demo
  labeling
- low-confidence, rescan-cancel, and flat repeated-rescan navigation behavior
- Drift/SQLite schema version five for scans, batches, orders, and app settings,
  including composite indexes for filtered keyset pages, remote revisions,
  separate metadata/photo synchronization states, and safe pull cursors
- repository-level batch/order validation and replaceable providers
- app-private retained history JPEGs using `flutter_image_compress` and
  `path_provider`
- offline Save Result, live newest-first History, and saved-scan details
- History detail actions distinguish unassigned scans (Add to Batch and
  bordered Delete saved scan) from assigned scans (View batch only)
- History filters for fruit, ripeness, batch assignment, quick date presets,
  specific dates, and inclusive date ranges
- History Select/Cancel mode with Select all and Clear selection; assigned scans
  remain selectable without bulk actions, unassigned-only selections can be
  deleted, mixed unassigned fruits keep Delete but cannot be added to a batch,
  and same-fruit selections can be assigned to a compatible or newly created
  batch atomically; borderless Select/Cancel text actions, a labeled Delete
  action, a `0 of N selected` toolbar count, and active-filter chips remain
  above displayed scans and no-match empty states; cards show batch assignment,
  saved date, confidence, and shared ripeness color capsules
- History filter sheet Newest first/Oldest first sorting
- In normal browsing mode, History places Filter and Select below its offline
  availability message; in selection mode, Select all/Clear appear above
  Cancel and the applicable Add to batch/Delete actions
- Batches list and Batch Details ripeness counts use the shared
  brightness-aware green/yellow/orange capsule treatment
- Batch Details saved-scan cards show a matching ripeness capsule with stage
  icon and label
- All saved scans has scoped Ripeness/Date/Sort filters with the History-style
  Filter action before Select
- Add scans cards use shared brightness-aware ripeness capsules and the same
  scoped Ripeness/Date/Sort filter action beside the
  right-aligned borderless Select/Cancel controls, with active chips and a
  clearable no-match state applied only after same-fruit, same-owner,
  unassigned eligibility filtering
- Save Result choices for Save to History or Save & Add to Batch; saved-result
  actions use a filled New Scan, outlined Add to Batch/View batch, and
  text-only View in History hierarchy
- offline batch creation, compatible existing/new batch assignment, live
  derived summaries, batch details, scan move/removal, batch rename, eligible
  empty-batch deletion, and confirmed completed-batch deletion with its saved
  scans; editable Batch Details also supports atomic
  multi-select Add scans for same-fruit unassigned records, with arrow-based
  detail browsing, a focused review that hides Add to Batch/Delete saved scan,
  and a left-aligned Select/Cancel checkbox mode plus successful-add feedback;
  the editable Saved scans header keeps Add scans at the right, and the full
  batch scan list previews three scans on
  the details page, remains tappable for
  details normally, and provides a checkbox-only Select/Cancel mode with
  atomic bulk removal; recent-preview and full-list detail review show only
  Remove from batch followed by Move to another batch
- confirmed saved-scan deletion with retained-image cleanup after the local
  soft-delete succeeds
- one active local order per non-empty batch, with Pending create/edit/cancel,
  replacement after cancellation, and confirmed completion that locks the
  order and batch
- Profile Appearance section with locally persisted light/dark mode switching,
  visible switch contrast, Light mode/Dark mode active title, and sun/moon
  active-mode icons
  and startup restoration
- theme-aware dark History/saved-assessment ripeness surfaces, placeholders,
  and a more vibrant dark-mode green accent
- focused Profile Appearance and Guest session controls; app-private database
  and retained-image storage remains internal to offline History
- top-level saved-scan detail navigation from batch details, avoiding a second
  main-shell navigator
- optional email/password account creation, sign-in, recovery, password reset,
  encrypted session restoration, per-account onboarding, and non-enumerating
  authentication errors when public Supabase configuration is supplied
- all-or-nothing authenticated claiming of active guest records, with separate
  draft cloud-photo consent; canceling the claim returns to unchanged Guest mode
- foreground-only, durable metadata synchronization with UUID idempotency,
  revision conflicts, dependency-ordered push, paginated overlapping pull, and
  startup/resume/local-write/refresh/manual-retry triggers
- private retained-photo upload and lazy retrieval, deterministic object keys,
  independent image states, consent revocation, and retryable object deletion
- authenticated Profile sync status and controls, ZIP/JSON/photo export, safe
  synchronized sign-out with an explicit destructive-discard alternative, and
  password-reauthenticated account deletion
- version-controlled Supabase migrations, pgTAP tests, private Storage/RLS
  policies, 30-day tombstone cleanup, and an authenticated `delete-account`
  Edge Function under `supabase/`

## Bundled model

Authorized private-team clones include:

- `assets/models/mobilenetv4_fruit_float32.tflite`
- `assets/models/mobilenetv4_fruit_float32.manifest.json`

The application validates the model checksum, tensor contract, and label order
against the manifest before inference. Replace the model and manifest together.
Do not redistribute the model outside the authorized research team or make the
repository public until the model owner confirms distribution rights in
writing.

Normal uploaded images are evaluated by model version
`mobilenetv4-fruit-enhanced-b11167b` entirely on device. A deterministic fake
is retained for automated tests, while classifier-triggered low-confidence
routing remains available. Accepted classifications use nine versioned
provisional literature-informed shelf-life recommendations; results requiring
a retake withhold guidance. These are approximate provisional estimates, not
locally validated remaining-life predictions.

The current model integration is explicitly provisional: the handoff did not
include a validated confidence threshold, unsupported-input rejection,
known-fixture parity evidence, cultivar verification, evaluation report, or
license. Its repository's ROI and output-probability descriptions also remain
unverified against a supplied fixture and the inspected binary. Automatic
low-confidence rejection is therefore disabled, and every real result warns
that model validation is still in progress.

The gallery picker does not request broad media/storage access. Canceling a
scan clears only Kami's session reference and never deletes or changes the
user's source image. Saving creates a separate app-owned, orientation-corrected,
metadata-omitting JPEG with a 1280-pixel maximum long edge and quality 82 under
the application documents directory.

## Not implemented

- validated low-confidence threshold, unsupported-input rejection, FP16
  deployment, or temporal result smoothing
- local validation of the provisional literature-informed shelf-life
  recommendations against classifier stages
- Completed-order reopen/audit or delivery business rules; local completed
  batch deletion is supported with an explicit saved-scan warning
- History text search
- a hosted development Supabase environment and two-device validation; local
  database, RLS/Storage policy, and lint checks now pass in Docker, but no
  hosted development project has been linked or deployed yet

Missing cloud configuration intentionally leaves the complete Guest workflow
available. Account and sync controls appear only for an authenticated account.
The cloud-photo consent text is a development draft and must be approved by an
authorized adviser/reviewer before thesis-release validation.

## Local configuration

Copy `config/example.json` to the ignored `config/dev.json` and supply only the
Supabase project URL and publishable key. Never place service-role keys,
database passwords, signing material, access tokens, or other secrets in a
Dart define file or Git.

Run with configuration:

```powershell
flutter run --dart-define-from-file=config/dev.json
```

Missing configuration is valid and keeps the app in local-only guest mode.
Valid configuration initializes the optional Supabase client and stores its
session through encrypted Android storage.

## Development

Run all commands from this directory.

Install dependencies:

```powershell
flutter pub get
npm install
```

The exact project-local Supabase CLI is invoked through `npx`. Docker Desktop
must be running before starting or resetting the local Supabase stack:

```powershell
npx supabase start
npx supabase db reset
npx supabase test db
```

Run formatting, analysis, and tests:

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub -r compact
```

Run the app or build a debug APK:

```powershell
flutter run
flutter build apk --debug --no-pub
```

After an intentional Drift schema change, regenerate database code with:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

Generated `lib/core/database/app_database.g.dart` should change only through
the Drift generator workflow.

The Android development identifier is `ph.fruitripeness.kami`. Minimum API 24
and compile/target API 36 are the verified scaffold baseline. Release signing
still uses debug keys and is not production-ready. Live Scan is verified on the
API 36 emulator but still requires representative physical-device validation.
