import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/core/persistence/persistence_validation.dart';
import 'package:kami/features/history/domain/retained_scan_image_store.dart';
import 'package:path_provider/path_provider.dart';

typedef AppPrivateRootResolver = Future<Directory> Function();

final retainedScanImageStoreProvider = Provider<RetainedScanImageStore>((ref) {
  return AppPrivateRetainedScanImageStore(
    getApplicationDocumentsDirectory,
    const FlutterRetainedImageCompressor(),
  );
});

abstract interface class RetainedImageCompressor {
  Future<void> compressJpeg({
    required String sourcePath,
    required String targetPath,
    required int maximumLongEdge,
    required int quality,
  });
}

final class AppPrivateRetainedScanImageStore implements RetainedScanImageStore {
  const AppPrivateRetainedScanImageStore(this._rootResolver, this._compressor);

  static const maximumLongEdge = 1280;
  static const jpegQuality = 82;
  static const _historyDirectoryName = 'history_images';

  final AppPrivateRootResolver _rootResolver;
  final RetainedImageCompressor _compressor;

  @override
  Future<RetainedScanImage> retain({
    required String sourcePath,
    required String scanId,
  }) async {
    PersistenceValidation.entityId(scanId, 'scanId');
    if (sourcePath.trim().isEmpty) {
      throw const RetainedScanImageException('The source image path is empty.');
    }

    final source = File(sourcePath);
    if (!await source.exists() || await source.length() == 0) {
      throw const RetainedScanImageException(
        'The selected source image is unavailable.',
      );
    }

    final directory = await _historyDirectory();
    await directory.create(recursive: true);
    final pending = File(
      '${directory.path}${Platform.pathSeparator}.$scanId.pending.jpg',
    );
    final output = File(
      '${directory.path}${Platform.pathSeparator}$scanId.jpg',
    );
    final relativePath = '$_historyDirectoryName/$scanId.jpg';

    if (await output.exists()) {
      throw const RetainedScanImageException(
        'A retained image already exists for this scan.',
      );
    }
    if (await pending.exists()) {
      await pending.delete();
    }

    try {
      await _compressor.compressJpeg(
        sourcePath: source.path,
        targetPath: pending.path,
        maximumLongEdge: maximumLongEdge,
        quality: jpegQuality,
      );
      if (!await pending.exists() || await pending.length() == 0) {
        throw const RetainedScanImageException(
          'Image compression did not create a valid history image.',
        );
      }
      await pending.rename(output.path);
      return RetainedScanImage(relativePath: relativePath);
    } on Object {
      if (await pending.exists()) {
        await pending.delete();
      }
      rethrow;
    }
  }

  @override
  Future<RetainedScanImage> copyToScan({
    required String sourceRelativePath,
    required String scanId,
  }) async {
    PersistenceValidation.entityId(scanId, 'scanId');
    final source = File(await resolvePath(sourceRelativePath));
    if (!await source.exists() || await source.length() == 0) {
      throw const RetainedScanImageException(
        'The retained source image is unavailable.',
      );
    }

    final directory = await _historyDirectory();
    await directory.create(recursive: true);
    final output = File(
      '${directory.path}${Platform.pathSeparator}$scanId.jpg',
    );
    if (await output.exists()) {
      throw const RetainedScanImageException(
        'A retained image already exists for this scan.',
      );
    }

    try {
      await source.copy(output.path);
      return RetainedScanImage(relativePath: '$_historyDirectoryName/$scanId.jpg');
    } on Object {
      if (await output.exists()) {
        await output.delete();
      }
      rethrow;
    }
  }

  @override
  Future<String> resolvePath(String relativePath) async {
    final fileName = _validatedFileName(relativePath);
    final directory = await _historyDirectory();
    return '${directory.path}${Platform.pathSeparator}$fileName';
  }

