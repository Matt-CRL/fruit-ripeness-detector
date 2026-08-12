import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kami/core/database/app_database_provider.dart';
import 'package:kami/core/persistence/entity_id_generator.dart';
import 'package:kami/features/history/application/save_scan_result.dart';
import 'package:kami/features/scan/application/live_camera.dart';
import 'package:kami/features/scan/application/live_scan_frame_store.dart';
import 'package:kami/features/scan/application/live_scan_providers.dart';
import 'package:kami/features/scan/data/camera/app_private_live_scan_frame_store.dart';
import 'package:kami/features/scan/domain/ripeness_classifier.dart';
import 'package:kami/features/scan/domain/scan_models.dart';
import 'package:kami/features/scan/presentation/live_scan_screen.dart';

import '../../helpers/fake_history_storage.dart';

void main() {
  testWidgets('shows live result and supports pause and resume', (
    tester,
  ) async {
    final session = _WidgetTestCameraSession();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          liveCameraGatewayProvider.overrideWithValue(
            _WidgetTestCameraGateway(session),
          ),
          liveScanClassifierProvider.overrideWithValue(_WidgetTestClassifier()),
        ],
        child: const MaterialApp(home: LiveScanScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Center one clear, well-lit fruit'), findsOneWidget);
    expect(find.text('Analyzing the camera view…'), findsOneWidget);

    session.emit(_widgetFrame);
    await tester.pump();
    await tester.pump();

    expect(find.text('Ripe Carabao mango'), findsOneWidget);
    expect(find.text('82% model confidence'), findsOneWidget);

    await tester.tap(find.text('Pause result'));
    await tester.pump();
    expect(find.text('Scanning paused'), findsOneWidget);
    expect(find.text('Resume scanning'), findsOneWidget);

    await tester.tap(find.text('Resume scanning'));
    await tester.pump();
    expect(find.text('Analyzing the camera view…'), findsOneWidget);
  });

  testWidgets('explains denied camera permission and offers retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          liveCameraGatewayProvider.overrideWithValue(
            const _DeniedCameraGateway(),
          ),
          liveScanClassifierProvider.overrideWithValue(_WidgetTestClassifier()),
        ],
        child: const MaterialApp(home: LiveScanScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Camera permission needed'), findsOneWidget);
    expect(
      find.text('Camera access was denied. Allow it to use Live Scan.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets(
    'saves the displayed frame and result once with a direct batch action',
    (tester) async {
      final session = _WidgetTestCameraSession();
      final classifier = _WidgetTestClassifier();
      final frameStore = _FakeLiveScanFrameStore();
      final repository = FakeScanRecordRepository();
      final retainedImages = FakeRetainedScanImageStore();
      final saveResult = SaveScanResultUseCase(
        repository,
        retainedImages,
        () => DateTime.utc(2026, 7, 31),
      );
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const LiveScanScreen(),
          ),
          GoRoute(
            path: '/saved-scans/:scanId/add-to-batch',
            builder: (context, state) => Scaffold(
              body: Text('Batch target ${state.pathParameters['scanId']}'),
            ),
          ),
        ],
      );
      addTearDown(repository.dispose);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            liveCameraGatewayProvider.overrideWithValue(
              _WidgetTestCameraGateway(session),
            ),
            liveScanClassifierProvider.overrideWithValue(classifier),
            liveScanFrameStoreProvider.overrideWithValue(frameStore),
            saveScanResultUseCaseProvider.overrideWithValue(saveResult),
            entityIdGeneratorProvider.overrideWithValue(
              const _FixedIdGenerator(),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();

      session.emit(_savableWidgetFrame);
      await tester.pump();
      await tester.pump();
      expect(find.text('Save Result'), findsOneWidget);

      await tester.tap(find.text('Save Result'));
      await tester.pumpAndSettle();

      expect(session.stopCount, 1);
      expect(classifier.callCount, 1);
      expect(frameStore.writtenFrames, [same(_savableWidgetFrame)]);
      expect(frameStore.removedImages, hasLength(1));
      expect(retainedImages.retainCalls, 1);
      final records = await repository.listActive();
      expect(records, hasLength(1));
      expect(records.single.fruit, FruitIdentifier.carabaoMango);
      expect(records.single.ripeness, RipenessStage.ripe);
      expect(records.single.modelConfidence, 0.82);
      expect(records.single.resultOrigin, ResultOrigin.onDeviceModel);
      expect(find.text('Saved to History'), findsNothing);
      expect(find.text('Scan another fruit'), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'Add to Batch'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextButton, 'View in History'),
        findsOneWidget,
      );
      expect(find.text('Estimated shelf life: 1-3 days'), findsOneWidget);
      expect(find.textContaining('Storage:'), findsOneWidget);
      expect(find.text('Result saved'), findsNothing);
      expect(find.text('Would you like to add it to a batch?'), findsNothing);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Add to Batch'));
      await tester.pumpAndSettle();

      expect(
        find.text('Batch target 22222222-2222-4222-8222-222222222222'),
        findsOneWidget,
      );
    },
  );

  testWidgets('a failed frame save keeps the paused snapshot for retry', (
    tester,
  ) async {
    final session = _WidgetTestCameraSession();
    final classifier = _WidgetTestClassifier();
    final frameStore = _FakeLiveScanFrameStore()..failWrites = true;
    final repository = FakeScanRecordRepository();
    final retainedImages = FakeRetainedScanImageStore();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          liveCameraGatewayProvider.overrideWithValue(
            _WidgetTestCameraGateway(session),
          ),
          liveScanClassifierProvider.overrideWithValue(classifier),
          liveScanFrameStoreProvider.overrideWithValue(frameStore),
          saveScanResultUseCaseProvider.overrideWithValue(
            SaveScanResultUseCase(
              repository,
              retainedImages,
              () => DateTime.utc(2026, 7, 31),
            ),
          ),
          entityIdGeneratorProvider.overrideWithValue(
            const _FixedIdGenerator(),
          ),
        ],
        child: const MaterialApp(home: LiveScanScreen()),
      ),
    );
    await tester.pump();
    session.emit(_savableWidgetFrame);
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Save Result'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('could not save this live result'),
      findsOneWidget,
    );
    expect(find.text('Scanning paused'), findsOneWidget);
    expect(await repository.listActive(), isEmpty);
    expect(classifier.callCount, 1);

    frameStore.failWrites = false;
    await tester.tap(find.text('Save Result'));
    await tester.pumpAndSettle();

    expect(find.text('Saved to History'), findsNothing);
    expect(find.text('Result saved'), findsNothing);
    expect(await repository.listActive(), hasLength(1));
    expect(classifier.callCount, 1);
    expect(find.text('Add to Batch'), findsOneWidget);
    expect(find.text('Scan another fruit'), findsOneWidget);
  });
}

