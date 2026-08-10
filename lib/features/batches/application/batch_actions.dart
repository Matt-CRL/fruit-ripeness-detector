import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/core/database/app_database_provider.dart';
import 'package:kami/core/persistence/entity_id_generator.dart';
import 'package:kami/core/persistence/local_sync_state.dart';
import 'package:kami/features/batches/data/drift_batch_repository.dart';
import 'package:kami/features/batches/domain/batch_repository.dart';
import 'package:kami/features/batches/domain/fruit_batch.dart';
import 'package:kami/features/history/data/app_private_retained_scan_image_store.dart';
import 'package:kami/features/history/domain/retained_scan_image_store.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

typedef BatchUtcNow = DateTime Function();

final batchUtcNowProvider = Provider<BatchUtcNow>(
  (ref) =>
      () => DateTime.now().toUtc(),
);

final createBatchUseCaseProvider = Provider<CreateBatchUseCase>((ref) {
  return CreateBatchUseCase(
    ref.watch(batchRepositoryProvider),
    ref.watch(entityIdGeneratorProvider),
    ref.watch(batchUtcNowProvider),
  );
});

final addScanToBatchUseCaseProvider = Provider<AddScanToBatchUseCase>((ref) {
  return AddScanToBatchUseCase(
    ref.watch(batchRepositoryProvider),
    ref.watch(batchUtcNowProvider),
  );
});

final addScansToBatchUseCaseProvider = Provider<AddScansToBatchUseCase>((ref) {
  return AddScansToBatchUseCase(
    ref.watch(batchRepositoryProvider),
    ref.watch(batchUtcNowProvider),
  );
});

final removeScanFromBatchUseCaseProvider = Provider<RemoveScanFromBatchUseCase>(
  (ref) {
    return RemoveScanFromBatchUseCase(
      ref.watch(batchRepositoryProvider),
      ref.watch(batchUtcNowProvider),
    );
  },
);

final removeScansFromBatchUseCaseProvider =
    Provider<RemoveScansFromBatchUseCase>((ref) {
      return RemoveScansFromBatchUseCase(
        ref.watch(batchRepositoryProvider),
        ref.watch(batchUtcNowProvider),
      );
    });

final moveScanToBatchUseCaseProvider = Provider<MoveScanToBatchUseCase>((ref) {
  return MoveScanToBatchUseCase(
    ref.watch(batchRepositoryProvider),
    ref.watch(batchUtcNowProvider),
  );
});

final renameBatchUseCaseProvider = Provider<RenameBatchUseCase>((ref) {
  return RenameBatchUseCase(
    ref.watch(batchRepositoryProvider),
    ref.watch(batchUtcNowProvider),
  );
});

final changeBatchFruitTypeUseCaseProvider =
    Provider<ChangeBatchFruitTypeUseCase>((ref) {
      return ChangeBatchFruitTypeUseCase(
        ref.watch(batchRepositoryProvider),
        ref.watch(batchUtcNowProvider),
      );
    });

final deleteBatchUseCaseProvider = Provider<DeleteBatchUseCase>((ref) {
  return DeleteBatchUseCase(
    ref.watch(batchRepositoryProvider),
    ref.watch(retainedScanImageStoreProvider),
    ref.watch(batchUtcNowProvider),
  );
});

final class CreateBatchUseCase {
  const CreateBatchUseCase(this._repository, this._idGenerator, this._utcNow);

  final BatchRepository _repository;
  final EntityIdGenerator _idGenerator;
  final BatchUtcNow _utcNow;

  Future<FruitBatch> execute({
    required String name,
    required FruitIdentifier fruit,
    String? scanId,
    Iterable<String> scanIds = const [],
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw const BatchActionException('Enter a batch name.');
    }
    if (normalizedName.length > 120) {
      throw const BatchActionException(
        'Batch names must be 120 characters or fewer.',
      );
    }

    final now = _utcNow();
    final batch = FruitBatch(
      id: _idGenerator.nextId(),
      name: normalizedName,
      fruit: fruit,
      createdAt: now,
      updatedAt: now,
      syncState: LocalSyncState.localOnly,
    );

    final selectedScanIds = <String>{...scanIds, ?scanId};
    try {
      if (selectedScanIds.isEmpty) {
        await _repository.create(batch);
      } else {
        await _repository.createWithScans(
          batch: batch,
          scanIds: selectedScanIds,
          updatedAt: now,
        );
      }
      return batch;
    } on BatchActionException {
      rethrow;
    } on Object {
      throw const BatchActionException(
        'Kami could not create this batch. Your saved scans were not changed.',
      );
    }
  }
}

final class AddScanToBatchUseCase {
  const AddScanToBatchUseCase(this._repository, this._utcNow);

  final BatchRepository _repository;
  final BatchUtcNow _utcNow;

  Future<void> execute({
    required String scanId,
    required String batchId,
  }) async {
    try {
      await _repository.assignScan(
        scanId: scanId,
        batchId: batchId,
        updatedAt: _utcNow(),
      );
    } on Object {
      throw const BatchActionException(
        'Kami could not add this scan to the batch. The scan remains safely '
        'saved in History.',
      );
    }
  }
}

final class AddScansToBatchUseCase {
  const AddScansToBatchUseCase(this._repository, this._utcNow);

