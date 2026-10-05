// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final uploadInput = html.FileUploadInputElement();
  uploadInput.accept = 'image/jpeg,image/png,image/webp,image/gif';
  uploadInput.click();

  await uploadInput.onChange.first;
  final files = uploadInput.files;
  if (files == null || files.isEmpty) {
    return null; // User cancelled
  }

  final file = files.first;
  final fileName = file.name;
  final mimeType = file.type;

  // Max 5MB
  if (file.size > 5 * 1024 * 1024) {
    return const ImageUploadResult(
      errorMessage: 'Image must be under 5MB.',
    );
  }

  final reader = html.FileReader();
  reader.readAsArrayBuffer(file);
  await reader.onLoadEnd.first;

  if (reader.result == null) {
    return const ImageUploadResult(
      errorMessage: 'Could not read the selected image file.',
    );
  }

  final bytes = reader.result is Uint8List
      ? reader.result as Uint8List
      : Uint8List.fromList(reader.result as List<int>);

  final cleanName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final cleanTheatreId = theatreId.isEmpty ? 'general' : theatreId;
  final storagePath = '$cleanTheatreId/${timestamp}_$cleanName';

  try {
    final client = Supabase.instance.client;
    final effectiveMime = mimeType.isNotEmpty ? mimeType : 'image/jpeg';

    await client.storage.from('snack-images').uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: effectiveMime,
            upsert: true,
          ),
        );

    final publicUrl = client.storage.from('snack-images').getPublicUrl(storagePath);
    return ImageUploadResult(
      storageUrl: publicUrl,
      fileName: fileName,
    );
  } on StorageException catch (e) {
    final msg = e.message.toLowerCase();
    final status = e.statusCode?.toString() ?? '';
    final isBucketNotFound = status == '404' || msg.contains('bucket not found');
    if (isBucketNotFound) {
      return const ImageUploadResult(
        errorMessage: 'The "snack-images" storage bucket has not been created yet in Supabase.',
      );
    }
    return ImageUploadResult(
      errorMessage: 'Storage error: ${e.message}',
    );
  } catch (e) {
    return ImageUploadResult(
      errorMessage: 'Upload failed: $e',
    );
  }
}
