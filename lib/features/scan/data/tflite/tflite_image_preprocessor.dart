import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:kami/features/scan/data/camera/live_camera_frame_converter.dart';
import 'package:kami/features/scan/data/tflite/image_preprocessing_exception.dart';
import 'package:kami/features/scan/data/tflite/model_bundle_manifest.dart';
import 'package:kami/features/scan/domain/ripeness_classifier.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

export 'image_preprocessing_exception.dart';

final class PreprocessedAssessmentInput {
  const PreprocessedAssessmentInput({
    required this.tensorValues,
    this.isolatedImageBytes,
  });

  final Float32List tensorValues;
  final Uint8List? isolatedImageBytes;
}

Float32List prepareU2netInput(Uint8List bytes) {
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
  final oriented = image.bakeOrientation(decoded);
  final resized = image.copyResize(
    oriented,
    width: 320,
    height: 320,
    interpolation: image.Interpolation.linear,
  );

  final values = Float32List(1 * 3 * 320 * 320);
  const planeSize = 320 * 320;
  var rOff = 0;
  var gOff = planeSize;
  var bOff = planeSize * 2;

  const mean = [0.485, 0.456, 0.406];
  const std = [0.229, 0.224, 0.225];

  for (var y = 0; y < 320; y++) {
    for (var x = 0; x < 320; x++) {
      final p = resized.getPixel(x, y);
      values[rOff++] = (p.r / 255.0 - mean[0]) / std[0];
      values[gOff++] = (p.g / 255.0 - mean[1]) / std[1];
      values[bOff++] = (p.b / 255.0 - mean[2]) / std[2];
    }
  }
  return values;
}

Future<PreprocessedAssessmentInput> preprocessImageFile(
  String imagePath,
  ModelInputContract contract, {
  List<double>? u2netAlphaMask,
}) async {
  final bytes = await File(imagePath).readAsBytes();
  return preprocessImageBytes(
    bytes,
    contract,
    u2netAlphaMask: u2netAlphaMask,
  );
}

PreprocessedAssessmentInput preprocessImageBytes(
  Uint8List bytes,
  ModelInputContract contract, {
  List<double>? u2netAlphaMask,
}) {
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

  final oriented = image.bakeOrientation(decoded);
  return _preprocessRgbImageWithPipeline(
    oriented,
    contract,
    u2netAlphaMask: u2netAlphaMask,
  );
}

Float32List preprocessCameraFrame(
  LiveCameraFrame frame,
  ModelInputContract contract,
) {
  final oriented = convertLiveCameraFrameToImage(frame);
  final input = _preprocessRgbImageWithPipeline(
    oriented,
    contract,
    crop: frame.targetCrop,
  );
  return input.tensorValues;
}

PreprocessedAssessmentInput _preprocessRgbImageWithPipeline(
  image.Image oriented,
  ModelInputContract contract, {
  NormalizedCropRect? crop,
  List<double>? u2netAlphaMask,
}) {
  image.Image isolatedSquare;

  if (u2netAlphaMask != null && u2netAlphaMask.isNotEmpty) {
    isolatedSquare = _isolateUsingAlphaMask(oriented, u2netAlphaMask);
  } else if (crop != null) {
    final cropped = _cropNormalized(oriented, crop);
    isolatedSquare = _letterboxSquare(cropped);
  } else if (contract.squareTransform == 'center_crop') {
    isolatedSquare = _centerSquare(oriented);
  } else {
    isolatedSquare = _letterboxSquare(oriented);
  }

  Uint8List? isolatedJpg;
  try {
    isolatedJpg = Uint8List.fromList(image.encodeJpg(isolatedSquare, quality: 90));
  } on Object {
    // Best-effort image encoding
  }

  final resized = image.copyResize(
    isolatedSquare,
    width: contract.width,
    height: contract.height,
    interpolation: image.Interpolation.linear,
  );

  final Float32List tensorValues;
  if (contract.isNchw) {
    tensorValues = _normalizeNchw(resized, contract);
  } else {
    tensorValues = _normalizeNhwc(resized, contract);
  }

  return PreprocessedAssessmentInput(
    tensorValues: tensorValues,
    isolatedImageBytes: isolatedJpg,
  );
}

