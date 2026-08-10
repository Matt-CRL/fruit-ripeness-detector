import 'package:flutter_test/flutter_test.dart';
import 'package:kami/features/history/application/save_scan_result.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

import '../../helpers/fake_history_storage.dart';

const _scanId = '11111111-1111-4111-8111-111111111111';
final _now = DateTime.utc(2026, 7, 31, 12);

void main() {
  test('saves an immutable Demo snapshot after retaining its image', () async {
    final repository = FakeScanRecordRepository();
    final images = FakeRetainedScanImageStore();
    addTearDown(repository.dispose);
    final useCase = SaveScanResultUseCase(repository, images, () => _now);

    final record = await useCase.execute(preview: _preview, scanId: _scanId);

    expect(record.id, _scanId);
    expect(record.resultOrigin, ResultOrigin.demo);
    expect(record.localImageRelativePath, 'history_images/$_scanId.jpg');
    expect(record.createdAt, _now);
    expect(repository.createCalls, 1);
    expect(images.retainCalls, 1);
    expect(images.removedPaths, isEmpty);
  });

  test('database failure compensates the newly retained image', () async {
    final repository = FakeScanRecordRepository()..failCreates = true;
    final images = FakeRetainedScanImageStore();
    addTearDown(repository.dispose);
    final useCase = SaveScanResultUseCase(repository, images, () => _now);

    await expectLater(
      useCase.execute(preview: _preview, scanId: _scanId),
      throwsA(isA<SaveScanResultException>()),
    );

    expect(await repository.listActive(), isEmpty);
    expect(images.removedPaths, ['history_images/$_scanId.jpg']);
  });

  test('an existing scan ID is idempotent and does not retain again', () async {
    final repository = FakeScanRecordRepository();
    final images = FakeRetainedScanImageStore();
    addTearDown(repository.dispose);
    final useCase = SaveScanResultUseCase(repository, images, () => _now);
    final first = await useCase.execute(preview: _preview, scanId: _scanId);

    final second = await useCase.execute(preview: _preview, scanId: _scanId);

    expect(second, same(first));
    expect(repository.createCalls, 1);
    expect(images.retainCalls, 1);
  });

  test(
    'cleanup failure is reported without claiming database success',
    () async {
      final repository = FakeScanRecordRepository()..failCreates = true;
      final images = FakeRetainedScanImageStore()..failRemove = true;
      addTearDown(repository.dispose);
      final useCase = SaveScanResultUseCase(repository, images, () => _now);

      await expectLater(
        useCase.execute(preview: _preview, scanId: _scanId),
        throwsA(
          isA<SaveScanResultException>().having(
            (failure) => failure.message,
            'message',
            contains('could not be cleaned up'),
          ),
        ),
      );

      expect(await repository.listActive(), isEmpty);
      expect(images.removedPaths, ['history_images/$_scanId.jpg']);
    },
  );
}

const _preview = ScanPreview(
  image: SelectedScanImage(path: '/virtual/mango.png', name: 'mango.png'),
  classification: ClassificationResult(
    fruit: FruitIdentifier.carabaoMango,
    ripeness: RipenessStage.ripe,
    modelConfidence: 0.87,
    modelVersion: 'fake-foundation-v1',
    origin: ResultOrigin.demo,
    requiresRetake: false,
  ),
  shelfLife: ShelfLifeUnavailable(
    reason: 'No reviewed guidance is available.',
    evidenceVersion: 'unavailable-v1',
  ),
);
