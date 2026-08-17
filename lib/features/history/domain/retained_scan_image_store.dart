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

  /// Copies an already-retained app-private JPEG to a new scan identity.
  ///
  /// This is used when a linked account's offline workspace is deliberately
  /// detached into a fresh local-only Guest workspace. The copy keeps the
  /// image local while preventing the old scan ID from being reused by a
  /// later synchronization session.
  Future<RetainedScanImage> copyToScan({
    required String sourceRelativePath,
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
