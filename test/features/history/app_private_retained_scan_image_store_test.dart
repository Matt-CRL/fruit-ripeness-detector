import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kami/features/history/data/app_private_retained_scan_image_store.dart';
import 'package:kami/features/history/domain/retained_scan_image_store.dart';

const _scanId = '11111111-1111-4111-8111-111111111111';

void main() {
  late Directory root;
  late File source;
  late FakeRetainedImageCompressor compressor;
  late AppPrivateRetainedScanImageStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('kami_retained_image_test_');
    source = File('${root.path}${Platform.pathSeparator}source.png');
    await source.writeAsBytes([1, 2, 3, 4], flush: true);
    compressor = FakeRetainedImageCompressor();
    store = AppPrivateRetainedScanImageStore(() async => root, compressor);
  });

  tearDown(() async {
    if (root.path.contains('kami_retained_image_test_') &&
        await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  test('retains one validated private JPEG with approved settings', () async {
    final retained = await store.retain(
      sourcePath: source.path,
      scanId: _scanId,
    );
    final resolved = File(await store.resolvePath(retained.relativePath));

    expect(retained.relativePath, 'history_images/$_scanId.jpg');
    expect(await resolved.exists(), isTrue);
    expect(await resolved.readAsBytes(), [8, 2]);
    expect(compressor.maximumLongEdge, 1280);
    expect(compressor.quality, 82);
    expect(
      await File(
        '${root.path}${Platform.pathSeparator}history_images'
        '${Platform.pathSeparator}.$_scanId.pending.jpg',
      ).exists(),
      isFalse,
    );
  });

  test('rejects paths outside the owned history directory', () async {
    await expectLater(store.resolvePath('../outside.jpg'), throwsArgumentError);
    await expectLater(store.remove('other/$_scanId.jpg'), throwsArgumentError);
  });

  test('compression failure removes only the pending output', () async {
    compressor.failAfterWrite = true;

    await expectLater(
      store.retain(sourcePath: source.path, scanId: _scanId),
      throwsA(isA<RetainedScanImageException>()),
    );

    final history = Directory(
      '${root.path}${Platform.pathSeparator}history_images',
    );
    expect(await history.exists(), isTrue);
    expect(await history.list().toList(), isEmpty);
    expect(await source.exists(), isTrue);
  });

  test('missing source fails before creating a history output', () async {
    final missing = '${root.path}${Platform.pathSeparator}missing.png';

    await expectLater(
      store.retain(sourcePath: missing, scanId: _scanId),
      throwsA(isA<RetainedScanImageException>()),
    );

    expect(compressor.maximumLongEdge, isNull);
    expect(
      await Directory(
        '${root.path}${Platform.pathSeparator}history_images',
      ).exists(),
      isFalse,
    );
  });
}

final class FakeRetainedImageCompressor implements RetainedImageCompressor {
  bool failAfterWrite = false;
  int? maximumLongEdge;
  int? quality;

  @override
  Future<void> compressJpeg({
    required String sourcePath,
    required String targetPath,
    required int maximumLongEdge,
    required int quality,
  }) async {
    this.maximumLongEdge = maximumLongEdge;
    this.quality = quality;
    await File(targetPath).writeAsBytes([8, 2], flush: true);
    if (failAfterWrite) {
      throw const RetainedScanImageException('Synthetic compressor failure.');
    }
  }
}
