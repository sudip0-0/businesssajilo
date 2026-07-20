import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';

/// Large-touch-target quantity stepper with typeable quantity.
class QtyStepper extends StatefulWidget {
  const QtyStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int? max;

  @override
  State<QtyStepper> createState() => _QtyStepperState();
}

class _QtyStepperState extends State<QtyStepper> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(QtyStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _commitText();
    }
  }

  int _clamp(int v) {
    var next = v;
    if (next < widget.min) next = widget.min;
    if (widget.max != null && next > widget.max!) next = widget.max!;
    return next;
  }

  void _commitText() {
    final parsed = int.tryParse(_controller.text.trim());
    final next = _clamp(parsed ?? widget.min);
    if (_controller.text != '$next') {
      _controller.text = '$next';
    }
    if (next != widget.value) {
      widget.onChanged(next);
    }
  }

  void _setValue(int raw) {
    final next = _clamp(raw);
    _controller.text = '$next';
    if (next != widget.value) {
      widget.onChanged(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: widget.value > widget.min
              ? () => _setValue(widget.value - 1)
              : null,
          icon: const Icon(Icons.remove),
          tooltip: l10n.decreaseQuantity,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
        SizedBox(
          width: 72,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (text) {
              final parsed = int.tryParse(text.trim());
              if (parsed == null) return;
              final next = _clamp(parsed);
              if (next != widget.value) {
                widget.onChanged(next);
              }
            },
            onSubmitted: (_) => _commitText(),
          ),
        ),
        IconButton.filled(
          onPressed: (widget.max == null || widget.value < widget.max!)
              ? () => _setValue(widget.value + 1)
              : null,
          icon: const Icon(Icons.add),
          tooltip: l10n.increaseQuantity,
          style: IconButton.styleFrom(backgroundColor: scheme.primary),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
      ],
    );
  }
}
