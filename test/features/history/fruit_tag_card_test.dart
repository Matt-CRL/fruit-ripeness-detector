import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kami/features/history/data/app_private_retained_scan_image_store.dart';
import 'package:kami/features/history/data/drift_scan_record_repository.dart';
import 'package:kami/features/history/application/fruit_tag_sequence.dart';
import 'package:kami/features/history/application/save_scan_result.dart';
import 'package:kami/features/history/presentation/fruit_tag_card.dart';
import 'package:kami/features/scan/domain/scan_models.dart';
import 'package:kami/features/scan/presentation/scan_image_provider.dart';
import 'package:kami/features/scan/presentation/scan_screens.dart';

import '../../helpers/fake_history_storage.dart';

void main() {
  testWidgets('Upload suggestion shows the physical-label guidance', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FruitTagCard.uploadSuggestion(fruitTagId: 'CH-000001'),
          ),
        ),
      ),
    );

    expect(find.text('Saved offline'), findsNothing);
    expect(find.text('Suggested next step'), findsOneWidget);
    expect(find.text('Label this fruit'), findsOneWidget);
    expect(
      find.text('Write this ID on a tag and attach it to the fruit.'),
      findsOneWidget,
    );
    expect(find.text('FRUIT ID'), findsOneWidget);
    expect(find.text('CH-000001'), findsOneWidget);
    expect(find.text('Copy ID'), findsNothing);
    expect(find.textContaining('Chami cannot verify'), findsNothing);
    expect(find.bySemanticsLabel('Chami logo'), findsOneWidget);
  });

  testWidgets('real Upload save displays its reserved ID suggestion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeScanRecordRepository();
    final imageStore = FakeRetainedScanImageStore();
    addTearDown(repository.dispose);

    const preview = ScanPreview(
      image: SelectedScanImage(path: 'fake://upload', name: 'upload.jpg'),
      classification: ClassificationResult(
        fruit: FruitIdentifier.carabaoMango,
        ripeness: RipenessStage.ripe,
        modelConfidence: 0.9,
        modelVersion: 'test-model-v1',
        origin: ResultOrigin.onDeviceModel,
        requiresRetake: false,
      ),
      shelfLife: ShelfLifeRange(
        minimum: 1,
        maximum: 3,
        unit: 'days',
        storageGuidance: 'Keep cool.',
        evidenceVersion: 'test-v1',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scanRecordRepositoryProvider.overrideWithValue(repository),
          retainedScanImageStoreProvider.overrideWithValue(imageStore),
          saveScanResultUseCaseProvider.overrideWithValue(
            SaveScanResultUseCase(
              repository,
              imageStore,
              () => DateTime.utc(2026, 9, 11),
            ),
          ),
          fruitTagSequenceProvider.overrideWithValue(
            _TestFruitTagSequence('CH-000041'),
          ),
          scanImageProviderFactoryProvider.overrideWithValue(
            (_) => MemoryImage(Uint8List.fromList(<int>[0])),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ScanResultScreen(preview: preview)),
        ),
      ),
    );
    await tester.pump();
    final saveButton = find.widgetWithText(FilledButton, 'Save Result');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save to History'));
    await tester.pumpAndSettle();

    expect(find.text('Label this fruit'), findsOneWidget);
    expect(find.text('CH-000041'), findsOneWidget);
    expect(find.text('Copy ID'), findsNothing);
    expect(find.textContaining('Chami cannot verify'), findsNothing);
    expect((await repository.listActive()).single.fruitTagId, 'CH-000041');
  });

  testWidgets('Demo detail uses a record ID without label guidance', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FruitTagCard.savedDetail(fruitTagId: 'CH-000002', isDemo: true),
        ),
      ),
    );

    expect(find.text('Demo record ID'), findsOneWidget);
    expect(find.text('CH-000002'), findsOneWidget);
    expect(find.text('Label this fruit'), findsNothing);
    expect(find.text('Suggested next step'), findsNothing);
  });

  testWidgets('Upload suggestion remains usable at large text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FruitTagCard.uploadSuggestion(fruitTagId: 'CH-000003'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('CH-000003'), findsOneWidget);
  });

  testWidgets('Fruit tag punch holes have visible outlines in both themes', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: const Scaffold(
            body: FruitTagCard.uploadSuggestion(fruitTagId: 'CH-000004'),
          ),
        ),
      );
      await tester.pump();

      final notches = tester
          .widgetList<DecoratedBox>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is DecoratedBox &&
                  widget.decoration is BoxDecoration &&
                  (widget.decoration as BoxDecoration).shape == BoxShape.circle,
            ),
          )
          .toList(growable: false);
      expect(notches, hasLength(2));
      final notchClips = tester
          .widgetList<ClipRect>(find.byType(ClipRect))
          .toList(growable: false);
      expect(notchClips, hasLength(2));
      for (final notchClip in notchClips) {
        expect(tester.getSize(find.byWidget(notchClip)), const Size(14, 28));
      }
      for (final notch in notches) {
        final decoration = notch.decoration as BoxDecoration;
        expect(decoration.border, isNotNull);
        expect(decoration.border!.top.width, 1.5);
      }
    }
  });
}

final class _TestFruitTagSequence implements WorkspaceFruitTagSequence {
  _TestFruitTagSequence(this.value);

  final String value;

  @override
  Future<String> reserveNext() async => value;

  @override
  Future<void> reconcileCurrentWorkspace() async {}
}
