import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kami/core/persistence/local_sync_state.dart';
import 'package:kami/features/batches/domain/fruit_batch.dart';
import 'package:kami/features/batches/presentation/batch_providers.dart';
import 'package:kami/features/batches/presentation/batch_screens.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/orders/presentation/order_providers.dart';
import 'package:kami/features/scan/data/shelf_life/literature_shelf_life_advisor.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

void main() {
  testWidgets(
    'mixed batch keeps compact priority and shows all guidance in urgency order',
    (tester) async {
      final scans = [
        _record(1, RipenessStage.unripe),
        _record(2, RipenessStage.unripe),
        _record(3, RipenessStage.ripe),
        _record(4, RipenessStage.ripe),
        _record(5, RipenessStage.overripe),
        _record(6, RipenessStage.overripe),
      ];
      await _pumpSummary(
        tester,
        summary: const BatchSummary(total: 6, unripe: 2, ripe: 2, overripe: 2),
        scans: scans,
      );

      expect(
        find.text('2 overripe fruits need immediate attention.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('batch-shelf-life-sheet')), findsNothing);

      await tester.tap(find.byKey(const Key('batch-shelf-life-open')));
      await tester.pumpAndSettle();

      expect(find.text('Shelf-life & storage'), findsOneWidget);
      expect(find.text('Provisional literature estimate'), findsOneWidget);
      expect(
        find.text(
          'This batch has mixed ripeness. Follow the guidance for each stage '
          'separately.',
        ),
        findsOneWidget,
      );
      expect(find.text('Consume immediately'), findsOneWidget);
      expect(find.text('approximately 1–3 days'), findsOneWidget);
      expect(find.text('approximately 5–7 days'), findsOneWidget);
      expect(
        find.text('Consume immediately if still sound; otherwise discard.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Keep in the coolest shaded area available and consume soon. Brief '
          'refrigeration is only a short-term hold.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Keep whole at room temperature in a dry, ventilated, shaded area. '
          'Do not refrigerate while green.',
        ),
        findsOneWidget,
      );
      expect(find.text('Storage guidance'), findsNWidgets(3));
      expect(find.text(shelfLifeVariabilityDisclaimer), findsOneWidget);
      expect(find.textContaining('0–0'), findsNothing);
      expect(find.text('0 days'), findsNothing);

      final overripeTop = tester
          .getTopLeft(find.byKey(const Key('batch-shelf-life-stage-overripe')))
          .dy;
      final ripeTop = tester
          .getTopLeft(find.byKey(const Key('batch-shelf-life-stage-ripe')))
          .dy;
      final unripeTop = tester
          .getTopLeft(find.byKey(const Key('batch-shelf-life-stage-unripe')))
          .dy;
      expect(overripeTop, lessThan(ripeTop));
      expect(ripeTop, lessThan(unripeTop));
    },
  );

  testWidgets('single-stage batch omits the mixed note', (tester) async {
    final scans = [_record(1, RipenessStage.unripe)];
    await _pumpSummary(
      tester,
      summary: const BatchSummary(total: 1, unripe: 1, ripe: 0, overripe: 0),
      scans: scans,
    );

    expect(find.text('1 unripe fruit is still ripening.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('batch-shelf-life-open')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('batch-shelf-life-stage-unripe')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('batch-shelf-life-mixed-note')), findsNothing);
    expect(find.byKey(const Key('batch-shelf-life-stage-ripe')), findsNothing);
    expect(
      find.byKey(const Key('batch-shelf-life-stage-overripe')),
      findsNothing,
    );
  });

  testWidgets('two-stage batch prioritizes ripe fruit', (tester) async {
    final scans = [
      _record(1, RipenessStage.unripe),
      _record(2, RipenessStage.ripe),
      _record(3, RipenessStage.ripe),
    ];
    await _pumpSummary(
      tester,
      summary: const BatchSummary(total: 3, unripe: 1, ripe: 2, overripe: 0),
      scans: scans,
    );

    expect(find.text('2 ripe fruits should be used soon.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('batch-shelf-life-open')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('batch-shelf-life-stage-ripe')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('batch-shelf-life-stage-unripe')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('batch-shelf-life-stage-overripe')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('batch-shelf-life-mixed-note')),
      findsOneWidget,
    );
  });

  testWidgets('empty batch omits the priority and guidance action', (
    tester,
  ) async {
    await _pumpSummary(
      tester,
      summary: const BatchSummary(total: 0, unripe: 0, ripe: 0, overripe: 0),
      scans: const [],
    );

    expect(find.byKey(const Key('batch-shelf-life-priority')), findsNothing);
    expect(find.byKey(const Key('batch-shelf-life-open')), findsNothing);
  });

  testWidgets('unavailable persisted guidance uses the safe fallback', (
    tester,
  ) async {
    final scans = [
      _record(
        1,
        RipenessStage.ripe,
        shelfLife: const ShelfLifeUnavailable(
          reason: 'Legacy guidance is unavailable.',
          evidenceVersion: 'legacy-unavailable',
        ),
      ),
    ];
    await _pumpSummary(
      tester,
      summary: const BatchSummary(total: 1, unripe: 0, ripe: 1, overripe: 0),
      scans: scans,
    );
    await tester.tap(find.byKey(const Key('batch-shelf-life-open')));
    await tester.pumpAndSettle();

    expect(find.text('Guidance unavailable'), findsOneWidget);
    expect(
      find.text(
        'Legacy guidance is unavailable. Review the individual saved scans '
        'for details.',
      ),
      findsOneWidget,
    );
    expect(find.text('Storage guidance'), findsNothing);
  });

  testWidgets('inconsistent persisted guidance is never merged', (
    tester,
  ) async {
    final scans = [
      _record(1, RipenessStage.ripe),
      _record(
        2,
        RipenessStage.ripe,
        shelfLife: const ShelfLifeRange(
          minimum: 2,
          maximum: 4,
          unit: 'days',
          storageGuidance: 'Conflicting legacy guidance.',
          evidenceVersion: 'legacy-conflict',
        ),
      ),
    ];
    await _pumpSummary(
      tester,
      summary: const BatchSummary(total: 2, unripe: 0, ripe: 2, overripe: 0),
      scans: scans,
    );
    await tester.tap(find.byKey(const Key('batch-shelf-life-open')));
    await tester.pumpAndSettle();

    expect(find.text('Guidance unavailable'), findsOneWidget);
    expect(
      find.text(
        'Saved recommendations for this stage are inconsistent. Review the '
        'individual saved scans for details.',
      ),
      findsOneWidget,
    );
    expect(find.text('approximately 1–3 days'), findsNothing);
    expect(find.text('approximately 2–4 days'), findsNothing);
  });

  testWidgets('matching display guidance remains grouped across versions', (
    tester,
  ) async {
    final scans = [
      _record(1, RipenessStage.ripe),
      _record(
        2,
        RipenessStage.ripe,
        shelfLife: const ShelfLifeRange(
          minimum: 1,
          maximum: 3,
          unit: 'days',
          storageGuidance:
              'Keep in the coolest shaded area available and consume soon. '
              'Brief refrigeration is only a short-term hold.',
          evidenceVersion: 'future-version-same-display',
        ),
      ),
    ];
    await _pumpSummary(
      tester,
      summary: const BatchSummary(total: 2, unripe: 0, ripe: 2, overripe: 0),
      scans: scans,
    );
    await tester.tap(find.byKey(const Key('batch-shelf-life-open')));
    await tester.pumpAndSettle();

    expect(find.text('approximately 1–3 days'), findsOneWidget);
    expect(find.text('Guidance unavailable'), findsNothing);
  });

  testWidgets('locked Batch Details keeps guidance accessible', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final scan = _record(1, RipenessStage.overripe);
    final batch = FruitBatch(
      id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      name: 'Completed mangoes',
      fruit: FruitIdentifier.carabaoMango,
      createdAt: DateTime.utc(2026, 8, 8),
      updatedAt: DateTime.utc(2026, 8, 8),
      syncState: LocalSyncState.localOnly,
    );
    final snapshot = BatchSnapshot(
      batch: batch,
      summary: const BatchSummary(total: 1, unripe: 0, ripe: 0, overripe: 1),
      scans: [scan],
      isLocked: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          batchSnapshotProvider(
            batch.id,
          ).overrideWith((ref) => Stream.value(snapshot)),
          activeBatchOrderProvider(
            batch.id,
          ).overrideWith((ref) => Stream.value(null)),
        ],
        child: MaterialApp(home: BatchDetailsScreen(batchId: batch.id)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.text('This batch is read-only because its order is completed.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('batch-shelf-life-open')), findsOneWidget);
    await tester.tap(find.byKey(const Key('batch-shelf-life-open')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('batch-shelf-life-sheet')), findsOneWidget);
    expect(find.text('Consume immediately'), findsOneWidget);
  });
}

Future<void> _pumpSummary(
  WidgetTester tester, {
  required BatchSummary summary,
  required List<SavedScanRecord> scans,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: BatchSummaryCard(summary: summary, scans: scans),
        ),
      ),
    ),
  );
}

SavedScanRecord _record(
  int index,
  RipenessStage stage, {
  ShelfLifeEstimate? shelfLife,
}) {
  final sequence = index.toString().padLeft(8, '0');
  final savedAt = DateTime.utc(2026, 8, 8, 8, index);
  return SavedScanRecord(
    id: '$sequence-2222-4222-8222-222222222222',
    batchId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    fruit: FruitIdentifier.carabaoMango,
    ripeness: stage,
    modelConfidence: 0.87,
    modelVersion: 'test-model-v1',
    resultOrigin: ResultOrigin.onDeviceModel,
    shelfLife: shelfLife ?? _estimate(stage),
    localImageRelativePath: null,
    createdAt: savedAt,
    updatedAt: savedAt,
    syncState: LocalSyncState.localOnly,
  );
}

ShelfLifeEstimate _estimate(RipenessStage stage) {
  return const LiteratureShelfLifeAdvisor().estimate(
    ClassificationResult(
      fruit: FruitIdentifier.carabaoMango,
      ripeness: stage,
      modelConfidence: 0.87,
      modelVersion: 'test-model-v1',
      origin: ResultOrigin.onDeviceModel,
      requiresRetake: false,
    ),
  );
}
