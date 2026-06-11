import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/messages_repository.dart';
import '../../domain/models/message.dart';

final orderMessagesProvider =
    StreamProvider.autoDispose.family<List<Message>, String>((ref, orderId) {
  return ref.watch(messagesRepositoryProvider).watch(orderId);
});
