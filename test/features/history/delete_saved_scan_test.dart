import 'package:flutter_test/flutter_test.dart';
import 'package:kami/core/persistence/local_sync_state.dart';
import 'package:kami/features/history/application/delete_saved_scan.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

import '../../helpers/fake_history_storage.dart';

const _scanId = '11111111-1111-4111-8111-111111111111';
final _now = DateTime.utc(2026, 8, 2, 12);

void main() {
  test('soft-deletes the active scan and removes its private image', () async {
    final repository = FakeScanRecordRepository(initialRecords: [_scan()]);
    final images = FakeRetainedScanImageStore();
    addTearDown(repository.dispose);
    final useCase = DeleteSavedScanUseCase(repository, images, () => _now);

    final deleted = await useCase.execute(scanId: _scanId);

    expect(deleted.record.id, _scanId);
    expect(deleted.imageRemoved, isTrue);
    expect(await repository.findActiveById(_scanId), isNull);
    expect(images.removedPaths, ['history_images/$_scanId.jpg']);
  });

  test(
    'keeps the active record absent when private-image cleanup fails',
    () async {
      final repository = FakeScanRecordRepository(initialRecords: [_scan()]);
      final images = FakeRetainedScanImageStore()..failRemove = true;
      addTearDown(repository.dispose);
      final useCase = DeleteSavedScanUseCase(repository, images, () => _now);

      final deleted = await useCase.execute(scanId: _scanId);

      expect(deleted.imageRemoved, isFalse);
      expect(await repository.findActiveById(_scanId), isNull);
      expect(images.removedPaths, ['history_images/$_scanId.jpg']);
    },
  );

  test(
    'keeps the scan and image untouched when database deletion fails',
    () async {
      final repository = FakeScanRecordRepository(initialRecords: [_scan()])
        ..failDeletes = true;
      final images = FakeRetainedScanImageStore();
      addTearDown(repository.dispose);
      final useCase = DeleteSavedScanUseCase(repository, images, () => _now);

      await expectLater(
        useCase.execute(scanId: _scanId),
        throwsA(isA<ScanManagementException>()),
      );

      expect(await repository.findActiveById(_scanId), isNotNull);
      expect(images.removedPaths, isEmpty);
    },
  );

  test(
    'bulk deletion soft-deletes all scans and cleans their images',
    () async {
      const secondScanId = '22222222-2222-4222-8222-222222222222';
      final repository = FakeScanRecordRepository(
        initialRecords: [
          _scan(),
          _scan(id: secondScanId),
        ],
      );
      final images = FakeRetainedScanImageStore();
      addTearDown(repository.dispose);
      final useCase = DeleteSavedScanUseCase(repository, images, () => _now);

      final deleted = await useCase.executeMany(
        scanIds: [_scanId, secondScanId],
      );

      expect(deleted.records.map((record) => record.id), [
        _scanId,
        secondScanId,
      ]);
      expect(deleted.removedImageCount, 2);
      expect(await repository.listActive(), isEmpty);
      expect(
        images.removedPaths,
        containsAll([
          'history_images/$_scanId.jpg',
          'history_images/$secondScanId.jpg',
        ]),
      );
    },
  );
}

SavedScanRecord _scan({String id = _scanId}) {
  return SavedScanRecord(
    id: id,
    fruit: FruitIdentifier.carabaoMango,
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
