import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/enums.dart';
import '../../domain/models/member.dart';
import '../repositories/members_repository.dart';
import 'supabase_provider.dart';

class SupabaseMembersRepository implements MembersRepository {
  SupabaseMembersRepository(this._client);

  final SupabaseClient? _client;

  @override
  Future<List<Member>> listMembers() async {
    final client = requireSupabaseClient(_client);
    final rows = await client
        .from('members')
        .select()
        .order('created_at', ascending: true);
    return (rows as List)
        .map((row) => Member.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<({String memberId, String? customerId})> createMember({
    String? email,
    required String password,
    required Role role,
    required String displayName,
    String? phone,
    String? shopName,
    String? contactName,
    String? address,
    int openingBalance = 0,
    bool isActive = true,
  }) async {
    final client = requireSupabaseClient(_client);
    final response = await client.functions.invoke(
      'create-member',
      body: {
        'email': ?email,
        'password': password,
        'role': role.name,
        'displayName': displayName,
        'phone': ?phone,
        'shopName': ?shopName,
        'contactName': ?contactName,
        'address': ?address,
        'openingBalance': openingBalance,
        'isActive': isActive,
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

  @override
  Future<void> resetMemberPassword({
    required String memberId,
    required String newPassword,
  }) async {
    final client = requireSupabaseClient(_client);
    final response = await client.functions.invoke(
      'reset-member-password',
      body: {'memberId': memberId, 'newPassword': newPassword},
    );
    if (response.status != 200) {
      final data = response.data;
      final message = data is Map ? data['error']?.toString() : null;
      throw Exception(message ?? 'Failed to reset password');
    }
  }

  @override
  Future<void> deactivateMember(String memberId) async {
    final client = requireSupabaseClient(_client);
    await client
        .from('members')
        .update({'is_active': false})
        .eq('id', memberId);
  }

  @override
  Future<void> activateMember(String memberId) async {
    final client = requireSupabaseClient(_client);
    await client.from('members').update({'is_active': true}).eq('id', memberId);
  }

  @override
  Future<Member?> getMember(String memberId) async {
    final client = requireSupabaseClient(_client);
    final row = await client
        .from('members')
        .select()
        .eq('id', memberId)
        .maybeSingle();
    if (row == null) return null;
    return Member.fromJson(Map<String, dynamic>.from(row));
  }
}
