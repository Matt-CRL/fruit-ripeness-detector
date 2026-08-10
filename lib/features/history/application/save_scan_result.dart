import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/core/persistence/local_sync_state.dart';
import 'package:kami/features/history/data/app_private_retained_scan_image_store.dart';
import 'package:kami/features/history/data/drift_scan_record_repository.dart';
import 'package:kami/features/history/domain/retained_scan_image_store.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/history/domain/scan_record_repository.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

typedef UtcNow = DateTime Function();

final utcNowProvider = Provider<UtcNow>(
  (ref) =>
      () => DateTime.now().toUtc(),
);

final saveScanResultUseCaseProvider = Provider<SaveScanResultUseCase>((ref) {
  return SaveScanResultUseCase(
    ref.watch(scanRecordRepositoryProvider),
    ref.watch(retainedScanImageStoreProvider),
    ref.watch(utcNowProvider),
  );
});

final class SaveScanResultUseCase {
  const SaveScanResultUseCase(this._repository, this._imageStore, this._utcNow);

  final ScanRecordRepository _repository;
  final RetainedScanImageStore _imageStore;
  final UtcNow _utcNow;

  Future<SavedScanRecord> execute({
    required ScanPreview preview,
    required String scanId,
  }) async {
    if (preview.classification.requiresRetake) {
      throw const SaveScanResultException(
        'Low-confidence previews cannot be saved.',
      );
    }

    final existing = await _repository.findActiveById(scanId);
    if (existing != null) {
      return existing;
    }

    final retained = await _imageStore.retain(
      sourcePath: preview.image.path,
      scanId: scanId,
    );
    final now = _utcNow();
    final record = SavedScanRecord(
      id: scanId,
      fruit: preview.classification.fruit,
      ripeness: preview.classification.ripeness,
      modelConfidence: preview.classification.modelConfidence,
      modelVersion: preview.classification.modelVersion,
      resultOrigin: preview.classification.origin,
      shelfLife: preview.shelfLife,
      localImageRelativePath: retained.relativePath,
      createdAt: now,
      updatedAt: now,
      syncState: LocalSyncState.localOnly,
    );

    try {
      await _repository.create(record);
      return record;
    } on Object catch (databaseError) {
      try {
        await _imageStore.remove(retained.relativePath);
      } on Object catch (cleanupError) {
        throw SaveScanResultException(
          'The scan was not saved, and its temporary history image could not '
          'be cleaned up. Database error: $databaseError. Cleanup error: '
          '$cleanupError.',
        );
      }
      throw SaveScanResultException(
        'The scan was not saved to local storage: $databaseError',
      );
    }
  }
}

final class SaveScanResultException implements Exception {
  const SaveScanResultException(this.message);

  final String message;

  @override
  String toString() => 'SaveScanResultException: $message';
}
