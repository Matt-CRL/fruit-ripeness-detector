import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/core/database/app_database.dart';
import 'package:kami/core/database/app_database_provider.dart';
import 'package:kami/core/persistence/image_sync_state.dart';
import 'package:kami/core/persistence/local_sync_state.dart';
import 'package:kami/core/persistence/persistence_codecs.dart';
import 'package:kami/features/auth/domain/offline_workspace_models.dart';
import 'package:kami/features/sync/domain/sync_models.dart';

const developmentConsentVersion = 'draft-development-v1';

final localSyncStoreProvider = Provider<LocalSyncStore>((ref) {
  return LocalSyncStore(ref.watch(appDatabaseProvider));
});

final class LocalSyncStore {
  const LocalSyncStore(this._database);

  Future<void> saveOfflineWorkspaceState({
    required String workspaceId,
    required String installationId,
    required int generation,
    required bool pendingRelease,
  }) async {
    await _database
        .into(_database.offlineWorkspaceStates)
        .insertOnConflictUpdate(
          OfflineWorkspaceStatesCompanion.insert(
            id: 'default',
            workspaceId: workspaceId,
            installationId: installationId,
            generation: Value(generation),
            pendingRelease: Value(pendingRelease),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  }

  Future<OfflineWorkspaceState?> readOfflineWorkspaceState() async {
    final row = await (_database.select(
      _database.offlineWorkspaceStates,
    )..where((row) => row.id.equals('default'))).getSingleOrNull();
    if (row == null) return null;
    return OfflineWorkspaceState(
      workspaceId: row.workspaceId,
      installationId: row.installationId,
      generation: row.generation,
      pendingRelease: row.pendingRelease,
      updatedAt: row.updatedAt,
    );
  }

  Future<List<DetachedEntityOrigin>> readDetachedEntityOrigins({
    required String workspaceId,
    required int generation,
    String? originalOwnerId,
  }) async {
    final rows = await (_database.select(
      _database.detachedEntityOrigins,
    )..where(
          (row) =>
              row.workspaceId.equals(workspaceId) &
              row.generation.equals(generation) &
              (originalOwnerId == null
                  ? const Constant(true)
                  : row.originalOwnerId.equals(originalOwnerId)),
        )).get();
    return [
      for (final row in rows)
        DetachedEntityOrigin(
          workspaceId: row.workspaceId,
          generation: row.generation,
          entityType: row.entityType,
          guestEntityId: row.guestEntityId,
          originalOwnerId: row.originalOwnerId,
          originalEntityId: row.originalEntityId,
          originalRemoteRevision: row.originalRemoteRevision,
          detachedAt: row.detachedAt,
        ),
    ];
  }

  final AppDatabase _database;

  Future<bool> hasActiveGuestData() async {
    final batch =
        await (_database.selectOnly(_database.batches)
              ..addColumns([_database.batches.id.count()])
              ..where(
                _database.batches.ownerId.isNull() &
                    _database.batches.deletedAt.isNull(),
              ))
            .getSingle();
    final scan =
        await (_database.selectOnly(_database.scanRecords)
              ..addColumns([_database.scanRecords.id.count()])
              ..where(
                _database.scanRecords.ownerId.isNull() &
                    _database.scanRecords.deletedAt.isNull(),
              ))
            .getSingle();
    final order =
        await (_database.selectOnly(_database.orders)
              ..addColumns([_database.orders.id.count()])
              ..where(
                _database.orders.ownerId.isNull() &
                    _database.orders.deletedAt.isNull(),
              ))
            .getSingle();
    return (batch.read(_database.batches.id.count()) ?? 0) > 0 ||
        (scan.read(_database.scanRecords.id.count()) ?? 0) > 0 ||
        (order.read(_database.orders.id.count()) ?? 0) > 0;
  }

  /// Claims all active guest data atomically.
  ///
  /// Guest tombstones have never reached a server, so retaining them would
  /// only upload meaningless deletions. They are purged before ownership is
  /// assigned to active rows.
  Future<void> claimGuestData({
    required String ownerId,
    required bool imageUploadConsent,
    String consentVersion = developmentConsentVersion,
  }) async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.orders,
      )..where((row) => row.ownerId.isNull() & row.deletedAt.isNotNull())).go();
      await (_database.delete(
        _database.scanRecords,
      )..where((row) => row.ownerId.isNull() & row.deletedAt.isNotNull())).go();
      await (_database.delete(
        _database.batches,
      )..where((row) => row.ownerId.isNull() & row.deletedAt.isNotNull())).go();

