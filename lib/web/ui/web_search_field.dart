import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class WebSearchField extends StatelessWidget {
  const WebSearchField({
    super.key,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.focusNode,
    this.autofocus = false,
  });

  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: onSubmitted != null
          ? TextInputAction.search
          : TextInputAction.done,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass, size: 20),
        isDense: true,
      ),
    );
  }
}
