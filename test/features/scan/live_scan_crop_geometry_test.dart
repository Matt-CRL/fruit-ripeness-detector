import 'package:flutter_test/flutter_test.dart';
import 'package:kami/features/scan/application/live_scan_crop_geometry.dart';
import 'package:kami/features/scan/domain/ripeness_classifier.dart';

void main() {
  const geometry = LivePreviewTargetGeometry(
    viewportWidth: 400,
    viewportHeight: 800,
    targetLeft: 100,
    targetTop: 300,
    targetWidth: 200,
    targetHeight: 200,
    sourceAspectRatio: 0.5,
  );

  test('maps the visible target center to the oriented frame center', () {
    final crop = resolveLiveTargetCrop(
      frame: _frame(width: 800, height: 400, rotation: 0),
      geometry: geometry,
    );

    expect(crop.left + (crop.width / 2), closeTo(0.5, 0.01));
    expect(crop.top + (crop.height / 2), closeTo(0.5, 0.01));
    expect(crop.width * 800, closeTo(crop.height * 400, 1));
  });

  test('handles every supported frame rotation', () {
    for (final rotation in [0, 90, 180, 270]) {
      final rotated = rotation == 90 || rotation == 270;
      final crop = resolveLiveTargetCrop(
        frame: _frame(
          width: rotated ? 400 : 800,
          height: rotated ? 800 : 400,
          rotation: rotation,
        ),
        geometry: geometry,
      );

      expect(crop.isValid, isTrue, reason: 'rotation $rotation');
      expect(crop.left + crop.width, lessThanOrEqualTo(1));
      expect(crop.top + crop.height, lessThanOrEqualTo(1));
    }
  });

  test('keeps an edge-adjacent square crop inside the frame', () {
    const edgeGeometry = LivePreviewTargetGeometry(
      viewportWidth: 400,
      viewportHeight: 800,
      targetLeft: 260,
      targetTop: 270,
      targetWidth: 120,
      targetHeight: 120,
      sourceAspectRatio: 0.5,
    );

    final crop = resolveLiveTargetCrop(
      frame: _frame(width: 800, height: 400, rotation: 0),
      geometry: edgeGeometry,
    );

    expect(crop.isValid, isTrue);
    expect(crop.left + crop.width, lessThanOrEqualTo(1));
    expect(crop.top + crop.height, lessThanOrEqualTo(1));
  });
}

LiveCameraFrame _frame({
  required int width,
  required int height,
  required int rotation,
}) {
  return LiveCameraFrame(
    width: width,
    height: height,
    rotationDegrees: rotation,
    pixelFormat: LiveCameraPixelFormat.yuv420,
    planes: const <LiveCameraPlane>[],
  );
}
