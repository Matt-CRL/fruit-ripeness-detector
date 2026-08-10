import 'package:image/image.dart' as image;
import 'package:kami/features/scan/data/tflite/image_preprocessing_exception.dart';
import 'package:kami/features/scan/domain/ripeness_classifier.dart';

image.Image convertLiveCameraFrameToImage(LiveCameraFrame frame) {
  if (frame.width <= 0 || frame.height <= 0) {
    throw const ImagePreprocessingException(
      'The camera frame dimensions are invalid.',
    );
  }
  if (frame.pixelFormat != LiveCameraPixelFormat.yuv420 ||
      frame.planes.length != 3) {
    throw const ImagePreprocessingException(
      'The camera produced an unsupported image format.',
    );
  }
  if (!const {0, 90, 180, 270}.contains(frame.rotationDegrees)) {
    throw const ImagePreprocessingException(
      'The camera frame rotation is unsupported.',
    );
  }

  final yPlane = frame.planes[0];
  final uPlane = frame.planes[1];
  final vPlane = frame.planes[2];
  _validatePlane(yPlane, frame.width, frame.height, chroma: false);
  _validatePlane(uPlane, frame.width, frame.height, chroma: true);
  _validatePlane(vPlane, frame.width, frame.height, chroma: true);

  final converted = image.Image(width: frame.width, height: frame.height);
  for (var y = 0; y < frame.height; y++) {
    final yRow = y * yPlane.bytesPerRow;
    final uvRow = (y ~/ 2) * uPlane.bytesPerRow;
    final vvRow = (y ~/ 2) * vPlane.bytesPerRow;
    for (var x = 0; x < frame.width; x++) {
      final yIndex = yRow + (x * yPlane.bytesPerPixel);
      final uvIndex = uvRow + ((x ~/ 2) * uPlane.bytesPerPixel);
      final vvIndex = vvRow + ((x ~/ 2) * vPlane.bytesPerPixel);
      if (yIndex >= yPlane.bytes.length ||
          uvIndex >= uPlane.bytes.length ||
          vvIndex >= vPlane.bytes.length) {
        throw const ImagePreprocessingException(
          'The camera frame plane data is incomplete.',
        );
      }

      final luminance = yPlane.bytes[yIndex].toDouble();
      final u = uPlane.bytes[uvIndex].toDouble() - 128;
      final v = vPlane.bytes[vvIndex].toDouble() - 128;
      final red = (luminance + (1.402 * v)).round().clamp(0, 255);
      final green = (luminance - (0.344136 * u) - (0.714136 * v)).round().clamp(
        0,
        255,
      );
      final blue = (luminance + (1.772 * u)).round().clamp(0, 255);
      converted.setPixelRgb(x, y, red, green, blue);
    }
  }

  return frame.rotationDegrees == 0
      ? converted
      : image.copyRotate(converted, angle: frame.rotationDegrees);
}

void _validatePlane(
  LiveCameraPlane plane,
  int width,
  int height, {
  required bool chroma,
}) {
  if (plane.bytesPerRow <= 0 || plane.bytesPerPixel <= 0) {
    throw const ImagePreprocessingException(
      'The camera frame plane stride is invalid.',
    );
  }
  final rows = chroma ? (height + 1) ~/ 2 : height;
  final columns = chroma ? (width + 1) ~/ 2 : width;
  final minimumLength =
      ((rows - 1) * plane.bytesPerRow) +
      ((columns - 1) * plane.bytesPerPixel) +
      1;
  if (plane.bytes.length < minimumLength) {
    throw const ImagePreprocessingException(
      'The camera frame plane data is incomplete.',
    );
  }
}
