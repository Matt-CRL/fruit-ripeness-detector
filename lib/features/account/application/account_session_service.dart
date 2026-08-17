import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/core/persistence/entity_id_generator.dart';
import 'package:kami/features/auth/application/auth_providers.dart';
import 'package:kami/features/auth/application/current_owner_provider.dart';
import 'package:kami/features/auth/data/device_account_link_store.dart';
import 'package:kami/features/auth/data/offline_workspace_link_service.dart';
import 'package:kami/features/auth/domain/auth_repository.dart';
import 'package:kami/features/history/data/app_private_retained_scan_image_store.dart';
import 'package:kami/features/history/domain/retained_scan_image_store.dart';
import 'package:kami/features/sync/application/sync_coordinator.dart';
import 'package:kami/features/sync/data/local_sync_store.dart';
import 'package:kami/features/sync/domain/sync_models.dart';

final accountSessionServiceProvider = Provider<AccountSessionService>((ref) {
  return AccountSessionService(
    ref.watch(authRepositoryProvider),
    ref.watch(localSyncStoreProvider),
    ref.watch(retainedScanImageStoreProvider),
    ref.watch(syncCoordinatorProvider),
    ref.watch(authenticatedAccountIdProvider),
    ref.watch(deviceLinkedAccountIdProvider),
    ref.read(deviceLinkedAccountIdProvider.notifier),
    ref.watch(offlineWorkspaceLinkServiceProvider),
    ref.watch(deviceAccountLinkStoreProvider),
    const UuidEntityIdGenerator(),
  );
});

enum AccountSignOutResult { signedOut, blockedByUnsynchronizedChanges, failed }

final class AccountSessionService {
  const AccountSessionService(
    this._auth,
    this._local,
    this._images,
    this._sync,
    this._userId,
    this._linkedOwnerId,
    this._linkedOwnerController,
    this._workspaceLinkService,
    this._linkStore,
    this._idGenerator,
  );

  final AuthRepository _auth;
  final LocalSyncStore _local;
  final RetainedScanImageStore _images;
  final SyncCoordinator _sync;
  final String? _userId;
  final String? _linkedOwnerId;
  final DeviceLinkedAccountIdController _linkedOwnerController;
  final OfflineWorkspaceLinkService _workspaceLinkService;
  final DeviceAccountLinkStore _linkStore;
  final EntityIdGenerator _idGenerator;

  Future<AccountSignOutResult> signOut({bool discardChanges = false}) async {
    final userId = _userId;
    if (userId == null) return AccountSignOutResult.failed;
    try {
      final isPersistentWorkspace = _linkedOwnerId == userId;
      if (isPersistentWorkspace) {
        // Linked workspaces remain available in Guest mode. Sync is best
        // effort here because local rows and pending work are retained.
        try {
          await _sync.syncNow(SyncTrigger.manualRetry);
        } on Object {
          // Signing out must not strand a retained offline workspace when a
          // sync attempt fails before it can return a structured result.
        }
        await _auth.signOut(localOnly: true);
        return AccountSignOutResult.signedOut;
      }
      if (!discardChanges) {
        final sync = await _sync.syncNow(SyncTrigger.manualRetry);
        if (sync.status == SyncStatus.failed ||
            sync.status == SyncStatus.idle) {
          return AccountSignOutResult.blockedByUnsynchronizedChanges;
        }
        if (await _local.unsynchronizedCount(userId) > 0) {
          return AccountSignOutResult.blockedByUnsynchronizedChanges;
        }
      }
      await _removeLocalAccount(userId);
      await _auth.signOut(localOnly: true);
      return AccountSignOutResult.signedOut;
    } on Object {
      return AccountSignOutResult.failed;
    }
  }

  Future<void> deleteAccount({required String password}) async {
    final userId = _userId;
    if (userId == null) {
      throw const AccountSessionException('Sign in again before deleting.');
    }
    var remoteDeleted = false;
    try {
      await _auth.reauthenticate(password);
      await _sync.deleteRemoteAccount();
      remoteDeleted = true;
      await _removeLocalAccount(userId);
      await _linkedOwnerController.clearIfMatches(userId);
      await _auth.signOut(localOnly: true);
    } on AccountAuthException catch (error) {
      throw AccountSessionException(error.message);
    } on Object {
      throw AccountSessionException(
        remoteDeleted
            ? 'The cloud account was deleted, but device cleanup did not '
                  'finish. Restart Kami to clear the local session.'
            : 'Account deletion did not finish. Your account remains '
                  'available; check your connection and retry.',
      );
    }
  }

