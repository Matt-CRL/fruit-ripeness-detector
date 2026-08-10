import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/features/batches/data/drift_batch_repository.dart';
import 'package:kami/features/batches/domain/fruit_batch.dart';

final activeBatchSnapshotsProvider = StreamProvider<List<BatchSnapshot>>((ref) {
  return ref.watch(batchRepositoryProvider).watchActiveSnapshots();
});

final activeBatchListProvider = StreamProvider<List<BatchListItem>>((ref) {
  return ref.watch(batchRepositoryProvider).watchActiveList();
});

final batchSnapshotProvider = StreamProvider.autoDispose
    .family<BatchSnapshot?, String>((ref, batchId) {
      return ref.watch(batchRepositoryProvider).watchActiveSnapshot(batchId);
    });

final compatibleBatchSnapshotsProvider = FutureProvider.autoDispose
    .family<List<BatchSnapshot>, String>((ref, scanId) {
      return ref.watch(batchRepositoryProvider).listCompatibleForScan(scanId);
    });

final moveTargetBatchSnapshotsProvider = FutureProvider.autoDispose
    .family<List<BatchSnapshot>, String>((ref, scanId) {
      return ref.watch(batchRepositoryProvider).listMoveTargets(scanId);
    });
