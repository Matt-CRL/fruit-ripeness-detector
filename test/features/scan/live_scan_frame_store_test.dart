import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:kami/core/persistence/entity_id_generator.dart';
import 'package:kami/features/scan/data/camera/app_private_live_scan_frame_store.dart';
import 'package:kami/features/scan/domain/ripeness_classifier.dart';

void main() {
  test(
    'writes an orientation-corrected JPEG and removes only its owned file',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'kami-live-frame-test-',
      );
      addTearDown(() => root.delete(recursive: true));
      final store = AppPrivateLiveScanFrameStore(
        () async => root,
        const _FixedIdGenerator(),
      );

      final selected = await store.writeTemporary(_portraitFrame);
      final output = File(selected.path);
      expect(await output.exists(), isTrue);
      expect(
        selected.name,
        'live-scan-11111111-1111-4111-8111-111111111111.jpg',
      );

      final decoded = image.decodeJpg(await output.readAsBytes());
      expect(decoded, isNotNull);
      expect(decoded!.width, 4);
      expect(decoded.height, 2);

      await store.removeTemporary(selected);
      expect(await output.exists(), isFalse);
    },
  );
}

final _portraitFrame = LiveCameraFrame(
  width: 2,
  height: 4,
  rotationDegrees: 90,
  pixelFormat: LiveCameraPixelFormat.yuv420,
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

final class _FixedIdGenerator implements EntityIdGenerator {
  const _FixedIdGenerator();

  @override
  String nextId() => '11111111-1111-4111-8111-111111111111';
}
