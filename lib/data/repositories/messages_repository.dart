import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/message.dart';
import '../remote/supabase_messages_repository.dart';
import '../remote/supabase_provider.dart';

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  return SupabaseMessagesRepository(ref.watch(supabaseClientProvider));
});

abstract class MessagesRepository {
  Stream<List<Message>> watch(String orderId);

  Future<Message> sendText({
    required String orderId,
    required String senderMemberId,
    required String body,
  });

  Future<Message> sendImage({
    required String orderId,
    required String senderMemberId,
    required String businessId,
    required Uint8List bytes,
    required String fileName,
  });

  Future<String?> signedImageUrl(String? storagePath);
}
