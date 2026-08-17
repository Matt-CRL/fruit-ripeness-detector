import 'dart:async';
import 'dart:typed_data';

import 'package:kami/features/history/domain/retained_scan_image_store.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/history/domain/scan_record_repository.dart';
import 'package:kami/features/history/domain/saved_scan_query.dart';

final class FakeScanRecordRepository implements ScanRecordRepository {
  FakeScanRecordRepository({
    Iterable<SavedScanRecord> initialRecords = const [],
  }) : _records = {for (final record in initialRecords) record.id: record};

  final Map<String, SavedScanRecord> _records;
  final StreamController<List<SavedScanRecord>> _changes =
      StreamController<List<SavedScanRecord>>.broadcast();

  bool failCreates = false;
  bool failReads = false;
  bool failDeletes = false;
  int createCalls = 0;

  Future<void> assignToBatch(
    String scanId,
    String batchId, {
    DateTime? updatedAt,
  }) async {
    final record = _records[scanId];
    if (record == null || record.deletedAt != null) {
      throw StateError('Synthetic scan unavailable.');
    }
    if (record.batchId != null && record.batchId != batchId) {
      throw StateError('Synthetic scan already assigned.');
    }
    _records[scanId] = SavedScanRecord(
      id: record.id,
      ownerId: record.ownerId,
      batchId: batchId,
      fruit: record.fruit,
      ripeness: record.ripeness,
      modelConfidence: record.modelConfidence,
      modelVersion: record.modelVersion,
      resultOrigin: record.resultOrigin,
      shelfLife: record.shelfLife,
      localImageRelativePath: record.localImageRelativePath,
      remoteImageKey: record.remoteImageKey,
      createdAt: record.createdAt,
      updatedAt: updatedAt ?? record.updatedAt,
      deletedAt: record.deletedAt,
      syncState: record.syncState,
    );
    _emit();
  }

  Future<void> removeFromBatch(
    String scanId, {
    required DateTime updatedAt,
  }) async {
    final record = _records[scanId];
    if (record == null || record.deletedAt != null || record.batchId == null) {
      throw StateError('Synthetic assigned scan unavailable.');
    }
    _records[scanId] = _copy(record, batchId: null, updatedAt: updatedAt);
    _emit();
  }

  Future<void> moveToBatch(
    String scanId,
    String batchId, {
    required DateTime updatedAt,
  }) async {
    final record = _records[scanId];
    if (record == null || record.deletedAt != null || record.batchId == null) {
      throw StateError('Synthetic assigned scan unavailable.');
    }
    _records[scanId] = _copy(record, batchId: batchId, updatedAt: updatedAt);
    _emit();
  }

  @override
  Future<void> create(SavedScanRecord record) async {
    createCalls += 1;
    if (failCreates) {
      throw StateError('Synthetic database failure.');
    }
    if (_records.containsKey(record.id)) {
      throw StateError('Synthetic duplicate scan.');
    }
    _records[record.id] = record;
    _emit();
  }

  @override
  Future<SavedScanRecord?> findActiveById(String id) async {
    if (failReads) {
      throw StateError('Synthetic database read failure.');
    }
    final record = _records[id];
    return record?.deletedAt == null ? record : null;
  }

  @override
  Stream<SavedScanRecord?> watchActiveById(String id) async* {
    if (failReads) {
      throw StateError('Synthetic database read failure.');
    }
    yield _records[id]?.deletedAt == null ? _records[id] : null;
    yield* _changes.stream.map((_) {
      final record = _records[id];
      return record?.deletedAt == null ? record : null;
    });
  }

  @override
  Future<List<SavedScanRecord>> listActive() async {
    if (failReads) {
      throw StateError('Synthetic database read failure.');
    }
    return _activeRecords();
  }

  @override
  Stream<List<SavedScanRecord>> watchActive() async* {
    if (failReads) {
      throw StateError('Synthetic database read failure.');
    }
    yield _activeRecords();
    yield* _changes.stream;
  }

  @override
  Stream<int> watchActiveRevision() async* {
    if (failReads) {
      throw StateError('Synthetic database read failure.');
    }
    yield _revision();
    yield* _changes.stream.map((_) => _revision());
  }

