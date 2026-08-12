import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/features/batches/data/drift_batch_repository.dart';
import 'package:kami/features/batches/domain/fruit_batch.dart';
import 'package:kami/features/auth/application/current_owner_provider.dart';

final activeBatchSnapshotsProvider = StreamProvider<List<BatchSnapshot>>((ref) {
  final ownerId = ref.watch(currentOwnerIdProvider);
  return ref
      .watch(batchRepositoryProvider)
      .watchActiveSnapshots()
      .map(
        (items) => items
            .where((item) => item.batch.ownerId == ownerId)
            .toList(growable: false),
      );
});

final activeBatchListProvider = StreamProvider<List<BatchListItem>>((ref) {
  final ownerId = ref.watch(currentOwnerIdProvider);
  return ref
      .watch(batchRepositoryProvider)
      .watchActiveList()
      .map(
        (items) => items
            .where((item) => item.batch.ownerId == ownerId)
            .toList(growable: false),
      );
});

final batchSnapshotProvider = StreamProvider.autoDispose.family<BatchSnapshot?, String>((
  ref,
  batchId,
) {
      final ownerId = ref.watch(currentOwnerIdProvider);
      return ref
          .watch(batchRepositoryProvider)
          .watchActiveSnapshot(batchId)
          .map((item) => item?.batch.ownerId == ownerId ? item : null);
    });

final compatibleBatchSnapshotsProvider =
    FutureProvider.autoDispose.family<List<BatchSnapshot>, String>((ref, scanId) {
      final ownerId = ref.watch(currentOwnerIdProvider);
      return ref
          .watch(batchRepositoryProvider)
          .listCompatibleForScan(scanId)
          .then(
            (items) => items
                .where((item) => item.batch.ownerId == ownerId)
                .toList(growable: false),
          );
    });

final moveTargetBatchSnapshotsProvider =
    FutureProvider.autoDispose.family<List<BatchSnapshot>, String>((ref, scanId) {
      final ownerId = ref.watch(currentOwnerIdProvider);
      return ref
          .watch(batchRepositoryProvider)
          .listMoveTargets(scanId)
          .then(
            (items) => items
                .where((item) => item.batch.ownerId == ownerId)
                .toList(growable: false),
          );
    });
