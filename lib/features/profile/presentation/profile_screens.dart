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
import 'package:kami/features/auth/data/device_account_link_store.dart';
import 'package:kami/features/auth/domain/auth_repository.dart';
import 'package:kami/features/auth/data/offline_workspace_link_service.dart';
import 'package:kami/features/auth/presentation/development_photo_consent_dialog.dart';
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

  Future<void> _linkThisDevice() async {
    final account = ref.read(currentAccountProvider);
    if (account == null) return;
    setState(() => _accountActionRunning = true);
    var linkAccepted = false;
    try {
      final service = ref.read(offlineWorkspaceLinkServiceProvider);
      final releaseReady = await service.retryPendingRelease(
        authenticated: true,
      );
      if (!releaseReady) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'A previous unlink is still waiting for cloud confirmation. '
                'Try again when you are online.',
              ),
            ),
          );
        }
        return;
      }
      final eligibility = await service.checkEligibility(account.id);
      // `localAlreadyLinked` is idempotent: the registry already belongs to
      // this account/workspace, so allow the claim/reconciliation path to
      // repair local state instead of treating it as a conflict. This can
      // happen after an interrupted link or a response lost after the RPC
      // committed remotely.
      final canContinue =
          eligibility == WorkspaceLinkEligibility.eligible ||
          eligibility == WorkspaceLinkEligibility.localAlreadyLinked;
      if (!canContinue) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                switch (eligibility) {
                  WorkspaceLinkEligibility.accountLinkedElsewhere =>
                    'This account is already linked to another device.',
                  WorkspaceLinkEligibility.workspaceLinked =>
                    'This offline workspace is already linked to another '
                        'account.',
                  WorkspaceLinkEligibility.pendingRelease =>
                    'A previous unlink is still waiting for cloud '
                        'confirmation. Try again when you are online.',
                  WorkspaceLinkEligibility.unavailable =>
                    'Chami could not verify the link with the cloud. Check '
                        'your connection and try again.',
                  WorkspaceLinkEligibility.eligible ||
                  WorkspaceLinkEligibility.localAlreadyLinked =>
                    'This device cannot be linked right now. Try again.',
                },
              ),
            ),
          );
        }
        return;
      }
      final result = await service.link(account.id);
      if (result != WorkspaceLinkResult.linked) {
        if (mounted) {
          final message = switch (result) {
            WorkspaceLinkResult.accountLinkedElsewhere =>
              'This account is already linked to another device.',
            WorkspaceLinkResult.workspaceLinked =>
              'This offline workspace is already linked to another account.',
            WorkspaceLinkResult.localAlreadyLinked =>
              'This account is already linked to this device.',
            WorkspaceLinkResult.unavailable =>
              'Chami could not verify the link with the cloud. Check your '
                  'connection and try again.',
            WorkspaceLinkResult.linked => 'This device is now linked.',
          };
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
        return;
      }
      await ref.read(deviceLinkedAccountIdProvider.notifier).link(account.id);
      linkAccepted = true;
      final local = ref.read(localSyncStoreProvider);
      final linkStore = ref.read(deviceAccountLinkStoreProvider);
      final workspaceId = await linkStore.readOrCreateWorkspaceId();
      final generation = await linkStore.readWorkspaceGeneration();
      final consent =
          await local.photoConsentForAccount(account.id) ??
          (mounted ? await requestDevelopmentPhotoConsent(context) : null);
      if (consent == null) {
        await service.release(authenticated: true);
        await ref
            .read(deviceLinkedAccountIdProvider.notifier)
            .clearIfMatches(account.id);
        return;
      }
      final reassociated = await local.reassociateDetachedGuestData(
        ownerId: account.id,
        workspaceId: workspaceId,
        generation: generation > 0 ? generation - 1 : generation,
        imageUploadConsent: consent,
      );
      if (!reassociated && await local.hasActiveGuestData()) {
        await local.claimGuestData(
          ownerId: account.id,
          imageUploadConsent: consent,
        );
      } else {
        await local.setImageUploadConsent(
          ownerId: account.id,
          consent: consent,
          authenticated: true,
        );
      }
      await local.saveOfflineWorkspaceState(
        workspaceId: workspaceId,
        installationId: await linkStore.readOrCreateInstallationId(),
        generation: generation,
        pendingRelease: false,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This device is now linked.')),
        );
      }
    } on Object {
      if (linkAccepted) {
        final service = ref.read(offlineWorkspaceLinkServiceProvider);
        await service.release(authenticated: true);
        await ref
            .read(deviceLinkedAccountIdProvider.notifier)
            .clearIfMatches(account.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              linkAccepted
                  ? 'The account link was rolled back because local data '
                        'could not be restored. Your Guest data was kept.'
                  : 'This device could not be linked. Try again when you are '
                        'online.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _accountActionRunning = false);
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
    final formKey = GlobalKey<FormState>();
    String? enteredName;
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit display name'),
        content: Form(
          key: formKey,
          child: TextFormField(
            initialValue: account.displayName ?? '',
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Display name'),
            onSaved: (value) => enteredName = value?.trim(),
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
              final form = formKey.currentState;
              if (form?.validate() ?? false) {
                form!.save();
                Navigator.of(dialogContext).pop(enteredName);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value == null || !mounted) return;
    setState(() => _accountActionRunning = true);
    try {
      await ref.read(authRepositoryProvider).updateDisplayName(value);
      ref.invalidate(currentAccountProvider);
    } on AccountAuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The display name could not be updated. Please try again.',
            ),
          ),
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
    var enteredPassword = '';
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm permanent deletion'),
        content: TextField(
          obscureText: true,
          autofocus: true,
          onChanged: (value) => enteredPassword = value,
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
            onPressed: () => Navigator.of(dialogContext).pop(enteredPassword),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    if (password == null || password.isEmpty || !mounted) return;
    setState(() => _accountActionRunning = true);
    try {
      await ref
          .read(accountSessionServiceProvider)
          .deleteAccount(password: password);
      if (!mounted) return;

      // Clear the local loading state before changing routes. The account
      // deletion also emits a signed-out auth event, which can dispose this
      // Profile route while go_router is moving to Account Choice. Updating
      // state from the old route after navigation causes the red Flutter
      // "setState after dispose" screen observed after successful deletion.
      setState(() => _accountActionRunning = false);
      context.go(AppRoutes.accountChoice);
    } on AccountSessionException catch (error) {
      if (mounted) {
        setState(() => _accountActionRunning = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on Object {
      if (mounted) {
        setState(() => _accountActionRunning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The account could not be deleted cleanly. Please restart Chami '
              'and check your connection before trying again.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _detachLinkedWorkspace() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keep offline data on this device?'),
        content: const Text(
          'Chami will unlink this device and keep your scans, batches, orders, '
          'and saved photos as local-only Guest data. The detached copy will '
          'not synchronize to the old account, and the cloud account itself '
          'will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Keep data and unlink'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final wasAuthenticated = ref.read(currentAccountProvider) != null;
    setState(() => _accountActionRunning = true);
    try {
      await ref.read(accountSessionServiceProvider).detachLinkedWorkspace();
      if (!mounted) return;
      setState(() => _accountActionRunning = false);
      if (wasAuthenticated) {
        context.go(AppRoutes.accountChoice);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offline data is now kept as local Guest data.'),
          ),
        );
      }
    } on AccountSessionException catch (error) {
      if (mounted) {
        setState(() => _accountActionRunning = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on Object {
      if (mounted) {
        setState(() => _accountActionRunning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Offline data could not be detached safely. Please try again.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final account = ref.watch(currentAccountProvider);
    final linkedOwnerId = ref.watch(deviceLinkedAccountIdProvider);
    if (account != null) {
      return _buildAccountProfile(
        context,
        accountId: account.id,
        accountEmail: account.email,
        accountDisplayName: account.displayName,
        colorScheme: colorScheme,
        themeMode: themeMode,
        isLinkedWorkspace: linkedOwnerId == account.id,
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
          _ProfileAppearanceSection(
            themeMode: themeMode,
            onChanged: _setDarkMode,
          ),
          if (linkedOwnerId != null) ...[
            const SizedBox(height: 24),
            Text(
              'Offline workspace',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: Icon(Icons.link_off, color: colorScheme.primary),
                title: const Text('Keep data on this device'),
                subtitle: const Text(
                  'Detach the linked workspace if you can no longer use that '
                  'account. Data stays local and is not deleted.',
                ),
                onTap: _accountActionRunning ? null : _detachLinkedWorkspace,
              ),
            ),
          ],
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
    required bool isLinkedWorkspace,
  }) {
    final status = ref.watch(syncStatusProvider);
    final settings = ref.watch(syncSettingsProvider).value;
    final effectiveLastSync =
        status.lastSuccessfulSyncAt ?? settings?.lastSuccessfulSyncAt;
    final syncLabel = switch (status.status) {
      SyncStatus.idle => 'Ready to synchronize',
      SyncStatus.syncing => 'Synchronizing…',
      SyncStatus.upToDate => 'Up to date',
      SyncStatus.failed =>
        status.failureCategory == SyncFailureCategory.record
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
              title: Row(
                children: [
                  Flexible(child: Text(accountDisplayName ?? 'Chami account')),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Edit display name',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    onPressed: _accountActionRunning ? null : _editDisplayName,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
              subtitle: Text(accountEmail),
            ),
          ),
          const SizedBox(height: 24),
          _ProfileAppearanceSection(
            themeMode: themeMode,
            onChanged: _setDarkMode,
          ),
          if (isLinkedWorkspace) ...[
            const SizedBox(height: 24),
            Text(
              'Offline workspace',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: Icon(Icons.link_off, color: colorScheme.primary),
                title: const Text('Unlink this device'),
                subtitle: const Text(
                  'Keep your offline data here as local-only Guest data.',
                ),
                onTap: _accountActionRunning ? null : _detachLinkedWorkspace,
              ),
            ),
          ],
          if (!isLinkedWorkspace &&
              ref.watch(deviceLinkedAccountIdProvider) == null) ...[
            const SizedBox(height: 24),
            Text(
              'Offline workspace',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: Icon(Icons.link_outlined, color: colorScheme.primary),
                title: const Text('Link this device'),
                subtitle: const Text(
                  'Keep local Guest data available when you sign out of this account.',
                ),
                onTap: _accountActionRunning ? null : _linkThisDevice,
              ),
            ),
          ],
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
                  value: settings?.imageUploadConsent ?? false,
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

class _ProfileAppearanceSection extends StatelessWidget {
  const _ProfileAppearanceSection({
    required this.themeMode,
    required this.onChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = themeMode == ThemeMode.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                color: colorScheme.primary,
              ),
            ),
            title: Text(isDark ? 'Dark mode' : 'Light mode'),
            subtitle: Text(
              isDark ? 'Dark colors are active' : 'Light colors are active',
            ),
            trailing: Switch(
              value: isDark,
              onChanged: onChanged,
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
      ],
    );
  }
}
