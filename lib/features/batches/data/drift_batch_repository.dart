import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/core/database/app_database.dart';
import 'package:kami/core/database/app_database_provider.dart';
import 'package:kami/core/persistence/local_sync_state.dart';
import 'package:kami/core/persistence/persistence_codecs.dart';
import 'package:kami/core/persistence/persistence_validation.dart';
import 'package:kami/features/batches/domain/batch_repository.dart';
import 'package:kami/features/batches/domain/fruit_batch.dart';
import 'package:kami/features/history/data/drift_scan_record_repository.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/orders/domain/batch_order.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

final batchRepositoryProvider = Provider<BatchRepository>((ref) {
  return DriftBatchRepository(ref.watch(appDatabaseProvider));
});

final class DriftBatchRepository implements BatchRepository {
  const DriftBatchRepository(this._database);

  final AppDatabase _database;

  @override
  Future<void> create(FruitBatch batch) async {
    await _database.into(_database.batches).insert(_toCompanion(batch));
  }

  @override
  Future<void> createWithScan({
    required FruitBatch batch,
    required String scanId,
    required DateTime updatedAt,
  }) async {
    await createWithScans(
      batch: batch,
      scanIds: [scanId],
      updatedAt: updatedAt,
    );
  }

  @override
  Future<void> createWithScans({
    required FruitBatch batch,
    required Iterable<String> scanIds,
    required DateTime updatedAt,
  }) async {
    final ids = scanIds.toSet().toList(growable: false);
    if (ids.isEmpty) {
      throw StateError('At least one scan is required.');
    }
    for (final scanId in ids) {
      PersistenceValidation.entityId(scanId, 'scanId');
    }
    PersistenceValidation.entityId(batch.id, 'batchId');
    PersistenceValidation.utc(updatedAt, 'updatedAt');

    await _database.transaction(() async {
      final scansQuery = _database.select(_database.scanRecords)
        ..where((table) => table.id.isIn(ids) & table.deletedAt.isNull());
      final scans = await scansQuery.get();
      if (scans.length != ids.length) {
        throw StateError('A selected scan does not exist or was deleted.');
      }
      for (final scan in scans) {
        if (scan.batchId != null) {
          throw StateError('A selected scan already belongs to a batch.');
        }
        if (scan.fruitType != PersistenceCodecs.encodeFruit(batch.fruit)) {
          throw StateError('A scan can only join a batch of the same fruit.');
        }
        if (scan.ownerId != batch.ownerId) {
          throw StateError('The scan and batch must have the same owner.');
        }
        if (updatedAt.isBefore(scan.updatedAt.toUtc())) {
          throw StateError('The assignment timestamp is older than the scan.');
        }
      }

      await _database.into(_database.batches).insert(_toCompanion(batch));
      for (final scan in scans) {
        await (_database.update(
          _database.scanRecords,
        )..where((table) => table.id.equals(scan.id))).write(
          ScanRecordsCompanion(
            batchId: Value(batch.id),
            updatedAt: Value(updatedAt),
            syncState: Value(
              PersistenceCodecs.encodeSyncState(
                scan.ownerId == null
                    ? LocalSyncState.localOnly
                    : LocalSyncState.pending,
              ),
            ),
          ),
        );
      }
    });
  }

