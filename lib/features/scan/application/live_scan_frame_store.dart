import 'package:kami/features/scan/domain/ripeness_classifier.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

abstract interface class LiveScanFrameStore {
  Future<SelectedScanImage> writeTemporary(LiveCameraFrame frame);

  Future<void> removeTemporary(SelectedScanImage image);
}

final class LiveScanFrameStoreException implements Exception {
  const LiveScanFrameStoreException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'LiveScanFrameStoreException: $message';
}
