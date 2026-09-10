import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/core/database/app_database.dart';
import 'package:kami/core/database/app_database_provider.dart';
import 'package:kami/core/persistence/fruit_tag_id.dart';
import 'package:kami/core/persistence/local_sync_state.dart';
import 'package:kami/core/persistence/persistence_codecs.dart';
import 'package:kami/features/auth/application/current_owner_provider.dart';
import 'package:kami/features/auth/data/device_account_link_store.dart';

final fruitTagSequenceProvider = Provider<WorkspaceFruitTagSequence>((ref) {
  return DriftWorkspaceFruitTagSequence(
    ref.watch(appDatabaseProvider),
    ownerId: ref.watch(currentOwnerIdProvider),
    linkedAccountId: ref.watch(deviceLinkedAccountIdProvider),
    linkStore: ref.watch(deviceAccountLinkStoreProvider),
  );
});

abstract interface class WorkspaceFruitTagSequence {
  Future<String> reserveNext();

  Future<void> reconcileCurrentWorkspace();
}

final class DriftWorkspaceFruitTagSequence
    implements WorkspaceFruitTagSequence {
  const DriftWorkspaceFruitTagSequence(
    this._database, {
    required this.ownerId,
    required this.linkedAccountId,
    required this.linkStore,
  });

  final AppDatabase _database;
  final String? ownerId;
  final String? linkedAccountId;
  final DeviceAccountLinkStore linkStore;

  @override
  Future<String> reserveNext() async {
    final scope = await _scope();
    return _database.transaction(() async {
      final next = await _reconcile(scope);
      final now = DateTime.now().toUtc();
      await _database
          .into(_database.workspaceSequenceCounters)
          .insertOnConflictUpdate(
            WorkspaceSequenceCountersCompanion.insert(
              workspaceKey: scope.key,
              nextValue: Value(next + 1),
              updatedAt: now,
            ),
          );
      return FruitTagIds.format(next);
    });
  }

  @override
  Future<void> reconcileCurrentWorkspace() async {
    final scope = await _scope();
    await _database.transaction(() async {
      final next = await _reconcile(scope);
      final now = DateTime.now().toUtc();
      await _database
          .into(_database.workspaceSequenceCounters)
          .insertOnConflictUpdate(
            WorkspaceSequenceCountersCompanion.insert(
              workspaceKey: scope.key,
              nextValue: Value(next),
              updatedAt: now,
            ),
          );
    });
  }

  Future<int> _reconcile(_WorkspaceScope scope) async {
    final rows = await (_database.select(
      _database.scanRecords,
    )..where(scope.predicate)).get();
    final highestAssigned = rows.fold<int>(0, (highest, row) {
      final value = FruitTagIds.parse(row.fruitTagId);
      return value == null || value <= highest ? highest : value;
    });
    final counter = await (_database.select(
      _database.workspaceSequenceCounters,
    )..where((row) => row.workspaceKey.equals(scope.key))).getSingleOrNull();
    var next = counter?.nextValue ?? 1;
    if (next <= highestAssigned) next = highestAssigned + 1;

    final missing = rows.where((row) => row.fruitTagId == null).toList()
      ..sort((left, right) {
        final created = left.createdAt.compareTo(right.createdAt);
        return created == 0 ? left.id.compareTo(right.id) : created;
      });
    for (final row in missing) {
      final tagId = FruitTagIds.format(next++);
      final syncState = row.ownerId == null
          ? LocalSyncState.localOnly
          : LocalSyncState.pending;
      await (_database.update(
        _database.scanRecords,
      )..where((table) => table.id.equals(row.id))).write(
        ScanRecordsCompanion(
          fruitTagId: Value(tagId),
          syncState: Value(PersistenceCodecs.encodeSyncState(syncState)),
        ),
      );
    }
    return next;
  }

  Future<_WorkspaceScope> _scope() async {
    final workspaceId = await linkStore.readOrCreateWorkspaceId();
    if (ownerId == null || ownerId == linkedAccountId) {
      return _WorkspaceScope(
        key: 'persistent:$workspaceId',
        predicate: ownerId == null
            ? (table) => table.ownerId.isNull()
            : (table) => table.ownerId.equals(ownerId!),
      );
    }
    return _WorkspaceScope(
      key: 'temporary:$ownerId',
      predicate: (table) => table.ownerId.equals(ownerId!),
    );
  }
}

final class _WorkspaceScope {
  const _WorkspaceScope({required this.key, required this.predicate});

  final String key;
  final Expression<bool> Function($ScanRecordsTable table) predicate;
}
