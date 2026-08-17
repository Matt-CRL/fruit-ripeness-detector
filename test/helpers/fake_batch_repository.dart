import 'dart:async';

import 'package:kami/features/batches/domain/batch_repository.dart';
import 'package:kami/features/batches/domain/fruit_batch.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

import 'fake_history_storage.dart';

final class FakeBatchRepository implements BatchRepository {
  FakeBatchRepository(
    this._scans, {
    Iterable<FruitBatch> initialBatches = const [],
  }) : _batches = {for (final batch in initialBatches) batch.id: batch};

  final FakeScanRecordRepository _scans;
  final Map<String, FruitBatch> _batches;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  bool failReads = false;
  bool failCreates = false;
  bool failAssignments = false;
  bool failCorrections = false;
  int createCalls = 0;
  int assignmentCalls = 0;

  Future<void> dispose() => _changes.close();

  @override
  Future<void> create(FruitBatch batch) async {
    createCalls++;
    if (failCreates) {
      throw StateError('Synthetic batch create failure.');
    }
    if (_batches.containsKey(batch.id)) {
      throw StateError('Synthetic duplicate batch.');
    }
    _batches[batch.id] = batch;
    _changes.add(null);
  }

  @override
  Future<void> createWithScan({
    required FruitBatch batch,
    required String scanId,
    required DateTime updatedAt,
  }) async {
    await createWithScans(
      batch: batch,
      scanIds: [scanId],
      updatedAt: updatedAt,
    );
  }

  @override
  Future<void> createWithScans({
    required FruitBatch batch,
    required Iterable<String> scanIds,
    required DateTime updatedAt,
  }) async {
    createCalls++;
    if (failCreates || failAssignments) {
      throw StateError('Synthetic atomic create failure.');
    }
    final ids = scanIds.toSet().toList(growable: false);
    if (ids.isEmpty) {
      throw StateError('Synthetic empty assignment.');
    }
    final scans = <SavedScanRecord>[];
    for (final scanId in ids) {
      final scan = await _scans.findActiveById(scanId);
      if (scan == null ||
          scan.batchId != null ||
          scan.fruit != batch.fruit ||
          scan.ownerId != batch.ownerId) {
        throw StateError('Synthetic incompatible scan.');
      }
      scans.add(scan);
    }
    _batches[batch.id] = batch;
    try {
      for (final scan in scans) {
        await _scans.assignToBatch(scan.id, batch.id, updatedAt: updatedAt);
      }
    } on Object {
      _batches.remove(batch.id);
      for (final scan in scans) {
        final current = await _scans.findActiveById(scan.id);
        if (current?.batchId == batch.id) {
          await _scans.removeFromBatch(scan.id, updatedAt: scan.updatedAt);
        }
      }
      rethrow;
    }
    _changes.add(null);
  }

  @override
  Future<FruitBatch?> findActiveById(String id) async {
    _checkReads();
    final batch = _batches[id];
    return batch?.deletedAt == null ? batch : null;
  }

  @override
  Future<List<FruitBatch>> listActive() async {
    _checkReads();
    final batches =
        _batches.values.where((batch) => batch.deletedAt == null).toList()
          ..sort((left, right) {
            final dateOrder = right.createdAt.compareTo(left.createdAt);
            return dateOrder != 0 ? dateOrder : right.id.compareTo(left.id);
          });
    return List.unmodifiable(batches);
  }

  @override
  Stream<List<BatchSnapshot>> watchActiveSnapshots() async* {
    _checkReads();
    yield await _snapshots();
    yield* _changes.stream.asyncMap((_) => _snapshots());
  }

  @override
  Stream<List<BatchListItem>> watchActiveList() async* {
    await for (final snapshots in watchActiveSnapshots()) {
      yield snapshots
          .map(
            (snapshot) => BatchListItem(
              batch: snapshot.batch,
              summary: snapshot.summary,
              containsDemo: snapshot.containsDemo,
            ),
          )
          .toList(growable: false);
    }
  }

  @override
  Stream<BatchSnapshot?> watchActiveSnapshot(String batchId) async* {
    await for (final snapshots in watchActiveSnapshots()) {
      BatchSnapshot? match;
      for (final snapshot in snapshots) {
        if (snapshot.batch.id == batchId) {
          match = snapshot;
          break;
        }
      }
      yield match;
    }
  }

  @override
  Future<List<BatchSnapshot>> listCompatibleForScan(String scanId) async {
    _checkReads();
    final scan = await _scans.findActiveById(scanId);
    if (scan == null || scan.batchId != null) {
      return const [];
    }
    return (await _snapshots())
        .where(
          (snapshot) =>
              snapshot.batch.fruit == scan.fruit && !snapshot.isLocked,
        )
        .toList(growable: false);
  }