      final pending = PersistenceCodecs.encodeSyncState(LocalSyncState.pending);
      await (_database.update(
        _database.batches,
      )..where((row) => row.ownerId.isNull() & row.deletedAt.isNull())).write(
        BatchesCompanion(ownerId: Value(ownerId), syncState: Value(pending)),
      );
      await (_database.update(
        _database.scanRecords,
      )..where((row) => row.ownerId.isNull() & row.deletedAt.isNull())).write(
        ScanRecordsCompanion(
          ownerId: Value(ownerId),
          syncState: Value(pending),
          imageSyncState: Value(
            PersistenceCodecs.encodeImageSyncState(
              imageUploadConsent
                  ? ImageSyncState.pendingUpload
                  : ImageSyncState.localOnly,
            ),
          ),
        ),
      );
      await (_database.update(
        _database.orders,
      )..where((row) => row.ownerId.isNull() & row.deletedAt.isNull())).write(
        OrdersCompanion(ownerId: Value(ownerId), syncState: Value(pending)),
      );
      await _database
          .into(_database.accountSyncSettings)
          .insertOnConflictUpdate(
            AccountSyncSettingsCompanion.insert(
              ownerId: ownerId,
              imageUploadConsent: Value(imageUploadConsent),
              consentVersion: Value(consentVersion),
              syncState: Value(pending),
            ),
          );
    });
  }

  /// Reattaches detached rows to their original cloud identities when the
  /// former owner links the same workspace again. Rows created after detach
  /// remain new records and are claimed normally.
  Future<bool> reassociateDetachedGuestData({
    required String ownerId,
    required String workspaceId,
    required int generation,
    required bool imageUploadConsent,
    String consentVersion = developmentConsentVersion,
  }) async {
    final origins =
        await (_database.select(_database.detachedEntityOrigins)..where(
              (row) =>
                  row.workspaceId.equals(workspaceId) &
                  row.generation.equals(generation) &
                  row.originalOwnerId.equals(ownerId),
            ))
            .get();
    if (origins.isEmpty) return false;

    final batches = await (_database.select(
      _database.batches,
    )..where((row) => row.ownerId.isNull() & row.deletedAt.isNull())).get();
    final scans = await (_database.select(
      _database.scanRecords,
    )..where((row) => row.ownerId.isNull() & row.deletedAt.isNull())).get();
    final orders = await (_database.select(
      _database.orders,
    )..where((row) => row.ownerId.isNull() & row.deletedAt.isNull())).get();
    final originByGuestId = {
      for (final origin in origins) origin.guestEntityId: origin,
    };
    final batchIdMap = <String, String>{};
    final scanIdMap = <String, String>{};
    final orderIdMap = <String, String>{};
    for (final row in batches) {
      final origin = originByGuestId[row.id];
      if (origin?.entityType == 'batch') {
        batchIdMap[row.id] = origin!.originalEntityId;
      }
    }
    for (final row in scans) {
      final origin = originByGuestId[row.id];
      if (origin?.entityType == 'scan') {
        scanIdMap[row.id] = origin!.originalEntityId;
      }
    }
    for (final row in orders) {
      final origin = originByGuestId[row.id];
      if (origin?.entityType == 'order') {
        orderIdMap[row.id] = origin!.originalEntityId;
      }
    }

    final existingBatches = await (_database.select(
      _database.batches,
    )..where((row) => row.ownerId.equals(ownerId))).get();
    final existingScans = await (_database.select(
      _database.scanRecords,
    )..where((row) => row.ownerId.equals(ownerId))).get();
    final existingOrders = await (_database.select(
      _database.orders,
    )..where((row) => row.ownerId.equals(ownerId))).get();
    if (existingBatches.any((row) => batchIdMap.values.contains(row.id)) ||
        existingScans.any((row) => scanIdMap.values.contains(row.id)) ||
        existingOrders.any((row) => orderIdMap.values.contains(row.id))) {
      throw StateError(
        'The original account already has local records. Resolve the '
        'account session before re-linking this workspace.',
      );
    }

    final pending = PersistenceCodecs.encodeSyncState(LocalSyncState.pending);
    final imageState = PersistenceCodecs.encodeImageSyncState(
      imageUploadConsent
          ? ImageSyncState.pendingUpload
          : ImageSyncState.localOnly,
    );
    await _database.transaction(() async {
      for (final row in batches) {
        final newId = batchIdMap[row.id];
        if (newId == null) continue;
        final origin = originByGuestId[row.id]!;
        await _database
            .into(_database.batches)
            .insert(
              BatchesCompanion.insert(
                id: newId,
                ownerId: Value(ownerId),
                name: row.name,
                fruitType: row.fruitType,
                createdAt: row.createdAt,
                updatedAt: row.updatedAt,
                syncState: Value(pending),
                remoteRevision: Value(origin.originalRemoteRevision),
              ),
            );
      }
      for (final row in scans) {
        final newId = scanIdMap[row.id];
        if (newId == null) continue;
        final origin = originByGuestId[row.id]!;
        await _database
            .into(_database.scanRecords)
            .insert(
              ScanRecordsCompanion.insert(
                id: newId,
                ownerId: Value(ownerId),
                batchId: Value(
                  row.batchId == null ? null : batchIdMap[row.batchId!],
                ),
                fruitType: row.fruitType,
                ripenessStage: row.ripenessStage,
                modelConfidence: row.modelConfidence,
                modelVersion: row.modelVersion,
                resultOrigin: Value(row.resultOrigin),
                shelfLifeStatus: row.shelfLifeStatus,
                shelfLifeMinimum: Value(row.shelfLifeMinimum),
                shelfLifeMaximum: Value(row.shelfLifeMaximum),
                shelfLifeUnit: Value(row.shelfLifeUnit),
                shelfLifeGuidance: Value(row.shelfLifeGuidance),
                shelfLifeReason: Value(row.shelfLifeReason),
                shelfLifeEvidenceVersion: row.shelfLifeEvidenceVersion,
                localImageRelativePath: Value(row.localImageRelativePath),
                remoteImageKey: const Value<String?>(null),
                createdAt: row.createdAt,
                updatedAt: row.updatedAt,
                syncState: Value(pending),
                remoteRevision: Value(origin.originalRemoteRevision),
                imageSyncState: Value(imageState),
              ),
            );
      }
      for (final row in orders) {
        final newId = orderIdMap[row.id];
        if (newId == null) continue;
        final origin = originByGuestId[row.id]!;
        final newBatchId = batchIdMap[row.batchId];
        if (newBatchId == null) continue;
        await _database
            .into(_database.orders)
            .insert(
              OrdersCompanion.insert(
                id: newId,
                ownerId: Value(ownerId),
                batchId: newBatchId,
                customerName: row.customerName,
                deliveryAddress: row.deliveryAddress,
                deliveryDate: row.deliveryDate,
                status: row.status,
                createdAt: row.createdAt,
                updatedAt: row.updatedAt,
                syncState: Value(pending),
                remoteRevision: Value(origin.originalRemoteRevision),
              ),
            );
      }

      if (orderIdMap.isNotEmpty) {
        await (_database.delete(
          _database.orders,
        )..where((row) => row.id.isIn(orderIdMap.keys))).go();
      }
      if (scanIdMap.isNotEmpty) {
        await (_database.delete(
          _database.scanRecords,
        )..where((row) => row.id.isIn(scanIdMap.keys))).go();
      }
      if (batchIdMap.isNotEmpty) {
        await (_database.delete(
          _database.batches,
        )..where((row) => row.id.isIn(batchIdMap.keys))).go();
      }
      // Scans, batches, and orders created after the detach have no origin
      // mapping. Claim those rows as new records for the former owner.
      await (_database.update(
        _database.batches,
      )..where((row) => row.ownerId.isNull() & row.deletedAt.isNull())).write(
        BatchesCompanion(ownerId: Value(ownerId), syncState: Value(pending)),
      );
      await (_database.update(
        _database.scanRecords,
      )..where((row) => row.ownerId.isNull() & row.deletedAt.isNull())).write(
        ScanRecordsCompanion(
          ownerId: Value(ownerId),
          syncState: Value(pending),
          imageSyncState: Value(imageState),
        ),
      );
      await (_database.update(
        _database.orders,
      )..where((row) => row.ownerId.isNull() & row.deletedAt.isNull())).write(
        OrdersCompanion(ownerId: Value(ownerId), syncState: Value(pending)),
      );
      await (_database.delete(_database.detachedEntityOrigins)..where(
            (row) =>
                row.workspaceId.equals(workspaceId) &
                row.generation.equals(generation),
          ))
          .go();
      await _database
          .into(_database.accountSyncSettings)
          .insertOnConflictUpdate(
            AccountSyncSettingsCompanion.insert(
              ownerId: ownerId,
              imageUploadConsent: Value(imageUploadConsent),
              consentVersion: Value(consentVersion),
              syncState: Value(pending),
            ),
          );
    });
    return true;
  }

  Future<void> purgeGuestTombstones() async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.orders,
      )..where((row) => row.ownerId.isNull() & row.deletedAt.isNotNull())).go();
      await (_database.delete(
        _database.scanRecords,
      )..where((row) => row.ownerId.isNull() & row.deletedAt.isNotNull())).go();
      await (_database.delete(
        _database.batches,
      )..where((row) => row.ownerId.isNull() & row.deletedAt.isNotNull())).go();
    });
  }

  Future<void> recoverInterrupted(String ownerId) async {
    final syncing = PersistenceCodecs.encodeSyncState(LocalSyncState.syncing);
    final pending = PersistenceCodecs.encodeSyncState(LocalSyncState.pending);
    await _database.transaction(() async {
      await (_database.update(_database.batches)..where(
            (row) =>
                row.ownerId.equals(ownerId) & row.syncState.equals(syncing),
          ))
          .write(BatchesCompanion(syncState: Value(pending)));
      await (_database.update(_database.scanRecords)..where(
            (row) =>
                row.ownerId.equals(ownerId) & row.syncState.equals(syncing),
          ))
          .write(ScanRecordsCompanion(syncState: Value(pending)));
      await (_database.update(_database.orders)..where(
            (row) =>
                row.ownerId.equals(ownerId) & row.syncState.equals(syncing),
          ))
          .write(OrdersCompanion(syncState: Value(pending)));
      await (_database.update(_database.scanRecords)..where(
            (row) =>
                row.ownerId.equals(ownerId) &
                row.imageSyncState.equals(
                  PersistenceCodecs.encodeImageSyncState(
                    ImageSyncState.uploading,
                  ),
                ),
          ))
          .write(
            ScanRecordsCompanion(
              imageSyncState: Value(
                PersistenceCodecs.encodeImageSyncState(
                  ImageSyncState.pendingUpload,
                ),
              ),
            ),
          );
      await (_database.update(_database.accountSyncSettings)..where(
            (row) =>
                row.ownerId.equals(ownerId) & row.syncState.equals(syncing),
          ))
          .write(AccountSyncSettingsCompanion(syncState: Value(pending)));
    });
  }

  Future<LocalSyncSettings> readSettings(String ownerId) async {
    final row = await (_database.select(
      _database.accountSyncSettings,
    )..where((row) => row.ownerId.equals(ownerId))).getSingleOrNull();
    if (row == null) {
      return const LocalSyncSettings();
    }
    return _settingsFromRow(row);
  }

  /// A consent decision only applies to the account that made it on this
  /// device. A stale decision from another account must not enable uploads.
  Future<bool?> photoConsentForAccount(String ownerId) async {
    return (await readSettings(ownerId)).imageUploadConsent;
  }

  Stream<LocalSyncSettings> watchSettings(String ownerId) {
    final query = _database.select(_database.accountSyncSettings)
      ..where((row) => row.ownerId.equals(ownerId));
    return query.watchSingleOrNull().map(
      (row) => row == null ? const LocalSyncSettings() : _settingsFromRow(row),
    );
  }

  Stream<bool> watchHasPendingWork(String ownerId) {
    return _database
        .customSelect(
          '''
          SELECT EXISTS (
            SELECT 1 FROM batches
            WHERE owner_id = ? AND sync_state IN ('pending', 'failed')
            UNION ALL
            SELECT 1 FROM scan_records
            WHERE owner_id = ? AND (
              sync_state IN ('pending', 'failed')
              OR image_sync_state IN ('pending_upload', 'failed')
            )
            UNION ALL
            SELECT 1 FROM orders
            WHERE owner_id = ? AND sync_state IN ('pending', 'failed')
            UNION ALL
            SELECT 1 FROM account_sync_settings
            WHERE owner_id = ? AND sync_state IN ('pending', 'failed')
          ) AS has_pending
          ''',
          variables: [
            Variable<String>(ownerId),
            Variable<String>(ownerId),
            Variable<String>(ownerId),
            Variable<String>(ownerId),
          ],
          readsFrom: {
            _database.batches,
            _database.scanRecords,
            _database.orders,
            _database.accountSyncSettings,
          },
        )
        .watchSingle()
        .map((row) => row.read<int>('has_pending') == 1)
        .distinct();
  }

  Future<void> setImageUploadConsent({
    required String ownerId,
    required bool consent,
    required bool authenticated,
    String consentVersion = developmentConsentVersion,
  }) async {
    final state = authenticated
        ? LocalSyncState.pending
        : LocalSyncState.localOnly;
    await _database.transaction(() async {
      await _database
          .into(_database.accountSyncSettings)
          .insertOnConflictUpdate(
            AccountSyncSettingsCompanion.insert(
              ownerId: ownerId,
              imageUploadConsent: Value(consent),
              consentVersion: Value(consentVersion),
              syncState: Value(PersistenceCodecs.encodeSyncState(state)),
            ),
          );
      if (authenticated && consent) {
        await (_database.update(_database.scanRecords)..where(
              (row) =>
                  row.ownerId.equals(ownerId) &
                  row.deletedAt.isNull() &
                  row.localImageRelativePath.isNotNull() &
                  row.remoteImageKey.isNull(),
            ))
            .write(
              ScanRecordsCompanion(
                imageSyncState: Value(
                  PersistenceCodecs.encodeImageSyncState(
                    ImageSyncState.pendingUpload,
                  ),
                ),
              ),
            );
      }
    });
  }

  Future<List<RemoteSyncRecord>> pendingRecords(
    SyncTable table,
    String userId,
  ) async {
    final retryable = [
      PersistenceCodecs.encodeSyncState(LocalSyncState.pending),
      PersistenceCodecs.encodeSyncState(LocalSyncState.failed),
    ];
    switch (table) {
      case SyncTable.batches:
        final rows =
            await (_database.select(_database.batches)
                  ..where(
                    (row) =>
                        row.ownerId.equals(userId) &
                        row.syncState.isIn(retryable),
                  )
                  ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
                .get();
        return rows.map(_batchToRemote).toList(growable: false);
      case SyncTable.scanRecords:
        final rows =
            await (_database.select(_database.scanRecords)
                  ..where(
                    (row) =>
                        row.ownerId.equals(userId) &
                        row.syncState.isIn(retryable),
                  )
                  ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
                .get();
        return rows.map(_scanToRemote).toList(growable: false);
      case SyncTable.orders:
        final rows =
            await (_database.select(_database.orders)
                  ..where(
                    (row) =>
                        row.ownerId.equals(userId) &
                        row.syncState.isIn(retryable),
                  )
                  ..orderBy([
                    (row) => OrderingTerm.asc(row.status),
                    (row) => OrderingTerm.asc(row.createdAt),
                  ]))
                .get();
        return rows.map(_orderToRemote).toList(growable: false);
      case SyncTable.userSettings:
        final settings = await readSettings(userId);
        if (settings.imageUploadConsent == null ||
            !retryable.contains(
              PersistenceCodecs.encodeSyncState(settings.syncState),
            )) {
          return const [];
        }
        final now = DateTime.now().toUtc();
        return [
          RemoteSyncRecord(
            table: SyncTable.userSettings,
            id: userId,
            userId: userId,
            values: {
              'image_upload_consent': settings.imageUploadConsent,
              'consent_version': settings.consentVersion,
              'created_at': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
              'deleted_at': null,
            },
            revision: settings.remoteRevision,
            serverChangedAt: now,
          ),
        ];
    }
  }

  Future<void> markMetadataState({
    required SyncTable table,
    required String id,
    required LocalSyncState state,
    int? remoteRevision,
  }) async {
    final encoded = PersistenceCodecs.encodeSyncState(state);
    switch (table) {
      case SyncTable.batches:
        await (_database.update(
          _database.batches,
        )..where((row) => row.id.equals(id))).write(
          BatchesCompanion(
            syncState: Value(encoded),
            remoteRevision: remoteRevision == null
                ? const Value.absent()
                : Value(remoteRevision),
          ),
        );
      case SyncTable.scanRecords:
        await (_database.update(
          _database.scanRecords,
        )..where((row) => row.id.equals(id))).write(
          ScanRecordsCompanion(
            syncState: Value(encoded),
            remoteRevision: remoteRevision == null
                ? const Value.absent()
                : Value(remoteRevision),
          ),
        );
      case SyncTable.orders:
        await (_database.update(
          _database.orders,
        )..where((row) => row.id.equals(id))).write(
          OrdersCompanion(
            syncState: Value(encoded),
            remoteRevision: remoteRevision == null
                ? const Value.absent()
                : Value(remoteRevision),
          ),
        );
      case SyncTable.userSettings:
        await (_database.update(
          _database.accountSyncSettings,
        )..where((row) => row.ownerId.equals(id))).write(
          AccountSyncSettingsCompanion(
            syncState: Value(encoded),
            remoteRevision: remoteRevision == null
                ? const Value.absent()
                : Value(remoteRevision),
          ),
        );
    }
  }

  Future<LocalApplyResult> applyRemote(RemoteSyncRecord remote) async {
    return _database.transaction(() async {
      switch (remote.table) {
        case SyncTable.batches:
          final existing = await (_database.select(
            _database.batches,
          )..where((row) => row.id.equals(remote.id))).getSingleOrNull();
          final result = _applyResult(
            existing?.remoteRevision,
            existing?.syncState,
            remote.revision,
          );
          if (result == LocalApplyResult.ignoredAsDuplicate) return result;
          await _database
              .into(_database.batches)
              .insertOnConflictUpdate(
                BatchesCompanion.insert(
                  id: remote.id,
                  ownerId: Value(remote.userId),
                  name: _requiredString(remote.values, 'name'),
                  fruitType: _requiredString(remote.values, 'fruit_type'),
                  createdAt: _requiredDate(remote.values, 'created_at'),
                  updatedAt: _requiredDate(remote.values, 'updated_at'),
                  deletedAt: Value(_optionalDate(remote.values, 'deleted_at')),
                  syncState: Value(
                    PersistenceCodecs.encodeSyncState(
                      LocalSyncState.synchronized,
                    ),
                  ),
                  remoteRevision: Value(remote.revision),
                ),
              );
          return result;
        case SyncTable.scanRecords:
          final existing = await (_database.select(
            _database.scanRecords,
          )..where((row) => row.id.equals(remote.id))).getSingleOrNull();
          final result = _applyResult(
            existing?.remoteRevision,
            existing?.syncState,
            remote.revision,
          );
          if (result == LocalApplyResult.ignoredAsDuplicate) return result;
          final remoteImageKey = _optionalString(
            remote.values,
            'remote_image_key',
          );
          final localPath = existing?.localImageRelativePath;
          final imageState = remoteImageKey == null
              ? existing?.imageSyncState ??
                    PersistenceCodecs.encodeImageSyncState(
                      ImageSyncState.localOnly,
                    )
              : PersistenceCodecs.encodeImageSyncState(
                  localPath == null
                      ? ImageSyncState.remoteOnly
                      : ImageSyncState.synchronized,
                );
          await _database
              .into(_database.scanRecords)
              .insertOnConflictUpdate(
                ScanRecordsCompanion.insert(
                  id: remote.id,
                  ownerId: Value(remote.userId),
                  batchId: Value(_optionalString(remote.values, 'batch_id')),
                  fruitType: _requiredString(remote.values, 'fruit_type'),
                  ripenessStage: _requiredString(
                    remote.values,
                    'ripeness_stage',
                  ),
                  modelConfidence: _requiredDouble(
                    remote.values,
                    'model_confidence',
                  ),
                  modelVersion: _requiredString(remote.values, 'model_version'),
                  resultOrigin: Value(
                    _requiredString(remote.values, 'result_origin'),
                  ),
                  shelfLifeStatus: _requiredString(
                    remote.values,
                    'shelf_life_status',
                  ),
                  shelfLifeMinimum: Value(
                    _optionalInt(remote.values, 'shelf_life_minimum'),
                  ),
                  shelfLifeMaximum: Value(
                    _optionalInt(remote.values, 'shelf_life_maximum'),
                  ),
                  shelfLifeUnit: Value(
                    _optionalString(remote.values, 'shelf_life_unit'),
                  ),
                  shelfLifeGuidance: Value(
                    _optionalString(remote.values, 'shelf_life_guidance'),
                  ),
                  shelfLifeReason: Value(
                    _optionalString(remote.values, 'shelf_life_reason'),
                  ),
                  shelfLifeEvidenceVersion: _requiredString(
                    remote.values,
                    'shelf_life_evidence_version',
                  ),
                  localImageRelativePath: Value(localPath),
                  remoteImageKey: Value(remoteImageKey),
                  createdAt: _requiredDate(remote.values, 'created_at'),
                  updatedAt: _requiredDate(remote.values, 'updated_at'),
                  deletedAt: Value(_optionalDate(remote.values, 'deleted_at')),
                  syncState: Value(
                    PersistenceCodecs.encodeSyncState(
                      LocalSyncState.synchronized,
                    ),
                  ),
                  remoteRevision: Value(remote.revision),
                  imageSyncState: Value(imageState),
                ),
              );
          return result;
        case SyncTable.orders:
          final existing = await (_database.select(
            _database.orders,
          )..where((row) => row.id.equals(remote.id))).getSingleOrNull();
          final result = _applyResult(
            existing?.remoteRevision,
            existing?.syncState,
            remote.revision,
          );
          if (result == LocalApplyResult.ignoredAsDuplicate) return result;
          await _database
              .into(_database.orders)
              .insertOnConflictUpdate(
                OrdersCompanion.insert(
                  id: remote.id,
                  ownerId: Value(remote.userId),
                  batchId: _requiredString(remote.values, 'batch_id'),
                  customerName: _requiredString(remote.values, 'customer_name'),
                  deliveryAddress: _requiredString(
                    remote.values,
                    'delivery_address',
                  ),
                  deliveryDate: _requiredDate(remote.values, 'delivery_date'),
                  status: _requiredString(remote.values, 'status'),
                  createdAt: _requiredDate(remote.values, 'created_at'),
                  updatedAt: _requiredDate(remote.values, 'updated_at'),
                  deletedAt: Value(_optionalDate(remote.values, 'deleted_at')),
                  syncState: Value(
                    PersistenceCodecs.encodeSyncState(
                      LocalSyncState.synchronized,
                    ),
                  ),
                  remoteRevision: Value(remote.revision),
                ),
              );
          return result;
        case SyncTable.userSettings:
          final settings = await readSettings(remote.userId);
          final result = _applyResult(
            settings.remoteRevision,
            PersistenceCodecs.encodeSyncState(settings.syncState),
            remote.revision,
          );
          if (result == LocalApplyResult.ignoredAsDuplicate) return result;
          await _database
              .into(_database.accountSyncSettings)
              .insertOnConflictUpdate(
                AccountSyncSettingsCompanion.insert(
                  ownerId: remote.userId,
                  imageUploadConsent: Value(
                    _requiredBool(remote.values, 'image_upload_consent'),
                  ),
                  consentVersion: Value(
                    _requiredString(remote.values, 'consent_version'),
                  ),
                  syncState: Value(
                    PersistenceCodecs.encodeSyncState(
                      LocalSyncState.synchronized,
                    ),
                  ),
                  remoteRevision: Value(remote.revision),
                ),
              );
          return result;
      }
    });
  }

  Future<List<ScanRecordRow>> pendingImageUploads(String userId) async {
    final states = [
      ImageSyncState.pendingUpload,
      ImageSyncState.failed,
    ].map(PersistenceCodecs.encodeImageSyncState).toList(growable: false);
    return (_database.select(_database.scanRecords)..where(
          (row) =>
              row.ownerId.equals(userId) &
              row.deletedAt.isNull() &
              row.localImageRelativePath.isNotNull() &
              row.imageSyncState.isIn(states),
        ))
        .get();
  }

  Future<void> markImageState({
    required String scanId,
    required ImageSyncState state,
    String? remoteImageKey,
    bool clearRemoteImageKey = false,
  }) async {
    await (_database.update(
      _database.scanRecords,
    )..where((row) => row.id.equals(scanId))).write(
      ScanRecordsCompanion(
        imageSyncState: Value(PersistenceCodecs.encodeImageSyncState(state)),
        remoteImageKey: clearRemoteImageKey
            ? const Value(null)
            : remoteImageKey == null
            ? const Value.absent()
            : Value(remoteImageKey),
      ),
    );
  }

  Future<void> markUploadedObject({
    required String scanId,
    required String objectKey,
  }) async {
    await (_database.update(
      _database.scanRecords,
    )..where((row) => row.id.equals(scanId))).write(
      ScanRecordsCompanion(
        remoteImageKey: Value(objectKey),
        imageSyncState: Value(
          PersistenceCodecs.encodeImageSyncState(ImageSyncState.uploading),
        ),
        syncState: Value(
          PersistenceCodecs.encodeSyncState(LocalSyncState.pending),
        ),
      ),
    );
  }

  Future<void> markDownloadedImage({
    required String scanId,
    required String relativePath,
  }) async {
    await (_database.update(
      _database.scanRecords,
    )..where((row) => row.id.equals(scanId))).write(
      ScanRecordsCompanion(
        localImageRelativePath: Value(relativePath),
        imageSyncState: Value(
          PersistenceCodecs.encodeImageSyncState(ImageSyncState.synchronized),
        ),
      ),
    );
  }

  Future<List<ScanRecordRow>> scansWithRemoteImages(String userId) {
    return (_database.select(_database.scanRecords)..where(
          (row) => row.ownerId.equals(userId) & row.remoteImageKey.isNotNull(),
        ))
        .get();
  }

  Future<List<ScanRecordRow>> remoteOnlyScans(String userId) {
    return (_database.select(_database.scanRecords)..where(
          (row) =>
              row.ownerId.equals(userId) &
              row.deletedAt.isNull() &
              row.remoteImageKey.isNotNull() &
              row.localImageRelativePath.isNull(),
        ))
        .get();
  }

  Future<ScanRecordRow?> scanById(String scanId) {
    return (_database.select(
      _database.scanRecords,
    )..where((row) => row.id.equals(scanId))).getSingleOrNull();
  }

  Future<void> clearRemoteImageForSync(String scanId) async {
    await (_database.update(
      _database.scanRecords,
    )..where((row) => row.id.equals(scanId))).write(
      ScanRecordsCompanion(
        remoteImageKey: const Value(null),
        imageSyncState: Value(
          PersistenceCodecs.encodeImageSyncState(ImageSyncState.localOnly),
        ),
        syncState: Value(
          PersistenceCodecs.encodeSyncState(LocalSyncState.pending),
        ),
      ),
    );
  }

  Future<void> recordAttempt(String ownerId, DateTime at) async {
    await _database
        .into(_database.accountSyncSettings)
        .insertOnConflictUpdate(
          AccountSyncSettingsCompanion.insert(
            ownerId: ownerId,
            lastSyncAttemptAt: Value(at.toUtc()),
          ),
        );
  }

  Future<void> recordSuccess({
    required String ownerId,
    required DateTime at,
    required DateTime anchor,
  }) async {
    await _database
        .into(_database.accountSyncSettings)
        .insertOnConflictUpdate(
          AccountSyncSettingsCompanion.insert(
            ownerId: ownerId,
            lastSuccessfulSyncAt: Value(at.toUtc()),
            lastSyncAttemptAt: Value(at.toUtc()),
            syncCursorAt: Value(anchor.toUtc()),
            lastSyncErrorCode: const Value(null),
          ),
        );
  }

  Future<void> recordFailure({
    required String ownerId,
    required DateTime at,
    required String errorCode,
  }) async {
    await _database
        .into(_database.accountSyncSettings)
        .insertOnConflictUpdate(
          AccountSyncSettingsCompanion.insert(
            ownerId: ownerId,
            lastSyncAttemptAt: Value(at.toUtc()),
            lastSyncErrorCode: Value(errorCode),
          ),
        );
  }

  Future<int> unsynchronizedCount(String ownerId) async {
    final synchronized = PersistenceCodecs.encodeSyncState(
      LocalSyncState.synchronized,
    );
    final batchCount =
        await (_database.selectOnly(_database.batches)
              ..addColumns([_database.batches.id.count()])
              ..where(
                _database.batches.ownerId.equals(ownerId) &
                    _database.batches.syncState.equals(synchronized).not(),
              ))
            .getSingle();
    final scanCount =
        await (_database.selectOnly(_database.scanRecords)
              ..addColumns([_database.scanRecords.id.count()])
              ..where(
                _database.scanRecords.ownerId.equals(ownerId) &
                    _database.scanRecords.syncState.equals(synchronized).not(),
              ))
            .getSingle();
    final orderCount =
        await (_database.selectOnly(_database.orders)
              ..addColumns([_database.orders.id.count()])
              ..where(
                _database.orders.ownerId.equals(ownerId) &
                    _database.orders.syncState.equals(synchronized).not(),
              ))
            .getSingle();
    final imageCount =
        await (_database.selectOnly(_database.scanRecords)
              ..addColumns([_database.scanRecords.id.count()])
              ..where(
                _database.scanRecords.ownerId.equals(ownerId) &
                    _database.scanRecords.imageSyncState
                        .equals(
                          PersistenceCodecs.encodeImageSyncState(
                            ImageSyncState.synchronized,
                          ),
                        )
                        .not() &
                    _database.scanRecords.imageSyncState
                        .equals(
                          PersistenceCodecs.encodeImageSyncState(
                            ImageSyncState.localOnly,
                          ),
                        )
                        .not(),
              ))
            .getSingle();
    final settings = await readSettings(ownerId);
    final settingsCount =
        settings.syncState == LocalSyncState.pending ||
            settings.syncState == LocalSyncState.syncing ||
            settings.syncState == LocalSyncState.failed
        ? 1
        : 0;
    return ((batchCount.read(_database.batches.id.count()) ?? 0) +
            (scanCount.read(_database.scanRecords.id.count()) ?? 0) +
            (orderCount.read(_database.orders.id.count()) ?? 0) +
            (imageCount.read(_database.scanRecords.id.count()) ?? 0) +
            settingsCount)
        .toInt();
  }

  Future<LocalAccountData> readAccountData(String ownerId) async {
    final batches = await (_database.select(
      _database.batches,
    )..where((row) => row.ownerId.equals(ownerId))).get();
    final scans = await (_database.select(
      _database.scanRecords,
    )..where((row) => row.ownerId.equals(ownerId))).get();
    final orders = await (_database.select(
      _database.orders,
    )..where((row) => row.ownerId.equals(ownerId))).get();
    return LocalAccountData(
      batches: batches,
      scans: scans,
      orders: orders,
      settings: await readSettings(ownerId),
    );
  }

  Future<List<String>> accountImagePaths(String ownerId) async {
    final rows =
        await (_database.selectOnly(_database.scanRecords)
              ..addColumns([_database.scanRecords.localImageRelativePath])
              ..where(
                _database.scanRecords.ownerId.equals(ownerId) &
                    _database.scanRecords.localImageRelativePath.isNotNull(),
              ))
            .get();
    return rows
        .map((row) => row.read(_database.scanRecords.localImageRelativePath))
        .whereType<String>()
        .toList(growable: false);
  }

  Future<List<String>> purgeAccount(String ownerId) async {
    return _database.transaction(() async {
      final scans = await (_database.select(
        _database.scanRecords,
      )..where((row) => row.ownerId.equals(ownerId))).get();
      final imagePaths = scans
          .map((row) => row.localImageRelativePath)
          .whereType<String>()
          .toList(growable: false);
      await (_database.delete(
        _database.orders,
      )..where((row) => row.ownerId.equals(ownerId))).go();
      await (_database.delete(
        _database.scanRecords,
      )..where((row) => row.ownerId.equals(ownerId))).go();
      await (_database.delete(
        _database.batches,
      )..where((row) => row.ownerId.equals(ownerId))).go();
      await (_database.delete(
        _database.accountSyncSettings,
      )..where((row) => row.ownerId.equals(ownerId))).go();
      return imagePaths;
    });
  }

  /// Detaches an authenticated owner's active local graph into Guest mode.
  ///
  /// The caller supplies fresh IDs and copied image paths. This method keeps
  /// the database part atomic: active rows are recreated as unowned,
  /// local-only records, then the old owner rows and account sync settings are
  /// removed. Remote identifiers, revisions, tombstones, and sync queues are
  /// intentionally discarded so the detached copy cannot be synchronized to
  /// the old account.
  Future<List<String>> detachAccountToGuest({
    required String ownerId,
    required Map<String, String> batchIdMap,
    required Map<String, String> scanIdMap,
    required Map<String, String> orderIdMap,
    required Map<String, String> imagePathByScanId,
    String workspaceId = 'legacy-workspace',
    int workspaceGeneration = 0,
  }) async {
    final localOnly = PersistenceCodecs.encodeSyncState(
      LocalSyncState.localOnly,
    );
    final imageLocalOnly = PersistenceCodecs.encodeImageSyncState(
      ImageSyncState.localOnly,
    );

    return _database.transaction(() async {
      final batches = await (_database.select(
        _database.batches,
      )..where((row) => row.ownerId.equals(ownerId))).get();
      final scans = await (_database.select(
        _database.scanRecords,
      )..where((row) => row.ownerId.equals(ownerId))).get();
      final orders = await (_database.select(
        _database.orders,
      )..where((row) => row.ownerId.equals(ownerId))).get();
      final detachedAt = DateTime.now().toUtc();
      final oldImagePaths = scans
          .map((row) => row.localImageRelativePath)
          .whereType<String>()
          .toList(growable: false);
      final activeBatchIds = batches
          .where((row) => row.deletedAt == null)
          .map((row) => row.id)
          .toSet();

      for (final batch in batches.where((row) => row.deletedAt == null)) {
        final newId = batchIdMap[batch.id];
        if (newId == null) {
          throw StateError('Missing detached batch ID for ${batch.id}.');
        }
        await _database
            .into(_database.batches)
            .insert(
              BatchesCompanion.insert(
                id: newId,
                ownerId: Value<String?>(null),
                name: batch.name,
                fruitType: batch.fruitType,
                createdAt: batch.createdAt,
                updatedAt: batch.updatedAt,
                syncState: Value(localOnly),
                remoteRevision: const Value(0),
              ),
            );
        await _database
            .into(_database.detachedEntityOrigins)
            .insert(
              DetachedEntityOriginsCompanion.insert(
                id: _originId(
                  'batch',
                  batch.id,
                  workspaceId,
                  workspaceGeneration,
                ),
                workspaceId: workspaceId,
                generation: workspaceGeneration,
                entityType: 'batch',
                guestEntityId: newId,
                originalOwnerId: ownerId,
                originalEntityId: batch.id,
                originalRemoteRevision: batch.remoteRevision,
                detachedAt: detachedAt,
              ),
            );
      }

      for (final scan in scans.where((row) => row.deletedAt == null)) {
        final newId = scanIdMap[scan.id];
        if (newId == null) {
          throw StateError('Missing detached scan ID for ${scan.id}.');
        }
        final newBatchId = scan.batchId == null
            ? null
            : batchIdMap[scan.batchId!];
        final imagePath = imagePathByScanId[scan.id];
        await _database
            .into(_database.scanRecords)
            .insert(
              ScanRecordsCompanion.insert(
                id: newId,
                ownerId: Value<String?>(null),
                batchId: Value<String?>(newBatchId),
                fruitType: scan.fruitType,
                ripenessStage: scan.ripenessStage,
                modelConfidence: scan.modelConfidence,
                modelVersion: scan.modelVersion,
                resultOrigin: Value(scan.resultOrigin),
                shelfLifeStatus: scan.shelfLifeStatus,
                shelfLifeMinimum: Value(scan.shelfLifeMinimum),
                shelfLifeMaximum: Value(scan.shelfLifeMaximum),
                shelfLifeUnit: Value(scan.shelfLifeUnit),
                shelfLifeGuidance: Value(scan.shelfLifeGuidance),
                shelfLifeReason: Value(scan.shelfLifeReason),
                shelfLifeEvidenceVersion: scan.shelfLifeEvidenceVersion,
                localImageRelativePath: Value(imagePath),
                remoteImageKey: const Value<String?>(null),
                createdAt: scan.createdAt,
                updatedAt: scan.updatedAt,
                syncState: Value(localOnly),
                remoteRevision: const Value(0),
                imageSyncState: Value(imageLocalOnly),
              ),
            );
        await _database
            .into(_database.detachedEntityOrigins)
            .insert(
              DetachedEntityOriginsCompanion.insert(
                id: _originId(
                  'scan',
                  scan.id,
                  workspaceId,
                  workspaceGeneration,
                ),
                workspaceId: workspaceId,
                generation: workspaceGeneration,
                entityType: 'scan',
                guestEntityId: newId,
                originalOwnerId: ownerId,
                originalEntityId: scan.id,
                originalRemoteRevision: scan.remoteRevision,
                detachedAt: detachedAt,
              ),
            );
      }

      for (final order in orders.where(
        (row) => row.deletedAt == null && activeBatchIds.contains(row.batchId),
      )) {
        final newId = orderIdMap[order.id];
        final newBatchId = batchIdMap[order.batchId];
        if (newId == null || newBatchId == null) {
          throw StateError('Missing detached order mapping for ${order.id}.');
        }
        await _database
            .into(_database.orders)
            .insert(
              OrdersCompanion.insert(
                id: newId,
                ownerId: Value<String?>(null),
                batchId: newBatchId,
                customerName: order.customerName,
                deliveryAddress: order.deliveryAddress,
                deliveryDate: order.deliveryDate,
                status: order.status,
                createdAt: order.createdAt,
                updatedAt: order.updatedAt,
                syncState: Value(localOnly),
                remoteRevision: const Value(0),
              ),
            );
        await _database
            .into(_database.detachedEntityOrigins)
            .insert(
              DetachedEntityOriginsCompanion.insert(
                id: _originId(
                  'order',
                  order.id,
                  workspaceId,
                  workspaceGeneration,
                ),
                workspaceId: workspaceId,
                generation: workspaceGeneration,
                entityType: 'order',
                guestEntityId: newId,
                originalOwnerId: ownerId,
                originalEntityId: order.id,
                originalRemoteRevision: order.remoteRevision,
                detachedAt: detachedAt,
              ),
            );
      }

      await (_database.delete(
        _database.orders,
      )..where((row) => row.ownerId.equals(ownerId))).go();
      await (_database.delete(
        _database.scanRecords,
      )..where((row) => row.ownerId.equals(ownerId))).go();
      await (_database.delete(
        _database.batches,
      )..where((row) => row.ownerId.equals(ownerId))).go();
      await (_database.delete(
        _database.accountSyncSettings,
      )..where((row) => row.ownerId.equals(ownerId))).go();
      return oldImagePaths;
    });
  }

  static String _originId(
    String entityType,
    String entityId,
    String workspaceId,
    int generation,
  ) => '$workspaceId:$generation:$entityType:$entityId';

  static LocalSyncSettings _settingsFromRow(AccountSyncSettingsRow row) {
    return LocalSyncSettings(
      imageUploadConsent: row.imageUploadConsent,
      consentVersion: row.consentVersion,
      lastSuccessfulSyncAt: row.lastSuccessfulSyncAt?.toUtc(),
      lastSyncAttemptAt: row.lastSyncAttemptAt?.toUtc(),
      syncCursorAt: row.syncCursorAt?.toUtc(),
      lastSyncErrorCode: row.lastSyncErrorCode,
      remoteRevision: row.remoteRevision,
      syncState: PersistenceCodecs.decodeSyncState(row.syncState),
    );
  }

  static LocalApplyResult _applyResult(
    int? localRevision,
    String? localSyncState,
    int remoteRevision,
  ) {
    if (localRevision != null && localRevision >= remoteRevision) {
      return LocalApplyResult.ignoredAsDuplicate;
    }
    if (localSyncState != null) {
      final state = PersistenceCodecs.decodeSyncState(localSyncState);
      if (state == LocalSyncState.pending ||
          state == LocalSyncState.syncing ||
          state == LocalSyncState.failed) {
        return LocalApplyResult.replacedPendingConflict;
      }
    }
    return LocalApplyResult.applied;
  }

  static RemoteSyncRecord _batchToRemote(BatchRow row) {
    return RemoteSyncRecord(
      table: SyncTable.batches,
      id: row.id,
      userId: row.ownerId!,
      values: {
        'name': row.name,
        'fruit_type': row.fruitType,
        'created_at': row.createdAt.toUtc().toIso8601String(),
        'updated_at': row.updatedAt.toUtc().toIso8601String(),
        'deleted_at': row.deletedAt?.toUtc().toIso8601String(),
      },
      revision: row.remoteRevision,
      serverChangedAt: row.updatedAt.toUtc(),
    );
  }

  static RemoteSyncRecord _scanToRemote(ScanRecordRow row) {
    return RemoteSyncRecord(
      table: SyncTable.scanRecords,
      id: row.id,
      userId: row.ownerId!,
      values: {
        'batch_id': row.batchId,
        'fruit_type': row.fruitType,
        'ripeness_stage': row.ripenessStage,
        'model_confidence': row.modelConfidence,
        'model_version': row.modelVersion,
        'result_origin': row.resultOrigin,
        'shelf_life_status': row.shelfLifeStatus,
        'shelf_life_minimum': row.shelfLifeMinimum,
        'shelf_life_maximum': row.shelfLifeMaximum,
        'shelf_life_unit': row.shelfLifeUnit,
        'shelf_life_guidance': row.shelfLifeGuidance,
        'shelf_life_reason': row.shelfLifeReason,
        'shelf_life_evidence_version': row.shelfLifeEvidenceVersion,
        'remote_image_key': row.remoteImageKey,
        'created_at': row.createdAt.toUtc().toIso8601String(),
        'updated_at': row.updatedAt.toUtc().toIso8601String(),
        'deleted_at': row.deletedAt?.toUtc().toIso8601String(),
      },
      revision: row.remoteRevision,
      serverChangedAt: row.updatedAt.toUtc(),
    );
  }

  static RemoteSyncRecord _orderToRemote(OrderRow row) {
    return RemoteSyncRecord(
      table: SyncTable.orders,
      id: row.id,
      userId: row.ownerId!,
      values: {
        'batch_id': row.batchId,
        'customer_name': row.customerName,
        'delivery_address': row.deliveryAddress,
        'delivery_date': row.deliveryDate.toUtc().toIso8601String(),
        'status': row.status,
        'created_at': row.createdAt.toUtc().toIso8601String(),
        'updated_at': row.updatedAt.toUtc().toIso8601String(),
        'deleted_at': row.deletedAt?.toUtc().toIso8601String(),
      },
      revision: row.remoteRevision,
      serverChangedAt: row.updatedAt.toUtc(),
    );
  }
}

final class LocalAccountData {
  const LocalAccountData({
    required this.batches,
    required this.scans,
    required this.orders,
    required this.settings,
  });

  final List<BatchRow> batches;
  final List<ScanRecordRow> scans;
  final List<OrderRow> orders;
  final LocalSyncSettings settings;
}

String _requiredString(Map<String, Object?> values, String key) {
  final value = values[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Missing remote field: $key');
}

String? _optionalString(Map<String, Object?> values, String key) {
  final value = values[key];
  return value == null ? null : value as String;
}

DateTime _requiredDate(Map<String, Object?> values, String key) {
  final value = values[key];
  if (value is DateTime) return value.toUtc();
  if (value is String) return DateTime.parse(value).toUtc();
  throw FormatException('Missing remote date: $key');
}

DateTime? _optionalDate(Map<String, Object?> values, String key) {
  final value = values[key];
  if (value == null) return null;
  return value is DateTime
      ? value.toUtc()
      : DateTime.parse(value as String).toUtc();
}

int? _optionalInt(Map<String, Object?> values, String key) {
  final value = values[key];
  return value == null ? null : (value as num).toInt();
}

double _requiredDouble(Map<String, Object?> values, String key) {
  final value = values[key];
  if (value is num) return value.toDouble();
  throw FormatException('Missing remote number: $key');
}

bool _requiredBool(Map<String, Object?> values, String key) {
  final value = values[key];
  if (value is bool) return value;
  throw FormatException('Missing remote boolean: $key');
}
