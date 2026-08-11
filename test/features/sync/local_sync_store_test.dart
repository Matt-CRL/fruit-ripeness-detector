import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kami/core/database/app_database.dart';
import 'package:kami/core/persistence/image_sync_state.dart';
import 'package:kami/core/persistence/local_sync_state.dart';
import 'package:kami/core/persistence/persistence_codecs.dart';
import 'package:kami/features/batches/data/drift_batch_repository.dart';
import 'package:kami/features/batches/domain/fruit_batch.dart';
import 'package:kami/features/history/data/drift_scan_record_repository.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/orders/data/drift_order_repository.dart';
import 'package:kami/features/orders/domain/batch_order.dart';
import 'package:kami/features/scan/domain/scan_models.dart';
import 'package:kami/features/sync/data/local_sync_store.dart';

const _ownerId = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
const _batchId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _scanId = '11111111-1111-4111-8111-111111111111';
const _deletedScanId = '22222222-2222-4222-8222-222222222222';
const _orderId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
final _now = DateTime.utc(2026, 8, 10, 8);

void main() {
  late AppDatabase database;
  late DriftBatchRepository batches;
  late DriftScanRecordRepository scans;
  late DriftOrderRepository orders;
  late LocalSyncStore sync;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    batches = DriftBatchRepository(database);
    scans = DriftScanRecordRepository(database);
    orders = DriftOrderRepository(database);
    sync = LocalSyncStore(database);
  });

  tearDown(() => database.close());

  test(
    'claims active guest graph atomically and purges guest tombstones',
    () async {
      await batches.create(
        FruitBatch(
          id: _batchId,
          name: 'Guest batch',
          fruit: FruitIdentifier.carabaoMango,
          createdAt: _now,
          updatedAt: _now,
          syncState: LocalSyncState.localOnly,
        ),
      );
      await scans.create(_scan(_scanId, batchId: _batchId));
      await orders.create(
        BatchOrder(
          id: _orderId,
          batchId: _batchId,
          customerName: 'Synthetic customer',
          deliveryAddress: 'Synthetic address',
          deliveryDate: _now.add(const Duration(days: 1)),
          status: BatchOrderStatus.pending,
          createdAt: _now,
          updatedAt: _now,
          syncState: LocalSyncState.localOnly,
        ),
      );
      await scans.create(_scan(_deletedScanId));
      await scans.deleteActive(
        scanId: _deletedScanId,
        deletedAt: _now.add(const Duration(minutes: 1)),
      );

      expect(await sync.hasActiveGuestData(), isTrue);
      await sync.claimGuestData(ownerId: _ownerId, imageUploadConsent: true);

      final batch = await database.select(database.batches).getSingle();
      final scan = await (database.select(
        database.scanRecords,
      )..where((row) => row.id.equals(_scanId))).getSingle();
      final order = await database.select(database.orders).getSingle();
      final allScans = await database.select(database.scanRecords).get();
      final settings = await sync.readSettings();

      expect(batch.ownerId, _ownerId);
      expect(scan.ownerId, _ownerId);
      expect(order.ownerId, _ownerId);
      expect(
        [batch.syncState, scan.syncState, order.syncState],
        everyElement(PersistenceCodecs.encodeSyncState(LocalSyncState.pending)),
      );
      expect(
        scan.imageSyncState,
        PersistenceCodecs.encodeImageSyncState(ImageSyncState.pendingUpload),
      );
      expect(allScans.map((row) => row.id), [_scanId]);
      expect(settings.imageUploadConsent, isTrue);
      expect(settings.consentVersion, developmentConsentVersion);
      expect(settings.syncState, LocalSyncState.pending);
      expect(await sync.hasActiveGuestData(), isFalse);
    },
  );

  test('metadata-only claim keeps retained photos local', () async {
    await scans.create(_scan(_scanId));

    await sync.claimGuestData(ownerId: _ownerId, imageUploadConsent: false);

    final row = await database.select(database.scanRecords).getSingle();
    expect(row.ownerId, _ownerId);
    expect(
      row.syncState,
      PersistenceCodecs.encodeSyncState(LocalSyncState.pending),
    );
    expect(
      row.imageSyncState,
      PersistenceCodecs.encodeImageSyncState(ImageSyncState.localOnly),
    );
  });
}

SavedScanRecord _scan(String id, {String? batchId}) {
  return SavedScanRecord(
    id: id,
    batchId: batchId,
    fruit: FruitIdentifier.carabaoMango,
    ripeness: RipenessStage.ripe,
    modelConfidence: 0.91,
    modelVersion: 'synthetic-model-v1',
    resultOrigin: ResultOrigin.onDeviceModel,
    shelfLife: const ShelfLifeRange(
      minimum: 2,
      maximum: 4,
      unit: 'days',
      storageGuidance: 'Synthetic test guidance.',
      evidenceVersion: 'evidence-v1',
    ),
    localImageRelativePath: 'history_images/$id.jpg',
    createdAt: _now,
    updatedAt: _now,
    syncState: LocalSyncState.localOnly,
  );
}
