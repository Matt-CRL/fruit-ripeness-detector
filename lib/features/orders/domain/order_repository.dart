import 'package:kami/features/orders/domain/batch_order.dart';

abstract interface class OrderRepository {
  Future<void> create(BatchOrder order);

  Future<BatchOrder?> findActiveForBatch(String batchId);

  Stream<List<BatchOrder>> watchActive();

  Stream<BatchOrder?> watchActiveForBatch(String batchId);

  Future<void> updatePending(BatchOrder order);

  Future<void> cancel({required String batchId, required DateTime updatedAt});

  Future<BatchOrder> complete({
    required String batchId,
    required DateTime updatedAt,
  });
}
