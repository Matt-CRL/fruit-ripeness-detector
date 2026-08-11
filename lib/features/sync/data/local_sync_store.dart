import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/core/database/app_database.dart';
import 'package:kami/core/database/app_database_provider.dart';
import 'package:kami/core/persistence/image_sync_state.dart';
import 'package:kami/core/persistence/local_sync_state.dart';
import 'package:kami/core/persistence/persistence_codecs.dart';
import 'package:kami/features/sync/domain/sync_models.dart';

const developmentConsentVersion = 'draft-development-v1';

final localSyncStoreProvider = Provider<LocalSyncStore>((ref) {
  return LocalSyncStore(ref.watch(appDatabaseProvider));
});

final class LocalSyncStore {
  const LocalSyncStore(this._database);

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
          .into(_database.appSettings)
          .insertOnConflictUpdate(
            AppSettingsCompanion.insert(
              id: const Value(1),
              imageUploadConsent: Value(imageUploadConsent),
              consentVersion: Value(consentVersion),
              syncState: Value(pending),
            ),
          );
    });
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
      await (_database.update(_database.appSettings)
            ..where((row) => row.syncState.equals(syncing)))
          .write(AppSettingsCompanion(syncState: Value(pending)));
    });
  }

  Future<LocalSyncSettings> readSettings() async {
    final row = await (_database.select(
      _database.appSettings,
    )..where((row) => row.id.equals(1))).getSingleOrNull();
    if (row == null) {
      return const LocalSyncSettings();
    }
    return _settingsFromRow(row);
  }

  Stream<LocalSyncSettings> watchSettings() {
    final query = _database.select(_database.appSettings)
      ..where((row) => row.id.equals(1));
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
            SELECT 1 FROM app_settings
            WHERE sync_state IN ('pending', 'failed')
          ) AS has_pending
          ''',
          variables: [
            Variable<String>(ownerId),
            Variable<String>(ownerId),
            Variable<String>(ownerId),
          ],
          readsFrom: {
            _database.batches,
            _database.scanRecords,
            _database.orders,
            _database.appSettings,
          },
        )
        .watchSingle()
        .map((row) => row.read<int>('has_pending') == 1)
        .distinct();
  }

  Future<void> setImageUploadConsent({
    required bool consent,
    required bool authenticated,
    String consentVersion = developmentConsentVersion,
  }) async {
    final state = authenticated
        ? LocalSyncState.pending
        : LocalSyncState.localOnly;
    await _database.transaction(() async {
      await _database
          .into(_database.appSettings)
          .insertOnConflictUpdate(
            AppSettingsCompanion.insert(
              id: const Value(1),
              imageUploadConsent: Value(consent),
              consentVersion: Value(consentVersion),
              syncState: Value(PersistenceCodecs.encodeSyncState(state)),
            ),
          );
      if (authenticated && consent) {
        await (_database.update(_database.scanRecords)..where(
              (row) =>
                  row.ownerId.isNotNull() &
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
        final settings = await readSettings();
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
          _database.appSettings,
        )..where((row) => row.id.equals(1))).write(
          AppSettingsCompanion(
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
          final settings = await readSettings();
          final result = _applyResult(
            settings.remoteRevision,
            PersistenceCodecs.encodeSyncState(settings.syncState),
            remote.revision,
          );
          if (result == LocalApplyResult.ignoredAsDuplicate) return result;
          await _database
              .into(_database.appSettings)
              .insertOnConflictUpdate(
                AppSettingsCompanion.insert(
                  id: const Value(1),
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

  Future<void> recordAttempt(DateTime at) async {
    await _database
        .into(_database.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            id: const Value(1),
            lastSyncAttemptAt: Value(at.toUtc()),
          ),
        );
  }

  Future<void> recordSuccess({
    required DateTime at,
    required DateTime anchor,
  }) async {
    await _database
        .into(_database.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            id: const Value(1),
            lastSuccessfulSyncAt: Value(at.toUtc()),
            lastSyncAttemptAt: Value(at.toUtc()),
            syncCursorAt: Value(anchor.toUtc()),
            lastSyncErrorCode: const Value(null),
          ),
        );
  }

  Future<void> recordFailure({
    required DateTime at,
    required String errorCode,
  }) async {
    await _database
        .into(_database.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            id: const Value(1),
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
    final settings = await readSettings();
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
      settings: await readSettings(),
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
      await _database.delete(_database.appSettings).go();
      return imagePaths;
    });
  }

  static LocalSyncSettings _settingsFromRow(AppSettingsRow row) {
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
    if (localSyncState != null &&
        PersistenceCodecs.decodeSyncState(localSyncState) !=
            LocalSyncState.synchronized) {
      return LocalApplyResult.replacedPendingConflict;
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