  /// Detaches the linked account's local graph into a fresh Guest workspace.
  ///
  /// This can be initiated while the linked account is signed in or from Guest
  /// mode when the account is no longer accessible. The detached records keep
  /// their user-visible content and local photos, but receive fresh IDs,
  /// unowned/local-only state, and no remote identifiers. The old linked graph
  /// is removed so a future sign-in cannot accidentally reclaim the detached
  /// copy.
  Future<void> detachLinkedWorkspace() async {
    final ownerId = _linkedOwnerId;
    if (ownerId == null) {
      throw const AccountSessionException(
        'There is no linked offline workspace to detach.',
      );
    }
    if (_userId != null && _userId != ownerId) {
      throw const AccountSessionException(
        'Sign out of this account before recovering another workspace.',
      );
    }

    final data = await _local.readAccountData(ownerId);
    final workspaceId = await _linkStore.readOrCreateWorkspaceId();
    final workspaceGeneration = await _linkStore.readWorkspaceGeneration();
    final activeBatches = data.batches.where((row) => row.deletedAt == null);
    final activeScans = data.scans.where((row) => row.deletedAt == null);
    final activeBatchIds = activeBatches.map((row) => row.id).toSet();
    final batchIdMap = <String, String>{
      for (final batch in activeBatches) batch.id: _idGenerator.nextId(),
    };
    final scanIdMap = <String, String>{
      for (final scan in activeScans) scan.id: _idGenerator.nextId(),
    };
    final orderIdMap = <String, String>{
      for (final order in data.orders.where(
        (row) => row.deletedAt == null && activeBatchIds.contains(row.batchId),
      ))
        order.id: _idGenerator.nextId(),
    };
    final copiedImagePaths = <String, String>{};
    final newImagePaths = <String>[];

    try {
      for (final scan in activeScans) {
        final oldPath = scan.localImageRelativePath;
        if (oldPath == null) continue;
        final newPath = await _images.copyToScan(
          sourceRelativePath: oldPath,
          scanId: scanIdMap[scan.id]!,
        );
        copiedImagePaths[scan.id] = newPath.relativePath;
        newImagePaths.add(newPath.relativePath);
      }
    } on Object catch (error) {
      await _removeImagesBestEffort(newImagePaths);
      throw AccountSessionException(
        'The offline workspace could not be copied safely: $error',
      );
    }

    late final List<String> oldImagePaths;
    try {
      oldImagePaths = await _local.detachAccountToGuest(
        ownerId: ownerId,
        batchIdMap: batchIdMap,
        scanIdMap: scanIdMap,
        orderIdMap: orderIdMap,
        imagePathByScanId: copiedImagePaths,
        workspaceId: workspaceId,
        workspaceGeneration: workspaceGeneration,
      );
    } on Object catch (error) {
      await _removeImagesBestEffort(newImagePaths);
      throw AccountSessionException(
        'The offline workspace could not be detached safely: $error',
      );
    }

    await _removeImagesBestEffort(oldImagePaths);
    await _workspaceLinkService.advanceWorkspaceGeneration();
    await _local.saveOfflineWorkspaceState(
      workspaceId: workspaceId,
      installationId: await _linkStore.readOrCreateInstallationId(),
      generation: workspaceGeneration + 1,
      pendingRelease: !(await _workspaceLinkService.release(
        authenticated: _userId == ownerId,
      )),
    );
    await _linkedOwnerController.clearIfMatches(ownerId);
    if (_userId != null) {
      await _auth.signOut(localOnly: true);
    }
  }

  Future<void> _removeLocalAccount(String userId) async {
    final paths = await _local.accountImagePaths(userId);
    for (final path in paths) {
      try {
        await _images.remove(path);
      } on Object {
        // Continue with account-row and session removal. An inaccessible
        // app-private orphan must not leave readable account data or tokens.
      }
    }
    await _local.purgeAccount(userId);
  }

  Future<void> _removeImagesBestEffort(Iterable<String> paths) async {
    for (final path in paths) {
      try {
        await _images.remove(path);
      } on Object {
        // A stale app-private file must not prevent the ownership transition.
      }
    }
  }
}

final class AccountSessionException implements Exception {
  const AccountSessionException(this.message);

  final String message;
}
