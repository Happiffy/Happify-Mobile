import 'dart:convert';
import 'dart:typed_data';

import '../../../core/app_services.dart';
import '../../../core/happify_repository.dart';

class UploadedImage {
  const UploadedImage({required this.url, required this.key});

  final String url;
  final String key;
}

class MediaRepository {
  const MediaRepository(this._repository);

  static const maxBytes = 5 * 1024 * 1024;
  static const allowedTypes = {'image/jpeg', 'image/png', 'image/webp'};

  final HappifyRepository _repository;

  Future<UploadedImage> upload({
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (!allowedTypes.contains(contentType)) {
      throw const AppFailure('Choose a JPEG, PNG, or WebP image.');
    }
    if (bytes.isEmpty) throw const AppFailure('The selected image is empty.');
    if (bytes.length > maxBytes) {
      throw const AppFailure('Choose an image smaller than 5 MB.');
    }
    final result = await _repository.uploadImage(
      imageBase64: base64Encode(bytes),
      contentType: contentType,
    );
    final url = result['url']?.toString() ?? '';
    final key = result['key']?.toString() ?? '';
    if (!Uri.tryParse(url)!.hasScheme || key.isEmpty) {
      throw const AppFailure('The uploaded image response was invalid.');
    }
    return UploadedImage(url: url, key: key);
  }
}
