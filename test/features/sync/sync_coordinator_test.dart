import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kami/core/database/app_database.dart';
import 'package:kami/core/database/app_database_provider.dart';
import 'package:kami/core/persistence/local_sync_state.dart';
import 'package:kami/features/auth/application/current_owner_provider.dart';
import 'package:kami/features/batches/data/drift_batch_repository.dart';
import 'package:kami/features/batches/domain/fruit_batch.dart';
import 'package:kami/features/history/data/app_private_retained_scan_image_store.dart';
import 'package:kami/features/history/data/drift_scan_record_repository.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/orders/data/drift_order_repository.dart';
import 'package:kami/features/orders/domain/batch_order.dart';
import 'package:kami/features/scan/domain/scan_models.dart';
import 'package:kami/features/sync/application/sync_coordinator.dart';
import 'package:kami/features/sync/domain/sync_gateway.dart';
import 'package:kami/features/sync/domain/sync_models.dart';

import '../../helpers/fake_history_storage.dart';

const _ownerId = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
const _batchId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _scanId = '11111111-1111-4111-8111-111111111111';
const _orderId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
final _now = DateTime.utc(2026, 8, 10, 8);

void main() {
  late AppDatabase database;
  late FakeSyncGateway gateway;
  late ProviderContainer container;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    gateway = FakeSyncGateway();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        currentOwnerIdProvider.overrideWithValue(_ownerId),
        syncGatewayProvider.overrideWithValue(gateway),
        retainedScanImageStoreProvider.overrideWithValue(
          FakeRetainedScanImageStore(),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  test('pushes pending metadata in dependency order', () async {
    await _createPendingGraph(database);

    final result = await container
        .read(syncCoordinatorProvider)
        .syncNow(SyncTrigger.manualRetry);

    expect(result.status, SyncStatus.upToDate);
    expect(result.pushed, 3);
    expect(gateway.pushOrder, [
      '${SyncTable.batches.name}:$_batchId',
      '${SyncTable.scanRecords.name}:$_scanId',
      '${SyncTable.orders.name}:$_orderId',
    ]);
    final rows = await database.select(database.batches).get();
    expect(rows.single.remoteRevision, 1);
    expect(rows.single.syncState, 'synchronized');
  });

  test('a stale edit is replaced and reported as a conflict', () async {
    await DriftBatchRepository(database).create(
      FruitBatch(
        id: _batchId,
        ownerId: _ownerId,
        name: 'Stale local name',
        fruit: FruitIdentifier.carabaoMango,
        createdAt: _now,
        updatedAt: _now.add(const Duration(minutes: 2)),
        syncState: LocalSyncState.pending,
        remoteRevision: 1,
      ),
    );
    gateway.seed(
      RemoteSyncRecord(
        table: SyncTable.batches,
        id: _batchId,
        userId: _ownerId,
        values: {
          'name': 'Accepted cloud name',
          'fruit_type': 'carabao_mango',
          'created_at': _now.toIso8601String(),
          'updated_at': _now.add(const Duration(minutes: 1)).toIso8601String(),
          'deleted_at': null,
        },
        revision: 2,
        serverChangedAt: _now.add(const Duration(minutes: 1)),
      ),
    );

    final result = await container
        .read(syncCoordinatorProvider)
        .syncNow(SyncTrigger.manualRetry);

    expect(result.status, SyncStatus.conflict);
    expect(result.conflicts, 1);
    final row = await database.select(database.batches).getSingle();
    expect(row.name, 'Accepted cloud name');
    expect(row.remoteRevision, 2);
    expect(row.syncState, 'synchronized');
  });
}

Future<void> _createPendingGraph(AppDatabase database) async {
  await DriftBatchRepository(database).create(
    FruitBatch(
      id: _batchId,
      ownerId: _ownerId,
      name: 'Account batch',
      fruit: FruitIdentifier.carabaoMango,
      createdAt: _now,
      updatedAt: _now,
      syncState: LocalSyncState.pending,
    ),
  );
  await DriftScanRecordRepository(database).create(
    SavedScanRecord(
      id: _scanId,
      ownerId: _ownerId,
      batchId: _batchId,
      fruit: FruitIdentifier.carabaoMango,
      ripeness: RipenessStage.ripe,
      modelConfidence: 0.91,
      modelVersion: 'synthetic-model-v1',
      resultOrigin: ResultOrigin.onDeviceModel,
      shelfLife: const ShelfLifeRange(
        minimum: 2,
        maximum: 4,
        unit: 'days',
        storageGuidance: 'Synthetic guidance.',
        evidenceVersion: 'evidence-v1',
      ),
      createdAt: _now,
      updatedAt: _now,
      syncState: LocalSyncState.pending,
    ),
  );
  await DriftOrderRepository(database).create(
    BatchOrder(
      id: _orderId,
      ownerId: _ownerId,
      batchId: _batchId,
      customerName: 'Synthetic customer',
      deliveryAddress: 'Synthetic address',
      deliveryDate: _now.add(const Duration(days: 1)),
      status: BatchOrderStatus.pending,
      createdAt: _now,
      updatedAt: _now,
      syncState: LocalSyncState.pending,
    ),
  );
}

final class FakeSyncGateway implements SyncGateway {
  final Map<String, RemoteSyncRecord> _records = {};
  final List<String> pushOrder = [];

  void seed(RemoteSyncRecord record) {
    _records[_key(record.table, record.id)] = record;
  }

  @override
  Future<DateTime> serverTimeAnchor() async =>
      _now.add(const Duration(hours: 1));

  @override
  Future<PushResult> push(
    RemoteSyncRecord record, {
    required int expectedRevision,
  }) async {
    pushOrder.add('${record.table.name}:${record.id}');
    final key = _key(record.table, record.id);
    final existing = _records[key];
    if (existing == null && expectedRevision != 0 ||
        existing != null && existing.revision != expectedRevision) {
      return PushConflict(existing!);
    }
    final accepted = RemoteSyncRecord(
      table: record.table,
      id: record.id,
      userId: record.userId,
      values: record.values,
      revision: (existing?.revision ?? 0) + 1,
      serverChangedAt: _now.add(const Duration(minutes: 30)),
    );
    _records[key] = accepted;
    return PushAccepted(accepted);
  }

  @override
  Future<PullPage> pull({
    required SyncTable table,
    required String userId,
    required DateTime changedSince,
    required DateTime anchor,
    SyncCursor? after,
    int limit = 200,
  }) async {
    final records = _records.values
        .where(
          (record) =>
              record.table == table &&
              record.userId == userId &&
              !record.serverChangedAt.isBefore(changedSince) &&
              !record.serverChangedAt.isAfter(anchor),
        )
        .toList(growable: false);
    return PullPage(records: records, hasMore: false);
  }

  @override
  Future<void> uploadHistoryImage({
    required String objectKey,
    required Uint8List jpegBytes,
  }) async {}

  @override
  Future<Uint8List> downloadHistoryImage(String objectKey) async =>
      Uint8List(0);

  @override
  Future<void> deleteHistoryImages(Iterable<String> objectKeys) async {}

  @override
  Future<void> deleteAccount() async {}

  static String _key(SyncTable table, String id) => '${table.name}:$id';
}
