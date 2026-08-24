import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kami/features/scan/data/tflite/model_bundle_manifest.dart';
import 'package:kami/features/scan/data/tflite/tflite_image_preprocessor.dart';
import 'package:kami/features/scan/domain/ripeness_classifier.dart';

void main() {
  const contract = ModelInputContract(
    name: 'input',
    shape: [1, 2, 2, 3],
    dataType: 'float32',
    pixelScale: 255,
    mean: [0, 0, 0],
    standardDeviation: [1, 1, 1],
    squareTransform: 'center_crop',
  );

  test('converts padded YUV420 camera planes to normalized RGB', () {
    final frame = LiveCameraFrame(
      width: 2,
      height: 2,
      rotationDegrees: 0,
      pixelFormat: LiveCameraPixelFormat.yuv420,
      planes: [
        LiveCameraPlane(
          bytes: Uint8List.fromList([76, 76, 0, 76, 76]),
          bytesPerRow: 3,
          bytesPerPixel: 1,
        ),
        LiveCameraPlane(
          bytes: Uint8List.fromList([84]),
          bytesPerRow: 1,
          bytesPerPixel: 1,
        ),
        LiveCameraPlane(
          bytes: Uint8List.fromList([255]),
          bytesPerRow: 1,
          bytesPerPixel: 1,
        ),
      ],
    );

    final values = preprocessCameraFrame(frame, contract).tensorValues;

    expect(values, hasLength(12));
    for (var offset = 0; offset < values.length; offset += 3) {
      expect(values[offset], closeTo(254 / 255, 1e-6));
      expect(values[offset + 1], 0);
      expect(values[offset + 2], 0);
    }
  });

  test('supports interleaved chroma plane pixel strides', () {
    final frame = LiveCameraFrame(
      width: 2,
      height: 2,
      rotationDegrees: 90,
      pixelFormat: LiveCameraPixelFormat.yuv420,
      planes: [
        LiveCameraPlane(
          bytes: Uint8List.fromList([128, 128, 128, 128]),
          bytesPerRow: 2,
          bytesPerPixel: 1,
        ),
        LiveCameraPlane(
          bytes: Uint8List.fromList([128, 0]),
          bytesPerRow: 2,
          bytesPerPixel: 2,
        ),
        LiveCameraPlane(
          bytes: Uint8List.fromList([128, 0]),
          bytesPerRow: 2,
          bytesPerPixel: 2,
        ),
      ],
    );

    final values = preprocessCameraFrame(frame, contract).tensorValues;

    expect(values, hasLength(12));
    expect(values.every((value) => (value - (128 / 255)).abs() < 1e-6), isTrue);
  });

  test('uses the visible normalized target crop before resizing', () {
    final frame = LiveCameraFrame(
      width: 4,
      height: 2,
      rotationDegrees: 0,
      pixelFormat: LiveCameraPixelFormat.yuv420,
      targetCrop: const NormalizedCropRect(
        left: 0.5,
        top: 0,
        width: 0.5,
        height: 1,
      ),
      planes: [
        LiveCameraPlane(
          bytes: Uint8List.fromList([20, 20, 220, 220, 20, 20, 220, 220]),
          bytesPerRow: 4,
          bytesPerPixel: 1,
        ),
        LiveCameraPlane(
          bytes: Uint8List.fromList([128, 128]),
          bytesPerRow: 2,
          bytesPerPixel: 1,
        ),
        LiveCameraPlane(
          bytes: Uint8List.fromList([128, 128]),
          bytesPerRow: 2,
          bytesPerPixel: 1,
        ),
      ],
    );

    final values = preprocessCameraFrame(frame, contract).tensorValues;

    expect(values, hasLength(12));
    expect(values[0], closeTo(220 / 255, 1e-6));
    expect(values[3], closeTo(220 / 255, 1e-6));
  });

  test('target crop remains valid for the supported rotated frame path', () {
    const crop = NormalizedCropRect(
      left: 0.2,
      top: 0.1,
      width: 0.6,
      height: 0.8,
    );
    final frame = LiveCameraFrame(
      width: 2,
      height: 4,
      rotationDegrees: 90,
      pixelFormat: LiveCameraPixelFormat.yuv420,
      targetCrop: crop,
      planes: [
        LiveCameraPlane(
          bytes: Uint8List.fromList(List<int>.filled(8, 128)),
          bytesPerRow: 2,
          bytesPerPixel: 1,
        ),
        LiveCameraPlane(
          bytes: Uint8List.fromList([128, 128]),
          bytesPerRow: 1,
          bytesPerPixel: 1,
        ),
        LiveCameraPlane(
          bytes: Uint8List.fromList([128, 128]),
          bytesPerRow: 1,
          bytesPerPixel: 1,
        ),
      ],
    );

    expect(() => preprocessCameraFrame(frame, contract), returnsNormally);
  });

  test('rejects incomplete camera plane data', () {
    final frame = LiveCameraFrame(
      width: 2,
      height: 2,
      rotationDegrees: 0,
      pixelFormat: LiveCameraPixelFormat.yuv420,
      planes: [
        LiveCameraPlane(
          bytes: Uint8List.fromList([128]),
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

    expect(
      () => preprocessCameraFrame(frame, contract),
      throwsA(isA<ImagePreprocessingException>()),
    );
  });

  test('camera frame and input contract cross an isolate boundary', () async {
    final frame = LiveCameraFrame(
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

    final values = (await Isolate.run(
      () => preprocessCameraFrame(frame, contract),
    )).tensorValues;

    expect(values, hasLength(12));
  });
}
