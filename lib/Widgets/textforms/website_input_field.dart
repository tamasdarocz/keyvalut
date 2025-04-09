import 'package:flutter/material.dart';

class WebsiteInputField extends StatelessWidget {
  const WebsiteInputField({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: TextStyle(fontSize: 20),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.alternate_email),
        label: Text('Website'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(48),
          borderSide: BorderSide(color: Colors.amber, width: 4),
        ),
      ),
    );
  }
}