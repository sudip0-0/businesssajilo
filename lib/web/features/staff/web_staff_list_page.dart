import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/utils/role_label.dart';
import '../../../data/repositories/members_repository.dart';
import '../../../domain/enums.dart';
import '../../../domain/models/member.dart';
import '../../../features/staff/add_member_sheet.dart';
import '../../../features/staff/reset_member_password_sheet.dart';
import '../../../features/staff/staff_list_screen.dart';
import '../../theme/web_palette.dart';
import '../../ui/web_data_table.dart';
import '../../ui/web_empty_state.dart';
import '../../ui/web_side_panel.dart';
import '../web_page_scaffold.dart';

bool _isStaffRole(Role role) =>
    role == Role.sales || role == Role.warehouse || role == Role.owner;

class WebStaffListPage extends ConsumerStatefulWidget {
  const WebStaffListPage({super.key});

  @override
  ConsumerState<WebStaffListPage> createState() => _WebStaffListPageState();
}

class _WebStaffListPageState extends ConsumerState<WebStaffListPage> {
  int? _sortColumnIndex;
  bool _sortAscending = true;
  bool _showInactive = true;

  Future<void> _openAddMember() async {
    final l10n = AppLocalizations.of(context);
    final created = await showWebSidePanel<bool>(
      context: context,
      title: l10n.addMember,
      child: const AddMemberSheet(),
    );
    if (created == true) ref.invalidate(staffListProvider);
  }

  Future<void> _deactivate(Member member) async {
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

  Future<void> _reactivate(Member member) async {
    await ref.read(membersRepositoryProvider).activateMember(member.id);
    ref.invalidate(staffListProvider);
  }

  List<Member> _sorted(List<Member> members) {
    final sorted = List<Member>.from(members);
    if (_sortColumnIndex == null) return sorted;
    sorted.sort((a, b) {
      final cmp = switch (_sortColumnIndex) {
        0 => a.displayName.compareTo(b.displayName),
        1 => a.role.name.compareTo(b.role.name),
        2 => (a.phone ?? '').compareTo(b.phone ?? ''),
        _ => 0,
      };
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final staffAsync = ref.watch(staffListProvider);

    return WebPageScaffold(
      title: l10n.staffManagement,
      breadcrumbs: [l10n.staffManagement],
      actions: [
        FilterChip(
          label: Text(_showInactive ? l10n.hideInactive : l10n.showInactive),
          selected: _showInactive,
          onSelected: (v) => setState(() => _showInactive = v),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _openAddMember,
          icon: const Icon(PhosphorIconsRegular.userPlus),
          label: Text(l10n.addMember),
        ),
      ],
      body: AsyncBody(
        value: staffAsync,
        onRetry: () => ref.invalidate(staffListProvider),
        data: (members) {
          final staff = members
              .where((m) => _isStaffRole(m.role))
              .where((m) => _showInactive || m.isActive)
              .toList();
          if (staff.isEmpty) {
            return WebEmptyState(
              message: l10n.noStaff,
              icon: PhosphorIconsRegular.users,
              actionLabel: l10n.addMember,
              onAction: _openAddMember,
            );
          }

          final sorted = _sorted(staff);

          return WebDataTable<Member>(
            columns: [
              DataColumn(
                label: Text(l10n.displayName),
                onSort: (_, asc) => setState(() {
                  _sortColumnIndex = 0;
                  _sortAscending = asc;
                }),
              ),
              DataColumn(
                label: Text(l10n.staff),
                onSort: (_, asc) => setState(() {
                  _sortColumnIndex = 1;
                  _sortAscending = asc;
                }),
              ),
              DataColumn(
                label: Text(l10n.phoneNumber),
                onSort: (_, asc) => setState(() {
                  _sortColumnIndex = 2;
                  _sortAscending = asc;
                }),
              ),
              DataColumn(label: Text(l10n.active)),
              const DataColumn(label: Text('')),
            ],
            items: sorted,
            sortColumnIndex: _sortColumnIndex,
            sortAscending: _sortAscending,
            rowBuilder: (member, index) => DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: WebPalette.navyWash,
                        child: Text(
                          member.displayName.isNotEmpty
                              ? member.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: WebPalette.navy,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(member.displayName),
                    ],
                  ),
                ),
                DataCell(
                  member.role == Role.owner
                      ? Chip(label: Text(l10n.roleOwner))
                      : Text(roleLabel(l10n, member.role)),
                ),
                DataCell(Text(member.phone ?? '—')),
                DataCell(
                  Chip(
                    label: Text(member.isActive ? l10n.active : l10n.inactive),
                  ),
                ),
                DataCell(
                  member.role == Role.owner
                      ? const SizedBox.shrink()
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: l10n.resetPassword,
                              icon: const Icon(PhosphorIconsRegular.lockKey),
                              onPressed: () => showResetMemberPasswordSheet(
                                context,
                                memberId: member.id,
                                memberName: member.displayName,
                              ),
                            ),
                            if (member.isActive)
                              IconButton(
                                tooltip: l10n.deactivate,
                                icon: const Icon(
                                  PhosphorIconsRegular.userMinus,
                                ),
                                onPressed: () => _deactivate(member),
                              )
                            else
                              IconButton(
                                tooltip: l10n.reactivate,
                                icon: const Icon(PhosphorIconsRegular.userPlus),
                                onPressed: () => _reactivate(member),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
