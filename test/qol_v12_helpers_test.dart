import 'package:businesssajilo/core/config/feature_flags.dart';
import 'package:businesssajilo/core/utils/app_prefs.dart';
import 'package:businesssajilo/core/validation/image_upload.dart';
import 'package:businesssajilo/features/billing/payment_allocation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

void main() {
  group('resolveQuoteRate', () {
    test('prefers last quoted when positive', () {
      expect(
        resolveQuoteRate(lastQuotedPaisa: 12500, referencePaisa: 9000),
        12500,
      );
    });

    test('falls back to reference price', () {
      expect(
        resolveQuoteRate(lastQuotedPaisa: null, referencePaisa: 9000),
        9000,
      );
      expect(resolveQuoteRate(lastQuotedPaisa: 0, referencePaisa: 9000), 9000);
    });
  });

  group('PaymentAllocation', () {
    test('oldest first sends allocate flag', () {
      const a = PaymentAllocation(mode: PaymentAllocateMode.oldestFirst);
      expect(a.rpcAllocate, 'oldest_first');
      expect(a.rpcBillId, isNull);
    });

    test('bill mode sends bill id', () {
      const a = PaymentAllocation(mode: PaymentAllocateMode.bill, billId: 'b1');
      expect(a.rpcBillId, 'b1');
      expect(a.rpcAllocate, isNull);
    });
  });

  group('ImageUpload.compressForUpload', () {
    test('leaves small images unchanged', () {
      final original = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0x01, 0x02]);
      expect(ImageUpload.compressForUpload(original), same(original));
    });

    test('shrinks a large generated bitmap', () {
      final canvas = img.Image(width: 1600, height: 1600);
      img.fill(canvas, color: img.ColorRgb8(200, 40, 40));
      final bytes = Uint8List.fromList(img.encodeBmp(canvas));
      expect(bytes.length, greaterThan(ImageUpload.compressBelowBytes));
      final compressed = ImageUpload.compressForUpload(bytes);
      expect(compressed.length, lessThan(bytes.length));
      expect(ImageUpload.sniffMime(compressed), 'image/jpeg');
    });
  });

  test('quote TTL is 7 days', () {
    final created = DateTime.utc(2026, 1, 1);
    expect(quoteExpiresAt(created), DateTime.utc(2026, 1, 8));
  });

  group('NotificationMutePrefs', () {
    test('mutes dues reminders by default', () {
      const prefs = NotificationMutePrefs();
      expect(prefs.dues, isTrue);
      expect(prefs.chat, isFalse);
      expect(prefs.lowStock, isFalse);
      expect(prefs.mutedTypes, ['dues_reminder']);
    });

    test('load treats a missing dues key as muted', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await NotificationMutePrefs.load();
      expect(prefs.dues, isTrue);
      expect(prefs.mutedTypes, ['dues_reminder']);
    });

    test('load keeps an explicit unmute', () async {
      SharedPreferences.setMockInitialValues({notifMuteDuesPrefKey: false});
      final prefs = await NotificationMutePrefs.load();
      expect(prefs.dues, isFalse);
      expect(prefs.mutedTypes, isEmpty);
    });

    test('fromNotificationPrefs reads muted types from server json', () {
      final prefs = NotificationMutePrefs.fromNotificationPrefs({
        'muted': ['dues_reminder', 'chat_message'],
      });
      expect(prefs.dues, isTrue);
      expect(prefs.chat, isTrue);
      expect(prefs.lowStock, isFalse);
      expect(prefs.mutes('dues_reminder'), isTrue);
      expect(prefs.mutes('low_stock'), isFalse);
    });

    test('fromNotificationPrefs treats an empty muted list as unmuted', () {
      final prefs = NotificationMutePrefs.fromNotificationPrefs({
        'muted': <String>[],
      });
      expect(prefs.dues, isFalse);
      expect(prefs.mutedTypes, isEmpty);
    });

    test('fromNotificationPrefs keeps dues muted when json is missing', () {
      expect(
        NotificationMutePrefs.fromNotificationPrefs(null).dues,
        isTrue,
      );
    });
  });
}
