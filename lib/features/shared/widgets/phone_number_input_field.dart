import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneNumberInput extends StatefulWidget {
  final String labelText;
  final String? initialPhone;
  final ValueChanged<String?>? onPhoneChanged;
  final bool isRequired;

  const PhoneNumberInput({
    super.key,
    required this.labelText,
    this.initialPhone,
    this.onPhoneChanged,
    this.isRequired = false,
  });

  @override
  State<PhoneNumberInput> createState() => _PhoneNumberInputState();
}

class _PhoneNumberInputState extends State<PhoneNumberInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPhone);
    _controller.addListener(() {
      if (widget.onPhoneChanged != null) {
        widget.onPhoneChanged!(_controller.text.isNotEmpty ? _controller.text : null);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return TextFormField(
      controller: _controller,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
        LengthLimitingTextInputFormatter(15), // Reasonable max length for phone numbers (including country code)
      ],
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: 'e.g., +12025550123',
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1)
        ),
        prefixIcon: const Icon(Icons.phone),
      ),
      validator: widget.isRequired
          ? (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a phone number';
        }
        return null;
      }
          : null,
    );
  }
}