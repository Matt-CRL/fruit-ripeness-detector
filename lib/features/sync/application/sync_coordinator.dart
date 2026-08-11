import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/core/persistence/image_sync_state.dart';
import 'package:kami/core/persistence/local_sync_state.dart';
import 'package:kami/core/supabase/supabase_client_provider.dart';
import 'package:kami/features/auth/application/current_owner_provider.dart';
import 'package:kami/features/history/data/app_private_retained_scan_image_store.dart';
import 'package:kami/features/history/domain/retained_scan_image_store.dart';
import 'package:kami/features/sync/data/local_sync_store.dart';
import 'package:kami/features/sync/data/supabase_sync_gateway.dart';
import 'package:kami/features/sync/domain/sync_gateway.dart';
import 'package:kami/features/sync/domain/sync_models.dart';

final syncStatusProvider =
    NotifierProvider<SyncStatusController, SyncStatusSnapshot>(
      SyncStatusController.new,
    );

final syncGatewayProvider = Provider<SyncGateway?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseSyncGateway(client);
});

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  return SyncCoordinator(
    ref.watch(syncGatewayProvider),
    () => ref.read(localSyncStoreProvider),
    () => ref.read(retainedScanImageStoreProvider),
    ref.watch(currentOwnerIdProvider),
    ref.read(syncStatusProvider.notifier),
  );
});

final syncSettingsProvider = StreamProvider<LocalSyncSettings>((ref) {
  return ref.watch(localSyncStoreProvider).watchSettings();
});

final localSyncPendingProvider = StreamProvider<bool>((ref) {
  final userId = ref.watch(currentOwnerIdProvider);
  if (userId == null) return Stream.value(false);
  return ref.watch(localSyncStoreProvider).watchHasPendingWork(userId);
});

final class SyncStatusController extends Notifier<SyncStatusSnapshot> {
  @override
  SyncStatusSnapshot build() => const SyncStatusSnapshot();

  void setSyncing() {
    state = state.copyWith(
      status: SyncStatus.syncing,
      clearErrorCode: true,
      conflictCount: 0,
    );
  }

  void setSuccess(DateTime at, int conflicts) {
    state = state.copyWith(
      status: conflicts == 0 ? SyncStatus.upToDate : SyncStatus.conflict,
      lastSuccessfulSyncAt: at,
      clearErrorCode: true,
      conflictCount: conflicts,
    );
  }

  void setFailure(String code) {
    state = state.copyWith(status: SyncStatus.failed, errorCode: code);
  }
}

final class SyncCoordinator {
  SyncCoordinator(
    this._gateway,
    this._localResolver,
    this._imageResolver,
    this._userId,
    this._status,
  );

  final SyncGateway? _gateway;
  final LocalSyncStore Function() _localResolver;
  final RetainedScanImageStore Function() _imageResolver;
  final String? _userId;
  final SyncStatusController _status;

  LocalSyncStore get _local => _localResolver();

  RetainedScanImageStore get _images => _imageResolver();

  Future<SyncRunResult>? _activeRun;

  Future<SyncRunResult> syncNow(SyncTrigger trigger) {
    final active = _activeRun;
    if (active != null) return active;
    final run = _run(trigger);
    _activeRun = run;
    return run.whenComplete(() {
      if (identical(_activeRun, run)) _activeRun = null;
    });
  }

