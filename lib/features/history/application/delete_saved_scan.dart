import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/features/batches/domain/batch_repository.dart';
import 'package:kami/features/history/application/save_scan_result.dart';
import 'package:kami/features/history/data/app_private_retained_scan_image_store.dart';
import 'package:kami/features/history/data/drift_scan_record_repository.dart';
import 'package:kami/features/history/domain/retained_scan_image_store.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/history/domain/scan_record_repository.dart';

final deleteSavedScanUseCaseProvider = Provider<DeleteSavedScanUseCase>((ref) {
  return DeleteSavedScanUseCase(
    ref.watch(scanRecordRepositoryProvider),
    ref.watch(retainedScanImageStoreProvider),
    ref.watch(utcNowProvider),
  );
});

final class DeletedSavedScan {
  const DeletedSavedScan({required this.record, required this.imageRemoved});

  final SavedScanRecord record;
  final bool imageRemoved;
}

final class DeletedSavedScans {
  const DeletedSavedScans({
    required this.records,
    required this.removedImageCount,
  });

  final List<SavedScanRecord> records;
  final int removedImageCount;
}

final class DeleteSavedScanUseCase {
  const DeleteSavedScanUseCase(
    this._repository,
    this._imageStore,
    this._utcNow,
  );

  final ScanRecordRepository _repository;
  final RetainedScanImageStore _imageStore;
  final UtcNow _utcNow;

  Future<DeletedSavedScan> execute({required String scanId}) async {
    final record = await _deleteRecord(scanId);
    final relativePath = record.localImageRelativePath;
    if (relativePath == null) {
      return DeletedSavedScan(record: record, imageRemoved: true);
    }

    try {
      await _imageStore.remove(relativePath);
      return DeletedSavedScan(record: record, imageRemoved: true);
    } on Object {
      // The record is already safely absent from active History. Do not
      // resurrect it merely because private-file cleanup failed.
      return DeletedSavedScan(record: record, imageRemoved: false);
    }
  }

  Future<DeletedSavedScans> executeMany({
    required Iterable<String> scanIds,
  }) async {
    final ids = scanIds.toSet();
    if (ids.isEmpty) {
      return const DeletedSavedScans(records: [], removedImageCount: 0);
    }

    final records = await _deleteRecords(ids);
    var removedImageCount = 0;
    for (final record in records) {
      final relativePath = record.localImageRelativePath;
      if (relativePath == null) {
        removedImageCount += 1;
        continue;
      }
      try {
        await _imageStore.remove(relativePath);
        removedImageCount += 1;
      } on Object {
        // The records are already safely absent from active History. Do not
        // resurrect them merely because private-file cleanup failed.
      }
    }
    return DeletedSavedScans(
      records: records,
      removedImageCount: removedImageCount,
    );
  }

  Future<SavedScanRecord> _deleteRecord(String scanId) async {
    try {
      return await _repository.deleteActive(
        scanId: scanId,
        deletedAt: _utcNow(),
      );
    } on PendingOrderBatchException {
      throw const ScanManagementException(PendingOrderBatchException.message);
    } on Object {
      throw const ScanManagementException(
        'Chami could not delete this saved scan. It is still available in '
        'History.',
      );
    }
  }

  Future<List<SavedScanRecord>> _deleteRecords(Iterable<String> scanIds) async {
    try {
      return await _repository.deleteActiveMany(
        scanIds: scanIds,
        deletedAt: _utcNow(),
      );
    } on PendingOrderBatchException {
      throw const ScanManagementException(PendingOrderBatchException.message);
    } on Object {
      throw const ScanManagementException(
        'Chami could not delete these saved scans. They are still available in '
        'History.',
      );
    }
  }
}

final class ScanManagementException implements Exception {
  const ScanManagementException(this.message);

  final String message;

  @override
  String toString() => 'ScanManagementException: $message';
}
