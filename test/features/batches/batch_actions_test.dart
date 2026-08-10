import 'package:flutter_test/flutter_test.dart';
import 'package:kami/core/persistence/entity_id_generator.dart';
import 'package:kami/core/persistence/local_sync_state.dart';
import 'package:kami/features/batches/application/batch_actions.dart';
import 'package:kami/features/batches/domain/fruit_batch.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

import '../../helpers/fake_batch_repository.dart';
import '../../helpers/fake_history_storage.dart';

const _batchId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _otherBatchId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const _scanId = '11111111-1111-4111-8111-111111111111';
const _secondScanId = '22222222-2222-4222-8222-222222222222';
const _otherFruitScanId = '33333333-3333-4333-8333-333333333333';
final _now = DateTime.utc(2026, 7, 31, 12);

void main() {
  test('creates a trimmed empty batch', () async {
    final scans = FakeScanRecordRepository();
    final batches = FakeBatchRepository(scans);
    addTearDown(scans.dispose);
    addTearDown(batches.dispose);
    final useCase = CreateBatchUseCase(
      batches,
      const _FixedIdGenerator(),
      () => _now,
    );

    final batch = await useCase.execute(
      name: '  Market mangoes  ',
      fruit: FruitIdentifier.carabaoMango,
    );

    expect(batch.id, _batchId);
    expect(batch.name, 'Market mangoes');
    expect(batch.syncState, LocalSyncState.localOnly);
    expect((await batches.listActive()).single.id, _batchId);
  });

  test('creates and assigns a new batch from a saved scan', () async {
    final scans = FakeScanRecordRepository(initialRecords: [_scan()]);
    final batches = FakeBatchRepository(scans);
    addTearDown(scans.dispose);
    addTearDown(batches.dispose);
    final useCase = CreateBatchUseCase(
      batches,
      const _FixedIdGenerator(),
      () => _now,
    );

    await useCase.execute(
      name: 'New batch',
      fruit: FruitIdentifier.carabaoMango,
      scanId: _scanId,
    );

    expect((await scans.findActiveById(_scanId))?.batchId, _batchId);
    expect(batches.createCalls, 1);
  });

  test('creates and assigns a new batch from multiple saved scans', () async {
    final scans = FakeScanRecordRepository(
      initialRecords: [
        _scan(),
        _scan(id: _secondScanId),
      ],
    );
    final batches = FakeBatchRepository(scans);
    addTearDown(scans.dispose);
    addTearDown(batches.dispose);
    final useCase = CreateBatchUseCase(
      batches,
      const _FixedIdGenerator(),
      () => _now,
    );

    await useCase.execute(
      name: 'New batch',
      fruit: FruitIdentifier.carabaoMango,
      scanIds: [_scanId, _secondScanId],
    );

    expect((await scans.findActiveById(_scanId))?.batchId, _batchId);
    expect((await scans.findActiveById(_secondScanId))?.batchId, _batchId);
    expect(batches.createCalls, 1);
  });

  test('adds multiple eligible scans atomically to one batch', () async {
    final scans = FakeScanRecordRepository(
      initialRecords: [
        _scan(),
        _scan(id: _secondScanId),
        _scan(id: _otherFruitScanId, fruit: FruitIdentifier.redPapaya),
      ],
    );
    final batches = FakeBatchRepository(
      scans,
      initialBatches: [_batch(_batchId)],
    );
    addTearDown(scans.dispose);
    addTearDown(batches.dispose);

    await AddScansToBatchUseCase(
      batches,
      () => _now,
    ).execute(scanIds: [_scanId, _secondScanId], batchId: _batchId);

    expect((await scans.findActiveById(_scanId))?.batchId, _batchId);
    expect((await scans.findActiveById(_secondScanId))?.batchId, _batchId);
    expect((await scans.findActiveById(_otherFruitScanId))?.batchId, isNull);

    await expectLater(
      AddScansToBatchUseCase(batches, () => _now).execute(
        scanIds: [_otherFruitScanId, '44444444-4444-4444-8444-444444444444'],
        batchId: _batchId,
      ),
      throwsA(isA<BatchActionException>()),
    );
    expect((await scans.findActiveById(_otherFruitScanId))?.batchId, isNull);
  });

  test('rejects a blank name without writing', () async {
    final scans = FakeScanRecordRepository();
    final batches = FakeBatchRepository(scans);
    addTearDown(scans.dispose);
    addTearDown(batches.dispose);
    final useCase = CreateBatchUseCase(
      batches,
      const _FixedIdGenerator(),
      () => _now,
    );

    await expectLater(
      useCase.execute(name: '   ', fruit: FruitIdentifier.carabaoMango),
      throwsA(
        isA<BatchActionException>().having(
          (error) => error.message,
          'message',
          'Enter a batch name.',
        ),
      ),
    );
    expect(batches.createCalls, 0);
  });

  test('renames, moves, removes, and deletes eligible local batches', () async {
    final scans = FakeScanRecordRepository(
      initialRecords: [_scan(batchId: _batchId)],
    );
    final batches = FakeBatchRepository(
      scans,
      initialBatches: [_batch(_batchId), _batch(_otherBatchId)],
    );
    addTearDown(scans.dispose);
    addTearDown(batches.dispose);

    await RenameBatchUseCase(
      batches,
      () => _now,
    ).execute(batchId: _batchId, name: '  Revised mangoes  ');
    expect((await batches.findActiveById(_batchId))?.name, 'Revised mangoes');

    await MoveScanToBatchUseCase(
      batches,
      () => _now,
    ).execute(scanId: _scanId, targetBatchId: _otherBatchId);
    expect((await scans.findActiveById(_scanId))?.batchId, _otherBatchId);

    await RemoveScanFromBatchUseCase(
      batches,
      () => _now,
    ).execute(scanId: _scanId);
    expect((await scans.findActiveById(_scanId))?.batchId, isNull);

    await DeleteBatchUseCase(
      batches,
      FakeRetainedScanImageStore(),
      () => _now,
    ).execute(batchId: _otherBatchId);
    expect(await batches.findActiveById(_otherBatchId), isNull);
  });

  test('changes the fruit type of an empty batch', () async {
    final scans = FakeScanRecordRepository();
    final batches = FakeBatchRepository(
      scans,
      initialBatches: [_batch(_batchId)],
    );
    addTearDown(scans.dispose);
    addTearDown(batches.dispose);

    await ChangeBatchFruitTypeUseCase(
      batches,
      () => _now,
    ).execute(batchId: _batchId, fruit: FruitIdentifier.redPapaya);

    expect(
      (await batches.findActiveById(_batchId))?.fruit,
      FruitIdentifier.redPapaya,
    );
  });

  test('withholds fruit-type changes for non-empty batches', () async {
    final scans = FakeScanRecordRepository(
      initialRecords: [_scan(batchId: _batchId)],
    );
    final batches = FakeBatchRepository(
      scans,
      initialBatches: [_batch(_batchId)],
    );
    addTearDown(scans.dispose);
    addTearDown(batches.dispose);

    await expectLater(
      ChangeBatchFruitTypeUseCase(
        batches,
        () => _now,
      ).execute(batchId: _batchId, fruit: FruitIdentifier.redPapaya),
      throwsA(
        isA<BatchActionException>().having(
          (error) => error.message,
          'message',
          'Kami could not change the fruit type. The batch was not changed.',
        ),
      ),
    );
    expect(
      (await batches.findActiveById(_batchId))?.fruit,
      FruitIdentifier.carabaoMango,
    );
  });

  test(
    'deletes a completed batch with its scans and retained images',
    () async {
      final scans = FakeScanRecordRepository(
        initialRecords: [_scan(batchId: _batchId)],
      );
      final batches = FakeBatchRepository(
        scans,
        initialBatches: [_batch(_batchId)],
      );
      final images = FakeRetainedScanImageStore();
      addTearDown(scans.dispose);
      addTearDown(batches.dispose);
      await DeleteBatchUseCase(
        batches,
        images,
        () => _now,
      ).execute(batchId: _batchId, deleteCompletedWithScans: true);
      expect(await batches.findActiveById(_batchId), isNull);
      expect(await scans.listActive(), isEmpty);
      expect(images.removedPaths, ['history_images/$_scanId.jpg']);
    },
  );
}

SavedScanRecord _scan({
  String id = _scanId,
  String? batchId,
  FruitIdentifier fruit = FruitIdentifier.carabaoMango,
}) {
  return SavedScanRecord(
    id: id,
    batchId: batchId,
    fruit: fruit,
    ripeness: RipenessStage.ripe,
    modelConfidence: 0.87,
    modelVersion: 'fake-foundation-v1',
    resultOrigin: ResultOrigin.demo,
    shelfLife: const ShelfLifeUnavailable(
      reason: 'No reviewed guidance is available.',
      evidenceVersion: 'unavailable-v1',
    ),
    localImageRelativePath: 'history_images/$id.jpg',
    createdAt: _now,
    updatedAt: _now,
    syncState: LocalSyncState.localOnly,
  );
}

FruitBatch _batch(String id) {
  return FruitBatch(
    id: id,
    name: 'Synthetic mangoes',
    fruit: FruitIdentifier.carabaoMango,
    createdAt: _now,
    updatedAt: _now,
    syncState: LocalSyncState.localOnly,
  );
}

final class _FixedIdGenerator implements EntityIdGenerator {
  const _FixedIdGenerator();

  @override
  String nextId() => _batchId;
}
