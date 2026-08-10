import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/bs_snackbar.dart';
import '../../core/ui/qty_stepper.dart';
import '../../core/ui/submit_action.dart';
import '../../data/repositories/stock_repository.dart';
import '../auth/providers/auth_provider.dart';
import 'providers.dart';

class StockAdjustSheet extends ConsumerStatefulWidget {
  const StockAdjustSheet({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<StockAdjustSheet> createState() => _StockAdjustSheetState();
}

class _StockAdjustSheetState extends ConsumerState<StockAdjustSheet> {
  final _reasonController = TextEditingController();
  int _qtyDelta = 1;
  bool _negative = false;
  bool _loading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_reasonController.text.trim().isEmpty) {
      showBsSnackBar(
        context,
        message: l10n.reasonRequired,
        backgroundColor: BsColors.danger,
      );
      return;
    }
    final delta = _negative ? -_qtyDelta : _qtyDelta;
    final product = ref.read(productDetailProvider(widget.productId)).value;
    if (delta < 0 &&
        product != null &&
        product.stockCached + delta < 0) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.negativeAdjustTitle),
          content: Text(l10n.negativeAdjustBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.continueAnyway),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }
    final memberId = ref.read(authProvider).value?.member?.id;
    if (memberId == null) return;
    setState(() => _loading = true);
    await runSubmitAction(
      context,
      action: () async {
        await ref
            .read(stockRepositoryProvider)
            .adjust(
              productId: widget.productId,
              qtyDelta: delta,
              reason: _reasonController.text.trim(),
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
            Text(
              l10n.stockAdjust,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _negative = false),
                    icon: const Icon(Icons.add),
                    label: Text('+ ${l10n.qtyChange}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          _negative ? BsColors.success : Colors.white,
                      backgroundColor: _negative ? null : BsColors.success,
                      side: const BorderSide(color: BsColors.success),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _negative = true),
                    icon: const Icon(Icons.remove),
                    label: Text('- ${l10n.qtyChange}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _negative ? Colors.white : BsColors.danger,
                      backgroundColor: _negative ? BsColors.danger : null,
                      side: const BorderSide(color: BsColors.danger),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: QtyStepper(
                value: _qtyDelta,
                min: 1,
                onChanged: (v) => setState(() => _qtyDelta = v),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(labelText: l10n.adjustmentReason),
              maxLines: 2,
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
