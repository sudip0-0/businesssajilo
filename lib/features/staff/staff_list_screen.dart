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

bool _isStaffRole(Role role) =>
    role == Role.sales || role == Role.warehouse || role == Role.owner;

class StaffListScreen extends ConsumerStatefulWidget {
  const StaffListScreen({super.key});

  @override
  ConsumerState<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends ConsumerState<StaffListScreen> {
  bool _showInactive = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final staffAsync = ref.watch(staffListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(
            _showInactive ? l10n.hideInactive : l10n.showInactive,
          ),
          value: _showInactive,
          onChanged: (v) => setState(() => _showInactive = v),
        ),
        Expanded(
          child: AsyncBody(
            value: staffAsync,
            onRetry: () => ref.invalidate(staffListProvider),
            data: (members) {
              final staff = members
                  .where((m) => _isStaffRole(m.role))
                  .where((m) => _showInactive || m.isActive)
                  .toList();
              if (staff.isEmpty) {
                return EmptyState(
                  icon: Icons.people_outline,
                  message: l10n.noStaff,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: staff.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final member = staff[index];
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
                      [
                        roleLabel(l10n, member.role),
                        if (member.phone != null) member.phone!,
                        member.isActive ? l10n.active : l10n.inactive,
                      ].join(' · '),
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
                              if (member.isActive)
                                IconButton(
                                  tooltip: l10n.deactivate,
                                  icon: const Icon(Icons.person_off_outlined),
                                  onPressed: () =>
                                      _deactivate(context, ref, member),
                                )
                              else
                                IconButton(
                                  tooltip: l10n.reactivate,
                                  icon: const Icon(Icons.person_add_outlined),
                                  onPressed: () =>
                                      _reactivate(context, ref, member),
                                ),
                            ],
                          ),
                  );
                },
              );
            },
          ),
        ),
      ],
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

  Future<void> _reactivate(
    BuildContext context,
    WidgetRef ref,
    Member member,
  ) async {
    await ref.read(membersRepositoryProvider).activateMember(member.id);
    ref.invalidate(staffListProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).reactivate)),
    );
  }
}
