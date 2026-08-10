import 'package:kami/features/scan/domain/scan_models.dart';

abstract interface class ScanImagePicker {
  Future<SelectedScanImage?> pickFromGallery();

  Future<SelectedScanImage?> recoverLostSelection();
}

final class ScanImagePickerFailure implements Exception {
  const ScanImagePickerFailure(this.message);

  final String message;

  @override
  String toString() => 'ScanImagePickerFailure: $message';
}
