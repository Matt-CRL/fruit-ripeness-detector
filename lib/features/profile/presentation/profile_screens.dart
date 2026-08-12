import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kami/app/router/main_shell.dart';
import 'package:kami/app/router/app_routes.dart';
import 'package:kami/app/theme/theme_mode_controller.dart';
import 'package:kami/core/layout/kami_responsive.dart';
import 'package:kami/features/account/application/account_session_service.dart';
import 'package:kami/features/auth/application/auth_providers.dart';
import 'package:kami/features/auth/domain/auth_repository.dart';
import 'package:kami/features/startup/domain/startup_preferences.dart';
import 'package:kami/features/sync/application/sync_coordinator.dart';
import 'package:kami/features/sync/data/local_sync_store.dart';
import 'package:kami/features/sync/domain/sync_models.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isReturningToSignIn = false;
  bool _accountActionRunning = false;

  Future<void> _returnToSignIn() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Return to sign in?'),
          content: const Text(
            'You will leave guest mode and return to account options. If you '
            'continue as a guest again, onboarding will start from the first '
            'slide. Saved local data will not be deleted.',
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 64),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text(
                        'Stay as guest',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 64),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: const Text('Sign in', textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isReturningToSignIn = true);
    try {
      await ref.read(startupPreferencesProvider).resetGuestEntry();
      if (mounted) {
        context.go(AppRoutes.accountChoice);
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guest mode could not be closed. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isReturningToSignIn = false);
      }
    }
  }

  Future<void> _setDarkMode(bool enabled) async {
    final saved = await ref
        .read(themeModeProvider.notifier)
        .setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
    if (!saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appearance could not be saved. Please try again.'),
        ),
      );
    }
  }

  Future<void> _syncNow() async {
    setState(() => _accountActionRunning = true);
    final result = await ref
        .read(syncCoordinatorProvider)
        .syncNow(SyncTrigger.manualRetry);
    if (mounted) {
      setState(() => _accountActionRunning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.status == SyncStatus.failed &&
                    result.failureCategory == SyncFailureCategory.record
                ? 'Some saved items need attention. Other items were synchronized.'
                : result.status == SyncStatus.failed
                ? 'Sync could not finish. Check your connection and retry.'
                : result.conflicts > 0
                ? 'Sync finished. A newer cloud change replaced a stale local edit.'
                : 'Account data is up to date.',
          ),
        ),
      );
    }
  }

  Future<void> _setPhotoConsent(bool consent) async {
    final account = ref.read(currentAccountProvider);
    if (account == null) return;
    if (!consent) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Stop cloud photo backup?'),
          content: const Text(
            'Metadata will continue to synchronize. Uploaded History photos '
            'will be removed from cloud storage, while local copies stay on '
            'this device. Failed removals remain retryable.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Stop and remove photos'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() => _accountActionRunning = true);
    await ref
        .read(localSyncStoreProvider)
        .setImageUploadConsent(
          ownerId: account.id,
          consent: consent,
          authenticated: true,
        );
    await ref.read(syncCoordinatorProvider).syncNow(SyncTrigger.manualRetry);
    if (mounted) setState(() => _accountActionRunning = false);
  }

  Future<void> _editDisplayName() async {
    final account = ref.read(currentAccountProvider);
    if (account == null) return;
    final controller = TextEditingController(text: account.displayName ?? '');
    final formKey = GlobalKey<FormState>();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit display name'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Display name'),
            validator: (value) {
              final length = (value?.trim() ?? '').runes.length;
              return length < 2 || length > 50
                  ? 'Use 2 to 50 characters.'
                  : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(controller.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || !mounted) return;
    setState(() => _accountActionRunning = true);
    try {
      await ref.read(authRepositoryProvider).updateDisplayName(value);
      ref.invalidate(currentAccountProvider);
    } on AccountAuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _accountActionRunning = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _accountActionRunning = true);
    final result = await ref.read(accountSessionServiceProvider).signOut();
    if (!mounted) return;
    setState(() => _accountActionRunning = false);
    if (result == AccountSignOutResult.signedOut) {
      context.go(AppRoutes.accountChoice);
      return;
    }
    if (result == AccountSignOutResult.failed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign out could not be completed.')),
      );
      return;
    }
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unsynchronized changes remain'),
        content: const Text(
          'Ordinary sign-out is blocked so local account changes are not '
          'lost. Retry when online, or explicitly discard the unsynchronized '
          'changes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('discard'),
            child: const Text('Discard changes'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop('retry'),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
    if (action == 'retry') {
      await _signOut();
    } else if (action == 'discard' && mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Discard local changes?'),
          content: const Text(
            'This permanently removes unsynchronized account records and '
            'retained photos from this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Discard and sign out'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        setState(() => _accountActionRunning = true);
        final forced = await ref
            .read(accountSessionServiceProvider)
            .signOut(discardChanges: true);
        if (mounted) {
          setState(() => _accountActionRunning = false);
          if (forced == AccountSignOutResult.signedOut) {
            context.go(AppRoutes.accountChoice);
          }
        }
      }
    }
  }

  Future<void> _deleteAccount() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'Deletion is immediate and permanent. Your account and cloud data '
          'will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop('delete'),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (choice != 'delete' || !mounted) return;
    final passwordController = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm permanent deletion'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Current password',
            helperText: 'Reauthentication is required.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(passwordController.text),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    passwordController.dispose();
    if (password == null || password.isEmpty || !mounted) return;
    setState(() => _accountActionRunning = true);
    try {
      await ref
          .read(accountSessionServiceProvider)
          .deleteAccount(password: password);
      if (mounted) context.go(AppRoutes.accountChoice);
    } on AccountSessionException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _accountActionRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final account = ref.watch(currentAccountProvider);
    if (account != null) {
      return _buildAccountProfile(
        context,
        accountId: account.id,
        accountEmail: account.email,
        accountDisplayName: account.displayName,
        colorScheme: colorScheme,
        themeMode: themeMode,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: KamiResponsive.pagePadding(
          context,
          top: 8,
          bottom: 32 + mainNavigationContentBottomInset(context),
        ),
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.person_outline,
                      color: colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Guest mode',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text('Works locally without an account or internet.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  themeMode == ThemeMode.dark
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                  color: colorScheme.primary,
                ),
              ),
              title: Text(
                themeMode == ThemeMode.dark ? 'Dark mode' : 'Light mode',
              ),
              subtitle: Text(
                themeMode == ThemeMode.dark
                    ? 'Dark colors are active'
                    : 'Light colors are active',
              ),
              trailing: Switch(
                value: themeMode == ThemeMode.dark,
                onChanged: _setDarkMode,
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? colorScheme.onPrimary
                      : colorScheme.primary;
                }),
                trackColor: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest;
                }),
                trackOutlineColor: WidgetStatePropertyAll(colorScheme.outline),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Guest session', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'You can return to account options without deleting '
                    'local data.',
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _isReturningToSignIn ? null : _returnToSignIn,
                    icon: _isReturningToSignIn
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout),
                    label: const Text('Return to sign in'),
                  ),
                ],
              ),
            ),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 24),
            Text(
              'Developer preview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.rule_folder_outlined,
                    color: colorScheme.primary,
                  ),
                ),
                title: const Text('Shelf-life sample previews'),
                subtitle: const Text('View all nine saved-result examples'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.shelfLifePreview),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountProfile(
    BuildContext context, {
    required String accountId,
    required String accountEmail,
    required String? accountDisplayName,
    required ColorScheme colorScheme,
    required ThemeMode themeMode,
  }) {
    final status = ref.watch(syncStatusProvider);
    final settings = ref.watch(syncSettingsProvider).value;
    final effectiveLastSync =
        status.lastSuccessfulSyncAt ?? settings?.lastSuccessfulSyncAt;
    final syncLabel = switch (status.status) {
      SyncStatus.idle => 'Ready to synchronize',
      SyncStatus.syncing => 'Synchronizing…',
      SyncStatus.upToDate => 'Up to date',
      SyncStatus.failed => status.failureCategory == SyncFailureCategory.record
          ? 'Some saved items need attention'
          : 'Sync needs attention',
      SyncStatus.conflict => 'Up to date with a resolved conflict',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: KamiResponsive.pagePadding(
          context,
          top: 8,
          bottom: 32 + mainNavigationContentBottomInset(context),
        ),
        children: [
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(20),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(Icons.person_outline, color: colorScheme.primary),
              ),
              title: Text(accountDisplayName ?? 'Kami account'),
              subtitle: Text(accountEmail),
              trailing: IconButton(
                tooltip: 'Edit display name',
                onPressed: _accountActionRunning ? null : _editDisplayName,
                icon: const Icon(Icons.edit_outlined),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Synchronization',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      status.status == SyncStatus.failed
                          ? Icons.sync_problem_outlined
                          : Icons.cloud_done_outlined,
                    ),
                    title: Text(syncLabel),
                    subtitle: Text(
                      effectiveLastSync == null
                          ? 'No successful sync on this device yet'
                          : 'Last success: ${effectiveLastSync.toLocal()}',
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _accountActionRunning ? null : _syncNow,
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync now'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Privacy and data',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: settings?.consentAccountId == accountId
                      ? settings?.imageUploadConsent ?? false
                      : false,
                  onChanged: _accountActionRunning ? null : _setPhotoConsent,
                  secondary: const Icon(Icons.photo_outlined),
                  title: const Text('Cloud photo backup'),
                  subtitle: const Text(
                    'Metadata synchronizes even when this is off.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Card(
            child: SwitchListTile(
              value: themeMode == ThemeMode.dark,
              onChanged: _setDarkMode,
              secondary: Icon(
                themeMode == ThemeMode.dark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
              ),
              title: Text(
                themeMode == ThemeMode.dark ? 'Dark mode' : 'Light mode',
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Account', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign out'),
                  onTap: _accountActionRunning ? null : _signOut,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: colorScheme.error),
                  title: Text(
                    'Delete account',
                    style: TextStyle(color: colorScheme.error),
                  ),
                  onTap: _accountActionRunning ? null : _deleteAccount,
                ),
              ],
            ),
          ),
          if (_accountActionRunning) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
