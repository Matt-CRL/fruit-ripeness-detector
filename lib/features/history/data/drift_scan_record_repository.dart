import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/core/database/app_database.dart';
import 'package:kami/core/database/app_database_provider.dart';
import 'package:kami/core/persistence/local_sync_state.dart';
import 'package:kami/core/persistence/persistence_codecs.dart';
import 'package:kami/core/persistence/persistence_validation.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/history/domain/scan_record_repository.dart';
import 'package:kami/features/history/domain/saved_scan_query.dart';
import 'package:kami/features/auth/application/current_owner_provider.dart';
import 'package:kami/features/orders/domain/batch_order.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

final scanRecordRepositoryProvider = Provider<ScanRecordRepository>((ref) {
  return DriftScanRecordRepository(
    ref.watch(appDatabaseProvider),
    ownerId: ref.watch(currentOwnerIdProvider),
    scopeOwner: true,
  );
});

final class DriftScanRecordRepository implements ScanRecordRepository {
  const DriftScanRecordRepository(
    this._database, {
    this.ownerId,
    this.scopeOwner = false,
  });

  final AppDatabase _database;
  final String? ownerId;
  final bool scopeOwner;

  @override
  Future<void> create(SavedScanRecord record) async {
    if (scopeOwner && record.ownerId != ownerId) {
      throw StateError('The scan owner does not match the signed-in account.');
    }
    await _database.transaction(() async {
      final batchId = record.batchId;
      if (batchId != null) {
        final batchQuery = _database.select(_database.batches)
          ..where(
            (table) => table.id.equals(batchId) & table.deletedAt.isNull(),
          );
        final batch = await batchQuery.getSingleOrNull();
        if (batch == null) {
          throw StateError('The scan requires an active batch.');
        }
        if (batch.fruitType != PersistenceCodecs.encodeFruit(record.fruit)) {
          throw StateError('A scan can only join a batch of the same fruit.');
        }
        if (batch.ownerId != record.ownerId) {
          throw StateError('The scan and batch must have the same owner.');
        }

        final completedOrderQuery = _database.select(_database.orders)
          ..where(
            (table) =>
                table.batchId.equals(batchId) &
                table.deletedAt.isNull() &
                table.status.equals(
                  PersistenceCodecs.encodeOrderStatus(
                    BatchOrderStatus.completed,
                  ),
                ),
          );
        if (await completedOrderQuery.getSingleOrNull() != null) {
          throw StateError('A completed-order batch is locked.');
        }
      }

      await _database.into(_database.scanRecords).insert(_toCompanion(record));
    });
  }

  @override
  Future<SavedScanRecord?> findActiveById(String id) async {
    final query = _database.select(_database.scanRecords)
      ..where((table) =>
          table.id.equals(id) & table.deletedAt.isNull() & _ownerPredicate(table));
    final row = await query.getSingleOrNull();
    return row == null ? null : fromRow(row);
  }

