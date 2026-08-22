import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kami/features/scan/application/live_camera.dart';
import 'package:kami/features/scan/domain/ripeness_classifier.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

enum LiveScanPhase { initializing, active, paused, suspended, failed }

final class LiveScanSnapshot {
  const LiveScanSnapshot({required this.frame, required this.classification});

  final LiveCameraFrame frame;
  final ClassificationResult classification;
}

final class LiveScanController extends ChangeNotifier {
  LiveScanController({
    required LiveCameraGateway cameraGateway,
    required LiveRipenessClassifier classifier,
    Duration inferenceInterval = const Duration(milliseconds: 500),
  }) : this._(cameraGateway, classifier, inferenceInterval);

  LiveScanController._(
    this._cameraGateway,
    this._classifier,
    this.inferenceInterval,
  ) {
    _clock.start();
  }

  final LiveCameraGateway _cameraGateway;
  final LiveRipenessClassifier _classifier;
  final Duration inferenceInterval;
  final Stopwatch _clock = Stopwatch();

  LiveCameraSession? _session;
  LiveScanPhase _phase = LiveScanPhase.initializing;
  LiveScanSnapshot? _snapshot;
  Duration? _lastInferenceStarted;
  bool _inferenceInFlight = false;
  bool _closed = false;
  int _generation = 0;
  String? _failureMessage;
  LiveCameraFailureKind? _failureKind;
  NormalizedCropRect? _targetCrop;

  LiveCameraSession? get session => _session;
  LiveScanPhase get phase => _phase;
  LiveScanSnapshot? get snapshot => _snapshot;
  ClassificationResult? get result => _snapshot?.classification;
  bool get isAnalyzing => _inferenceInFlight;
  String? get failureMessage => _failureMessage;
  LiveCameraFailureKind? get failureKind => _failureKind;
  NormalizedCropRect? get targetCrop => _targetCrop;

  void updateTargetCrop(NormalizedCropRect crop) {
    if (_closed || !crop.isValid) {
      return;
    }
    final current = _targetCrop;
    if (current != null &&
        current.left == crop.left &&
        current.top == crop.top &&
        current.width == crop.width &&
        current.height == crop.height) {
      return;
    }
    _targetCrop = crop;
    _notify();
  }

  Future<void> initialize() async {
    if (_closed) {
      return;
    }
    final generation = ++_generation;
    _phase = LiveScanPhase.initializing;
    _snapshot = null;
    _failureMessage = null;
    _failureKind = null;
    _inferenceInFlight = false;
    _lastInferenceStarted = null;
    _targetCrop = null;
    _notify();
    await _disposeSession();
    if (!_isCurrent(generation)) {
      return;
    }

    try {
      final session = await _cameraGateway.openRearCamera();
      if (!_isCurrent(generation)) {
        await session.dispose();
        return;
      }
      _session = session;
      _phase = LiveScanPhase.active;
      _notify();
      await _startStream(session, generation);
    } on LiveCameraFailure catch (error) {
      await _fail(error, generation);
    } on Object catch (error) {
      await _fail(
        LiveCameraFailure(
          LiveCameraFailureKind.initialization,
          'Chami could not start Live Scan.',
          error,
        ),
        generation,
      );
    }
  }

  Future<void> pause() async {
    final session = _session;
    if (_closed || _phase != LiveScanPhase.active || session == null) {
      return;
    }
    final generation = ++_generation;
    _phase = LiveScanPhase.paused;
    _inferenceInFlight = false;
    _notify();
    try {
      await session.stopImageStream();
    } on LiveCameraFailure catch (error) {
      await _fail(error, generation);
    }
  }

  Future<void> resume() async {
    final session = _session;
    if (_closed || _phase != LiveScanPhase.paused) {
      return;
    }
    if (session == null) {
      await initialize();
      return;
    }
    final generation = ++_generation;
    _phase = LiveScanPhase.active;
    _snapshot = null;
    _lastInferenceStarted = null;
    _failureMessage = null;
    _failureKind = null;
    _notify();
    try {
      await _startStream(session, generation);
    } on LiveCameraFailure catch (error) {
      await _fail(error, generation);
    }
  }

  Future<void> suspendForLifecycle() async {
    if (_closed || _phase == LiveScanPhase.suspended) {
      return;
    }
    if (_phase == LiveScanPhase.initializing && _session == null) {
      // Android's permission dialog briefly inactivates the app while camera
      // initialization is still waiting. Let that one initialization finish.
      return;
    }
    ++_generation;
    _phase = LiveScanPhase.suspended;
    _snapshot = null;
    _inferenceInFlight = false;
    _notify();
    await _disposeSession();
  }

  Future<void> _startStream(LiveCameraSession session, int generation) async {
    await session.startImageStream(
      shouldCopyFrame: () => _shouldAcceptFrame(generation),
      onFrame: (frame) => unawaited(_classify(frame, generation)),
    );
  }

  bool _shouldAcceptFrame(int generation) {
    if (!_isCurrent(generation) ||
        _phase != LiveScanPhase.active ||
        _inferenceInFlight) {
      return false;
    }
    if (_targetCrop == null) {
      return false;
    }
    final lastStarted = _lastInferenceStarted;
    return lastStarted == null ||
        _clock.elapsed - lastStarted >= inferenceInterval;
  }

  Future<void> _classify(LiveCameraFrame frame, int generation) async {
    if (!_shouldAcceptFrame(generation)) {
      return;
    }
    final targetCrop = _targetCrop;
    if (targetCrop == null) {
      return;
    }
    _inferenceInFlight = true;
    _lastInferenceStarted = _clock.elapsed;
    _notify();
    try {
      final classifiedFrame = frame.copyWith(targetCrop: targetCrop);
      final result = await _classifier.classifyFrame(classifiedFrame);
      if (_isCurrent(generation) && _phase == LiveScanPhase.active) {
        _snapshot = LiveScanSnapshot(frame: frame, classification: result);
      }
    } on RipenessClassificationException catch (error) {
      await _fail(
        LiveCameraFailure(
          LiveCameraFailureKind.streaming,
          error.userMessage,
          error,
        ),
        generation,
      );
      return;
    } on Object catch (error) {
      await _fail(
        LiveCameraFailure(
          LiveCameraFailureKind.streaming,
          'Chami could not analyze the live camera frame.',
          error,
        ),
        generation,
      );
      return;
    } finally {
      if (_isCurrent(generation)) {
        _inferenceInFlight = false;
        _notify();
      }
    }
  }

  Future<void> _fail(LiveCameraFailure error, int generation) async {
    if (!_isCurrent(generation)) {
      return;
    }
    ++_generation;
    _phase = LiveScanPhase.failed;
    _failureMessage = error.message;
    _failureKind = error.kind;
    _inferenceInFlight = false;
    _notify();
    await _disposeSession();
  }

  Future<void> _disposeSession() async {
    final session = _session;
    _session = null;
    if (session == null) {
      return;
    }
    try {
      await session.dispose();
    } on Object {
      // Camera disposal is best effort during navigation and lifecycle changes.
    }
  }

  bool _isCurrent(int generation) => !_closed && generation == _generation;

  void _notify() {
    if (!_closed) {
      notifyListeners();
    }
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    ++_generation;
    await _disposeSession();
    super.dispose();
  }
}
