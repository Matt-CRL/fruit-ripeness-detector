import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/core/database/app_database.dart';
import 'package:kami/core/database/app_database_provider.dart';
import 'package:kami/core/persistence/local_sync_state.dart';
import 'package:kami/core/persistence/persistence_codecs.dart';
import 'package:kami/core/persistence/persistence_validation.dart';
import 'package:kami/features/orders/domain/batch_order.dart';
import 'package:kami/features/orders/domain/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return DriftOrderRepository(ref.watch(appDatabaseProvider));
});

final class DriftOrderRepository implements OrderRepository {
  const DriftOrderRepository(this._database);

  final AppDatabase _database;

  @override
  Future<void> create(BatchOrder order) async {
    await _database.transaction(() async {
      final batch = await _requireOrderableBatch(
        batchId: order.batchId,
        ownerId: order.ownerId,
        requireSavedScan: true,
      );
      if (order.status != BatchOrderStatus.pending) {
        throw StateError('New orders must start as Pending.');
      }
      final activeOrderQuery = _database.select(_database.orders)
        ..where(
          (table) =>
              table.batchId.equals(order.batchId) & table.deletedAt.isNull(),
        );
      if (await activeOrderQuery.getSingleOrNull() != null) {
        throw StateError('A batch can have only one active order.');
      }

      await _database
          .into(_database.orders)
          .insert(
            OrdersCompanion.insert(
              id: order.id,
              ownerId: Value(order.ownerId),
              batchId: order.batchId,
              customerName: order.customerName,
              deliveryAddress: order.deliveryAddress,
              deliveryDate: order.deliveryDate,
              status: PersistenceCodecs.encodeOrderStatus(order.status),
              createdAt: order.createdAt,
              updatedAt: order.updatedAt,
              deletedAt: Value(order.deletedAt),
              syncState: Value(
                PersistenceCodecs.encodeSyncState(
                  batch.ownerId == null
                      ? LocalSyncState.localOnly
                      : LocalSyncState.pending,
                ),
              ),
              remoteRevision: Value(order.remoteRevision),
            ),
          );
    });
  }

  @override
  Future<BatchOrder?> findActiveForBatch(String batchId) async {
    PersistenceValidation.entityId(batchId, 'batchId');
    final query = _database.select(_database.orders)
      ..where(
        (table) => table.batchId.equals(batchId) & table.deletedAt.isNull(),
      );
    final row = await query.getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  @override
  Stream<List<BatchOrder>> watchActive() {
    final query = _database.select(_database.orders)
      ..where((table) => table.deletedAt.isNull())
      ..orderBy([
        (table) => OrderingTerm.desc(table.createdAt),
        (table) => OrderingTerm.desc(table.id),
      ]);
    return query.watch().map(
      (rows) => rows.map(_fromRow).toList(growable: false),
    );
  }

  @override
  Stream<BatchOrder?> watchActiveForBatch(String batchId) {
    PersistenceValidation.entityId(batchId, 'batchId');
    final query = _database.select(_database.orders)
      ..where(
        (table) => table.batchId.equals(batchId) & table.deletedAt.isNull(),
      );
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : _fromRow(row),
    );
  }

  @override
  Future<void> updatePending(BatchOrder order) async {
    await _database.transaction(() async {
      final query = _database.select(_database.orders)
        ..where(
          (table) =>
              table.batchId.equals(order.batchId) & table.deletedAt.isNull(),
        );
      final existing = await query.getSingleOrNull();
      if (existing == null || existing.id != order.id) {
        throw StateError('The Pending order is no longer available.');
      }
      if (PersistenceCodecs.decodeOrderStatus(existing.status) !=
              BatchOrderStatus.pending ||
          order.status != BatchOrderStatus.pending) {
        throw StateError('Completed orders cannot be edited.');
      }
      if (existing.ownerId != order.ownerId) {
        throw StateError('The order owner cannot be changed.');
      }
      if (order.updatedAt.isBefore(existing.updatedAt.toUtc())) {
        throw StateError('The update time is older than the saved order.');
      }
      await _requireOrderableBatch(
        batchId: order.batchId,
        ownerId: order.ownerId,
        requireSavedScan: false,
      );

      await (_database.update(
        _database.orders,
      )..where((table) => table.id.equals(order.id))).write(
        OrdersCompanion(
          customerName: Value(order.customerName),
          deliveryAddress: Value(order.deliveryAddress),
          deliveryDate: Value(order.deliveryDate),
          updatedAt: Value(order.updatedAt),
          syncState: Value(
            PersistenceCodecs.encodeSyncState(
              order.ownerId == null
                  ? LocalSyncState.localOnly
                  : LocalSyncState.pending,
            ),
          ),
        ),
      );
    });
  }

