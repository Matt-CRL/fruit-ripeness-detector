import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as image;
import 'package:kami/core/database/app_database_provider.dart';
import 'package:kami/core/persistence/entity_id_generator.dart';
import 'package:kami/features/scan/application/live_scan_frame_store.dart';
import 'package:kami/features/scan/data/camera/live_camera_frame_converter.dart';
import 'package:kami/features/scan/domain/ripeness_classifier.dart';
import 'package:kami/features/scan/domain/scan_models.dart';
import 'package:path_provider/path_provider.dart';

typedef TemporaryRootResolver = Future<Directory> Function();

final liveScanFrameStoreProvider = Provider<LiveScanFrameStore>((ref) {
  return AppPrivateLiveScanFrameStore(
    getTemporaryDirectory,
    ref.watch(entityIdGeneratorProvider),
  );
});

final class AppPrivateLiveScanFrameStore implements LiveScanFrameStore {
  AppPrivateLiveScanFrameStore(this._rootResolver, this._idGenerator);

  static const jpegQuality = 95;
  static const _directoryName = 'live_scan_frames';

  final TemporaryRootResolver _rootResolver;
  final EntityIdGenerator _idGenerator;
  final Set<String> _ownedPaths = {};

  @override
  Future<SelectedScanImage> writeTemporary(LiveCameraFrame frame) async {
    try {
      final bytes = await Isolate.run(
        () => encodeLiveCameraFrameJpeg(frame),
        debugName: 'KamiLiveFrameJpegEncoding',
      );
      return _writeBytes(bytes);
    } on LiveScanFrameStoreException {
      rethrow;
    } on Object catch (error) {
      throw LiveScanFrameStoreException(
        'Chami could not prepare the live result image for saving.',
        error,
      );
    }
  }

  @override
  Future<SelectedScanImage> writeTemporaryTargetCrop(
    LiveCameraFrame frame,
  ) async {
    try {
      final bytes = await Isolate.run(
        () => encodeLiveCameraTargetCropJpeg(frame),
        debugName: 'KamiLiveTargetCropJpegEncoding',
      );
      return _writeBytes(bytes);
    } on LiveScanFrameStoreException {
      rethrow;
    } on Object catch (error) {
      throw LiveScanFrameStoreException(
        'Chami could not prepare the live result image for saving.',
        error,
      );
    }
  }

  Future<SelectedScanImage> _writeBytes(Uint8List bytes) async {
    File? pending;
    try {
      if (bytes.isEmpty) {
        throw const LiveScanFrameStoreException(
          'The live result image could not be encoded.',
        );
      }

      final directory = Directory(
        '${(await _rootResolver()).path}${Platform.pathSeparator}$_directoryName',
      );
      await directory.create(recursive: true);
      final id = _idGenerator.nextId();
      final name = 'live-scan-$id.jpg';
      pending = File(
        '${directory.path}${Platform.pathSeparator}.$name.pending',
      );
      final output = File('${directory.path}${Platform.pathSeparator}$name');
      await pending.writeAsBytes(bytes, flush: true);
      await pending.rename(output.path);
      _ownedPaths.add(output.path);
      return SelectedScanImage(path: output.path, name: name);
    } on LiveScanFrameStoreException {
      rethrow;
    } on Object catch (error) {
      if (pending != null && await pending.exists()) {
        await pending.delete();
      }
      throw LiveScanFrameStoreException(
        'Chami could not prepare the live result image for saving.',
        error,
      );
    }
  }

  @override
  Future<void> removeTemporary(SelectedScanImage image) async {
    if (!_ownedPaths.remove(image.path)) {
      return;
    }
    final file = File(image.path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

Uint8List encodeLiveCameraFrameJpeg(LiveCameraFrame frame) {
  final converted = convertLiveCameraFrameToImage(frame);
  return image.encodeJpg(
    converted,
    quality: AppPrivateLiveScanFrameStore.jpegQuality,
  );
}

Uint8List encodeLiveCameraTargetCropJpeg(LiveCameraFrame frame) {
  final crop = frame.targetCrop;
  if (crop == null || !crop.isValid) {
    throw const LiveScanFrameStoreException(
      'The live target crop was unavailable. Please scan again.',
    );
  }
  final converted = convertLiveCameraFrameToImage(frame);
  final target = _cropToSquare(
    converted,
    crop,
    expansion: 1.10,
  );
  return image.encodeJpg(
    target,
    quality: AppPrivateLiveScanFrameStore.jpegQuality,
  );
}

image.Image _cropToSquare(
  image.Image source,
  NormalizedCropRect crop, {
  required double expansion,
}) {
  final left = (crop.left * source.width).round();
  final top = (crop.top * source.height).round();
  final right = ((crop.left + crop.width) * source.width).round();
  final bottom = ((crop.top + crop.height) * source.height).round();
  final centerX = (left + right) / 2;
  final centerY = (top + bottom) / 2;
  final baseSide = (right - left > bottom - top ? right - left : bottom - top)
      .clamp(1, source.width)
      .toInt()
      .clamp(1, source.height)
      .toInt();
  final requestedSide = (baseSide * expansion).round();
  final side = requestedSide
      .clamp(1, source.width)
      .toInt()
      .clamp(1, source.height)
      .toInt();
  final startX = _boundedCropStart(centerX, side, source.width);
  final startY = _boundedCropStart(centerY, side, source.height);
  return image.copyCrop(
    source,
    x: startX,
    y: startY,
    width: side,
    height: side,
  );
}

int _boundedCropStart(double center, int side, int extent) {
  return (center - side / 2).round().clamp(0, extent - side).toInt();
}
