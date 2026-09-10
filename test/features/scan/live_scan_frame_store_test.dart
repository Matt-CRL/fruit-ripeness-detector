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

  test('writes a clean widened target crop without black padding', () async {
    final root = await Directory.systemTemp.createTemp(
      'kami-live-model-input-test-',
    );
    addTearDown(() => root.delete(recursive: true));
    final store = AppPrivateLiveScanFrameStore(
      () async => root,
      const _FixedIdGenerator(),
    );
    final selected = await store.writeTemporaryTargetCrop(_targetFrame);
    final output = File(selected.path);
    final decoded = image.decodeJpg(await output.readAsBytes());

    expect(decoded, isNotNull);
    expect(decoded!.width, 6);
    expect(decoded.height, 6);
    expect(
      decoded
          .getBytes(order: image.ChannelOrder.rgb)
          .every((value) => value > 10),
      isTrue,
    );

    await store.removeTemporary(selected);
    expect(await output.exists(), isFalse);
  });
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

final _targetFrame = LiveCameraFrame(
  width: 10,
  height: 10,
  rotationDegrees: 0,
  pixelFormat: LiveCameraPixelFormat.yuv420,
  targetCrop: const NormalizedCropRect(
    left: 0.25,
    top: 0.25,
    width: 0.5,
    height: 0.5,
  ),
  planes: [
    LiveCameraPlane(
      bytes: Uint8List.fromList(List<int>.filled(100, 128)),
      bytesPerRow: 10,
      bytesPerPixel: 1,
    ),
    LiveCameraPlane(
      bytes: Uint8List.fromList(List<int>.filled(25, 128)),
      bytesPerRow: 5,
      bytesPerPixel: 1,
    ),
    LiveCameraPlane(
      bytes: Uint8List.fromList(List<int>.filled(25, 128)),
      bytesPerRow: 5,
      bytesPerPixel: 1,
    ),
  ],
);

final class _FixedIdGenerator implements EntityIdGenerator {
  const _FixedIdGenerator();

  @override
  String nextId() => '11111111-1111-4111-8111-111111111111';
}
