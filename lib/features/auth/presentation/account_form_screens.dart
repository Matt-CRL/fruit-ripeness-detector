import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kami/app/router/app_routes.dart';
import 'package:kami/core/layout/kami_responsive.dart';
import 'package:kami/features/account/application/account_session_service.dart';
import 'package:kami/features/auth/application/auth_providers.dart';
import 'package:kami/features/auth/data/device_account_link_store.dart';
import 'package:kami/features/auth/data/offline_workspace_link_service.dart';
import 'package:kami/features/auth/domain/auth_repository.dart';
import 'package:kami/features/auth/presentation/development_photo_consent_dialog.dart';
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
  var linkedAccountId = ref.read(deviceLinkedAccountIdProvider);
  var linkAccepted = linkedAccountId == user.id;
  var claimedThisSession = false;
  final linkStore = ref.read(deviceAccountLinkStoreProvider);
  final workspaceId = await linkStore.readOrCreateWorkspaceId();
  final installationId = await linkStore.readOrCreateInstallationId();
  final workspaceGeneration = await linkStore.readWorkspaceGeneration();
  await localSync.saveOfflineWorkspaceState(
    workspaceId: workspaceId,
    installationId: installationId,
    generation: workspaceGeneration,
    pendingRelease: await linkStore.hasPendingRelease(),
  );
  if (!context.mounted) return;

  final workspaceLink = ref.read(offlineWorkspaceLinkServiceProvider);
  if (linkedAccountId == null) {
    final releaseReady = await workspaceLink.retryPendingRelease(
      authenticated: true,
    );
    final eligibility = releaseReady
        ? await workspaceLink.checkEligibility(user.id)
        : WorkspaceLinkEligibility.pendingRelease;
    if (eligibility == WorkspaceLinkEligibility.eligible &&
        !await linkStore.hasAskedToLink(user.id)) {
      await linkStore.markAskedToLink(user.id);
      if (!context.mounted) return;
      final link = await _confirmOfflineWorkspaceLink(context, hasGuestData);
      if (link == true) {
        final result = await workspaceLink.link(user.id);
        if (result == WorkspaceLinkResult.linked) {
          await ref.read(deviceLinkedAccountIdProvider.notifier).link(user.id);
          linkedAccountId = user.id;
          linkAccepted = true;
          claimedThisSession = true;
          await localSync.saveOfflineWorkspaceState(
            workspaceId: workspaceId,
            installationId: installationId,
            generation: workspaceGeneration,
            pendingRelease: false,
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result == WorkspaceLinkResult.accountLinkedElsewhere
                    ? 'This account already keeps an offline workspace on '
                          'another device.'
                    : 'This device could not link the offline workspace. '
                          'You can try again from Profile.',
              ),
            ),
          );
        }
      }
    } else if (eligibility == WorkspaceLinkEligibility.accountLinkedElsewhere &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This account already keeps an offline workspace on another '
            'device. This session stays separate from local Guest data.',
          ),
        ),
      );
    }
  } else if (linkedAccountId == user.id) {
    // Legacy linked installations predate the global registry. Re-register
    // them the next time the owner authenticates, when Supabase is available.
    // A local_already_linked response is idempotent; an unavailable response
    // leaves the existing offline owner untouched for a later retry.
    final result = await workspaceLink.link(user.id);
    if (result == WorkspaceLinkResult.accountLinkedElsewhere) {
      // A legacy installation can discover that the account was registered by
      // another phone. Detach this phone's graph to Guest before continuing;
      // never claim or merge the other phone's workspace. The detach service
      // also clears the local owner and signs out this temporary session.
      var detached = false;
      try {
        await ref.read(accountSessionServiceProvider).detachLinkedWorkspace();
        detached = true;
      } on Object {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'This account is linked to another device. Detach the local '
                'workspace from Profile before trying again.',
              ),
            ),
          );
        }
      }
      if (detached && context.mounted) context.go(AppRoutes.accountChoice);
      return;
    }
  }

  final shouldClaim = linkAccepted;

  var photoConsent = await localSync.photoConsentForAccount(user.id);
  if (photoConsent == null) {
    if (!context.mounted) return;
    photoConsent = await requestDevelopmentPhotoConsent(context);
    if (photoConsent == null) {
      await ref.read(authRepositoryProvider).signOut(localOnly: true);
      if (context.mounted) context.go(AppRoutes.accountChoice);
      return;
    }
  }

  try {
    if (shouldClaim) {
      final reassociated = await localSync.reassociateDetachedGuestData(
        ownerId: user.id,
        workspaceId: workspaceId,
        generation: workspaceGeneration > 0
            ? workspaceGeneration - 1
            : workspaceGeneration,
        imageUploadConsent: photoConsent,
      );
      if (!reassociated && hasGuestData) {
        await localSync.claimGuestData(
          ownerId: user.id,
          imageUploadConsent: photoConsent,
        );
      }
    } else {
      await localSync.purgeGuestTombstones();
      await localSync.setImageUploadConsent(
        ownerId: user.id,
        consent: photoConsent,
        authenticated: true,
      );
    }
  } on Object {
    if (claimedThisSession) {
      await workspaceLink.release(authenticated: true);
      await ref
          .read(deviceLinkedAccountIdProvider.notifier)
          .clearIfMatches(user.id);
    }
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

  if (shouldClaim && hasGuestData && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Local guest data was added to this account.'),
      ),
    );
  }

  final completed = await ref
      .read(startupPreferencesProvider)
      .isAccountOnboardingCompleted(user.id);
  if (context.mounted) {
    context.go(completed ? AppRoutes.home : AppRoutes.onboarding);
  }
  unawaited(ref.read(syncCoordinatorProvider).syncNow(SyncTrigger.signIn));
}

