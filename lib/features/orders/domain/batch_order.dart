import 'package:kami/core/persistence/local_sync_state.dart';
import 'package:kami/core/persistence/persistence_validation.dart';

enum BatchOrderStatus { pending, completed }

final class BatchOrder {
  BatchOrder({
    required this.id,
    required this.batchId,
    required this.customerName,
    required this.deliveryAddress,
    required this.deliveryDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    this.ownerId,
    this.deletedAt,
  }) {
    PersistenceValidation.entityId(id, 'id');
    PersistenceValidation.entityId(batchId, 'batchId');
    PersistenceValidation.optionalEntityId(ownerId, 'ownerId');
    PersistenceValidation.nonBlank(customerName, 'customerName');
    PersistenceValidation.nonBlank(deliveryAddress, 'deliveryAddress');
    PersistenceValidation.utc(deliveryDate, 'deliveryDate');
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
  final String batchId;
  final String customerName;
  final String deliveryAddress;
  final DateTime deliveryDate;
  final BatchOrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final LocalSyncState syncState;
}
