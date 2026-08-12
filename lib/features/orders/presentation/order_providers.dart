import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/features/orders/data/drift_order_repository.dart';
import 'package:kami/features/orders/domain/batch_order.dart';
import 'package:kami/features/auth/application/current_owner_provider.dart';

final activeBatchOrderProvider = StreamProvider.autoDispose
    .family<BatchOrder?, String>((ref, batchId) {
      final ownerId = ref.watch(currentOwnerIdProvider);
      return ref
          .watch(orderRepositoryProvider)
          .watchActiveForBatch(batchId)
          .map((item) => item?.ownerId == ownerId ? item : null);
    });

final activeOrdersProvider = StreamProvider<List<BatchOrder>>((ref) {
  final ownerId = ref.watch(currentOwnerIdProvider);
  return ref.watch(orderRepositoryProvider).watchActive().map(
        (items) => items
            .where((item) => item.ownerId == ownerId)
            .toList(growable: false),
      );
});
