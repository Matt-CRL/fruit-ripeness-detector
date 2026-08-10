import 'package:flutter/widgets.dart';
import 'package:kami/features/scan/domain/ripeness_classifier.dart';

typedef LiveFrameAdmission = bool Function();
typedef LiveFrameCallback = void Function(LiveCameraFrame frame);

abstract interface class LiveCameraGateway {
  Future<LiveCameraSession> openRearCamera();
}

abstract interface class LiveCameraSession {
  double get previewAspectRatio;

  Widget buildPreview();

  Future<void> startImageStream({
    required LiveFrameAdmission shouldCopyFrame,
    required LiveFrameCallback onFrame,
  });

  Future<void> stopImageStream();

  Future<void> dispose();
}

enum LiveCameraFailureKind {
  permissionDenied,
  permissionPermanentlyDenied,
  noRearCamera,
  unsupportedStreaming,
  initialization,
  streaming,
}

final class LiveCameraFailure implements Exception {
  const LiveCameraFailure(this.kind, this.message, [this.cause]);

  final LiveCameraFailureKind kind;
  final String message;
  final Object? cause;

  @override
  String toString() => 'LiveCameraFailure: $message';
}
