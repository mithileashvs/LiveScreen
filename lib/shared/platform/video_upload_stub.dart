class VideoUploadResult {
  final String? storageUrl;
  final String? fileName;
  final String? errorMessage;

  const VideoUploadResult({
    this.storageUrl,
    this.fileName,
    this.errorMessage,
  });

  bool get isSuccess => storageUrl != null && errorMessage == null;
}

Future<VideoUploadResult?> pickAndUploadImmersiveTrailer({
  required String producerId,
}) async {
  return const VideoUploadResult(
    errorMessage: 'File upload is not supported on this platform.',
  );
}
