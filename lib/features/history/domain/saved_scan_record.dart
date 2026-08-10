import 'package:kami/core/persistence/local_sync_state.dart';
import 'package:kami/core/persistence/persistence_validation.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

final class SavedScanRecord {
  SavedScanRecord({
    required this.id,
    required this.fruit,
    required this.ripeness,
    required this.modelConfidence,
    required this.modelVersion,
    required this.resultOrigin,
    required this.shelfLife,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    this.ownerId,
    this.batchId,
    this.localImageRelativePath,
    this.remoteImageKey,
    this.deletedAt,
  }) {
    PersistenceValidation.entityId(id, 'id');
    PersistenceValidation.optionalEntityId(ownerId, 'ownerId');
    PersistenceValidation.optionalEntityId(batchId, 'batchId');
    if (modelConfidence < 0 || modelConfidence > 1) {
      throw ArgumentError.value(
        modelConfidence,
        'modelConfidence',
        'must be between 0 and 1',
      );
    }
    PersistenceValidation.nonBlank(modelVersion, 'modelVersion');
    PersistenceValidation.relativePath(
      localImageRelativePath,
      'localImageRelativePath',
    );
    if (remoteImageKey != null) {
      PersistenceValidation.nonBlank(remoteImageKey!, 'remoteImageKey');
    }
    _validateShelfLife(shelfLife);
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
  }

  final String id;
  final String? ownerId;
  final String? batchId;
  final FruitIdentifier fruit;
  final RipenessStage ripeness;
  final double modelConfidence;
  final String modelVersion;
  final ResultOrigin resultOrigin;
  final ShelfLifeEstimate shelfLife;
  final String? localImageRelativePath;
  final String? remoteImageKey;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final LocalSyncState syncState;

  static void _validateShelfLife(ShelfLifeEstimate value) {
    switch (value) {
      case ShelfLifeRange():
        if (value.minimum <= 0 || value.maximum < value.minimum) {
          throw ArgumentError.value(
            value,
            'shelfLife',
            'must have a positive ordered range',
          );
        }
        PersistenceValidation.nonBlank(value.unit, 'shelfLife.unit');
        PersistenceValidation.nonBlank(
          value.storageGuidance,
          'shelfLife.storageGuidance',
        );
        PersistenceValidation.nonBlank(
          value.evidenceVersion,
          'shelfLife.evidenceVersion',
        );
      case ShelfLifeConsumeImmediately():
        PersistenceValidation.nonBlank(
          value.storageGuidance,
          'shelfLife.storageGuidance',
        );
        PersistenceValidation.nonBlank(
          value.evidenceVersion,
          'shelfLife.evidenceVersion',
        );
      case ShelfLifeUnavailable():
        PersistenceValidation.nonBlank(value.reason, 'shelfLife.reason');
        PersistenceValidation.nonBlank(
          value.evidenceVersion,
          'shelfLife.evidenceVersion',
        );
    }
  }
}
