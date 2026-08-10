import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kami/app/router/app_routes.dart';
import 'package:kami/features/startup/domain/startup_preferences.dart';

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
        await context.push(AppRoutes.onboarding);
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.eco,
                        size: 44,
                        color: colorScheme.primary,
                        semanticLabel: 'Kami leaf',
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Welcome to Kami',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check fruit ripeness in a few steps.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
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
                          const SizedBox(height: 16),
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
                  const SizedBox(height: 20),
                  Text(
                    'Other options',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Accounts are not available yet.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _isStartingGuestMode
                        ? null
                        : () => context.push(AppRoutes.signIn),
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isStartingGuestMode
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

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AccountPlaceholder(
      title: 'Sign in',
      message: 'Supabase authentication is not part of this foundation.',
    );
  }
}

class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AccountPlaceholder(
      title: 'Create account',
      message:
          'Account creation will be implemented with consent and migration.',
    );
  }
}

class _AccountPlaceholder extends StatelessWidget {
  const _AccountPlaceholder({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.cloud_off_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Not available yet',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(message, textAlign: TextAlign.center),
                      const SizedBox(height: 28),
                      FilledButton.icon(
                        onPressed: () => context.go(AppRoutes.accountChoice),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back to account options'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
