import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/history/domain/saved_scan_query.dart';

abstract interface class ScanRecordRepository {
  Future<void> create(SavedScanRecord record);

  Future<SavedScanRecord?> findActiveById(String id);

  Stream<SavedScanRecord?> watchActiveById(String id);

  Future<List<SavedScanRecord>> listActive();

  Stream<List<SavedScanRecord>> watchActive();

  /// Emits a lightweight revision whenever active History rows change.
  ///
  /// This is intentionally separate from [watchActive] so paged History can
  /// refresh without loading every saved scan into memory.
  Stream<int> watchActiveRevision();

  Future<SavedScanPage> fetchPage({
    required SavedScanQuery query,
    PageCursor? cursor,
    int limit = 50,
  });

  Future<int> count({required SavedScanQuery query});

  /// Soft-deletes one active, unassigned scan and returns the record that
  /// owned its retained image. Assigned scans must first be removed from
  /// their batch in Batch Details.
  Future<SavedScanRecord> deleteActive({
    required String scanId,
    required DateTime deletedAt,
  });

  /// Soft-deletes several active, unassigned scans atomically and returns the
  /// records that owned their retained images. Implementations must reject
  /// any assigned scan in the selection. Batch order safeguards remain
  /// enforced by the batch correction operations.
  Future<List<SavedScanRecord>> deleteActiveMany({
    required Iterable<String> scanIds,
    required DateTime deletedAt,
  });
}