image.Image _isolateUsingAlphaMask(
  image.Image source,
  List<double> rawMask320,
) {
  if (rawMask320.length != 320 * 320 ||
      rawMask320.any((value) => !value.isFinite)) {
    return _letterboxSquare(source);
  }
  final w = source.width;
  final h = source.height;

  var minV = rawMask320.reduce(math.min);
  var maxV = rawMask320.reduce(math.max);
  var range = maxV - minV + 1e-8;

  final mask320Img = image.Image(width: 320, height: 320);
  for (var y = 0; y < 320; y++) {
    for (var x = 0; x < 320; x++) {
      final v = (rawMask320[y * 320 + x] - minV) / range;
      final byteVal = (v * 255).clamp(0, 255).toInt();
      mask320Img.setPixelRgb(x, y, byteVal, byteVal, byteVal);
    }
  }

  final maskOrig = image.copyResize(
    mask320Img,
    width: w,
    height: h,
    interpolation: image.Interpolation.linear,
  );

  var minX = w;
  var minY = h;
  var maxX = 0;
  var maxY = 0;
  var foundForeground = false;

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final alpha = maskOrig.getPixel(x, y).r;
      if (alpha > 50) {
        foundForeground = true;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  if (!foundForeground || minX >= maxX || minY >= maxY) {
    return _letterboxSquare(source);
  }

  final bboxW = (maxX - minX + 1).clamp(1, w);
  final bboxH = (maxY - minY + 1).clamp(1, h);
  final maxDim = math.max(bboxW, bboxH);

  final square = image.Image(width: maxDim, height: maxDim);
  image.fill(square, color: image.ColorRgb8(0, 0, 0));

  final offX = (maxDim - bboxW) ~/ 2;
  final offY = (maxDim - bboxH) ~/ 2;

  for (var y = 0; y < bboxH; y++) {
    final srcY = minY + y;
    if (srcY >= h) continue;
    for (var x = 0; x < bboxW; x++) {
      final srcX = minX + x;
      if (srcX >= w) continue;
      final alphaVal = maskOrig.getPixel(srcX, srcY).r / 255.0;
      final p = source.getPixel(srcX, srcY);
      final r = (p.r * alphaVal).round().clamp(0, 255);
      final g = (p.g * alphaVal).round().clamp(0, 255);
      final b = (p.b * alphaVal).round().clamp(0, 255);
      square.setPixelRgb(offX + x, offY + y, r, g, b);
    }
  }

  return square;
}

image.Image _letterboxSquare(image.Image source) {
  final w = source.width;
  final h = source.height;
  final maxDim = math.max(w, h);

  final square = image.Image(width: maxDim, height: maxDim);
  image.fill(square, color: image.ColorRgb8(0, 0, 0));

  final offX = (maxDim - w) ~/ 2;
  final offY = (maxDim - h) ~/ 2;

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = source.getPixel(x, y);
      square.setPixelRgb(offX + x, offY + y, p.r.toInt(), p.g.toInt(), p.b.toInt());
    }
  }
  return square;
}

