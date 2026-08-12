import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/core/database/app_database_provider.dart';
import 'package:kami/core/persistence/entity_id_generator.dart';
import 'package:kami/core/persistence/local_sync_state.dart';
import 'package:kami/features/auth/application/current_owner_provider.dart';
import 'package:kami/features/orders/data/drift_order_repository.dart';
import 'package:kami/features/orders/domain/batch_order.dart';
import 'package:kami/features/orders/domain/order_repository.dart';

typedef OrderUtcNow = DateTime Function();

final orderUtcNowProvider = Provider<OrderUtcNow>(
  (ref) =>
      () => DateTime.now().toUtc(),
);

final createOrderUseCaseProvider = Provider<CreateOrderUseCase>((ref) {
  return CreateOrderUseCase(
    ref.watch(orderRepositoryProvider),
    ref.watch(entityIdGeneratorProvider),
    ref.watch(orderUtcNowProvider),
    ref.watch(currentOwnerIdProvider),
  );
});

final updatePendingOrderUseCaseProvider = Provider<UpdatePendingOrderUseCase>((
  ref,
) {
  return UpdatePendingOrderUseCase(
    ref.watch(orderRepositoryProvider),
    ref.watch(orderUtcNowProvider),
  );
});

final cancelPendingOrderUseCaseProvider = Provider<CancelPendingOrderUseCase>((
  ref,
) {
  return CancelPendingOrderUseCase(
    ref.watch(orderRepositoryProvider),
    ref.watch(orderUtcNowProvider),
  );
});

final completeOrderUseCaseProvider = Provider<CompleteOrderUseCase>((ref) {
  return CompleteOrderUseCase(
    ref.watch(orderRepositoryProvider),
    ref.watch(orderUtcNowProvider),
  );
});

final class CreateOrderUseCase {
  const CreateOrderUseCase(
    this._repository,
    this._idGenerator,
    this._utcNow, [
    this._ownerId,
  ]);

  final OrderRepository _repository;
  final EntityIdGenerator _idGenerator;
  final OrderUtcNow _utcNow;
  final String? _ownerId;

  Future<BatchOrder> execute({
    required String batchId,
    required String customerName,
    required String deliveryAddress,
    required DateTime deliveryDate,
  }) async {
    final fields = _validate(customerName, deliveryAddress);
    final now = _utcNow();
    _validateDeliveryDate(deliveryDate, now);
    final order = BatchOrder(
      id: _idGenerator.nextId(),
      ownerId: _ownerId,
      batchId: batchId,
      customerName: fields.customerName,
      deliveryAddress: fields.deliveryAddress,
      deliveryDate: deliveryDate.toUtc(),
      status: BatchOrderStatus.pending,
      createdAt: now,
      updatedAt: now,
      syncState: _ownerId == null
          ? LocalSyncState.localOnly
          : LocalSyncState.pending,
    );
    try {
      await _repository.create(order);
      return order;
    } on OrderActionException {
      rethrow;
    } on Object {
      throw const OrderActionException(
        'Kami could not create this local order. The batch was not changed.',
      );
    }
  }
}

final class UpdatePendingOrderUseCase {
  const UpdatePendingOrderUseCase(this._repository, this._utcNow);

  final OrderRepository _repository;
  final OrderUtcNow _utcNow;

  Future<void> execute({
    required BatchOrder existing,
    required String customerName,
    required String deliveryAddress,
    required DateTime deliveryDate,
  }) async {
    final fields = _validate(customerName, deliveryAddress);
    final now = _utcNow();
    _validateDeliveryDate(deliveryDate, now);
    final updated = BatchOrder(
      id: existing.id,
      ownerId: existing.ownerId,
      batchId: existing.batchId,
      customerName: fields.customerName,
      deliveryAddress: fields.deliveryAddress,
      deliveryDate: deliveryDate.toUtc(),
      status: BatchOrderStatus.pending,
      createdAt: existing.createdAt,
      updatedAt: now,
      deletedAt: existing.deletedAt,
      syncState: existing.syncState,
      remoteRevision: existing.remoteRevision,
    );
    try {
      await _repository.updatePending(updated);
    } on OrderActionException {
      rethrow;
    } on Object {
      throw const OrderActionException(
        'Kami could not save these order changes. The current details were kept.',
      );
    }
  }
}

final class CompleteOrderUseCase {
  const CompleteOrderUseCase(this._repository, this._utcNow);

  final OrderRepository _repository;
  final OrderUtcNow _utcNow;

  Future<BatchOrder> execute({required String batchId}) async {
    try {
      return await _repository.complete(batchId: batchId, updatedAt: _utcNow());
    } on Object {
      throw const OrderActionException(
        'Kami could not complete this order. It remains Pending.',
      );
    }
  }
}

final class CancelPendingOrderUseCase {
  const CancelPendingOrderUseCase(this._repository, this._utcNow);

  final OrderRepository _repository;
  final OrderUtcNow _utcNow;

  Future<void> execute({required String batchId}) async {
    try {
      await _repository.cancel(batchId: batchId, updatedAt: _utcNow());
    } on Object {
      throw const OrderActionException(
        'Kami could not cancel this Pending order. Its current details were '
        'kept.',
      );
    }
  }
}

({String customerName, String deliveryAddress}) _validate(
  String customerName,
  String deliveryAddress,
) {
  final name = customerName.trim();
  final address = deliveryAddress.trim();
  if (name.isEmpty) {
    throw const OrderActionException('Enter the customer name.');
  }
  if (name.length > 160) {
    throw const OrderActionException(
      'Customer names must be 160 characters or fewer.',
    );
  }
  if (address.isEmpty) {
    throw const OrderActionException('Enter the delivery address.');
  }
  if (address.length > 500) {
    throw const OrderActionException(
      'Delivery addresses must be 500 characters or fewer.',
    );
  }
  return (customerName: name, deliveryAddress: address);
}

void _validateDeliveryDate(DateTime deliveryDate, DateTime now) {
  final selected = _dateOnlyUtc(deliveryDate);
  final today = _dateOnlyUtc(now);
  if (selected.isBefore(today)) {
    throw const OrderActionException(
      'Delivery date cannot be earlier than today.',
    );
  }
}

DateTime _dateOnlyUtc(DateTime value) {
  final utc = value.toUtc();
  return DateTime.utc(utc.year, utc.month, utc.day);
}

final class OrderActionException implements Exception {
  const OrderActionException(this.message);

  final String message;

  @override
  String toString() => 'OrderActionException: $message';
}
