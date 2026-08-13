import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Client-side image upload checks (storage buckets enforce 5 MB + MIME).
abstract final class ImageUpload {
  static const maxBytes = 5 * 1024 * 1024;

  /// Skip compression for images already under this size.
  static const compressBelowBytes = 400 * 1024;

  static const _maxSide = 1600;
  static const _jpegQuality = 82;

  /// Detects JPEG / PNG / WebP from magic bytes.
  static String? sniffMime(Uint8List bytes) {
    if (bytes.length < 12) return null;
    // JPEG
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    // PNG
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    // WebP: RIFF....WEBP
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return null;
  }

  static ImageUploadError? validate(Uint8List bytes) {
    if (bytes.lengthInBytes > maxBytes) return ImageUploadError.tooLarge;
    if (sniffMime(bytes) == null) return ImageUploadError.invalidType;
    return null;
  }

  /// Shrinks large photos before Storage upload. Returns [bytes] unchanged
  /// when already small or when decode fails.
  static Uint8List compressForUpload(Uint8List bytes) {
    if (bytes.lengthInBytes <= compressBelowBytes) return bytes;
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    var image = decoded;
    if (image.width > _maxSide || image.height > _maxSide) {
      image = img.copyResize(
        image,
        width: image.width >= image.height ? _maxSide : null,
        height: image.height > image.width ? _maxSide : null,
      );
    }
    final encoded = Uint8List.fromList(
      img.encodeJpg(image, quality: _jpegQuality),
    );
    if (encoded.isEmpty || encoded.lengthInBytes >= bytes.lengthInBytes) {
      return bytes;
    }
    return encoded;
  }

  static String extensionForMime(String mime) {
    if (mime.contains('png')) return 'png';
    if (mime.contains('webp')) return 'webp';
    return 'jpg';
  }
}

enum ImageUploadError { tooLarge, invalidType }
