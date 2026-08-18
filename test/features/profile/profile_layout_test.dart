import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kami/app/theme/app_theme.dart';
import 'package:kami/app/theme/theme_mode_controller.dart';
import 'package:kami/features/auth/application/auth_providers.dart';
import 'package:kami/features/auth/data/device_account_link_store.dart';
import 'package:kami/features/auth/domain/auth_repository.dart';
import 'package:kami/features/profile/presentation/profile_screens.dart';
import 'package:kami/features/startup/domain/startup_preferences.dart';
import 'package:kami/features/sync/application/sync_coordinator.dart';
import 'package:kami/features/sync/domain/sync_models.dart';

import '../../helpers/fake_startup_preferences.dart';

void main() {
  testWidgets('signed-in Profile keeps the requested section order', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1080, 2400));
    await _pumpSignedInProfile(tester);

    final accountCard = find.ancestor(
      of: find.text('person@example.com'),
      matching: find.byType(Card),
    );
    final appearance = find.text('Appearance');
    final synchronization = find.text('Synchronization');
    final privacy = find.text('Privacy and data');
    final account = find.text('Account');

    expect(accountCard, findsOneWidget);
    expect(appearance, findsOneWidget);
    expect(find.text('Light mode'), findsOneWidget);
    expect(find.text('Light colors are active'), findsOneWidget);
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    expect(
      tester.getTopLeft(accountCard).dy,
      lessThan(tester.getTopLeft(appearance).dy),
    );
    expect(
      tester.getTopLeft(appearance).dy,
      lessThan(tester.getTopLeft(synchronization).dy),
    );
    expect(
      tester.getTopLeft(synchronization).dy,
      lessThan(tester.getTopLeft(privacy).dy),
    );
    expect(
      tester.getTopLeft(privacy).dy,
      lessThan(tester.getTopLeft(account).dy),
    );

    final appearanceCard = find
        .ancestor(of: find.text('Light mode'), matching: find.byType(Card))
        .first;
    final lightSwitchFinder = find.descendant(
      of: appearanceCard,
      matching: find.byType(Switch),
    );
    final lightSwitch = tester.widget<Switch>(lightSwitchFinder);
    final lightScheme = Theme.of(tester.element(appearance)).colorScheme;
    expect(
      lightSwitch.thumbColor?.resolve(<WidgetState>{}),
      lightScheme.primary,
    );
    expect(
      lightSwitch.trackColor?.resolve(<WidgetState>{}),
      lightScheme.surfaceContainerHighest,
    );

    await tester.tap(lightSwitchFinder);
    await tester.pumpAndSettle();

    expect(find.text('Dark mode'), findsOneWidget);
    expect(find.text('Dark colors are active'), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    expect(find.text('Light mode'), findsNothing);
    expect(find.text('Light colors are active'), findsNothing);
    expect(
      Theme.of(tester.element(find.text('Appearance'))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('signed-in linked workspace stays below Appearance', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1080, 2400));
    await _pumpSignedInProfile(
      tester,
      linkedAccountId: 'account-a',
    );

    expect(find.text('Unlink this device'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Appearance')).dy,
      lessThan(tester.getTopLeft(find.text('Offline workspace')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Offline workspace')).dy,
      lessThan(tester.getTopLeft(find.text('Synchronization')).dy),
    );
  });
}

Future<void> _setViewport(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _pumpSignedInProfile(
  WidgetTester tester, {
  String? linkedAccountId,
}) async {
  final preferences = FakeStartupPreferences(
    guestSelected: false,
    onboardingCompleted: true,
  );
  const account = AccountUser(
    id: 'account-a',
    email: 'person@example.com',
    displayName: 'Person',
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        startupPreferencesProvider.overrideWithValue(preferences),
        initialThemeModeProvider.overrideWithValue(ThemeMode.light),
        currentAccountProvider.overrideWithValue(account),
        initialLinkedAccountIdProvider.overrideWithValue(linkedAccountId),
        syncSettingsProvider.overrideWith(
          (ref) => Stream.value(const LocalSyncSettings()),
        ),
      ],
      child: Consumer(
        builder: (context, ref, child) => MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ref.watch(themeModeProvider),
          home: const ProfileScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
