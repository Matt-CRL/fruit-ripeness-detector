import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kami/core/database/app_database.dart';
import 'package:kami/core/persistence/entity_id_generator.dart';
import 'package:kami/core/persistence/local_sync_state.dart';
import 'package:kami/core/persistence/persistence_codecs.dart';
import 'package:kami/features/batches/data/drift_batch_repository.dart';
import 'package:kami/features/batches/domain/fruit_batch.dart';
import 'package:kami/features/history/data/drift_scan_record_repository.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/history/domain/saved_scan_query.dart';
import 'package:kami/features/orders/data/drift_order_repository.dart';
import 'package:kami/features/orders/domain/batch_order.dart';
import 'package:kami/features/scan/domain/scan_models.dart';
import 'package:uuid/uuid.dart';

const _scanOneId = '11111111-1111-4111-8111-111111111111';
const _scanTwoId = '22222222-2222-4222-8222-222222222222';
const _scanThreeId = '33333333-3333-4333-8333-333333333333';
const _scanFourId = '44444444-4444-4444-8444-444444444444';
const _batchOneId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _batchTwoId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const _batchThreeId = 'abababab-abab-4bab-8bab-abababababab';
const _orderOneId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const _orderTwoId = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
const _ownerOneId = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
const _ownerTwoId = 'ffffffff-ffff-4fff-8fff-ffffffffffff';

final _createdAt = DateTime.utc(2026, 7, 31, 8);
final _updatedAt = DateTime.utc(2026, 7, 31, 9);

