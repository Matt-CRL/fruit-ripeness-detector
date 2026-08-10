import 'dart:typed_data';

import 'package:kami/features/scan/domain/scan_models.dart';

abstract interface class RipenessClassifier {
  Future<ClassificationResult> classify(String imagePath);
}

abstract interface class LiveRipenessClassifier {
  Future<ClassificationResult> classifyFrame(LiveCameraFrame frame);
}

enum LiveCameraPixelFormat { yuv420 }

final class LiveCameraPlane {
  const LiveCameraPlane({
    required this.bytes,
    required this.bytesPerRow,
    required this.bytesPerPixel,
  });

  final Uint8List bytes;
  final int bytesPerRow;
  final int bytesPerPixel;
}

final class LiveCameraFrame {
  const LiveCameraFrame({
    required this.width,
    required this.height,
    required this.rotationDegrees,
    required this.pixelFormat,
    required this.planes,
  });

  final int width;
  final int height;
  final int rotationDegrees;
  final LiveCameraPixelFormat pixelFormat;
  final List<LiveCameraPlane> planes;
}

abstract interface class ShelfLifeAdvisor {
  ShelfLifeEstimate estimate(ClassificationResult classification);
}

final class RipenessClassificationException implements Exception {
  const RipenessClassificationException(this.userMessage, [this.cause]);

  final String userMessage;
  final Object? cause;

  @override
  String toString() => 'RipenessClassificationException: $userMessage';
}
