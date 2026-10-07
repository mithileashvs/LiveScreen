// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/trailer_url.dart';

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
  final uploadInput = html.FileUploadInputElement();
  uploadInput.accept = 'video/mp4,video/webm';
  uploadInput.click();

  await uploadInput.onChange.first;
  final files = uploadInput.files;
  if (files == null || files.isEmpty) {
    return null; // User cancelled the picker
  }

  final file = files.first;
  final fileName = file.name;
  final mimeType = file.type;

  // 1. Validate file extension and MIME type before reading/uploading
  final validationError = TrailerSource.validateImmersiveVideoFile(
    fileName: fileName,
    mimeType: mimeType,
  );
  if (validationError != null) {
    return VideoUploadResult(errorMessage: validationError);
  }

  // 2. Read bytes as ArrayBuffer
  final reader = html.FileReader();
  reader.readAsArrayBuffer(file);
  await reader.onLoadEnd.first;

  if (reader.result == null) {
    return const VideoUploadResult(
      errorMessage: 'Could not read the selected video file.',
    );
  }

  final bytes = reader.result is Uint8List
      ? reader.result as Uint8List
      : Uint8List.fromList(reader.result as List<int>);

  // 3. Upload to Supabase Storage 'trailers' bucket
  final cleanName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final cleanProducerId = producerId.isEmpty ? 'anonymous' : producerId;
  final storagePath = 'immersive/$cleanProducerId/${timestamp}_$cleanName';

  try {
    final client = Supabase.instance.client;
    final effectiveMime = mimeType.isNotEmpty
        ? mimeType
        : (cleanName.toLowerCase().endsWith('.webm') ? 'video/webm' : 'video/mp4');

    await client.storage.from('trailers').uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: effectiveMime,
            upsert: true,
          ),
        );

    final publicUrl = client.storage.from('trailers').getPublicUrl(storagePath);
    return VideoUploadResult(
      storageUrl: publicUrl,
      fileName: fileName,
    );
  } on StorageException catch (e) {
    final msg = e.message.toLowerCase();
    final status = e.statusCode?.toString() ?? '';
    final errStr = e.error?.toString().toLowerCase() ?? '';
    final isBucketNotFound = status == '404' ||
        msg.contains('bucket not found') ||
        errStr.contains('bucket not found');
    if (isBucketNotFound) {
      return const VideoUploadResult(
        errorMessage:
            'The "trailers" storage bucket has not been created yet in your Supabase project. '
            'Please run migration 0008_movie_trailer_dual_assets.sql in your Supabase SQL Editor.',
      );
    }
    final isPermissionDenied = status == '403' ||
        status == '401' ||
        msg.contains('unauthorized') ||
        msg.contains('row-level security') ||
        errStr.contains('accessdenied');
    if (isPermissionDenied) {
      return const VideoUploadResult(
        errorMessage:
            'Permission denied uploading to trailers storage. '
            'Ensure your account has producer privileges and migration 0008 policies are applied.',
      );
    }
    return VideoUploadResult(
      errorMessage: 'Failed to upload video to storage: ${e.message}',
    );
  } catch (e) {
    return VideoUploadResult(
      errorMessage: 'Failed to upload video to storage: $e',
    );
  }
}
