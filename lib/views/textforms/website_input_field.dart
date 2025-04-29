import 'package:flutter/material.dart';

class WebsiteInputField extends StatelessWidget {
  final TextEditingController controller;

  const WebsiteInputField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
        controller: controller,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.http),
          hintText: 'google.com',
          border: OutlineInputBorder(
            borderSide: BorderSide(color:Theme.of(context).colorScheme.primary, width: 1),
          ),
          label: const Text('Website'),
        ));
  }
}
