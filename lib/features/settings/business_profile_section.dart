import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/submit_action.dart';
import '../../data/repositories/businesses_repository.dart';
import '../../domain/enums.dart';
import '../auth/providers/auth_provider.dart';

class BusinessProfileSection extends ConsumerStatefulWidget {
  const BusinessProfileSection({super.key});

  @override
  ConsumerState<BusinessProfileSection> createState() =>
      _BusinessProfileSectionState();
}

class _BusinessProfileSectionState
    extends ConsumerState<BusinessProfileSection> {
  final _name = TextEditingController();
  final _nameNp = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  var _hydrated = false;
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _nameNp.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save(String businessId) async {
    setState(() => _saving = true);
    await runSubmitAction(
      context,
      action: () async {
        await ref
            .read(businessesRepositoryProvider)
            .update(
              id: businessId,
              name: _name.text,
              nameNp: _nameNp.text.trim().isEmpty ? null : _nameNp.text.trim(),
              address: _address.text.trim().isEmpty
                  ? null
                  : _address.text.trim(),
              phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            );
        ref.invalidate(currentBusinessProvider);
      },
    );
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(authProvider).value?.member?.role;
    if (role != Role.owner) return const SizedBox.shrink();

    final businessAsync = ref.watch(currentBusinessProvider);
    return businessAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (business) {
        if (business == null) return const SizedBox.shrink();
        if (!_hydrated) {
          _hydrated = true;
          _name.text = business.name;
          _nameNp.text = business.nameNp ?? '';
          _address.text = business.address ?? '';
          _phone.text = business.phone ?? '';
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.businessProfile,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.businessProfileHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                decoration: InputDecoration(labelText: l10n.businessName),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameNp,
                decoration: InputDecoration(labelText: l10n.businessNameNp),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _address,
                decoration: InputDecoration(labelText: l10n.address),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phone,
                decoration: InputDecoration(labelText: l10n.phone),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving ? null : () => _save(business.id),
                child: Text(l10n.save),
              ),
            ],
          ),
        );
      },
    );
  }
}
