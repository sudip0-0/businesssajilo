import 'dart:typed_data';

import 'package:businesssajilo/core/validation/image_upload.dart';
import 'package:businesssajilo/core/validation/message_validator.dart';
import 'package:businesssajilo/core/validation/password_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageValidator', () {
    test('accepts body at max length', () {
      final body = 'a' * MessageValidator.maxBodyLength;
      expect(MessageValidator.isBodyTooLong(body), isFalse);
    });

    test('rejects body over max length', () {
      final body = 'a' * (MessageValidator.maxBodyLength + 1);
      expect(MessageValidator.isBodyTooLong(body), isTrue);
    });
  });

  group('PasswordValidator', () {
    test('rejects empty and oversized passwords', () {
      expect(PasswordValidator.validate(''), isNotNull);
      expect(PasswordValidator.validate('a' * 73), isNotNull);
    });

    test('accepts valid password', () {
      expect(PasswordValidator.validate('secure-pass-1'), isNull);
    });
  });

  group('ImageUpload', () {
    test('rejects empty / non-image bytes', () {
      expect(ImageUpload.validate(Uint8List(0)), ImageUploadError.invalidType);
      expect(
        ImageUpload.validate(Uint8List.fromList(List.filled(20, 0))),
        ImageUploadError.invalidType,
      );
    });

    test('accepts JPEG magic bytes', () {
      final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, ...List.filled(20, 0)]);
      expect(ImageUpload.sniffMime(jpeg), 'image/jpeg');
      expect(ImageUpload.validate(jpeg), isNull);
    });

    test('rejects oversized payload', () {
      final jpeg = Uint8List(ImageUpload.maxBytes + 10);
      jpeg[0] = 0xFF;
      jpeg[1] = 0xD8;
      jpeg[2] = 0xFF;
      expect(ImageUpload.validate(jpeg), ImageUploadError.tooLarge);
    });
  });
}