  @override
  Future<FruitBatch?> findActiveById(String id) async {
    final query = _database.select(_database.batches)
      ..where((table) => table.id.equals(id) & table.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<List<FruitBatch>> listActive() async {
    final query = _database.select(_database.batches)
      ..where((table) => table.deletedAt.isNull())
      ..orderBy([
        (table) => OrderingTerm.desc(table.createdAt),
        (table) => OrderingTerm.desc(table.id),
      ]);
    return (await query.get()).map(_fromRow).toList(growable: false);
  }

  @override
  Stream<List<BatchSnapshot>> watchActiveSnapshots() {
    return _activeSnapshotQuery().watch().map(_snapshotsFromRows);
  }

  @override
  Stream<List<BatchListItem>> watchActiveList() {
    const sql = '''
      SELECT
        b.id,
        b.owner_id,
        b.name,
        b.fruit_type,
        b.created_at,
        b.updated_at,
        b.deleted_at,
        b.sync_state,
        COUNT(s.id) AS total_count,
        COALESCE(SUM(CASE WHEN s.ripeness_stage = 'unripe' THEN 1 ELSE 0 END), 0)
          AS unripe_count,
        COALESCE(SUM(CASE WHEN s.ripeness_stage = 'ripe' THEN 1 ELSE 0 END), 0)
          AS ripe_count,
        COALESCE(SUM(CASE WHEN s.ripeness_stage = 'overripe' THEN 1 ELSE 0 END), 0)
          AS overripe_count,
        MAX(CASE WHEN s.result_origin = 'demo' THEN 1 ELSE 0 END)
          AS contains_demo
      FROM batches b
      LEFT JOIN scan_records s
        ON s.batch_id = b.id AND s.deleted_at IS NULL
      WHERE b.deleted_at IS NULL
      GROUP BY b.id, b.owner_id, b.name, b.fruit_type, b.created_at,
        b.updated_at, b.deleted_at, b.sync_state
      ORDER BY b.created_at DESC, b.id DESC
    ''';
    return _database
        .customSelect(
          sql,
          readsFrom: {_database.batches, _database.scanRecords},
        )
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => BatchListItem(
                  batch: FruitBatch(
                    id: row.read<String>('id'),
                    ownerId: row.readNullable<String>('owner_id'),
                    name: row.read<String>('name'),
                    fruit: PersistenceCodecs.decodeFruit(
                      row.read<String>('fruit_type'),
                    ),
                    createdAt: row.read<DateTime>('created_at').toUtc(),
                    updatedAt: row.read<DateTime>('updated_at').toUtc(),
                    deletedAt: row
                        .readNullable<DateTime>('deleted_at')
                        ?.toUtc(),
                    syncState: PersistenceCodecs.decodeSyncState(
                      row.read<String>('sync_state'),
                    ),
                  ),
                  summary: BatchSummary(
                    total: row.read<int>('total_count'),
                    unripe: row.read<int>('unripe_count'),
                    ripe: row.read<int>('ripe_count'),
                    overripe: row.read<int>('overripe_count'),
                  ),
                  containsDemo: row.read<int>('contains_demo') == 1,
                ),
              )
              .toList(growable: false),
        );
  }

  @override
  Stream<BatchSnapshot?> watchActiveSnapshot(String batchId) {
    PersistenceValidation.entityId(batchId, 'batchId');
    return watchActiveSnapshots().map((snapshots) {
      for (final snapshot in snapshots) {
        if (snapshot.batch.id == batchId) {
          return snapshot;
        }
      }
      return null;
    });
  }

  @override
  Future<List<BatchSnapshot>> listCompatibleForScan(String scanId) async {
    PersistenceValidation.entityId(scanId, 'scanId');
    final scanQuery = _database.select(_database.scanRecords)
      ..where((table) => table.id.equals(scanId) & table.deletedAt.isNull());
    final scan = await scanQuery.getSingleOrNull();
    if (scan == null) {
      throw StateError('The scan does not exist or has been deleted.');
    }
    if (scan.batchId != null) {
      return const [];
    }

    final snapshots = _snapshotsFromRows(await _activeSnapshotQuery().get());
    return snapshots
        .where(
          (snapshot) =>
              snapshot.batch.ownerId == scan.ownerId &&
              PersistenceCodecs.encodeFruit(snapshot.batch.fruit) ==
                  scan.fruitType &&
              !snapshot.isLocked,
        )
        .toList(growable: false);
  }