  @override
  Future<void> cancel({
    required String batchId,
    required DateTime updatedAt,
  }) async {
    PersistenceValidation.entityId(batchId, 'batchId');
    PersistenceValidation.utc(updatedAt, 'updatedAt');

    await _database.transaction(() async {
      final query = _database.select(_database.orders)
        ..where(
          (table) => table.batchId.equals(batchId) & table.deletedAt.isNull(),
        );
      final existing = await query.getSingleOrNull();
      if (existing == null) {
        throw StateError('The Pending order is no longer available.');
      }
      if (PersistenceCodecs.decodeOrderStatus(existing.status) !=
          BatchOrderStatus.pending) {
        throw StateError('Completed orders cannot be canceled.');
      }
      if (updatedAt.isBefore(existing.updatedAt.toUtc())) {
        throw StateError(
          'The cancellation time is older than the saved order.',
        );
      }

      final syncState = existing.ownerId == null
          ? LocalSyncState.localOnly
          : LocalSyncState.pending;
      await (_database.update(
        _database.orders,
      )..where((table) => table.id.equals(existing.id))).write(
        OrdersCompanion(
          updatedAt: Value(updatedAt),
          deletedAt: Value(updatedAt),
          syncState: Value(PersistenceCodecs.encodeSyncState(syncState)),
        ),
      );
    });
  }

  @override
  Future<BatchOrder> complete({
    required String batchId,
    required DateTime updatedAt,
  }) async {
    PersistenceValidation.entityId(batchId, 'batchId');
    PersistenceValidation.utc(updatedAt, 'updatedAt');

    return _database.transaction(() async {
      final query = _database.select(_database.orders)
        ..where(
          (table) => table.batchId.equals(batchId) & table.deletedAt.isNull(),
        );
      final existing = await query.getSingleOrNull();
      if (existing == null) {
        throw StateError('The Pending order is no longer available.');
      }
      if (PersistenceCodecs.decodeOrderStatus(existing.status) !=
          BatchOrderStatus.pending) {
        throw StateError('This order is already completed.');
      }
      if (updatedAt.isBefore(existing.updatedAt.toUtc())) {
        throw StateError('The completion time is older than the saved order.');
      }
      await _requireOrderableBatch(
        batchId: batchId,
        ownerId: existing.ownerId,
        requireSavedScan: true,
      );

      final syncState = existing.ownerId == null
          ? LocalSyncState.localOnly
          : LocalSyncState.pending;
      await (_database.update(
        _database.orders,
      )..where((table) => table.id.equals(existing.id))).write(
        OrdersCompanion(
          status: Value(
            PersistenceCodecs.encodeOrderStatus(BatchOrderStatus.completed),
          ),
          updatedAt: Value(updatedAt),
          syncState: Value(PersistenceCodecs.encodeSyncState(syncState)),
        ),
      );
      return BatchOrder(
        id: existing.id,
        ownerId: existing.ownerId,
        batchId: existing.batchId,
        customerName: existing.customerName,
        deliveryAddress: existing.deliveryAddress,
        deliveryDate: existing.deliveryDate.toUtc(),
        status: BatchOrderStatus.completed,
        createdAt: existing.createdAt.toUtc(),
        updatedAt: updatedAt,
        deletedAt: existing.deletedAt?.toUtc(),
        syncState: syncState,
        remoteRevision: existing.remoteRevision,
      );
    });
  }

  Future<BatchRow> _requireOrderableBatch({
    required String batchId,
    required String? ownerId,
    required bool requireSavedScan,
  }) async {
    final batchQuery = _database.select(_database.batches)
      ..where((table) => table.id.equals(batchId) & table.deletedAt.isNull());
    final batch = await batchQuery.getSingleOrNull();
    if (batch == null) {
      throw StateError('The order requires an active batch.');
    }
    if (batch.ownerId != ownerId) {
      throw StateError('The order and batch must have the same owner.');
    }
    if (requireSavedScan) {
      final scansQuery = _database.select(_database.scanRecords)
        ..where(
          (table) => table.batchId.equals(batchId) & table.deletedAt.isNull(),
        );
      if ((await scansQuery.get()).isEmpty) {
        throw StateError(
          'An order requires a batch with at least one saved scan.',
        );
      }
    }
    return batch;
  }

  static BatchOrder _fromRow(OrderRow row) {
    return BatchOrder(
      id: row.id,
      ownerId: row.ownerId,
      batchId: row.batchId,
      customerName: row.customerName,
      deliveryAddress: row.deliveryAddress,
      deliveryDate: row.deliveryDate.toUtc(),
      status: PersistenceCodecs.decodeOrderStatus(row.status),
      createdAt: row.createdAt.toUtc(),
      updatedAt: row.updatedAt.toUtc(),
      deletedAt: row.deletedAt?.toUtc(),
      syncState: PersistenceCodecs.decodeSyncState(row.syncState),
      remoteRevision: row.remoteRevision,
    );
  }
}
