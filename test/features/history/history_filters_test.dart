import 'package:flutter_test/flutter_test.dart';
import 'package:kami/core/persistence/local_sync_state.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/history/presentation/history_filters.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

void main() {
  test('combines fruit, ripeness, and batch filters with AND semantics', () {
    final records = [
      _record(
        id: '11111111-1111-4111-8111-111111111111',
        fruit: FruitIdentifier.carabaoMango,
        ripeness: RipenessStage.ripe,
        inBatch: true,
        createdAt: DateTime(2026, 8, 6, 10),
      ),
      _record(
        id: '22222222-2222-4222-8222-222222222222',
        fruit: FruitIdentifier.carabaoMango,
        ripeness: RipenessStage.unripe,
        inBatch: false,
        createdAt: DateTime(2026, 8, 5, 10),
      ),
      _record(
        id: '33333333-3333-4333-8333-333333333333',
        fruit: FruitIdentifier.redPapaya,
        ripeness: RipenessStage.ripe,
        inBatch: true,
        createdAt: DateTime(2026, 8, 4, 10),
      ),
    ];

    final filtered = const HistoryFilters(
      fruit: FruitIdentifier.carabaoMango,
      ripeness: RipenessStage.ripe,
      inBatch: true,
    ).apply(records);

    expect(filtered.map((record) => record.id), [
      '11111111-1111-4111-8111-111111111111',
    ]);
  });

  test('specific date uses local calendar boundaries', () {
    final selectedDay = DateTime(2026, 8, 5, 12);
    final records = [
      _record(
        id: '44444444-4444-4444-8444-444444444444',
        createdAt: DateTime(2026, 8, 5, 0, 1),
      ),
      _record(
        id: '55555555-5555-4555-8555-555555555555',
        createdAt: DateTime(2026, 8, 6, 0, 1),
      ),
    ];

    final filtered = HistoryFilters(
      dateKind: HistoryDateFilterKind.specificDate,
      specificDate: selectedDay,
    ).apply(records, now: DateTime(2026, 8, 6, 12));

    expect(filtered.map((record) => record.id), [
      '44444444-4444-4444-8444-444444444444',
    ]);
  });

  test(
    'date range includes both selected calendar days and keeps newest first',
    () {
      final records = [
        _record(
          id: '66666666-6666-4666-8666-666666666666',
          createdAt: DateTime(2026, 8, 3, 10),
        ),
        _record(
          id: '77777777-7777-4777-8777-777777777777',
          createdAt: DateTime(2026, 8, 5, 10),
        ),
        _record(
          id: '88888888-8888-4888-8888-888888888888',
          createdAt: DateTime(2026, 8, 6, 10),
        ),
      ];

      final filtered = HistoryFilters(
        dateKind: HistoryDateFilterKind.dateRange,
        rangeStart: DateTime(2026, 8, 3),
        rangeEnd: DateTime(2026, 8, 5),
      ).apply(records);

      expect(filtered.map((record) => record.id), [
        '77777777-7777-4777-8777-777777777777',
        '66666666-6666-4666-8666-666666666666',
      ]);
    },
  );

  test('oldest sort reverses the default newest-first order', () {
    final records = [
      _record(
        id: '99999999-9999-4999-8999-999999999999',
        createdAt: DateTime(2026, 8, 6, 10),
      ),
      _record(
        id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        createdAt: DateTime(2026, 8, 3, 10),
      ),
    ];

    final filtered = const HistoryFilters(
      sortOrder: HistorySortOrder.oldestFirst,
    ).apply(records);

    expect(filtered.map((record) => record.id), [
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      '99999999-9999-4999-8999-999999999999',
    ]);
  });
}

SavedScanRecord _record({
  required String id,
  DateTime? createdAt,
  FruitIdentifier fruit = FruitIdentifier.carabaoMango,
  RipenessStage ripeness = RipenessStage.ripe,
  bool inBatch = false,
}) {
  final localCreatedAt = createdAt ?? DateTime(2026, 8, 1, 10);
  final utcCreatedAt = localCreatedAt.toUtc();
  return SavedScanRecord(
    id: id,
    fruit: fruit,
    ripeness: ripeness,
    modelConfidence: 0.87,
    modelVersion: 'filter-test-v1',
    resultOrigin: ResultOrigin.demo,
    shelfLife: const ShelfLifeUnavailable(
      reason: 'Unavailable for test',
      evidenceVersion: 'test-v1',
    ),
    createdAt: utcCreatedAt,
    updatedAt: utcCreatedAt,
    syncState: LocalSyncState.localOnly,
    batchId: inBatch ? '99999999-9999-4999-8999-999999999999' : null,
  );
}
