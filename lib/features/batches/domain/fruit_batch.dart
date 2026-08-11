import 'package:kami/core/persistence/local_sync_state.dart';
import 'package:kami/core/persistence/persistence_validation.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

final class FruitBatch {
  FruitBatch({
    required this.id,
    required this.name,
    required this.fruit,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    this.remoteRevision = 0,
    this.ownerId,
    this.deletedAt,
  }) {
    PersistenceValidation.entityId(id, 'id');
    PersistenceValidation.optionalEntityId(ownerId, 'ownerId');
    PersistenceValidation.nonBlank(name, 'name');
    PersistenceValidation.utc(createdAt, 'createdAt');
    PersistenceValidation.utc(updatedAt, 'updatedAt');
    if (deletedAt != null) {
      PersistenceValidation.utc(deletedAt!, 'deletedAt');
    }
    PersistenceValidation.chronological(
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
    if (remoteRevision < 0) {
      throw ArgumentError.value(
        remoteRevision,
        'remoteRevision',
        'must not be negative',
      );
    }
  }

  final String id;
  final String? ownerId;
  final String name;
  final FruitIdentifier fruit;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final LocalSyncState syncState;
  final int remoteRevision;
}

final class BatchSummary {
  const BatchSummary({
    required this.total,
    required this.unripe,
    required this.ripe,
    required this.overripe,
  });

  final int total;
  final int unripe;
  final int ripe;
  final int overripe;
}

final class BatchSnapshot {
  BatchSnapshot({
    required this.batch,
    required this.summary,
    required Iterable<SavedScanRecord> scans,
    required this.isLocked,
  }) : scans = List.unmodifiable(scans);

  final FruitBatch batch;
  final BatchSummary summary;
  final List<SavedScanRecord> scans;
  final bool isLocked;

  bool get containsDemo =>
      scans.any((record) => record.resultOrigin == ResultOrigin.demo);
}

/// Lightweight data for the Batches list. Full scan records are loaded only
/// by Batch Details and the batch scan picker.
final class BatchListItem {
  const BatchListItem({
    required this.batch,
    required this.summary,
    required this.containsDemo,
  });

  final FruitBatch batch;
  final BatchSummary summary;
  final bool containsDemo;
}