  @override
  Future<List<BatchSnapshot>> listMoveTargets(String scanId) async {
    PersistenceValidation.entityId(scanId, 'scanId');
    final scanQuery = _database.select(_database.scanRecords)
      ..where((table) => table.id.equals(scanId) & table.deletedAt.isNull());
    final scan = await scanQuery.getSingleOrNull();
    if (scan == null) {
      throw StateError('The scan does not exist or has been deleted.');
    }
    if (scan.batchId == null) {
      return const [];
    }

    final snapshots = _snapshotsFromRows(await _activeSnapshotQuery().get());
    return snapshots
        .where(
          (snapshot) =>
              snapshot.batch.id != scan.batchId &&
              snapshot.batch.ownerId == scan.ownerId &&
              PersistenceCodecs.encodeFruit(snapshot.batch.fruit) ==
                  scan.fruitType &&
              !snapshot.isLocked,
        )
        .toList(growable: false);
  }

  @override
  Future<void> assignScan({
    required String scanId,
    required String batchId,
    required DateTime updatedAt,
  }) async {
    await assignScans(
      scanIds: [scanId],
      batchId: batchId,
      updatedAt: updatedAt,
    );
  }

  @override
  Future<void> assignScans({
    required Iterable<String> scanIds,
    required String batchId,
    required DateTime updatedAt,
  }) async {
    final ids = scanIds.toSet().toList(growable: false);
    if (ids.isEmpty) {
      throw StateError('At least one scan is required.');
    }
    for (final scanId in ids) {
      PersistenceValidation.entityId(scanId, 'scanId');
    }
    PersistenceValidation.entityId(batchId, 'batchId');
    PersistenceValidation.utc(updatedAt, 'updatedAt');

    await _database.transaction(() async {
      final batch = await _requireUnlockedBatch(batchId);
      final scansQuery = _database.select(_database.scanRecords)
        ..where((table) => table.id.isIn(ids) & table.deletedAt.isNull());
      final scans = await scansQuery.get();
      if (scans.length != ids.length) {
        throw StateError('A selected scan does not exist or was deleted.');
      }

      for (final scan in scans) {
        if (scan.batchId != null && scan.batchId != batchId) {
          throw StateError('A selected scan already belongs to another batch.');
        }
        if (scan.fruitType != batch.fruitType) {
          throw StateError('A scan can only join a batch of the same fruit.');
        }
        if (scan.ownerId != batch.ownerId) {
          throw StateError('The scan and batch must have the same owner.');
        }
        if (updatedAt.isBefore(scan.updatedAt.toUtc())) {
          throw StateError('The assignment timestamp is older than the scan.');
        }
      }

      for (final scan in scans) {
        final nextSyncState = scan.ownerId == null
            ? LocalSyncState.localOnly
            : LocalSyncState.pending;
        await (_database.update(
          _database.scanRecords,
        )..where((table) => table.id.equals(scan.id))).write(
          ScanRecordsCompanion(
            batchId: Value(batchId),
            updatedAt: Value(updatedAt),
            syncState: Value(PersistenceCodecs.encodeSyncState(nextSyncState)),
          ),
        );
      }
    });
  }

  @override
  Future<void> removeScan({
    required String scanId,
    required DateTime updatedAt,
  }) async {
    await removeScans(scanIds: [scanId], updatedAt: updatedAt);
  }

  @override
  Future<void> removeScans({
    required Iterable<String> scanIds,
    required DateTime updatedAt,
  }) async {
    final ids = scanIds.toSet().toList(growable: false);
    if (ids.isEmpty) {
      throw StateError('At least one scan is required.');
    }
    for (final scanId in ids) {
      PersistenceValidation.entityId(scanId, 'scanId');
    }
    PersistenceValidation.utc(updatedAt, 'updatedAt');

    await _database.transaction(() async {
      final scansQuery = _database.select(_database.scanRecords)
        ..where((table) => table.id.isIn(ids) & table.deletedAt.isNull());
      final scans = await scansQuery.get();
      if (scans.length != ids.length ||
          scans.any((scan) => scan.batchId == null)) {
        throw StateError('A selected scan is not assigned to an active batch.');
      }
      final batchId = scans.first.batchId!;
      if (scans.any((scan) => scan.batchId != batchId)) {
        throw StateError('Selected scans must belong to the same batch.');
      }
      if (scans.any((scan) => updatedAt.isBefore(scan.updatedAt.toUtc()))) {
        throw StateError(
          'The removal timestamp is older than a selected scan.',
        );
      }
      await _requireUnlockedBatch(batchId);
      await _ensurePendingOrderKeepsAnotherScan(
        batchId: batchId,
        excludedScanIds: ids,
      );

      for (final scan in scans) {
        await (_database.update(
          _database.scanRecords,
        )..where((table) => table.id.equals(scan.id))).write(
          ScanRecordsCompanion(
            batchId: const Value(null),
            updatedAt: Value(updatedAt),
            syncState: Value(
              PersistenceCodecs.encodeSyncState(
                scan.ownerId == null
                    ? LocalSyncState.localOnly
                    : LocalSyncState.pending,
              ),
            ),
          ),
        );
      }
    });
  }

