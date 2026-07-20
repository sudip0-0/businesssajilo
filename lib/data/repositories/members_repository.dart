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

  /// [email] may be omitted when [phone] is given; the Edge Function then
  /// derives a synthetic login email from the phone number.
  ///
  /// When [isActive] is false (e.g. customer created without portal login),
  /// the member row is created inactive so they cannot sign in until enabled.
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
    final client = _requireClient();
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

  /// Owner sets a temporary password for a member (staff or customer).
  /// The member is forced to choose a new password on next login.
  Future<void> resetMemberPassword({
    required String memberId,
    required String newPassword,
  }) async {
    final client = _requireClient();
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

  Future<void> deactivateMember(String memberId) async {
    final client = _requireClient();
    await client
        .from('members')
        .update({'is_active': false})
        .eq('id', memberId);
  }

  Future<void> activateMember(String memberId) async {
    final client = _requireClient();
    await client
        .from('members')
        .update({'is_active': true})
        .eq('id', memberId);
  }

  Future<Member?> getMember(String memberId) async {
    final client = _requireClient();
    final row = await client
        .from('members')
        .select()
        .eq('id', memberId)
        .maybeSingle();
    if (row == null) return null;
    return Member.fromJson(Map<String, dynamic>.from(row));
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase not configured');
    }
    return client;
  }
}