void main() {
  late AppDatabase database;
  late DriftScanRecordRepository scans;
  late DriftBatchRepository batches;
  late DriftOrderRepository orders;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    scans = DriftScanRecordRepository(database);
    batches = DriftBatchRepository(database);
    orders = DriftOrderRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'schema version four opens with foreign keys and matches Drift',
    () async {
      final foreignKeys = await database
          .customSelect('PRAGMA foreign_keys')
          .getSingle();
      final userVersion = await database
          .customSelect('PRAGMA user_version')
          .getSingle();

      expect(database.schemaVersion, 4);
      expect(foreignKeys.data.values.single, 1);
      expect(userVersion.data.values.single, 4);
      await database.validateDatabaseSchema();
    },
  );

  test('version one scan rows migrate with explicit Demo provenance', () async {
    await database.close();
    final migrated = AppDatabase(
      NativeDatabase.memory(
        setup: (rawDatabase) {
          rawDatabase.execute('''
            CREATE TABLE scan_records (
              id TEXT NOT NULL PRIMARY KEY,
              owner_id TEXT NULL,
              batch_id TEXT NULL,
              fruit_type TEXT NOT NULL,
              ripeness_stage TEXT NOT NULL,
              model_confidence REAL NOT NULL,
              model_version TEXT NOT NULL,
              shelf_life_status TEXT NOT NULL,
              shelf_life_minimum INTEGER NULL,
              shelf_life_maximum INTEGER NULL,
              shelf_life_unit TEXT NULL,
              shelf_life_guidance TEXT NULL,
              shelf_life_reason TEXT NULL,
              shelf_life_evidence_version TEXT NOT NULL,
              local_image_relative_path TEXT NULL,
              remote_image_key TEXT NULL,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              deleted_at INTEGER NULL,
              sync_state TEXT NOT NULL DEFAULT 'local_only'
            )
          ''');
          rawDatabase.execute('''
            INSERT INTO scan_records (
              id, fruit_type, ripeness_stage, model_confidence, model_version,
              shelf_life_status, shelf_life_reason,
              shelf_life_evidence_version, created_at, updated_at, sync_state
            ) VALUES (
              '$_scanOneId', 'carabao_mango', 'ripe', 0.87,
              'legacy-fake-v1', 'unavailable', 'Legacy demo output.',
              'unavailable-v1', 1785484800, 1785484800, 'local_only'
            )
          ''');
          rawDatabase.userVersion = 1;
        },
      ),
    );
    addTearDown(migrated.close);

    final row = await migrated.select(migrated.scanRecords).getSingle();

    expect(
      row.resultOrigin,
      PersistenceCodecs.encodeResultOrigin(ResultOrigin.demo),
    );
    expect(
      (await migrated.customSelect('PRAGMA user_version').getSingle())
          .data
          .values
          .single,
      4,
    );
  });

  test('UUID generator creates valid client-side identifiers', () {
    final id = const UuidEntityIdGenerator().nextId();

    expect(Uuid.isValidUUIDFormat(fromString: id), isTrue);
  });

  test(
    'guest scans round-trip shelf-life variants and hide soft deletion',
    () async {
      await scans.create(_scan(id: _scanOneId));
      await scans.create(
        _scan(
          id: _scanTwoId,
          ripeness: RipenessStage.overripe,
          shelfLife: const ShelfLifeUnavailable(
            reason: 'No reviewed guidance is available.',
            evidenceVersion: 'evidence-v1',
          ),
          deletedAt: DateTime.utc(2026, 7, 31, 10),
        ),
      );

      final saved = await scans.findActiveById(_scanOneId);
      final visible = await scans.listActive();

      expect(saved?.ownerId, isNull);
      expect(saved?.batchId, isNull);
      expect(saved?.localImageRelativePath, 'retained/scans/example.jpg');
      expect(saved?.resultOrigin, ResultOrigin.onDeviceModel);
      expect(saved?.syncState, LocalSyncState.localOnly);
      expect(saved?.shelfLife, isA<ShelfLifeRange>());
      expect(visible.map((scan) => scan.id), [_scanOneId]);
      expect(await scans.findActiveById(_scanTwoId), isNull);
    },
  );

  test('saved scan pages use a stable cursor and preserve filters', () async {
    await scans.create(
      _scan(
        id: _scanOneId,
        createdAt: _createdAt,
        ripeness: RipenessStage.unripe,
      ),
    );
    await scans.create(
      _scan(
        id: _scanTwoId,
        createdAt: _createdAt.add(const Duration(minutes: 1)),
        ripeness: RipenessStage.ripe,
      ),
    );
    await scans.create(
      _scan(
        id: _scanThreeId,
        createdAt: _createdAt.add(const Duration(minutes: 2)),
        ripeness: RipenessStage.ripe,
      ),
    );
    await scans.create(
      _scan(
        id: _scanFourId,
        createdAt: _createdAt.add(const Duration(minutes: 3)),
        ripeness: RipenessStage.overripe,
      ),
    );

    const query = SavedScanQuery();
    final first = await scans.fetchPage(query: query, limit: 2);
    final second = await scans.fetchPage(
      query: query,
      cursor: first.nextCursor,
      limit: 2,
    );

    expect(first.records.map((record) => record.id), [
      _scanFourId,
      _scanThreeId,
    ]);
    expect(second.records.map((record) => record.id), [_scanTwoId, _scanOneId]);
    expect(first.totalCount, 4);
    expect(first.hasMore, isTrue);
    expect(second.hasMore, isFalse);

    final ripe = await scans.fetchPage(
      query: const SavedScanQuery(ripeness: RipenessStage.ripe),
      limit: 50,
    );
    expect(ripe.records.map((record) => record.id), [_scanThreeId, _scanTwoId]);
    expect(ripe.totalCount, 2);
  });

  test(
    'batch list projection returns summaries without scan collections',
    () async {
      await batches.create(_batch(id: _batchOneId));
      await scans.create(
        _scan(
          id: _scanOneId,
          batchId: _batchOneId,
          ripeness: RipenessStage.unripe,
        ),
      );
      await scans.create(
        _scan(
          id: _scanTwoId,
          batchId: _batchOneId,
          ripeness: RipenessStage.overripe,
        ),
      );

      final item = await batches.watchActiveList().first;

      expect(item, hasLength(1));
      expect(item.single.summary.total, 2);
      expect(item.single.summary.unripe, 1);
      expect(item.single.summary.overripe, 1);
    },
  );

  test(
    'consume immediately round-trips through the 0-0 compatibility sentinel',
    () async {
      await scans.create(
        _scan(
          id: _scanThreeId,
          ripeness: RipenessStage.overripe,
          shelfLife: const ShelfLifeConsumeImmediately(
            storageGuidance: 'Consume immediately if still sound.',
            evidenceVersion: 'provisional-literature-rules-v1.0',
          ),
        ),
      );

      final raw = await (database.select(
        database.scanRecords,
      )..where((row) => row.id.equals(_scanThreeId))).getSingle();
      final restored = await scans.findActiveById(_scanThreeId);

      expect(raw.shelfLifeStatus, PersistenceCodecs.shelfLifeAvailable);
      expect(raw.shelfLifeMinimum, 0);
      expect(raw.shelfLifeMaximum, 0);
      expect(restored?.shelfLife, isA<ShelfLifeConsumeImmediately>());
      final immediate = restored!.shelfLife as ShelfLifeConsumeImmediately;
      expect(immediate.storageGuidance, 'Consume immediately if still sound.');
    },
  );

  test('domain validation rejects unsafe paths and invalid shelf life', () {
    expect(
      () => _scan(id: _scanOneId, localImageRelativePath: '../outside.jpg'),
      throwsArgumentError,
    );
    expect(
      () => _scan(
        id: _scanOneId,
        shelfLife: const ShelfLifeRange(
          minimum: 4,
          maximum: 2,
          unit: 'days',
          storageGuidance: 'Synthetic test guidance.',
          evidenceVersion: 'evidence-v1',
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => PersistenceCodecs.decodeFruit('future_unreviewed_fruit'),
      throwsFormatException,
    );
  });

  test(
    'database constraints reject invalid codes and shelf-life shapes',
    () async {
      await expectLater(
        database
            .into(database.scanRecords)
            .insert(
              _scanCompanion(
                id: _scanOneId,
                fruitType: 'future_unreviewed_fruit',
              ),
            ),
        throwsA(anything),
      );
      await expectLater(
        database
            .into(database.scanRecords)
            .insert(
              _scanCompanion(
                id: '44444444-4444-4444-8444-444444444444',
                resultOrigin: const Value('future_unreviewed_origin'),
              ),
            ),
        throwsA(anything),
      );
      await expectLater(
        database
            .into(database.scanRecords)
            .insert(
              _scanCompanion(
                id: _scanTwoId,
                shelfLifeStatus: PersistenceCodecs.shelfLifeUnavailable,
                shelfLifeMinimum: const Value(1),
                shelfLifeMaximum: const Value(2),
                shelfLifeUnit: const Value('days'),
                shelfLifeGuidance: const Value('Inconsistent synthetic data.'),
                shelfLifeReason: const Value('Cannot coexist with a range.'),
              ),
            ),
        throwsA(anything),
      );
      await expectLater(
        database
            .into(database.scanRecords)
            .insert(
              _scanCompanion(
                id: _scanThreeId,
                ripenessStage: 'future_unreviewed_stage',
              ),
            ),
        throwsA(anything),
      );
    },
  );

  test('batch assignment is compatible, summarized, and atomic', () async {
    await batches.create(_batch(id: _batchOneId));
    await batches.create(
      _batch(id: _batchTwoId, fruit: FruitIdentifier.lakatanBanana),
    );
    await scans.create(_scan(id: _scanOneId));
    await scans.create(_scan(id: _scanTwoId, ripeness: RipenessStage.unripe));

    await batches.assignScan(
      scanId: _scanOneId,
      batchId: _batchOneId,
      updatedAt: _updatedAt,
    );
    await batches.assignScan(
      scanId: _scanTwoId,
      batchId: _batchOneId,
      updatedAt: _updatedAt,
    );
    final summary = await batches.summarize(_batchOneId);

    expect(summary.total, 2);
    expect(summary.unripe, 1);
    expect(summary.ripe, 1);
    expect(summary.overripe, 0);

    await scans.create(_scan(id: _scanThreeId));
    await scans.create(
      _scan(id: _scanFourId, fruit: FruitIdentifier.lakatanBanana),
    );
    await expectLater(
      batches.assignScans(
        scanIds: [_scanThreeId, _scanFourId],
        batchId: _batchOneId,
        updatedAt: _updatedAt,
      ),
      throwsStateError,
    );
    expect((await scans.findActiveById(_scanThreeId))?.batchId, isNull);
    expect((await scans.findActiveById(_scanFourId))?.batchId, isNull);

    await expectLater(
      batches.assignScan(
        scanId: _scanOneId,
        batchId: _batchTwoId,
        updatedAt: DateTime.utc(2026, 7, 31, 10),
      ),
      throwsStateError,
    );
    expect((await scans.findActiveById(_scanOneId))?.batchId, _batchOneId);
  });

  test('batch snapshots update live and create-with-scan is atomic', () async {
    await scans.create(_scan(id: _scanOneId));
    await batches.createWithScan(
      batch: _batch(id: _batchOneId),
      scanId: _scanOneId,
      updatedAt: _updatedAt,
    );

    final snapshot = (await batches.watchActiveSnapshots().first).single;
    expect(snapshot.batch.id, _batchOneId);
    expect(snapshot.summary.total, 1);
    expect(snapshot.summary.ripe, 1);
    expect(snapshot.scans.single.id, _scanOneId);
    expect((await scans.findActiveById(_scanOneId))?.batchId, _batchOneId);

    await scans.create(
      _scan(id: _scanTwoId, fruit: FruitIdentifier.lakatanBanana),
    );
    await expectLater(
      batches.createWithScan(
        batch: _batch(id: _batchTwoId),
        scanId: _scanTwoId,
        updatedAt: _updatedAt,
      ),
      throwsStateError,
    );
    expect(await batches.findActiveById(_batchTwoId), isNull);
    expect((await scans.findActiveById(_scanTwoId))?.batchId, isNull);
  });

  test(
    'compatible batches exclude other fruits and completed orders',
    () async {
      await batches.create(_batch(id: _batchOneId));
      await batches.create(
        _batch(id: _batchTwoId, fruit: FruitIdentifier.lakatanBanana),
      );
      await batches.create(_batch(id: _batchThreeId));
      await scans.create(_scan(id: _scanThreeId, batchId: _batchThreeId));
      await orders.create(_order(id: _orderOneId, batchId: _batchThreeId));
      await orders.complete(batchId: _batchThreeId, updatedAt: _updatedAt);
      await scans.create(_scan(id: _scanOneId));

      final compatible = await batches.listCompatibleForScan(_scanOneId);

      expect(compatible.map((snapshot) => snapshot.batch.id), [_batchOneId]);
    },
  );

  test(
    'orders enforce ownership, uniqueness, and completed-batch locking',
    () async {
      await batches.create(_batch(id: _batchOneId, ownerId: _ownerOneId));

      await expectLater(
        scans.create(
          _scan(id: _scanOneId, ownerId: _ownerTwoId, batchId: _batchOneId),
        ),
        throwsStateError,
      );
      expect(await scans.findActiveById(_scanOneId), isNull);

      await expectLater(
        orders.create(
          _order(id: _orderOneId, batchId: _batchOneId, ownerId: _ownerTwoId),
        ),
        throwsStateError,
      );

      await scans.create(
        _scan(id: _scanTwoId, ownerId: _ownerOneId, batchId: _batchOneId),
      );
      await orders.create(
        _order(id: _orderOneId, batchId: _batchOneId, ownerId: _ownerOneId),
      );
      await orders.complete(batchId: _batchOneId, updatedAt: _updatedAt);
      expect(
        (await orders.findActiveForBatch(_batchOneId))?.status,
        BatchOrderStatus.completed,
      );

      await expectLater(
        orders.create(
          _order(id: _orderTwoId, batchId: _batchOneId, ownerId: _ownerOneId),
        ),
        throwsA(anything),
      );

      await scans.create(_scan(id: _scanOneId, ownerId: _ownerOneId));
      await expectLater(
        batches.assignScan(
          scanId: _scanOneId,
          batchId: _batchOneId,
          updatedAt: _updatedAt,
        ),
        throwsStateError,
      );
      expect((await scans.findActiveById(_scanOneId))?.batchId, isNull);
    },
  );

  test(
    'local correction and deletion preserve batch and order safeguards',
    () async {
      await batches.create(_batch(id: _batchOneId));
      await batches.create(_batch(id: _batchTwoId));
      await scans.create(_scan(id: _scanOneId, batchId: _batchOneId));

      expect(
        (await batches.listMoveTargets(
          _scanOneId,
        )).map((snapshot) => snapshot.batch.id),
        [_batchTwoId],
      );
      await batches.moveScan(
        scanId: _scanOneId,
        targetBatchId: _batchTwoId,
        updatedAt: _updatedAt,
      );
      expect((await scans.findActiveById(_scanOneId))?.batchId, _batchTwoId);

      await batches.removeScan(scanId: _scanOneId, updatedAt: _updatedAt);
      expect((await scans.findActiveById(_scanOneId))?.batchId, isNull);
      await batches.changeFruitType(
        batchId: _batchOneId,
        fruit: FruitIdentifier.redPapaya,
        updatedAt: _updatedAt,
      );
      expect(
        (await batches.findActiveById(_batchOneId))?.fruit,
        FruitIdentifier.redPapaya,
      );
      await batches.delete(batchId: _batchOneId, deletedAt: _updatedAt);
      expect(await batches.findActiveById(_batchOneId), isNull);

      await batches.rename(
        batchId: _batchTwoId,
        name: 'Corrected batch name',
        updatedAt: _updatedAt,
      );
      expect(
        (await batches.findActiveById(_batchTwoId))?.name,
        'Corrected batch name',
      );

      await scans.create(_scan(id: _scanTwoId, batchId: _batchTwoId));
      await orders.create(_order(id: _orderOneId, batchId: _batchTwoId));
      await orders.complete(batchId: _batchTwoId, updatedAt: _updatedAt);

      await expectLater(
        scans.deleteActive(scanId: _scanTwoId, deletedAt: _updatedAt),
        throwsStateError,
      );
      await expectLater(
        batches.removeScan(scanId: _scanTwoId, updatedAt: _updatedAt),
        throwsStateError,
      );
      await expectLater(
        batches.rename(
          batchId: _batchTwoId,
          name: 'Blocked rename',
          updatedAt: _updatedAt,
        ),
        throwsStateError,
      );
      await expectLater(
        batches.changeFruitType(
          batchId: _batchTwoId,
          fruit: FruitIdentifier.redPapaya,
          updatedAt: _updatedAt,
        ),
        throwsStateError,
      );
      expect((await scans.findActiveById(_scanTwoId))?.batchId, _batchTwoId);
    },
  );

  test(
    'completed batch deletion soft-deletes order, scans, and batch',
    () async {
      await batches.create(_batch(id: _batchOneId));
      await scans.create(_scan(id: _scanOneId, batchId: _batchOneId));
      await orders.create(_order(id: _orderOneId, batchId: _batchOneId));
      await orders.complete(batchId: _batchOneId, updatedAt: _updatedAt);

      final deleted = await batches.deleteCompletedWithScans(
        batchId: _batchOneId,
        deletedAt: DateTime.utc(2026, 8, 1),
      );

      expect(deleted.map((scan) => scan.id), [_scanOneId]);
      expect(await batches.findActiveById(_batchOneId), isNull);
      expect(await scans.findActiveById(_scanOneId), isNull);
      expect(await orders.findActiveForBatch(_batchOneId), isNull);
    },
  );

  test(
    'orders require saved scans, allow Pending edits, and complete once',
    () async {
      await batches.create(_batch(id: _batchOneId));
      await expectLater(
        orders.create(_order(id: _orderOneId, batchId: _batchOneId)),
        throwsStateError,
      );

      await scans.create(_scan(id: _scanOneId, batchId: _batchOneId));
      await orders.create(_order(id: _orderOneId, batchId: _batchOneId));
      final pending = (await orders.findActiveForBatch(_batchOneId))!;
      await orders.updatePending(
        BatchOrder(
          id: pending.id,
          ownerId: pending.ownerId,
          batchId: pending.batchId,
          customerName: 'Updated customer',
          deliveryAddress: 'Updated address',
          deliveryDate: DateTime.utc(2026, 8, 2),
          status: BatchOrderStatus.pending,
          createdAt: pending.createdAt,
          updatedAt: _updatedAt,
          syncState: pending.syncState,
        ),
      );
      expect(
        (await orders.findActiveForBatch(_batchOneId))?.customerName,
        'Updated customer',
      );

      final completed = await orders.complete(
        batchId: _batchOneId,
        updatedAt: _updatedAt,
      );
      expect(completed.status, BatchOrderStatus.completed);
      await expectLater(
        orders.complete(batchId: _batchOneId, updatedAt: _updatedAt),
        throwsStateError,
      );
    },
  );

  test(
    'Pending orders keep their final scan until the order is canceled',
    () async {
      await batches.create(_batch(id: _batchThreeId));
      await scans.create(_scan(id: _scanThreeId, batchId: _batchThreeId));
      await orders.create(_order(id: _orderTwoId, batchId: _batchThreeId));

      await expectLater(
        scans.deleteActive(scanId: _scanThreeId, deletedAt: _updatedAt),
        throwsStateError,
      );
      await expectLater(
        batches.removeScan(scanId: _scanThreeId, updatedAt: _updatedAt),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        batches.moveScan(
          scanId: _scanThreeId,
          targetBatchId: _batchOneId,
          updatedAt: _updatedAt,
        ),
        throwsA(isA<Exception>()),
      );

      await orders.cancel(batchId: _batchThreeId, updatedAt: _updatedAt);
      expect(await orders.findActiveForBatch(_batchThreeId), isNull);
      await expectLater(
        scans.deleteActive(scanId: _scanThreeId, deletedAt: _updatedAt),
        throwsStateError,
      );
      await expectLater(
        scans.deleteActiveMany(scanIds: [_scanThreeId], deletedAt: _updatedAt),
        throwsStateError,
      );
      await batches.removeScan(scanId: _scanThreeId, updatedAt: _updatedAt);
      await scans.deleteActive(scanId: _scanThreeId, deletedAt: _updatedAt);
      await batches.delete(batchId: _batchThreeId, deletedAt: _updatedAt);
      expect(await batches.findActiveById(_batchThreeId), isNull);
    },
  );

  test(
    'a canceled Pending order can be replaced without changing the batch',
    () async {
      await batches.create(_batch(id: _batchOneId));
      await scans.create(_scan(id: _scanOneId, batchId: _batchOneId));
      await orders.create(_order(id: _orderOneId, batchId: _batchOneId));

      await orders.cancel(batchId: _batchOneId, updatedAt: _updatedAt);
      await orders.create(_order(id: _orderTwoId, batchId: _batchOneId));

      expect((await orders.findActiveForBatch(_batchOneId))?.id, _orderTwoId);
      expect((await scans.findActiveById(_scanOneId))?.batchId, _batchOneId);
    },
  );

  test('foreign keys and singleton app settings are enforced', () async {
    await expectLater(
      database
          .into(database.orders)
          .insert(
            OrdersCompanion.insert(
              id: _orderOneId,
              batchId: _batchOneId,
              customerName: 'Synthetic customer',
              deliveryAddress: 'Synthetic delivery location',
              deliveryDate: DateTime.utc(2026, 8, 1),
              status: PersistenceCodecs.encodeOrderStatus(
                BatchOrderStatus.pending,
              ),
              createdAt: _createdAt,
              updatedAt: _createdAt,
            ),
          ),
      throwsA(anything),
    );

    await database
        .into(database.appSettings)
        .insert(
          const AppSettingsCompanion(
            id: Value(1),
            imageUploadConsent: Value(false),
            consentVersion: Value('consent-v1'),
          ),
        );
    await expectLater(
      database
          .into(database.appSettings)
          .insert(const AppSettingsCompanion(id: Value(2))),
      throwsA(anything),
    );
  });
}

SavedScanRecord _scan({
  required String id,
  String? ownerId,
  String? batchId,
  FruitIdentifier fruit = FruitIdentifier.carabaoMango,
  RipenessStage ripeness = RipenessStage.ripe,
  ShelfLifeEstimate shelfLife = const ShelfLifeRange(
    minimum: 2,
    maximum: 4,
    unit: 'days',
    storageGuidance: 'Synthetic test guidance.',
    evidenceVersion: 'evidence-v1',
  ),
  String? localImageRelativePath = 'retained/scans/example.jpg',
  DateTime? createdAt,
  DateTime? deletedAt,
}) {
  final savedAt = createdAt ?? _createdAt;
  return SavedScanRecord(
    id: id,
    ownerId: ownerId,
    batchId: batchId,
    fruit: fruit,
    ripeness: ripeness,
    modelConfidence: 0.91,
    modelVersion: 'synthetic-model-v1',
    resultOrigin: ResultOrigin.onDeviceModel,
    shelfLife: shelfLife,
    localImageRelativePath: localImageRelativePath,
    createdAt: savedAt,
    updatedAt: savedAt,
    deletedAt: deletedAt,
    syncState: LocalSyncState.localOnly,
  );
}

FruitBatch _batch({
  required String id,
  String? ownerId,
  FruitIdentifier fruit = FruitIdentifier.carabaoMango,
}) {
  return FruitBatch(
    id: id,
    ownerId: ownerId,
    name: 'Synthetic batch',
    fruit: fruit,
    createdAt: _createdAt,
    updatedAt: _createdAt,
    syncState: LocalSyncState.localOnly,
  );
}

BatchOrder _order({
  required String id,
  required String batchId,
  String? ownerId,
  BatchOrderStatus status = BatchOrderStatus.pending,
}) {
  return BatchOrder(
    id: id,
    ownerId: ownerId,
    batchId: batchId,
    customerName: 'Synthetic customer',
    deliveryAddress: 'Synthetic delivery location',
    deliveryDate: DateTime.utc(2026, 8, 1),
    status: status,
    createdAt: _createdAt,
    updatedAt: _createdAt,
    syncState: ownerId == null
        ? LocalSyncState.localOnly
        : LocalSyncState.pending,
  );
}

ScanRecordsCompanion _scanCompanion({
  required String id,
  String fruitType = 'carabao_mango',
  String ripenessStage = 'ripe',
  String shelfLifeStatus = PersistenceCodecs.shelfLifeAvailable,
  Value<int?> shelfLifeMinimum = const Value(2),
  Value<int?> shelfLifeMaximum = const Value(4),
  Value<String?> shelfLifeUnit = const Value('days'),
  Value<String?> shelfLifeGuidance = const Value('Synthetic test guidance.'),
  Value<String?> shelfLifeReason = const Value(null),
  Value<String> resultOrigin = const Value('demo'),
}) {
  return ScanRecordsCompanion.insert(
    id: id,
    fruitType: fruitType,
    ripenessStage: ripenessStage,
    modelConfidence: 0.91,
    modelVersion: 'synthetic-model-v1',
    resultOrigin: resultOrigin,
    shelfLifeStatus: shelfLifeStatus,
    shelfLifeMinimum: shelfLifeMinimum,
    shelfLifeMaximum: shelfLifeMaximum,
    shelfLifeUnit: shelfLifeUnit,
    shelfLifeGuidance: shelfLifeGuidance,
    shelfLifeReason: shelfLifeReason,
    shelfLifeEvidenceVersion: 'evidence-v1',
    createdAt: _createdAt,
    updatedAt: _createdAt,
  );
}
