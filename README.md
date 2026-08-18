# Chami Android application

Chami is an Android-only Flutter application for offline image-based ripeness
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
  the custom transparent Chami launcher icon, and cleaned theme-aware Chami
  wordmark assets used by account entry and native Android launch resources;
  Android 12+ keeps the centered icon with the text-only Chami name below,
  while legacy launch backgrounds center a stacked icon/name composite without
  an artificial delay
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
  action; the Home Welcome card includes a transparent Chami mascot holding a
  mango beside a responsive, theme-aware “Ready to check a fruit?” speech
  bubble while keeping the scan explanation and action below
- Android Photo Picker upload through `image_picker`, selected-image preview,
  cancellation/replacement, and lost-result recovery
- pinned offline FLOAT32 TFLite upload-image inference using
  `tflite_flutter`, checksum/tensor manifest validation, orientation-aware
  center-crop/ImageNet preprocessing, stable Softmax, and nine ordered labels
- rear-camera Live Scan using Flutter CameraX, on-demand camera permission,
  direct YUV420-to-RGB frame preprocessing, single-flight throttled inference,
  updating model results, pause/resume, exact frame/result saving to History,
  compact post-save `Estimated shelf life: ...` guidance, filled Scan another
  fruit, outlined Add to Batch/View batch, borderless View in History, automatic
  History refresh after a new save, lifecycle cleanup, and recoverable failure
  states
- deterministic fake classifier/advisor test boundaries with explicit Demo
  labeling
- low-confidence, rescan-cancel, and flat repeated-rescan navigation behavior
- Drift/SQLite schema version eight for scans, batches, orders, workspace state,
  detached provenance, and account-scoped synchronization settings, including
  composite indexes for filtered keyset pages, remote revisions, separate
  metadata/photo synchronization states, and safe pull cursors
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
  action, a `0 of N selected` toolbar count with scan-card margins, centered
  lower Cancel/Add to batch/Delete actions, and active-filter chips remain
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
  text-only View in History hierarchy; Live Scan uses the corresponding three
  actions plus its compact shelf-life summary and refreshes History when the
  user opens it after saving
- compact portrait layout support for 360 x 800 logical-pixel phones, with
  portrait-up orientation lock, viewport-fitted onboarding/auth forms, and
  scrollable long-content fallbacks
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
  atomic bulk removal; selection mode places filled Remove beside an outlined
  secondary Move to another batch action, with an atomic compatible multi-scan
  move screen; recent-preview and full-list detail review show only Remove
  from batch followed by Move to another batch, while the Add scans detail
  context exposes a filled Add to Batch action only and assigns directly to
  the current batch when its picker supplies a target; History-originated Add
  to Batch still opens the batch chooser; destructive Delete empty batch text
  uses the theme error color
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
  required editable display names, encrypted session restoration, per-account
  onboarding, and non-enumerating authentication errors when public Supabase
  configuration is supplied
- device-linked, all-or-nothing claiming of active Guest records; the linked
  account owns the persistent offline workspace after sign-out, while a
  different authenticated account gets an isolated temporary workspace and
  never absorbs or exposes the linked data; later Guest records use the linked
  owner automatically; Supabase globally enforces one account/workspace link,
  with generation-scoped prompts, secure revocation, guarded Profile retry, and
  safe pending-release recovery
- foreground-only, durable metadata synchronization with UUID idempotency,
  revision conflicts, dependency-ordered push, paginated overlapping pull, and
  startup/resume/local-write/refresh/manual-retry triggers
- private retained-photo upload and automatic cross-device retrieval,
  deterministic object keys, independent image states, consent revocation, and
  retryable object deletion
- authenticated Profile sync status and controls; linked-workspace sign-out is
  best-effort and retains local data, while temporary-account sign-out keeps an
  explicit destructive-discard alternative; password-reauthenticated account
  deletion remains available
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
scan clears only Chami's session reference and never deletes or changes the
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
- configured hosted app validation and two-device validation; the T-0123 local
  database, RLS/Storage policy, and lint checks passed in Docker, and its
  reviewed initial migration plus authenticated deletion function are deployed
  to the private Singapore development project. The T-0124 follow-up and
  T-0132 registry migrations are deployed; local reset/pgTAP/lint still require
  Docker. Two-device and cloud/Guest conflict acceptance remain pending.
- deliberate account unlinking and lost-account local recovery; Profile can
  detach a fresh local-only copy with fresh IDs, retained photos, cleared
  remote identifiers, and a cleared device link; single-device unlink/re-link
  and pending-release recovery passed physical-device acceptance, while
  lost-account cloud release remains pending

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
must be running before starting or resetting the local Supabase stack. The
T-0124 follow-up and T-0132 registry migrations are deployed to the configured
hosted project, but still need local reset/pgTAP/lint verification:

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

The latest configured APK (T-0134 speech-bubble outline refinement after
T-0135 Profile work) is
`build/app/outputs/flutter-apk/app-debug.apk` (236,448,552 bytes, built
2026-08-19 00:00 +08:00; SHA-256
`69F6BD18268CA9CAA9B466A6A7B2846989ACAB7A5F70242A614BF97B3E405C89`). Its
native cold-start lettering is reduced slightly while the prior icon-plus-
branding layout is retained. It also includes the Guest onboarding
back-navigation loading-state fix and the create-account global
eligibility/prompt fix. It was installed over existing data on
`emulator-5554`.
It also includes the Home mascot prompt and transparent mascot asset; the
regular and compact dark-mode Home checks passed, and light/dark Home
screenshots verified the smaller mascot, larger bubble, visible tail, unified
tail/body outline, and continuous prompt hover on the emulator. Profile now
uses the same light/dark
Appearance card in Guest and signed-in modes, with the requested section
ordering and a visible light-mode switch. The mascot asset also has the
isolated arm/body white background component removed; dark Home verification
shows that gap as transparent. The speech-bubble tail and rounded body are
painted as one outlined path, eliminating the visible junction seam.
The single-device link/persist/isolate/pending-release/unlink/re-link flow has
also passed on a physical Android device; two-device convergence and
cloud/Guest conflict acceptance remain open.

After an intentional Drift schema change, regenerate database code with:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

Generated `lib/core/database/app_database.g.dart` should change only through
the Drift generator workflow.

The Android development identifier is `ph.fruitripeness.kami`. Minimum API 24
and compile/target API 36 are the verified scaffold baseline. Release signing
still uses debug keys and is not production-ready. Live Scan has passed the
physical-device smoke pass; representative-device performance, saved-frame,
heat, memory, and battery validation remain separate acceptance work.