  @override
  Stream<SavedScanRecord?> watchActiveById(String id) {
    final query = _database.select(_database.scanRecords)
      ..where((table) =>
          table.id.equals(id) & table.deletedAt.isNull() & _ownerPredicate(table));
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : fromRow(row),
    );
  }

  @override
  Future<List<SavedScanRecord>> listActive() async {
    final query = _activeScansQuery();
    return (await query.get()).map(fromRow).toList(growable: false);
  }

  @override
  Stream<List<SavedScanRecord>> watchActive() {
    return _activeScansQuery().watch().map(
      (rows) => rows.map(fromRow).toList(growable: false),
    );
  }

  @override
  Future<SavedScanPage> fetchPage({
    required SavedScanQuery query,
    PageCursor? cursor,
    int limit = 50,
  }) async {
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'Must be greater than zero.');
    }
    final statement = _pagedScansQuery(query, cursor: cursor);
    final rows = await (statement..limit(limit + 1)).get();
    final hasMore = rows.length > limit;
    final pageRows = hasMore ? rows.take(limit).toList() : rows;
    final records = pageRows.map(fromRow).toList(growable: false);
    final nextCursor = hasMore && records.isNotEmpty
        ? PageCursor(createdAt: records.last.createdAt, id: records.last.id)
        : null;
    return SavedScanPage(
      records: records,
      totalCount: await count(query: query),
      nextCursor: nextCursor,
    );
  }

  @override
  Future<int> count({required SavedScanQuery query}) async {
    final statement = _database.selectOnly(_database.scanRecords)
      ..addColumns([_database.scanRecords.id.count()])
      ..where(_scanPredicates(query));
    final row = await statement.getSingle();
    return row.read(_database.scanRecords.id.count()) ?? 0;
  }

  @override
  Future<SavedScanRecord> deleteActive({
    required String scanId,
    required DateTime deletedAt,
  }) async {
    PersistenceValidation.entityId(scanId, 'scanId');
    PersistenceValidation.utc(deletedAt, 'deletedAt');

    return _database.transaction(() async {
      final scanQuery = _database.select(_database.scanRecords)
        ..where((table) =>
            table.id.equals(scanId) &
            table.deletedAt.isNull() &
            _ownerPredicate(table));
      final scan = await scanQuery.getSingleOrNull();
      if (scan == null) {
        throw StateError('The saved scan is no longer available.');
      }
      if (deletedAt.isBefore(scan.updatedAt.toUtc())) {
        throw StateError('The deletion time is older than the saved scan.');
      }

      final batchId = scan.batchId;
      if (batchId != null) {
        throw StateError(
          'Assigned scans must be removed from their batch before deletion.',
        );
      }

      final record = fromRow(scan);
      final nextSyncState = scan.ownerId == null
          ? LocalSyncState.localOnly
          : LocalSyncState.pending;
      await (_database.update(
        _database.scanRecords,
      )..where((table) => table.id.equals(scanId))).write(
        ScanRecordsCompanion(
          updatedAt: Value(deletedAt),
          deletedAt: Value(deletedAt),
          syncState: Value(PersistenceCodecs.encodeSyncState(nextSyncState)),
        ),
      );
      return record;
    });
  }

  @override
  Future<List<SavedScanRecord>> deleteActiveMany({
    required Iterable<String> scanIds,
    required DateTime deletedAt,
  }) async {
    final ids = scanIds.toSet();
    for (final id in ids) {
      PersistenceValidation.entityId(id, 'scanId');
    }
    PersistenceValidation.utc(deletedAt, 'deletedAt');
    if (ids.isEmpty) {
      return const [];
    }

    return _database.transaction(() async {
      final scanQuery = _database.select(_database.scanRecords)
        ..where(
          (table) =>
              table.id.isIn(ids.toList()) &
              table.deletedAt.isNull() &
              _ownerPredicate(table),
        );
      final scans = await scanQuery.get();
      if (scans.length != ids.length) {
        throw StateError('One or more saved scans are no longer available.');
      }
      for (final scan in scans) {
        if (deletedAt.isBefore(scan.updatedAt.toUtc())) {
          throw StateError('The deletion time is older than a saved scan.');
        }
        if (scan.batchId != null) {
          throw StateError(
            'Assigned scans must be removed from their batch before deletion.',
          );
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
            updatedAt: Value(deletedAt),
            deletedAt: Value(deletedAt),
            syncState: Value(PersistenceCodecs.encodeSyncState(nextSyncState)),
          ),
        );
      }
      return scans.map(fromRow).toList(growable: false);
    });
  }

  SimpleSelectStatement<$ScanRecordsTable, ScanRecordRow> _activeScansQuery() {
    return _database.select(_database.scanRecords)
      ..where((table) => table.deletedAt.isNull() & _ownerPredicate(table))
      ..orderBy([
        (table) => OrderingTerm.desc(table.createdAt),
        (table) => OrderingTerm.desc(table.id),
      ]);
  }

  SimpleSelectStatement<$ScanRecordsTable, ScanRecordRow> _pagedScansQuery(
    SavedScanQuery query, {
    PageCursor? cursor,
  }) {
    final predicates = _scanPredicates(query);
    final cursorPredicate = cursor == null
        ? null
        : query.sortOrder == SavedScanSortOrder.newestFirst
        ? (_database.scanRecords.createdAt.isSmallerThanValue(
                cursor.createdAt,
              ) |
              (_database.scanRecords.createdAt.equals(cursor.createdAt) &
                  _database.scanRecords.id.isSmallerThanValue(cursor.id)))
        : (_database.scanRecords.createdAt.isBiggerThanValue(cursor.createdAt) |
              (_database.scanRecords.createdAt.equals(cursor.createdAt) &
                  _database.scanRecords.id.isBiggerThanValue(cursor.id)));
    return _database.select(_database.scanRecords)
      ..where(
        (table) =>
            cursorPredicate == null ? predicates : predicates & cursorPredicate,
      )
      ..orderBy([
        (table) => OrderingTerm(
          expression: table.createdAt,
          mode: query.sortOrder == SavedScanSortOrder.newestFirst
              ? OrderingMode.desc
              : OrderingMode.asc,
        ),
        (table) => OrderingTerm(
          expression: table.id,
          mode: query.sortOrder == SavedScanSortOrder.newestFirst
              ? OrderingMode.desc
              : OrderingMode.asc,
        ),
      ]);
  }

  Expression<bool> _scanPredicates(SavedScanQuery query) {
    final table = _database.scanRecords;
    var predicate = table.deletedAt.isNull();
    if (scopeOwner) predicate &= _ownerPredicate(table);
    if (query.fruit != null) {
      predicate &= table.fruitType.equals(
        PersistenceCodecs.encodeFruit(query.fruit!),
      );
    }
    if (query.ripeness != null) {
      predicate &= table.ripenessStage.equals(
        PersistenceCodecs.encodeRipeness(query.ripeness!),
      );
    }
    if (query.inBatch != null) {
      predicate &= query.inBatch!
          ? table.batchId.isNotNull()
          : table.batchId.isNull();
    }
    if (query.batchId != null) {
      predicate &= table.batchId.equals(query.batchId!);
    }
    if (query.ownerId != null) {
      predicate &= table.ownerId.equals(query.ownerId!);
    } else if (query.onlyNullOwner) {
      predicate &= table.ownerId.isNull();
    }
    if (query.createdFromUtc != null) {
      predicate &= table.createdAt.isBiggerOrEqualValue(query.createdFromUtc!);
    }
    if (query.createdUntilUtc != null) {
      predicate &= table.createdAt.isSmallerThanValue(query.createdUntilUtc!);
    }
    return predicate;
  }

  Expression<bool> _ownerPredicate($ScanRecordsTable table) {
    if (!scopeOwner) return const Constant(true);
    return ownerId == null ? table.ownerId.isNull() : table.ownerId.equals(ownerId!);
  }

  static ScanRecordsCompanion _toCompanion(SavedScanRecord record) {
    final shelfLife = record.shelfLife;
    return ScanRecordsCompanion.insert(
      id: record.id,
      ownerId: Value(record.ownerId),
      batchId: Value(record.batchId),
      fruitType: PersistenceCodecs.encodeFruit(record.fruit),
      ripenessStage: PersistenceCodecs.encodeRipeness(record.ripeness),
      modelConfidence: record.modelConfidence,
      modelVersion: record.modelVersion,
      resultOrigin: Value(
        PersistenceCodecs.encodeResultOrigin(record.resultOrigin),
      ),
      shelfLifeStatus: switch (shelfLife) {
        ShelfLifeRange() => PersistenceCodecs.shelfLifeAvailable,
        ShelfLifeConsumeImmediately() => PersistenceCodecs.shelfLifeAvailable,
        ShelfLifeUnavailable() => PersistenceCodecs.shelfLifeUnavailable,
      },
      shelfLifeMinimum: Value(switch (shelfLife) {
        ShelfLifeRange() => shelfLife.minimum,
        ShelfLifeConsumeImmediately() => 0,
        ShelfLifeUnavailable() => null,
      }),
      shelfLifeMaximum: Value(switch (shelfLife) {
        ShelfLifeRange() => shelfLife.maximum,
        ShelfLifeConsumeImmediately() => 0,
        ShelfLifeUnavailable() => null,
      }),
      shelfLifeUnit: Value(switch (shelfLife) {
        ShelfLifeRange() => shelfLife.unit,
        ShelfLifeConsumeImmediately() => 'days',
        ShelfLifeUnavailable() => null,
      }),
      shelfLifeGuidance: Value(switch (shelfLife) {
        ShelfLifeRange() => shelfLife.storageGuidance,
        ShelfLifeConsumeImmediately() => shelfLife.storageGuidance,
        ShelfLifeUnavailable() => null,
      }),
      shelfLifeReason: Value(switch (shelfLife) {
        ShelfLifeRange() => null,
        ShelfLifeConsumeImmediately() => null,
        ShelfLifeUnavailable() => shelfLife.reason,
      }),
      shelfLifeEvidenceVersion: switch (shelfLife) {
        ShelfLifeRange() => shelfLife.evidenceVersion,
        ShelfLifeConsumeImmediately() => shelfLife.evidenceVersion,
        ShelfLifeUnavailable() => shelfLife.evidenceVersion,
      },
      localImageRelativePath: Value(record.localImageRelativePath),
      remoteImageKey: Value(record.remoteImageKey),
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
      deletedAt: Value(record.deletedAt),
      syncState: Value(PersistenceCodecs.encodeSyncState(record.syncState)),
      remoteRevision: Value(record.remoteRevision),
      imageSyncState: Value(
        PersistenceCodecs.encodeImageSyncState(record.imageSyncState),
      ),
    );
  }

  static SavedScanRecord fromRow(ScanRecordRow row) {
    final shelfLife = switch (row.shelfLifeStatus) {
      PersistenceCodecs.shelfLifeAvailable =>
        row.shelfLifeMinimum == 0 && row.shelfLifeMaximum == 0
            ? ShelfLifeConsumeImmediately(
                storageGuidance: row.shelfLifeGuidance!,
                evidenceVersion: row.shelfLifeEvidenceVersion,
              )
            : ShelfLifeRange(
                minimum: row.shelfLifeMinimum!,
                maximum: row.shelfLifeMaximum!,
                unit: row.shelfLifeUnit!,
                storageGuidance: row.shelfLifeGuidance!,
                evidenceVersion: row.shelfLifeEvidenceVersion,
              ),
      PersistenceCodecs.shelfLifeUnavailable => ShelfLifeUnavailable(
        reason: row.shelfLifeReason!,
        evidenceVersion: row.shelfLifeEvidenceVersion,
      ),
      final value => throw FormatException(
        'Unknown persisted shelf-life status: $value',
      ),
    };

    return SavedScanRecord(
      id: row.id,
      ownerId: row.ownerId,
      batchId: row.batchId,
      fruit: PersistenceCodecs.decodeFruit(row.fruitType),
      ripeness: PersistenceCodecs.decodeRipeness(row.ripenessStage),
      modelConfidence: row.modelConfidence,
      modelVersion: row.modelVersion,
      resultOrigin: PersistenceCodecs.decodeResultOrigin(row.resultOrigin),
      shelfLife: shelfLife,
      localImageRelativePath: row.localImageRelativePath,
      remoteImageKey: row.remoteImageKey,
      createdAt: row.createdAt.toUtc(),
      updatedAt: row.updatedAt.toUtc(),
      deletedAt: row.deletedAt?.toUtc(),
      syncState: PersistenceCodecs.decodeSyncState(row.syncState),
      remoteRevision: row.remoteRevision,
      imageSyncState: PersistenceCodecs.decodeImageSyncState(
        row.imageSyncState,
      ),
    );
  }
}