  @override
  Future<RetainedScanImage> storeDownloadedJpeg({
    required Uint8List bytes,
    required String scanId,
  }) async {
    PersistenceValidation.entityId(scanId, 'scanId');
    if (bytes.length < 4 ||
        bytes.length > 5 * 1024 * 1024 ||
        bytes[0] != 0xff ||
        bytes[1] != 0xd8 ||
        bytes[bytes.length - 2] != 0xff ||
        bytes[bytes.length - 1] != 0xd9) {
      throw const RetainedScanImageException(
        'The downloaded history image is not a valid retained JPEG.',
      );
    }
    final directory = await _historyDirectory();
    await directory.create(recursive: true);
    final pending = File(
      '${directory.path}${Platform.pathSeparator}.$scanId.download.jpg',
    );
    final output = File(
      '${directory.path}${Platform.pathSeparator}$scanId.jpg',
    );
    if (await pending.exists()) await pending.delete();
    try {
      await pending.writeAsBytes(bytes, flush: true);
      if (await output.exists()) await output.delete();
      await pending.rename(output.path);
      return RetainedScanImage(
        relativePath: '$_historyDirectoryName/$scanId.jpg',
      );
    } on Object {
      if (await pending.exists()) await pending.delete();
      rethrow;
    }
  }

  @override
  Future<void> remove(String relativePath) async {
    final resolved = File(await resolvePath(relativePath));
    if (await resolved.exists()) {
      await resolved.delete();
    }
  }

  Future<Directory> _historyDirectory() async {
    final root = await _rootResolver();
    return Directory(
      '${root.path}${Platform.pathSeparator}$_historyDirectoryName',
    );
  }

  static String _validatedFileName(String relativePath) {
    PersistenceValidation.relativePath(relativePath, 'relativePath');
    final normalized = relativePath.replaceAll('\\', '/');
    final segments = normalized.split('/');
    if (segments.length != 2 || segments.first != _historyDirectoryName) {
      throw ArgumentError.value(
        relativePath,
        'relativePath',
        'must identify an app-owned history image',
      );
    }

    final fileName = segments.last;
    if (!fileName.endsWith('.jpg')) {
      throw ArgumentError.value(
        relativePath,
        'relativePath',
        'must identify a JPEG history image',
      );
    }
    PersistenceValidation.entityId(
      fileName.substring(0, fileName.length - 4),
      'relativePath.scanId',
    );
    return fileName;
  }
}

final class FlutterRetainedImageCompressor implements RetainedImageCompressor {
  const FlutterRetainedImageCompressor();

  @override
  Future<void> compressJpeg({
    required String sourcePath,
    required String targetPath,
    required int maximumLongEdge,
    required int quality,
  }) async {
    final sourceDimensions = await _readDimensions(File(sourcePath));
    final targetDimensions = sourceDimensions.fitWithin(maximumLongEdge);
    final output = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      targetPath,
      minWidth: targetDimensions.width,
      minHeight: targetDimensions.height,
      quality: quality,
      rotate: 0,
      autoCorrectionAngle: true,
      format: CompressFormat.jpeg,
      keepExif: false,
    );
    if (output == null) {
      throw const RetainedScanImageException('Image compression failed.');
    }

    final outputFile = File(output.path);
    if (!await outputFile.exists() || await outputFile.length() == 0) {
      throw const RetainedScanImageException(
        'Image compression returned an empty file.',
      );
    }
    final outputDimensions = await _readDimensions(outputFile);
    if (outputDimensions.longEdge > maximumLongEdge) {
      throw const RetainedScanImageException(
        'The compressed image exceeds the approved size.',
      );
    }
  }

  static Future<_ImageDimensions> _readDimensions(File file) async {
    final Uint8List bytes = await file.readAsBytes();
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      try {
        final frame = await codec.getNextFrame();
        try {
          return _ImageDimensions(frame.image.width, frame.image.height);
        } finally {
          frame.image.dispose();
        }
      } finally {
        codec.dispose();
      }
    } on Object catch (error) {
      throw RetainedScanImageException(
        'The image could not be decoded: $error',
      );
    }
  }
}

final class _ImageDimensions {
  const _ImageDimensions(this.width, this.height);

  final int width;
  final int height;

  int get longEdge => width > height ? width : height;

  _ImageDimensions fitWithin(int maximumLongEdge) {
    if (longEdge <= maximumLongEdge) {
      return this;
    }
    final scale = maximumLongEdge / longEdge;
    return _ImageDimensions(
      (width * scale).round().clamp(1, maximumLongEdge),
      (height * scale).round().clamp(1, maximumLongEdge),
    );
  }
}
