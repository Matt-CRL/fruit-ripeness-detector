import 'dart:typed_data';

import 'package:kami/features/scan/domain/scan_models.dart';

abstract interface class RipenessClassifier {
  Future<ClassificationResult> classify(String imagePath);
}

abstract interface class LiveRipenessClassifier {
  Future<ClassificationResult> classifyFrame(LiveCameraFrame frame);
}

final class NormalizedCropRect {
  const NormalizedCropRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  bool get isValid =>
      left.isFinite &&
      top.isFinite &&
      width.isFinite &&
      height.isFinite &&
      width > 0 &&
      height > 0 &&
      left >= 0 &&
      top >= 0 &&
      left + width <= 1.0001 &&
      top + height <= 1.0001;
}

/// The target box as laid out over the covered live-camera preview.
///
/// Coordinates are in logical preview pixels. The source aspect ratio is the
/// oriented aspect ratio used by the preview before its BoxFit.cover scale.
final class LivePreviewTargetGeometry {
  const LivePreviewTargetGeometry({
    required this.viewportWidth,
    required this.viewportHeight,
    required this.targetLeft,
    required this.targetTop,
    required this.targetWidth,
    required this.targetHeight,
    required this.sourceAspectRatio,
  });

  final double viewportWidth;
  final double viewportHeight;
  final double targetLeft;
  final double targetTop;
  final double targetWidth;
  final double targetHeight;
  final double sourceAspectRatio;

  bool get isValid =>
      viewportWidth.isFinite &&
      viewportHeight.isFinite &&
      targetLeft.isFinite &&
      targetTop.isFinite &&
      targetWidth.isFinite &&
      targetHeight.isFinite &&
      sourceAspectRatio.isFinite &&
      viewportWidth > 0 &&
      viewportHeight > 0 &&
      targetWidth > 0 &&
      targetHeight > 0 &&
      sourceAspectRatio > 0;
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
    this.targetCrop,
  });

  final int width;
  final int height;
  final int rotationDegrees;
  final LiveCameraPixelFormat pixelFormat;
  final List<LiveCameraPlane> planes;
  final NormalizedCropRect? targetCrop;

  LiveCameraFrame copyWith({NormalizedCropRect? targetCrop}) => LiveCameraFrame(
    width: width,
    height: height,
    rotationDegrees: rotationDegrees,
    pixelFormat: pixelFormat,
    planes: planes,
    targetCrop: targetCrop ?? this.targetCrop,
  );
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
