import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:kami/features/scan/application/live_camera.dart';
import 'package:kami/features/scan/domain/ripeness_classifier.dart';

final class FlutterLiveCameraGateway implements LiveCameraGateway {
  const FlutterLiveCameraGateway();

  @override
  Future<LiveCameraSession> openRearCamera() async {
    late final List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } on CameraException catch (error) {
      throw _mapCameraException(error);
    } on Object catch (error) {
      throw LiveCameraFailure(
        LiveCameraFailureKind.initialization,
        'Kami could not check the cameras on this device.',
        error,
      );
    }

    CameraDescription? rearCamera;
    for (final camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.back) {
        rearCamera = camera;
        break;
      }
    }
    if (rearCamera == null) {
      throw const LiveCameraFailure(
        LiveCameraFailureKind.noRearCamera,
        'Kami could not find a rear camera on this device.',
      );
    }

    final controller = CameraController(
      rearCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    try {
      await controller.initialize();
      if (!controller.supportsImageStreaming()) {
        await controller.dispose();
        throw const LiveCameraFailure(
          LiveCameraFailureKind.unsupportedStreaming,
          'This camera does not provide the image stream required by Live Scan.',
        );
      }
      return _FlutterLiveCameraSession(
        description: rearCamera,
        controller: controller,
      );
    } on LiveCameraFailure {
      rethrow;
    } on CameraException catch (error) {
      await controller.dispose();
      throw _mapCameraException(error);
    } on Object catch (error) {
      await controller.dispose();
      throw LiveCameraFailure(
        LiveCameraFailureKind.initialization,
        'Kami could not start the rear camera.',
        error,
      );
    }
  }
}

final class _FlutterLiveCameraSession implements LiveCameraSession {
  _FlutterLiveCameraSession({
    required this._description,
    required this._controller,
  });

  final CameraDescription _description;
  final CameraController _controller;
  bool _disposed = false;

  @override
  double get previewAspectRatio => _controller.value.aspectRatio;

  @override
  Widget buildPreview() => CameraPreview(_controller);

  @override
  Future<void> startImageStream({
    required LiveFrameAdmission shouldCopyFrame,
    required LiveFrameCallback onFrame,
  }) async {
    if (_disposed) {
      throw const LiveCameraFailure(
        LiveCameraFailureKind.streaming,
        'The camera session is no longer available.',
      );
    }
    try {
      if (_controller.value.isStreamingImages) {
        return;
      }
      await _controller.startImageStream((cameraImage) {
        if (_disposed || !shouldCopyFrame()) {
          return;
        }
        final planes = cameraImage.planes
            .map(
              (plane) => LiveCameraPlane(
                bytes: Uint8List.fromList(plane.bytes),
                bytesPerRow: plane.bytesPerRow,
                bytesPerPixel: plane.bytesPerPixel ?? 1,
              ),
            )
            .toList(growable: false);
        onFrame(
          LiveCameraFrame(
            width: cameraImage.width,
            height: cameraImage.height,
            rotationDegrees: _rotationDegrees(
              _description.sensorOrientation,
              _controller.value.deviceOrientation,
            ),
            pixelFormat: LiveCameraPixelFormat.yuv420,
            planes: List.unmodifiable(planes),
          ),
        );
      });
    } on CameraException catch (error) {
      throw _mapCameraException(error, streaming: true);
    } on LiveCameraFailure {
      rethrow;
    } on Object catch (error) {
      throw LiveCameraFailure(
        LiveCameraFailureKind.streaming,
        'Kami could not read frames from the rear camera.',
        error,
      );
    }
  }

  @override
  Future<void> stopImageStream() async {
    if (_disposed || !_controller.value.isStreamingImages) {
      return;
    }
    try {
      await _controller.stopImageStream();
    } on CameraException catch (error) {
      throw _mapCameraException(error, streaming: true);
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    if (_controller.value.isStreamingImages) {
      try {
        await _controller.stopImageStream();
      } on Object {
        // Continue releasing the camera after a best-effort stream stop.
      }
    }
    await _controller.dispose();
  }
}

int _rotationDegrees(int sensorOrientation, DeviceOrientation orientation) {
  final deviceDegrees = switch (orientation) {
    DeviceOrientation.portraitUp => 0,
    DeviceOrientation.landscapeLeft => 90,
    DeviceOrientation.portraitDown => 180,
    DeviceOrientation.landscapeRight => 270,
  };
  return (sensorOrientation - deviceDegrees + 360) % 360;
}

LiveCameraFailure _mapCameraException(
  CameraException error, {
  bool streaming = false,
}) {
  return switch (error.code) {
    'CameraAccessDenied' => LiveCameraFailure(
      LiveCameraFailureKind.permissionDenied,
      'Camera access was denied. Allow camera access to use Live Scan.',
      error,
    ),
    'CameraAccessDeniedWithoutPrompt' => LiveCameraFailure(
      LiveCameraFailureKind.permissionPermanentlyDenied,
      'Camera access is blocked. Enable it for Kami in Android Settings, then try again.',
      error,
    ),
    'CameraAccessRestricted' => LiveCameraFailure(
      LiveCameraFailureKind.permissionPermanentlyDenied,
      'Camera access is restricted on this device.',
      error,
    ),
    _ => LiveCameraFailure(
      streaming
          ? LiveCameraFailureKind.streaming
          : LiveCameraFailureKind.initialization,
      streaming
          ? 'Kami could not continue reading camera frames.'
          : 'Kami could not start the rear camera.',
      error,
    ),
  };
}
