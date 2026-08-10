import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kami/features/scan/application/live_camera.dart';
import 'package:kami/features/scan/application/live_scan_controller.dart';
import 'package:kami/features/scan/domain/ripeness_classifier.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

void main() {
  test('drops frames while one live inference is in flight', () async {
    final session = _FakeLiveCameraSession();
    final classifier = _CompletingLiveClassifier();
    final controller = LiveScanController(
      cameraGateway: _FakeLiveCameraGateway([session]),
      classifier: classifier,
      inferenceInterval: Duration.zero,
    );
    addTearDown(controller.close);

    await controller.initialize();
    session.emit(_frame);
    session.emit(_frame);
    session.emit(_frame);

    expect(classifier.callCount, 1);
    expect(controller.isAnalyzing, isTrue);

    classifier.completeNext(_result);
    await _flushAsyncWork();

    expect(controller.result, same(_result));
    expect(controller.isAnalyzing, isFalse);
  });

  test(
    'pause keeps the result and resume starts with a fresh result',
    () async {
      final session = _FakeLiveCameraSession();
      final classifier = _ImmediateLiveClassifier();
      final controller = LiveScanController(
        cameraGateway: _FakeLiveCameraGateway([session]),
        classifier: classifier,
        inferenceInterval: Duration.zero,
      );
      addTearDown(controller.close);

      await controller.initialize();
      session.emit(_frame);
      await _flushAsyncWork();
      expect(controller.result, isNotNull);

      await controller.pause();
      expect(controller.phase, LiveScanPhase.paused);
      expect(controller.result, isNotNull);
      expect(session.stopCount, 1);

      await controller.resume();
      expect(controller.phase, LiveScanPhase.active);
      expect(controller.result, isNull);
      expect(session.startCount, 2);
    },
  );

  test(
    'keeps the exact admitted frame paired with its completed result',
    () async {
      final session = _FakeLiveCameraSession();
      final classifier = _CompletingLiveClassifier();
      final controller = LiveScanController(
        cameraGateway: _FakeLiveCameraGateway([session]),
        classifier: classifier,
        inferenceInterval: Duration.zero,
      );
      addTearDown(controller.close);

      final firstFrame = _frameWithLuminance(64);
      final secondFrame = _frameWithLuminance(192);
      await controller.initialize();

      session.emit(firstFrame);
      classifier.completeNext(_result);
      await _flushAsyncWork();
      expect(controller.snapshot?.frame, same(firstFrame));
      expect(controller.snapshot?.classification, same(_result));

      session.emit(secondFrame);
      classifier.completeNext(_secondResult);
      await _flushAsyncWork();
      expect(controller.snapshot?.frame, same(secondFrame));
      expect(controller.snapshot?.classification, same(_secondResult));

      await controller.pause();
      expect(controller.snapshot?.frame, same(secondFrame));
      expect(controller.snapshot?.classification, same(_secondResult));
    },
  );

  test(
    'lifecycle suspension disposes camera and initialization opens a new one',
    () async {
      final first = _FakeLiveCameraSession();
      final second = _FakeLiveCameraSession();
      final gateway = _FakeLiveCameraGateway([first, second]);
      final controller = LiveScanController(
        cameraGateway: gateway,
        classifier: _ImmediateLiveClassifier(),
      );
      addTearDown(controller.close);

      await controller.initialize();
      await controller.suspendForLifecycle();

      expect(controller.phase, LiveScanPhase.suspended);
      expect(first.disposeCount, 1);

      await controller.initialize();
      expect(controller.phase, LiveScanPhase.active);
      expect(controller.session, same(second));
      expect(gateway.openCount, 2);
    },
  );

  test(
    'permission-dialog lifecycle interruption keeps initialization alive',
    () async {
      final session = _FakeLiveCameraSession();
      final gateway = _PendingLiveCameraGateway();
      final controller = LiveScanController(
        cameraGateway: gateway,
        classifier: _ImmediateLiveClassifier(),
      );
      addTearDown(controller.close);

      final initialization = controller.initialize();
      await _flushAsyncWork();
      await controller.suspendForLifecycle();

      expect(controller.phase, LiveScanPhase.initializing);
      gateway.complete(session);
      await initialization;

      expect(controller.phase, LiveScanPhase.active);
      expect(controller.session, same(session));
      expect(session.disposeCount, 0);
    },
  );
}

const _result = ClassificationResult(
  fruit: FruitIdentifier.carabaoMango,
  ripeness: RipenessStage.ripe,
  modelConfidence: 0.82,
  modelVersion: 'test-model',
  origin: ResultOrigin.onDeviceModel,
  requiresRetake: false,
);

const _secondResult = ClassificationResult(
  fruit: FruitIdentifier.lakatanBanana,
  ripeness: RipenessStage.overripe,
  modelConfidence: 0.74,
  modelVersion: 'test-model',
  origin: ResultOrigin.onDeviceModel,
  requiresRetake: false,
);

final _frame = LiveCameraFrame(
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

LiveCameraFrame _frameWithLuminance(int luminance) {
  return LiveCameraFrame(
    width: 2,
    height: 2,
    rotationDegrees: 0,
    pixelFormat: LiveCameraPixelFormat.yuv420,
    planes: [
      LiveCameraPlane(
        bytes: Uint8List.fromList(List<int>.filled(4, luminance)),
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
}

Future<void> _flushAsyncWork() => Future<void>.delayed(Duration.zero);

final class _FakeLiveCameraGateway implements LiveCameraGateway {
  _FakeLiveCameraGateway(this.sessions);

  final List<_FakeLiveCameraSession> sessions;
  int openCount = 0;

  @override
  Future<LiveCameraSession> openRearCamera() async {
    final session = sessions[openCount];
    openCount++;
    return session;
  }
}

final class _PendingLiveCameraGateway implements LiveCameraGateway {
  final Completer<LiveCameraSession> _completer =
      Completer<LiveCameraSession>();

  @override
  Future<LiveCameraSession> openRearCamera() => _completer.future;

  void complete(LiveCameraSession session) => _completer.complete(session);
}

final class _FakeLiveCameraSession implements LiveCameraSession {
  LiveFrameAdmission? _shouldCopyFrame;
  LiveFrameCallback? _onFrame;
  int startCount = 0;
  int stopCount = 0;
  int disposeCount = 0;

  @override
  double get previewAspectRatio => 4 / 3;

  @override
  Widget buildPreview() => const ColoredBox(color: Color(0xFF112233));

  @override
  Future<void> startImageStream({
    required LiveFrameAdmission shouldCopyFrame,
    required LiveFrameCallback onFrame,
  }) async {
    startCount++;
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
  Future<void> dispose() async {
    disposeCount++;
  }
}

final class _CompletingLiveClassifier implements LiveRipenessClassifier {
  final List<Completer<ClassificationResult>> _completers = [];
  int callCount = 0;

  @override
  Future<ClassificationResult> classifyFrame(LiveCameraFrame frame) {
    callCount++;
    final completer = Completer<ClassificationResult>();
    _completers.add(completer);
    return completer.future;
  }

  void completeNext(ClassificationResult result) {
    _completers.removeAt(0).complete(result);
  }
}

final class _ImmediateLiveClassifier implements LiveRipenessClassifier {
  @override
  Future<ClassificationResult> classifyFrame(LiveCameraFrame frame) async {
    return _result;
  }
}
