final class ImagePreprocessingException implements Exception {
  const ImagePreprocessingException(this.message);

  final String message;

  @override
  String toString() => 'ImagePreprocessingException: $message';
}