final class _WidgetTestCameraGateway implements LiveCameraGateway {
  const _WidgetTestCameraGateway(this.session);

  final _WidgetTestCameraSession session;

  @override
  Future<LiveCameraSession> openRearCamera() async => session;
}

final class _DeniedCameraGateway implements LiveCameraGateway {
  const _DeniedCameraGateway();

  @override
  Future<LiveCameraSession> openRearCamera() {
    throw const LiveCameraFailure(
      LiveCameraFailureKind.permissionDenied,
      'Camera access was denied. Allow it to use Live Scan.',
    );
  }
}

final class _WidgetTestCameraSession implements LiveCameraSession {
  LiveFrameAdmission? _shouldCopyFrame;
  LiveFrameCallback? _onFrame;
  int stopCount = 0;

  @override
  double get previewAspectRatio => 4 / 3;

  @override
  Widget buildPreview() => const ColoredBox(color: Colors.green);

  @override
  Future<void> startImageStream({
    required LiveFrameAdmission shouldCopyFrame,
    required LiveFrameCallback onFrame,
  }) async {
    _shouldCopyFrame = shouldCopyFrame;
    _onFrame = onFrame;
  }

  void emit(LiveCameraFrame frame) {
    if (_shouldCopyFrame?.call() ?? false) {
      _onFrame?.call(frame);
    }
  }

  @override
  Future<void> stopImageStream() async {
    stopCount++;
  }

  @override
  Future<void> dispose() async {}
}

final class _WidgetTestClassifier implements LiveRipenessClassifier {
  int callCount = 0;

  @override
  Future<ClassificationResult> classifyFrame(LiveCameraFrame frame) async {
    callCount++;
    return const ClassificationResult(
      fruit: FruitIdentifier.carabaoMango,
      ripeness: RipenessStage.ripe,
      modelConfidence: 0.82,
      modelVersion: 'test-model',
      origin: ResultOrigin.onDeviceModel,
      requiresRetake: false,
    );
  }
}

const _widgetFrame = LiveCameraFrame(
  width: 2,
  height: 2,
  rotationDegrees: 0,
  pixelFormat: LiveCameraPixelFormat.yuv420,
  planes: [],
);

final _savableWidgetFrame = LiveCameraFrame(
  width: 2,
  height: 2,
  rotationDegrees: 0,
  pixelFormat: LiveCameraPixelFormat.yuv420,
  planes: [
    LiveCameraPlane(
      bytes: Uint8List.fromList([128, 128, 128, 128]),
      bytesPerRow: 2,
      bytesPerPixel: 1,
    ),
    LiveCameraPlane(
      bytes: Uint8List.fromList([128]),
      bytesPerRow: 1,
      bytesPerPixel: 1,
    ),
    LiveCameraPlane(
      bytes: Uint8List.fromList([128]),
      bytesPerRow: 1,
      bytesPerPixel: 1,
    ),
  ],
);

final class _FakeLiveScanFrameStore implements LiveScanFrameStore {
  final List<LiveCameraFrame> writtenFrames = [];
  final List<SelectedScanImage> removedImages = [];
  bool failWrites = false;

  @override
  Future<SelectedScanImage> writeTemporary(LiveCameraFrame frame) async {
    writtenFrames.add(frame);
    if (failWrites) {
      throw const LiveScanFrameStoreException('Synthetic frame write failure.');
    }
    return const SelectedScanImage(
      path: '/virtual/live-scan.jpg',
      name: 'live-scan.jpg',
    );
  }

  @override
  Future<void> removeTemporary(SelectedScanImage image) async {
    removedImages.add(image);
  }
}

final class _FixedIdGenerator implements EntityIdGenerator {
  const _FixedIdGenerator();

  @override
  String nextId() => '22222222-2222-4222-8222-222222222222';
}