Future<bool?> _confirmOfflineWorkspaceLink(
  BuildContext context,
  bool hasGuestData,
) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Keep local data with this account?'),
      content: Text(
        hasGuestData
            ? 'Kami found local scans, batches, or orders. Link this account '
                  'so they remain available when you sign out and return to '
                  'Guest mode.'
            : 'Link this account to the offline workspace on this device. '
                  'New local scans, batches, and orders will remain available '
                  'when you sign out and return to Guest mode.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Link account'),
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
  if (!_hasMinimumPasswordLength(password) ||
      !_hasLowercase(password) ||
      !_hasUppercase(password) ||
      !_hasNumber(password)) {
    return 'Password does not meet the requirements.';
  }
  return null;
}

bool _hasMinimumPasswordLength(String password) => password.length >= 8;

bool _hasLowercase(String password) => password.contains(RegExp('[a-z]'));

bool _hasUppercase(String password) => password.contains(RegExp('[A-Z]'));

bool _hasNumber(String password) => password.contains(RegExp('[0-9]'));

String? _validateDisplayName(String? value) {
  final name = value?.trim() ?? '';
  final length = name.runes.length;
  if (length < 2 || length > 50) {
    return 'Enter a display name from 2 to 50 characters.';
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
      leading: IconButton(
        tooltip: 'Back to account choice',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go(AppRoutes.accountChoice),
      ),
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
            SizedBox(
              height: KamiResponsive.value(context, regular: 16, compact: 12),
            ),
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
            SizedBox(
              height: KamiResponsive.value(context, regular: 20, compact: 16),
            ),
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
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _submitting = false;
  bool _obscurePassword = true;
  String _password = '';
  String? _error;

  @override
  void dispose() {
    _displayNameController.dispose();
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
            displayName: _displayNameController.text.trim(),
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
        if (!mounted) return;
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
              controller: _displayNameController,
              enabled: !_submitting,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.nickname],
              decoration: const InputDecoration(
                labelText: 'Display name',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: _validateDisplayName,
            ),
            SizedBox(
              height: KamiResponsive.value(context, regular: 16, compact: 12),
            ),
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
            SizedBox(
              height: KamiResponsive.value(context, regular: 16, compact: 12),
            ),
            TextFormField(
              controller: _passwordController,
              enabled: !_submitting,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (value) => setState(() => _password = value),
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
            const SizedBox(height: 10),
            _PasswordRequirements(password: _password),
            SizedBox(
              height: KamiResponsive.value(context, regular: 16, compact: 12),
            ),
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
            SizedBox(
              height: KamiResponsive.value(context, regular: 20, compact: 16),
            ),
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
                  SizedBox(
                    height: KamiResponsive.value(
                      context,
                      regular: 20,
                      compact: 16,
                    ),
                  ),
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
                helperText:
                    'Use 8+ characters with uppercase, lowercase, and a number.',
                helperMaxLines: 2,
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: _validatePassword,
            ),
            SizedBox(
              height: KamiResponsive.value(context, regular: 16, compact: 12),
            ),
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
            SizedBox(
              height: KamiResponsive.value(context, regular: 20, compact: 16),
            ),
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

class _PasswordRequirements extends StatelessWidget {
  const _PasswordRequirements({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final requirements = [
      ('At least 8 characters', _hasMinimumPasswordLength(password)),
      ('Contains uppercase letter', _hasUppercase(password)),
      ('Contains lowercase letter', _hasLowercase(password)),
      ('Contains number', _hasNumber(password)),
    ];
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password requirements',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        ...requirements.map(
          (requirement) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: [
                Icon(
                  requirement.$2
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  size: 16,
                  color: requirement.$2 ? colors.primary : colors.error,
                  semanticLabel: requirement.$2 ? 'Met' : 'Not met',
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    requirement.$1,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountFormScaffold extends StatelessWidget {
  const _AccountFormScaffold({
    required this.title,
    required this.icon,
    required this.intro,
    this.leading,
    required this.child,
  });

  final String title;
  final IconData icon;
  final String intro;
  final Widget? leading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final compact = KamiResponsive.isCompactPhone(context);
    return Scaffold(
      appBar: AppBar(title: Text(title), leading: leading),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(compact ? 12 : 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(compact ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        icon,
                        size: compact ? 40 : 56,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(height: compact ? 12 : 16),
                      Text(
                        intro,
                        textAlign: TextAlign.center,
                        style: compact
                            ? Theme.of(context).textTheme.bodyMedium
                            : Theme.of(context).textTheme.bodyLarge,
                      ),
                      SizedBox(height: compact ? 16 : 24),
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
