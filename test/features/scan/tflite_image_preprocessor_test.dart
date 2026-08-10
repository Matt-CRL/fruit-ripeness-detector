import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:kami/features/scan/data/tflite/model_bundle_manifest.dart';
import 'package:kami/features/scan/data/tflite/tflite_image_preprocessor.dart';

void main() {
  test('center crop removes the outer edges before resizing', () {
    final source = image.Image(width: 4, height: 2);
    for (var y = 0; y < source.height; y++) {
      source.setPixelRgb(0, y, 255, 0, 0);
      source.setPixelRgb(1, y, 0, 255, 0);
      source.setPixelRgb(2, y, 0, 255, 0);
      source.setPixelRgb(3, y, 255, 0, 0);
    }

    final values = preprocessImageBytes(
      Uint8List.fromList(image.encodePng(source)),
      _inputContract(width: 2, height: 2),
    );

    expect(values, hasLength(12));
    for (var offset = 0; offset < values.length; offset += 3) {
      expect(values[offset], closeTo(0, 1e-6));
      expect(values[offset + 1], closeTo(1, 1e-6));
      expect(values[offset + 2], closeTo(0, 1e-6));
    }
  });

  test('normalizes RGB channels using manifest values', () {
    final source = image.Image(width: 1, height: 1)
      ..setPixelRgb(0, 0, 255, 128, 0);
    const contract = ModelInputContract(
      name: 'input_tensor',
      shape: [1, 1, 1, 3],
      dataType: 'float32',
      pixelScale: 255,
      mean: [0.5, 0.25, 0],
      standardDeviation: [0.5, 0.25, 1],
    );

    final values = preprocessImageBytes(
      Uint8List.fromList(image.encodePng(source)),
      contract,
    );

    expect(values[0], closeTo(1, 1e-6));
    expect(values[1], closeTo((128 / 255 - 0.25) / 0.25, 1e-6));
    expect(values[2], closeTo(0, 1e-6));
  });

  test('rejects bytes that are not a supported image', () {
    expect(
      () => preprocessImageBytes(
        Uint8List.fromList([1, 2, 3]),
        _inputContract(width: 2, height: 2),
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
      final contract = _inputContract(width: 1, height: 1);

      final values = await Isolate.run(
        () => preprocessImageFile(file.path, contract),
      );

      expect(values, hasLength(3));
      expect(values[0], closeTo(1, 1e-6));
      expect(values[1], closeTo(0, 1e-6));
      expect(values[2], closeTo(0, 1e-6));
    },
  );
}

ModelInputContract _inputContract({required int width, required int height}) {
  return ModelInputContract(
    name: 'input_tensor',
    shape: [1, height, width, 3],
    dataType: 'float32',
    pixelScale: 255,
    mean: const [0, 0, 0],
    standardDeviation: const [1, 1, 1],
  );
}