  final BatchRepository _repository;
  final BatchUtcNow _utcNow;

  Future<void> execute({
    required Iterable<String> scanIds,
    required String batchId,
  }) async {
    final ids = scanIds.toSet().toList(growable: false);
    if (ids.isEmpty) {
      throw const BatchActionException('Select at least one saved scan.');
    }
    try {
      await _repository.assignScans(
        scanIds: ids,
        batchId: batchId,
        updatedAt: _utcNow(),
      );
    } on Object {
      throw const BatchActionException(
        'Kami could not add the selected scans. They were not changed. '
        'Refresh and try again.',
      );
    }
  }
}

final class RemoveScanFromBatchUseCase {
  const RemoveScanFromBatchUseCase(this._repository, this._utcNow);

  final BatchRepository _repository;
  final BatchUtcNow _utcNow;

  Future<void> execute({required String scanId}) async {
    try {
      await _repository.removeScan(scanId: scanId, updatedAt: _utcNow());
    } on PendingOrderBatchException {
      throw const BatchActionException(PendingOrderBatchException.message);
    } on Object {
      throw const BatchActionException(
        'Kami could not remove this scan from the batch. It is still in its '
        'current batch.',
      );
    }
  }
}

final class RemoveScansFromBatchUseCase {
  const RemoveScansFromBatchUseCase(this._repository, this._utcNow);

  final BatchRepository _repository;
  final BatchUtcNow _utcNow;

  Future<void> execute({required Iterable<String> scanIds}) async {
    final ids = scanIds.toSet().toList(growable: false);
    if (ids.isEmpty) {
      throw const BatchActionException('Select at least one saved scan.');
    }
    try {
      await _repository.removeScans(scanIds: ids, updatedAt: _utcNow());
    } on PendingOrderBatchException {
      throw const BatchActionException(PendingOrderBatchException.message);
    } on Object {
      throw const BatchActionException(
        'Kami could not remove the selected scans. They remain in their '
        'current batch. Refresh and try again.',
      );
    }
  }
}

final class MoveScanToBatchUseCase {
  const MoveScanToBatchUseCase(this._repository, this._utcNow);

  final BatchRepository _repository;
  final BatchUtcNow _utcNow;

  Future<void> execute({
    required String scanId,
    required String targetBatchId,
  }) async {
    try {
      await _repository.moveScan(
        scanId: scanId,
        targetBatchId: targetBatchId,
        updatedAt: _utcNow(),
      );
    } on PendingOrderBatchException {
      throw const BatchActionException(PendingOrderBatchException.message);
    } on Object {
      throw const BatchActionException(
        'Kami could not move this scan. It remains in its current batch.',
      );
    }
  }
}

final class RenameBatchUseCase {
  const RenameBatchUseCase(this._repository, this._utcNow);

  final BatchRepository _repository;
  final BatchUtcNow _utcNow;

  Future<void> execute({required String batchId, required String name}) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw const BatchActionException('Enter a batch name.');
    }
    if (normalizedName.length > 120) {
      throw const BatchActionException(
        'Batch names must be 120 characters or fewer.',
      );
    }

    try {
      await _repository.rename(
        batchId: batchId,
        name: normalizedName,
        updatedAt: _utcNow(),
      );
    } on BatchActionException {
      rethrow;
    } on Object {
      throw const BatchActionException(
        'Kami could not rename this batch. Its current name was kept.',
      );
    }
  }
}

final class ChangeBatchFruitTypeUseCase {
  const ChangeBatchFruitTypeUseCase(this._repository, this._utcNow);

  final BatchRepository _repository;
  final BatchUtcNow _utcNow;

  Future<void> execute({
    required String batchId,
    required FruitIdentifier fruit,
  }) async {
    try {
      await _repository.changeFruitType(
        batchId: batchId,
        fruit: fruit,
        updatedAt: _utcNow(),
      );
    } on BatchActionException {
      rethrow;
    } on Object {
      throw const BatchActionException(
        'Kami could not change the fruit type. The batch was not changed.',
      );
    }
  }
}

final class DeleteBatchUseCase {
  const DeleteBatchUseCase(this._repository, this._imageStore, this._utcNow);

  final BatchRepository _repository;
  final RetainedScanImageStore _imageStore;
  final BatchUtcNow _utcNow;

  Future<void> execute({
    required String batchId,
    bool deleteCompletedWithScans = false,
  }) async {
    try {
      final deletedScans = deleteCompletedWithScans
          ? await _repository.deleteCompletedWithScans(
              batchId: batchId,
              deletedAt: _utcNow(),
            )
          : <SavedScanRecord>[];
      if (!deleteCompletedWithScans) {
        await _repository.delete(batchId: batchId, deletedAt: _utcNow());
      }
      for (final scan in deletedScans) {
        final path = scan.localImageRelativePath;
        if (path == null) {
          continue;
        }
        try {
          await _imageStore.remove(path);
        } on Object {
          // The records are already safely absent. Do not resurrect them
          // because a retained-image cleanup failed.
        }
      }
    } on Object {
      throw const BatchActionException('Kami could not delete this batch.');
    }
  }
}

final class BatchActionException implements Exception {
  const BatchActionException(this.message);

  final String message;

  @override
  String toString() => 'BatchActionException: $message';
}