  Future<SyncRunResult> _run(SyncTrigger trigger) async {
    final gateway = _gateway;
    final userId = _userId;
    if (gateway == null || userId == null) {
      return const SyncRunResult.notConfigured();
    }

    final startedAt = DateTime.now().toUtc();
    await _local.recordAttempt(startedAt);
    _status.setSyncing();
    var pushed = 0;
    var pulled = 0;
    var conflicts = 0;
    var recoverableFailures = 0;
    try {
      await _local.recoverInterrupted(userId);
      final anchor = await gateway.serverTimeAnchor();

      final settingsPush = await _pushTable(
        gateway,
        userId,
        SyncTable.userSettings,
      );
      pushed += settingsPush.accepted;
      conflicts += settingsPush.conflicts;

      final deletionOrder = [
        SyncTable.orders,
        SyncTable.scanRecords,
        SyncTable.batches,
      ];
      for (final table in deletionOrder) {
        final outcome = await _pushTable(
          gateway,
          userId,
          table,
          include: (record) => record.values['deleted_at'] != null,
        );
        pushed += outcome.accepted;
        conflicts += outcome.conflicts;
      }

      for (final table in [SyncTable.batches, SyncTable.scanRecords]) {
        final outcome = await _pushTable(
          gateway,
          userId,
          table,
          include: (record) => record.values['deleted_at'] == null,
        );
        pushed += outcome.accepted;
        conflicts += outcome.conflicts;
      }

      final pendingOrders = await _pushTable(
        gateway,
        userId,
        SyncTable.orders,
        include: (record) =>
            record.values['deleted_at'] == null &&
            record.values['status'] == 'pending',
      );
      pushed += pendingOrders.accepted;
      conflicts += pendingOrders.conflicts;
      final completedOrders = await _pushTable(
        gateway,
        userId,
        SyncTable.orders,
        include: (record) =>
            record.values['deleted_at'] == null &&
            record.values['status'] == 'completed',
      );
      pushed += completedOrders.accepted;
      conflicts += completedOrders.conflicts;

      final localSettings = await _local.readSettings();
      if (localSettings.imageUploadConsent == true) {
        final imageOutcome = await _uploadPendingImages(gateway, userId);
        pushed += imageOutcome.accepted;
        conflicts += imageOutcome.conflicts;
        recoverableFailures += imageOutcome.failures;
      } else if (localSettings.imageUploadConsent == false) {
        final revokeOutcome = await _removeRevokedImages(gateway, userId);
        pushed += revokeOutcome.accepted;
        conflicts += revokeOutcome.conflicts;
        recoverableFailures += revokeOutcome.failures;
      }

      final pullStart = (localSettings.syncCursorAt ?? DateTime.utc(1970))
          .subtract(const Duration(minutes: 10));
      for (final table in [
        SyncTable.userSettings,
        SyncTable.batches,
        SyncTable.scanRecords,
        SyncTable.orders,
      ]) {
        SyncCursor? cursor;
        var hasMore = true;
        while (hasMore) {
          final page = await gateway.pull(
            table: table,
            userId: userId,
            changedSince: pullStart,
            anchor: anchor,
            after: cursor,
          );
          for (final record in page.records) {
            final result = await _local.applyRemote(record);
            if (result == LocalApplyResult.replacedPendingConflict) conflicts++;
            if (result != LocalApplyResult.ignoredAsDuplicate) pulled++;
          }
          hasMore = page.hasMore;
          if (page.records.isNotEmpty) {
            final last = page.records.last;
            cursor = SyncCursor(
              serverChangedAt: last.serverChangedAt,
              id: last.id,
            );
          } else {
            hasMore = false;
          }
        }
      }

      final pulledSettings = await _local.readSettings();
      if (pulledSettings.imageUploadConsent == false) {
        final revokeOutcome = await _removeRevokedImages(gateway, userId);
        pushed += revokeOutcome.accepted;
        conflicts += revokeOutcome.conflicts;
        recoverableFailures += revokeOutcome.failures;
      }
      if (recoverableFailures > 0) {
        throw StateError('Retryable synchronization work remains.');
      }

      final completedAt = DateTime.now().toUtc();
      await _local.recordSuccess(at: completedAt, anchor: anchor);
      _status.setSuccess(completedAt, conflicts);
      return SyncRunResult(
        status: conflicts == 0 ? SyncStatus.upToDate : SyncStatus.conflict,
        pushed: pushed,
        pulled: pulled,
        conflicts: conflicts,
        completedAt: completedAt,
      );
    } on Object {
      const errorCode = 'sync_failed';
      final failedAt = DateTime.now().toUtc();
      await _local.recordFailure(at: failedAt, errorCode: errorCode);
      _status.setFailure(errorCode);
      return SyncRunResult(
        status: SyncStatus.failed,
        pushed: pushed,
        pulled: pulled,
        conflicts: conflicts,
        errorCode: errorCode,
      );
    }
  }

