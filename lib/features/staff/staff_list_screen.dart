import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/async_body.dart';
import '../../core/ui/empty_state.dart';
import '../../core/utils/role_label.dart';
import '../../data/repositories/members_repository.dart';
import '../../domain/enums.dart';
import '../../domain/models/member.dart';
import 'reset_member_password_sheet.dart';

final staffListProvider = FutureProvider.autoDispose<List<Member>>((ref) {
  return ref.watch(membersRepositoryProvider).listMembers();
});

class StaffListScreen extends ConsumerWidget {
  const StaffListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final staffAsync = ref.watch(staffListProvider);

    return AsyncBody(
      value: staffAsync,
      onRetry: () => ref.invalidate(staffListProvider),
      data: (members) {
        final active = members.where((m) => m.isActive).toList();
        if (active.isEmpty) {
          return EmptyState(icon: Icons.people_outline, message: l10n.noStaff);
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: active.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final member = active[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: BsColors.primary.withValues(alpha: 0.12),
                child: Text(
                  member.displayName.isNotEmpty
                      ? member.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: BsColors.primary),
                ),
              ),
              title: Text(member.displayName),
              subtitle: Text(
                '${roleLabel(l10n, member.role)}${member.phone != null ? ' · ${member.phone}' : ''}',
              ),
              trailing: member.role == Role.owner
                  ? Chip(label: Text(l10n.roleOwner))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10n.resetPassword,
                          icon: const Icon(Icons.lock_reset_outlined),
                          onPressed: () => showResetMemberPasswordSheet(
                            context,
                            memberId: member.id,
                            memberName: member.displayName,
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.deactivate,
                          icon: const Icon(Icons.person_off_outlined),
                          onPressed: () => _deactivate(context, ref, member),
                        ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  Future<void> _deactivate(
    BuildContext context,
    WidgetRef ref,
    Member member,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deactivate),
        content: Text(l10n.deactivateConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deactivate),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(membersRepositoryProvider).deactivateMember(member.id);
    ref.invalidate(staffListProvider);
  }
}
