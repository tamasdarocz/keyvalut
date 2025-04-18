import 'package:flutter/material.dart';

class TitleInputField extends StatelessWidget {
  final TextEditingController controller;
  const TitleInputField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(fontSize: 20),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.devices),
        label: Text('Title: (Required)'),
        hintText: 'Required',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 4),
        ),
      ),
    );
  }
}
