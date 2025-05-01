import 'package:flutter/material.dart';

class TitleInputField extends StatelessWidget {
  final TextEditingController controller;
  const TitleInputField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.devices),
        label: Text('Title Required'),
        suffixText: 'Required',
        border: OutlineInputBorder(
          //borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1),
        ),
      ),
    );
  }
}