  Future<_PushOutcome> _pushTable(
    SyncGateway gateway,
    String userId,
    SyncTable table, {
    bool Function(RemoteSyncRecord record)? include,
  }) async {
    var accepted = 0;
    var conflicts = 0;
    final records = await _local.pendingRecords(table, userId);
    for (final record in records) {
      if (include != null && !include(record)) continue;
      final outcome = await _pushOne(gateway, record);
      accepted += outcome.accepted;
      conflicts += outcome.conflicts;
    }
    return _PushOutcome(accepted: accepted, conflicts: conflicts);
  }

  Future<_PushOutcome> _pushOne(
    SyncGateway gateway,
    RemoteSyncRecord record,
  ) async {
    await _local.markMetadataState(
      table: record.table,
      id: record.id,
      state: LocalSyncState.syncing,
    );
    try {
      final result = await gateway.push(
        record,
        expectedRevision: record.revision,
      );
      switch (result) {
        case PushConflict(:final remote):
          await _local.applyRemote(remote);
          if (record.table == SyncTable.scanRecords &&
              record.values['remote_image_key'] != null) {
            await _local.markImageState(
              scanId: record.id,
              state: ImageSyncState.failed,
            );
          }
          return const _PushOutcome(accepted: 0, conflicts: 1);
        case PushAccepted(record: final accepted):
          if (record.table == SyncTable.scanRecords &&
              record.values['deleted_at'] != null &&
              record.values['remote_image_key'] is String) {
            return _finishDeletedImage(gateway, record, accepted);
          }
          await _local.markMetadataState(
            table: record.table,
            id: record.id,
            state: LocalSyncState.synchronized,
            remoteRevision: accepted.revision,
          );
          if (record.table == SyncTable.scanRecords &&
              record.values['remote_image_key'] != null) {
            await _local.markImageState(
              scanId: record.id,
              state: ImageSyncState.synchronized,
            );
          }
          return const _PushOutcome(accepted: 1, conflicts: 0);
      }
    } on Object {
      await _local.markMetadataState(
        table: record.table,
        id: record.id,
        state: LocalSyncState.failed,
      );
      rethrow;
    }
  }

  Future<_PushOutcome> _finishDeletedImage(
    SyncGateway gateway,
    RemoteSyncRecord local,
    RemoteSyncRecord accepted,
  ) async {
    final key = local.values['remote_image_key']! as String;
    try {
      await gateway.deleteHistoryImages([key]);
      final cleared = RemoteSyncRecord(
        table: accepted.table,
        id: accepted.id,
        userId: accepted.userId,
        values: {...accepted.values, 'remote_image_key': null},
        revision: accepted.revision,
        serverChangedAt: accepted.serverChangedAt,
      );
      final clearResult = await gateway.push(
        cleared,
        expectedRevision: accepted.revision,
      );
      switch (clearResult) {
        case PushAccepted(record: final finalRecord):
          await _local.markImageState(
            scanId: local.id,
            state: ImageSyncState.localOnly,
            clearRemoteImageKey: true,
          );
          await _local.markMetadataState(
            table: local.table,
            id: local.id,
            state: LocalSyncState.synchronized,
            remoteRevision: finalRecord.revision,
          );
          return const _PushOutcome(accepted: 1, conflicts: 0);
        case PushConflict(:final remote):
          await _local.applyRemote(remote);
          return const _PushOutcome(accepted: 0, conflicts: 1);
      }
    } on Object {
      await _local.markMetadataState(
        table: local.table,
        id: local.id,
        state: LocalSyncState.failed,
        remoteRevision: accepted.revision,
      );
      await _local.markImageState(
        scanId: local.id,
        state: ImageSyncState.failed,
      );
      rethrow;
    }
  }

