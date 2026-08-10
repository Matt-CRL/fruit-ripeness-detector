import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/features/orders/data/drift_order_repository.dart';
import 'package:kami/features/orders/domain/batch_order.dart';

final activeBatchOrderProvider = StreamProvider.autoDispose
    .family<BatchOrder?, String>((ref, batchId) {
      return ref.watch(orderRepositoryProvider).watchActiveForBatch(batchId);
    });

final activeOrdersProvider = StreamProvider<List<BatchOrder>>((ref) {
  return ref.watch(orderRepositoryProvider).watchActive();
});
