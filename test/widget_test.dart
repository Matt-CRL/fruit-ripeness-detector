import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kami/app/kami_app.dart';
import 'package:kami/app/theme/app_colors.dart';
import 'package:kami/app/theme/theme_mode_controller.dart';
import 'package:kami/core/persistence/local_sync_state.dart';
import 'package:kami/features/auth/data/device_account_link_store.dart';
import 'package:kami/features/batches/data/drift_batch_repository.dart';
import 'package:kami/features/batches/domain/batch_repository.dart';
import 'package:kami/features/batches/domain/fruit_batch.dart';
import 'package:kami/features/batches/presentation/batch_providers.dart';
import 'package:kami/features/batches/presentation/batch_screens.dart';
import 'package:kami/features/history/data/app_private_retained_scan_image_store.dart';
import 'package:kami/features/history/data/drift_scan_record_repository.dart';
import 'package:kami/features/history/domain/retained_scan_image_store.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/history/domain/scan_record_repository.dart';
import 'package:kami/features/orders/data/drift_order_repository.dart';
import 'package:kami/features/orders/domain/batch_order.dart';
import 'package:kami/features/orders/domain/order_repository.dart';
import 'package:kami/features/scan/application/scan_service_providers.dart';
import 'package:kami/features/scan/data/fakes/fake_scan_services.dart';
import 'package:kami/features/scan/data/image_picker_scan_image_picker.dart';
import 'package:kami/features/scan/data/shelf_life/literature_shelf_life_advisor.dart';
import 'package:kami/features/scan/domain/scan_models.dart';
import 'package:kami/features/scan/presentation/scan_image_provider.dart';
import 'package:kami/features/startup/domain/startup_destination.dart';
import 'package:kami/features/startup/domain/startup_preferences.dart';

import 'helpers/fake_scan_image_picker.dart';
import 'helpers/fake_startup_preferences.dart';
import 'helpers/fake_batch_repository.dart';
import 'helpers/fake_history_storage.dart';
import 'helpers/fake_order_repository.dart';

const _batchFixtureId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _pendingBatchFixtureId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const _completedBatchFixtureId = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';

const _galleryFixture = SelectedScanImage(
  path: '/virtual/sample-fruit.png',
  name: 'sample-fruit.png',
);

const _lowConfidenceFixture = SelectedScanImage(
  path: 'fake://retake',
  name: 'unclear-fruit.png',
);

const _unrecognizedFixture = SelectedScanImage(
  path: 'fake://unrecognized',
  name: 'unrecognized-fruit.png',
);

final Uint8List _validPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
  '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

