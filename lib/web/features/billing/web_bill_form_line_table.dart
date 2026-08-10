import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/money.dart';
import '../../../features/billing/bill_draft_line.dart';
import '../../theme/web_palette.dart';

/// Shared column metrics so header labels and row cells stay aligned.
const double _kSnWidth = 40;
const double _kQtyWidth = 88;
const double _kUnitWidth = 72;
const double _kRateWidth = 112;
const double _kAmountWidth = 112;
const double _kActionWidth = 44;
const double _kColGap = 12;

/// Table header for bill line items on web.
class WebBillItemsTableHeader extends StatelessWidget {
  const WebBillItemsTableHeader({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: WebPalette.inkSoft,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          SizedBox(
            width: _kSnWidth,
            child: Text(l10n.sn, style: style),
          ),
          const SizedBox(width: _kColGap),
          Expanded(child: Text(l10n.productName, style: style)),
          const SizedBox(width: _kColGap),
          SizedBox(
            width: _kQtyWidth,
            child: Text(l10n.qty, style: style, textAlign: TextAlign.center),
          ),
          const SizedBox(width: _kColGap),
          SizedBox(
            width: _kUnitWidth,
            child: Text(l10n.unit, style: style),
          ),
          const SizedBox(width: _kColGap),
          SizedBox(
            width: _kRateWidth,
            child: Text(l10n.rateRs, style: style, textAlign: TextAlign.end),
          ),
          const SizedBox(width: _kColGap),
          SizedBox(
            width: _kAmountWidth,
            child: Text(l10n.amountRs, style: style, textAlign: TextAlign.end),
          ),
          const SizedBox(width: _kColGap),
          const SizedBox(width: _kActionWidth),
        ],
      ),
    );
  }
}

/// Single editable bill line row on web.
///
/// Keyboard chain: Qty → Price → [onDoneEditing] (typically product search).
class WebBillItemRow extends StatefulWidget {
  const WebBillItemRow({
    super.key,
    required this.index,
    required this.line,
    required this.l10n,
    required this.onChanged,
    required this.onRemove,
    this.autofocusQty = false,
    this.onQtyFocusHandled,
    this.onDoneEditing,
  });

  final int index;
  final BillDraftLine line;
  final AppLocalizations l10n;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  /// When true after a rebuild, focus jumps to qty and selects its text.
  final bool autofocusQty;

  /// Fired once the autofocus qty request has been applied.
  final VoidCallback? onQtyFocusHandled;

  /// Fired when the user submits the price field (Enter) — parent returns to
  /// product search for the next item.
  final VoidCallback? onDoneEditing;

  @override
  State<WebBillItemRow> createState() => _WebBillItemRowState();
}

class _WebBillItemRowState extends State<WebBillItemRow> {
  late final TextEditingController _qtyController;
  late final TextEditingController _rateController;
  late final FocusNode _qtyFocus;
  late final FocusNode _rateFocus;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: '${widget.line.qty}');
    _rateController = TextEditingController(text: _formatRate(widget.line.rate));
    _qtyFocus = FocusNode(debugLabel: 'billQty');
    _rateFocus = FocusNode(debugLabel: 'billRate');
    _qtyFocus.addListener(_onQtyFocusChange);
    _rateFocus.addListener(_onRateFocusChange);
    if (widget.autofocusQty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusQty());
    }
  }

  @override
  void didUpdateWidget(covariant WebBillItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_qtyFocus.hasFocus) {
      final qtyText = '${widget.line.qty}';
      if (_qtyController.text != qtyText) {
        _qtyController.text = qtyText;
      }
    }
    if (!_rateFocus.hasFocus) {
      final rateText = _formatRate(widget.line.rate);
      if (_rateController.text != rateText) {
        _rateController.text = rateText;
      }
    }
    if (widget.autofocusQty && !oldWidget.autofocusQty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusQty());
    }
  }

  @override
  void dispose() {
    _qtyFocus.removeListener(_onQtyFocusChange);
    _rateFocus.removeListener(_onRateFocusChange);
    _qtyFocus.dispose();
    _rateFocus.dispose();
    _qtyController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  String _formatRate(int rate) =>
      formatNpr(Paisa(rate), showSymbol: false, showPaisa: false);

  void _selectAll(TextEditingController controller) {
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  void _onQtyFocusChange() {
    if (_qtyFocus.hasFocus) _selectAll(_qtyController);
  }

  void _onRateFocusChange() {
    if (_rateFocus.hasFocus) _selectAll(_rateController);
  }

  void _focusQty() {
    if (!mounted) return;
    _qtyController.text = '${widget.line.qty}';
    _qtyFocus.requestFocus();
    _selectAll(_qtyController);
    widget.onQtyFocusHandled?.call();
  }

  void _submitQty() {
    _rateFocus.requestFocus();
  }

  void _submitRate() {
    widget.onDoneEditing?.call();
  }

  static const _fieldDecoration = InputDecoration(
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: WebPalette.hairline.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _kSnWidth,
            child: Text('${widget.index + 1}'),
          ),
          const SizedBox(width: _kColGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.line.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${widget.l10n.availableStock}: '
                  '${widget.line.product.stockCached}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: widget.line.qty > widget.line.product.stockCached
                        ? WebPalette.danger
                        : WebPalette.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: _kColGap),
          SizedBox(
            width: _kQtyWidth,
            child: TextField(
              controller: _qtyController,
              focusNode: _qtyFocus,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _fieldDecoration,
              onChanged: (v) {
                final parsed = int.tryParse(v);
                if (parsed == null) return;
                widget.line.setQty(parsed);
                widget.onChanged();
              },
              onSubmitted: (_) => _submitQty(),
            ),
          ),
          const SizedBox(width: _kColGap),
          SizedBox(
            width: _kUnitWidth,
            child: Text(
              widget.line.product.unit,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: _kColGap),
          SizedBox(
            width: _kRateWidth,
            child: TextField(
              controller: _rateController,
              focusNode: _rateFocus,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.end,
              decoration: _fieldDecoration,
              onChanged: (v) {
                widget.line.rate = parseNpr(v)?.value ?? widget.line.rate;
                widget.onChanged();
              },
              onSubmitted: (_) => _submitRate(),
            ),
          ),
          const SizedBox(width: _kColGap),
          SizedBox(
            width: _kAmountWidth,
            child: Text(
              formatNpr(Paisa(widget.line.lineTotal), showPaisa: false),
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: _kColGap),
          SizedBox(
            width: _kActionWidth,
            child: IconButton(
              tooltip: widget.l10n.remove,
              icon: const Icon(
                PhosphorIconsRegular.trash,
                color: WebPalette.danger,
              ),
              onPressed: widget.onRemove,
            ),
          ),
        ],
      ),
    );
  }
}