  @override
  Future<List<BatchSnapshot>> listMoveTargets(String scanId) async {
    _checkReads();
    final scan = await _scans.findActiveById(scanId);
    if (scan == null || scan.batchId == null) {
      return const [];
    }
    return (await _snapshots())
        .where(
          (snapshot) =>
              snapshot.batch.id != scan.batchId &&
              snapshot.batch.fruit == scan.fruit &&
              !snapshot.isLocked,
        )
        .toList(growable: false);
  }

  @override
  Future<void> assignScan({
    required String scanId,
    required String batchId,
    required DateTime updatedAt,
  }) async {
    await assignScans(
      scanIds: [scanId],
      batchId: batchId,
      updatedAt: updatedAt,
    );
  }

  @override
  Future<void> assignScans({
    required Iterable<String> scanIds,
    required String batchId,
    required DateTime updatedAt,
  }) async {
    assignmentCalls++;
    if (failAssignments) {
      throw StateError('Synthetic assignment failure.');
    }
    final ids = scanIds.toSet().toList(growable: false);
    if (ids.isEmpty) {
      throw StateError('Synthetic empty assignment.');
    }
    final batch = _batches[batchId];
    if (batch == null || batch.deletedAt != null) {
      throw StateError('Synthetic incompatible assignment.');
    }
    final scans = <SavedScanRecord>[];
    for (final scanId in ids) {
      final scan = await _scans.findActiveById(scanId);
      if (scan == null ||
          scan.fruit != batch.fruit ||
          scan.ownerId != batch.ownerId ||
          (scan.batchId != null && scan.batchId != batchId)) {
        throw StateError('Synthetic incompatible assignment.');
      }
      scans.add(scan);
    }
    for (final scan in scans) {
      await _scans.assignToBatch(scan.id, batchId, updatedAt: updatedAt);
    }
    _changes.add(null);
  }

  @override
  Future<void> removeScan({
    required String scanId,
    required DateTime updatedAt,
  }) async {
    await removeScans(scanIds: [scanId], updatedAt: updatedAt);
  }

  @override
  Future<void> removeScans({
    required Iterable<String> scanIds,
    required DateTime updatedAt,
  }) async {
    if (failCorrections) {
      throw StateError('Synthetic scan removal failure.');
    }
    final ids = scanIds.toSet().toList(growable: false);
    if (ids.isEmpty) {
      throw StateError('Synthetic empty removal.');
    }
    final records = <SavedScanRecord>[];
    for (final scanId in ids) {
      final record = await _scans.findActiveById(scanId);
      if (record == null || record.batchId == null) {
        throw StateError('Synthetic assigned scan unavailable.');
      }
      records.add(record);
    }
    final batchId = records.first.batchId;
    if (records.any((record) => record.batchId != batchId)) {
      throw StateError('Synthetic scans belong to different batches.');
    }
    for (final record in records) {
      await _scans.removeFromBatch(record.id, updatedAt: updatedAt);
    }
    _changes.add(null);
  }

  @override
  Future<void> moveScan({
    required String scanId,
    required String targetBatchId,
    required DateTime updatedAt,
  }) async {
    await moveScans(
      scanIds: [scanId],
      targetBatchId: targetBatchId,
      updatedAt: updatedAt,
    );
  }

  @override
  Future<void> moveScans({
    required Iterable<String> scanIds,
    required String targetBatchId,
    required DateTime updatedAt,
  }) async {
    if (failCorrections) {
      throw StateError('Synthetic scan move failure.');
    }
    final ids = scanIds.toSet().toList(growable: false);
    if (ids.isEmpty) {
      throw StateError('Synthetic empty move.');
    }
    final target = _batches[targetBatchId];
    final selected = [
      for (final scanId in ids) await _scans.findActiveById(scanId),
    ];
    if (selected.any((scan) => scan == null) ||
        target == null ||
        target.deletedAt != null) {
      throw StateError('Synthetic incompatible move.');
    }
    final scans = selected.cast<SavedScanRecord>();
    if (scans.any(
      (scan) =>
          scan.batchId == null ||
          scan.batchId == targetBatchId ||
          scan.fruit != target.fruit,
    )) {
      throw StateError('Synthetic incompatible move.');
    }
    final sourceBatchId = scans.first.batchId!;
    if (scans.any((scan) => scan.batchId != sourceBatchId)) {
      throw StateError('Synthetic scans belong to different batches.');
    }
    for (final scan in scans) {
      await _scans.moveToBatch(scan.id, targetBatchId, updatedAt: updatedAt);
    }
    _changes.add(null);
  }

