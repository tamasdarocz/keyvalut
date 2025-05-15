import 'package:flutter/material.dart';

class TitleInputField extends StatelessWidget {
  final TextEditingController controller;
  const TitleInputField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: Theme.of(context).textTheme.displayMedium,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.devices),
        label: Text('Title Required'),
        suffixText: 'Required',
      ),
    );
  }
}
