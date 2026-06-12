import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Green success action button per Design.md (Add, Confirm, Save).
class BsSuccessButton extends StatelessWidget {
  const BsSuccessButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.outlined = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final Widget? icon;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final child = icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon!,
              const SizedBox(width: 8),
              Text(label),
            ],
          )
        : Text(label);

    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: BsColors.secondary,
          side: const BorderSide(color: BsColors.secondary),
        ),
        child: child,
      );
    }

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: BsColors.secondary,
        foregroundColor: BsColors.onSecondary,
      ),
      child: child,
    );
  }
}
