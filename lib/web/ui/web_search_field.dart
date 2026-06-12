import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class WebSearchField extends StatelessWidget {
  const WebSearchField({
    super.key,
    required this.hint,
    this.onChanged,
    this.controller,
    this.autofocus = false,
  });

  final String hint;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass, size: 20),
        isDense: true,
      ),
    );
  }
}