  @override
  Future<SavedScanPage> fetchPage({
    required SavedScanQuery query,
    PageCursor? cursor,
    int limit = 50,
  }) async {
    if (failReads) {
      throw StateError('Synthetic database read failure.');
    }
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'Must be greater than zero.');
    }
    final records = _activeRecords()
        .where((record) => _matchesQuery(record, query))
        .toList();
    records.sort((left, right) {
      final dateOrder = left.createdAt.compareTo(right.createdAt);
      final ordered = dateOrder == 0 ? left.id.compareTo(right.id) : dateOrder;
      return query.sortOrder == SavedScanSortOrder.newestFirst
          ? -ordered
          : ordered;
    });
    final start = cursor == null
        ? 0
        : records.indexWhere(
                (record) =>
                    record.id == cursor.id &&
                    record.createdAt == cursor.createdAt,
              ) +
              1;
    final end = start + limit > records.length ? records.length : start + limit;
    final page = records.sublist(start, end);
    final hasMore = end < records.length;
    return SavedScanPage(
      records: List.unmodifiable(page),
      totalCount: records.length,
      nextCursor: hasMore
          ? PageCursor(createdAt: page.last.createdAt, id: page.last.id)
          : null,
    );
  }

  @override
  Future<int> count({required SavedScanQuery query}) async {
    if (failReads) {
      throw StateError('Synthetic database read failure.');
    }
    return _activeRecords()
        .where((record) => _matchesQuery(record, query))
        .length;
  }

  @override
  Future<SavedScanRecord> deleteActive({
    required String scanId,
    required DateTime deletedAt,
  }) async {
    if (failDeletes) {
      throw StateError('Synthetic scan deletion failure.');
    }
    final record = await findActiveById(scanId);
    if (record == null) {
      throw StateError('Synthetic scan unavailable.');
    }
    if (record.batchId != null) {
      throw StateError(
        'Assigned scans must be removed from their batch before deletion.',
      );
    }
    _records[scanId] = _copy(
      record,
      batchId: record.batchId,
      updatedAt: deletedAt,
      deletedAt: deletedAt,
    );
    _emit();
    return record;
  }

  @override
  Future<List<SavedScanRecord>> deleteActiveMany({
    required Iterable<String> scanIds,
    required DateTime deletedAt,
  }) async {
    if (failDeletes) {
      throw StateError('Synthetic scan deletion failure.');
    }
    final ids = scanIds.toSet();
    final records = <SavedScanRecord>[];
    for (final id in ids) {
      final record = await findActiveById(id);
      if (record == null) {
        throw StateError('Synthetic scan unavailable.');
      }
      if (record.batchId != null) {
        throw StateError(
          'Assigned scans must be removed from their batch before deletion.',
        );
      }
      records.add(record);
    }
    for (final record in records) {
      _records[record.id] = _copy(
        record,
        batchId: record.batchId,
        updatedAt: deletedAt,
        deletedAt: deletedAt,
      );
    }
    _emit();
    return records;
  }

  Future<void> dispose() => _changes.close();

  void _emit() => _changes.add(_activeRecords());

  int _revision() {
    final records = _activeRecords();
    final latest = records.fold<DateTime?>(
      null,
      (current, record) => current == null || record.updatedAt.isAfter(current)
          ? record.updatedAt
          : current,
    );
    return Object.hash(records.length, latest?.microsecondsSinceEpoch);
  }

  List<SavedScanRecord> _activeRecords() {
    final values = _records.values
        .where((record) => record.deletedAt == null)
        .toList();
    values.sort((left, right) {
      final dateOrder = right.createdAt.compareTo(left.createdAt);
      return dateOrder != 0 ? dateOrder : right.id.compareTo(left.id);
    });
    return List.unmodifiable(values);
  }

  static bool _matchesQuery(SavedScanRecord record, SavedScanQuery query) {
    if (query.fruit != null && record.fruit != query.fruit) return false;
    if (query.ripeness != null && record.ripeness != query.ripeness) {
      return false;
    }
    if (query.inBatch != null && (record.batchId != null) != query.inBatch) {
      return false;
    }
    if (query.batchId != null && record.batchId != query.batchId) return false;
    if (query.ownerId != null && record.ownerId != query.ownerId) return false;
    if (query.onlyNullOwner && record.ownerId != null) return false;
    if (query.createdFromUtc != null &&
        record.createdAt.isBefore(query.createdFromUtc!)) {
      return false;
    }
    if (query.createdUntilUtc != null &&
        !record.createdAt.isBefore(query.createdUntilUtc!)) {
      return false;
    }
    return true;
  }

  static SavedScanRecord _copy(
    SavedScanRecord record, {
    String? batchId,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return SavedScanRecord(
      id: record.id,
      ownerId: record.ownerId,
      batchId: batchId,
      fruit: record.fruit,
      ripeness: record.ripeness,
      modelConfidence: record.modelConfidence,
      modelVersion: record.modelVersion,
      resultOrigin: record.resultOrigin,
      shelfLife: record.shelfLife,
      localImageRelativePath: record.localImageRelativePath,
      remoteImageKey: record.remoteImageKey,
      createdAt: record.createdAt,
      updatedAt: updatedAt ?? record.updatedAt,
      deletedAt: deletedAt,
      syncState: record.syncState,
    );
  }
}

final class FakeRetainedScanImageStore implements RetainedScanImageStore {
  bool failRetain = false;
  bool failRemove = false;
  int retainCalls = 0;
  final List<String> removedPaths = [];
  final List<String> retainedPaths = [];

  @override
  Future<RetainedScanImage> retain({
    required String sourcePath,
    required String scanId,
  }) async {
    retainCalls += 1;
    if (failRetain) {
      throw const RetainedScanImageException('Synthetic compression failure.');
    }
    return RetainedScanImage(relativePath: 'history_images/$scanId.jpg');
  }

  @override
  Future<RetainedScanImage> copyToScan({
    required String sourceRelativePath,
    required String scanId,
  }) async {
    if (failRetain) {
      throw const RetainedScanImageException('Synthetic copy failure.');
    }
    final path = 'history_images/$scanId.jpg';
    retainedPaths.add(path);
    return RetainedScanImage(relativePath: path);
  }

  @override
  Future<void> remove(String relativePath) async {
    removedPaths.add(relativePath);
    if (failRemove) {
      throw const RetainedScanImageException('Synthetic cleanup failure.');
    }
  }

  @override
  Future<String> resolvePath(String relativePath) async {
    return '/virtual/$relativePath';
  }

  @override
  Future<RetainedScanImage> storeDownloadedJpeg({
    required Uint8List bytes,
    required String scanId,
  }) async {
    final relativePath = 'history_images/$scanId.jpg';
    retainedPaths.add(relativePath);
    return RetainedScanImage(relativePath: relativePath);
  }
}