  @override
  Future<void> rename({
    required String batchId,
    required String name,
    required DateTime updatedAt,
  }) async {
    if (failCorrections) {
      throw StateError('Synthetic batch rename failure.');
    }
    final batch = _batches[batchId];
    if (batch == null || batch.deletedAt != null) {
      throw StateError('Synthetic unavailable batch.');
    }
    _batches[batchId] = FruitBatch(
      id: batch.id,
      ownerId: batch.ownerId,
      name: name,
      fruit: batch.fruit,
      createdAt: batch.createdAt,
      updatedAt: updatedAt,
      deletedAt: batch.deletedAt,
      syncState: batch.syncState,
    );
    _changes.add(null);
  }

  @override
  Future<void> changeFruitType({
    required String batchId,
    required FruitIdentifier fruit,
    required DateTime updatedAt,
  }) async {
    if (failCorrections) {
      throw StateError('Synthetic fruit-type change failure.');
    }
    final batch = _batches[batchId];
    if (batch == null || batch.deletedAt != null) {
      throw StateError('Synthetic unavailable batch.');
    }
    if (batch.fruit == fruit) {
      return;
    }
    final scans = await _scans.listActive();
    if (scans.any((scan) => scan.batchId == batchId)) {
      throw StateError('Synthetic non-empty batch.');
    }
    _batches[batchId] = FruitBatch(
      id: batch.id,
      ownerId: batch.ownerId,
      name: batch.name,
      fruit: fruit,
      createdAt: batch.createdAt,
      updatedAt: updatedAt,
      deletedAt: batch.deletedAt,
      syncState: batch.syncState,
    );
    _changes.add(null);
  }

  @override
  Future<void> delete({
    required String batchId,
    required DateTime deletedAt,
  }) async {
    if (failCorrections) {
      throw StateError('Synthetic batch deletion failure.');
    }
    final batch = _batches[batchId];
    if (batch == null || batch.deletedAt != null) {
      throw StateError('Synthetic unavailable batch.');
    }
    final scans = await _scans.listActive();
    if (scans.any((scan) => scan.batchId == batchId)) {
      throw StateError('Synthetic non-empty batch.');
    }
    _batches[batchId] = FruitBatch(
      id: batch.id,
      ownerId: batch.ownerId,
      name: batch.name,
      fruit: batch.fruit,
      createdAt: batch.createdAt,
      updatedAt: deletedAt,
      deletedAt: deletedAt,
      syncState: batch.syncState,
    );
    _changes.add(null);
  }

  @override
  Future<List<SavedScanRecord>> deleteCompletedWithScans({
    required String batchId,
    required DateTime deletedAt,
  }) async {
    if (failCorrections) {
      throw StateError('Synthetic batch deletion failure.');
    }
    final batch = _batches[batchId];
    if (batch == null || batch.deletedAt != null) {
      throw StateError('Synthetic unavailable batch.');
    }
    final scans = (await _scans.listActive())
        .where((scan) => scan.batchId == batchId)
        .toList(growable: false);
    for (final scan in scans) {
      await _scans.removeFromBatch(scan.id, updatedAt: deletedAt);
      await _scans.deleteActive(scanId: scan.id, deletedAt: deletedAt);
    }
    _batches[batchId] = FruitBatch(
      id: batch.id,
      ownerId: batch.ownerId,
      name: batch.name,
      fruit: batch.fruit,
      createdAt: batch.createdAt,
      updatedAt: deletedAt,
      deletedAt: deletedAt,
      syncState: batch.syncState,
    );
    _changes.add(null);
    return scans;
  }

  @override
  Future<BatchSummary> summarize(String batchId) async {
    final snapshots = await _snapshots();
    return snapshots
        .singleWhere((snapshot) => snapshot.batch.id == batchId)
        .summary;
  }

  void _checkReads() {
    if (failReads) {
      throw StateError('Synthetic batch read failure.');
    }
  }

  Future<List<BatchSnapshot>> _snapshots() async {
    _checkReads();
    final scans = await _scans.listActive();
    final batches =
        _batches.values.where((batch) => batch.deletedAt == null).toList()
          ..sort((left, right) {
            final dateOrder = right.createdAt.compareTo(left.createdAt);
            return dateOrder != 0 ? dateOrder : right.id.compareTo(left.id);
          });
    return batches
        .map((batch) {
          final assigned = scans
              .where((scan) => scan.batchId == batch.id)
              .toList(growable: false);
          return BatchSnapshot(
            batch: batch,
            summary: _summary(assigned),
            scans: assigned,
            isLocked: false,
          );
        })
        .toList(growable: false);
  }

  static BatchSummary _summary(List<SavedScanRecord> scans) {
    var unripe = 0;
    var ripe = 0;
    var overripe = 0;
    for (final scan in scans) {
      switch (scan.ripeness) {
        case RipenessStage.unripe:
          unripe++;
        case RipenessStage.ripe:
          ripe++;
        case RipenessStage.overripe:
          overripe++;
      }
    }
    return BatchSummary(
      total: scans.length,
      unripe: unripe,
      ripe: ripe,
      overripe: overripe,
    );
  }
}
