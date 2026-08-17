import 'package:kami/features/batches/domain/fruit_batch.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

abstract interface class BatchRepository {
  Future<void> create(FruitBatch batch);

  Future<void> createWithScan({
    required FruitBatch batch,
    required String scanId,
    required DateTime updatedAt,
  });

  /// Creates a batch and assigns all provided unassigned scans atomically.
  Future<void> createWithScans({
    required FruitBatch batch,
    required Iterable<String> scanIds,
    required DateTime updatedAt,
  });

  Future<FruitBatch?> findActiveById(String id);

  Future<List<FruitBatch>> listActive();

  Stream<List<BatchSnapshot>> watchActiveSnapshots();

  Stream<List<BatchListItem>> watchActiveList();

  Stream<BatchSnapshot?> watchActiveSnapshot(String batchId);

  Future<List<BatchSnapshot>> listCompatibleForScan(String scanId);

  Future<void> assignScan({
    required String scanId,
    required String batchId,
    required DateTime updatedAt,
  });

  Future<void> assignScans({
    required Iterable<String> scanIds,
    required String batchId,
    required DateTime updatedAt,
  });

  Future<List<BatchSnapshot>> listMoveTargets(String scanId);

  Future<void> removeScan({
    required String scanId,
    required DateTime updatedAt,
  });

  /// Removes multiple scans from their current batch in one transaction.
  /// Implementations must preserve Pending-order and completed-order rules.
  Future<void> removeScans({
    required Iterable<String> scanIds,
    required DateTime updatedAt,
  });

  Future<void> moveScan({
    required String scanId,
    required String targetBatchId,
    required DateTime updatedAt,
  });

  /// Moves multiple scans from one batch to a compatible target atomically.
  /// Implementations must preserve Pending-order and completed-order rules.
  Future<void> moveScans({
    required Iterable<String> scanIds,
    required String targetBatchId,
    required DateTime updatedAt,
  });

  Future<void> rename({
    required String batchId,
    required String name,
    required DateTime updatedAt,
  });

  /// Changes the fruit type of an unlocked batch that has no active scans.
  Future<void> changeFruitType({
    required String batchId,
    required FruitIdentifier fruit,
    required DateTime updatedAt,
  });

  Future<void> delete({required String batchId, required DateTime deletedAt});

  /// Soft-deletes a completed batch, its active completed order, and every
  /// saved scan assigned to it in one transaction. Returns the deleted scans
  /// so their retained local images can be cleaned up by the use case.
  Future<List<SavedScanRecord>> deleteCompletedWithScans({
    required String batchId,
    required DateTime deletedAt,
  });

  Future<BatchSummary> summarize(String batchId);
}

/// Raised when a Pending order would be left without any saved scan.
final class PendingOrderBatchException implements Exception {
  const PendingOrderBatchException();

  static const message =
      'A Pending order must keep at least one saved scan. Cancel the order '
      'before removing its final scan.';

  @override
  String toString() => message;
}
