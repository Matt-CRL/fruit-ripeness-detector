import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kami/app/router/app_routes.dart';
import 'package:kami/core/layout/kami_responsive.dart';
import 'package:kami/features/auth/application/auth_providers.dart';
import 'package:kami/features/startup/domain/startup_preferences.dart';

export 'account_form_screens.dart';

class AccountChoiceScreen extends ConsumerStatefulWidget {
  const AccountChoiceScreen({super.key});

  @override
  ConsumerState<AccountChoiceScreen> createState() =>
      _AccountChoiceScreenState();
}

class _AccountChoiceScreenState extends ConsumerState<AccountChoiceScreen> {
  bool _isStartingGuestMode = false;

  Future<void> _continueAsGuest() async {
    setState(() => _isStartingGuestMode = true);

    try {
      await ref.read(startupPreferencesProvider).selectGuest();
      if (mounted) {
        await context.push('${AppRoutes.onboarding}?from=account-choice');
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guest mode could not be started. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isStartingGuestMode = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accountsAvailable = ref.watch(authRepositoryProvider).isConfigured;
    final compact = KamiResponsive.isCompactPhone(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : 20,
              compact ? 8 : 16,
              compact ? 12 : 20,
              compact ? 20 : 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      colorScheme.brightness == Brightness.dark
                          ? 'assets/branding/chami_wordmark_dark.png'
                          : 'assets/branding/chami_wordmark_light.png',
                      key: const Key('chami-wordmark'),
                      width: compact ? 240 : 300,
                      fit: BoxFit.contain,
                      semanticLabel: 'Chami logo',
                    ),
                  ),
                  SizedBox(height: compact ? 12 : 18),
                  const Text(
                    'Check fruit ripeness in a few steps.',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: compact ? 12 : 18),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(compact ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.offline_bolt_outlined,
                                color: colorScheme.primary,
                                semanticLabel: 'Works without internet',
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Guest mode',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No account or internet needed.',
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: compact ? 12 : 16),
                          FilledButton(
                            onPressed: _isStartingGuestMode
                                ? null
                                : _continueAsGuest,
                            child: _isStartingGuestMode
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Continue as guest'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 12 : 20),
                  Text(
                    'Other options',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    accountsAvailable
                        ? 'Sign in to synchronize across your devices.'
                        : 'Online accounts are not configured in this build.',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: compact ? 12 : 16),
                  OutlinedButton.icon(
                    onPressed: _isStartingGuestMode || !accountsAvailable
                        ? null
                        : () => context.push(AppRoutes.signIn),
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isStartingGuestMode || !accountsAvailable
                        ? null
                        : () => context.push(AppRoutes.createAccount),
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text('Create account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
