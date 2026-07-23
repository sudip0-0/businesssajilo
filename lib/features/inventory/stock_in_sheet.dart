import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/qty_stepper.dart';
import '../../core/ui/submit_action.dart';
import '../../data/repositories/stock_repository.dart';
import '../auth/providers/auth_provider.dart';

class StockInSheet extends ConsumerStatefulWidget {
  const StockInSheet({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<StockInSheet> createState() => _StockInSheetState();
}

class _StockInSheetState extends ConsumerState<StockInSheet> {
  int _qty = 1;
  bool _loading = false;

  Future<void> _submit() async {
    final memberId = ref.read(authProvider).value?.member?.id;
    if (memberId == null) return;
    setState(() => _loading = true);
    await runSubmitAction(
      context,
      action: () async {
        await ref
            .read(stockRepositoryProvider)
            .stockIn(
              productId: widget.productId,
              qty: _qty,
              createdByMemberId: memberId,
            );
        if (mounted) Navigator.pop(context, true);
      },
    );
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Material(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.stockIn, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(l10n.stockInQty),
            const SizedBox(height: 8),
            Center(
              child: QtyStepper(
                value: _qty,
                min: 1,
                onChanged: (v) => setState(() => _qty = v),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