  @override
  Future<void> moveScan({
    required String scanId,
    required String targetBatchId,
    required DateTime updatedAt,
  }) async {
    PersistenceValidation.entityId(scanId, 'scanId');
    PersistenceValidation.entityId(targetBatchId, 'targetBatchId');
    PersistenceValidation.utc(updatedAt, 'updatedAt');

    await _database.transaction(() async {
      final scanQuery = _database.select(_database.scanRecords)
        ..where((table) => table.id.equals(scanId) & table.deletedAt.isNull());
      final scan = await scanQuery.getSingleOrNull();
      if (scan == null || scan.batchId == null) {
        throw StateError('The scan is not assigned to an active batch.');
      }
      if (scan.batchId == targetBatchId) {
        return;
      }
      if (updatedAt.isBefore(scan.updatedAt.toUtc())) {
        throw StateError('The move timestamp is older than the scan.');
      }
      await _requireUnlockedBatch(scan.batchId!);
      await _ensurePendingOrderKeepsAnotherScan(
        batchId: scan.batchId!,
        excludedScanIds: [scanId],
      );

      final targetQuery = _database.select(_database.batches)
        ..where(
          (table) => table.id.equals(targetBatchId) & table.deletedAt.isNull(),
        );
      final target = await targetQuery.getSingleOrNull();
      if (target == null) {
        throw StateError('The destination batch does not exist.');
      }
      if (target.fruitType != scan.fruitType ||
          target.ownerId != scan.ownerId) {
        throw StateError(
          'The destination batch is not compatible with this scan.',
        );
      }
      await _requireUnlockedBatch(targetBatchId);

      await (_database.update(
        _database.scanRecords,
      )..where((table) => table.id.equals(scanId))).write(
        ScanRecordsCompanion(
          batchId: Value(targetBatchId),
          updatedAt: Value(updatedAt),
          syncState: Value(
            PersistenceCodecs.encodeSyncState(
              scan.ownerId == null
                  ? LocalSyncState.localOnly
                  : LocalSyncState.pending,
            ),
          ),
        ),
      );
    });
  }

  @override
  Future<void> rename({
    required String batchId,
    required String name,
    required DateTime updatedAt,
  }) async {
    PersistenceValidation.entityId(batchId, 'batchId');
    PersistenceValidation.nonBlank(name, 'name');
    PersistenceValidation.utc(updatedAt, 'updatedAt');

    await _database.transaction(() async {
      final batch = await _requireUnlockedBatch(batchId);
      if (updatedAt.isBefore(batch.updatedAt.toUtc())) {
        throw StateError('The rename timestamp is older than the batch.');
      }
      await (_database.update(
        _database.batches,
      )..where((table) => table.id.equals(batchId))).write(
        BatchesCompanion(
          name: Value(name),
          updatedAt: Value(updatedAt),
          syncState: Value(
            PersistenceCodecs.encodeSyncState(
              batch.ownerId == null
                  ? LocalSyncState.localOnly
                  : LocalSyncState.pending,
            ),
          ),
        ),
      );
    });
  }

