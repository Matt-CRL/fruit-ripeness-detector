import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

enum SavedScanSortOrder { newestFirst, oldestFirst }

/// A stable keyset cursor for saved-scan pages.
final class PageCursor {
  const PageCursor({required this.createdAt, required this.id});

  final DateTime createdAt;
  final String id;
}

/// Repository-level criteria shared by History, Batch Details, and Add scans.
final class SavedScanQuery {
  const SavedScanQuery({
    this.fruit,
    this.ripeness,
    this.inBatch,
    this.batchId,
    this.ownerId,
    this.onlyNullOwner = false,
    this.createdFromUtc,
    this.createdUntilUtc,
    this.sortOrder = SavedScanSortOrder.newestFirst,
  });

  final FruitIdentifier? fruit;
  final RipenessStage? ripeness;
  final bool? inBatch;
  final String? batchId;
  final String? ownerId;
  final bool onlyNullOwner;
  final DateTime? createdFromUtc;
  final DateTime? createdUntilUtc;
  final SavedScanSortOrder sortOrder;
}

final class SavedScanPage {
  const SavedScanPage({
    required this.records,
    required this.totalCount,
    required this.nextCursor,
  });

  final List<SavedScanRecord> records;
  final int totalCount;
  final PageCursor? nextCursor;

  bool get hasMore => nextCursor != null;
}
