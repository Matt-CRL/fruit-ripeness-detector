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
const _detachedBatchId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const _detachedScanId = '33333333-3333-4333-8333-333333333333';
const _detachedOrderId = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
const _postDetachScanId = '44444444-4444-4444-8444-444444444444';
const _workspaceId = '55555555-5555-4555-8555-555555555555';
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
      final settings = await sync.readSettings(_ownerId);

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

  test('photo consent and sync settings are independent per account', () async {
    await sync.setImageUploadConsent(
      ownerId: _ownerId,
      consent: true,
      authenticated: true,
    );

    expect(await sync.photoConsentForAccount(_ownerId), isTrue);
    expect(
      await sync.photoConsentForAccount('ffffffff-ffff-4fff-8fff-ffffffffffff'),
      isNull,
    );

    await sync.setImageUploadConsent(
      ownerId: 'ffffffff-ffff-4fff-8fff-ffffffffffff',
      consent: false,
      authenticated: true,
    );
    expect(await sync.photoConsentForAccount(_ownerId), isTrue);
    expect(
      await sync.photoConsentForAccount('ffffffff-ffff-4fff-8fff-ffffffffffff'),
      isFalse,
    );
  });

  test('detaches a linked graph into fresh local-only Guest records', () async {
    await batches.create(
      FruitBatch(
        id: _batchId,
        name: 'Linked batch',
        fruit: FruitIdentifier.carabaoMango,
        createdAt: _now,
        updatedAt: _now,
        ownerId: _ownerId,
        syncState: LocalSyncState.synchronized,
      ),
    );
    await scans.create(_scan(_scanId, batchId: _batchId, ownerId: _ownerId));
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
        ownerId: _ownerId,
        syncState: LocalSyncState.synchronized,
      ),
    );
    await sync.setImageUploadConsent(
      ownerId: _ownerId,
      consent: true,
      authenticated: true,
    );

    final oldImagePaths = await sync.detachAccountToGuest(
      ownerId: _ownerId,
      batchIdMap: {_batchId: _detachedBatchId},
      scanIdMap: {_scanId: _detachedScanId},
      orderIdMap: {_orderId: _detachedOrderId},
      imagePathByScanId: const {},
    );

    expect(oldImagePaths, ['history_images/$_scanId.jpg']);
    final detachedBatch = await (database.select(
      database.batches,
    )..where((row) => row.id.equals(_detachedBatchId))).getSingle();
    final detachedScan = await (database.select(
      database.scanRecords,
    )..where((row) => row.id.equals(_detachedScanId))).getSingle();
    final detachedOrder = await (database.select(
      database.orders,
    )..where((row) => row.id.equals(_detachedOrderId))).getSingle();

    expect(detachedBatch.ownerId, isNull);
    expect(detachedBatch.syncState, 'local_only');
    expect(detachedBatch.remoteRevision, 0);
    expect(detachedScan.ownerId, isNull);
    expect(detachedScan.batchId, _detachedBatchId);
    expect(detachedScan.localImageRelativePath, isNull);
    expect(detachedScan.remoteImageKey, isNull);
    expect(detachedScan.syncState, 'local_only');
    expect(detachedScan.imageSyncState, 'local_only');
    expect(detachedOrder.ownerId, isNull);
    expect(detachedOrder.batchId, _detachedBatchId);
    expect(detachedOrder.syncState, 'local_only');
    expect(await database.select(database.accountSyncSettings).get(), isEmpty);
    expect(
      await (database.select(
        database.batches,
      )..where((row) => row.id.equals(_batchId))).get(),
      isEmpty,
    );
    expect(
      await (database.select(
        database.scanRecords,
      )..where((row) => row.id.equals(_scanId))).get(),
      isEmpty,
    );
    expect(
      await (database.select(
        database.orders,
      )..where((row) => row.id.equals(_orderId))).get(),
      isEmpty,
    );
  });

  test(
    'former-owner re-link restores original IDs and keeps new Guest scans',
    () async {
      await batches.create(
        FruitBatch(
          id: _batchId,
          name: 'Linked batch',
          fruit: FruitIdentifier.carabaoMango,
          createdAt: _now,
          updatedAt: _now,
          ownerId: _ownerId,
          syncState: LocalSyncState.synchronized,
        ),
      );
      await scans.create(_scan(_scanId, batchId: _batchId, ownerId: _ownerId));

      await sync.detachAccountToGuest(
        ownerId: _ownerId,
        batchIdMap: {_batchId: _detachedBatchId},
        scanIdMap: {_scanId: _detachedScanId},
        orderIdMap: const {},
        imagePathByScanId: const {},
        workspaceId: _workspaceId,
        workspaceGeneration: 0,
      );
      await scans.create(_scan(_postDetachScanId));

      final reassociated = await sync.reassociateDetachedGuestData(
        ownerId: _ownerId,
        workspaceId: _workspaceId,
        generation: 0,
        imageUploadConsent: false,
      );

      expect(reassociated, isTrue);
      final restoredBatch = await (database.select(
        database.batches,
      )..where((row) => row.id.equals(_batchId))).getSingle();
      final restoredScan = await (database.select(
        database.scanRecords,
      )..where((row) => row.id.equals(_scanId))).getSingle();
      final newScan = await (database.select(
        database.scanRecords,
      )..where((row) => row.id.equals(_postDetachScanId))).getSingle();

      expect(restoredBatch.ownerId, _ownerId);
      expect(restoredBatch.remoteRevision, 0);
      expect(restoredScan.ownerId, _ownerId);
      expect(restoredScan.batchId, _batchId);
      expect(newScan.ownerId, _ownerId);
      expect(newScan.batchId, isNull);
    },
  );
}

SavedScanRecord _scan(String id, {String? batchId, String? ownerId}) {
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
    ownerId: ownerId,
    syncState: LocalSyncState.localOnly,
  );
}
