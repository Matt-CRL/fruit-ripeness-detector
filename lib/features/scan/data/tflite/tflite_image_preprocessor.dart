import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:kami/features/scan/data/camera/live_camera_frame_converter.dart';
import 'package:kami/features/scan/data/tflite/image_preprocessing_exception.dart';
import 'package:kami/features/scan/data/tflite/model_bundle_manifest.dart';
import 'package:kami/features/scan/domain/ripeness_classifier.dart';

export 'image_preprocessing_exception.dart';

Future<Float32List> preprocessImageFile(
  String imagePath,
  ModelInputContract contract,
) async {
  final bytes = await File(imagePath).readAsBytes();
  return preprocessImageBytes(bytes, contract);
}

Float32List preprocessImageBytes(Uint8List bytes, ModelInputContract contract) {
  image.Image? decoded;
  try {
    decoded = image.decodeImage(bytes);
  } on Object {
    throw const ImagePreprocessingException(
      'The selected image could not be decoded.',
    );
  }
  if (decoded == null) {
    throw const ImagePreprocessingException(
      'The selected image could not be decoded.',
    );
  }

  return _preprocessRgbImage(image.bakeOrientation(decoded), contract);
}

Float32List preprocessCameraFrame(
  LiveCameraFrame frame,
  ModelInputContract contract,
) {
  final oriented = convertLiveCameraFrameToImage(frame);
  return _preprocessRgbImage(oriented, contract);
}

Float32List _preprocessRgbImage(
  image.Image oriented,
  ModelInputContract contract,
) {
  final squareEdge = oriented.width < oriented.height
      ? oriented.width
      : oriented.height;
  final cropped = image.copyCrop(
    oriented,
    x: (oriented.width - squareEdge) ~/ 2,
    y: (oriented.height - squareEdge) ~/ 2,
    width: squareEdge,
    height: squareEdge,
  );
  final resized = image.copyResize(
    cropped,
    width: contract.width,
    height: contract.height,
    interpolation: image.Interpolation.linear,
  );

  final values = Float32List(contract.width * contract.height * 3);
  var offset = 0;
  for (var y = 0; y < contract.height; y++) {
    for (var x = 0; x < contract.width; x++) {
      final pixel = resized.getPixel(x, y);
      values[offset++] = _normalize(pixel.r, 0, contract);
      values[offset++] = _normalize(pixel.g, 1, contract);
      values[offset++] = _normalize(pixel.b, 2, contract);
    }
  }
  return values;
}

double _normalize(num channel, int index, ModelInputContract contract) {
  final scaled = channel.toDouble() / contract.pixelScale;
  return (scaled - contract.mean[index]) / contract.standardDeviation[index];
}
