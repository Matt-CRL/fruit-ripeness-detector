import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/features/history/data/drift_scan_record_repository.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/history/domain/scan_record_repository.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

typedef SavedScanAdjustmentUtcNow = DateTime Function();

final savedScanAdjustmentUtcNowProvider = Provider<SavedScanAdjustmentUtcNow>(
  (ref) =>
      () => DateTime.now().toUtc(),
);

final adjustSavedScanRipenessUseCaseProvider =
    Provider<AdjustSavedScanRipenessUseCase>((ref) {
      return AdjustSavedScanRipenessUseCase(
        ref.watch(scanRecordRepositoryProvider),
        ref.watch(savedScanAdjustmentUtcNowProvider),
      );
    });

final class AdjustSavedScanRipenessUseCase {
  const AdjustSavedScanRipenessUseCase(this._repository, this._utcNow);

  final ScanRecordRepository _repository;
  final SavedScanAdjustmentUtcNow _utcNow;

  Future<SavedScanRecord> execute({
    required String scanId,
    required RipenessStage ripeness,
    required String modelVersion,
    required ShelfLifeEstimate shelfLife,
    DateTime? expectedUpdatedAt,
  }) async {
    try {
      return await _repository.updateRipeness(
        scanId: scanId,
        ripeness: ripeness,
        modelVersion: modelVersion,
        shelfLife: shelfLife,
        updatedAt: _utcNow(),
        expectedUpdatedAt: expectedUpdatedAt,
        updateSource: RipenessUpdateSource.manual,
      );
    } on SavedScanRipenessAdjustmentException {
      rethrow;
    } on Object {
      throw const SavedScanRipenessAdjustmentException(
        'Chami could not update the saved ripeness. The previous assessment '
        'was kept.',
      );
    }
  }
}

final class SavedScanRipenessAdjustmentException implements Exception {
  const SavedScanRipenessAdjustmentException(this.message);

  final String message;

  @override
  String toString() => 'SavedScanRipenessAdjustmentException: $message';
}
