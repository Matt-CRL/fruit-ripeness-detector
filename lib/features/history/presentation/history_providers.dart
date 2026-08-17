import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/features/history/data/app_private_retained_scan_image_store.dart';
import 'package:kami/features/history/data/drift_scan_record_repository.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';

final activeScanRecordsProvider = StreamProvider<List<SavedScanRecord>>((ref) {
  return ref.watch(scanRecordRepositoryProvider).watchActive();
});

final activeScanRevisionProvider = StreamProvider<int>((ref) {
  return ref.watch(scanRecordRepositoryProvider).watchActiveRevision();
});

final savedScanRecordProvider = StreamProvider.autoDispose
    .family<SavedScanRecord?, String>((ref, scanId) {
      return ref.watch(scanRecordRepositoryProvider).watchActiveById(scanId);
    });

final retainedImagePathProvider = FutureProvider.autoDispose
    .family<String, String>((ref, relativePath) {
      return ref
          .watch(retainedScanImageStoreProvider)
          .resolvePath(relativePath);
    });