  @override
  Future<void> changeFruitType({
    required String batchId,
    required FruitIdentifier fruit,
    required DateTime updatedAt,
  }) async {
    PersistenceValidation.entityId(batchId, 'batchId');
    PersistenceValidation.utc(updatedAt, 'updatedAt');
    final fruitType = PersistenceCodecs.encodeFruit(fruit);

    await _database.transaction(() async {
      final batch = await _requireUnlockedBatch(batchId);
      if (batch.fruitType == fruitType) {
        return;
      }
      if (updatedAt.isBefore(batch.updatedAt.toUtc())) {
        throw StateError(
          'The fruit-type change timestamp is older than the batch.',
        );
      }

      final activeScansQuery = _database.select(_database.scanRecords)
        ..where(
          (table) => table.batchId.equals(batchId) & table.deletedAt.isNull(),
        );
      if ((await activeScansQuery.get()).isNotEmpty) {
        throw StateError(
          'Fruit type can only be changed while the batch is empty.',
        );
      }

      final activeOrderQuery = _database.select(_database.orders)
        ..where(
          (table) => table.batchId.equals(batchId) & table.deletedAt.isNull(),
        );
      if (await activeOrderQuery.getSingleOrNull() != null) {
        throw StateError(
          'A batch with an active order cannot change fruit type.',
        );
      }

      await (_database.update(
        _database.batches,
      )..where((table) => table.id.equals(batchId))).write(
        BatchesCompanion(
          fruitType: Value(fruitType),
          updatedAt: Value(updatedAt),
          syncState: Value(
            PersistenceCodecs.encodeSyncState(
              batch.ownerId == null
                  ? LocalSyncState.localOnly
                  : LocalSyncState.pending,
            ),
          ),
        ),
      );
    });
  }

  @override
  Future<void> delete({
    required String batchId,
    required DateTime deletedAt,
  }) async {
    PersistenceValidation.entityId(batchId, 'batchId');
    PersistenceValidation.utc(deletedAt, 'deletedAt');

    await _database.transaction(() async {
      final batch = await _requireUnlockedBatch(batchId);
      if (deletedAt.isBefore(batch.updatedAt.toUtc())) {
        throw StateError('The deletion time is older than the batch.');
      }

      final activeScansQuery = _database.select(_database.scanRecords)
        ..where(
          (table) => table.batchId.equals(batchId) & table.deletedAt.isNull(),
        );
      if ((await activeScansQuery.get()).isNotEmpty) {
        throw StateError(
          'Remove or move every saved scan before deleting this batch.',
        );
      }
      final activeOrderQuery = _database.select(_database.orders)
        ..where(
          (table) => table.batchId.equals(batchId) & table.deletedAt.isNull(),
        );
      if (await activeOrderQuery.getSingleOrNull() != null) {
        throw StateError('A batch with an order cannot be deleted.');
      }

      await (_database.update(
        _database.batches,
      )..where((table) => table.id.equals(batchId))).write(
        BatchesCompanion(
          updatedAt: Value(deletedAt),
          deletedAt: Value(deletedAt),
          syncState: Value(
            PersistenceCodecs.encodeSyncState(
              batch.ownerId == null
                  ? LocalSyncState.localOnly
                  : LocalSyncState.pending,
            ),
          ),
        ),
      );
    });
  }

