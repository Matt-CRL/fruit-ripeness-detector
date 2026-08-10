import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kami/features/scan/domain/scan_image_picker.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

final scanImagePickerProvider = Provider<ScanImagePicker>((ref) {
  return ImagePickerScanImagePicker(ImagePicker());
});

final class ImagePickerScanImagePicker implements ScanImagePicker {
  ImagePickerScanImagePicker(this._picker);

  final ImagePicker _picker;

  @override
  Future<SelectedScanImage?> pickFromGallery() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
      return image == null ? null : await _selectedImage(image);
    } on Object catch (error) {
      throw ScanImagePickerFailure('Gallery selection failed: $error');
    }
  }

  @override
  Future<SelectedScanImage?> recoverLostSelection() async {
    try {
      final response = await _picker.retrieveLostData();
      if (response.isEmpty) {
        return null;
      }

      final files = response.files;
      if (files != null && files.isNotEmpty) {
        return await _selectedImage(files.first);
      }

      throw ScanImagePickerFailure(
        response.exception?.message ?? 'The interrupted selection was lost.',
      );
    } on ScanImagePickerFailure {
      rethrow;
    } on Object catch (error) {
      throw ScanImagePickerFailure('Selection recovery failed: $error');
    }
  }

  Future<SelectedScanImage> _selectedImage(XFile image) async {
    if (await image.length() == 0) {
      throw const ScanImagePickerFailure('The selected image is empty.');
    }
    return SelectedScanImage(path: image.path, name: image.name);
  }
}
