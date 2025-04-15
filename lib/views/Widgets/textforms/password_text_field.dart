import 'package:flutter/material.dart';
import '../../../services/password_generator.dart';

class PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;

  const PasswordTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.validator,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _isObscured = true;
  bool _showPasswordOptions = false;
  late PasswordGenerator _passwordGenerator;

  @override
  void initState() {
    super.initState();
    _passwordGenerator = PasswordGenerator();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: _isObscured,
          decoration: InputDecoration(
            labelText: widget.labelText,
            border: const OutlineInputBorder(),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _isObscured ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscured = !_isObscured;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      _showPasswordOptions = !_showPasswordOptions;
                    });
                  },
                ),
              ],
            ),
          ),
          validator: widget.validator,
        ),
        if (_showPasswordOptions) ...[
          const SizedBox(height: 8),
          const Text('Password Generator Options'),
          Wrap(
            spacing: 8.0,
            children: [
              ChoiceChip(
                label: const Text('Uppercase'),
                selected: _passwordGenerator.includeUppercase,
                onSelected: (selected) {
                  setState(() {
                    _passwordGenerator.includeUppercase = selected;
                  });
                },
              ),
              ChoiceChip(
                label: const Text('Lowercase'),
                selected: _passwordGenerator.includeLowercase,
                onSelected: (selected) {
                  setState(() {
                    _passwordGenerator.includeLowercase = selected;
                  });
                },
              ),
              ChoiceChip(
                label: const Text('Numbers'),
                selected: _passwordGenerator.includeNumbers,
                onSelected: (selected) {
                  setState(() {
                    _passwordGenerator.includeNumbers = selected;
                  });
                },
              ),
              ChoiceChip(
                label: const Text('Symbols'),
                selected: _passwordGenerator.includeSymbols,
                onSelected: (selected) {
                  setState(() {
                    _passwordGenerator.includeSymbols = selected;
                  });
                },
              ),
            ],
          ),
          Slider(
            value: _passwordGenerator.passwordLength.toDouble(),
            min: 8,
            max: 32,
            divisions: 24,
            label: _passwordGenerator.passwordLength.toString(),
            onChanged: (value) {
              setState(() {
                _passwordGenerator.passwordLength = value.toInt();
              });
            },
          ),
          ElevatedButton(
            onPressed: () {
              widget.controller.text = _passwordGenerator.generatePassword();
            },
            child: const Text('Generate Password'),
          ),
        ],
      ],
    );
  }
}