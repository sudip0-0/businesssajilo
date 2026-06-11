import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/message.dart';
import '../remote/supabase_provider.dart';

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  return MessagesRepository(ref.watch(supabaseClientProvider));
});

class MessagesRepository {
  MessagesRepository(this._client);

  final SupabaseClient? _client;
  static const _bucket = 'order-chat-images';

  Future<List<Message>> list(String orderId) async {
    final client = _requireClient();
    final rows = await client
        .from('messages')
        .select('*, members(display_name)')
        .eq('order_id', orderId)
        .order('created_at', ascending: true);
    return (rows as List).map(_mapRow).toList();
  }

  Stream<List<Message>> watch(String orderId) {
    final client = _requireClient();
    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('order_id', orderId)
        .order('created_at')
        .map((rows) => rows.map(_mapRow).toList());
  }

  Future<Message> sendText({
    required String orderId,
    required String senderMemberId,
    required String body,
  }) async {
    final client = _requireClient();
    final id = const Uuid().v4();
    final row = await client
        .from('messages')
        .insert({
          'id': id,
          'order_id': orderId,
          'sender_member_id': senderMemberId,
          'body': body,
        })
        .select('*, members(display_name)')
        .single();
    return _mapRow(row);
  }

  Future<Message> sendImage({
    required String orderId,
    required String senderMemberId,
    required String businessId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final client = _requireClient();
    final path = '$businessId/$orderId/${const Uuid().v4()}_$fileName';
    await client.storage.from(_bucket).uploadBinary(path, bytes);

    final id = const Uuid().v4();
    final row = await client
        .from('messages')
        .insert({
          'id': id,
          'order_id': orderId,
          'sender_member_id': senderMemberId,
          'image_url': path,
        })
        .select('*, members(display_name)')
        .single();
    return _mapRow(row);
  }

  Future<String?> signedImageUrl(String? storagePath) async {
    if (storagePath == null || storagePath.isEmpty) return null;
    final client = _requireClient();
    return client.storage
        .from(_bucket)
        .createSignedUrl(storagePath, 60 * 60 * 24);
  }

  Message _mapRow(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    final member = map.remove('members');
    if (member is Map) {
      map['sender_name'] = member['display_name'];
    }
    return Message.fromJson(map);
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) throw Exception('Supabase not configured');
    return client;
  }
}
