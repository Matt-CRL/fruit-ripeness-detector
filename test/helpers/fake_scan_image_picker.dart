import 'package:kami/features/scan/domain/scan_image_picker.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

final class FakeScanImagePicker implements ScanImagePicker {
  SelectedScanImage? nextSelection;
  SelectedScanImage? recoveredSelection;
  bool failPick = false;
  bool failRecovery = false;
  int pickCalls = 0;
  int recoveryCalls = 0;

  @override
  Future<SelectedScanImage?> pickFromGallery() async {
    pickCalls += 1;
    if (failPick) {
      throw const ScanImagePickerFailure('Fake picker failure.');
    }
    return nextSelection;
  }

  @override
  Future<SelectedScanImage?> recoverLostSelection() async {
    recoveryCalls += 1;
    if (failRecovery) {
      throw const ScanImagePickerFailure('Fake recovery failure.');
    }
    return recoveredSelection;
  }
}
