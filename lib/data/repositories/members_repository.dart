import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/enums.dart';
import '../../domain/models/member.dart';
import '../remote/supabase_provider.dart';

final membersRepositoryProvider = Provider<MembersRepository>((ref) {
  return MembersRepository(ref.watch(supabaseClientProvider));
});

class MembersRepository {
  MembersRepository(this._client);

  final SupabaseClient? _client;

  Future<List<Member>> listMembers() async {
    final client = _requireClient();
    final rows = await client
        .from('members')
        .select()
        .order('created_at', ascending: true);
    return (rows as List)
        .map((row) => Member.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<({String memberId, String? customerId})> createMember({
    required String email,
    required String password,
    required Role role,
    required String displayName,
    String? phone,
    String? shopName,
    String? contactName,
    String? address,
  }) async {
    final client = _requireClient();
    final response = await client.functions.invoke(
      'create-member',
      body: {
        'email': email,
        'password': password,
        'role': role.name,
        'displayName': displayName,
        'phone': ?phone,
        'shopName': ?shopName,
        'contactName': ?contactName,
        'address': ?address,
      },
    );

    if (response.status != 200) {
      final data = response.data;
      final message = data is Map ? data['error']?.toString() : null;
      throw Exception(message ?? 'Failed to create member');
    }

    final data = response.data as Map<String, dynamic>;
    return (
      memberId: data['memberId'] as String,
      customerId: data['customerId'] as String?,
    );
  }

  Future<void> deactivateMember(String memberId) async {
    final client = _requireClient();
    await client
        .from('members')
        .update({'is_active': false})
        .eq('id', memberId);
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase not configured');
    }
    return client;
  }
}
