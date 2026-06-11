import 'package:flutter/material.dart';

/// Large-touch-target quantity stepper for billing/order screens.
class QtyStepper extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
        SizedBox(
          width: 56,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton.filled(
          onPressed: (max == null || value < max!)
              ? () => onChanged(value + 1)
              : null,
          icon: const Icon(Icons.add),
          style: IconButton.styleFrom(backgroundColor: scheme.primary),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
      ],
    );
  }
}
