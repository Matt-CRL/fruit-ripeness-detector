import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/features/auth/domain/auth_repository.dart';
import 'package:kami/features/auth/application/auth_providers.dart';
import 'package:kami/features/auth/presentation/account_form_screens.dart';
import 'package:kami/features/onboarding/presentation/onboarding_screens.dart';

void main() {
  testWidgets('Create account action is visible on a compact phone', (
    tester,
  ) async {
    await _setViewport(tester, const Size(360, 800));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            const _ConfiguredAuthRepository(),
          ),
        ],
        child: const MaterialApp(home: CreateAccountScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final button = find.widgetWithText(FilledButton, 'Create account');
    expect(button, findsOneWidget);
    expect(tester.getBottomRight(button).dy, lessThanOrEqualTo(800));
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding slides fit a compact phone at normal text size', (
    tester,
  ) async {
    await _setViewport(tester, const Size(360, 800));
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    await tester.pumpAndSettle();

    const titles = [
      'Scan or upload a fruit',
      'Understand the assessment',
      'Organize fruits into batches',
    ];
    for (var index = 0; index < titles.length; index++) {
      final scrollView = find.byKey(
        ValueKey('onboarding-slide-scroll-${titles[index]}'),
      );
      final scrollable = find.descendant(
        of: scrollView,
        matching: find.byType(Scrollable),
      );
      expect(scrollView, findsOneWidget);
      expect(
        tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
        0,
      );
      if (index < titles.length - 1) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding remains reachable with larger text', (tester) async {
    await _setViewport(tester, const Size(360, 800));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    await tester.pumpAndSettle();

    for (final title in const [
      'Scan or upload a fruit',
      'Understand the assessment',
      'Organize fruits into batches',
    ]) {
      final scrollView = find.byKey(ValueKey('onboarding-slide-scroll-$title'));
      await tester.drag(scrollView, const Offset(0, -260));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
      if (title != 'Organize fruits into batches') {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('regular emulator viewport keeps the form available', (
    tester,
  ) async {
    await _setViewport(tester, const Size(411, 914));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            const _ConfiguredAuthRepository(),
          ),
        ],
        child: const MaterialApp(home: CreateAccountScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Create account'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _setViewport(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

final class _ConfiguredAuthRepository implements AuthRepository {
  const _ConfiguredAuthRepository();

  @override
  bool get isConfigured => true;

  @override
  AccountUser? get currentUser => null;

  @override
  Stream<AccountAuthState> watchState() => const Stream.empty();

  @override
  Future<AccountSignUpResult> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) => Future.error(const AccountAuthException('Not used in this test.'));

  @override
  Future<AccountUser> updateDisplayName(String displayName) =>
      Future.error(const AccountAuthException('Not used in this test.'));

  @override
  Future<AccountUser> signIn({
    required String email,
    required String password,
  }) => Future.error(const AccountAuthException('Not used in this test.'));

  @override
  Future<void> requestPasswordReset(String email) =>
      Future.error(const AccountAuthException('Not used in this test.'));

  @override
  Future<void> updateRecoveredPassword(String password) =>
      Future.error(const AccountAuthException('Not used in this test.'));

  @override
  Future<void> reauthenticate(String password) =>
      Future.error(const AccountAuthException('Not used in this test.'));

  @override
  Future<void> signOut({bool localOnly = false}) async {}
}
