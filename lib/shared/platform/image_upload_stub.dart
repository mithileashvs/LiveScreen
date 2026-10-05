class ImageUploadResult {
  final String? storageUrl;
  final String? fileName;
  final String? errorMessage;

  const ImageUploadResult({
    this.storageUrl,
    this.fileName,
    this.errorMessage,
  });

  bool get isSuccess => storageUrl != null && errorMessage == null;
}

Future<ImageUploadResult?> pickAndUploadSnackImage({
  required String theatreId,
}) async {
  return const ImageUploadResult(
    errorMessage: 'Image upload is not supported on this platform.',
  );
}