  @override
  Future<List<SavedScanRecord>> deleteCompletedWithScans({
    required String batchId,
    required DateTime deletedAt,
  }) async {
    PersistenceValidation.entityId(batchId, 'batchId');
    PersistenceValidation.utc(deletedAt, 'deletedAt');

    return _database.transaction(() async {
      final batchQuery = _database.select(_database.batches)
        ..where((table) => table.id.equals(batchId) & table.deletedAt.isNull());
      final batch = await batchQuery.getSingleOrNull();
      if (batch == null) {
        throw StateError('The batch does not exist or has been deleted.');
      }
      if (deletedAt.isBefore(batch.updatedAt.toUtc())) {
        throw StateError('The deletion time is older than the batch.');
      }

      final orderQuery = _database.select(_database.orders)
        ..where(
          (table) => table.batchId.equals(batchId) & table.deletedAt.isNull(),
        );
      final order = await orderQuery.getSingleOrNull();
      if (order == null ||
          PersistenceCodecs.decodeOrderStatus(order.status) !=
              BatchOrderStatus.completed) {
        throw StateError(
          'Only a completed-order batch can be deleted this way.',
        );
      }
      if (deletedAt.isBefore(order.updatedAt.toUtc())) {
        throw StateError(
          'The deletion time is older than the completed order.',
        );
      }

      final scansQuery = _database.select(_database.scanRecords)
        ..where(
          (table) => table.batchId.equals(batchId) & table.deletedAt.isNull(),
        );
      final scans = await scansQuery.get();
      for (final scan in scans) {
        if (deletedAt.isBefore(scan.updatedAt.toUtc())) {
          throw StateError('The deletion time is older than a saved scan.');
        }
      }

      final syncState = PersistenceCodecs.encodeSyncState(
        batch.ownerId == null
            ? LocalSyncState.localOnly
            : LocalSyncState.pending,
      );
      await (_database.update(_database.scanRecords)..where(
            (table) => table.batchId.equals(batchId) & table.deletedAt.isNull(),
          ))
          .write(
            ScanRecordsCompanion(
              updatedAt: Value(deletedAt),
              deletedAt: Value(deletedAt),
              syncState: Value(syncState),
            ),
          );
      await (_database.update(
        _database.orders,
      )..where((table) => table.id.equals(order.id))).write(
        OrdersCompanion(
          updatedAt: Value(deletedAt),
          deletedAt: Value(deletedAt),
          syncState: Value(syncState),
        ),
      );
      await (_database.update(
        _database.batches,
      )..where((table) => table.id.equals(batchId))).write(
        BatchesCompanion(
          updatedAt: Value(deletedAt),
          deletedAt: Value(deletedAt),
          syncState: Value(syncState),
        ),
      );

      return scans
          .map(DriftScanRecordRepository.fromRow)
          .toList(growable: false);
    });
  }

  @override
  Future<BatchSummary> summarize(String batchId) async {
    PersistenceValidation.entityId(batchId, 'batchId');
    if (await findActiveById(batchId) == null) {
      throw StateError('The batch does not exist or has been deleted.');
    }

    final query = _database.select(_database.scanRecords)
      ..where(
        (table) => table.batchId.equals(batchId) & table.deletedAt.isNull(),
      );
    final rows = await query.get();
    var unripe = 0;
    var ripe = 0;
    var overripe = 0;
    for (final row in rows) {
      switch (PersistenceCodecs.decodeRipeness(row.ripenessStage)) {
        case RipenessStage.unripe:
          unripe++;
        case RipenessStage.ripe:
          ripe++;
        case RipenessStage.overripe:
          overripe++;
      }
    }
    return BatchSummary(
      total: rows.length,
      unripe: unripe,
      ripe: ripe,
      overripe: overripe,
    );
  }

  static FruitBatch _fromRow(BatchRow row) {
    return FruitBatch(
      id: row.id,
      ownerId: row.ownerId,
      name: row.name,
      fruit: PersistenceCodecs.decodeFruit(row.fruitType),
      createdAt: row.createdAt.toUtc(),
      updatedAt: row.updatedAt.toUtc(),
      deletedAt: row.deletedAt?.toUtc(),
      syncState: PersistenceCodecs.decodeSyncState(row.syncState),
    );
  }

  Future<BatchRow> _requireUnlockedBatch(String batchId) async {
    final batchQuery = _database.select(_database.batches)
      ..where((table) => table.id.equals(batchId) & table.deletedAt.isNull());
    final batch = await batchQuery.getSingleOrNull();
    if (batch == null) {
      throw StateError('The batch does not exist or has been deleted.');
    }

    final completedOrderQuery = _database.select(_database.orders)
      ..where(
        (table) =>
            table.batchId.equals(batchId) &
            table.deletedAt.isNull() &
            table.status.equals(
              PersistenceCodecs.encodeOrderStatus(BatchOrderStatus.completed),
            ),
      );
    if (await completedOrderQuery.getSingleOrNull() != null) {
      throw StateError('A completed-order batch is locked.');
    }
    return batch;
  }