  Future<_PushOutcome> _uploadPendingImages(
    SyncGateway gateway,
    String userId,
  ) async {
    var accepted = 0;
    var conflicts = 0;
    var failures = 0;
    final scans = await _local.pendingImageUploads(userId);
    for (final scan in scans) {
      try {
        await _local.markImageState(
          scanId: scan.id,
          state: ImageSyncState.uploading,
        );
        final path = await _images.resolvePath(scan.localImageRelativePath!);
        final bytes = await File(path).readAsBytes();
        if (bytes.length > 5 * 1024 * 1024) {
          throw StateError('Retained image exceeds the cloud size limit.');
        }
        final objectKey = '$userId/${scan.id}/history.jpg';
        await gateway.uploadHistoryImage(
          objectKey: objectKey,
          jpegBytes: bytes,
        );
        await _local.markUploadedObject(scanId: scan.id, objectKey: objectKey);
        final pending = await _local.pendingRecords(
          SyncTable.scanRecords,
          userId,
        );
        final record = pending.firstWhere((item) => item.id == scan.id);
        final outcome = await _pushOne(gateway, record);
        accepted += outcome.accepted;
        conflicts += outcome.conflicts;
      } on Object {
        failures++;
        await _local.markImageState(
          scanId: scan.id,
          state: ImageSyncState.failed,
        );
      }
    }
    return _PushOutcome(
      accepted: accepted,
      conflicts: conflicts,
      failures: failures,
    );
  }

  Future<_PushOutcome> _removeRevokedImages(
    SyncGateway gateway,
    String userId,
  ) async {
    var accepted = 0;
    var conflicts = 0;
    var failures = 0;
    final scans = await _local.scansWithRemoteImages(userId);
    for (final scan in scans) {
      try {
        await gateway.deleteHistoryImages([scan.remoteImageKey!]);
        await _local.clearRemoteImageForSync(scan.id);
        final pending = await _local.pendingRecords(
          SyncTable.scanRecords,
          userId,
        );
        final record = pending.firstWhere((item) => item.id == scan.id);
        final outcome = await _pushOne(gateway, record);
        accepted += outcome.accepted;
        conflicts += outcome.conflicts;
      } on Object {
        failures++;
        await _local.markImageState(
          scanId: scan.id,
          state: ImageSyncState.failed,
        );
      }
    }
    return _PushOutcome(
      accepted: accepted,
      conflicts: conflicts,
      failures: failures,
    );
  }

  Future<String?> downloadRemoteImage(String scanId) async {
    final gateway = _gateway;
    final userId = _userId;
    if (gateway == null || userId == null) return null;
    final scan = await _local.scanById(scanId);
    if (scan == null ||
        scan.ownerId != userId ||
        scan.remoteImageKey == null ||
        scan.localImageRelativePath != null) {
      return scan?.localImageRelativePath;
    }
    try {
      final bytes = await gateway.downloadHistoryImage(scan.remoteImageKey!);
      final retained = await _images.storeDownloadedJpeg(
        bytes: bytes,
        scanId: scanId,
      );
      await _local.markDownloadedImage(
        scanId: scanId,
        relativePath: retained.relativePath,
      );
      return retained.relativePath;
    } on Object {
      await _local.markImageState(scanId: scanId, state: ImageSyncState.failed);
      return null;
    }
  }

  Future<void> deleteRemoteAccount() async {
    final gateway = _gateway;
    if (gateway == null || _userId == null) {
      throw StateError('Cloud account deletion is unavailable.');
    }
    await gateway.deleteAccount();
  }
}

final class _PushOutcome {
  const _PushOutcome({
    required this.accepted,
    required this.conflicts,
    this.failures = 0,
  });

  final int accepted;
  final int conflicts;
  final int failures;
}