Uint8List? generateGradCamOverlay(
  Uint8List baseImageBytes,
  ActivationHeatmap heatmap,
) {
  image.Image? baseImage;
  try {
    baseImage = image.decodeImage(baseImageBytes);
  } on Object {
    return null;
  }
  if (baseImage == null) return null;

  final values = heatmap.values;
  if (values.isEmpty || heatmap.width <= 0 || heatmap.height <= 0) {
    return null;
  }

  final minVal = values.reduce(math.min);
  final maxVal = values.reduce(math.max);
  final range = maxVal - minVal;

  final blended = image.Image(width: baseImage.width, height: baseImage.height);

  double sampleHeatmap(double u, double v) {
    final hx = (u * (heatmap.width - 1)).clamp(0.0, heatmap.width - 1.0);
    final hy = (v * (heatmap.height - 1)).clamp(0.0, heatmap.height - 1.0);
    final x0 = hx.floor();
    final y0 = hy.floor();
    final x1 = math.min(x0 + 1, heatmap.width - 1);
    final y1 = math.min(y0 + 1, heatmap.height - 1);
    final tx = hx - x0;
    final ty = hy - y0;

    final v00 = heatmap.valueAt(x0, y0);
    final v10 = heatmap.valueAt(x1, y0);
    final v01 = heatmap.valueAt(x0, y1);
    final v11 = heatmap.valueAt(x1, y1);

    final top = v00 * (1 - tx) + v10 * tx;
    final bottom = v01 * (1 - tx) + v11 * tx;
    return top * (1 - ty) + bottom * ty;
  }

  for (var y = 0; y < baseImage.height; y++) {
    final v = baseImage.height == 1 ? 0.0 : y / (baseImage.height - 1);
    for (var x = 0; x < baseImage.width; x++) {
      final u = baseImage.width == 1 ? 0.0 : x / (baseImage.width - 1);
      final rawVal = sampleHeatmap(u, v);
      final heat = range <= 0 ? 0.5 : ((rawVal - minVal) / range).clamp(0.0, 1.0);

      final jetR = (1.5 - (heat * 4.0 - 1.5).abs()).clamp(0.0, 1.0) * 255.0;
      final jetG = (1.5 - (heat * 4.0 - 2.5).abs()).clamp(0.0, 1.0) * 255.0;
      final jetB = (1.5 - (heat * 4.0 - 0.5).abs()).clamp(0.0, 1.0) * 255.0;

      final p = baseImage.getPixel(x, y);
      final r = (0.6 * p.r + 0.4 * jetR).round().clamp(0, 255);
      final g = (0.6 * p.g + 0.4 * jetG).round().clamp(0, 255);
      final b = (0.6 * p.b + 0.4 * jetB).round().clamp(0, 255);
      blended.setPixelRgb(x, y, r, g, b);
    }
  }

  try {
    return Uint8List.fromList(image.encodeJpg(blended, quality: 90));
  } on Object {
    return null;
  }
}

Float32List _normalizeNchw(image.Image resized, ModelInputContract contract) {
  final values = Float32List(1 * 3 * contract.width * contract.height);
  final planeSize = contract.width * contract.height;
  var rOff = 0;
  var gOff = planeSize;
  var bOff = planeSize * 2;

  for (var y = 0; y < contract.height; y++) {
    for (var x = 0; x < contract.width; x++) {
      final pixel = resized.getPixel(x, y);
      values[rOff++] = _normalize(pixel.r, 0, contract);
      values[gOff++] = _normalize(pixel.g, 1, contract);
      values[bOff++] = _normalize(pixel.b, 2, contract);
    }
  }
  return values;
}

Float32List _normalizeNhwc(image.Image resized, ModelInputContract contract) {
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

image.Image _centerSquare(image.Image oriented) {
  final squareEdge = oriented.width < oriented.height
      ? oriented.width
      : oriented.height;
  return image.copyCrop(
    oriented,
    x: (oriented.width - squareEdge) ~/ 2,
    y: (oriented.height - squareEdge) ~/ 2,
    width: squareEdge,
    height: squareEdge,
  );
}

image.Image _cropNormalized(image.Image oriented, NormalizedCropRect crop) {
  if (!crop.isValid) {
    throw const ImagePreprocessingException(
      'The live target crop is outside the camera frame.',
    );
  }
  final left = (crop.left * oriented.width).round().clamp(
    0,
    oriented.width - 1,
  );
  final top = (crop.top * oriented.height).round().clamp(
    0,
    oriented.height - 1,
  );
  final right = ((crop.left + crop.width) * oriented.width).round().clamp(
    left + 1,
    oriented.width,
  );
  final bottom = ((crop.top + crop.height) * oriented.height).round().clamp(
    top + 1,
    oriented.height,
  );
  return image.copyCrop(
    oriented,
    x: left,
    y: top,
    width: right - left,
    height: bottom - top,
  );
}

double _normalize(num channel, int index, ModelInputContract contract) {
  final scaled = channel.toDouble() / contract.pixelScale;
  return (scaled - contract.mean[index]) / contract.standardDeviation[index];
}
