import 'package:flutter/material.dart';

/// Form-field-shaped selector that opens a nested bottom sheet instead of a
/// [DropdownButton] overlay.
///
/// Overlays are positioned against the keyboarded viewport, so when a field in
/// a modal sheet steals focus the menu detaches and floats mid-screen. A nested
/// sheet is laid out after the keyboard dismisses.
class SheetSelectField<T> extends StatelessWidget {
  const SheetSelectField({
    super.key,
    required this.label,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.value,
    this.enabled = true,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T> onChanged;
  final bool enabled;

  Future<void> _open(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    // Let the keyboard collapse so the picker sheet isn't offset by viewInsets.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!context.mounted) return;

    final selected = await showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final maxHeight = MediaQuery.sizeOf(ctx).height * 0.5;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        title: Text(itemLabel(item)),
                        selected: item == value,
                        onTap: () => Navigator.pop(ctx, item),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: enabled ? () => _open(context) : null,
      behavior: HitTestBehavior.opaque,
      child: InputDecorator(
        isEmpty: !hasValue,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.arrow_drop_down),
          enabled: enabled,
        ),
        child: Text(
          hasValue ? itemLabel(value as T) : '',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
