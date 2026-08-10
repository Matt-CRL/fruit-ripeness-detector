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
    File? pending;
    try {
      final bytes = await Isolate.run(
        () => encodeLiveCameraFrameJpeg(frame),
        debugName: 'KamiLiveFrameJpegEncoding',
      );
      if (bytes.isEmpty) {
        throw const LiveScanFrameStoreException(
          'The live camera frame could not be encoded.',
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
        'Kami could not prepare the live result image for saving.',
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
