import 'package:flutter/material.dart';

import '../../config/constants.dart';

class InputFieldWidget extends StatefulWidget {
  /// Display [InputFieldWidget] which allows user to input values

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;

  const InputFieldWidget({
    super.key,
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  @override
  State<InputFieldWidget> createState() => _InputFieldWidgetState();
}

class _InputFieldWidgetState extends State<InputFieldWidget> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      style: inputFieldStyle,
      keyboardType: TextInputType.number, // Numeric inputs
      controller: widget.controller,
      onChanged: widget.onChanged, // on changed function can be called
      decoration: InputDecoration(
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder,
        filled: true,
        fillColor: white,
        labelText: widget.label,
        labelStyle: inputFieldStyle,
      ),
    );
  }
}
