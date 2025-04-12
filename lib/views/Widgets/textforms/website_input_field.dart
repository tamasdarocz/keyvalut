import 'package:flutter/material.dart';

class WebsiteInputField extends StatelessWidget {
  final TextEditingController controller;
  const WebsiteInputField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(fontSize: 20),
      keyboardType: TextInputType.url,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.alternate_email),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(48),
          borderSide: BorderSide(color: Colors.amber, width: 4),
        ),
        label: Text('Website'),
      ),
    );
  }
}
