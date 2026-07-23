import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/enums.dart';
import '../../domain/models/member.dart';
import '../remote/supabase_members_repository.dart';
import '../remote/supabase_provider.dart';

final membersRepositoryProvider = Provider<MembersRepository>((ref) {
  return SupabaseMembersRepository(ref.watch(supabaseClientProvider));
});

abstract class MembersRepository {
  Future<List<Member>> listMembers();

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
  });

  /// Owner sets a temporary password for a member (staff or customer).
  /// The member is forced to choose a new password on next login.
  Future<void> resetMemberPassword({
    required String memberId,
    required String newPassword,
  });

  Future<void> deactivateMember(String memberId);
  Future<void> activateMember(String memberId);
  Future<Member?> getMember(String memberId);
}
