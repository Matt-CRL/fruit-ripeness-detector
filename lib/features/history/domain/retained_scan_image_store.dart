import 'dart:typed_data';

final class RetainedScanImage {
  const RetainedScanImage({required this.relativePath});

  final String relativePath;
}

abstract interface class RetainedScanImageStore {
  Future<RetainedScanImage> retain({
    required String sourcePath,
    required String scanId,
  });

  Future<String> resolvePath(String relativePath);

  Future<RetainedScanImage> storeDownloadedJpeg({
    required Uint8List bytes,
    required String scanId,
  });

  Future<void> remove(String relativePath);
}

final class RetainedScanImageException implements Exception {
  const RetainedScanImageException(this.message);

  final String message;

  @override
  String toString() => 'RetainedScanImageException: $message';
}
