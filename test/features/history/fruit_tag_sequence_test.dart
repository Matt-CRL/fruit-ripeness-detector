import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:kami/core/database/app_database.dart';
import 'package:kami/core/persistence/fruit_tag_id.dart';
import 'package:kami/core/persistence/local_sync_state.dart';
import 'package:kami/features/auth/data/device_account_link_store.dart';
import 'package:kami/features/history/application/fruit_tag_sequence.dart';
import 'package:kami/features/history/data/drift_scan_record_repository.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

const _ownerId = '11111111-1111-4111-8111-111111111111';
late AppDatabase _database;
late _TestLinkStore _linkStore;

void main() {
  setUp(() {
    _database = AppDatabase(NativeDatabase.memory());
    _linkStore = _TestLinkStore();
  });

  tearDown(() => _database.close());

  test('formats six-digit IDs and continues naturally past six digits', () {
    expect(FruitTagIds.format(1), 'CH-000001');
    expect(FruitTagIds.format(999999), 'CH-999999');
    expect(FruitTagIds.format(1000000), 'CH-1000000');
    expect(FruitTagIds.parse('CH-000042'), 42);
    expect(FruitTagIds.parse('not-an-id'), isNull);
  });

  test(
    'reserves unique IDs concurrently and never reuses the counter',
    () async {
      final sequence = _sequence(ownerId: null);

      final values = await Future.wait(
        List.generate(20, (_) => sequence.reserveNext()),
      );

      expect(values.toSet(), hasLength(20));
      expect(values.map(FruitTagIds.parse).toSet(), {
        for (var value = 1; value <= 20; value++) value,
      });

      final secondInstance = _sequence(ownerId: null);
      expect(await secondInstance.reserveNext(), 'CH-000021');
    },
  );

  test('keeps counters separate between workspace scopes', () async {
    final guestSequence = _sequence(ownerId: null);
    final temporaryAccountSequence = _sequence(ownerId: _ownerId);

    expect(await guestSequence.reserveNext(), 'CH-000001');
    expect(await temporaryAccountSequence.reserveNext(), 'CH-000001');
    expect(await guestSequence.reserveNext(), 'CH-000002');
  });

  test('backfills active and soft-deleted rows chronologically', () async {
    final scans = DriftScanRecordRepository(_database);
    await scans.create(
      _record(
        id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        createdAt: DateTime.utc(2026, 1, 2),
      ),
    );
    await scans.create(
      _record(
        id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        createdAt: DateTime.utc(2026, 1, 1),
        deletedAt: DateTime.utc(2026, 1, 3),
      ),
    );

    await _sequence(ownerId: null).reconcileCurrentWorkspace();

    final rows =
        await (_database.select(_database.scanRecords)..orderBy([
              (row) => OrderingTerm.asc(row.createdAt),
              (row) => OrderingTerm.asc(row.id),
            ]))
            .get();
    expect(rows.map((row) => row.fruitTagId), ['CH-000001', 'CH-000002']);
    expect(await _sequence(ownerId: null).reserveNext(), 'CH-000003');
  });
}

DriftWorkspaceFruitTagSequence _sequence({required String? ownerId}) {
  return DriftWorkspaceFruitTagSequence(
    _database,
    ownerId: ownerId,
    linkedAccountId: null,
    linkStore: _linkStore,
  );
}

SavedScanRecord _record({
  required String id,
  required DateTime createdAt,
  DateTime? deletedAt,
}) {
  return SavedScanRecord(
    id: id,
    ownerId: null,
    fruit: FruitIdentifier.carabaoMango,
    ripeness: RipenessStage.ripe,
    modelConfidence: 0.8,
    modelVersion: 'test-model-v1',
    resultOrigin: ResultOrigin.onDeviceModel,
    shelfLife: const ShelfLifeUnavailable(
      reason: 'Test estimate unavailable.',
      evidenceVersion: 'test-v1',
    ),
    createdAt: createdAt,
    updatedAt: deletedAt ?? createdAt,
    deletedAt: deletedAt,
    syncState: LocalSyncState.localOnly,
  );
}

final class _TestLinkStore implements DeviceAccountLinkStore {
  String? linkedAccountId;
  String workspaceId = '99999999-9999-4999-8999-999999999999';
  String installationId = '88888888-8888-4888-8888-888888888888';
  int generation = 0;
  bool pendingRelease = false;
  String? revocationToken;

  @override
  Future<String?> readLinkedAccountId() async => linkedAccountId;

  @override
  Future<void> writeLinkedAccountId(String accountId) async {
    linkedAccountId = accountId;
  }

  @override
  Future<void> clearLinkedAccountId() async {
    linkedAccountId = null;
  }

  @override
  Future<void> clearLinkedAccountIdIfMatches(String accountId) async {
    if (linkedAccountId == accountId) linkedAccountId = null;
  }

  @override
  Future<bool> hasAskedToLink(String accountId) async => false;

  @override
  Future<void> markAskedToLink(String accountId) async {}

  @override
  Future<String> readOrCreateWorkspaceId() async => workspaceId;

  @override
  Future<String> readOrCreateInstallationId() async => installationId;

  @override
  Future<int> readWorkspaceGeneration() async => generation;

  @override
  Future<int> advanceWorkspaceGeneration() async => ++generation;

  @override
  Future<void> writeRevocationToken(String token) async {
    revocationToken = token;
  }

  @override
  Future<String?> readRevocationToken() async => revocationToken;

  @override
  Future<void> clearRevocationToken() async {
    revocationToken = null;
  }

  @override
  Future<bool> hasPendingRelease() async => pendingRelease;

  @override
  Future<void> setPendingRelease(bool pending) async {
    pendingRelease = pending;
  }
}