void main() {
  testWidgets('fresh guest completes all three onboarding slides', (
    WidgetTester tester,
  ) async {
    final preferences = FakeStartupPreferences();
    await _pumpKami(
      tester,
      destination: StartupDestination.accountEntry,
      preferences: preferences,
    );

    expect(find.byKey(const Key('chami-wordmark')), findsOneWidget);
    expect(find.bySemanticsLabel('Chami logo'), findsOneWidget);
    expect(find.text('Welcome to Chami'), findsNothing);
    expect(find.text('Continue as guest'), findsOneWidget);
    expect(find.text('No account or internet needed.'), findsOneWidget);
    expect(find.text('START HERE'), findsNothing);
    expect(find.text('Guest activity stays on this device.'), findsNothing);
    expect(find.text('Scan or upload a fruit'), findsNothing);

    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();

    expect(find.text('Scan or upload a fruit'), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);
    expect(preferences.guestSelected, isTrue);
    expect(preferences.onboardingCompleted, isFalse);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Understand the assessment'), findsOneWidget);
    expect(find.text('2 of 3'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Organize fruits into batches'), findsOneWidget);
    expect(find.text('3 of 3'), findsOneWidget);

    await tester.tap(find.text('Start using Chami'));
    await tester.pumpAndSettle();

    expect(find.text('Ready to check a fruit?'), findsOneWidget);
    expect(preferences.onboardingCompleted, isTrue);
    expect(
      await preferences.readDestination(),
      StartupDestination.returningGuest,
    );
  });

  testWidgets('account entry uses the readable dark Chami wordmark', (
    WidgetTester tester,
  ) async {
    await _pumpKami(
      tester,
      destination: StartupDestination.accountEntry,
      preferences: FakeStartupPreferences(appearanceMode: AppearanceMode.dark),
    );

    final wordmark = tester.widget<Image>(
      find.byKey(const Key('chami-wordmark')),
    );
    expect(
      (wordmark.image as AssetImage).assetName,
      'assets/branding/chami_wordmark_dark.png',
    );
    expect(find.bySemanticsLabel('Chami logo'), findsOneWidget);
    expect(find.text('Welcome to Chami'), findsNothing);
  });

  testWidgets('onboarding slides can be swiped backward', (
    WidgetTester tester,
  ) async {
    await _pumpKami(
      tester,
      destination: StartupDestination.onboarding,
      preferences: FakeStartupPreferences(guestSelected: true),
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Understand the assessment'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(320, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text('Scan or upload a fruit'), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);
    expect(find.text('Back'), findsNothing);
  });

  testWidgets('account entry and onboarding support larger text', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });

    await _pumpKami(
      tester,
      destination: StartupDestination.accountEntry,
      preferences: FakeStartupPreferences(),
    );

    expect(find.text('Continue as guest'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();

    expect(find.text('Scan or upload a fruit'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back from guest onboarding clears account-entry loading', (
    WidgetTester tester,
  ) async {
    await _pumpKami(
      tester,
      destination: StartupDestination.accountEntry,
      preferences: FakeStartupPreferences(),
    );

    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    expect(find.text('Scan or upload a fruit'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to account options'));
    await tester.pumpAndSettle();

    expect(find.text('Continue as guest'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('interrupted guest startup resumes onboarding', (
    WidgetTester tester,
  ) async {
    await _pumpKami(
      tester,
      destination: StartupDestination.onboarding,
      preferences: FakeStartupPreferences(guestSelected: true),
    );

    expect(find.text('Scan or upload a fruit'), findsOneWidget);
    expect(find.text('Welcome to Chami'), findsNothing);
  });

  testWidgets('failed guest preference write stays on account entry', (
    WidgetTester tester,
  ) async {
    await _pumpKami(
      tester,
      destination: StartupDestination.accountEntry,
      preferences: FakeStartupPreferences(failWrites: true),
    );

    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chami-wordmark')), findsOneWidget);
    expect(find.text('Welcome to Chami'), findsNothing);
    expect(
      find.text('Guest mode could not be started. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('returning guest opens local home immediately', (
    WidgetTester tester,
  ) async {
    await _pumpKami(
      tester,
      destination: StartupDestination.returningGuest,
      preferences: FakeStartupPreferences(
        guestSelected: true,
        onboardingCompleted: true,
      ),
    );

    expect(find.text('Ready to check a fruit?'), findsOneWidget);
    expect(find.text('Welcome to Chami'), findsNothing);
    expect(
      tester
          .widget<Scaffold>(find.byKey(const Key('main-shell-scaffold')))
          .extendBody,
      isTrue,
    );
    final contentList = tester.widget<ListView>(find.byType(ListView).first);
    expect(
      contentList.padding?.resolve(TextDirection.ltr).bottom,
      greaterThan(76),
    );
    final navPill = tester.widget<Material>(
      find.byKey(const Key('main-nav-pill')),
    );
    expect(navPill.shape, isA<RoundedRectangleBorder>());
    expect(
      (navPill.shape! as RoundedRectangleBorder).side.color,
      isNot(Colors.transparent),
    );
  });

  testWidgets('returning account opens local home without cloud access', (
    WidgetTester tester,
  ) async {
    await _pumpKami(
      tester,
      destination: StartupDestination.returningAccount,
      preferences: FakeStartupPreferences(),
    );

    expect(find.text('Ready to check a fruit?'), findsOneWidget);
    expect(find.text('Welcome to Chami'), findsNothing);
  });

  testWidgets('guest can cancel or confirm return to sign in', (
    WidgetTester tester,
  ) async {
    final preferences = await _pumpGuestProfile(tester);

    expect(find.text('View onboarding again'), findsNothing);
    expect(find.text('Guest mode'), findsOneWidget);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.person)).color,
      AppColors.brandGreen,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.home_outlined)).color,
      AppColors.navigationInactive,
    );

    await tester.tap(find.text('Return to sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Return to sign in?'), findsOneWidget);
    final stayButton = find.widgetWithText(OutlinedButton, 'Stay as guest');
    final returnButton = find.widgetWithText(FilledButton, 'Sign in');
    expect(stayButton, findsOneWidget);
    expect(returnButton, findsOneWidget);
    expect(
      tester.getTopLeft(stayButton).dy,
      tester.getTopLeft(returnButton).dy,
    );

    await tester.tap(find.text('Stay as guest'));
    await tester.pumpAndSettle();

    expect(find.text('Guest mode'), findsOneWidget);
    expect(preferences.guestSelected, isTrue);
    expect(preferences.onboardingCompleted, isTrue);

    await tester.tap(find.text('Return to sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chami-wordmark')), findsOneWidget);
    expect(find.text('Welcome to Chami'), findsNothing);
    expect(
      find.text('Works locally without an account or internet.'),
      findsNothing,
    );
    expect(preferences.guestSelected, isFalse);
    expect(preferences.onboardingCompleted, isFalse);

    await tester.binding.handlePopRoute();
    await _pumpRoute(tester);
    expect(
      find.text('Works locally without an account or internet.'),
      findsNothing,
    );

    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();

    expect(find.text('Scan or upload a fruit'), findsOneWidget);
    expect(preferences.guestSelected, isTrue);
    expect(preferences.onboardingCompleted, isFalse);
  });

  testWidgets('failed guest reset stays in Profile with retry feedback', (
    WidgetTester tester,
  ) async {
    final preferences = await _pumpGuestProfile(tester, failWrites: true);

    await tester.tap(find.text('Return to sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Guest mode'), findsOneWidget);
    expect(
      find.text('Guest mode could not be closed. Please try again.'),
      findsOneWidget,
    );
    expect(preferences.guestSelected, isTrue);
    expect(preferences.onboardingCompleted, isTrue);
  });

  testWidgets('Profile appearance section toggles and persists dark mode', (
    WidgetTester tester,
  ) async {
    final preferences = await _pumpGuestProfile(tester);

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Light mode'), findsOneWidget);
    expect(find.text('Dark mode'), findsNothing);
    expect(find.text('Light colors are active'), findsOneWidget);
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode_outlined), findsNothing);
    final lightSwitch = tester.widget<Switch>(find.byType(Switch));
    expect(
      lightSwitch.thumbColor?.resolve(<WidgetState>{}),
      AppColors.brandGreen,
    );
    expect(
      Theme.of(tester.element(find.text('Appearance'))).brightness,
      Brightness.light,
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('Dark colors are active'), findsOneWidget);
    expect(find.text('Dark mode'), findsOneWidget);
    expect(find.text('Light mode'), findsNothing);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    expect(find.byIcon(Icons.light_mode_outlined), findsNothing);
    expect(
      Theme.of(tester.element(find.text('Appearance'))).brightness,
      Brightness.dark,
    );
    expect(preferences.appearanceMode, AppearanceMode.dark);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('Light colors are active'), findsOneWidget);
    expect(preferences.appearanceMode, AppearanceMode.light);
  });

  testWidgets('Guest can detach a linked offline workspace', (
    WidgetTester tester,
  ) async {
    final linkStore = _MemoryDeviceAccountLinkStore(
      'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
    );
    await _pumpGuestProfile(
      tester,
      linkedAccountId: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
      linkStore: linkStore,
    );

    expect(find.text('Keep data on this device'), findsOneWidget);
    await tester.tap(find.text('Keep data on this device'));
    await tester.pumpAndSettle();
    expect(find.text('Keep offline data on this device?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Keep data on this device'), findsOneWidget);
  });

  testWidgets('bottom Scan entry separates upload image from Live Scan', (
    WidgetTester tester,
  ) async {
    await _pumpReturningGuest(tester, imagePicker: FakeScanImagePicker());

    expect(
      tester.widget<Icon>(find.byIcon(Icons.home)).color,
      AppColors.brandGreen,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.inventory_2_outlined)).color,
      AppColors.navigationInactive,
    );
    final homeInkWell = tester.widget<InkWell>(
      find.ancestor(of: find.text('Home'), matching: find.byType(InkWell)),
    );
    expect(
      homeInkWell.overlayColor?.resolve({WidgetState.pressed}),
      Colors.transparent,
    );
    expect(homeInkWell.splashFactory, NoSplash.splashFactory);
    expect(find.text('Scan'), findsNothing);
    expect(find.bySemanticsLabel('Scan'), findsOneWidget);
    expect(find.byIcon(Icons.document_scanner_outlined), findsWidgets);
    expect(find.byIcon(Icons.camera_alt_outlined), findsNothing);
    final scanButton = find.byKey(const Key('main-nav-scan-button'));
    final scanMaterial = tester.widget<Material>(scanButton);
    expect(scanMaterial.color, AppColors.brandGreen);
    expect(scanMaterial.shape, isA<RoundedRectangleBorder>());
    expect(tester.getSize(scanButton), const Size(60, 46));
    await tester.tap(find.bySemanticsLabel('Scan'));
    await _pumpRoute(tester);

    expect(find.text('Choose a scan method'), findsOneWidget);
    expect(find.text('Upload image'), findsOneWidget);
    expect(find.text('Live Scan'), findsOneWidget);
    expect(find.text('Coming later'), findsNothing);
    expect(
      find.text('Camera access is requested only when needed'),
      findsOneWidget,
    );
    final uploadCard = find
        .ancestor(of: find.text('Upload image'), matching: find.byType(Card))
        .first;
    final liveScanCard = find
        .ancestor(of: find.text('Live Scan'), matching: find.byType(Card))
        .first;
    final privacyCard = find
        .ancestor(
          of: find.text('Camera access is requested only when needed'),
          matching: find.byType(Card),
        )
        .first;
    expect(
      tester.getTopLeft(liveScanCard).dy - tester.getBottomLeft(uploadCard).dy,
      closeTo(16, 0.1),
    );
    expect(
      tester.getTopLeft(privacyCard).dy - tester.getBottomLeft(liveScanCard).dy,
      closeTo(16, 0.1),
    );

    await tester.tap(find.text('Upload image'));
    await _pumpRoute(tester);

    expect(find.text('Upload one fruit image'), findsOneWidget);
    expect(find.text('Take a photo'), findsNothing);
    expect(find.text('Preview low-confidence sample'), findsNothing);

    await tester.binding.handlePopRoute();
    await _pumpRoute(tester);

    expect(find.text('Choose a scan method'), findsOneWidget);
  });

  testWidgets('Home scan action opens the method chooser', (
    WidgetTester tester,
  ) async {
    await _pumpReturningGuest(tester, imagePicker: FakeScanImagePicker());

    expect(find.text('Guest mode'), findsOneWidget);
    expect(find.text('Offline ready'), findsOneWidget);
    expect(find.text('Carabao mango'), findsOneWidget);
    expect(find.text('Lakatan banana'), findsOneWidget);
    expect(find.text('Red papaya'), findsOneWidget);
    expect(find.text('Center one fruit in the image.'), findsOneWidget);
    expect(find.text('Use bright, even lighting.'), findsOneWidget);
    expect(find.text('Avoid blur and obstruction.'), findsOneWidget);
    expect(find.text('Save and review'), findsNothing);
    expect(find.text('Save scans offline'), findsNothing);

    await tester.tap(find.text('Start scan'));
    await _pumpRoute(tester);

    expect(find.text('Choose a scan method'), findsOneWidget);
    expect(find.text('Upload image'), findsOneWidget);
    expect(find.text('Live Scan'), findsOneWidget);
  });

  testWidgets('Home welcome card shows the Chami mascot prompt', (
    WidgetTester tester,
  ) async {
    await _pumpReturningGuest(tester, imagePicker: FakeScanImagePicker());

    expect(find.byKey(const Key('home-chami-mascot')), findsOneWidget);
    expect(find.bySemanticsLabel('Chami holding a mango'), findsOneWidget);
    expect(find.byKey(const Key('home-chami-prompt')), findsOneWidget);
    expect(find.text('Ready to check a fruit?'), findsOneWidget);
    expect(find.text('Start scan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home mascot prompt remains usable in dark compact layout', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });

    await _pumpKami(
      tester,
      destination: StartupDestination.returningGuest,
      preferences: FakeStartupPreferences(
        guestSelected: true,
        onboardingCompleted: true,
        appearanceMode: AppearanceMode.dark,
      ),
    );

    expect(find.byKey(const Key('home-chami-mascot')), findsOneWidget);
    expect(find.byKey(const Key('home-chami-prompt')), findsOneWidget);
    expect(find.text('Ready to check a fruit?'), findsOneWidget);
    expect(find.text('Start scan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('History loads older scans in explicit pages', (
    WidgetTester tester,
  ) async {
    final records = List.generate(
      51,
      (index) => _savedDemoRecord(
        id: '00000000-0000-4000-8000-${index.toString().padLeft(12, '0')}',
        createdAt: DateTime.utc(2026, 8, 10).subtract(Duration(minutes: index)),
        omitImage: true,
      ),
    );
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker(),
      scanRepository: FakeScanRecordRepository(initialRecords: records),
    );

    await tester.tap(find.bySemanticsLabel('History'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Load more'), 500);

    expect(find.text('Showing 50 of 51 scans'), findsOneWidget);
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    expect(find.text('Showing 51 of 51 scans'), findsOneWidget);
    expect(find.text('Load more'), findsNothing);
  });

  testWidgets('Home remains usable on a narrow screen with larger text', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });

    await _pumpKami(
      tester,
      destination: StartupDestination.returningGuest,
      preferences: FakeStartupPreferences(
        guestSelected: true,
        onboardingCompleted: true,
      ),
    );

    expect(find.text('Ready to check a fruit?'), findsOneWidget);
    expect(find.text('Start scan'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Avoid blur and obstruction.'),
      300,
    );
    expect(find.text('Avoid blur and obstruction.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('History and Batches show honest refreshed empty states', (
    WidgetTester tester,
  ) async {
    await _pumpReturningGuest(tester, imagePicker: FakeScanImagePicker());

    await tester.tap(find.bySemanticsLabel('History'));
    await tester.pumpAndSettle();

    expect(find.text('Review past results'), findsOneWidget);
    expect(find.text('No saved scans yet'), findsOneWidget);
    expect(find.text('Ready offline'), findsOneWidget);
    final historyAvailability = find.text(
      'Saved scans stay available on this device, even when you are offline.',
    );
    expect(historyAvailability, findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('history-filter-button'))).dy,
      greaterThan(tester.getBottomLeft(historyAvailability).dy),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('history-select-button'))).dy,
      greaterThan(tester.getBottomLeft(historyAvailability).dy),
    );
    expect(
      find.text(
        'Save a result after choosing a fruit photo and it will appear here.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel('Batches'));
    await tester.pumpAndSettle();

    expect(find.text('Organize fruit by batch'), findsOneWidget);
    expect(find.text('No batches yet'), findsOneWidget);
    expect(find.text('Ready offline'), findsOneWidget);
    expect(find.text('Create first batch'), findsNothing);
  });

  testWidgets('empty History selection keeps Cancel available', (
    WidgetTester tester,
  ) async {
    await _pumpReturningGuest(tester, imagePicker: FakeScanImagePicker());

    await tester.tap(find.bySemanticsLabel('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history-select-button')));
    await tester.pumpAndSettle();

    expect(find.text('No saved scans yet'), findsOneWidget);
    expect(find.text('0 of 0 selected'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-select-button')), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Cancel'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('History refreshes when a saved scan changes locally', (
    WidgetTester tester,
  ) async {
    final scans = FakeScanRecordRepository();
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker(),
      scanRepository: scans,
    );

    await tester.tap(find.bySemanticsLabel('History'));
    await tester.pumpAndSettle();
    expect(find.text('No saved scans yet'), findsOneWidget);

    await scans.create(
      _savedDemoRecord(
        id: '99999999-9999-4999-8999-999999999999',
        omitImage: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No saved scans yet'), findsNothing);
    expect(find.text('Showing 1 of 1 scans'), findsOneWidget);
    expect(find.text('Carabao mango'), findsOneWidget);
  });

  testWidgets('History and Batches support larger text on a narrow screen', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });

    await _pumpReturningGuest(tester, imagePicker: FakeScanImagePicker());

    await tester.tap(find.bySemanticsLabel('History'));
    await tester.pumpAndSettle();
    expect(find.text('Review past results'), findsOneWidget);
    expect(find.text('Ready offline'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.bySemanticsLabel('Batches'));
    await tester.pumpAndSettle();
    expect(find.text('Organize fruit by batch'), findsOneWidget);
    expect(find.text('Create first batch'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('History filters scans by fruit, ripeness, and batch', (
    WidgetTester tester,
  ) async {
    final scans = FakeScanRecordRepository(
      initialRecords: [
        _savedDemoRecord(
          id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
          fruit: FruitIdentifier.carabaoMango,
          ripeness: RipenessStage.ripe,
          batchId: _batchFixtureId,
          omitImage: true,
        ),
        _savedDemoRecord(
          id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
          fruit: FruitIdentifier.carabaoMango,
          ripeness: RipenessStage.unripe,
          omitImage: true,
        ),
        _savedDemoRecord(
          id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
          fruit: FruitIdentifier.redPapaya,
          ripeness: RipenessStage.ripe,
          batchId: _batchFixtureId,
          omitImage: true,
        ),
      ],
    );
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker(),
      scanRepository: scans,
      batchRepository: FakeBatchRepository(
        scans,
        initialBatches: [_batchFixture()],
      ),
    );

    await tester.tap(find.bySemanticsLabel('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history-filter-button')));
    await tester.pumpAndSettle();

    expect(find.text('Filter saved scans'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Carabao mango'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Ripe'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'In a batch'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Oldest first'));
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();

    expect(find.text('Carabao mango'), findsOneWidget);
    expect(find.text('Fruit: Carabao mango'), findsOneWidget);
    expect(find.text('Ripeness: Ripe'), findsOneWidget);
    expect(find.text('Batch: In a batch'), findsOneWidget);
    expect(find.text('Batch: Market mangoes'), findsOneWidget);
    expect(find.text('Sort: Oldest first'), findsOneWidget);
    expect(find.text('Red papaya'), findsNothing);
    expect(find.text('4'), findsOneWidget);

    await tester.tap(find.byKey(const Key('history-filter-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Overripe'));
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();

    expect(find.text('No scans match these filters'), findsOneWidget);
    expect(find.text('Fruit: Carabao mango'), findsOneWidget);
    expect(find.text('Ripeness: Overripe'), findsOneWidget);
    expect(find.text('Batch: In a batch'), findsOneWidget);
    expect(find.text('Sort: Oldest first'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('No scans match these filters'), findsNothing);
    expect(find.text('Fruit: Carabao mango'), findsNothing);
    expect(find.text('Ripeness: Ripe'), findsNothing);
    expect(find.text('Batch: In a batch'), findsNothing);
    expect(find.text('Sort: Oldest first'), findsNothing);
    expect(find.text('Batch: Market mangoes'), findsNWidgets(2));
    expect(find.text('Batch: Unassigned'), findsOneWidget);
    expect(find.text('Red papaya'), findsOneWidget);
  });

  testWidgets('History supports selecting and deleting multiple scans', (
    WidgetTester tester,
  ) async {
    final scans = FakeScanRecordRepository(
      initialRecords: [
        _savedDemoRecord(
          id: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
          fruit: FruitIdentifier.carabaoMango,
          omitImage: true,
        ),
        _savedDemoRecord(
          id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
          fruit: FruitIdentifier.redPapaya,
          omitImage: true,
        ),
      ],
    );
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker(),
      scanRepository: scans,
    );

    await tester.tap(find.bySemanticsLabel('History'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextButton, 'Select'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(TextButton, 'Select'),
        matching: find.byIcon(Icons.check_box_outlined),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('history-select-button')));
    await tester.pumpAndSettle();

    expect(find.text('0 selected'), findsNothing);
    expect(find.text('History'), findsAtLeastNWidgets(1));
    expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(TextButton, 'Cancel'),
        matching: find.byIcon(Icons.close),
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, 'Delete'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Add to batch'), findsNothing);
    expect(find.text('0 of 2 selected'), findsOneWidget);
    expect(
      tester.getTopLeft(find.widgetWithText(TextButton, 'Cancel')).dy,
      greaterThan(
        tester.getBottomLeft(find.widgetWithText(TextButton, 'Clear')).dy,
      ),
    );
    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsNothing);
    expect(find.text('2 of 2 selected'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Delete'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Add to batch'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Add to batch'))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const Key('history-delete-selected')));
    await tester.pumpAndSettle();
    expect(find.text('Delete 2 saved scans?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(
      find.text('2 scans deleted. Private images deleted.'),
      findsOneWidget,
    );
    expect(find.text('No saved scans yet'), findsOneWidget);
    expect(await scans.listActive(), isEmpty);
  });

  testWidgets('History assigned selections expose no bulk actions', (
    WidgetTester tester,
  ) async {
    final scans = FakeScanRecordRepository(
      initialRecords: [
        _savedDemoRecord(
          id: '11111111-1111-4111-8111-111111111111',
          batchId: _batchFixtureId,
          omitImage: true,
        ),
        _savedDemoRecord(
          id: '22222222-2222-4222-8222-222222222222',
          omitImage: true,
        ),
      ],
    );
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker(),
      scanRepository: scans,
      batchRepository: FakeBatchRepository(
        scans,
        initialBatches: [_batchFixture()],
      ),
    );

    await tester.tap(find.bySemanticsLabel('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history-select-button')));
    await tester.pump();
    await tester.tap(find.text('Select all'));
    await tester.pump();

    expect(find.widgetWithText(TextButton, 'Delete'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Add to batch'), findsNothing);
    expect(
      find.text('Assigned scans can only be managed from Batch Details.'),
      findsOneWidget,
    );
  });

  testWidgets('History mixed unassigned fruits allow delete only', (
    WidgetTester tester,
  ) async {
    final scans = FakeScanRecordRepository(
      initialRecords: [
        _savedDemoRecord(
          id: '33333333-3333-4333-8333-333333333333',
          fruit: FruitIdentifier.carabaoMango,
          omitImage: true,
        ),
        _savedDemoRecord(
          id: '44444444-4444-4444-8444-444444444444',
          fruit: FruitIdentifier.redPapaya,
          omitImage: true,
        ),
      ],
    );
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker(),
      scanRepository: scans,
    );

    await tester.tap(find.bySemanticsLabel('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history-select-button')));
    await tester.pump();
    await tester.tap(find.text('Select all'));
    await tester.pump();

    expect(find.widgetWithText(TextButton, 'Delete'), findsOneWidget);
    final addButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Add to batch'),
    );
    expect(addButton.onPressed, isNull);
    expect(
      find.text('Select scans of one fruit type to add them to a batch.'),
      findsOneWidget,
    );
  });

  testWidgets('History adds same-fruit selection to a batch', (
    WidgetTester tester,
  ) async {
    final scans = FakeScanRecordRepository(
      initialRecords: [
        _savedDemoRecord(
          id: '55555555-5555-4555-8555-555555555555',
          omitImage: true,
        ),
        _savedDemoRecord(
          id: '66666666-6666-4666-8666-666666666666',
          omitImage: true,
        ),
      ],
    );
    final batches = FakeBatchRepository(
      scans,
      initialBatches: [_batchFixture()],
    );
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker(),
      scanRepository: scans,
      batchRepository: batches,
    );

    await tester.tap(find.bySemanticsLabel('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history-select-button')));
    await tester.pump();
    await tester.tap(find.text('Select all'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('history-add-selected-to-batch')));
    await tester.pumpAndSettle();

    expect(find.text('2 scans selected'), findsOneWidget);
    expect(find.text('Choose a Carabao mango batch'), findsOneWidget);
    await tester.tap(find.text('Market mangoes'));
    await tester.pumpAndSettle();

    expect(find.text('2 scans added to batch.'), findsOneWidget);
    expect(
      (await scans.listActive()).every(
        (record) => record.batchId == _batchFixtureId,
      ),
      isTrue,
    );
    expect(batches.assignmentCalls, 1);
  });

  testWidgets('gallery image reaches explicitly fake result', (
    WidgetTester tester,
  ) async {
    const image = _galleryFixture;
    final picker = FakeScanImagePicker()..nextSelection = image;
    await _pumpReturningGuest(tester, imagePicker: picker);

    await _openUploadFlow(tester);
    expect(find.text('Upload one fruit image'), findsOneWidget);
    expect(find.text('Take a photo'), findsNothing);
    expect(find.text('Return to previous result'), findsNothing);

    await tester.tap(find.text('Choose from gallery'));
    await _pumpImagePreview(tester);
    expect(find.text(image.name), findsOneWidget);
    expect(find.text('Use photo'), findsOneWidget);
    expect(
      tester.getCenter(find.text('Cancel')).dx,
      lessThan(tester.getCenter(find.text('Change')).dx),
    );
    expect(
      tester.getCenter(find.text('Use photo')).dy,
      lessThan(tester.getCenter(find.text('Cancel')).dy),
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Use photo'))
          .onPressed,
      isNotNull,
    );

    await tester.scrollUntilVisible(find.text('Use photo'), 300);
    await tester.tap(find.text('Use photo'));
    await _pumpRoute(tester);

    expect(find.text('Demo preview only'), findsOneWidget);
    expect(find.text('Carabao mango'), findsOneWidget);
    expect(find.text('Ripe'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.text('Model confidence (demo)'), findsOneWidget);
    expect(find.text('87%'), findsOneWidget);
    expect(find.text('Estimated quality window'), findsOneWidget);
    expect(find.text('approximately 1–3 days'), findsOneWidget);
    expect(find.text(shelfLifeVariabilityDisclaimer), findsOneWidget);
    expect(find.text('Not saved yet'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Save Result'), findsOneWidget);
    expect(find.text('Save result — persistence not enabled'), findsNothing);
    expect(find.text('Add to batch — persistence not enabled'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Rescan'), findsOneWidget);
    expect(picker.pickCalls, 1);
  });

  testWidgets('dark model confidence card uses a readable dark surface', (
    WidgetTester tester,
  ) async {
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker()..nextSelection = _galleryFixture,
      appearanceMode: AppearanceMode.dark,
    );
    await _openFakeResult(tester);

    final confidenceCard = tester.widget<Container>(
      find.byKey(const Key('model-confidence-card')),
    );
    final decoration = confidenceCard.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.darkSurface);
    expect(find.text('Model confidence (demo)'), findsOneWidget);
    expect(find.text('87%'), findsOneWidget);
  });

  testWidgets('assessment result uses a secondary rescan action', (
    WidgetTester tester,
  ) async {
    final picker = FakeScanImagePicker()..nextSelection = _galleryFixture;
    await _pumpReturningGuest(tester, imagePicker: picker);
    await _openFakeResult(tester);

    expect(find.text('Back to home'), findsNothing);
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Rescan'))
          .onPressed,
      isNotNull,
    );
    expect(find.widgetWithText(FilledButton, 'Rescan'), findsNothing);
  });

  testWidgets(
    'low confidence shows a tentative result and uploads a new photo',
    (WidgetTester tester) async {
      final picker = FakeScanImagePicker()
        ..nextSelection = _lowConfidenceFixture;
      await _pumpReturningGuest(tester, imagePicker: picker);
      await _openLowConfidenceResult(tester);

      expect(
        find.text('Low confidence - this result may not be accurate'),
        findsOneWidget,
      );
      expect(find.text('Tentative demo result'), findsOneWidget);
      expect(find.text('Carabao mango'), findsOneWidget);
      expect(find.text('Ripe'), findsOneWidget);
      expect(find.text('31%'), findsOneWidget);
      expect(find.text('Shelf-life guidance not shown'), findsOneWidget);
      expect(find.text('Shelf-life guidance unavailable'), findsNothing);
      expect(find.text('Back to selected image'), findsOneWidget);
      expect(find.text('Return to previous result'), findsNothing);

      picker.nextSelection = _galleryFixture;
      await tester.scrollUntilVisible(find.text('Upload a new photo'), 300);
      await tester.tap(find.text('Upload a new photo'));
      await _pumpRoute(tester);
      await _pumpImagePreview(tester);

      expect(find.text(_galleryFixture.name), findsOneWidget);
      expect(
        find.text('Low confidence - this result may not be accurate'),
        findsNothing,
      );
      expect(picker.pickCalls, 2);
    },
  );

  testWidgets('unrecognized result hides the candidate and shows its heatmap', (
    WidgetTester tester,
  ) async {
    final picker = FakeScanImagePicker()..nextSelection = _unrecognizedFixture;
    await _pumpReturningGuest(tester, imagePicker: picker);
    await _openUnrecognizedResult(tester);

    expect(find.text('Fruit not recognized or unclear'), findsNWidgets(2));
    expect(find.text('Carabao mango'), findsNothing);
    expect(find.text('Ripe'), findsNothing);
    expect(find.text('42%'), findsNothing);
    expect(find.text('Isolated'), findsNothing);
    expect(find.text('Original'), findsOneWidget);
    expect(find.text('Grad-CAM'), findsOneWidget);
    expect(find.byKey(const Key('rejected-gradcam-overlay')), findsOneWidget);

    await tester.tap(find.text('Original'));
    await tester.pump();
    expect(find.byKey(const Key('rejected-gradcam-overlay')), findsNothing);

    expect(find.text('What Chami focused on'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Heatmap explanation. Colored regions show what influenced the model, '
        'not fruit boundaries or proof of correctness.',
      ),
      findsOneWidget,
    );
    expect(find.text('Upload a new photo'), findsOneWidget);
    expect(find.text('Save Result'), findsNothing);
  });

  testWidgets('unrecognized result app bar fits compact phone width', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final picker = FakeScanImagePicker()..nextSelection = _unrecognizedFixture;
    await _pumpReturningGuest(tester, imagePicker: picker);
    await _openUnrecognizedResult(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('upload preview hides the low-confidence developer sample', (
    WidgetTester tester,
  ) async {
    final picker = FakeScanImagePicker()..nextSelection = _galleryFixture;
    await _pumpReturningGuest(tester, imagePicker: picker);
    await _openUploadFlow(tester);
    await tester.tap(find.text('Choose from gallery'));
    await _pumpImagePreview(tester);

    expect(find.text('Preview low-confidence sample'), findsNothing);
    expect(find.text('Developer preview - debug builds only'), findsNothing);
    expect(find.text(_galleryFixture.name), findsOneWidget);
    expect(picker.pickCalls, 1);
  });

  testWidgets('Android Back preserves the low-confidence selected image', (
    WidgetTester tester,
  ) async {
    final picker = FakeScanImagePicker()..nextSelection = _lowConfidenceFixture;
    await _pumpReturningGuest(tester, imagePicker: picker);
    await _openLowConfidenceResult(tester);

    await tester.binding.handlePopRoute();
    await _pumpRoute(tester);

    expect(find.text('Upload one fruit image'), findsOneWidget);
    expect(find.text(_lowConfidenceFixture.name), findsOneWidget);
    expect(
      find.text('Low confidence - this result may not be accurate'),
      findsNothing,
    );
  });

  testWidgets('low-confidence rescan stays in the fresh upload flow', (
    WidgetTester tester,
  ) async {
    final picker = FakeScanImagePicker()..nextSelection = _galleryFixture;
    await _pumpReturningGuest(tester, imagePicker: picker);
    await _openFakeResult(tester);

    picker.nextSelection = _lowConfidenceFixture;
    await tester.scrollUntilVisible(find.text('Rescan'), 300);
    await tester.tap(find.text('Rescan'));
    await _pumpRoute(tester);
    await tester.tap(find.text('Choose from gallery'));
    await _pumpImagePreview(tester);
    await tester.scrollUntilVisible(find.text('Use photo'), 300);
    await tester.tap(find.text('Use photo'));
    await _pumpRoute(tester);

    expect(
      find.text('Low confidence - this result may not be accurate'),
      findsOneWidget,
    );
    expect(find.text('Return to previous result'), findsNothing);
    expect(find.text('Back to selected image'), findsOneWidget);

    await tester.tap(find.text('Back to selected image'));
    await _pumpRoute(tester);

    expect(find.text('Return to previous result'), findsNothing);
    expect(find.text('Upload one fruit image'), findsOneWidget);
  });

  testWidgets('rescan opens a fresh upload without a previous-result action', (
    WidgetTester tester,
  ) async {
    final picker = FakeScanImagePicker()..nextSelection = _galleryFixture;
    await _pumpReturningGuest(tester, imagePicker: picker);
    await _openFakeResult(tester);

    await tester.scrollUntilVisible(find.text('Rescan'), 300);
    await tester.tap(find.text('Rescan'));
    await _pumpRoute(tester);

    expect(find.text('Upload one fruit image'), findsOneWidget);
    expect(find.text('Return to previous result'), findsNothing);
    expect(find.byTooltip('Back to scan methods'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to scan methods'));
    await _pumpRoute(tester);
    expect(find.text('Choose a scan method'), findsOneWidget);
    expect(find.byTooltip('Back to home'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to home'));
    await _pumpRoute(tester);
    expect(find.text('Ready to check a fruit?'), findsOneWidget);
  });

  testWidgets('Android Back exits the fresh rescan flow', (
    WidgetTester tester,
  ) async {
    final picker = FakeScanImagePicker()..nextSelection = _galleryFixture;
    await _pumpReturningGuest(tester, imagePicker: picker);
    await _openFakeResult(tester);

    await tester.scrollUntilVisible(find.text('Rescan'), 300);
    await tester.tap(find.text('Rescan'));
    await _pumpRoute(tester);
    expect(find.text('Return to previous result'), findsNothing);

    await tester.binding.handlePopRoute();
    await _pumpRoute(tester);

    expect(find.text('Choose a scan method'), findsOneWidget);
  });

  testWidgets(
    'completed rescans replace one result instead of stacking routes',
    (WidgetTester tester) async {
      final picker = FakeScanImagePicker()..nextSelection = _galleryFixture;
      await _pumpReturningGuest(tester, imagePicker: picker);
      await _openFakeResult(tester);

      await _completeRescan(tester);
      await _completeRescan(tester);
      expect(picker.pickCalls, 3);

      await tester.scrollUntilVisible(find.text('Rescan'), 300);
      await tester.tap(find.text('Rescan'));
      await _pumpRoute(tester);
      expect(find.text('Return to previous result'), findsNothing);
      expect(find.text('Upload one fruit image'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await _pumpRoute(tester);

      expect(find.text('Choose a scan method'), findsOneWidget);
    },
  );

  testWidgets('gallery cancellation stays on stable empty scan state', (
    WidgetTester tester,
  ) async {
    final picker = FakeScanImagePicker();
    await _pumpReturningGuest(tester, imagePicker: picker);

    await _openUploadFlow(tester);
    await tester.tap(find.text('Choose from gallery'));
    await _pumpRoute(tester);

    expect(find.text('Choose from gallery'), findsOneWidget);
    expect(find.text('Gallery unavailable'), findsNothing);
    expect(picker.pickCalls, 1);
  });

  testWidgets('cancelled replacement keeps the current selection', (
    WidgetTester tester,
  ) async {
    const image = _galleryFixture;
    final picker = FakeScanImagePicker()..nextSelection = image;
    await _pumpReturningGuest(tester, imagePicker: picker);

    await _openUploadFlow(tester);
    await tester.tap(find.text('Choose from gallery'));
    await _pumpImagePreview(tester);
    expect(find.text(image.name), findsOneWidget);

    picker.nextSelection = null;
    await tester.scrollUntilVisible(find.text('Change'), 300);
    await tester.tap(find.text('Change'));
    await _pumpRoute(tester);

    expect(find.text(image.name), findsOneWidget);
    expect(find.text('Gallery unavailable'), findsNothing);
  });

  testWidgets('picker failure shows inline error without advancing', (
    WidgetTester tester,
  ) async {
    final picker = FakeScanImagePicker()..failPick = true;
    await _pumpReturningGuest(tester, imagePicker: picker);

    await _openUploadFlow(tester);
    await tester.tap(find.text('Choose from gallery'));
    await _pumpRoute(tester);

    expect(find.text('Gallery unavailable'), findsOneWidget);
    expect(
      find.text('Chami could not open that image. Please choose another one.'),
      findsOneWidget,
    );
  });

  testWidgets('unreadable selected image cannot be used', (
    WidgetTester tester,
  ) async {
    final picker = FakeScanImagePicker()
      ..nextSelection = SelectedScanImage(
        path: '/virtual/kami-missing-image.png',
        name: 'missing-image.png',
      );
    await _pumpReturningGuest(
      tester,
      imagePicker: picker,
      imageProviderFactory: (_) => MemoryImage(Uint8List.fromList([0, 1, 2])),
    );

    await _openUploadFlow(tester);
    await tester.tap(find.text('Choose from gallery'));
    await _pumpImagePreview(tester);

    expect(
      find.text('This image could not be previewed. Choose another image.'),
      findsOneWidget,
    );
    final usePhoto = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Use photo'),
    );
    expect(usePhoto.onPressed, isNull);
  });

  testWidgets('lost Android picker selection is recovered', (
    WidgetTester tester,
  ) async {
    const image = _galleryFixture;
    final picker = FakeScanImagePicker()..recoveredSelection = image;
    await _pumpReturningGuest(tester, imagePicker: picker);

    await _openUploadFlow(tester);
    await _pumpImagePreview(tester);

    expect(find.text(image.name), findsOneWidget);
    expect(picker.recoveryCalls, 1);
  });

  testWidgets('Save Result adds a labeled Demo scan to History and details', (
    WidgetTester tester,
  ) async {
    final repository = FakeScanRecordRepository();
    final imageStore = FakeRetainedScanImageStore();
    final picker = FakeScanImagePicker()..nextSelection = _galleryFixture;
    await _pumpReturningGuest(
      tester,
      imagePicker: picker,
      scanRepository: repository,
      retainedImageStore: imageStore,
    );
    await _openFakeResult(tester);

    await tester.scrollUntilVisible(find.text('Save Result'), 300);
    await tester.tap(find.text('Save Result'));
    await tester.pumpAndSettle();
    expect(find.text('Save to History'), findsOneWidget);
    expect(find.text('Save & Add to Batch'), findsOneWidget);
    await tester.tap(find.text('Save to History'));
    await tester.pumpAndSettle();

    expect(find.text('Saved offline'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'New Scan'), findsOneWidget);
    expect(find.text('Add to Batch'), findsOneWidget);
    expect(find.text('View in History'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'New Scan'))
          .onPressed,
      isNotNull,
    );
    expect(find.widgetWithText(OutlinedButton, 'Add to Batch'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'View in History'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Rescan'), findsNothing);
    expect(
      find.widgetWithText(OutlinedButton, 'View in History'),
      findsNothing,
    );
    expect(repository.createCalls, 1);
    expect(imageStore.retainCalls, 1);
    final saved = await repository.listActive();
    expect(saved, hasLength(1));
    expect(saved.single.resultOrigin, ResultOrigin.demo);
    expect(saved.single.localImageRelativePath, startsWith('history_images/'));

    await tester.tap(find.text('View in History'));
    await tester.pumpAndSettle();

    expect(find.text('Review past results'), findsOneWidget);
    expect(find.text('Carabao mango'), findsOneWidget);
    expect(find.text('Demo'), findsOneWidget);

    await tester.tap(find.text('Carabao mango'));
    await tester.pumpAndSettle();

    expect(find.text('Saved scan'), findsOneWidget);
    expect(find.text('Saved demo result'), findsOneWidget);
    expect(find.textContaining('Demo record:'), findsOneWidget);
    expect(find.text('Stored on this device'), findsOneWidget);
  });

  testWidgets('failed database save removes its image and can retry', (
    WidgetTester tester,
  ) async {
    final repository = FakeScanRecordRepository()..failCreates = true;
    final imageStore = FakeRetainedScanImageStore();
    final picker = FakeScanImagePicker()..nextSelection = _galleryFixture;
    await _pumpReturningGuest(
      tester,
      imagePicker: picker,
      scanRepository: repository,
      retainedImageStore: imageStore,
    );
    await _openFakeResult(tester);

    await tester.scrollUntilVisible(find.text('Save Result'), 300);
    await tester.tap(find.text('Save Result'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save to History'));
    await tester.pumpAndSettle();

    expect(find.text('Save failed'), findsOneWidget);
    expect(repository.createCalls, 1);
    expect(await repository.listActive(), isEmpty);
    expect(imageStore.removedPaths, hasLength(1));

    repository.failCreates = false;
    await tester.tap(find.text('Save Result'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save to History'));
    await tester.pumpAndSettle();

    expect(find.text('Saved offline'), findsOneWidget);
    expect(repository.createCalls, 2);
    expect(await repository.listActive(), hasLength(1));
  });

  testWidgets('History exposes repository errors without changing data', (
    WidgetTester tester,
  ) async {
    final repository = FakeScanRecordRepository()..failReads = true;
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker(),
      scanRepository: repository,
    );

    await tester.tap(find.bySemanticsLabel('History'));
    await tester.pumpAndSettle();

    expect(find.text('History could not be loaded'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('creates an empty local batch and opens its details', (
    WidgetTester tester,
  ) async {
    final scans = FakeScanRecordRepository();
    final batches = FakeBatchRepository(scans);
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker(),
      scanRepository: scans,
      batchRepository: batches,
    );

    await tester.tap(find.bySemanticsLabel('Batches'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Create batch'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      '  Friday market mangoes  ',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create batch'));
    await tester.pumpAndSettle();

    expect(find.text('Friday market mangoes'), findsOneWidget);
    expect(find.text('Ripeness summary'), findsOneWidget);
    expect(find.text('No scans in this batch'), findsOneWidget);
    expect(find.text('Change fruit type'), findsOneWidget);
    expect(
      find.textContaining('Add at least one saved scan before creating'),
      findsOneWidget,
    );
    await tester.tap(find.text('Add scans'));
    await _pumpRoute(tester);
    expect(find.text('No unassigned Carabao mango scans'), findsOneWidget);
    expect(find.text('Ready offline'), findsNothing);
    expect(find.text('Back to batch'), findsNothing);
    expect((await batches.listActive()).single.name, 'Friday market mangoes');
  });

  testWidgets('fruit type dropdown creates the selected fruit batch', (
    WidgetTester tester,
  ) async {
    final scans = FakeScanRecordRepository();
    final batches = FakeBatchRepository(scans);
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker(),
      scanRepository: scans,
      batchRepository: batches,
    );

    await tester.tap(find.bySemanticsLabel('Batches'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Create batch'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Papaya delivery');
    expect(
      tester.getSize(find.byType(DropdownMenu<FruitIdentifier>)).width,
      tester.getSize(find.byType(TextField).first).width,
    );
    await tester.tap(find.byType(DropdownMenu<FruitIdentifier>));
    await tester.pumpAndSettle();
    expect(find.text('Red papaya'), findsWidgets);
    await tester.tap(find.text('Red papaya').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownMenu<FruitIdentifier>));
    await tester.pumpAndSettle();
    expect(find.text('Carabao mango'), findsWidgets);
    await tester.tap(find.text('Red papaya').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Create batch'));
    await tester.pumpAndSettle();

    final batch = (await batches.listActive()).single;
    expect(batch.name, 'Papaya delivery');
    expect(batch.fruit, FruitIdentifier.redPapaya);
  });

  testWidgets(
    'Save & Add to Batch saves first and assigns a compatible batch',
    (WidgetTester tester) async {
      final scans = FakeScanRecordRepository();
      final batches = FakeBatchRepository(
        scans,
        initialBatches: [_batchFixture()],
      );
      final picker = FakeScanImagePicker()..nextSelection = _galleryFixture;
      await _pumpReturningGuest(
        tester,
        imagePicker: picker,
        scanRepository: scans,
        batchRepository: batches,
      );
      await _openFakeResult(tester);

      await tester.scrollUntilVisible(find.text('Save Result'), 300);
      await tester.tap(find.text('Save Result'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save & Add to Batch'));
      await tester.pumpAndSettle();

      expect(find.text('Choose a Carabao mango batch'), findsOneWidget);
      expect(find.text('Market mangoes'), findsOneWidget);
      await tester.tap(find.text('Market mangoes'));
      await tester.pumpAndSettle();

      expect(find.text('Saved offline'), findsOneWidget);
      expect(find.text('View batch'), findsOneWidget);
      final saved = (await scans.listActive()).single;
      expect(saved.batchId, _batchFixtureId);
      expect(batches.assignmentCalls, 1);
    },
  );

  testWidgets('failed batch assignment keeps the result safely in History', (
    WidgetTester tester,
  ) async {
    final scans = FakeScanRecordRepository();
    final batches = FakeBatchRepository(
      scans,
      initialBatches: [_batchFixture()],
    )..failAssignments = true;
    final picker = FakeScanImagePicker()..nextSelection = _galleryFixture;
    await _pumpReturningGuest(
      tester,
      imagePicker: picker,
      scanRepository: scans,
      batchRepository: batches,
    );
    await _openFakeResult(tester);

    await tester.scrollUntilVisible(find.text('Save Result'), 300);
    await tester.tap(find.text('Save Result'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save & Add to Batch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Market mangoes'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('The scan remains safely saved in History.'),
      findsOneWidget,
    );
    final saved = (await scans.listActive()).single;
    expect(saved.batchId, isNull);
    expect(batches.assignmentCalls, 1);
  });

  testWidgets('History detail adds an unassigned scan to a batch', (
    WidgetTester tester,
  ) async {
    final scans = FakeScanRecordRepository(
      initialRecords: [_savedDemoRecord(omitImage: true)],
    );
    final batches = FakeBatchRepository(
      scans,
      initialBatches: [_batchFixture()],
    );
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker(),
      scanRepository: scans,
      batchRepository: batches,
    );

    await tester.tap(find.bySemanticsLabel('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carabao mango'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Add to Batch'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Delete saved scan'),
      findsOneWidget,
    );
    expect(find.text('View batch'), findsNothing);
    await tester.tap(find.text('Add to Batch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Market mangoes'));
    await tester.pumpAndSettle();

    expect(find.text('View batch'), findsOneWidget);
    expect(find.text('Delete saved scan'), findsNothing);
    expect(find.text('Move to another batch'), findsNothing);
    expect(find.text('Remove from batch'), findsNothing);
    expect((await scans.listActive()).single.batchId, _batchFixtureId);
  });

  testWidgets('opens a saved scan from batch details', (
    WidgetTester tester,
  ) async {
    final scan = _savedDemoRecord();
    final assignedScan = SavedScanRecord(
      id: scan.id,
      batchId: _batchFixtureId,
      fruit: scan.fruit,
      ripeness: scan.ripeness,
      modelConfidence: scan.modelConfidence,
      modelVersion: scan.modelVersion,
      resultOrigin: scan.resultOrigin,
      shelfLife: scan.shelfLife,
      localImageRelativePath: null,
      createdAt: scan.createdAt,
      updatedAt: scan.updatedAt,
      syncState: scan.syncState,
    );
    final scans = FakeScanRecordRepository(initialRecords: [assignedScan]);
    final batches = FakeBatchRepository(
      scans,
      initialBatches: [_batchFixture()],
    );
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker(),
      scanRepository: scans,
      batchRepository: batches,
      batchSnapshotOverride: BatchSnapshot(
        batch: _batchFixture(),
        summary: const BatchSummary(total: 1, unripe: 0, ripe: 1, overripe: 0),
        scans: [assignedScan],
        isLocked: false,
      ),
    );

    await tester.tap(find.bySemanticsLabel('Batches'));
    await _pumpRoute(tester);
    await tester.tap(find.text('Market mangoes'));
    await _pumpRoute(tester);
    await _pumpRoute(tester);
    expect(find.text('Saved scans'), findsOneWidget);
    await tester.tap(find.text('Ripe').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Saved demo result'), findsOneWidget);
    expect(find.text('Model confidence (demo)'), findsOneWidget);
    expect(find.text('87%'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Remove from batch'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(OutlinedButton, 'Move to another batch'),
      findsOneWidget,
    );
    expect(find.text('View batch'), findsNothing);
    expect(find.text('Delete saved scan'), findsNothing);
  });

  testWidgets('Batch Details previews three scans and enters selection mode', (
    WidgetTester tester,
  ) async {
    final assignedScans = _batchScanFixtures();
    final scans = FakeScanRecordRepository(initialRecords: assignedScans);
    final batches = FakeBatchRepository(
      scans,
      initialBatches: [_batchFixture()],
    );
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker(),
      scanRepository: scans,
      batchRepository: batches,
      batchSnapshotOverride: BatchSnapshot(
        batch: _batchFixture(),
        summary: const BatchSummary(total: 6, unripe: 2, ripe: 2, overripe: 2),
        scans: assignedScans,
        isLocked: false,
      ),
    );

    await tester.tap(find.bySemanticsLabel('Batches'));
    await _pumpRoute(tester);
    await tester.tap(find.text('Market mangoes'));
    await _pumpRoute(tester);
    await _pumpRoute(tester);

    expect(find.text('Order details'), findsOneWidget);
    expect(find.text('Manage batch'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Ripeness summary')).dy,
      lessThan(tester.getTopLeft(find.text('Saved scans')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Saved scans')).dy,
      lessThan(tester.getTopLeft(find.text('Order details')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Order details')).dy,
      lessThan(tester.getTopLeft(find.text('Manage batch')).dy),
    );
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(3));
    expect(find.text('View all scans (6)'), findsOneWidget);
    expect(find.textContaining('Created Jul 31, 2026'), findsOneWidget);
    expect(find.text('Batch information'), findsOneWidget);
    expect(find.text('Created'), findsOneWidget);
    expect(find.text('Last updated'), findsOneWidget);
    expect(find.text('Change fruit type'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Change fruit type'),
          )
          .onPressed,
      isNull,
    );
    expect(
      find.text('Empty the batch first to change fruit type.'),
      findsOneWidget,
    );

    await tester.tap(find.text('View all scans (6)'));
    await _pumpRoute(tester);

    expect(find.text('All saved scans'), findsOneWidget);
    expect(find.text('6 saved scans'), findsOneWidget);
    expect(find.byKey(const Key('batch-scans-filter-button')), findsOneWidget);
    expect(find.text('Select'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(6));

    await tester.tap(find.byIcon(Icons.chevron_right).first);
    await _pumpRoute(tester);
    expect(find.text('Saved scan'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Remove from batch'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(OutlinedButton, 'Move to another batch'),
      findsOneWidget,
    );
    expect(find.text('View batch'), findsNothing);
    expect(find.text('Delete saved scan'), findsNothing);
    await tester.binding.handlePopRoute();
    await _pumpRoute(tester);

    await tester.tap(find.byKey(const Key('batch-scans-filter-button')));
    await tester.pumpAndSettle();
    expect(find.text('Filter saved scans'), findsOneWidget);
    expect(find.text('Fruit'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Ripe'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Oldest first'));
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();
    expect(find.text('2 of 6 saved scans'), findsOneWidget);
    expect(find.text('Ripeness: Ripe'), findsOneWidget);
    expect(find.text('Sort: Oldest first'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('batch-scans-filter-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Clear all'));
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Select'));
    await tester.pump();
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(6));
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    await tester.tap(find.text('Ripe').first);
    await tester.pump();
    expect(find.text('All saved scans'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.tap(find.text('Select'));
    await tester.pump();
    for (var index = 0; index < 6; index++) {
      await tester.tap(find.byType(Checkbox).at(index));
    }
    await tester.pump();
    expect(find.text('Remove (6)'), findsOneWidget);
    await tester.tap(find.text('Remove (6)'));
    await tester.pumpAndSettle();
    expect(find.text('Remove 6 scans from batch?'), findsOneWidget);
    await tester.tap(find.text('Remove scans'));
    await tester.pumpAndSettle();
    expect(find.text('6 scans removed from batch.'), findsOneWidget);
    expect(
      (await scans.listActive()).every((scan) => scan.batchId == null),
      isTrue,
    );
  });

  testWidgets('Batch Details moves selected scans to another batch', (
    WidgetTester tester,
  ) async {
    final assignedScans = _batchScanFixtures(count: 2);
    final scans = FakeScanRecordRepository(initialRecords: assignedScans);
    final batches = FakeBatchRepository(
      scans,
      initialBatches: [
        _batchFixture(),
        _batchFixture(id: _pendingBatchFixtureId, name: 'Second mangoes'),
      ],
    );
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker(),
      scanRepository: scans,
      batchRepository: batches,
      batchSnapshotOverride: BatchSnapshot(
        batch: _batchFixture(),
        summary: const BatchSummary(total: 2, unripe: 1, ripe: 1, overripe: 0),
        scans: assignedScans,
        isLocked: false,
      ),
    );

    await tester.tap(find.bySemanticsLabel('Batches'));
    await _pumpRoute(tester);
    await tester.tap(find.text('Market mangoes'));
    await _pumpRoute(tester);
    await _pumpRoute(tester);
    await tester.tap(find.text('View all scans (2)'));
    await _pumpRoute(tester);
    await tester.tap(find.text('Select'));
    await tester.pump();
    await tester.tap(find.byType(Checkbox).at(0));
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pump();

    expect(
      find.widgetWithText(OutlinedButton, 'Move to another batch'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Remove (2)'), findsOneWidget);
    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Move to another batch'),
    );
    await _pumpRoute(tester);

    expect(find.text('Move saved scans'), findsOneWidget);
    expect(find.text('2 scans selected'), findsOneWidget);
    await tester.tap(find.text('Second mangoes'));
    await _pumpRoute(tester);

    expect(find.text('2 scans moved to another batch.'), findsOneWidget);
    expect(
      (await scans.listActive()).every(
        (scan) => scan.batchId == _pendingBatchFixtureId,
      ),
      isTrue,
    );
  });

  testWidgets('Batch Details adds only unassigned scans of the same fruit', (
    WidgetTester tester,
  ) async {
    final available = _savedDemoRecord(
      id: '55555555-5555-4555-8555-555555555555',
      ripeness: RipenessStage.unripe,
      createdAt: DateTime.utc(2026, 8, 5),
    );
    final assigned = _savedDemoRecord(
      id: '66666666-6666-4666-8666-666666666666',
      batchId: _batchFixtureId,
      ripeness: RipenessStage.ripe,
    );
    final otherFruit = _savedDemoRecord(
      id: '77777777-7777-4777-8777-777777777777',
      fruit: FruitIdentifier.redPapaya,
      ripeness: RipenessStage.overripe,
    );
    final scans = FakeScanRecordRepository(
      initialRecords: [available, assigned, otherFruit],
    );
    final batches = FakeBatchRepository(
      scans,
      initialBatches: [_batchFixture()],
    );
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker(),
      scanRepository: scans,
      batchRepository: batches,
    );

    await tester.tap(find.bySemanticsLabel('Batches'));
    await _pumpRoute(tester);
    await tester.tap(find.text('Market mangoes'));
    await _pumpRoute(tester);
    await tester.tap(find.text('Add scans'));
    await _pumpRoute(tester);

    expect(find.text('Add scans to batch'), findsOneWidget);
    expect(find.text('Unripe'), findsOneWidget);
    expect(find.byType(BatchRipenessChip), findsOneWidget);
    expect(find.text('Ripe'), findsNothing);
    expect(find.text('Overripe'), findsNothing);
    expect(find.text('Select'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Select'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Select'), findsNothing);
    expect(find.byKey(const Key('batch-scans-filter-button')), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.text('Add selected (0)'), findsNothing);
    expect(find.textContaining('scan(s) selected'), findsNothing);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await _pumpRoute(tester);
    expect(find.text('Saved scan'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Add to Batch'), findsOneWidget);
    expect(find.text('Delete saved scan'), findsNothing);
    expect(find.textContaining('Reviewing this scan'), findsNothing);
    await tester.binding.handlePopRoute();
    await _pumpRoute(tester);
    expect(find.text('Add scans to batch'), findsOneWidget);

    await tester.tap(find.text('Select'));
    await tester.pump();
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(find.text('Add selected (0)'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Add selected (1)'));
    await _pumpRoute(tester);

    expect(await scans.findActiveById(available.id), isNotNull);
    expect(
      (await scans.findActiveById(available.id))?.batchId,
      _batchFixtureId,
    );
    expect(find.text('1 scan added successfully.'), findsOneWidget);
    expect(find.text('Saved scans'), findsOneWidget);
  });

  testWidgets('Add scans detail adds directly to the current batch', (
    WidgetTester tester,
  ) async {
    final available = _savedDemoRecord(
      id: '88888888-8888-4888-8888-888888888888',
      ripeness: RipenessStage.unripe,
    );
    final scans = FakeScanRecordRepository(initialRecords: [available]);
    final batches = FakeBatchRepository(
      scans,
      initialBatches: [_batchFixture()],
    );
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker(),
      scanRepository: scans,
      batchRepository: batches,
    );

    await tester.tap(find.bySemanticsLabel('Batches'));
    await _pumpRoute(tester);
    await tester.tap(find.text('Market mangoes'));
    await _pumpRoute(tester);
    await tester.tap(find.text('Add scans'));
    await _pumpRoute(tester);
    await tester.tap(find.byIcon(Icons.chevron_right));
    await _pumpRoute(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Add to Batch'));
    await _pumpRoute(tester);

    expect(
      (await scans.findActiveById(available.id))?.batchId,
      _batchFixtureId,
    );
    expect(find.text('Add scans to batch'), findsOneWidget);
    expect(find.text('Scan added to Market mangoes.'), findsOneWidget);
  });

  testWidgets('Batches shows a compact order-status tag for each batch', (
    WidgetTester tester,
  ) async {
    final scans = FakeScanRecordRepository();
    final batches = FakeBatchRepository(
      scans,
      initialBatches: [
        _batchFixture(),
        _batchFixture(id: _pendingBatchFixtureId, name: 'Pending mangoes'),
        _batchFixture(id: _completedBatchFixtureId, name: 'Completed mangoes'),
      ],
    );
    final orders = FakeOrderRepository(
      initialOrders: [
        _pendingOrderFixture(batchId: _pendingBatchFixtureId),
        _completedOrderFixture(),
      ],
    );
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker(),
      scanRepository: scans,
      batchRepository: batches,
      orderRepository: orders,
    );

    await tester.tap(find.bySemanticsLabel('Batches'));
    await _pumpRoute(tester);
    await _pumpRoute(tester);

    expect(find.widgetWithText(ChoiceChip, 'No order'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Pending'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Completed'), findsOneWidget);
    expect(find.text('No order'), findsNWidgets(2));
    expect(find.text('Pending'), findsNWidgets(2));
    expect(find.text('Completed'), findsNWidgets(2));
    expect(find.text('Delivery: 2026-08-05'), findsOneWidget);
    expect(find.text('Delivery: 2026-08-06'), findsOneWidget);
    expect(find.text('Locked by a completed order'), findsNothing);
    expect(find.text('Ripeness colors'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Ripeness colors')).dy,
      lessThan(
        tester.getTopLeft(find.widgetWithText(FilledButton, 'Create batch')).dy,
      ),
    );
    expect(find.text('Unripe'), findsOneWidget);
    expect(find.text('Ripe'), findsOneWidget);
    expect(find.text('Overripe'), findsOneWidget);
    expect(find.text('Unripe 0'), findsNothing);
    expect(find.text('Ripe 0'), findsNothing);
    expect(find.text('Overripe 0'), findsNothing);
  });

  testWidgets('Batches searches names and combines status filters', (
    WidgetTester tester,
  ) async {
    final scans = FakeScanRecordRepository();
    final batches = FakeBatchRepository(
      scans,
      initialBatches: [
        _batchFixture(),
        _batchFixture(id: _pendingBatchFixtureId, name: 'Pending mangoes'),
        _batchFixture(id: _completedBatchFixtureId, name: 'Completed mangoes'),
      ],
    );
    final orders = FakeOrderRepository(
      initialOrders: [
        _pendingOrderFixture(batchId: _pendingBatchFixtureId),
        _completedOrderFixture(),
      ],
    );
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker(),
      scanRepository: scans,
      batchRepository: batches,
      orderRepository: orders,
    );

    await tester.tap(find.bySemanticsLabel('Batches'));
    await _pumpRoute(tester);
    await _pumpRoute(tester);

    expect(find.text('Market mangoes'), findsOneWidget);
    expect(find.text('Pending mangoes'), findsOneWidget);
    expect(find.text('Completed mangoes'), findsOneWidget);
    final batchCardWidth = tester
        .getSize(
          find
              .ancestor(
                of: find.text('Market mangoes'),
                matching: find.byType(Card),
              )
              .first,
        )
        .width;

    await tester.enterText(find.byType(TextField), '  PENDING  ');
    await tester.pump();
    expect(find.text('Pending mangoes'), findsOneWidget);
    expect(find.text('Market mangoes'), findsNothing);
    expect(find.text('Completed mangoes'), findsNothing);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Completed'));
    await tester.pump();
    expect(find.text('Completed mangoes'), findsOneWidget);
    expect(find.text('Market mangoes'), findsNothing);
    expect(find.text('Pending mangoes'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Market');
    await tester.pump();
    expect(find.text('No matching batches'), findsOneWidget);
    expect(find.text('Clear search'), findsOneWidget);
    await tester.tap(find.text('Clear search'));
    await tester.pump();
    expect(find.text('Completed mangoes'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Pending'));
    await tester.pump();
    expect(find.text('Pending mangoes'), findsOneWidget);
    await orders.complete(
      batchId: _pendingBatchFixtureId,
      updatedAt: DateTime.utc(2026, 8, 7),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pending mangoes'), findsNothing);
    expect(find.text('No batches with this status'), findsOneWidget);
    final emptyCardWidth = tester
        .getSize(
          find
              .ancestor(
                of: find.text('No batches with this status'),
                matching: find.byType(Card),
              )
              .first,
        )
        .width;
    expect(emptyCardWidth, closeTo(batchCardWidth, 0.01));

    await tester.tap(find.widgetWithText(ChoiceChip, 'Completed'));
    await tester.pump();
    expect(find.text('Pending mangoes'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pump();
    expect(find.text('Market mangoes'), findsOneWidget);
    expect(find.text('Pending mangoes'), findsOneWidget);
    expect(find.text('Completed mangoes'), findsOneWidget);
  });

  testWidgets('batch rename can be canceled or saved without an exception', (
    WidgetTester tester,
  ) async {
    final scans = FakeScanRecordRepository();
    final batches = FakeBatchRepository(
      scans,
      initialBatches: [_batchFixture()],
    );
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker(),
      scanRepository: scans,
      batchRepository: batches,
    );

    await tester.tap(find.bySemanticsLabel('Batches'));
    await _pumpRoute(tester);
    await tester.tap(find.text('Market mangoes'));
    await _pumpRoute(tester);
    await tester.tap(find.text('Rename batch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Rename batch'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Renamed mangoes');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Renamed mangoes'), findsOneWidget);
  });

  testWidgets('saved details remain readable when the image is unreadable', (
    WidgetTester tester,
  ) async {
    final repository = FakeScanRecordRepository(
      initialRecords: [_savedDemoRecord()],
    );
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker(),
      scanRepository: repository,
      imageProviderFactory: (_) => MemoryImage(Uint8List.fromList([0, 1, 2])),
    );

    await tester.tap(find.bySemanticsLabel('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carabao mango'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('The saved image is unavailable.'),
      findsOneWidget,
    );
    expect(find.text('Saved demo result'), findsOneWidget);
    expect(find.text('Model confidence (demo)'), findsOneWidget);
    expect(find.text('87%'), findsOneWidget);
  });

  testWidgets('saved assessment uses readable dark ripeness surfaces', (
    WidgetTester tester,
  ) async {
    final repository = FakeScanRecordRepository(
      initialRecords: [_savedDemoRecord(origin: ResultOrigin.onDeviceModel)],
    );
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker(),
      appearanceMode: AppearanceMode.dark,
      scanRepository: repository,
    );

    await tester.tap(find.bySemanticsLabel('History'));
    await _pumpRoute(tester);
    await tester.tap(find.text('Carabao mango'));
    await _pumpRoute(tester);

    final assessmentCard = tester
        .widgetList<Card>(find.byType(Card))
        .firstWhere((card) => card.color == AppColors.darkRipeSurface);
    expect(assessmentCard.color, AppColors.darkRipeSurface);
    expect(
      Theme.of(tester.element(find.text('Saved assessment'))).brightness,
      Brightness.dark,
    );
    expect(
      Theme.of(
        tester.element(find.text('Saved assessment')),
      ).textTheme.labelLarge?.color,
      AppColors.darkPrimaryText,
    );
    expect(find.text('Model confidence'), findsOneWidget);
    expect(find.text('87%'), findsOneWidget);
    final confidenceProgress = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('saved-model-confidence-progress')),
    );
    expect(confidenceProgress.value, 0.87);
    expect(confidenceProgress.color, const Color(0xFFFFD95A));
  });

  testWidgets('saved overripe recommendation restores as consume immediately', (
    WidgetTester tester,
  ) async {
    final repository = FakeScanRecordRepository(
      initialRecords: [
        _savedDemoRecord(
          ripeness: RipenessStage.overripe,
          shelfLife: const ShelfLifeConsumeImmediately(
            storageGuidance: 'Consume immediately if still sound.',
            evidenceVersion: LiteratureShelfLifeAdvisor.evidenceVersion,
          ),
        ),
      ],
    );
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker(),
      scanRepository: repository,
    );

    await tester.tap(find.bySemanticsLabel('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carabao mango'));
    await tester.pumpAndSettle();

    expect(find.text('Consume immediately'), findsOneWidget);
    expect(find.text('Consume immediately if still sound.'), findsOneWidget);
    expect(find.text(shelfLifeVariabilityDisclaimer), findsOneWidget);
    expect(find.textContaining('0 days'), findsNothing);
    expect(find.textContaining('0–0'), findsNothing);
  });

  testWidgets('saved detail confirms deletion before removing local history', (
    WidgetTester tester,
  ) async {
    final repository = FakeScanRecordRepository(
      initialRecords: [_savedDemoRecord()],
    );
    final imageStore = FakeRetainedScanImageStore();
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker(),
      scanRepository: repository,
      retainedImageStore: imageStore,
    );

    await tester.tap(find.bySemanticsLabel('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carabao mango'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Delete saved scan'), 300);
    await tester.tap(find.text('Delete saved scan'));
    await tester.pumpAndSettle();

    expect(find.text('Delete saved scan?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Review past results'), findsOneWidget);
    expect(find.text('No saved scans yet'), findsOneWidget);
    expect(await repository.listActive(), isEmpty);
    expect(imageStore.removedPaths, hasLength(1));
  });

  testWidgets('Batch Details shows and completes a local order', (
    WidgetTester tester,
  ) async {
    final scan = _savedDemoRecord();
    final assignedScan = SavedScanRecord(
      id: scan.id,
      batchId: _batchFixtureId,
      fruit: scan.fruit,
      ripeness: scan.ripeness,
      modelConfidence: scan.modelConfidence,
      modelVersion: scan.modelVersion,
      resultOrigin: scan.resultOrigin,
      shelfLife: scan.shelfLife,
      localImageRelativePath: scan.localImageRelativePath,
      createdAt: scan.createdAt,
      updatedAt: scan.updatedAt,
      syncState: scan.syncState,
    );
    final scans = FakeScanRecordRepository(initialRecords: [assignedScan]);
    final batches = FakeBatchRepository(
      scans,
      initialBatches: [_batchFixture()],
    );
    final orders = FakeOrderRepository(initialOrders: [_pendingOrderFixture()]);
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker(),
      scanRepository: scans,
      batchRepository: batches,
      orderRepository: orders,
      batchSnapshotOverride: BatchSnapshot(
        batch: _batchFixture(),
        summary: const BatchSummary(total: 1, unripe: 0, ripe: 1, overripe: 0),
        scans: [assignedScan],
        isLocked: false,
      ),
    );

    await tester.tap(find.bySemanticsLabel('Batches'));
    await _pumpRoute(tester);
    await tester.tap(find.text('Market mangoes'));
    await _pumpRoute(tester);
    await _pumpRoute(tester);

    expect(find.text('Order details'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('1 Market Street'), findsOneWidget);
    expect(find.text('Delivery date'), findsOneWidget);
    expect(find.text('Manage local order'), findsOneWidget);
    expect(find.text('Mark order completed'), findsOneWidget);
    expect(find.text('Add scans'), findsOneWidget);

    await tester.tap(find.text('Mark order completed'));
    await tester.pump();
    expect(find.text('Mark order completed?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Complete order'));
    await _pumpRoute(tester);

    expect(find.textContaining('Completed order.'), findsOneWidget);
    expect(find.text('Mark order completed'), findsNothing);
    expect(find.text('View order'), findsOneWidget);
  });

  testWidgets('completed batch deletion confirms saved-scan removal', (
    WidgetTester tester,
  ) async {
    final scan = _savedDemoRecord(batchId: _completedBatchFixtureId);
    final scans = FakeScanRecordRepository(initialRecords: [scan]);
    final batches = FakeBatchRepository(
      scans,
      initialBatches: [
        _batchFixture(id: _completedBatchFixtureId, name: 'Completed mangoes'),
      ],
    );
    final orders = FakeOrderRepository(
      initialOrders: [_completedOrderFixture()],
    );
    final imageStore = FakeRetainedScanImageStore();
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker(),
      scanRepository: scans,
      retainedImageStore: imageStore,
      batchRepository: batches,
      orderRepository: orders,
      batchSnapshotOverride: BatchSnapshot(
        batch: _batchFixture(
          id: _completedBatchFixtureId,
          name: 'Completed mangoes',
        ),
        summary: const BatchSummary(total: 1, unripe: 0, ripe: 1, overripe: 0),
        scans: [scan],
        isLocked: true,
      ),
    );

    await tester.tap(find.bySemanticsLabel('Batches'));
    await _pumpRoute(tester);
    await tester.tap(find.text('Completed mangoes'));
    await _pumpRoute(tester);
    await _pumpRoute(tester);

    await tester.scrollUntilVisible(find.text('Delete batch and scans'), 300);
    await tester.tap(find.text('Delete batch and scans'));
    await tester.pumpAndSettle();

    expect(find.text('Delete completed batch?'), findsOneWidget);
    expect(
      find.textContaining('also delete its 1 saved scans'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await _pumpRoute(tester);

    expect(await batches.findActiveById(_completedBatchFixtureId), isNull);
    expect(await scans.listActive(), isEmpty);
    expect(imageStore.removedPaths, ['history_images/${scan.id}.jpg']);
  });

  testWidgets('a Pending local order can be canceled without deleting scans', (
    WidgetTester tester,
  ) async {
    final scan = _savedDemoRecord();
    final assignedScan = SavedScanRecord(
      id: scan.id,
      batchId: _batchFixtureId,
      fruit: scan.fruit,
      ripeness: scan.ripeness,
      modelConfidence: scan.modelConfidence,
      modelVersion: scan.modelVersion,
      resultOrigin: scan.resultOrigin,
      shelfLife: scan.shelfLife,
      localImageRelativePath: scan.localImageRelativePath,
      createdAt: scan.createdAt,
      updatedAt: scan.updatedAt,
      syncState: scan.syncState,
    );
    final scans = FakeScanRecordRepository(initialRecords: [assignedScan]);
    final batches = FakeBatchRepository(
      scans,
      initialBatches: [_batchFixture()],
    );
    final orders = FakeOrderRepository(initialOrders: [_pendingOrderFixture()]);
    await _pumpReturningGuest(
      tester,
      imagePicker: FakeScanImagePicker(),
      scanRepository: scans,
      batchRepository: batches,
      orderRepository: orders,
    );

    await tester.tap(find.bySemanticsLabel('Batches'));
    await _pumpRoute(tester);
    await tester.tap(find.text('Market mangoes'));
    await _pumpRoute(tester);
    await tester.tap(find.text('Manage local order'));
    await _pumpRoute(tester);

    await tester.tap(find.text('Cancel Pending order'));
    await tester.pump();
    expect(find.text('Cancel Pending order?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel order'));
    await _pumpRoute(tester);

    expect(await orders.findActiveForBatch(_batchFixtureId), isNull);
    expect(await scans.findActiveById(assignedScan.id), isNotNull);
    expect(find.text('Manage local order'), findsOneWidget);
  });
}

SavedScanRecord _savedDemoRecord({
  ResultOrigin origin = ResultOrigin.demo,
  String id = '11111111-1111-4111-8111-111111111111',
  String? batchId,
  FruitIdentifier fruit = FruitIdentifier.carabaoMango,
  RipenessStage ripeness = RipenessStage.ripe,
  DateTime? createdAt,
  bool omitImage = false,
  ShelfLifeEstimate shelfLife = const ShelfLifeUnavailable(
    reason: 'No reviewed guidance is available.',
    evidenceVersion: 'unavailable-v1',
  ),
}) {
  final savedAt = createdAt ?? DateTime.utc(2026, 7, 31, 1);
  return SavedScanRecord(
    id: id,
    batchId: batchId,
    fruit: fruit,
    ripeness: ripeness,
    modelConfidence: 0.87,
    modelVersion: 'fake-foundation-v1',
    resultOrigin: origin,
    shelfLife: shelfLife,
    localImageRelativePath: omitImage ? null : 'history_images/$id.jpg',
    createdAt: savedAt,
    updatedAt: savedAt,
    syncState: LocalSyncState.localOnly,
  );
}

List<SavedScanRecord> _batchScanFixtures({int count = 6}) {
  return List.generate(count, (index) {
    final sequence = (index + 1).toString().padLeft(8, '0');
    final createdAt = DateTime.utc(2026, 8, 5).subtract(Duration(days: index));
    final ripeness = switch (index % 3) {
      0 => RipenessStage.unripe,
      1 => RipenessStage.ripe,
      _ => RipenessStage.overripe,
    };
    return SavedScanRecord(
      id: '$sequence-2222-4222-8222-222222222222',
      batchId: _batchFixtureId,
      fruit: FruitIdentifier.carabaoMango,
      ripeness: ripeness,
      modelConfidence: 0.87,
      modelVersion: 'fake-foundation-v1',
      resultOrigin: ResultOrigin.demo,
      shelfLife: const ShelfLifeUnavailable(
        reason: 'No reviewed guidance is available.',
        evidenceVersion: 'unavailable-v1',
      ),
      localImageRelativePath: null,
      createdAt: createdAt,
      updatedAt: createdAt,
      syncState: LocalSyncState.localOnly,
    );
  });
}

FruitBatch _batchFixture({
  String id = _batchFixtureId,
  String name = 'Market mangoes',
}) {
  final createdAt = DateTime.utc(2026, 7, 31, 11);
  return FruitBatch(
    id: id,
    name: name,
    fruit: FruitIdentifier.carabaoMango,
    createdAt: createdAt,
    updatedAt: createdAt,
    syncState: LocalSyncState.localOnly,
  );
}

BatchOrder _pendingOrderFixture({String batchId = _batchFixtureId}) {
  final createdAt = DateTime.utc(2026, 8, 2, 12);
  return BatchOrder(
    id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    batchId: batchId,
    customerName: 'Ana',
    deliveryAddress: '1 Market Street',
    deliveryDate: DateTime.utc(2026, 8, 5),
    status: BatchOrderStatus.pending,
    createdAt: createdAt,
    updatedAt: createdAt,
    syncState: LocalSyncState.localOnly,
  );
}

BatchOrder _completedOrderFixture() {
  final createdAt = DateTime.utc(2026, 8, 2, 12);
  return BatchOrder(
    id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
    batchId: _completedBatchFixtureId,
    customerName: 'Luis',
    deliveryAddress: '2 Market Street',
    deliveryDate: DateTime.utc(2026, 8, 6),
    status: BatchOrderStatus.completed,
    createdAt: createdAt,
    updatedAt: DateTime.utc(2026, 8, 3, 12),
    syncState: LocalSyncState.localOnly,
  );
}

Future<void> _pumpKami(
  WidgetTester tester, {
  required StartupDestination destination,
  required FakeStartupPreferences preferences,
  FakeScanImagePicker? imagePicker,
  ScanImageProviderFactory? imageProviderFactory,
  ScanRecordRepository? scanRepository,
  RetainedScanImageStore? retainedImageStore,
  BatchRepository? batchRepository,
  OrderRepository? orderRepository,
  BatchSnapshot? batchSnapshotOverride,
  String? linkedAccountId,
  DeviceAccountLinkStore? linkStore,
}) async {
  final repository = scanRepository ?? FakeScanRecordRepository();
  final imageStore = retainedImageStore ?? FakeRetainedScanImageStore();
  final batches =
      batchRepository ??
      FakeBatchRepository(repository as FakeScanRecordRepository);
  final orders = orderRepository ?? FakeOrderRepository();
  if (repository is FakeScanRecordRepository) {
    addTearDown(repository.dispose);
  }
  if (batches is FakeBatchRepository) {
    addTearDown(batches.dispose);
  }
  if (orders is FakeOrderRepository) {
    addTearDown(orders.dispose);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        startupDestinationProvider.overrideWithValue(destination),
        startupPreferencesProvider.overrideWithValue(preferences),
        initialThemeModeProvider.overrideWithValue(
          preferences.appearanceMode == AppearanceMode.dark
              ? ThemeMode.dark
              : ThemeMode.light,
        ),
        if (linkedAccountId != null)
          initialLinkedAccountIdProvider.overrideWithValue(linkedAccountId),
        if (linkStore != null)
          deviceAccountLinkStoreProvider.overrideWithValue(linkStore),
        scanRecordRepositoryProvider.overrideWithValue(repository),
        retainedScanImageStoreProvider.overrideWithValue(imageStore),
        batchRepositoryProvider.overrideWithValue(batches),
        orderRepositoryProvider.overrideWithValue(orders),
        if (batchSnapshotOverride != null)
          batchSnapshotProvider(
            batchSnapshotOverride.batch.id,
          ).overrideWith((ref) => Stream.value(batchSnapshotOverride)),
        ripenessClassifierProvider.overrideWithValue(
          const FakeRipenessClassifier(),
        ),
        shelfLifeAdvisorProvider.overrideWithValue(
          const LiteratureShelfLifeAdvisor(),
        ),
        if (imagePicker != null)
          scanImagePickerProvider.overrideWithValue(imagePicker),
        if (imageProviderFactory != null)
          scanImageProviderFactoryProvider.overrideWithValue(
            imageProviderFactory,
          ),
      ],
      child: const KamiApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpReturningGuest(
  WidgetTester tester, {
  required FakeScanImagePicker imagePicker,
  ScanImageProviderFactory? imageProviderFactory,
  AppearanceMode appearanceMode = AppearanceMode.light,
  ScanRecordRepository? scanRepository,
  RetainedScanImageStore? retainedImageStore,
  BatchRepository? batchRepository,
  OrderRepository? orderRepository,
  BatchSnapshot? batchSnapshotOverride,
}) async {
  await tester.binding.setSurfaceSize(const Size(1080, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await _pumpKami(
    tester,
    destination: StartupDestination.returningGuest,
    preferences: FakeStartupPreferences(
      guestSelected: true,
      onboardingCompleted: true,
      appearanceMode: appearanceMode,
    ),
    imagePicker: imagePicker,
    imageProviderFactory:
        imageProviderFactory ?? (_) => MemoryImage(_validPngBytes),
    scanRepository: scanRepository,
    retainedImageStore: retainedImageStore,
    batchRepository: batchRepository,
    orderRepository: orderRepository,
    batchSnapshotOverride: batchSnapshotOverride,
  );
}

Future<FakeStartupPreferences> _pumpGuestProfile(
  WidgetTester tester, {
  bool failWrites = false,
  String? linkedAccountId,
  DeviceAccountLinkStore? linkStore,
}) async {
  await tester.binding.setSurfaceSize(const Size(1080, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final preferences = FakeStartupPreferences(
    guestSelected: true,
    onboardingCompleted: true,
    failWrites: failWrites,
  );
  await _pumpKami(
    tester,
    destination: StartupDestination.returningGuest,
    preferences: preferences,
    linkedAccountId: linkedAccountId,
    linkStore: linkStore,
  );

  await tester.tap(find.text('Profile'));
  await _pumpRoute(tester);
  return preferences;
}

Future<void> _pumpImagePreview(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _openFakeResult(WidgetTester tester) async {
  await _openUploadFlow(tester);
  await tester.tap(find.text('Choose from gallery'));
  await _pumpImagePreview(tester);
  await tester.scrollUntilVisible(find.text('Use photo'), 300);
  await tester.tap(find.text('Use photo'));
  await _pumpRoute(tester);
  expect(find.textContaining('not a real assessment'), findsOneWidget);
}

Future<void> _openLowConfidenceResult(WidgetTester tester) async {
  await _openUploadFlow(tester);
  await tester.tap(find.text('Choose from gallery'));
  await _pumpImagePreview(tester);
  await tester.scrollUntilVisible(find.text('Use photo'), 300);
  await tester.tap(find.text('Use photo'));
  await _pumpRoute(tester);
  expect(
    find.text('Low confidence - this result may not be accurate'),
    findsOneWidget,
  );
}

Future<void> _openUnrecognizedResult(WidgetTester tester) async {
  await _openUploadFlow(tester);
  await tester.tap(find.text('Choose from gallery'));
  await _pumpImagePreview(tester);
  await tester.scrollUntilVisible(find.text('Use photo'), 300);
  await tester.tap(find.text('Use photo'));
  await _pumpRoute(tester);
  expect(find.text('Fruit not recognized or unclear'), findsNWidgets(2));
}

Future<void> _openUploadFlow(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Scan'));
  await _pumpRoute(tester);
  await tester.tap(find.text('Upload image'));
  await _pumpRoute(tester);
}

final class _MemoryDeviceAccountLinkStore implements DeviceAccountLinkStore {
  _MemoryDeviceAccountLinkStore(this.linkedAccountId);

  String? linkedAccountId;
  final Set<String> promptedAccountIds = <String>{};
  String workspaceId = '11111111-1111-4111-8111-111111111111';
  String installationId = '22222222-2222-4222-8222-222222222222';
  int generation = 0;
  String? revocationToken;
  bool pendingRelease = false;

  @override
  Future<String?> readLinkedAccountId() async => linkedAccountId;

  @override
  Future<void> writeLinkedAccountId(String accountId) async {
    linkedAccountId = accountId;
  }

  @override
  Future<void> clearLinkedAccountId() async {
    linkedAccountId = null;
  }

  @override
  Future<void> clearLinkedAccountIdIfMatches(String accountId) async {
    if (linkedAccountId == accountId) linkedAccountId = null;
  }

  @override
  Future<bool> hasAskedToLink(String accountId) async =>
      promptedAccountIds.contains('$generation:$accountId');

  @override
  Future<void> markAskedToLink(String accountId) async {
    promptedAccountIds.add('$generation:$accountId');
  }

  @override
  Future<String> readOrCreateWorkspaceId() async => workspaceId;

  @override
  Future<String> readOrCreateInstallationId() async => installationId;

  @override
  Future<int> readWorkspaceGeneration() async => generation;

  @override
  Future<int> advanceWorkspaceGeneration() async => ++generation;

  @override
  Future<void> writeRevocationToken(String token) async {
    revocationToken = token;
  }

  @override
  Future<String?> readRevocationToken() async => revocationToken;

  @override
  Future<void> clearRevocationToken() async {
    revocationToken = null;
  }

  @override
  Future<bool> hasPendingRelease() async => pendingRelease;

  @override
  Future<void> setPendingRelease(bool pending) async {
    pendingRelease = pending;
  }
}

Future<void> _completeRescan(WidgetTester tester) async {
  await tester.scrollUntilVisible(find.text('Rescan'), 300);
  await tester.tap(find.text('Rescan'));
  await _pumpRoute(tester);
  expect(find.text('Return to previous result'), findsNothing);

  await tester.tap(find.text('Choose from gallery'));
  await _pumpImagePreview(tester);
  await tester.scrollUntilVisible(find.text('Use photo'), 300);
  await tester.tap(find.text('Use photo'));
  await _pumpRoute(tester);

  expect(find.textContaining('not a real assessment'), findsOneWidget);
  expect(find.text('Return to previous result'), findsNothing);
}

Future<void> _pumpRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}
