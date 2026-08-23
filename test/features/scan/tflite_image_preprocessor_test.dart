import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:kami/features/scan/data/tflite/model_bundle_manifest.dart';
import 'package:kami/features/scan/data/tflite/tflite_image_preprocessor.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

void main() {
  test('center crop removes the outer edges before resizing (NHWC)', () {
    final source = image.Image(width: 4, height: 2);
    for (var y = 0; y < source.height; y++) {
      source.setPixelRgb(0, y, 255, 0, 0);
      source.setPixelRgb(1, y, 0, 255, 0);
      source.setPixelRgb(2, y, 0, 255, 0);
      source.setPixelRgb(3, y, 255, 0, 0);
    }

    final result = preprocessImageBytes(
      Uint8List.fromList(image.encodePng(source)),
      _inputContract(width: 2, height: 2, isNchw: false),
    );

    final values = result.tensorValues;
    expect(values, hasLength(12));
    for (var offset = 0; offset < values.length; offset += 3) {
      expect(values[offset], closeTo(0, 1e-6));
      expect(values[offset + 1], closeTo(1, 1e-6));
      expect(values[offset + 2], closeTo(0, 1e-6));
    }
  });

  test('normalizes RGB channels in planar format for NCHW', () {
    final source = image.Image(width: 1, height: 1)
      ..setPixelRgb(0, 0, 255, 128, 0);
    const contract = ModelInputContract(
      name: 'serving_default_args_0',
      shape: [1, 3, 1, 1],
      dataType: 'float32',
      pixelScale: 255,
      mean: [0.5, 0.25, 0],
      standardDeviation: [0.5, 0.25, 1],
    );

    final result = preprocessImageBytes(
      Uint8List.fromList(image.encodePng(source)),
      contract,
    );

    final values = result.tensorValues;
    expect(values, hasLength(3));
    expect(values[0], closeTo(1, 1e-6)); // Red plane
    expect(values[1], closeTo((128 / 255 - 0.25) / 0.25, 1e-6)); // Green plane
    expect(values[2], closeTo(0, 1e-6)); // Blue plane
  });

  test('rejects bytes that are not a supported image', () {
    expect(
      () => preprocessImageBytes(
        Uint8List.fromList([1, 2, 3]),
        _inputContract(width: 2, height: 2, isNchw: true),
      ),
      throwsA(isA<ImagePreprocessingException>()),
    );
  });

  test(
    'input contract and preprocessing result cross an isolate boundary',
    () async {
      final temporaryDirectory = Directory.systemTemp.createTempSync(
        'kami-preprocessing-test-',
      );
      addTearDown(() => temporaryDirectory.deleteSync(recursive: true));
      final source = image.Image(width: 1, height: 1)
        ..setPixelRgb(0, 0, 255, 0, 0);
      final file = File('${temporaryDirectory.path}/fruit.png')
        ..writeAsBytesSync(image.encodePng(source));
      final contract = _inputContract(width: 1, height: 1, isNchw: true);

      final result = await Isolate.run(
        () => preprocessImageFile(file.path, contract),
      );

      final values = result.tensorValues;
      expect(values, hasLength(3));
      expect(values[0], closeTo(1, 1e-6));
      expect(values[1], closeTo(0, 1e-6));
      expect(values[2], closeTo(0, 1e-6));
    },
  );

  test('generateGradCamOverlay blends 7x7 activation heatmap onto base image', () {
    final source = image.Image(width: 14, height: 14);
    image.fill(source, color: image.ColorRgb8(100, 100, 100));
    final sourceBytes = Uint8List.fromList(image.encodeJpg(source));

    final heatmap = ActivationHeatmap(
      width: 7,
      height: 7,
      values: List.generate(49, (i) => i.toDouble()),
    );

    final overlayBytes = generateGradCamOverlay(sourceBytes, heatmap);
    expect(overlayBytes, isNotNull);
    expect(overlayBytes!.isNotEmpty, isTrue);

    final decoded = image.decodeImage(overlayBytes);
    expect(decoded, isNotNull);
    expect(decoded!.width, 14);
    expect(decoded.height, 14);
  });

  test('malformed U2-Net masks fall back without crashing preprocessing', () {
    final source = image.Image(width: 4, height: 2);
    image.fill(source, color: image.ColorRgb8(80, 120, 160));

    final result = preprocessImageBytes(
      Uint8List.fromList(image.encodePng(source)),
      _inputContract(width: 2, height: 2, isNchw: false),
      u2netAlphaMask: const [double.nan],
    );

    expect(result.tensorValues, hasLength(12));
    expect(result.isolatedImageBytes, isNotNull);
  });
}

ModelInputContract _inputContract({
  required int width,
  required int height,
  required bool isNchw,
}) {
  return ModelInputContract(
    name: 'serving_default_args_0',
    shape: isNchw ? [1, 3, height, width] : [1, height, width, 3],
    dataType: 'float32',
    pixelScale: 255,
    mean: const [0, 0, 0],
    standardDeviation: const [1, 1, 1],
    squareTransform: 'center_crop',
  );
}