  Future<void> _ensurePendingOrderKeepsAnotherScan({
    required String batchId,
    required Iterable<String> excludedScanIds,
  }) async {
    final excludedIds = excludedScanIds.toSet().toList(growable: false);
    final pendingOrderQuery = _database.select(_database.orders)
      ..where(
        (table) =>
            table.batchId.equals(batchId) &
            table.deletedAt.isNull() &
            table.status.equals(
              PersistenceCodecs.encodeOrderStatus(BatchOrderStatus.pending),
            ),
      );
    if (await pendingOrderQuery.getSingleOrNull() == null) {
      return;
    }

    final remainingScansQuery = _database.select(_database.scanRecords)
      ..where(
        (table) =>
            table.batchId.equals(batchId) &
            table.id.isNotIn(excludedIds) &
            table.deletedAt.isNull(),
      );
    if ((await remainingScansQuery.get()).isEmpty) {
      throw const PendingOrderBatchException();
    }
  }

  JoinedSelectStatement<HasResultSet, dynamic> _activeSnapshotQuery() {
    final query =
        _database.select(_database.batches).join([
            leftOuterJoin(
              _database.scanRecords,
              _database.scanRecords.batchId.equalsExp(_database.batches.id) &
                  _database.scanRecords.deletedAt.isNull(),
            ),
            leftOuterJoin(
              _database.orders,
              _database.orders.batchId.equalsExp(_database.batches.id) &
                  _database.orders.deletedAt.isNull(),
            ),
          ])
          ..where(_database.batches.deletedAt.isNull())
          ..orderBy([
            OrderingTerm.desc(_database.batches.createdAt),
            OrderingTerm.desc(_database.batches.id),
            OrderingTerm.desc(_database.scanRecords.createdAt),
            OrderingTerm.desc(_database.scanRecords.id),
          ]);
    return query;
  }

  List<BatchSnapshot> _snapshotsFromRows(List<TypedResult> rows) {
    final builders = <String, _BatchSnapshotBuilder>{};
    for (final result in rows) {
      final batchRow = result.readTable(_database.batches);
      final builder = builders.putIfAbsent(
        batchRow.id,
        () => _BatchSnapshotBuilder(_fromRow(batchRow)),
      );
      final scanRow = result.readTableOrNull(_database.scanRecords);
      if (scanRow != null && !builder.scanIds.contains(scanRow.id)) {
        builder.scanIds.add(scanRow.id);
        builder.scans.add(DriftScanRecordRepository.fromRow(scanRow));
      }
      final orderRow = result.readTableOrNull(_database.orders);
      if (orderRow != null &&
          PersistenceCodecs.decodeOrderStatus(orderRow.status) ==
              BatchOrderStatus.completed) {
        builder.isLocked = true;
      }
    }

    return builders.values
        .map((builder) {
          var unripe = 0;
          var ripe = 0;
          var overripe = 0;
          for (final scan in builder.scans) {
            switch (scan.ripeness) {
              case RipenessStage.unripe:
                unripe++;
              case RipenessStage.ripe:
                ripe++;
              case RipenessStage.overripe:
                overripe++;
            }
          }
          return BatchSnapshot(
            batch: builder.batch,
            summary: BatchSummary(
              total: builder.scans.length,
              unripe: unripe,
              ripe: ripe,
              overripe: overripe,
            ),
            scans: builder.scans,
            isLocked: builder.isLocked,
          );
        })
        .toList(growable: false);
  }

  static BatchesCompanion _toCompanion(FruitBatch batch) {
    return BatchesCompanion.insert(
      id: batch.id,
      ownerId: Value(batch.ownerId),
      name: batch.name,
      fruitType: PersistenceCodecs.encodeFruit(batch.fruit),
      createdAt: batch.createdAt,
      updatedAt: batch.updatedAt,
      deletedAt: Value(batch.deletedAt),
      syncState: Value(PersistenceCodecs.encodeSyncState(batch.syncState)),
    );
  }
}

final class _BatchSnapshotBuilder {
  _BatchSnapshotBuilder(this.batch);

  final FruitBatch batch;
  final List<SavedScanRecord> scans = [];
  final Set<String> scanIds = {};
  bool isLocked = false;
}
