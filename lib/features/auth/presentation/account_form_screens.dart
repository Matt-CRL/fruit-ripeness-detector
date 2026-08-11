import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kami/app/router/app_routes.dart';
import 'package:kami/features/auth/application/auth_providers.dart';
import 'package:kami/features/auth/domain/auth_repository.dart';
import 'package:kami/features/startup/domain/startup_preferences.dart';
import 'package:kami/features/sync/application/sync_coordinator.dart';
import 'package:kami/features/sync/data/local_sync_store.dart';
import 'package:kami/features/sync/domain/sync_models.dart';

Future<void> _openAfterAuthentication(
  BuildContext context,
  WidgetRef ref,
  AccountUser user,
) async {
  final localSync = ref.read(localSyncStoreProvider);
  final hasGuestData = await localSync.hasActiveGuestData();
  if (!context.mounted) return;

  if (hasGuestData) {
    final transfer = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Transfer guest data?'),
        content: const Text(
          'Kami found scans, batches, or orders saved in guest mode. Transfer '
          'all active guest data to this account to continue. Nothing is '
          'uploaded until the transfer succeeds.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel and sign out'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Transfer all and continue'),
          ),
        ],
      ),
    );
    if (transfer != true) {
      await ref.read(authRepositoryProvider).signOut(localOnly: true);
      if (context.mounted) context.go(AppRoutes.accountChoice);
      return;
    }
  }

  final existingSettings = await localSync.readSettings();
  var photoConsent = existingSettings.imageUploadConsent;
  if (photoConsent == null) {
    if (!context.mounted) return;
    photoConsent = await _requestDevelopmentPhotoConsent(context);
    if (photoConsent == null) {
      await ref.read(authRepositoryProvider).signOut(localOnly: true);
      if (context.mounted) context.go(AppRoutes.accountChoice);
      return;
    }
  }

  try {
    if (hasGuestData) {
      await localSync.claimGuestData(
        ownerId: user.id,
        imageUploadConsent: photoConsent,
      );
    } else {
      await localSync.purgeGuestTombstones();
      await localSync.setImageUploadConsent(
        consent: photoConsent,
        authenticated: true,
      );
    }
  } on Object {
    await ref.read(authRepositoryProvider).signOut(localOnly: true);
    if (context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Transfer not completed'),
          content: const Text(
            'Your guest data was left unchanged. Sign in and try again.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (context.mounted) context.go(AppRoutes.accountChoice);
    }
    return;
  }

  final completed = await ref
      .read(startupPreferencesProvider)
      .isAccountOnboardingCompleted(user.id);
  if (context.mounted) {
    context.go(completed ? AppRoutes.home : AppRoutes.onboarding);
  }
  unawaited(ref.read(syncCoordinatorProvider).syncNow(SyncTrigger.signIn));
}

Future<bool?> _requestDevelopmentPhotoConsent(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Cloud photo backup'),
      content: const SingleChildScrollView(
        child: Text(
          'Development privacy notice (draft v1)\n\n'
          'Kami synchronizes scan metadata, batches, orders, and account '
          'settings so your account can work across devices. If you allow '
          'photo backup, Kami also stores the compressed, metadata-stripped '
          'JPEG retained in History. Photos are private to your account.\n\n'
          'You can withdraw photo consent later. Withdrawal removes uploaded '
          'photos while keeping local copies and metadata synchronization. '
          'Account tools will provide export and deletion. This wording is '
          'for development and still requires authorized review before thesis '
          'release.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Metadata only'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Allow photo backup'),
        ),
      ],
    ),
  );
}

String? _validateEmail(String? value) {
  final email = value?.trim() ?? '';
  final separator = email.indexOf('@');
  if (separator <= 0 || separator == email.length - 1) {
    return 'Enter a valid email address.';
  }
  return null;
}

String? _validatePassword(String? value) {
  final password = value ?? '';
  if (password.length < 8 ||
      !password.contains(RegExp('[a-z]')) ||
      !password.contains(RegExp('[A-Z]')) ||
      !password.contains(RegExp('[0-9]'))) {
    return 'Use 8+ characters with uppercase, lowercase, and a number.';
  }
  return null;
}

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (mounted) await _openAfterAuthentication(context, ref, user);
    } on AccountAuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AccountFormScaffold(
      title: 'Sign in',
      icon: Icons.login,
      intro: 'Access synchronized scans, batches, orders, and private photos.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              enabled: !_submitting,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              enabled: !_submitting,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
              onFieldSubmitted: (_) => _submitting ? null : _submit(),
              validator: (value) =>
                  (value?.isEmpty ?? true) ? 'Enter your password.' : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _AccountError(message: _error!),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign in'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _submitting
                  ? null
                  : () => context.push(AppRoutes.forgotPassword),
              child: const Text('Forgot password?'),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _submitting = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .createAccount(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (!mounted) return;
      if (result.requiresEmailConfirmation) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Check your email'),
            content: const Text(
              'Use the verification link sent to your email, then sign in.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted) context.go(AppRoutes.signIn);
      } else {
        await _openAfterAuthentication(context, ref, result.user);
      }
    } on AccountAuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AccountFormScaffold(
      title: 'Create account',
      icon: Icons.person_add_outlined,
      intro: 'Create a private account for cross-device synchronization.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              enabled: !_submitting,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newUsername],
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              enabled: !_submitting,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmationController,
              enabled: !_submitting,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Confirm password',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
              validator: (value) => value == _passwordController.text
                  ? null
                  : 'Passwords do not match.',
              onFieldSubmitted: (_) => _submitting ? null : _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _AccountError(message: _error!),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create account'),
            ),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitting = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .requestPasswordReset(_emailController.text);
      if (mounted) setState(() => _sent = true);
    } on AccountAuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AccountFormScaffold(
      title: 'Reset password',
      icon: Icons.mark_email_read_outlined,
      intro: _sent
          ? 'If an account matches that address, a recovery link has been sent.'
          : 'Enter your account email to request a recovery link.',
      child: _sent
          ? FilledButton(
              onPressed: () => context.go(AppRoutes.signIn),
              child: const Text('Back to sign in'),
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    enabled: !_submitting,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: _validateEmail,
                    onFieldSubmitted: (_) => _submitting ? null : _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _AccountError(message: _error!),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Send recovery link'),
                  ),
                ],
              ),
            ),
    );
  }
}

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .updateRecoveredPassword(_passwordController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. You can sign in now.')),
      );
      await ref.read(authRepositoryProvider).signOut();
      if (mounted) context.go(AppRoutes.signIn);
    } on AccountAuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AccountFormScaffold(
      title: 'Choose a new password',
      icon: Icons.password_outlined,
      intro: 'Set a new password for your Kami account.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _passwordController,
              enabled: !_submitting,
              obscureText: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'New password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmationController,
              enabled: !_submitting,
              obscureText: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
              validator: (value) => value == _passwordController.text
                  ? null
                  : 'Passwords do not match.',
              onFieldSubmitted: (_) => _submitting ? null : _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _AccountError(message: _error!),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update password'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountFormScaffold extends StatelessWidget {
  const _AccountFormScaffold({
    required this.title,
    required this.icon,
    required this.intro,
    required this.child,
  });

  final String title;
  final IconData icon;
  final String intro;
  final Widget child;

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
                        icon,
                        size: 56,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        intro,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      child,
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

class _AccountError extends StatelessWidget {
  const _AccountError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(message, style: TextStyle(color: colors.onErrorContainer)),
      ),
    );
  }
}
