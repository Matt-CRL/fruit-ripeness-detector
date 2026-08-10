import 'dart:async';

import 'package:kami/features/orders/domain/batch_order.dart';
import 'package:kami/features/orders/domain/order_repository.dart';

final class FakeOrderRepository implements OrderRepository {
  FakeOrderRepository({Iterable<BatchOrder> initialOrders = const []})
    : _orders = {for (final order in initialOrders) order.batchId: order};

  final Map<String, BatchOrder> _orders;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  bool failWrites = false;

  Future<void> dispose() => _changes.close();

  @override
  Future<void> create(BatchOrder order) async {
    _checkWrites();
    if (_orders.containsKey(order.batchId)) {
      throw StateError('Synthetic duplicate order.');
    }
    _orders[order.batchId] = order;
    _changes.add(null);
  }

  @override
  Future<BatchOrder?> findActiveForBatch(String batchId) async {
    return _orders[batchId];
  }

  @override
  Stream<List<BatchOrder>> watchActive() async* {
    yield _orders.values.toList(growable: false);
    yield* _changes.stream.map((_) => _orders.values.toList(growable: false));
  }

  @override
  Stream<BatchOrder?> watchActiveForBatch(String batchId) async* {
    yield _orders[batchId];
    yield* _changes.stream.map((_) => _orders[batchId]);
  }

  @override
  Future<void> updatePending(BatchOrder order) async {
    _checkWrites();
    final existing = _orders[order.batchId];
    if (existing == null ||
        existing.id != order.id ||
        existing.status != BatchOrderStatus.pending) {
      throw StateError('Synthetic unavailable Pending order.');
    }
    _orders[order.batchId] = order;
    _changes.add(null);
  }

  @override
  Future<void> cancel({
    required String batchId,
    required DateTime updatedAt,
  }) async {
    _checkWrites();
    final existing = _orders[batchId];
    if (existing == null || existing.status != BatchOrderStatus.pending) {
      throw StateError('Synthetic unavailable Pending order.');
    }
    _orders.remove(batchId);
    _changes.add(null);
  }

  @override
  Future<BatchOrder> complete({
    required String batchId,
    required DateTime updatedAt,
  }) async {
    _checkWrites();
    final existing = _orders[batchId];
    if (existing == null || existing.status != BatchOrderStatus.pending) {
      throw StateError('Synthetic unavailable Pending order.');
    }
    final completed = BatchOrder(
      id: existing.id,
      ownerId: existing.ownerId,
      batchId: existing.batchId,
      customerName: existing.customerName,
      deliveryAddress: existing.deliveryAddress,
      deliveryDate: existing.deliveryDate,
      status: BatchOrderStatus.completed,
      createdAt: existing.createdAt,
      updatedAt: updatedAt,
      deletedAt: existing.deletedAt,
      syncState: existing.syncState,
    );
    _orders[batchId] = completed;
    _changes.add(null);
    return completed;
  }

  void _checkWrites() {
    if (failWrites) {
      throw StateError('Synthetic order write failure.');
    }
  }
}
