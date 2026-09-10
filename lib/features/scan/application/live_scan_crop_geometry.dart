import 'dart:math' as math;

import 'package:kami/features/scan/domain/ripeness_classifier.dart';

/// Maps the visible target box through the preview's cover transform into the
/// orientation-corrected camera frame. The result is always a square crop, so
/// Live model inputs do not need artificial letterbox padding.
NormalizedCropRect resolveLiveTargetCrop({
  required LiveCameraFrame frame,
  required LivePreviewTargetGeometry geometry,
}) {
  if (!geometry.isValid || frame.width <= 0 || frame.height <= 0) {
    throw ArgumentError('Live target geometry or frame dimensions are invalid.');
  }

  final orientedWidth = frame.rotationDegrees == 90 ||
          frame.rotationDegrees == 270
      ? frame.height
      : frame.width;
  final orientedHeight = frame.rotationDegrees == 90 ||
          frame.rotationDegrees == 270
      ? frame.width
      : frame.height;
  final previewWidth = geometry.sourceAspectRatio * 1000;
  const previewHeight = 1000.0;
  final scale = math.max(
    geometry.viewportWidth / previewWidth,
    geometry.viewportHeight / previewHeight,
  );
  final scaledWidth = previewWidth * scale;
  final scaledHeight = previewHeight * scale;
  final offsetX = (geometry.viewportWidth - scaledWidth) / 2;
  final offsetY = (geometry.viewportHeight - scaledHeight) / 2;

  final visibleLeft =
      ((geometry.targetLeft - offsetX) / scaledWidth).clamp(0.0, 1.0);
  final visibleTop =
      ((geometry.targetTop - offsetY) / scaledHeight).clamp(0.0, 1.0);
  final visibleRight = ((geometry.targetLeft + geometry.targetWidth - offsetX) /
          scaledWidth)
      .clamp(0.0, 1.0);
  final visibleBottom =
      ((geometry.targetTop + geometry.targetHeight - offsetY) / scaledHeight)
          .clamp(0.0, 1.0);

  // The preview and image stream can use different resolutions/aspect ratios.
  // Treat the preview as a centered cover of the oriented stream when mapping
  // between those spaces, rather than assuming normalized coordinates are
  // interchangeable.
  final frameAspect = orientedWidth / orientedHeight;
  final visibleFrameWidth = frameAspect > geometry.sourceAspectRatio
      ? geometry.sourceAspectRatio / frameAspect
      : 1.0;
  final visibleFrameHeight = frameAspect < geometry.sourceAspectRatio
      ? frameAspect / geometry.sourceAspectRatio
      : 1.0;
  final frameOffsetX = (1 - visibleFrameWidth) / 2;
  final frameOffsetY = (1 - visibleFrameHeight) / 2;
  final left = frameOffsetX + visibleLeft * visibleFrameWidth;
  final top = frameOffsetY + visibleTop * visibleFrameHeight;
  final right = frameOffsetX + visibleRight * visibleFrameWidth;
  final bottom = frameOffsetY + visibleBottom * visibleFrameHeight;

  final leftPx = (left * orientedWidth).round();
  final topPx = (top * orientedHeight).round();
  final rightPx = (right * orientedWidth).round();
  final bottomPx = (bottom * orientedHeight).round();
  final centerX = (leftPx + rightPx) / 2;
  final centerY = (topPx + bottomPx) / 2;
  final requestedSide = math.max(
    rightPx - leftPx,
    bottomPx - topPx,
  );
  final side = requestedSide
      .clamp(1, math.min(orientedWidth, orientedHeight))
      .toInt();
  final boundedLeft = _boundedSquareStart(centerX, side, orientedWidth);
  final boundedTop = _boundedSquareStart(centerY, side, orientedHeight);

  return NormalizedCropRect(
    left: boundedLeft / orientedWidth,
    top: boundedTop / orientedHeight,
    width: side / orientedWidth,
    height: side / orientedHeight,
  );
}

int _boundedSquareStart(double center, int side, int extent) {
  final preferred = (center - side / 2).round();
  return preferred.clamp(0, extent - side).toInt();
}
