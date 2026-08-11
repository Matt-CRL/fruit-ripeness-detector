import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/features/auth/application/auth_providers.dart';
import 'package:kami/features/auth/application/current_owner_provider.dart';
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
    ref.watch(currentOwnerIdProvider),
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
  );

  final AuthRepository _auth;
  final LocalSyncStore _local;
  final RetainedScanImageStore _images;
  final SyncCoordinator _sync;
  final String? _userId;

  Future<AccountSignOutResult> signOut({bool discardChanges = false}) async {
    final userId = _userId;
    if (userId == null) return AccountSignOutResult.failed;
    try {
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
}

final class AccountSessionException implements Exception {
  const AccountSessionException(this.message);

  final String message;
}
